# CheckRef Test Data

This directory contains sample test data for trying out the CheckRef pipeline.

## Contents

### chr22/

Sample target VCF files for chromosome 22:

- `chr22_sample.vcf.gz` - Sample VCF file with ~1000 variants from chromosome 22 (hg38)

### reference/

Sample reference panel legend files:

- `chr22_sample.legend.gz` - Sample reference legend file for chromosome 22

## Data Source

The test data is derived from:

- **Target VCF**: Real genomic data from chromosome 22 (hg38 build)
- **Reference Panel**: V7HC-S reference panel (AfriGen-D/H3Africa)

## Quick Test

Run CheckRef with this test data:

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "test_data/chr22/*.vcf.gz" \
    --referenceDir "test_data/reference/" \
    --legendPattern "*.legend.gz" \
    --fixMethod remove \
    --outdir test_results \
    -profile docker
```

## Expected Results

The sample data should produce:

- Allele switch detection results
- Summary statistics
- Cleaned VCF file (with --fixMethod remove) or corrected VCF file (with --fixMethod correct)

## Full Test Data

For comprehensive testing, the full chr22 dataset is available:

- Full VCF: Contact AfriGen-D or check the AfriGen-D data repositories
- Full reference panels: Available through H3Africa reference panel distributions

## Data Format

### Target VCF Format

Standard VCF 4.2 format with:

- CHROM, POS, ID, REF, ALT, QUAL, FILTER, INFO columns
- Must be bgzipped and indexed

### Reference Legend Format

Legend file format with columns:

- `id` - Variant identifier
- `position` - Genomic position
- `a0` - Allele 0 (reference)
- `a1` - Allele 1 (alternate)

## Notes

- Sample data is provided for quick testing only
- For production use, use complete chromosome VCF files
- Ensure genome builds match between target and reference (both hg38 or both hg19)
