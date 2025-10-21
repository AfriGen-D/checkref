#!/bin/bash

# Test script for Allele Switch Checker workflow
# This script tests the workflow with sample data

set -e

# Print usage information
function usage {
  echo "Usage: ./test.sh [--help]"
  echo ""
  echo "This script runs a test of the Allele Switch Checker workflow using sample VCF files."
  echo ""
  echo "Options:"
  echo "  --help    Show this help message"
  exit 1
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --help)
      usage
      ;;
    *)
      echo "Unknown option: $key"
      usage
      ;;
  esac
  shift
done

# Define test data paths
TARGET_VCF="/home/ubuntu/devs/test_data/chr22.fixed.vcf.gz.lifted.vcf.gz"
REFERENCE_LEGEND="/mnt/storage/imputationserver2/apps/h3africa/v6hc-s/sitesV6HC-S_chr22_all_sitesOnly.v2025.01.legend.gz"
# Fall back to 1KG VCF if the legend file doesn't exist
if [ ! -f "$REFERENCE_LEGEND" ]; then
  REFERENCE_LEGEND="../iscb-tutorial/1KG.EAS.auto.snp.norm.nodup.split.rare002.common015.missing.vcf.gz"
  echo "Legend file not found, using reference VCF instead: $REFERENCE_LEGEND"
fi
OUTPUT_DIR="test_results"

# Check if test files exist
if [ ! -f "$TARGET_VCF" ]; then
  echo "Error: Target VCF file not found at $TARGET_VCF"
  exit 1
fi

if [ ! -f "$REFERENCE_LEGEND" ]; then
  echo "Error: Reference legend/VCF file not found at $REFERENCE_LEGEND"
  exit 1
fi

# Check if the script exists in bin directory
if [ ! -f "bin/check_allele_switch.py" ]; then
  echo "Error: Script not found at bin/check_allele_switch.py"
  exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "Starting Allele Switch Checker workflow test..."
echo "Target VCF: $TARGET_VCF"
echo "Reference Legend: $REFERENCE_LEGEND"
echo "Output directory: $OUTPUT_DIR"

# Run the Nextflow workflow
nextflow run main.nf \
  --targetVcf "$TARGET_VCF" \
  --referenceLegend "$REFERENCE_LEGEND" \
  --outputDir "$OUTPUT_DIR" \
  -profile standard \
  -resume

# Check if the workflow completed successfully
if [ $? -eq 0 ]; then
  echo "Test completed successfully!"
  echo "Results are available in $OUTPUT_DIR directory"
else
  echo "Test failed!"
  exit 1
fi 