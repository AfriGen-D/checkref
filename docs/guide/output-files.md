# Output Files

CheckRef generates organized output files in four main directories. This guide explains each output type and how to interpret the results.

## Output Directory Structure

```
results/
├── allele_switch_results/      # Detected allele switches (TSV files)
├── summary_files/              # Summary reports and statistics
├── fixed_vcfs/                 # Corrected or cleaned VCF files
└── logs/                       # Validation and verification logs
    ├── validation/             # VCF validation reports
    └── verification/           # Post-correction verification
```

## Allele Switch Results

### Individual Chromosome Files

Location: `results/allele_switch_results/`

**Filename format**: `chr{N}_{sample}_allele_switch_results.tsv`

**Content**: Tab-separated file listing all detected allele switches

**Columns**:
| Column | Description | Example |
|--------|-------------|---------|
| CHR | Chromosome | `chr22` |
| POS | Position | `16050036` |
| ALLELE_INFO | VCF→Legend allele comparison | `A>G\|G>A` |

**Example**:
```tsv
CHR     POS        ALLELE_INFO
chr22   16050036   A>G|G>A
chr22   16050115   C>T|T>C
chr22   16050213   G>A|A>G
```

**Interpretation**:
- `A>G|G>A` means:
  - VCF has REF=A, ALT=G
  - Legend has REF=G, ALT=A
  - → Alleles are switched

### Allele Info Format

The `ALLELE_INFO` column uses the format: `VCF_REF>VCF_ALT|LEGEND_REF>LEGEND_ALT`

**Allele switch**:
```
A>G|G>A    # REF and ALT are swapped
C>T|T>C    # REF and ALT are swapped
```

**Build mismatch** (pipeline will exit):
```
A>G|T>C    # Different alleles entirely - indicates build mismatch
```

## Summary Files

### Per-Chromosome Summaries

Location: `results/summary_files/`

**Filename format**: `chr{N}_{sample}_allele_switch_summary.txt`

**Content**: Text summary of allele switch detection for one chromosome

**Example**:
```
====================================
ALLELE SWITCH SUMMARY
====================================
Chromosome: chr22
Target VCF: sample_chr22.vcf.gz
Reference: ref_chr22.legend.gz

Total variants in target VCF: 10000
Total variants in reference: 50000
Total variants at common positions: 9500

Allele Comparison Results:
  - Matched variants: 9400 (98.95%)
  - Switched alleles (written to file): 100 (1.05%)
  - Complementary strand issues: 0
  - Complement + switch issues: 0
  - Other inconsistencies: 0

Overlap Statistics:
  - Target VCF coverage: 9500/10000 (95.00%)
  - Reference coverage: 9500/50000 (19.00%)
```

### Aggregated Summary

**Filename**: `all_chromosomes_summary.txt`

**Content**: Combined statistics across all chromosomes

**Example**:
```
====================================
ALLELE SWITCH CHECKER SUMMARY
====================================

Processed files: 22

Individual Chromosome Results:
------------------------------------

Chromosome: chr1
  - Target variants: 15000
  - Common variants: 14500
  - Matched: 14350
  - Switched: 150

Chromosome: chr2
  - Target variants: 14000
  - Common variants: 13700
  - Matched: 13600
  - Switched: 100

...

====================================
AGGREGATED RESULTS (ALL CHROMOSOMES)
====================================

Total variants in all target VCFs: 300000
Total variants in reference: 1500000
Total variants at common positions: 285000

Overlap Statistics:
  - Target VCF coverage: 285000/300000 (95.00%)
  - Reference coverage: 285000/1500000 (19.00%)

Allele Comparison Results:
  - Matched variants: 282000 (98.95%)
  - Switched alleles: 3000 (1.05%)
  - Complementary strand issues: 0
  - Complement + switch issues: 0
  - Other inconsistencies: 0
```

### Extracted Reference Legends

**Filename format**: `chr{N}_{sample}_extracted.legend.gz`

**Content**: Reference legend file filtered to common positions with target VCF

**Use**: Can be used as input for downstream imputation pipelines

## Fixed VCF Files

Location: `results/fixed_vcfs/`

The output depends on the `--fixMethod` parameter:

### Remove Mode (Default)

**Filename format**: `chr{N}_{sample}.noswitch.vcf.gz`

**Content**: VCF file with switched sites removed

**Features**:
- All sites with allele switches are excluded
- File size smaller than original
- Includes `.tbi` index file

**Example**:
```bash
# Original VCF: 10,000 variants
# Switched sites: 100
# Output VCF: 9,900 variants
```

### Correct Mode

**Filename format**: `chr{N}_{sample}.corrected.vcf.gz`

**Content**: VCF file with alleles corrected (REF↔ALT swapped)

