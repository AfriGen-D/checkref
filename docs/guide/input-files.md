# Input Files

CheckRef requires two types of input files: target VCF files and reference legend files. This guide explains the requirements and formats for each.

## Target VCF Files

### Format Requirements

- **File format**: VCF (Variant Call Format) version 4.0 or later
- **Compression**: gzipped (`.vcf.gz`) recommended
- **Index**: Not required (but `.tbi` index is preserved if present)
- **Chromosome naming**: Must be consistent across all files

### Supported Chromosome Naming

CheckRef automatically detects chromosomes from filenames using these patterns:

✅ **Supported formats**:
- `chr1`, `chr2`, ..., `chr22`, `chrX`, `chrY`, `chrMT`
- `1`, `2`, ..., `22`, `X`, `Y`, `MT`
- `sample_chr1.vcf.gz`
- `data.chr22.vcf.gz`
- `chr1_filtered.vcf.gz`

### VCF File Structure

Minimal required columns:
```
#CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO    FORMAT  SAMPLE1
chr1    100000  rs123   A       G       .       PASS    .       GT      0/1
chr1    150000  rs456   C       T       .       PASS    .       GT      1/1
```

### Input Methods

**Method 1: Glob pattern** (recommended for multiple files):
```bash
--targetVcfs "/path/to/vcfs/*.vcf.gz"
```

**Method 2: Comma-separated list**:
```bash
--targetVcfs "chr1.vcf.gz,chr2.vcf.gz,chr3.vcf.gz"
```

**Method 3: Single file**:
```bash
--targetVcfs "chromosome_22.vcf.gz"
```

## Reference Legend Files

### Format Requirements

- **File format**: Space or tab-delimited text file
- **Compression**: gzipped (`.legend.gz`) recommended
- **Header**: Required (column names)
- **Chromosome naming**: Must match VCF files

### Legend File Structure

**Standard format** (1000 Genomes style):
```
id          position  a0  a1
1:100000:A:G  100000   A   G
1:150000:C:T  150000   C   T
```

**Alternative format** (with CHROM column):
```
CHROM  POS     ID            REF  ALT
chr1   100000  1:100000:A:G  A    G
chr1   150000  1:150000:C:T  C    T
```

### Supported Column Names

CheckRef recognizes various column naming schemes:

| Data Type | Recognized Names |
|-----------|------------------|
| Chromosome | `CHROM`, `CHR` (optional) |
| Position | `POS`, `POSITION` |
| Reference | `REF`, `A0` |
| Alternate | `ALT`, `A1` |
| ID | `ID`, `SNP` |

### Legend File Requirements

- ✅ Must have header line
- ✅ Must contain position, reference, and alternate alleles
- ✅ Chromosome can be in ID field or separate column
- ✅ Can be gzipped or uncompressed

## File Organization

### Recommended Directory Structure

```
project/
├── target_vcfs/
│   ├── sample_chr1.vcf.gz
│   ├── sample_chr2.vcf.gz
│   ├── sample_chr3.vcf.gz
│   └── ...
└── reference_panels/
    ├── ref_panel_chr1.legend.gz
    ├── ref_panel_chr2.legend.gz
    ├── ref_panel_chr3.legend.gz
    └── ...
```

### Chromosome Matching

CheckRef automatically matches VCF and legend files by chromosome:

✅ **Correct matching**:
- VCF: `sample_chr1.vcf.gz` ↔ Legend: `ref_chr1.legend.gz`
- VCF: `data_1.vcf.gz` ↔ Legend: `panel_1.legend.gz`
- VCF: `chr22.vcf.gz` ↔ Legend: `chr22.legend.gz`

❌ **Mismatched formats** (won't pair):
- VCF: `sample_chr1.vcf.gz` ↔ Legend: `panel_1.legend.gz`
  (one uses 'chr' prefix, other doesn't)

### Legend Pattern

By default, CheckRef looks for `*.legend.gz` files. Customize with:

```bash
--legendPattern "*.legend.txt.gz"
--legendPattern "reference_*.legend.gz"
```

## Data Quality Checks

CheckRef performs automatic validation:

### VCF Validation

1. **File integrity**: Checks gzip compression
2. **Format compliance**: Validates VCF structure with bcftools
3. **Emptiness check**: Ensures file contains variant data
4. **Size check**: Detects suspiciously small files

### Build Compatibility

CheckRef checks for genome build mismatches:

- ✅ **Compatible**: Both files use same reference positions
- ❌ **Incompatible**: Reference alleles at same position differ
  - Example: Position 100000 is `A` in VCF but `G` in legend
  - Likely indicates hg19 vs hg38 mismatch

If a build mismatch is detected, the pipeline gracefully exits with a helpful message.

## Example Input Files

### Example VCF (target_chr22.vcf.gz)

```vcf
##fileformat=VCFv4.2
##contig=<ID=chr22>
##INFO=<ID=AF,Number=A,Type=Float,Description="Allele Frequency">
#CHROM  POS      ID         REF  ALT  QUAL  FILTER  INFO        FORMAT  SAMPLE1
chr22   16050036 rs587697622 A    G    .     PASS    AF=0.1      GT      0/1
chr22   16050115 rs9605903   C    T    .     PASS    AF=0.25     GT      1/1
chr22   16050213 rs5747620   G    A    .     PASS    AF=0.05     GT      0/0
```

### Example Legend (ref_chr22.legend.gz)

```
id                  position  a0  a1
22:16050036:A:G     16050036  A   G
22:16050115:C:T     16050115  C   T
22:16050213:G:A     16050213  G   A
22:16050400:T:C     16050400  T   C
```

## Preparing Your Data

### From PLINK Binary Files

Convert PLINK files to VCF:
```bash
plink --bfile mydata \
      --recode vcf bgz \
      --out mydata_chr22
```

### Splitting Multi-Chromosome VCF

Split a whole-genome VCF by chromosome:
```bash
for chr in {1..22} X Y; do
    bcftools view -r chr${chr} \
             whole_genome.vcf.gz \
             -Oz -o chr${chr}.vcf.gz
    bcftools index -t chr${chr}.vcf.gz
done
```

### Extracting Legend from VCF

Create a legend file from a reference VCF:
```bash
bcftools query -f '%CHROM:%POS:%REF:%ALT\t%POS\t%REF\t%ALT\n' \
         reference.vcf.gz | \
         gzip > reference.legend.gz

# Add header
echo -e "id\tposition\ta0\ta1" | \
         cat - reference.legend.gz | \
         gzip > reference_with_header.legend.gz
```

## Troubleshooting Input Files

### VCF validation failures

Check file integrity:
```bash
# Test gzip compression
gunzip -t myfile.vcf.gz

# Validate VCF format
bcftools view -h myfile.vcf.gz

# Count variants
bcftools view -H myfile.vcf.gz | wc -l
```

### Chromosome not detected

Ensure chromosome is in filename:
```bash
# Good filenames
sample_chr22.vcf.gz
data.chr1.vcf.gz
22.vcf.gz

# Bad filenames (won't auto-detect)
sample.vcf.gz
mydata.vcf.gz
```

### Legend file format issues

Validate legend structure:
```bash
# Check header
zcat reference.legend.gz | head -1

# Check columns
zcat reference.legend.gz | head -5 | column -t

# Ensure space/tab delimited
zcat reference.legend.gz | head | cat -A
```

## Next Steps

- [Running the Pipeline](/guide/running) - Execute CheckRef
- [Output Files](/guide/output-files) - Understanding results
- [Examples](/examples/) - Example datasets and commands
