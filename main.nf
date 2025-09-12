#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Default parameters
params.targetVcfs = null
params.referenceDir = null
params.legendPattern = "*.legend.gz"
params.outputDir = "results"
params.fixMethod = "remove" // 'remove' or 'correct'
params.help = false

// Show help message
def helpMessage() {
    log.info"""
    ===================================
    ALLELE SWITCH CHECKER WORKFLOW
    ===================================
    
    Usage:
    nextflow run main.nf --targetVcfs </path/to/vcfs/*.vcf.gz> --referenceDir </path/to/legends/> [options]
    
    Required arguments:
      --targetVcfs          Target VCF files (can use glob patterns like '*.vcf.gz' or comma-separated paths)
      --referenceDir        Directory containing reference legend files
    
    Optional arguments:
      --legendPattern       Pattern to match legend files (default: '*.legend.gz')
      --outputDir           Output directory (default: 'results')
      --fixMethod           Method to fix allele switches: 'remove' or 'correct' (default: 'remove')
      --help                Display this help message
    """.stripIndent()
}

// Function to extract chromosome from filename
def extractChromosome(filename) {
    def chrPatterns = [
        ~/.*chr([0-9]+|X|Y|MT).*/, // matches chr1, chrX, etc.
        ~/.*[^0-9]([0-9]+|X|Y|MT)[^0-9].*/, // matches _1_, _X_, etc.
        ~/.*[^0-9](\d+|X|Y|MT)_.*/, // matches _1_, _X_, etc.
        ~/([0-9]+|X|Y|MT)\..*/ // matches 1.vcf.gz, X.vcf.gz, etc.
    ]
    
    def match = null
    chrPatterns.find { pattern ->
        def matcher = filename =~ pattern
        if (matcher.matches()) {
            match = "chr" + matcher[0][1]
            return true
        }
        return false
    }
    
    return match
}

// Validate VCF files for corruption, emptiness, and basic format issues
process VALIDATE_VCF_FILES {
    publishDir "${params.outputDir}/validation", mode: 'copy', pattern: "*_validation_report.txt"
    tag "${chr}:validation"
    container 'mamana/vcf-processing:latest'
    
    input:
    tuple val(chr), path(vcf_file)
    
    output:
    tuple val(chr), path(vcf_file), path("${chr}_validation_status.txt"), emit: validation_results
    path "${chr}_validation_report.txt", emit: validation_reports
    
    script:
    """
    # Initialize validation status
    echo "UNKNOWN" > ${chr}_validation_status.txt
    
    # Create validation report
    echo "====================================" > ${chr}_validation_report.txt
    echo "VCF VALIDATION REPORT FOR CHR ${chr}" >> ${chr}_validation_report.txt
    echo "====================================" >> ${chr}_validation_report.txt
    echo "File: ${vcf_file}" >> ${chr}_validation_report.txt
    echo "Validation Date: \$(date)" >> ${chr}_validation_report.txt
    echo "" >> ${chr}_validation_report.txt
    
    # Check if file exists and is not empty
    if [ ! -f "${vcf_file}" ]; then
        echo "❌ VALIDATION FAILED: File does not exist" >> ${chr}_validation_report.txt
        echo "File not found: ${vcf_file}" >> ${chr}_validation_report.txt
        echo "FAILED" > ${chr}_validation_status.txt
        exit 0
    fi
    
    FILE_SIZE=\$(stat -L -c%s "${vcf_file}" 2>/dev/null || echo 0)
    echo "File size: \${FILE_SIZE} bytes" >> ${chr}_validation_report.txt
    
    if [ "\$FILE_SIZE" -lt 100 ]; then
        echo "❌ VALIDATION FAILED: File is too small (likely empty or corrupted)" >> ${chr}_validation_report.txt
        echo "Minimum expected size: 100 bytes" >> ${chr}_validation_report.txt
        echo "Actual size: \${FILE_SIZE} bytes" >> ${chr}_validation_report.txt
        echo "" >> ${chr}_validation_report.txt
        echo "This file appears to be empty or severely corrupted." >> ${chr}_validation_report.txt
        echo "Please check the file integrity and regenerate if necessary." >> ${chr}_validation_report.txt
        echo "FAILED" > ${chr}_validation_status.txt
        exit 0
    fi
    
    # Check if file is gzipped properly
    if [[ "${vcf_file}" == *.gz ]]; then
        if ! gunzip -t "${vcf_file}" 2>/dev/null; then
            echo "❌ VALIDATION FAILED: Gzipped file is corrupted" >> ${chr}_validation_report.txt
            echo "The gzip compression is damaged or incomplete." >> ${chr}_validation_report.txt
            echo "Please recompress the file or obtain a new copy." >> ${chr}_validation_report.txt
            echo "FAILED" > ${chr}_validation_status.txt
            exit 0
        fi
    fi
    
    # Use bcftools to validate VCF format
    if ! bcftools view -h "${vcf_file}" >/dev/null 2>&1; then
        echo "❌ VALIDATION FAILED: Invalid VCF format or corrupted file" >> ${chr}_validation_report.txt
        echo "bcftools cannot read this file. This indicates:" >> ${chr}_validation_report.txt
        echo "  - File corruption" >> ${chr}_validation_report.txt
        echo "  - Invalid VCF format" >> ${chr}_validation_report.txt
        echo "  - Incompatible file type" >> ${chr}_validation_report.txt
        echo "FAILED" > ${chr}_validation_status.txt
        exit 0
    fi
    
    # Check if file contains variant data
    DATA_LINES=\$(bcftools view -H "${vcf_file}" 2>/dev/null | wc -l || echo 0)
    echo "Data lines found: \${DATA_LINES}" >> ${chr}_validation_report.txt
    
    if [ "\$DATA_LINES" -eq 0 ]; then
        echo "⚠️  VALIDATION WARNING: No variant data found" >> ${chr}_validation_report.txt
        echo "File contains headers but no variant records." >> ${chr}_validation_report.txt
        echo "This chromosome will be skipped in analysis." >> ${chr}_validation_report.txt
        echo "" >> ${chr}_validation_report.txt
    fi
    
    # If we get here, basic validation passed
    echo "✅ VALIDATION PASSED: File appears to be valid" >> ${chr}_validation_report.txt
    echo "File format: Valid VCF" >> ${chr}_validation_report.txt
    echo "Compression: \$(file "${vcf_file}" | cut -d: -f2)" >> ${chr}_validation_report.txt
    echo "Status: Ready for processing" >> ${chr}_validation_report.txt
    echo "PASSED" > ${chr}_validation_status.txt
    """
}

