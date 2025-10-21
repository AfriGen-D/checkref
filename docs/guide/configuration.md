# Configuration

CheckRef can be configured using parameters, profiles, and configuration files. This guide covers all configuration options.

## Configuration Methods

### 1. Command-Line Parameters

Pass parameters directly when running the pipeline:

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/ref/" \
    --fixMethod correct \
    --outdir results
```

### 2. Configuration Profiles

Use predefined profiles with `-profile`:

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/ref/" \
    -profile docker,test
```

### 3. Custom Config Files

Create a custom configuration file:

```groovy
// my_config.config
params {
    targetVcfs = "*.vcf.gz"
    referenceDir = "/path/to/reference/"
    fixMethod = "correct"
    outdir = "my_results"
}

process {
    cpus = 2
    memory = 8.GB
}
```

Run with custom config:
```bash
nextflow run AfriGen-D/checkref -c my_config.config
```

## Available Profiles

### Container Profiles

**docker** - Run with Docker containers:
```bash
-profile docker
```

**singularity** - Run with Singularity containers:
```bash
-profile singularity
```

**podman** - Run with Podman containers:
```bash
-profile podman
```

### Test Profile

**test** - Run with built-in test data:
```bash
-profile test,docker
```

This profile includes small test datasets for quick validation.

### HPC Profile

**hpc** - Optimized for SLURM clusters:
```groovy
// Example HPC configuration
-profile hpc

// Customize for your cluster
process {
    executor = 'slurm'
    queue = 'normal'
    clusterOptions = '--account=your_project'
}
```

### Combining Profiles

Multiple profiles can be combined:
```bash
-profile singularity,hpc
```

## Parameters Reference

### Required Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `--targetVcfs` | string | Target VCF files (glob pattern, comma-separated, or single file) |
| `--referenceDir` | string | Directory containing reference legend files |

### Optional Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `--outdir` | string | `./results` | Output directory |
| `--fixMethod` | string | `remove` | Method to fix switches: 'remove' or 'correct' |
| `--legendPattern` | string | `*.legend.gz` | Pattern to match legend files |

### Resource Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `--maxCpus` | integer | `4` | Maximum CPUs per process |
| `--maxMemory` | string | `8.GB` | Maximum memory per process |
| `--maxTime` | string | `24.h` | Maximum time per process |

## Process-Specific Configuration

### Customize Resource Allocation

Override resources for specific processes:

```groovy
// custom_resources.config
process {
    withName: CHECK_ALLELE_SWITCH {
        cpus = 2
        memory = 8.GB
        time = 6.h
    }
    
    withName: CORRECT_SWITCHED_SITES {
        cpus = 1
        memory = 4.GB
        time = 2.h
    }
}
```

Usage:
```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/ref/" \
    -c custom_resources.config \
    -profile docker
```

### Process List

Available process names for customization:
- `VALIDATE_VCF_FILES`
- `CHECK_ALLELE_SWITCH`
- `REMOVE_SWITCHED_SITES`
- `CORRECT_SWITCHED_SITES`
- `VERIFY_CORRECTIONS`
- `CREATE_SUMMARY`

## HPC Configuration

### SLURM Example

```groovy
// slurm.config
process {
    executor = 'slurm'
    queue = 'batch'
    clusterOptions = '--account=genomics_project --partition=long'
    
    cpus = 1
    memory = 4.GB
    time = 4.h
    
    withName: CHECK_ALLELE_SWITCH {
        cpus = 2
        memory = 8.GB
        time = 8.h
        queue = 'highmem'
    }
}

executor {
    queueSize = 100
    submitRateLimit = '10 sec'
}
```

Usage:
```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/ref/" \
    -c slurm.config \
    -profile singularity
```

### PBS/Torque Example

```groovy
// pbs.config
process {
    executor = 'pbs'
    queue = 'batch'
    clusterOptions = '-l walltime=24:00:00 -A genomics'
    
    cpus = 1
    memory = '4GB'
}
```

