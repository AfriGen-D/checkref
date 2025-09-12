#!/usr/bin/env python3
import sys
import subprocess
import re
import argparse
import gzip
import os

def run_command(cmd):
    """Run a shell command and return the output"""
    proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = proc.communicate()
    if proc.returncode != 0:
        print(f"Error executing command: {cmd}")
        print(stderr.decode())
        sys.exit(1)
    return stdout.decode()

def parse_legend_file(legend_file):
    """Parse a legend file and return variants information"""
    variants = {}
    original_chroms = {}
    
    # Detect if file is gzipped
    open_func = gzip.open if legend_file.endswith('.gz') else open
    mode = 'rt' if legend_file.endswith('.gz') else 'r'
    
    try:
        with open_func(legend_file, mode) as f:
            # Read header
            header = f.readline().strip()
            print(f"Legend file header: {header}")
            
            # Check if header exists
            if header.startswith('id') or header.startswith('ID'):
                header_cols = header.upper().split()
                if 'CHROM' in header_cols:
                    chrom_idx = header_cols.index('CHROM')
                else:
                    chrom_idx = None
                    
                if 'POS' in header_cols:
                    pos_idx = header_cols.index('POS')
                elif 'POSITION' in header_cols:
                    pos_idx = header_cols.index('POSITION')
                else:
                    pos_idx = 2  # Default position index
                    
                if 'REF' in header_cols:
                    ref_idx = header_cols.index('REF')
                elif 'A0' in header_cols:
                    ref_idx = header_cols.index('A0')
                else:
                    ref_idx = 3  # Default reference index
                    
                if 'ALT' in header_cols:
                    alt_idx = header_cols.index('ALT')
                elif 'A1' in header_cols:
                    alt_idx = header_cols.index('A1')
                else:
                    alt_idx = 4  # Default alternate index
                
                print(f"Using column indices - CHROM: {chrom_idx if chrom_idx is not None else 'N/A'}, POS: {pos_idx}, REF: {ref_idx}, ALT: {alt_idx}")
            else:
                # Default column order in legend file: ID position a0 a1
                chrom_idx = None
                pos_idx = 1
                ref_idx = 2
                alt_idx = 3
                # Rewind if we skipped a non-header line
                f.seek(0)
                
            line_count = 0
            for line in f:
                line_count += 1
                cols = line.strip().split()
                if len(cols) <= max(pos_idx, ref_idx, alt_idx, chrom_idx if chrom_idx is not None else 0):
                    continue
                    
                # Determine chromosome
                if chrom_idx is not None:
                    original_chrom = cols[chrom_idx]
                    chrom = original_chrom.lstrip('chr')
                else:
                    # Try to extract chromosome from ID
                    id_parts = cols[0].split('_')
                    if len(id_parts) > 0 and id_parts[0].startswith(('chr', 'CHR')):
                        original_chrom = id_parts[0]
                        chrom = original_chrom.lstrip('chrCHR')
                    else:
                        # Default to chromosome from filename
                        match = re.search(r'(chr\d+|chrX|chrY|chrMT)', legend_file)
                        if match:
                            original_chrom = match.group(1)
                        else:
                            match = re.search(r'(\d+|X|Y|MT)', legend_file)
                            original_chrom = f"chr{match.group(1)}" if match else "unknown"
                        chrom = original_chrom.lstrip('chr')
                
                pos = cols[pos_idx]
                ref = cols[ref_idx]
                alt = cols[alt_idx]
                
                # Store position without 'chr' prefix for matching
                variants[(chrom, pos)] = (ref, alt)
                # Store original chromosome notation
                original_chroms[chrom] = original_chrom
                
                # Print sample of variants being processed
                if line_count <= 5 or line_count % 100000 == 0:
                    print(f"Sample variant {line_count}: CHROM={original_chrom}, POS={pos}, REF={ref}, ALT={alt}")
            
            print(f"Finished processing {line_count} lines from legend file.")
    except Exception as e:
        print(f"Error parsing legend file: {e}")
        print(f"File exists: {os.path.exists(legend_file)}")
        print(f"File size: {os.path.getsize(legend_file) if os.path.exists(legend_file) else 'N/A'}")
        raise
    
    return variants, original_chroms

def detect_genome_build(vcf_file):
    """Detect genome build from VCF file"""
    try:
        # Check VCF header for build information
        header_cmd = f"bcftools view -h {vcf_file}"
        header_output = run_command(header_cmd)

        # Look for build indicators in header
        if 'GRCh38' in header_output or 'hg38' in header_output:
            return 'hg38'
        elif 'GRCh37' in header_output or 'hg19' in header_output:
            return 'hg19'

        # Check filename for build indicators
        if 'hg38' in vcf_file or 'GRCh38' in vcf_file:
            return 'hg38'
        elif 'hg19' in vcf_file or 'GRCh37' in vcf_file:
            return 'hg19'

        return 'unknown'
    except:
        return 'unknown'

