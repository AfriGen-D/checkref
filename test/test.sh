#!/bin/bash

# Test script for Allele Switch Checker Pipeline
# This script runs automated tests to verify pipeline functionality

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIPELINE_DIR="$(dirname "$TEST_DIR")"
TEST_OUTPUT_DIR="$TEST_DIR/test_output"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo -e "${YELLOW}======================================${NC}"
echo -e "${YELLOW}  Allele Switch Checker Pipeline Test${NC}"
echo -e "${YELLOW}======================================${NC}"
echo ""

# Function to print test status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
        exit 1
    fi
}

# Function to cleanup test outputs
cleanup() {
    echo -e "${YELLOW}Cleaning up previous test outputs...${NC}"
    rm -rf "$TEST_OUTPUT_DIR"
    rm -rf "$PIPELINE_DIR/work/.nextflow*"
    mkdir -p "$TEST_OUTPUT_DIR"
}

# Test 1: Check pipeline dependencies
echo -e "${YELLOW}Test 1: Checking pipeline dependencies...${NC}"
cd "$PIPELINE_DIR"

# Check if main.nf exists
[ -f "main.nf" ]
print_status $? "main.nf exists"

# Check if nextflow.config exists
[ -f "nextflow.config" ]
print_status $? "nextflow.config exists"

# Check if Python script exists
[ -f "bin/check_allele_switch.py" ]
print_status $? "check_allele_switch.py exists"

# Check Nextflow version
nextflow -version >/dev/null 2>&1
print_status $? "Nextflow is available"

echo ""

# Test 2: Run pipeline with chr22 test data
echo -e "${YELLOW}Test 2: Running pipeline with chr22 test data...${NC}"

cleanup

# Run the pipeline
nextflow run main.nf \
  --targetVcfs "/cbio/dbs/refpanels/test_data/chr22.hg38/chr22.hg38.vcf.gz" \
  --referenceDir "/cbio/dbs/refpanels/h3a_reference_panels/version_7/v7hc_s/sites/" \
  --legendPattern "*chr22*.legend.gz" \
  --outputDir "$TEST_OUTPUT_DIR" \
  --max_cpus 2 \
  --max_memory '4.GB' \
  -profile singularity \
  > "$TEST_OUTPUT_DIR/pipeline_${TIMESTAMP}.log" 2>&1

print_status $? "Pipeline execution completed"

# Test 3: Verify output files
echo -e "${YELLOW}Test 3: Verifying output files...${NC}"

# Check if summary file exists
[ -f "$TEST_OUTPUT_DIR/all_chromosomes_summary.txt" ]
print_status $? "Summary file generated"

# Check if allele switch results exist
[ -f "$TEST_OUTPUT_DIR/chr22_allele_switch_results.tsv" ]
print_status $? "Allele switch results generated"

# Check if cleaned VCF exists
[ -f "$TEST_OUTPUT_DIR/chr22.noswitch.vcf.gz" ]
print_status $? "Cleaned VCF generated"

# Check if detailed summary exists
[ -f "$TEST_OUTPUT_DIR/chr22_allele_switch_summary.txt" ]
print_status $? "Detailed summary generated"

# Test 4: Verify overlap percentages in summary
echo -e "${YELLOW}Test 4: Verifying overlap percentages in summary...${NC}"

# Check if overlap percentages are present
grep -q "Overlap with target VCF:" "$TEST_OUTPUT_DIR/all_chromosomes_summary.txt"
print_status $? "Target VCF overlap percentage present"

grep -q "Overlap with reference:" "$TEST_OUTPUT_DIR/all_chromosomes_summary.txt"
print_status $? "Reference overlap percentage present"

# Check if total variant counts are present
grep -q "Total variants in target VCF:" "$TEST_OUTPUT_DIR/all_chromosomes_summary.txt"
print_status $? "Total target variants count present"

grep -q "Total variants in reference:" "$TEST_OUTPUT_DIR/all_chromosomes_summary.txt"
print_status $? "Total reference variants count present"

# Test 5: Verify numeric results make sense
echo -e "${YELLOW}Test 5: Verifying numeric results...${NC}"

# Extract key numbers from summary
TOTAL_TARGET=$(grep "Total variants in target VCF:" "$TEST_OUTPUT_DIR/all_chromosomes_summary.txt" | grep -o '[0-9]\+')
TOTAL_REF=$(grep "Total variants in reference:" "$TEST_OUTPUT_DIR/all_chromosomes_summary.txt" | grep -o '[0-9]\+')
COMMON=$(grep "Total variants at common positions:" "$TEST_OUTPUT_DIR/all_chromosomes_summary.txt" | grep -o '[0-9]\+')

# Verify that common <= target and common <= reference
[ "$COMMON" -le "$TOTAL_TARGET" ]
print_status $? "Common variants ≤ target variants ($COMMON ≤ $TOTAL_TARGET)"

[ "$COMMON" -le "$TOTAL_REF" ]
print_status $? "Common variants ≤ reference variants ($COMMON ≤ $TOTAL_REF)"

# Verify we have reasonable numbers (not zero)
[ "$TOTAL_TARGET" -gt 0 ]
print_status $? "Target variants > 0 ($TOTAL_TARGET)"

[ "$COMMON" -gt 0 ]
print_status $? "Common variants > 0 ($COMMON)"

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  ALL TESTS PASSED SUCCESSFULLY!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo "Test output directory: $TEST_OUTPUT_DIR"
echo "Pipeline log: $TEST_OUTPUT_DIR/pipeline_${TIMESTAMP}.log"
echo ""

# Display summary of results
echo -e "${YELLOW}Test Results Summary:${NC}"
echo "- Total variants in target: $TOTAL_TARGET"
echo "- Total variants in reference: $TOTAL_REF"  
echo "- Common variants: $COMMON"
echo "- Target overlap: $(echo "scale=2; $COMMON * 100 / $TOTAL_TARGET" | bc -l)%"
echo "- Reference overlap: $(echo "scale=2; $COMMON * 100 / $TOTAL_REF" | bc -l)%"

exit 0