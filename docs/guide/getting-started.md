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

```bash
nextflow run AfriGen-D/checkref -profile test,docker --outdir test_results
```

This will:
- Download the CheckRef pipeline from GitHub
- Pull the required Docker container
- Run on test data
- Generate results in `test_results/`

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