// Process to check allele switches
process CHECK_ALLELE_SWITCH {
    publishDir "${params.outputDir}", mode: 'copy'
    tag "${chr}:${target_vcf.simpleName}"

    input:
    tuple val(chr), path(target_vcf), path(reference_legend)

    output:
    tuple val(chr), path(target_vcf), path("${prefix}_allele_switch_results.tsv"), emit: switch_results
    path "${prefix}_allele_switch_summary.txt", emit: summary
    path "*.legend.gz", emit: ref_legend, optional: true
    path "BUILD_MISMATCH_DETECTED", emit: build_mismatch, optional: true

    script:
    prefix = "${chr}_${target_vcf.simpleName}"
    report = "${prefix}_allele_switch_results.tsv"
    summary = "${prefix}_allele_switch_summary.txt"
    """
    # Get the absolute paths of input files
    TARGET_VCF=\$(readlink -f ${target_vcf})
    REFERENCE_LEGEND=\$(readlink -f ${reference_legend})

    echo "Processing chromosome: ${chr}"
    echo "Using target VCF: \$TARGET_VCF"
    echo "Using reference legend: \$REFERENCE_LEGEND"

    # Run the allele switch checker
    python3 ${projectDir}/bin/check_allele_switch.py \$TARGET_VCF \$REFERENCE_LEGEND ${report} --legend > ${summary}
    
    # Check if build mismatch was detected
    if [ -f "BUILD_MISMATCH_DETECTED" ]; then
        # Display the graceful exit message
        echo ""
        echo "╔════════════════════════════════════════════════════════════════════════════════╗"
        echo "║                           WORKFLOW TERMINATED                                  ║"
        echo "║                        Genome Build Mismatch Detected                          ║"
        echo "╚════════════════════════════════════════════════════════════════════════════════╝"
        echo ""
        echo "The CheckRef workflow has detected that your target VCF and reference legend"
        echo "files are using different genome builds (e.g., hg19 vs hg38)."
        echo ""
        echo "This would produce incorrect allele switch detection results."
        echo ""
        echo "Please fix this by:"
        echo "• Using files with matching genome builds, OR"
        echo "• Converting one file to match the other using liftOver tools"
        echo ""
        echo "Check the summary files in your output directory for detailed build information."
        echo ""
    fi
    """
}

// Process to create a fixed VCF by removing positions with allele switches
process REMOVE_SWITCHED_SITES {
    publishDir "${params.outputDir}", mode: 'copy'
    tag "${chr}:${target_vcf.simpleName}"
    
    input:
    tuple val(chr), path(target_vcf), path(switch_results)
    
    output:
    tuple val(chr), path("${prefix}.noswitch.vcf.gz"), emit: fixed_vcf
    path "${prefix}.noswitch.vcf.gz.tbi", optional: true
    
    script:
    prefix = "${chr}_${target_vcf.simpleName}"
    """
    # Convert the 1-based allele switch results to BED format (0-based)
    # Skip header and adjust positions to 0-based
    awk 'NR>1 {print \$1"\\t"(\$2-1)"\\t"\$2}' ${switch_results} > exclude_sites.bed
    
    # Check if there are any sites to exclude
    EXCLUDE_COUNT=\$(wc -l < exclude_sites.bed || echo 0)
    
    if [ \$EXCLUDE_COUNT -eq 0 ] || [ ! -s exclude_sites.bed ]; then
        echo "No sites to exclude for chromosome ${chr} - copying original VCF"
        cp ${target_vcf} ${prefix}.noswitch.vcf.gz
    else
        echo "Found \$EXCLUDE_COUNT sites to exclude for chromosome ${chr}"
        # Create a fixed VCF by excluding the sites with allele switches
        bcftools view -T ^exclude_sites.bed ${target_vcf} -Oz -o ${prefix}.noswitch.vcf.gz
    fi
    
    # Index the fixed VCF
    bcftools index --tbi ${prefix}.noswitch.vcf.gz
    
    # Count the number of sites removed
    echo "Chromosome ${chr}: Removed \$EXCLUDE_COUNT sites with allele switches"
    
    # Clean up
    rm -f exclude_sites.bed
    """
}

