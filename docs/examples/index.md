# Examples

Practical examples of using CheckRef in different scenarios.

## Test with Sample Data

Start with our included test data to verify your installation:

```bash
# Clone the repository
git clone https://github.com/AfriGen-D/checkref.git
cd checkref

# Run with test data (chr22 sample)
nextflow run main.nf \
    --targetVcfs "test_data/chr22/*.vcf.gz" \
    --referenceDir "test_data/reference/" \
    --legendPattern "*.legend.gz" \
    --fixMethod remove \
    --outdir test_results \
    -profile docker
```

**Expected Results:**
- Runtime: ~2-5 minutes
- Output: Allele switch results, summary, and cleaned VCF
- Use this to verify CheckRef works before using your own data

## Basic Examples

### Single Chromosome

Process a single chromosome:

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "sample_chr22.vcf.gz" \
    --referenceDir "/reference/legends/" \
    --outdir chr22_results \
    -profile docker
```

### Multiple Chromosomes (Glob Pattern)

Process all chromosomes at once:

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "/data/vcfs/sample_chr*.vcf.gz" \
    --referenceDir "/data/1000G_phase3/" \
    --outdir results \
    -profile docker
```

### Whole Genome

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "/data/vcfs/*.vcf.gz" \
    --referenceDir "/data/reference/" \
    --fixMethod correct \
    --outdir whole_genome_results \
    -profile docker
```

## Fix Method Comparison

### Remove Switched Sites (Default)

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/ref/" \
    --fixMethod remove \
    --outdir results_remove \
    -profile docker
```

**Output**: `*.noswitch.vcf.gz` (smaller files, problematic sites excluded)

### Correct Switched Sites

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/ref/" \
    --fixMethod correct \
    --outdir results_correct \
    -profile docker
```

**Output**: `*.corrected.vcf.gz` (same size, alleles fixed, marked with SWITCHED=1)

## HPC Examples

### SLURM Cluster

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "\$SCRATCH/vcfs/*.vcf.gz" \
    --referenceDir "\$SCRATCH/reference/" \
    --outdir "\$SCRATCH/results" \
    -profile singularity \
    -c slurm.config \
    -resume
```

**slurm.config**:
```groovy
process {
    executor = 'slurm'
    queue = 'batch'
    clusterOptions = '--account=genomics'
    memory = 8.GB
    time = 8.h
}
```

### PBS Cluster

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/project/reference/" \
    -profile singularity \
    -c pbs.config
```

## Advanced Examples

### Custom Legend Pattern

If your legend files have a different naming:

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/ref/" \
    --legendPattern "1000G_phase3_*.legend.gz" \
    -profile docker
```

### Custom Output Structure

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/ref/" \
    --outdir "/results/project_$(date +%Y%m%d)" \
    -profile docker
```

### High-Memory Configuration

For large VCF files:

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "large_*.vcf.gz" \
    --referenceDir "/ref/" \
    --maxMemory "32.GB" \
    --maxTime "24.h" \
    -profile docker
```

## Integration Examples

### Pre-Imputation QC

Use CheckRef before imputation:

```bash
# Step 1: Check allele switches
nextflow run AfriGen-D/checkref \
    --targetVcfs "target_chr*.vcf.gz" \
    --referenceDir "/1000G/" \
    --fixMethod correct \
    --outdir qc_results \
    -profile docker

# Step 2: Use corrected VCFs for imputation
impute2 \
    -m /1000G/genetic_map.txt \
    -g qc_results/fixed_vcfs/target_chr22.corrected.vcf.gz \
    -int 20.0e6 20.5e6 \
    -o imputed_chr22.gen
```

### Data Harmonization

Harmonize data across multiple cohorts:

```bash
# Cohort 1
nextflow run AfriGen-D/checkref \
    --targetVcfs "/cohort1/*.vcf.gz" \
    --referenceDir "/unified_reference/" \
    --outdir cohort1_harmonized \
    -profile docker

# Cohort 2
nextflow run AfriGen-D/checkref \
    --targetVcfs "/cohort2/*.vcf.gz" \
    --referenceDir "/unified_reference/" \
    --outdir cohort2_harmonized \
    -profile docker

# Now both cohorts are harmonized to the same reference
```

## Next Steps

- [Guide](/guide/getting-started) - Full documentation
- [Parameters](/api/parameters) - All available parameters
- [Troubleshooting](/guide/troubleshooting) - Common issues
