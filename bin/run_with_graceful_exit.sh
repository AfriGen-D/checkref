#!/bin/bash

# Wrapper script to run CheckRef with graceful exit handling
# Usage: run_with_graceful_exit.sh <target_vcf> <reference_legend> <output_file> <summary_file>

TARGET_VCF="$1"
REFERENCE_LEGEND="$2"
OUTPUT_FILE="$3"
SUMMARY_FILE="$4"

# Run the allele switch checker
python3 /users/mamana/checkref/bin/check_allele_switch.py "$TARGET_VCF" "$REFERENCE_LEGEND" "$OUTPUT_FILE" --legend > "$SUMMARY_FILE"

# Check if build mismatch was detected
if [ -f "BUILD_MISMATCH_DETECTED" ]; then
    # Display the graceful exit message
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════════════════╗"
    echo "║                           WORKFLOW TERMINATED                                 ║"
    echo "║                        Genome Build Mismatch Detected                         ║"
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
    
    # Clean up the marker file
    rm -f BUILD_MISMATCH_DETECTED
    
    # Exit cleanly - let Nextflow handle the termination
    exit 0
else
    echo "Analysis completed successfully"
    exit 0
fi
