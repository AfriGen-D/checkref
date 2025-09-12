# Allele Switch Checker Workflow

A Nextflow pipeline for checking allele switches between a target VCF and a reference panel legend file, with options to fix identified issues.

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

### Single File Usage

```bash
# Basic usage
nextflow run main.nf --targetVcfs <path_to_target.vcf.gz> --referenceDir <path_to_reference_dir>

# Remove switched sites (default)
nextflow run main.nf --targetVcfs <path_to_target.vcf.gz> --referenceDir <path_to_reference_dir> --fixMethod remove

# Correct switched sites by swapping REF/ALT
nextflow run main.nf --targetVcfs <path_to_target.vcf.gz> --referenceDir <path_to_reference_dir> --fixMethod correct
```

### Multi-File Usage

The pipeline supports processing multiple VCF files simultaneously with automatic chromosome detection and reference matching.

#### Method 1: Comma-Separated List
```bash
nextflow run main.nf \
  --targetVcfs "file1.vcf.gz,file2.vcf.gz,file3.vcf.gz" \
  --referenceDir "/path/to/reference/panels/" \
  --outputDir results_multi \
  --fixMethod correct \
  -profile singularity
```

#### Method 2: Glob Pattern
```bash
# Process all VCF files in a directory
nextflow run main.nf \
  --targetVcfs "/path/to/vcfs/*.vcf.gz" \
  --referenceDir "/path/to/reference/panels/" \
  --outputDir results_glob \
  --fixMethod correct \
  -profile singularity

# Alternative: use quoted glob patterns
nextflow run main.nf \
  --targetVcfs "sample_*.vcf.gz" \
  --referenceDir "/path/to/reference/panels/" \
  --outputDir results_pattern \
  --fixMethod correct \
  -profile singularity
```

**Note**: Both `--targetVcfs "file*.vcf.gz"` (glob pattern) and `--targetVcfs "file1.vcf.gz,file2.vcf.gz"` (comma-separated) work equivalently.

#### Method 3: Specific Pattern Matching
```bash
# Process specific chromosome patterns
nextflow run main.nf \
  --targetVcfs "/data/vcfs/sample_chr*.vcf.gz" \
  --referenceDir "/data/reference_panels/" \
  --outputDir results_pattern \
  --fixMethod correct \
  -profile singularity
```

#### Method 4: Multiple Specific Files
```bash
# Process specific files from different locations
nextflow run main.nf \
  --targetVcfs "/path1/chr20.vcf.gz,/path2/chr21.vcf.gz,/path3/chr22.vcf.gz" \
  --referenceDir "/path/to/reference/panels/" \
  --outputDir results_mixed \
  --fixMethod correct \
  -profile singularity
```

#### Complete Multi-File Example
```bash
nextflow run main.nf \
  --targetVcfs "sample_chr20.vcf.gz,sample_chr21.vcf.gz,sample_chr22.vcf.gz" \
  --referenceDir "/cbio/dbs/refpanels/h3a_reference_panels/version_7/v7hc_s/sites/" \
  --legendPattern "*chr*.legend.gz" \
  --outputDir my_results \
  --fixMethod correct \
  --max_cpus 4 \
  --max_memory '8.GB' \
  -profile singularity \
  -resume
```

### Required Parameters

- `--targetVcfs`: Path(s) to target VCF file(s). Supports:
  - Single file: `/path/to/file.vcf.gz`
  - Multiple files: `"file1.vcf.gz,file2.vcf.gz,file3.vcf.gz"`
  - Glob patterns: `"/path/to/*.vcf.gz"`
- `--referenceDir`: Directory containing reference panel legend files

### Optional Parameters

- `--legendPattern`: Pattern to match legend files (default: '*.legend.gz')
- `--outputDir`: Output directory (default: 'results')  
- `--fixMethod`: Method to fix allele switches: 'remove' or 'correct' (default: 'remove')
- `--max_cpus`: Maximum number of CPUs to use
- `--max_memory`: Maximum memory to allocate
- `--help`: Display help message

### Multi-File Processing Features

- **Automatic Chromosome Detection**: Extracts chromosome information from filenames (e.g., `chr20`, `chr21`)
- **Reference Panel Matching**: Automatically matches each VCF with corresponding reference legend files
- **Parallel Processing**: Processes all chromosomes simultaneously for optimal performance
- **Individual Results**: Creates separate results for each chromosome
- **Combined Reporting**: Generates unified summary across all processed files
- **Verification**: Automatically verifies corrections for each chromosome

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