def detect_legend_build(legend_file):
    """Detect genome build from legend file"""
    try:
        # Check filename for build indicators
        if 'hg38' in legend_file or 'GRCh38' in legend_file or '2025' in legend_file:
            return 'hg38'
        elif 'hg19' in legend_file or 'GRCh37' in legend_file:
            return 'hg19'

        # Check file content for build indicators (sample a few positions)
        open_func = gzip.open if legend_file.endswith('.gz') else open
        mode = 'rt' if legend_file.endswith('.gz') else 'r'

        with open_func(legend_file, mode) as f:
            # Skip header
            header = f.readline()
            # Check first few variants for typical hg38 vs hg19 position ranges
            for i, line in enumerate(f):
                if i >= 10:  # Check first 10 variants
                    break
                parts = line.strip().split()
                if len(parts) >= 3:
                    try:
                        pos = int(parts[2])  # Assuming POS is in column 2
                        # hg38 typically has different position ranges than hg19
                        # This is a heuristic based on common patterns
                        if pos > 50000000:  # Large positions more common in hg38
                            return 'likely_hg38'
                    except:
                        continue

        return 'unknown'
    except:
        return 'unknown'

def check_allele_switch(target_vcf, reference_file, output_file, use_legend=False):
    """Check for allele switches between target and reference files"""
    print(f"Checking allele switches between {target_vcf} and {reference_file}")

    # Detect genome builds
    target_build = detect_genome_build(target_vcf)
    legend_build = detect_legend_build(reference_file)

    print(f"Detected target VCF build: {target_build}")
    print(f"Detected reference legend build: {legend_build}")

    # Check for build mismatches
    build_mismatch = False
    if target_build != 'unknown' and legend_build != 'unknown':
        if (target_build == 'hg19' and legend_build in ['hg38', 'likely_hg38']) or \
           (target_build == 'hg38' and legend_build == 'hg19'):
            build_mismatch = True

    # Handle build mismatches
    if build_mismatch:
        print("\n" + "="*80)
        print("GENOME BUILD MISMATCH DETECTED")
        print("="*80)
        print(f"Target VCF build:     {target_build}")
        print(f"Reference build:      {legend_build}")
        print("\nThis analysis cannot proceed because comparing variants between")
        print("different genome builds will produce incorrect results.")
        print("\nTo fix this issue:")
        print("1. Ensure both files use the same genome build (hg19/GRCh37 OR hg38/GRCh38)")
        print("2. Use liftOver or similar tools to convert between builds if needed")
        print("3. Check file documentation to confirm the correct genome build")
        print("\nWorkflow terminated to prevent incorrect analysis.")
        print("="*80)

        # Create an empty output file to prevent downstream errors
        with open(output_file, 'w') as f:
            f.write("CHROM\tPOS\tALLELE_SWITCH\n")
            f.write("# No results - genome build mismatch detected\n")

        # Use a different approach - create a special marker file and exit normally
        import os
        with open('BUILD_MISMATCH_DETECTED', 'w') as f:
            f.write("Build mismatch detected - workflow should terminate\n")

        sys.exit(0)  # Exit normally

    # Warn about uncertain builds
    if target_build == 'unknown' or legend_build == 'unknown':
        print("WARNING: Could not definitively determine genome builds from file names/headers")
        print("WARNING: Please verify that both files use the same genome build")
        print("WARNING: Proceeding with analysis but results may be incorrect if builds differ")

    # Get variants from target VCF
    print("Extracting variants from target VCF...")
    target_view_cmd = f"bcftools view -v snps {target_vcf} | bcftools query -f '%CHROM\\t%POS\\t%REF\\t%ALT\\n' > target_variants.txt"
    run_command(target_view_cmd)
    
    target_variants = {}
    original_chroms = {}
    
    print("Processing target variants...")
    with open("target_variants.txt", "r") as f:
        line_count = 0
        for line in f:
            line_count += 1
            try:
                chrom, pos, ref, alt = line.strip().split()
                # Handle multi-allelic variants by taking first alt
                alt = alt.split(',')[0]
                # Save original chromosome notation
                original_chrom = chrom
                # Store without 'chr' prefix for consistent matching
                chrom = chrom.lstrip('chr')
                target_variants[(chrom, pos)] = (ref, alt)
                # Store original chromosome notation
                original_chroms[chrom] = original_chrom
                
                # Print sample of variants being processed
                if line_count <= 5 or line_count % 100000 == 0:
                    print(f"Sample target variant {line_count}: CHROM={original_chrom}, POS={pos}, REF={ref}, ALT={alt}")
            except ValueError:
                # Skip malformed lines
                continue
    
    print(f"Processed {len(target_variants)} variants from target VCF.")
    
    # Get variants from reference file
    if use_legend:
        print("Parsing reference legend file...")
        ref_variants, ref_chroms = parse_legend_file(reference_file)
        # Merge chromosome notations, prioritizing target VCF notation
        for chrom in ref_chroms:
            if chrom not in original_chroms:
                original_chroms[chrom] = ref_chroms[chrom]
    else:
        print("Extracting variants from reference VCF...")
        ref_view_cmd = f"bcftools view -v snps {reference_file} | bcftools query -f '%CHROM\\t%POS\\t%REF\\t%ALT\\n' > ref_variants.txt"
        run_command(ref_view_cmd)
        
        ref_variants = {}
        print("Processing reference variants...")
        with open("ref_variants.txt", "r") as f:
            line_count = 0
            for line in f:
                line_count += 1
                try:
                    chrom, pos, ref, alt = line.strip().split()
                    # Handle multi-allelic variants by taking first alt
                    alt = alt.split(',')[0]
                    # Save original chromosome notation
                    original_chrom = chrom
                    # Store without 'chr' prefix for consistent matching
                    chrom = chrom.lstrip('chr')
                    ref_variants[(chrom, pos)] = (ref, alt)
                    # Store original chromosome notation if not already present
                    if chrom not in original_chroms:
                        original_chroms[chrom] = original_chrom
                except ValueError:
                    # Skip malformed lines
                    continue
                
                # Print status every 100,000 lines
                if line_count % 100000 == 0:
                    print(f"Processed {line_count} lines from reference file...")
    
    print(f"Processed {len(ref_variants)} variants from reference file.")
    
    # Find common positions
    common_positions = set(target_variants.keys()) & set(ref_variants.keys())
    num_common = len(common_positions)
    print(f"Found {num_common} variants at common positions")
    
    # Sample a few common positions for debugging
    sample_positions = list(common_positions)[:5] if num_common > 0 else []
    for pos in sample_positions:
        target_ref, target_alt = target_variants[pos]
        ref_ref, ref_alt = ref_variants[pos]
        original_chrom = original_chroms.get(pos[0], f"chr{pos[0]}")
        print(f"Sample common position: CHROM={original_chrom}, POS={pos[1]}, Target: {target_ref}/{target_alt}, Reference: {ref_ref}/{ref_alt}")
    
    # Check for allele switches
    matched = 0
    switched = 0
    complementary = 0
    complement_switched = 0
    other = 0
    
    # Get reference panel name from the reference file path  
    ref_panel_name = reference_file.split('/')[-1].replace('.legend.gz', '').replace('.legend', '')
    ref_panel_file = f"{ref_panel_name}_extracted.legend.gz"
    
    # Track matched positions for statistics
    matched_ref_positions = set()
    
    with open(output_file, "w") as out:
        # Write header for allele switches
        out.write("CHROM\tPOS\tALLELE_SWITCH\n")
        
        for pos in common_positions:
            chrom, position = pos
            target_ref, target_alt = target_variants[pos]
            ref_ref, ref_alt = ref_variants[pos]
            
            # Use original chromosome notation with 'chr' prefix
            original_chrom = original_chroms.get(chrom, f"chr{chrom}")
            
            # Track this as a matched position
            matched_ref_positions.add(pos)
            
            # Same alleles
            if target_ref == ref_ref and target_alt == ref_alt:
                status = "MATCH"
                matched += 1
            # Switched alleles
            elif target_ref == ref_alt and target_alt == ref_ref:
                status = "SWITCH"
                switched += 1
                # Only write SWITCH variants in 1-based coordinate format
                # Add additional info as a third column
                allele_info = f"{target_ref}>{target_alt}|{ref_ref}>{ref_alt}"
                out.write(f"{original_chrom}\t{position}\t{allele_info}\n")
            # Complementary alleles (A↔T, C↔G)
            elif (is_complement(target_ref, ref_ref) and is_complement(target_alt, ref_alt)):
                status = "COMPLEMENT"
                complementary += 1
            # Complementary + switch
            elif (is_complement(target_ref, ref_alt) and is_complement(target_alt, ref_ref)):
                status = "COMPLEMENT_SWITCH"
                complement_switched += 1
            else:
                status = "OTHER"
                other += 1
    
    # Create the reference panel legend file with all variants
    try:
        with gzip.open(ref_panel_file, 'wt') as ref_out:
            # Write legend header (matching the original format)
            ref_out.write("ID\tCHROM\tPOS\tREF\tALT\tAAF_AFR\tAAF_ALL\tMAF_AFR\tMAF_ALL\n")
            
            # Write all reference variants (both matched and unmatched)
            for pos in sorted(ref_variants.keys()):
                chrom, position = pos
                ref_ref, ref_alt = ref_variants[pos]
                # Use original chromosome notation
                original_chrom = original_chroms.get(chrom, f"chr{chrom}")
                
                # Create variant ID
                variant_id = f"{original_chrom}:{position}:{ref_ref}:{ref_alt}"
                
                # Write variant (with placeholder values for frequency columns)
                ref_out.write(f"{variant_id}\t{original_chrom}\t{position}\t{ref_ref}\t{ref_alt}\t.\t.\t.\t.\n")
        print(f"Successfully created reference legend file: {ref_panel_file}")
    except Exception as e:
        print(f"Error creating reference legend file: {e}")
        # Create a simple uncompressed legend file as fallback
        try:
            ref_panel_file_txt = ref_panel_file.replace('.gz', '')
            with open(ref_panel_file_txt, 'w') as ref_out:
                ref_out.write("ID\tCHROM\tPOS\tREF\tALT\tAAF_AFR\tAAF_ALL\tMAF_AFR\tMAF_ALL\n")
                for pos in sorted(ref_variants.keys()):
                    chrom, position = pos
                    ref_ref, ref_alt = ref_variants[pos]
                    original_chrom = original_chroms.get(chrom, f"chr{chrom}")
                    variant_id = f"{original_chrom}:{position}:{ref_ref}:{ref_alt}"
                    ref_out.write(f"{variant_id}\t{original_chrom}\t{position}\t{ref_ref}\t{ref_alt}\t.\t.\t.\t.\n")
            print(f"Created uncompressed reference legend file: {ref_panel_file_txt}")
        except Exception as e2:
            print(f"Error creating uncompressed legend file: {e2}")
    
    # Clean up
    run_command("rm target_variants.txt")
    if not use_legend:
        run_command("rm ref_variants.txt")
    
    # Print summary
    print("\nResults Summary:")
    print(f"Total variants in target VCF: {len(target_variants)}")
    print(f"Total variants in reference: {len(ref_variants)}")
    print(f"Total variants at common positions: {num_common}")
    
    # Calculate overlap percentages
    if len(target_variants) > 0:
        target_overlap_pct = (num_common / len(target_variants)) * 100
        print(f"Overlap with target VCF: {num_common}/{len(target_variants)} ({target_overlap_pct:.2f}%)")
    
    if len(ref_variants) > 0:
        ref_overlap_pct = (num_common / len(ref_variants)) * 100
        print(f"Overlap with reference: {num_common}/{len(ref_variants)} ({ref_overlap_pct:.2f}%)")
    
    if num_common > 0:
        print(f"Matched variants: {matched} ({matched/num_common*100:.2f}%)")
        print(f"Switched alleles (written to file): {switched} ({switched/num_common*100:.2f}%)")
        print(f"Complementary strand issues: {complementary} ({complementary/num_common*100:.2f}%)")
        print(f"Complement + switch issues: {complement_switched} ({complement_switched/num_common*100:.2f}%)")
        print(f"Other inconsistencies: {other} ({other/num_common*100:.2f}%)")
    else:
        print("No common positions found between target and reference files.")
    
    print(f"Switched alleles written to file: {output_file}")
    print(f"Reference panel legend file created: {ref_panel_file}")
    print(f"Total variants in extracted legend: {len(ref_variants)}")
    print(f"Variants overlapping with target: {len(matched_ref_positions)}")
    print(f"Variants unique to reference: {len(ref_variants) - len(matched_ref_positions)}")

def is_complement(allele1, allele2):
    """Check if alleles are complementary (A↔T, C↔G)"""
    complements = {'A': 'T', 'T': 'A', 'C': 'G', 'G': 'C'}
    
    if len(allele1) != len(allele2):
        return False
    
    for i in range(len(allele1)):
        if i >= len(allele2) or allele2[i] != complements.get(allele1[i], 'X'):
            return False
    
    return True

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Check allele switches between VCF files')
    parser.add_argument('target_vcf', help='Target VCF file')
    parser.add_argument('reference_file', help='Reference file (VCF or legend)')
    parser.add_argument('output_file', help='Output file to write results in 1-based coordinates')
    parser.add_argument('--legend', action='store_true', help='Use legend file format for reference')

    args = parser.parse_args()

    check_allele_switch(args.target_vcf, args.reference_file, args.output_file, args.legend)