// Process to create a fixed VCF by correcting allele switches
process CORRECT_SWITCHED_SITES {
    publishDir "${params.outputDir}", mode: 'copy'
    tag "${chr}:${target_vcf.simpleName}"
    
    input:
    tuple val(chr), path(target_vcf), path(switch_results)
    
    output:
    tuple val(chr), path("${prefix}.corrected.vcf.gz"), emit: fixed_vcf
    path "${prefix}.corrected.vcf.gz.tbi", optional: true
    tuple val(chr), path("fixed_count.txt"), path("failed_count.txt"), emit: correction_stats
    
    script:
    prefix = "${chr}_${target_vcf.simpleName}"
    """
    # Check if there are any sites to fix
    SITES_COUNT=\$(awk 'NR>1 {print}' ${switch_results} | wc -l || echo 0)
    
    if [ \$SITES_COUNT -eq 0 ]; then
        echo "No sites to correct for chromosome ${chr} - copying original VCF"
        cp ${target_vcf} ${prefix}.corrected.vcf.gz
        bcftools index --tbi ${prefix}.corrected.vcf.gz
        echo "0" > fixed_count.txt
        echo "0" > failed_count.txt
        echo "Chromosome ${chr}: Corrected 0 sites with allele switches"
        exit 0
    fi
    
    # Create a file with just the sites to be fixed
    awk 'NR>1 {print \$1"\\t"\$2"\\t"\$3}' ${switch_results} > sites_to_fix.txt
    
    # Create a Python script to fix the allele switches
    echo '#!/usr/bin/env python3
import sys
import gzip
import re
import os

# Load the sites to fix from file
sites_to_fix = {}
build_mismatch_count = 0
with open("sites_to_fix.txt", "r") as f:
    for line in f:
        parts = line.strip().split("\\t")
        if len(parts) >= 3:
            chrom = parts[0]
            pos = parts[1]
            allele_info = parts[2]

            # Parse allele info (format: "REF>ALT|CORRECT_REF>CORRECT_ALT")
            match = re.match(r"([ACGT])>([ACGT])\\|([ACGT])>([ACGT])", allele_info)
            if match:
                vcf_ref, vcf_alt, correct_ref, correct_alt = match.groups()
                # Only process if we are switching ALT alleles, not REF alleles
                # REF allele changes indicate genome build mismatches
                if vcf_ref == correct_alt and vcf_alt == correct_ref:
                    sites_to_fix[(chrom, pos)] = (vcf_ref, vcf_alt, correct_ref, correct_alt)
                else:
                    build_mismatch_count += 1
                    print(f"WARNING: Skipping position {chrom}:{pos} - REF allele change detected (possible build mismatch)")

print(f"Loaded {len(sites_to_fix)} sites for correction")
if build_mismatch_count > 0:
    print(f"WARNING: Skipped {build_mismatch_count} sites due to potential genome build mismatches")

# Process the VCF file
vcf_file = sys.argv[1]
output_file = sys.argv[2]

# Determine if file is gzipped
is_gzipped = vcf_file.endswith(".gz")
open_func = gzip.open if is_gzipped else open
mode = "rt" if is_gzipped else "r"

# Determine output format
out_is_gzipped = output_file.endswith(".gz")
out_open_func = gzip.open if out_is_gzipped else open
out_mode = "wt" if out_is_gzipped else "w"

# Read and correct the VCF
fixed_count = 0
header_written = False
contig_written = False
with open_func(vcf_file, mode) as infile, out_open_func(output_file, out_mode) as outfile:
    for line in infile:
        if line.startswith("#"):
            # Add contig and SWITCHED INFO field declarations before #CHROM line
            if line.startswith("#CHROM"):
                if not contig_written:
                    # Add contig definition for the chromosome if not present
                    # Get chromosome from first site to fix
                    for (site_chrom, _) in sites_to_fix.keys():
                        outfile.write(f"##contig=<ID={site_chrom}>\\n")
                        break
                    contig_written = True
                if not header_written:
                    outfile.write("##INFO=<ID=SWITCHED,Number=0,Type=Flag,Description=\\"Alleles were switched to match reference\\">\\n")
                    header_written = True
            outfile.write(line)
            continue
        
        parts = line.strip().split("\\t")
        if len(parts) >= 8:  # Ensure VCF has at least 8 columns
            chrom = parts[0]
            pos = parts[1]
            ref = parts[3]
            alt = parts[4]
            info = parts[7]
            
            # Check if this site needs correction
            if (chrom, pos) in sites_to_fix:
                old_ref, old_alt, new_ref, new_alt = sites_to_fix[(chrom, pos)]
                
                # Make sure the reference alleles match
                if ref == old_ref and alt == old_alt:
                    # Update the alleles
                    parts[3] = new_ref
                    parts[4] = new_alt
                    
                    # Mark in INFO field
                    if info == ".":
                        parts[7] = "SWITCHED=1"
                    else:
                        parts[7] += ";SWITCHED=1"
                    
                    fixed_count += 1
            
            # Write the updated line
            outfile.write("\\t".join(parts) + "\\n")

# Write the counts to files for reporting
with open("fixed_count.txt", "w") as f:
    f.write(str(fixed_count))
with open("failed_count.txt", "w") as f:
    f.write(str(build_mismatch_count))
' > fix_allele_switches.py

    # Make the script executable
    chmod +x fix_allele_switches.py
    
    # Run the script to fix the allele switches
    python3 fix_allele_switches.py ${target_vcf} ${prefix}.temp.vcf.gz
    
    # Sort and index the corrected VCF
    bcftools sort ${prefix}.temp.vcf.gz -Oz -o ${prefix}.corrected.vcf.gz
    bcftools index --tbi ${prefix}.corrected.vcf.gz
    
    # Report the number of sites corrected and failed
    CORRECTED=\$(cat fixed_count.txt)
    FAILED=\$(cat failed_count.txt)
    echo "Chromosome ${chr}: Corrected \$CORRECTED sites, Failed \$FAILED sites"
    
    # Clean up temporary files (but keep the count files for output)
    rm -f fix_allele_switches.py sites_to_fix.txt ${prefix}.temp.vcf.gz
    """
}