### Single File Processing

The pipeline produces:

#### Check Phase:
- `<target_prefix>_allele_switch_results.tsv`: Tab-separated file with allele switches
- `<target_prefix>_allele_switch_summary.txt`: Summary statistics of the analysis

#### Fix Phase:
When using `--fixMethod remove`:
- `<target_prefix>.noswitch.vcf.gz`: VCF with switched sites removed
- `<target_prefix>.noswitch.vcf.gz.tbi`: Index for the fixed VCF

When using `--fixMethod correct`:
- `<target_prefix>.corrected.vcf.gz`: VCF with corrected alleles (REF/ALT swapped)
- `<target_prefix>.corrected.vcf.gz.tbi`: Index for the corrected VCF

### Multi-File Processing

When processing multiple files, the output directory contains:

#### Individual Chromosome Results:
```
results/
├── chr20_allele_switch_results.tsv          # Chr20 switch results
├── chr20_allele_switch_summary.txt          # Chr20 summary
├── chr20.corrected.vcf.gz                   # Chr20 corrected VCF
├── chr20.corrected.vcf.gz.tbi               # Chr20 VCF index
├── chr21_allele_switch_results.tsv          # Chr21 switch results  
├── chr21_allele_switch_summary.txt          # Chr21 summary
├── chr21.corrected.vcf.gz                   # Chr21 corrected VCF
├── chr21.corrected.vcf.gz.tbi               # Chr21 VCF index
├── ...
```

#### Aggregated Results:
```
results/
├── all_chromosomes_summary.txt              # Combined summary for all chromosomes
├── correction_stats.txt                     # Correction statistics per chromosome
├── fixed_count.txt                          # Total sites corrected
├── failed_count.txt                         # Total sites that failed correction
├── verification/                            # Verification results directory
│   ├── chr20_verification_results.txt       # Chr20 verification report
│   ├── chr21_verification_results.txt       # Chr21 verification report
│   └── ...
└── reports/                                 # Execution reports
    └── ...
```

#### Output Summary Example:
```
Test Results Summary:
- Total variants in target: 1321
- Total variants in reference: 1741597  
- Common variants: 24
- Matched variants: 4
- Switched alleles: 4
- Sites corrected: 4
- Sites failed to correct: 0
- Sites remaining after correction: 1321
- Target overlap: 1.82%
- Reference overlap: 0.00%

✓ Corrections verified for chr21
✓ Corrections verified for chr20
✅ ALL CORRECTIONS VERIFIED SUCCESSFULLY
```

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

## Examples

### Single Chromosome Example:
```bash
nextflow run main.nf \
  --targetVcfs "/cbio/dbs/refpanels/test_data/chr22.hg38/chr22.hg38.vcf.gz" \
  --referenceDir "/cbio/dbs/refpanels/h3a_reference_panels/version_7/v7hc_s/sites/" \
  --legendPattern "*chr22*.legend.gz" \
  --outputDir test_chr22_output \
  --fixMethod correct \
  -profile singularity
```

### Multi-Chromosome Example:
```bash
nextflow run main.nf \
  --targetVcfs "/cbio/dbs/refpanels/test_data/test_datasets/test_data/tiny/VCF/tiny_ref_chr20_1000000_1030000.vcf.gz,/cbio/dbs/refpanels/test_data/test_datasets/test_data/tiny/VCF/tiny_ref_chr21_1000000_1030000.vcf.gz" \
  --referenceDir "/cbio/dbs/refpanels/h3a_reference_panels/version_7/v7hc_s/sites/" \
  --legendPattern "*chr*.legend.gz" \
  --outputDir test_multi_output \
  --fixMethod correct \
  --max_cpus 4 \
  --max_memory '8.GB' \
  -profile singularity
```

### Using Glob Patterns:
```bash
nextflow run main.nf \
  --targetVcfs "/home/ubuntu/devs/iscb-tutorial/chr*.vcf.gz" \
  --referenceDir "/mnt/storage/imputationserver2/apps/h3africa/v6hc-s/sites/" \
  --legendPattern "V6HC-S_chr*_all_sitesOnly.v2025.01.legend.gz" \
  --outputDir results \
  --fixMethod correct \
  -profile singularity
```