**Features**:
- Same number of variants as original
- REF and ALT alleles swapped for problematic sites
- Sites marked with `SWITCHED=1` in INFO field
- Includes `.tbi` index file

**Example VCF entry**:
```vcf
##INFO=<ID=SWITCHED,Number=0,Type=Flag,Description="Alleles were switched to match reference">
#CHROM  POS      ID    REF  ALT  QUAL  FILTER  INFO          FORMAT  SAMPLE
chr22   16050036 rs1   G    A    .     PASS    SWITCHED=1    GT      1/0
```

**Note**: Genotypes are automatically updated when alleles are switched.

## Log Files

### Validation Reports

Location: `results/logs/validation/`

**Filename format**: `chr{N}_validation_report.txt`

**Content**: Validation results for each input VCF file

**Example - Passed**:
```
====================================
VCF VALIDATION REPORT FOR CHR chr22
====================================
File: sample_chr22.vcf.gz
Validation Date: 2025-10-21

File size: 1234567 bytes
Data lines found: 10000

✅ VALIDATION PASSED: File appears to be valid
File format: Valid VCF
Compression: gzip compressed data
Status: Ready for processing
```

**Example - Failed**:
```
====================================
VCF VALIDATION REPORT FOR CHR chr22
====================================
File: sample_chr22.vcf.gz
Validation Date: 2025-10-21

❌ VALIDATION FAILED: File is too small (likely empty or corrupted)
Minimum expected size: 100 bytes
Actual size: 45 bytes

This file appears to be empty or severely corrupted.
Please check the file integrity and regenerate if necessary.
```

### Verification Reports

Location: `results/logs/verification/`

**Filename format**: `chr{N}_verification_results.txt`

**Content**: Verification that corrections were successful

**Example - Successful**:
```
====================================
VERIFICATION RESULTS FOR CHR chr22
====================================

✅ VERIFICATION PASSED: No allele switches detected in corrected VCF

Total switches found: 0
```

**Example - Failed**:
```
====================================
VERIFICATION RESULTS FOR CHR chr22
====================================

❌ VERIFICATION FAILED: 5 allele switches still present

Remaining switches:
CHR     POS        ALLELE_INFO
chr22   16050036   A>G|T>C

Total switches found: 5
```

## Correction Statistics

When using `--fixMethod correct`, additional statistics are generated:

Location: `results/logs/correction_stats.txt`

**Content**: Number of sites corrected vs failed per chromosome

**Example**:
```
Chr chr1: Corrected=150, Failed=0
Chr chr2: Corrected=100, Failed=0
Chr chr22: Corrected=50, Failed=2
```

**Note**: Failed corrections typically indicate build mismatches where REF alleles differ.

## Interpreting Results

### Healthy Results

**Indicators of good data quality**:
- ✅ High percentage of matched variants (>95%)
- ✅ Low percentage of switches (<5%)
- ✅ Zero complementary strand issues
- ✅ All VCF files pass validation
- ✅ All corrections verify successfully

### Warning Signs

**Indicators of potential issues**:
- ⚠️ High percentage of switches (>10%)
  - May indicate systematic strand issues
  - Check if VCF and reference use different strands
  
- ⚠️ Low target VCF coverage (<80%)
  - Many variants in VCF not in reference
  - May need different reference panel
  
- ⚠️ Complementary strand issues
  - Data may be on opposite DNA strands
  - Consider strand flipping
  
- ⚠️ Build mismatch detected
  - VCF and reference use different genome builds
  - Use liftOver to convert to matching build

### Critical Issues

**Requires immediate attention**:
- ❌ VCF validation failures
  - Fix or regenerate VCF files
  
- ❌ Verification failures after correction
  - Indicates bug or build mismatch
  - Report to CheckRef developers
  
- ❌ Genome build mismatch
  - Cannot proceed until files use same build

## Using Results Downstream

### For Imputation

Use the extracted legend files:
```bash
# Legend files are filtered to common positions
results/summary_files/chr{N}_extracted.legend.gz
```

### For Quality Control

Review the summary statistics:
```bash
# Check overall switch rate
grep "Switched alleles" results/summary_files/all_chromosomes_summary.txt

# Check per-chromosome rates
grep "Switched:" results/summary_files/*_summary.txt
```

### For Further Analysis

Use the corrected/cleaned VCF files:
```bash
# Corrected VCFs ready for downstream analysis
results/fixed_vcfs/*.corrected.vcf.gz
results/fixed_vcfs/*.noswitch.vcf.gz
```

## Next Steps

- [Troubleshooting](/guide/troubleshooting) - Resolve common issues
- [Examples](/examples/) - Example use cases
- [Parameters](/api/parameters) - Customize output options