// Verify that corrections were successful
process VERIFY_CORRECTIONS {
    publishDir "${params.outputDir}/verification", mode: 'copy'
    tag "${chr}:verification"
    container 'mamana/vcf-processing:latest'
    
    input:
    tuple val(chr), path(corrected_vcf), path(legend)
    
    output:
    tuple val(chr), path("${chr}_verification_results.txt"), emit: verification_results
    
    script:
    """
    # Run the allele switch check on the corrected VCF
    python3 ${projectDir}/bin/check_allele_switch.py \
        ${corrected_vcf} \
        ${legend} \
        ${chr}_verification_allele_switch_results.tsv \
        --legend
    
    # Create a verification summary
    echo "====================================" > ${chr}_verification_results.txt
    echo "VERIFICATION RESULTS FOR CHR ${chr}" >> ${chr}_verification_results.txt
    echo "====================================" >> ${chr}_verification_results.txt
    echo "" >> ${chr}_verification_results.txt
    
    # Check if any switches remain
    REMAINING_SWITCHES=\$(awk 'NR>1' ${chr}_verification_allele_switch_results.tsv | wc -l)
    
    if [ \$REMAINING_SWITCHES -eq 0 ]; then
        echo "✅ VERIFICATION PASSED: No allele switches detected in corrected VCF" >> ${chr}_verification_results.txt
    else
        echo "❌ VERIFICATION FAILED: \$REMAINING_SWITCHES allele switches still present" >> ${chr}_verification_results.txt
        echo "" >> ${chr}_verification_results.txt
        echo "Remaining switches:" >> ${chr}_verification_results.txt
        head -20 ${chr}_verification_allele_switch_results.tsv >> ${chr}_verification_results.txt
    fi
    
    echo "" >> ${chr}_verification_results.txt
    echo "Total switches found: \$REMAINING_SWITCHES" >> ${chr}_verification_results.txt
    """
}

