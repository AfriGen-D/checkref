# Allele Switch Checker Workflow

A Nextflow pipeline for checking allele switches between a target VCF and a reference panel legend file, with options to fix identified issues.

## Repository Structure

```text
checkref/
├── README.md                    # This file - main pipeline documentation
├── main.nf                     # Main Nextflow pipeline
├── direct.nf                   # Direct mode pipeline
├── minimal.nf                  # Minimal pipeline
├── nextflow.config             # Nextflow configuration
├── test.sh                     # Test script
├── bin/                        # Pipeline scripts and utilities
│   └── check_allele_switch.py  # Main allele switch checking script
├── results/                    # Test results and outputs
├── test_results/               # Test execution results
└── checkref-update-tools/      # Update and management tools
    ├── CHECKREF_UPDATE_README.md    # Detailed update tools documentation
    ├── check-checkref-version.sh    # Version checking script
    ├── update-checkref.sh           # Full-featured update script
    ├── quick-update-checkref.sh     # Simple update script
    ├── manage-checkref-config.sh    # Configuration management
    └── logs/                        # Update operation logs
        └── checkref-update.log      # Update log file
```

## Update Management

For updating the checkref application in production environments, use the tools in the `checkref-update-tools/` directory:

```bash
# Check current vs latest version
cd checkref-update-tools/
./check-checkref-version.sh

# Preview what an update would do
./update-checkref.sh --dry-run

# Perform the update
./update-checkref.sh
```

For detailed information about update tools, see [checkref-update-tools/CHECKREF_UPDATE_README.md](checkref-update-tools/CHECKREF_UPDATE_README.md).

## Overview

This workflow analyzes a target VCF file against a reference legend file to identify variants that have:
- Matching alleles
- Switched alleles (REF/ALT flipped)
- Complementary strand issues (A↔T, C↔G)
- Other inconsistencies

After identifying switched sites, the workflow can either:
1. Remove the problematic variants
2. Correct the alleles by swapping REF and ALT

## Requirements

- Nextflow (>=21.04.0)
- Python 3
- bcftools
- Docker or Singularity (optional)

## Usage

```bash
# Basic usage
nextflow run main.nf --targetVcf <path_to_target.vcf.gz> --referenceLegend <path_to_reference.legend.gz>

# Remove switched sites (default)
nextflow run main.nf --targetVcf <path_to_target.vcf.gz> --referenceLegend <path_to_reference.legend.gz> --fixMethod remove

# Correct switched sites by swapping REF/ALT
nextflow run main.nf --targetVcf <path_to_target.vcf.gz> --referenceLegend <path_to_reference.legend.gz> --fixMethod correct
```

### Required Parameters

- `--targetVcf`: Path to the target VCF file (can be gzipped)
- `--referenceLegend`: Path to the reference panel legend file (e.g., V6HC-S_chr22_all_sitesOnly.v2025.01.legend.gz)

### Optional Parameters

- `--outputDir`: Output directory (default: 'results')
- `--fixMethod`: Method to fix allele switches: 'remove' or 'correct' (default: 'remove')
- `--help`: Display help message

## Legend File Format

The reference legend file should be in the standard legend format with columns for:
- ID or variant identifier
- Position 
- Allele 0 (reference allele)
- Allele 1 (alternate allele)

Example legend file format:
```
id position a0 a1
rs12345 16050075 A G
rs67890 16050115 G A
```

The script will attempt to automatically detect the chromosome from the ID or filename.

## Methods

The workflow consists of several key processes that work together to identify and optionally fix allele switches:

### 1. CHECK_ALLELE_SWITCH Process

This is the core analysis process that compares target VCF files against reference legend files. The process:

- **Extracts variants**: Uses `bcftools` to extract SNP variants from the target VCF file, filtering out indels and complex variants
- **Parses reference data**: Reads the reference legend file (supports both gzipped and uncompressed formats) and automatically detects column structure
- **Chromosome matching**: Automatically detects chromosome information from filenames or variant IDs to match target and reference files
- **Allele comparison**: For each variant present in both files, compares the REF and ALT alleles and classifies them as:
  - **MATCH**: Identical alleles (REF₁=REF₂, ALT₁=ALT₂)
  - **SWITCH**: Flipped alleles (REF₁=ALT₂, ALT₁=REF₂) 
  - **COMPLEMENT**: Complementary strand (A↔T, C↔G transformations)
  - **COMPLEMENT_SWITCH**: Both complementary and switched
  - **OTHER**: Any other inconsistency

- **Output generation**: Creates two output files:
  - A detailed TSV file listing all switched variants with their allele information
  - A summary file with statistics about the comparison

### 2. REMOVE_SWITCHED_SITES Process

This process creates a "cleaned" VCF by removing problematic variants:

- **Site identification**: Reads the allele switch results from the CHECK_ALLELE_SWITCH process
- **Coordinate conversion**: Converts the 1-based coordinates from the results to 0-based BED format for bcftools
- **VCF filtering**: Uses `bcftools view` with the `-T ^exclude_sites.bed` option to remove variants at switched positions
- **Quality control**: Handles edge cases where no sites need to be excluded (copies original file)
- **Indexing**: Creates a tabix index (.tbi) for the output VCF for efficient access
- **Reporting**: Logs the number of sites removed for each chromosome

### 3. CORRECT_SWITCHED_SITES Process

This process fixes allele switches by swapping REF and ALT alleles:

- **Switch detection**: Parses the allele switch results to identify variants that need correction
- **Python correction script**: Dynamically generates a Python script that:
  - Reads the target VCF file (handles both gzipped and uncompressed formats)
  - For each variant marked as switched, swaps the REF and ALT alleles
  - Adds a `SWITCHED=1` flag to the INFO field to mark corrected variants
  - Preserves all other VCF information (genotypes, quality scores, etc.)
- **VCF processing**: Processes the entire VCF file while maintaining proper format
- **Sorting and indexing**: Uses `bcftools sort` to ensure proper coordinate order and creates an index
- **Validation**: Tracks and reports the number of successfully corrected variants

### 4. CREATE_SUMMARY Process

This process aggregates results across all processed chromosomes:

- **Summary collection**: Gathers individual chromosome summary files from the CHECK_ALLELE_SWITCH process
- **Report generation**: Creates a comprehensive summary report that includes:
  - Statistics for each chromosome processed
  - Overall counts of matched, switched, and problematic variants
  - Percentage breakdowns for each category
- **Formatting**: Produces a human-readable report with clear section headers and organized data

### Pipeline Logic Flow

1. **Input validation**: The workflow first validates that target VCF files and reference legend files are provided
2. **File matching**: Uses chromosome detection algorithms to automatically pair VCF files with their corresponding legend files
3. **Parallel processing**: Processes multiple chromosomes simultaneously for efficiency
4. **Conditional execution**: Runs either the REMOVE_SWITCHED_SITES or CORRECT_SWITCHED_SITES process based on the `--fixMethod` parameter
5. **Result aggregation**: Collects all individual results into a final summary report

### Quality Control Features

- **Error handling**: Gracefully handles missing files, malformed data, and edge cases
- **Logging**: Provides detailed logging for debugging and monitoring progress
- **Validation**: Includes checks for file integrity and expected formats
- **Flexible input**: Supports various chromosome naming conventions (chr1, 1, chrX, etc.)
- **Memory efficiency**: Processes large files without loading everything into memory

## Profiles

The workflow comes with several predefined profiles:

```bash
# Run locally
nextflow run main.nf -profile standard ...

# Run using Slurm
nextflow run main.nf -profile hpc ...

# Run with Docker
nextflow run main.nf -profile docker ...

# Run with Singularity
nextflow run main.nf -profile singularity ...
```

## Output Files

The pipeline produces:

### Check Phase:
- `<target_prefix>_allele_switch_results.tsv`: Tab-separated file with allele switches
- `<target_prefix>_allele_switch_summary.txt`: Summary statistics of the analysis

### Fix Phase:
When using `--fixMethod remove`:
- `<target_prefix>.noswitch.vcf.gz`: VCF with switched sites removed
- `<target_prefix>.noswitch.vcf.gz.tbi`: Index for the fixed VCF

When using `--fixMethod correct`:
- `<target_prefix>.corrected.vcf.gz`: VCF with corrected alleles (REF/ALT swapped)
- `<target_prefix>.corrected.vcf.gz.tbi`: Index for the corrected VCF

## Allele Switch Results Format

The allele switch results file includes:
```
CHROM   POS     ALLELE_SWITCH
chr22   22565895        A>G|G>A
```

Where:
- CHROM: Chromosome
- POS: Position (1-based)
- ALLELE_SWITCH: Shows format "TargetREF>TargetALT|ReferenceREF>ReferenceALT"

## Example Output Format

### allele_switch_results.tsv
```
CHROM   POS     TARGET_REF  TARGET_ALT  REF_REF  REF_ALT  STATUS
22      16050075        A       G        A       G       MATCH
22      16050115        G       A        A       G       SWITCH
22      16050213        C       T        G       A       COMPLEMENT
22      16050298        C       A        T       G       COMPLEMENT_SWITCH
```

### allele_switch_summary.txt
```
Results Summary:
Total variants at common positions: 1000
Matched variants: 850 (85.00%)
Switched alleles: 50 (5.00%)
Complementary strand issues: 80 (8.00%)
Complement + switch issues: 50 (5.00%)
Other inconsistencies: 20 (2.00%)
``` 

Example: 
nextflow run checkref/main.nf --targetVcfs "/home/ubuntu/devs/iscb-tutorial/chr*.vcf.gz" --referenceDir "/mnt/storage/imputationserver2/apps/h3africa/v6hc-s/sites/" --legendPattern "V6HC-S_chr1_all_sitesOnly.v2025.01.legend.gz"