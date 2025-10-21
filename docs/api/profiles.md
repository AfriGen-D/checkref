# Profiles

CheckRef supports multiple execution profiles for different computing environments. This page documents all available profiles and how to use them.

## Container Profiles

### docker

Executes processes using Docker containers.

**Requirements**:
- Docker installed and running
- User has Docker permissions

**Usage**:
```bash
-profile docker
```

**Features**:
- ✅ Maximum reproducibility
- ✅ Easy setup on local machines
- ✅ No dependency installation needed
- ✅ Works on Linux, macOS, Windows (WSL2)

**Container**: `mamana/vcf-processing:latest`

**Example**:
```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/ref/" \
    -profile docker
```

---

### singularity

Executes processes using Singularity containers.

**Requirements**:
- Singularity installed
- Recommended for HPC systems

**Usage**:
```bash
-profile singularity
```

**Features**:
- ✅ HPC-friendly (no root required)
- ✅ Better performance than Docker on HPC
- ✅ Automatic Docker→Singularity conversion
- ✅ Image caching

**Container**: Automatically converts `mamana/vcf-processing:latest` from Docker Hub

**Example**:
```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/ref/" \
    -profile singularity
```

**Singularity Cache**:
By default, images are cached in `$HOME/.singularity/cache/`. Customize:
```groovy
singularity {
    cacheDir = '/scratch/$USER/singularity'
}
```

---

### podman

Executes processes using Podman containers.

**Requirements**:
- Podman installed
- Alternative to Docker

**Usage**:
```bash
-profile podman
```

**Features**:
- ✅ Rootless containers
- ✅ Docker-compatible
- ✅ Better security model

---

## Test Profile

### test

Runs pipeline with built-in test data.

**Usage**:
```bash
-profile test,docker
```

**Features**:
- Small test dataset included
- Quick validation (few minutes)
- Verifies installation

**Test Data**:
- Sample VCF files for multiple chromosomes
- Corresponding legend files
- Expected outputs for validation

**Example**:
```bash
# Test with Docker
nextflow run AfriGen-D/checkref -profile test,docker --outdir test_output

# Test with Singularity
nextflow run AfriGen-D/checkref -profile test,singularity --outdir test_output
```

---

## HPC Profiles

### hpc

Basic HPC profile for SLURM clusters.

**Usage**:
```bash
-profile hpc,singularity
```

**Default Configuration**:
```groovy
process {
    executor = 'slurm'
    queue = 'normal'
    clusterOptions = '--account=project123'
}
```

**Customization Required**:
Create a custom config file for your HPC:

**slurm.config**:
```groovy
process {
    executor = 'slurm'
    queue = 'batch'
    clusterOptions = '--account=YOUR_PROJECT'
    
    cpus = 1
    memory = 4.GB
    time = 4.h
}
```

**Usage**:
```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/ref/" \
    -profile singularity,hpc \
    -c slurm.config
```

---

### SLURM Configuration Example

```groovy
// slurm.config
process {
    executor = 'slurm'
    queue = 'batch'
    clusterOptions = '--account=genomics --partition=standard'
    
    cpus = 1
    memory = 4.GB
    time = 4.h
    
    // Higher resources for intensive processes
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

---

### PBS/Torque Configuration Example

```groovy
// pbs.config
process {
    executor = 'pbs'
    queue = 'batch'
    clusterOptions = '-l nodes=1:ppn=1 -A genomics'
    
    cpus = 1
    memory = '4GB'
    time = '4h'
}
```

---

### LSF Configuration Example

```groovy
// lsf.config
process {
    executor = 'lsf'
    queue = 'normal'
    clusterOptions = '-P genomics'
    
    cpus = 1
    memory = 4.GB
    time = 4.h
}
```

---

### SGE Configuration Example

```groovy
// sge.config
process {
    executor = 'sge'
    penv = 'smp'
    queue = 'all.q'
    clusterOptions = '-P genomics'
    
    cpus = 1
    memory = '4G'
    time = '4h'
}
```

---

## Standard Profile

### standard

Local execution without containers (not recommended).

**Usage**:
```bash
-profile standard
```

**Requirements**:
- All dependencies installed locally:
  - Python 3
  - bcftools
  - Other VCF tools

**Note**: Use containers (Docker/Singularity) for better reproducibility.

---

## Combining Profiles

Multiple profiles can be combined with commas:

```bash
# Test with Docker
-profile test,docker

# HPC with Singularity
-profile hpc,singularity

# Custom combination
-profile singularity,cluster_specific
```

**Profile precedence**: Later profiles override earlier ones.

---

## Cloud Profiles

### AWS Batch

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

**Usage**:
```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "s3://bucket/vcfs/*.vcf.gz" \
    --referenceDir "s3://bucket/reference/" \
    --outdir "s3://bucket/results/" \
    -c aws.config \
    -profile awsbatch
```

---

### Google Cloud

```groovy
// gcp.config
process {
    executor = 'google-lifesciences'
    container = 'mamana/vcf-processing:latest'
}

google {
    region = 'us-central1'
    project = 'your-project-id'
    zone = 'us-central1-a'
}
```

**Usage**:
```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "gs://bucket/vcfs/*.vcf.gz" \
    --referenceDir "gs://bucket/reference/" \
    --outdir "gs://bucket/results/" \
    -c gcp.config
```

---

## Custom Profiles

Create custom profiles in your own config:

```groovy
// my_profiles.config
profiles {
    my_local {
        docker.enabled = true
        process.cpus = 4
        process.memory = 16.GB
    }
    
    my_hpc {
        singularity.enabled = true
        singularity.cacheDir = '/scratch/singularity'
        process.executor = 'slurm'
        process.queue = 'genomics'
    }
}
```

**Usage**:
```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/ref/" \
    -profile my_local \
    -c my_profiles.config
```

---

## Profile Configuration Reference

### Docker Profile

```groovy
docker {
    enabled = true
    runOptions = '-u $(id -u):$(id -g)'  // Run as current user
}
```

### Singularity Profile

```groovy
singularity {
    enabled = true
    autoMounts = true                     // Auto-mount host paths
    cacheDir = "$HOME/.singularity/cache" // Cache directory
    runOptions = ''                       // Additional options
}
```

### HPC Profile Template

```groovy
process {
    executor = 'slurm'  // or 'pbs', 'lsf', 'sge'
    queue = 'batch'
    clusterOptions = '--account=PROJECT'
    
    cpus = 1
    memory = 4.GB
    time = 4.h
    
    errorStrategy = 'retry'
    maxRetries = 2
}

executor {
    queueSize = 100              // Max parallel jobs
    submitRateLimit = '10 sec'   // Job submission rate
}
```

---

## Choosing a Profile

| Environment | Recommended Profile | Example |
|-------------|-------------------|---------|
| Local Linux/Mac | `docker` | `-profile docker` |
| Local Windows | `docker` (WSL2) | `-profile docker` |
| HPC Cluster | `singularity,hpc` | `-profile singularity,hpc -c slurm.config` |
| AWS | Custom AWS | `-profile awsbatch -c aws.config` |
| Google Cloud | Custom GCP | `-c gcp.config` |
| Testing | `test,docker` | `-profile test,docker` |

---

## Next Steps

- [Parameters](/api/parameters) - Configuration parameters
- [Modules](/api/modules) - Pipeline processes
- [Configuration](/guide/configuration) - Advanced configuration