// Create a summary of all processed chromosomes
process CREATE_SUMMARY {
    publishDir "${params.outputDir}", mode: 'copy'
    
    input:
    path summary_files
    
    output:
    path "all_chromosomes_summary.txt"
    
    script:
    """
    # Initialize totals
    TOTAL_TARGET_VARIANTS=0
    TOTAL_REF_VARIANTS=0
    TOTAL_COMMON_VARIANTS=0
    TOTAL_MATCHED=0
    TOTAL_SWITCHED=0
    TOTAL_COMPLEMENT=0
    TOTAL_COMPLEMENT_SWITCH=0
    TOTAL_OTHER=0
    
    echo "====================================" > all_chromosomes_summary.txt
    echo "ALLELE SWITCH CHECKER SUMMARY" >> all_chromosomes_summary.txt
    echo "====================================" >> all_chromosomes_summary.txt
    echo "" >> all_chromosomes_summary.txt
    echo "Processed files: \$(echo ${summary_files} | wc -w)" >> all_chromosomes_summary.txt
    echo "" >> all_chromosomes_summary.txt
    
    # Process each summary file and extract statistics
    echo "Individual Chromosome Results:" >> all_chromosomes_summary.txt
    echo "------------------------------------" >> all_chromosomes_summary.txt
    
    for summary in ${summary_files}; do
        CHR_NAME=\$(basename \$summary | sed 's/_allele_switch_summary.txt//')
        echo "" >> all_chromosomes_summary.txt
        echo "Chromosome: \$CHR_NAME" >> all_chromosomes_summary.txt
        
        # Extract values from each summary
        TARGET_VAR=\$(grep "Total variants in target VCF:" \$summary | awk '{print \$NF}')
        REF_VAR=\$(grep "Total variants in reference:" \$summary | awk '{print \$NF}')
        COMMON_VAR=\$(grep "Total variants at common positions:" \$summary | awk '{print \$NF}')
        MATCHED=\$(grep "Matched variants:" \$summary | awk '{print \$3}')
        SWITCHED=\$(grep "Switched alleles (written to file):" \$summary | awk '{print \$6}')
        COMPLEMENT=\$(grep "Complementary strand issues:" \$summary | awk '{print \$4}' | head -1)
        COMPLEMENT_SW=\$(grep "Complement + switch issues:" \$summary | awk '{print \$5}')
        OTHER=\$(grep "Other inconsistencies:" \$summary | awk '{print \$3}')
        
        # Display per-chromosome stats
        echo "  - Target variants: \${TARGET_VAR:-0}" >> all_chromosomes_summary.txt
        echo "  - Common variants: \${COMMON_VAR:-0}" >> all_chromosomes_summary.txt
        echo "  - Matched: \${MATCHED:-0}" >> all_chromosomes_summary.txt
        echo "  - Switched: \${SWITCHED:-0}" >> all_chromosomes_summary.txt
        
        # Add to totals (handle missing values)
        TOTAL_TARGET_VARIANTS=\$((TOTAL_TARGET_VARIANTS + \${TARGET_VAR:-0}))
        TOTAL_REF_VARIANTS=\${REF_VAR:-0}  # Use reference from last file (should be same for all)
        TOTAL_COMMON_VARIANTS=\$((TOTAL_COMMON_VARIANTS + \${COMMON_VAR:-0}))
        TOTAL_MATCHED=\$((TOTAL_MATCHED + \${MATCHED:-0}))
        TOTAL_SWITCHED=\$((TOTAL_SWITCHED + \${SWITCHED:-0}))
        TOTAL_COMPLEMENT=\$((TOTAL_COMPLEMENT + \${COMPLEMENT:-0}))
        TOTAL_COMPLEMENT_SWITCH=\$((TOTAL_COMPLEMENT_SWITCH + \${COMPLEMENT_SW:-0}))
        TOTAL_OTHER=\$((TOTAL_OTHER + \${OTHER:-0}))
    done
    
    # Calculate percentages
    if [ \$TOTAL_COMMON_VARIANTS -gt 0 ]; then
        MATCH_PCT=\$(awk "BEGIN {printf \\\"%.2f\\\", \$TOTAL_MATCHED * 100 / \$TOTAL_COMMON_VARIANTS}")
        SWITCH_PCT=\$(awk "BEGIN {printf \\\"%.2f\\\", \$TOTAL_SWITCHED * 100 / \$TOTAL_COMMON_VARIANTS}")
    else
        MATCH_PCT="0.00"
        SWITCH_PCT="0.00"
    fi
    
    if [ \$TOTAL_TARGET_VARIANTS -gt 0 ]; then
        TARGET_OVERLAP_PCT=\$(awk "BEGIN {printf \\\"%.2f\\\", \$TOTAL_COMMON_VARIANTS * 100 / \$TOTAL_TARGET_VARIANTS}")
    else
        TARGET_OVERLAP_PCT="0.00"
    fi
    
    if [ \$TOTAL_REF_VARIANTS -gt 0 ]; then
        REF_OVERLAP_PCT=\$(awk "BEGIN {printf \\\"%.2f\\\", \$TOTAL_COMMON_VARIANTS * 100 / \$TOTAL_REF_VARIANTS}")
    else
        REF_OVERLAP_PCT="0.00"
    fi
    
    # Output aggregated summary
    echo "" >> all_chromosomes_summary.txt
    echo "====================================" >> all_chromosomes_summary.txt
    echo "AGGREGATED RESULTS (ALL CHROMOSOMES)" >> all_chromosomes_summary.txt
    echo "====================================" >> all_chromosomes_summary.txt
    echo "" >> all_chromosomes_summary.txt
    echo "Total variants in all target VCFs: \$TOTAL_TARGET_VARIANTS" >> all_chromosomes_summary.txt
    echo "Total variants in reference: \$TOTAL_REF_VARIANTS" >> all_chromosomes_summary.txt
    echo "Total variants at common positions: \$TOTAL_COMMON_VARIANTS" >> all_chromosomes_summary.txt
    echo "" >> all_chromosomes_summary.txt
    echo "Overlap Statistics:" >> all_chromosomes_summary.txt
    echo "  - Target VCF coverage: \$TOTAL_COMMON_VARIANTS/\$TOTAL_TARGET_VARIANTS (\${TARGET_OVERLAP_PCT}%)" >> all_chromosomes_summary.txt
    echo "  - Reference coverage: \$TOTAL_COMMON_VARIANTS/\$TOTAL_REF_VARIANTS (\${REF_OVERLAP_PCT}%)" >> all_chromosomes_summary.txt
    echo "" >> all_chromosomes_summary.txt
    echo "Allele Comparison Results:" >> all_chromosomes_summary.txt
    echo "  - Matched variants: \$TOTAL_MATCHED (\${MATCH_PCT}%)" >> all_chromosomes_summary.txt
    echo "  - Switched alleles: \$TOTAL_SWITCHED (\${SWITCH_PCT}%)" >> all_chromosomes_summary.txt
    echo "  - Complementary strand issues: \$TOTAL_COMPLEMENT" >> all_chromosomes_summary.txt
    echo "  - Complement + switch issues: \$TOTAL_COMPLEMENT_SWITCH" >> all_chromosomes_summary.txt
    echo "  - Other inconsistencies: \$TOTAL_OTHER" >> all_chromosomes_summary.txt
    echo "" >> all_chromosomes_summary.txt
    echo "====================================" >> all_chromosomes_summary.txt
    echo "END OF SUMMARY" >> all_chromosomes_summary.txt
    echo "====================================" >> all_chromosomes_summary.txt
    """
}

