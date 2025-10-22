# Quick Start

This guide will help you run CheckRef quickly with minimal setup. For detailed instructions, see the [full installation guide](/guide/installation).

## Prerequisites

Ensure you have:
- Nextflow (≥21.04.0) installed
- Docker or Singularity installed
- Your VCF files and reference legend files ready

## Try with Test Data

The fastest way to test CheckRef is with our sample data:

### Step 1: Download CheckRef with Test Data

```bash
# Clone the repository
git clone https://github.com/AfriGen-D/checkref.git
cd checkref

# Test data is included in test_data/
ls test_data/
```

### Step 2: Run with Test Data

```bash
nextflow run main.nf \
    --targetVcfs "test_data/chr22/*.vcf.gz" \
    --referenceDir "test_data/reference/" \
    --legendPattern "*.legend.gz" \
    --fixMethod remove \
    --outdir test_results \
    -profile docker
```

Expected runtime: ~2-5 minutes

### Step 3: Check Results

```bash
ls test_results/
# You should see:
# - chr22_allele_switch_results.tsv
# - chr22_allele_switch_summary.txt
# - chr22.noswitch.vcf.gz
# - all_chromosomes_summary.txt
```

## Running with Your Data

### Step 1: Prepare Your Data

Organize your files:
```
/path/to/data/
├── vcf_files/
│   ├── sample_chr1.vcf.gz
│   ├── sample_chr2.vcf.gz
│   └── ...
└── reference_legends/
    ├── ref_chr1.legend.gz
    ├── ref_chr2.legend.gz
    └── ...
```

### Step 2: Run the Pipeline

**Remove switched sites** (default):
```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "/path/to/vcf_files/*.vcf.gz" \
    --referenceDir "/path/to/reference_legends/" \
    --fixMethod remove \
    --outdir results \
    -profile docker
```

**Correct switched sites**:
```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "/path/to/vcf_files/*.vcf.gz" \
    --referenceDir "/path/to/reference_legends/" \
    --fixMethod correct \
    --outdir results \
    -profile docker
```

### Step 3: Check Results

Results will be in the `results/` directory:
```
results/
├── allele_switch_results/     # TSV files with detected switches
├── summary_files/             # Summary reports
├── fixed_vcfs/                # Corrected/cleaned VCF files
└── logs/                      # Validation and verification logs
```

## Example Commands

### Single Chromosome (Test Data)

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "test_data/chr22/chr22_sample.vcf.gz" \
    --referenceDir "test_data/reference/" \
    --legendPattern "*.legend.gz" \
    --outdir chr22_results \
    -profile docker
```

### Your Own Data - Single Chromosome

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "your_chr22.vcf.gz" \
    --referenceDir "/path/to/reference/legends/" \
    --outdir chr22_results \
    -profile docker
```

### Multiple Files (Comma-Separated)

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "chr1.vcf.gz,chr2.vcf.gz,chr3.vcf.gz" \
    --referenceDir "/path/to/reference/legends/" \
    --outdir results \
    -profile docker
```

### Glob Pattern (Multiple Chromosomes)

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "/path/to/vcfs/sample_chr*.vcf.gz" \
    --referenceDir "/path/to/reference/legends/" \
    --outdir results \
    -profile docker
```

### Using Singularity (HPC)

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/path/to/reference/" \
    --outdir results \
    -profile singularity
```

### Resume Failed Run

If the pipeline fails or is interrupted, resume from where it left off:

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/reference/" \
    --outdir results \
    -profile docker \
    -resume
```

## Understanding Output

### Allele Switch Results

The `*_allele_switch_results.tsv` files contain detected switches:

| Column | Description |
|--------|-------------|
| CHR | Chromosome |
| POS | Position |
| ALLELE_INFO | VCF alleles vs Reference alleles |

Example:
```
CHR    POS       ALLELE_INFO
chr1   100000    A>G|G>A
chr1   150000    C>T|T>C
```

### Summary Files

The `all_chromosomes_summary.txt` provides aggregated statistics:
- Total variants processed
- Common variants between VCF and reference
- Number of matched variants
- Number of switched alleles
- Overlap percentages

### Fixed VCFs

Depending on `--fixMethod`:

**remove** mode:
- Produces `*.noswitch.vcf.gz` files
- Problematic sites removed
- File size smaller than original

**correct** mode:
- Produces `*.corrected.vcf.gz` files
- REF↔ALT alleles swapped
- Sites marked with `SWITCHED=1` in INFO field
- Same number of variants as original

## Next Steps

- [Configuration](/guide/configuration) - Customize pipeline settings
- [Input Files](/guide/input-files) - Detailed input requirements
- [Output Files](/guide/output-files) - Complete output description
- [Parameters](/api/parameters) - All available parameters
- [Examples](/examples/) - More advanced usage examples

## Common Issues

### No VCF files found

**Error**: `No reference legend files found`

**Solution**: Check that:
1. Path to VCF files is correct
2. Files match the glob pattern
3. Use quotes around patterns: `"*.vcf.gz"`

### Chromosome mismatch

**Error**: No matching legend file found for chromosome

**Solution**: Ensure chromosome naming is consistent:
- VCF: `chr1.vcf.gz` → Legend: `chr1.legend.gz`
- Or VCF: `1.vcf.gz` → Legend: `1.legend.gz`

### Build mismatch detected

**Message**: Genome build mismatch detected

**Solution**: Ensure VCF and legend files use the same genome build (both hg19 or both hg38). Use liftOver to convert if needed.

For more troubleshooting, see the [Troubleshooting Guide](/guide/troubleshooting).
