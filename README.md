# CheckRef

A Nextflow pipeline for detecting and correcting allele switches between target VCF files and reference panels.

[![Documentation](https://img.shields.io/badge/docs-checkref--docs-blue)](https://afrigen-d.github.io/checkref-docs/)
[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A521.04.0-23aa62.svg)](https://www.nextflow.io/)

## Quick Start

```bash
# Clone and run
git clone https://github.com/AfriGen-D/checkref.git
cd checkref

# Single file
nextflow run main.nf \
  --targetVcfs your_file.vcf.gz \
  --referenceDir /path/to/reference/panels/ \
  --outputDir results \
  -profile singularity

# Multiple files
nextflow run main.nf \
  --targetVcfs "chr*.vcf.gz" \
  --referenceDir /path/to/reference/panels/ \
  --fixMethod correct \
  -profile singularity
```

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--targetVcfs` | Target VCF file(s) | Required |
| `--referenceDir` | Reference legend directory | Required |
| `--fixMethod` | Fix method: `remove` or `correct` | `remove` |
| `--outputDir` | Output directory | `results` |
| `--legendPattern` | Legend file pattern | `*.legend.gz` |

## Requirements

- Nextflow ≥ 21.04.0
- Docker, Singularity, or Conda
- Target VCF files (bgzipped and indexed)
- Reference panel legend files

## Features

- ✅ **Allele Switch Detection** - Identifies REF↔ALT orientation mismatches
- ✅ **Multiple Fix Methods** - Remove problematic sites or correct orientations
- ✅ **Multi-File Processing** - Parallel processing of multiple chromosomes
- ✅ **Automatic Matching** - Smart pairing of VCFs with reference legends

## Documentation

**Complete documentation is available at: https://afrigen-d.github.io/checkref-docs/**

- [Quick Start Tutorial](https://afrigen-d.github.io/checkref-docs/tutorials/quick-start)
- [Parameter Reference](https://afrigen-d.github.io/checkref-docs/reference/parameters)
- [Examples](https://afrigen-d.github.io/checkref-docs/examples/)
- [Troubleshooting](https://afrigen-d.github.io/checkref-docs/docs/troubleshooting)

## Testing

```bash
# Run tests
./test/test.sh
```

## Support

- [Documentation Website](https://afrigen-d.github.io/checkref-docs/)
- [GitHub Issues](https://github.com/AfriGen-D/checkref/issues)
- [AfriGen-D Helpdesk](https://helpdesk.afrigen-d.org)