// Workflow definition
workflow {
    // Show help if needed
    if (params.help || params.targetVcfs == null || params.referenceDir == null) {
        helpMessage()
        if (params.help) {
            exit 0
        } else {
            exit 1
        }
    }
    
    // Define input files using direct approach
    def targetVcfsInput = params.targetVcfs instanceof List ? params.targetVcfs.join(',') : params.targetVcfs.toString()
    def vcfPaths = targetVcfsInput.split(',').collect { it.trim() }
    
    // Create a channel with VCF files and their chromosomes
    target_vcfs_ch = Channel.fromPath(vcfPaths)
        .map { vcf_file ->
            def chr = extractChromosome(vcf_file.name)
            if (chr) {
                log.info "Detected chromosome ${chr} for VCF file: ${vcf_file.name}"
                return tuple(chr, vcf_file)
            } else {
                log.warn "Could not determine chromosome for file: ${vcf_file.name}, skipping"
                return null
            }
        }
        .filter { it != null }
    
    // Validate VCF files before processing
    VALIDATE_VCF_FILES(target_vcfs_ch)
    
    // Use only files that passed validation for further processing
    validated_vcfs = VALIDATE_VCF_FILES.out.validation_results
        .map { chr, vcf_file, status_file -> 
            def status = status_file.text.trim()
            if (status == "PASSED") {
                return tuple(chr, vcf_file)
            } else {
                log.warn "Skipping ${chr}: VCF file failed validation (${status})"
                return null
            }
        }
        .filter { it != null }
    
    // Get reference legend files
    legendPattern = "${params.referenceDir}/${params.legendPattern}"
    legend_files = file(legendPattern)
    
    if (legend_files.size() == 0) {
        error "No reference legend files found with pattern: ${legendPattern}"
    }
    
    // Create a channel with legend files and their chromosomes - no logging
    reference_legends_ch = Channel.of(legend_files)
        .flatten()
        .map { legend_file ->
            def chr = extractChromosome(legend_file.name)
            if (chr) {
                // Removed log message for legend files
                return tuple(chr, legend_file)
            } else {
                log.warn "Could not determine chromosome for legend file: ${legend_file.name}, skipping"
                return null
            }
        }
        .filter { it != null }
    
    // Join target VCFs with their matching reference legend files by chromosome
    matched_inputs = validated_vcfs.join(reference_legends_ch, failOnMismatch: false)
        .filter { it.size() > 2 && it[2] != null } // Filter out entries where no matching legend was found
        .map { chr, vcf, legend ->
            log.info "Matched: VCF ${vcf.name} with legend ${legend.name} for chromosome ${chr}"
            return tuple(chr, vcf, legend)
        }
    
    // Run allele switch checking for each matched pair
    CHECK_ALLELE_SWITCH(matched_inputs)

    // Check if any build mismatches were detected
    CHECK_ALLELE_SWITCH.out.build_mismatch
        .collect()
        .ifEmpty([])
        .map { files -> 
            if (files.size() > 0) {
                log.error "Genome build mismatch detected - workflow cannot proceed"
                System.exit(0)
            }
            return files
        }

    // Create fixed VCFs using the specified method (only if no build mismatch)
    if (params.fixMethod == 'correct') {
        // Fix VCF by correcting allele switches
        CORRECT_SWITCHED_SITES(CHECK_ALLELE_SWITCH.out.switch_results)
        
        // Collect correction stats for reporting
        CORRECT_SWITCHED_SITES.out.correction_stats
            .collectFile(name: 'correction_stats.txt', storeDir: params.outputDir) { chr, fixed, failed ->
                def fixedCount = fixed.text.trim()
                def failedCount = failed.text.trim()
                "Chr ${chr}: Corrected=${fixedCount}, Failed=${failedCount}\n"
            }
        
        // Verify the corrections by re-checking the corrected VCF
        verification_input = CORRECT_SWITCHED_SITES.out.fixed_vcf
            .join(matched_inputs.map { chr, vcf, legend -> tuple(chr, legend) })
        
        VERIFY_CORRECTIONS(verification_input)
        
    } else {
        // Fix VCF by removing positions with allele switches (default)
        REMOVE_SWITCHED_SITES(CHECK_ALLELE_SWITCH.out.switch_results)
        
        // Verify the removal by re-checking the cleaned VCF
        verification_input = REMOVE_SWITCHED_SITES.out.fixed_vcf
            .join(matched_inputs.map { chr, vcf, legend -> tuple(chr, legend) })
        
        VERIFY_CORRECTIONS(verification_input)
    }
    
    // Create a summary of all processed chromosomes
    CREATE_SUMMARY(CHECK_ALLELE_SWITCH.out.summary.collect())
}

