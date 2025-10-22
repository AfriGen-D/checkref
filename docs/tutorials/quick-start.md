# Quick Start Tutorial

This tutorial will guide you through running CheckRef for the first time using our test data.

**Time Required**: 5-10 minutes

## Prerequisites

Before starting, ensure you have:
- ✅ Nextflow installed (version ≥21.04.0)
- ✅ Docker or Singularity installed
- ✅ Basic command line knowledge

If you haven't installed these yet, see the [Installation Guide](/guide/installation).

## Step 1: Get CheckRef and Test Data

You have two options:

### Option A: Clone Full Repository (Recommended)

```bash
# Clone repository - includes test data, source code, and docs
git clone https://github.com/AfriGen-D/checkref.git
cd checkref
```

### Option B: Download Test Data Only

If you only want to test CheckRef without cloning the full repository:

```bash
# Create directories
mkdir -p test_data/chr22 test_data/reference

# Download test data files (~30KB total)
wget https://raw.githubusercontent.com/AfriGen-D/checkref/main/test_data/chr22/chr22_sample.vcf.gz \
     -P test_data/chr22/

wget https://raw.githubusercontent.com/AfriGen-D/checkref/main/test_data/reference/chr22_sample.legend.gz \
     -P test_data/reference/
```

**Alternative with curl:**
```bash
curl -L https://raw.githubusercontent.com/AfriGen-D/checkref/main/test_data/chr22/chr22_sample.vcf.gz \
     --create-dirs -o test_data/chr22/chr22_sample.vcf.gz

curl -L https://raw.githubusercontent.com/AfriGen-D/checkref/main/test_data/reference/chr22_sample.legend.gz \
     --create-dirs -o test_data/reference/chr22_sample.legend.gz
```

## Step 2: Inspect Test Data

Let's look at what test data is included:

```bash
# List test data files
ls -lh test_data/chr22/
ls -lh test_data/reference/

# Peek at the VCF file
zcat test_data/chr22/chr22_sample.vcf.gz | head -n 20

# Peek at the legend file
zcat test_data/reference/chr22_sample.legend.gz | head -n 10
```

You should see:
- **VCF file**: Contains ~1000 variants from chromosome 22
- **Legend file**: Reference allele information

## Step 3: Run CheckRef

Run the pipeline with default settings (remove switched sites):

```bash
nextflow run main.nf \
    --targetVcfs "test_data/chr22/*.vcf.gz" \
    --referenceDir "test_data/reference/" \
    --legendPattern "*.legend.gz" \
    --fixMethod remove \
    --outdir tutorial_results \
    -profile docker
```

You'll see output like:
```
N E X T F L O W  ~  version 21.04.0
Launching `main.nf` [silly_curie] - revision: abc123

executor >  local (4)
[XX/YYYYYY] process > VALIDATE_VCF (chr22_sample.vcf.gz)     [100%] 1 of 1 ✔
[XX/YYYYYY] process > CHECK_ALLELE_SWITCH (chr22)            [100%] 1 of 1 ✔
[XX/YYYYYY] process > REMOVE_SWITCHED_SITES (chr22)          [100%] 1 of 1 ✔
[XX/YYYYYY] process > CREATE_SUMMARY                         [100%] 1 of 1 ✔

Completed at: 22-Oct-2025 12:00:00
Duration    : 2m 30s
CPU hours   : 0.1
Succeeded   : 4
```

## Step 4: Examine Results

Check what was created:

```bash
ls tutorial_results/
```

You should see:
```
chr22_allele_switch_results.tsv    # Detected allele switches
chr22_allele_switch_summary.txt    # Per-chromosome statistics
chr22.noswitch.vcf.gz              # Cleaned VCF file
chr22.noswitch.vcf.gz.tbi          # VCF index
all_chromosomes_summary.txt        # Overall summary
```

## Step 5: View the Summary

Let's see what CheckRef found:

```bash
cat tutorial_results/all_chromosomes_summary.txt
```

Example output:
```
==================================================
              ALLELE SWITCH SUMMARY
==================================================

Chromosome: chr22

Total variants in target VCF: 952
Total variants in reference: 987
Total variants at common positions: 845

Results:
  MATCH: 798 variants (94.44%)
  SWITCH: 12 variants (1.42%)
  COMPLEMENT: 20 variants (2.37%)
  OTHER: 15 variants (1.78%)

Overlap Statistics:
  Overlap with target VCF: 88.76%
  Overlap with reference: 85.61%
==================================================
```

## Step 6: Check Switched Variants

View which variants had allele switches:

```bash
cat tutorial_results/chr22_allele_switch_results.tsv
```

Example:
```
CHROM   POS       ALLELE_SWITCH
chr22   16050115  A>G|G>A
chr22   16050298  C>T|T>C
```

## Step 7: Try Correction Mode

Instead of removing switched sites, let's correct them:

```bash
nextflow run main.nf \
    --targetVcfs "test_data/chr22/*.vcf.gz" \
    --referenceDir "test_data/reference/" \
    --legendPattern "*.legend.gz" \
    --fixMethod correct \
    --outdir tutorial_results_corrected \
    -profile docker
```

This will create `chr22.corrected.vcf.gz` where REF↔ALT are swapped for switched sites.

## Understanding the Results

### MATCH
Variants where REF/ALT alleles match perfectly between your VCF and the reference.

### SWITCH
Variants where REF and ALT are flipped (e.g., your VCF has A>G, reference has G>A).

### COMPLEMENT
Variants on the opposite DNA strand (e.g., A↔T or C↔G).

### OTHER
Any other allele mismatch that doesn't fit the above categories.

## Next Steps

Now that you've run CheckRef successfully, you can:

1. **Use Your Own Data**: Replace test_data paths with your VCF files
2. **Learn More**: Check out [Output Files Guide](/guide/output-files)
3. **Scale Up**: See [Examples](/examples/) for running on multiple chromosomes
4. **Optimize**: Read [Configuration Guide](/guide/configuration) for customization

## Common Issues

### Pipeline hangs at validation

**Solution**: Check your VCF file is properly formatted and bgzipped:
```bash
bcftools view your_file.vcf.gz | head
```

### No matching legend file found

**Solution**: Ensure chromosome naming matches between VCF and legend files. Use `--legendPattern` to specify the pattern.

### Out of memory errors

**Solution**: Increase memory allocation:
```bash
nextflow run main.nf ... --max_memory '16.GB'
```

## Summary

Congratulations! You've successfully:
- ✅ Run CheckRef on test data
- ✅ Generated allele switch reports
- ✅ Created cleaned/corrected VCF files
- ✅ Understood the output format

You're now ready to use CheckRef with your own genomic data!
