# Getting Started

CheckRef is a Nextflow pipeline designed for detecting and correcting allele switches between target VCF files and reference panel legend files. This guide will help you get up and running with the pipeline.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Nextflow** (version 21.04.0 or later)
- **Container engine**: Docker, Singularity, Podman, Shifter, Charliecloud, or Conda
- **Java** 11 or later (required for Nextflow)

## Quick Installation

### 1. Install Nextflow

```bash
# Install Nextflow
curl -s https://get.nextflow.io | bash

# Make it executable and move to PATH
chmod +x nextflow
sudo mv nextflow /usr/local/bin/

# Verify installation
nextflow -version
```

### 2. Install Container Engine

Choose one of the following:

**Docker** (Recommended for local systems):
```bash
# Follow instructions at https://docs.docker.com/get-docker/
```

**Singularity** (Recommended for HPC):
```bash
# Follow instructions at https://sylabs.io/guides/latest/user-guide/
```

### 3. Test the Installation

Run the pipeline with test data to verify everything is working:

**Option A: Quick Test (recommended)**
```bash
# Clone repository with test data
git clone https://github.com/AfriGen-D/checkref.git
cd checkref

# Run with included test data
nextflow run main.nf \
    --targetVcfs "test_data/chr22/*.vcf.gz" \
    --referenceDir "test_data/reference/" \
    --legendPattern "*.legend.gz" \
    --outdir test_results \
    -profile docker
```

**Option B: Pull from GitHub**
```bash
nextflow run AfriGen-D/checkref -profile test,docker --outdir test_results
```

This will:
- Download the CheckRef pipeline from GitHub
- Pull the required Docker container
- Run on chr22 sample data (~1000 variants)
- Generate results in `test_results/`
- Complete in ~2-5 minutes

**Verify Results:**
```bash
ls test_results/
# Expected files:
# - chr22_allele_switch_results.tsv
# - chr22_allele_switch_summary.txt
# - chr22.noswitch.vcf.gz
# - all_chromosomes_summary.txt
```

## What's Next?

- [Installation](/guide/installation) - Detailed installation instructions
- [Quick Start](/guide/quick-start) - Run your first analysis
- [Configuration](/guide/configuration) - Customize the pipeline for your needs
- [Input Files](/guide/input-files) - Understand input file requirements

## Getting Help

If you encounter any issues:

1. Check the [troubleshooting guide](/guide/troubleshooting)
2. Search existing [GitHub issues](https://github.com/AfriGen-D/checkref/issues)
3. Create a new issue with details about your problem
4. Contact the AfriGen-D team at [helpdesk.afrigen-d.org](https://helpdesk.afrigen-d.org)