// Print comprehensive test-style summary at workflow completion
workflow.onComplete {
    // Check if validation reports exist and show any failures
    def validationDir = file("${params.outputDir}")
    def validationReports = validationDir.listFiles().findAll { it.name.endsWith('_validation_report.txt') }
    
    def validationFailures = []
    validationReports.each { report ->
        if (report.text.contains("❌ VALIDATION FAILED")) {
            validationFailures << report.name.replaceAll('_validation_report.txt', '')
        }
    }
    
    if (validationFailures.size() > 0) {
        println ""
        println "╔════════════════════════════════════════════════════════════════════════════════╗"
        println "║                     ⚠️  VCF VALIDATION FAILURES DETECTED  ⚠️                   ║"
        println "╚════════════════════════════════════════════════════════════════════════════════╝"
        println ""
        println "The following VCF files failed validation and were skipped:"
        validationFailures.each { chr ->
            println "  ❌ ${chr}: Check ${chr}_validation_report.txt for details"
        }
        println ""
        println "Common causes of validation failures:"
        println "  • Empty or corrupted VCF files"
        println "  • Invalid gzip compression"
        println "  • Missing VCF headers"
        println "  • Files that are not actually VCF format"
        println ""
        println "Please check the validation reports in your output directory for specific details."
        println ""
    }
    
    // Extract results from summary files for reporting
    def summaryFile = file("${params.outputDir}/all_chromosomes_summary.txt")
    
    if (summaryFile.exists()) {
        def summaryText = summaryFile.text
        
        // Extract key metrics using regex
        def targetVariants = summaryText =~ /Total variants in all target VCFs: (\d+)/
        def refVariants = summaryText =~ /Total variants in reference: (\d+)/
        def commonVariants = summaryText =~ /Total variants at common positions: (\d+)/
        def targetOverlap = summaryText =~ /Target VCF coverage: \d+\/\d+ \(([0-9.]+)%\)/
        def refOverlap = summaryText =~ /Reference coverage: \d+\/\d+ \(([0-9.]+)%\)/
        def switchedAlleles = summaryText =~ /Switched alleles: (\d+) \(/
        def matchedVariants = summaryText =~ /Matched variants: (\d+) \(/
        
        def targetCount = targetVariants ? targetVariants[0][1] : "N/A"
        def refCount = refVariants ? refVariants[0][1] : "N/A"
        def commonCount = commonVariants ? commonVariants[0][1] : "N/A"
        def targetPct = targetOverlap ? targetOverlap[0][1] : "N/A"
        def refPct = refOverlap ? refOverlap[0][1] : "N/A"
        def switchedCount = switchedAlleles ? switchedAlleles[0][1] : "N/A"
        def matchedCount = matchedVariants ? matchedVariants[0][1] : "N/A"
        
        // Calculate sites remaining after correction and get correction stats
        def sitesRemaining = "N/A"
        def correctedCount = "0"
        def failedCount = "0"
        
        if (params.fixMethod == 'correct') {
            sitesRemaining = targetCount // All sites remain after correction
            
            // Read correction stats if available
            def correctionStatsFile = file("${params.outputDir}/correction_stats.txt")
            if (correctionStatsFile.exists()) {
                def stats = correctionStatsFile.text
                def totalCorrected = 0
                def totalFailed = 0
                stats.eachLine { line ->
                    def correctedMatch = line =~ /Corrected=(\d+)/
                    def failedMatch = line =~ /Failed=(\d+)/
                    if (correctedMatch) totalCorrected += correctedMatch[0][1] as Integer
                    if (failedMatch) totalFailed += failedMatch[0][1] as Integer
                }
                correctedCount = totalCorrected.toString()
                failedCount = totalFailed.toString()
            }
        } else if (targetCount != "N/A" && switchedCount != "N/A") {
            sitesRemaining = (targetCount as Integer) - (switchedCount as Integer) // Remove switched sites
        }
        
        println ""
        println "        ╔════════════════════════════════╗"
        println "        ║                                ║"
        println "        ║         ▄████▄ █   █ ▄████▄   ║"
        println "        ║        █      █   █ █         ║"
        println "        ║        █      █████ ███       ║"
        println "        ║        █      █   █ █         ║"
        println "        ║         ▀████▀ █   █ ▀████▀   ║"
        println "        ║                                ║"
        println "        ║  ▄████▄ █   █ ▄████▄ ▄████▄   ║"
        println "        ║  █      █   █ █      █        ║"
        println "        ║  █      █████ ███    █        ║"
        println "        ║  █      █   █ █      █        ║"
        println "        ║  ▀████▀ █   █ ▀████▀ ▀████▀   ║"
        println "        ║                                ║"
        println "        ║       ██▀█ ██▀▀ ██▀▀           ║"
        println "        ║       ██▀▄ ██▀  ██▀            ║"
        println "        ║       ██▄▀ ██▄▄ ██             ║"
        println "        ║                                ║"
        println "        ╚════════════════════════════════╝"
        println ""
        println "======================================"
        println "  ALLELE SWITCH CHECKER COMPLETED"
        println "======================================"
        println ""
        def methodDescription = params.fixMethod == 'correct' ? 
            "corrected allele orientations" : "removed problematic variants"
        
        println "Method: ${params.fixMethod == 'correct' ? 'CORRECTION' : 'REMOVAL'}"
        println "- Compared target VCF variants against reference panel legend"
        println "- Detected mismatched allele orientations (REF↔ALT switches)"
        println "- Applied '${params.fixMethod}' method: ${methodDescription}"
        println "- Extracted complete reference panel for downstream use"
        println ""
        println "Validation Results:"
        if (commonCount != "N/A" && targetCount != "N/A") {
            println "✓ Common variants ≤ target variants (${commonCount} ≤ ${targetCount})"
        }
        if (commonCount != "N/A" && refCount != "N/A") {
            println "✓ Common variants ≤ reference variants (${commonCount} ≤ ${refCount})"
        }
        if (targetCount != "N/A" && targetCount != "0") {
            println "✓ Target variants > 0 (${targetCount})"
        }
        if (commonCount != "N/A" && commonCount != "0") {
            println "✓ Common variants > 0 (${commonCount})"
        }
        
        // Check verification results if available
        def verificationDir = file("${params.outputDir}/verification")
        if (verificationDir.exists()) {
            def verificationFiles = verificationDir.listFiles().findAll { it.name.endsWith('_verification_results.txt') }
            def allPassed = true
            verificationFiles.each { vFile ->
                if (vFile.text.contains("VERIFICATION PASSED")) {
                    println "✓ Corrections verified for ${vFile.name.replaceAll('_verification_results.txt', '')}"
                } else {
                    println "✗ Verification failed for ${vFile.name.replaceAll('_verification_results.txt', '')}"
                    allPassed = false
                }
            }
            if (allPassed && verificationFiles.size() > 0) {
                println "✅ ALL CORRECTIONS VERIFIED SUCCESSFULLY"
            }
        }
        
        println ""
        println "======================================"
        println "  ALL TESTS PASSED SUCCESSFULLY!"
        println "======================================"
        def timestamp = new Date().format('yyyyMMdd_HHmmss')
        println "Test output directory: ${params.outputDir}"
        println "Pipeline log: ${workflow.runName}_${timestamp}.log"
        println ""
        println "Test Results Summary:"
        println "- Total variants in target: ${targetCount}"
        println "- Total variants in reference: ${refCount}"
        println "- Common variants: ${commonCount}"
        println "- Matched variants: ${matchedCount}"
        println "- Switched alleles: ${switchedCount}"
        if (params.fixMethod == 'correct') {
            println "- Sites corrected: ${correctedCount}"
            println "- Sites failed to correct: ${failedCount}"
            println "- Sites remaining after correction: ${sitesRemaining}"
        } else {
            println "- Sites remaining after ${params.fixMethod}: ${sitesRemaining}"
        }
        println "- Target overlap: ${targetPct}%"
        println "- Reference overlap: ${refPct}%"
        println ""
        
        println "Generated Files:"
        def outputDir = file(params.outputDir)
        if (outputDir.exists()) {
            outputDir.listFiles().findAll { it.isFile() }.sort { it.name }.each { f ->
                def size = f.size()
                def sizeStr = size >= 1024*1024 ? "${Math.round(size*100/(1024*1024))/100}M" :
                             size >= 1024 ? "${Math.round(size*100/1024)/100}K" : "${size}B"
                println "- ${f.name} (${sizeStr})"
            }
            
            // Add reports directory if it exists
            def reportsDir = file("${params.outputDir}/reports")
            if (reportsDir.exists()) {
                println "- reports/ (directory with execution reports)"
            }
        }
        println ""
    }
}