### LSF Example

```groovy
// lsf.config
process {
    executor = 'lsf'
    queue = 'normal'
    clusterOptions = '-P genomics'
    
    cpus = 1
    memory = 4.GB
}
```

## Container Configuration

### Docker Configuration

```groovy
docker {
    enabled = true
    runOptions = '-u $(id -u):$(id -g)'
}
```

### Singularity Configuration

```groovy
singularity {
    enabled = true
    autoMounts = true
    cacheDir = '/path/to/singularity/cache'
}
```

### Custom Container

Override the default container:

```groovy
process {
    container = 'your_username/custom-vcf-tools:latest'
}
```

## Output Directory Configuration

### Custom Output Subdirectories

```groovy
params {
    // Main output directory
    outdir = 'my_results'
    
    // Subdirectories
    allele_switch_results = "${params.outdir}/switches"
    summary_files = "${params.outdir}/summaries"
    fixed_vcfs = "${params.outdir}/corrected_vcfs"
    logs = "${params.outdir}/pipeline_logs"
}
```

## Advanced Configuration

### Retry Strategy

Configure automatic retries on failure:

```groovy
process {
    errorStrategy = 'retry'
    maxRetries = 3
    
    withName: CHECK_ALLELE_SWITCH {
        errorStrategy = { task.attempt < 3 ? 'retry' : 'finish' }
        memory = { 4.GB * task.attempt }
    }
}
```

### Caching and Resume

Enable work directory caching:

```groovy
// Specify work directory
workDir = '/scratch/nextflow/work'

// Enable resume by default
resume = true
```

Usage:
```bash
# Automatically resumes from last successful step
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/ref/" \
    -resume
```

### Execution Reports

Configure detailed execution reports:

```groovy
report {
    enabled = true
    file = "${params.outdir}/reports/execution_report.html"
}

timeline {
    enabled = true
    file = "${params.outdir}/reports/timeline.html"
}

dag {
    enabled = true
    file = "${params.outdir}/reports/dag.html"
}

trace {
    enabled = true
    file = "${params.outdir}/reports/trace.txt"
}
```

## Environment-Specific Configs

### Local Workstation

```groovy
// local.config
process {
    executor = 'local'
    cpus = 2
    memory = 8.GB
}

docker.enabled = true
```

### Cloud (AWS)

```groovy
// aws.config
process {
    executor = 'awsbatch'
    queue = 'genomics-queue'
    container = 'mamana/vcf-processing:latest'
}

aws {
    region = 'us-east-1'
    batch {
        cliPath = '/home/ec2-user/miniconda/bin/aws'
    }
}
```

### Cloud (Google Cloud)

```groovy
// gcp.config
process {
    executor = 'google-lifesciences'
    container = 'mamana/vcf-processing:latest'
}

google {
    region = 'us-central1'
    project = 'your-project-id'
}
```

## Configuration Best Practices

1. **Use profiles** for different environments (local, HPC, cloud)
2. **Version control** your custom config files
3. **Document** any custom settings
4. **Test** configurations with small datasets first
5. **Monitor** resource usage and adjust as needed

## Example Complete Configuration

```groovy
// complete_config.config

// Parameters
params {
    targetVcfs = "/data/vcfs/*.vcf.gz"
    referenceDir = "/data/reference/"
    fixMethod = "correct"
    outdir = "/results/checkref_output"
    legendPattern = "*.legend.gz"
}

// Process configuration
process {
    executor = 'slurm'
    queue = 'batch'
    
    cpus = 1
    memory = 4.GB
    time = 4.h
    
    errorStrategy = 'retry'
    maxRetries = 2
    
    withName: CHECK_ALLELE_SWITCH {
        cpus = 2
        memory = 8.GB
        time = 8.h
    }
}

// Container
singularity {
    enabled = true
    autoMounts = true
    cacheDir = '/scratch/singularity'
}

// Reports
report.enabled = true
timeline.enabled = true
trace.enabled = true
