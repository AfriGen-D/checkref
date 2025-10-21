#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Default parameters
params.targetVcf = "/home/ubuntu/devs/test_data/chr22.fixed.vcf.gz.lifted.vcf.gz"
params.referenceLegend = "/mnt/storage/imputationserver2/apps/h3africa/v6hc-s/sites/V6HC-S_chr22_all_sitesOnly.v2025.01.legend.gz"
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
    // Create channels for input files
    vcf_ch = Channel.fromPath(params.targetVcf, checkIfExists: true)
    legend_ch = Channel.fromPath(params.referenceLegend, checkIfExists: true)
    
    // Run the process with the input files
    CHECK_FILES(vcf_ch, legend_ch)
} 