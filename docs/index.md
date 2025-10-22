---
layout: home

hero:
  name: "CheckRef"
  text: "Allele Switch Checker"
  tagline: "Detect and correct allele switches between VCF files and reference panels"
  actions:
    - theme: brand
      text: Get Started
      link: /guide/getting-started
    - theme: alt
      text: View on GitHub
      link: https://github.com/AfriGen-D/checkref

features:
  - icon: 🔬
    title: Nextflow Workflow
    details: Scalable and reproducible pipeline built with Nextflow DSL2 for seamless execution across platforms.
  - icon: 🧬
    title: Allele Switch Detection
    details: Automatically identifies REF↔ALT orientation mismatches between target VCF files and reference panels.
  - icon: ✅
    title: VCF Validation
    details: Comprehensive file integrity checks detect corrupted, empty, or malformed VCF files before processing.
  - icon: 🔄
    title: Two Fix Methods
    details: Choose to remove problematic sites or correct allele orientations by swapping REF↔ALT alleles.
  - icon: 🧪
    title: Build Mismatch Detection
    details: Gracefully exits when genome builds don't match (e.g., hg19 vs hg38) to prevent incorrect results.
  - icon: 📊
    title: Comprehensive Reporting
    details: Per-chromosome and aggregated statistics with validation and verification reports.
  - icon: 🐳
    title: Container Support
    details: Run with Docker, Singularity, Podman, Shifter, or Charliecloud for maximum reproducibility.
  - icon: ⚡
    title: Automated Matching
    details: Intelligent chromosome detection automatically pairs VCF files with corresponding legend files.
---

## Quick Start

Run the pipeline with minimal configuration:

```bash
# Install Nextflow
curl -s https://get.nextflow.io | bash

# Run with test data
nextflow run AfriGen-D/checkref -profile test,docker --outdir results

# Run with your data
nextflow run AfriGen-D/checkref \
    --targetVcfs "sample*.vcf.gz" \
    --referenceDir /path/to/reference/panels/ \
    --fixMethod correct \
    --outdir results \
    -profile docker
```

## Pipeline Overview

CheckRef performs seven key steps:

1. **VCF Validation** - Assess file integrity and format compliance
2. **Chromosome Detection** - Automatically identify chromosomes from filenames
3. **Reference Matching** - Pair VCF files with corresponding legend files
4. **Allele Switch Detection** - Compare REF/ALT orientations against reference
5. **Correction/Removal** - Fix allele switches or remove problematic sites
6. **Verification** - Validate that corrections were successful
7. **Results Aggregation** - Generate comprehensive summary reports

## Use Cases

- **Quality Control** before genotype imputation
- **Data Harmonization** across different reference panels
- **Genomic Data Cleaning** for association studies
- **Reference Panel Preparation** for population genetics research

## Documentation

- [Getting Started](/guide/getting-started) - Installation and basic usage
- [Parameters](/api/parameters) - Complete parameter reference
- [Examples](/examples/) - Example configurations and use cases
- [Workflow Details](/workflow/) - Technical pipeline documentation

## Requirements

- Nextflow ≥ 21.04.0
- Docker, Singularity, Podman, Shifter, Charliecloud, or Conda
- Java 11 or later (for Nextflow)

## Support

- [GitHub Issues](https://github.com/AfriGen-D/checkref/issues)
- [AfriGen-D Discussions](https://github.com/orgs/AfriGen-D/discussions)
- [Helpdesk](https://helpdesk.afrigen-d.org)
- [AfriGen-D Website](https://afrigen-d.org)

## About AfriGen-D

CheckRef is part of the AfriGen-D project, dedicated to enabling innovation in African genomics research through cutting-edge bioinformatics tools, curated datasets, collaborative networks, and capacity building.

<!-- Last updated: 2025-10-22 -->
