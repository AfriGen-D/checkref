<div align="center">
  <img src="https://raw.githubusercontent.com/AfriGen-D/afrigen-d-templates/main/assets/afrigen-d-logo.png" alt="AfriGen-D Logo" width="200" />
  <h1>CheckRef</h1>
</div>

<div align="center">

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A521.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Documentation](https://img.shields.io/badge/docs-checkref-blue)](https://afrigen-d.github.io/checkref/)

</div>

## Introduction

CheckRef is a bioinformatics best-practice analysis pipeline for detecting and correcting allele switches between target VCF files and reference panels. The pipeline is designed to work with VCF files and produces corrected VCF files with verified allele orientations.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute environments in a very portable manner. It uses Docker/Singularity containers making installation trivial and results highly reproducible.

## Pipeline summary

CheckRef performs the following steps:

1. **VCF Validation** - Assess file integrity and format compliance
2. **Chromosome Detection** - Automatically identify chromosomes from filenames
3. **Reference Matching** - Pair VCF files with corresponding legend files
4. **Allele Switch Detection** - Compare REF/ALT orientations against reference
5. **Correction/Removal** - Fix allele switches or remove problematic sites
6. **Verification** - Validate that corrections were successful
7. **Results Aggregation** - Generate comprehensive summary reports

## Quick Start

1. Install [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (`>=21.04.0`)

2. Install any of [`Docker`](https://docs.docker.com/engine/installation/), [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/), [`Podman`](https://podman.io/), [`Shifter`](https://nersc.gitlab.io/development/shifter/how-to-use/) or [`Charliecloud`](https://hpc.github.io/charliecloud/) for full pipeline reproducibility

3. Download the pipeline and test it on a minimal dataset:

   ```bash
   nextflow run AfriGen-D/checkref -profile test,docker --outdir results
   ```

4. Start running your own analysis!

   ```bash
   nextflow run AfriGen-D/checkref \
       --targetVcfs "sample*.vcf.gz" \
       --referenceDir /path/to/reference/panels/ \
       --fixMethod correct \
       --outdir results \
       -profile <docker/singularity/podman/shifter/charliecloud/conda>
   ```

## Documentation

The CheckRef pipeline comes with comprehensive documentation: **https://afrigen-d.github.io/checkref/**

- [Getting Started](https://afrigen-d.github.io/checkref/guide/getting-started)
- [Quick Start Tutorial](https://afrigen-d.github.io/checkref/guide/quick-start)
- [Parameter Reference](https://afrigen-d.github.io/checkref/api/parameters)
- [Examples](https://afrigen-d.github.io/checkref/examples/)
- [Troubleshooting](https://afrigen-d.github.io/checkref/guide/troubleshooting)

## Parameters

### Input/output options

| Parameter | Description | Type | Default | Required | Hidden |
|-----------|-----------|------|---------|----------|--------|
| `--targetVcfs` | Target VCF file(s) - supports single files, comma-separated lists, or glob patterns | `string` | | True | |
| `--referenceDir` | Directory containing reference legend files | `string` | | True | |
| `--outdir` | The output directory where the results will be saved | `string` | `./results` | True | |

### Analysis options

| Parameter | Description | Type | Default | Required | Hidden |
|-----------|-----------|------|---------|----------|--------|
| `--fixMethod` | Method to fix allele switches: 'remove' or 'correct' | `string` | `remove` | | |
| `--legendPattern` | Pattern to match legend files in reference directory | `string` | `*.legend.gz` | | |

### Institutional config options

| Parameter | Description | Type | Default | Required | Hidden |
|-----------|-----------|------|---------|----------|--------|
| `--custom_config_version` | Git commit id for Institutional configs | `string` | `master` | | True |
| `--custom_config_base` | Base directory for Institutional configs | `string` | `https://raw.githubusercontent.com/nf-core/configs/master` | | True |
| `--config_profile_name` | Institutional config name | `string` | | | True |
| `--config_profile_description` | Institutional config description | `string` | | | True |

## Credits

CheckRef was originally written by Mamana Mbiyavanga.

We thank the following people for their extensive assistance in the development of this pipeline:

- AfriGen-D project members and collaborators
- Contributing researchers and developers
- The broader genomics and open science communities

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [AfriGen-D discussions](https://github.com/orgs/AfriGen-D/discussions) or visit our [helpdesk](https://helpdesk.afrigen-d.org).

## Citations

If you use CheckRef for your analysis, please cite it using the following:

```bibtex
@software{checkref_2025,
  title = {CheckRef: Allele Switch Checker for Population Genetics},
  author = {Mamana Mbiyavanga and AfriGen-D project},
  year = {2025},
  url = {https://github.com/AfriGen-D/checkref},
  note = {Nextflow pipeline for detecting and correcting allele switches}
}
```

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) initiative, and reused here under the [MIT license](https://github.com/nf-core/tools/blob/master/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Holger Hoeft, Johannes Alneberg, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).

## About AfriGen-D

AfriGen-D is a project dedicated to enabling innovation in African genomics research through:

- **Research Tools**: Cutting-edge bioinformatics software
- **Data Resources**: Curated genomic datasets and reference panels
- **Community**: Collaborative research networks
- **Education**: Training and capacity building

Visit [afrigen-d.org](https://afrigen-d.org) to learn more about our mission and projects.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">
  <p><strong>Enabling innovation in African genomics research</strong></p>
  <p>
    <a href="https://afrigen-d.org">Website</a> •
    <a href="https://twitter.com/AfriGenD">Twitter</a> •
    <a href="https://linkedin.com/company/afrigen-d">LinkedIn</a> •
    <a href="https://youtube.com/@afrigen-d">YouTube</a>
  </p>
</div>