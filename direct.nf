#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Default parameters
params.outputDir = "results"

// Simple process to check files
process CHECK_FILES {
    publishDir "${params.outputDir}", mode: 'copy'
    
    input:
    path vcf
    path legend
    
    output:
    path "check_summary.txt"
    
    script:
    """
    echo "VCF file: ${vcf}" > check_summary.txt
    echo "Legend file: ${legend}" >> check_summary.txt
    echo "Files exist!" >> check_summary.txt
    """
}

// Workflow definition
workflow {
    vcf_file = file("/home/ubuntu/devs/test_data/chr22.fixed.vcf.gz.lifted.vcf.gz")
    legend_file = file("/mnt/storage/imputationserver2/apps/h3africa/v6hc-s/sites/V6HC-S_chr22_all_sitesOnly.v2025.01.legend.gz")
    
    if (!vcf_file.exists()) {
        error "VCF file does not exist: ${vcf_file}"
    }
    
    if (!legend_file.exists()) {
        error "Legend file does not exist: ${legend_file}"
    }
    
    // Run the process with the input files
    CHECK_FILES(vcf_file, legend_file)
} 