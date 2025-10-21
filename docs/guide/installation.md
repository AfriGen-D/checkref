# Installation

This page provides detailed installation instructions for CheckRef and its dependencies.

## System Requirements

- **Operating System**: Linux, macOS, or Windows (with WSL2)
- **Memory**: Minimum 4GB RAM (8GB recommended)
- **Storage**: At least 10GB free space
- **Java**: Version 11 or later
- **Internet connection**: For downloading containers and dependencies

## Installation Methods

### Method 1: Direct Run from GitHub (Recommended)

The easiest way to use CheckRef is to run it directly from GitHub. Nextflow will automatically download the pipeline:

```bash
# Install Nextflow first
curl -s https://get.nextflow.io | bash
chmod +x nextflow
sudo mv nextflow /usr/local/bin/

# Run CheckRef directly (Nextflow handles the download)
nextflow run AfriGen-D/checkref -profile test,docker --outdir results
```

This method:
- ✅ Always uses the latest stable version
- ✅ No manual cloning required
- ✅ Automatically handles updates

### Method 2: Clone from GitHub

If you want to modify the pipeline or work offline:

```bash
# Clone the repository
git clone https://github.com/AfriGen-D/checkref.git
cd checkref

# Run the pipeline
nextflow run main.nf --targetVcfs "*.vcf.gz" --referenceDir /path/to/legends/ -profile docker
```

## Container Engine Installation

CheckRef requires a container engine. Choose one based on your system:

### Docker (Local Systems)

**Linux**:
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group (logout/login required)
sudo usermod -aG docker $USER

# Verify installation
docker --version
```

**macOS**:
- Download and install [Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/)
- Follow the installer instructions

**Windows** (WSL2):
- Install WSL2 if not already installed
- Download and install [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
- Enable WSL2 integration in Docker Desktop settings

### Singularity (HPC Systems)

**From source** (requires root):
```bash
# Install dependencies (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y build-essential libssl-dev uuid-dev libgpgme11-dev \
    squashfs-tools libseccomp-dev wget pkg-config git cryptsetup

# Install Go
export VERSION=1.20.2 OS=linux ARCH=amd64
wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz
sudo tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz
rm go$VERSION.$OS-$ARCH.tar.gz

echo 'export PATH=/usr/local/go/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Install Singularity
export VERSION=3.11.0
wget https://github.com/sylabs/singularity/releases/download/v${VERSION}/singularity-ce-${VERSION}.tar.gz
tar -xzf singularity-ce-${VERSION}.tar.gz
cd singularity-ce-${VERSION}

./mconfig
make -C builddir
sudo make -C builddir install

# Verify installation
singularity --version
```

**Using Conda/Mamba**:
```bash
conda install -c conda-forge singularity
# or
mamba install -c conda-forge singularity
```

**On HPC**: Most HPC systems have Singularity pre-installed. Load it with:
```bash
module load singularity
```

### Conda (Alternative)

If you cannot use containers, Conda is an alternative (though less reproducible):

```bash
# Install Conda/Mamba
wget https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh
bash Mambaforge-Linux-x86_64.sh

# The pipeline will create its own Conda environment when using -profile conda
```

## Verifying Installation

### Test Nextflow

```bash
nextflow -version
```

Expected output:
```
nextflow version 23.10.0.5889
```

### Test Container Engine

**Docker**:
```bash
docker run hello-world
```

**Singularity**:
```bash
singularity run docker://hello-world
```

### Test CheckRef

Run the built-in test profile:

```bash
nextflow run AfriGen-D/checkref -profile test,docker --outdir test_output
```

This should complete without errors and generate results in `test_output/`.

## Updating CheckRef

### Update to Latest Version

If using direct GitHub runs:
```bash
nextflow pull AfriGen-D/checkref
nextflow run AfriGen-D/checkref -profile docker --outdir results
```

If using a cloned repository:
```bash
cd checkref
git pull origin main
nextflow run main.nf -profile docker --outdir results
```

### Use Specific Version

```bash
# Run a specific release version
nextflow run AfriGen-D/checkref -r v1.0.0 -profile docker

# Run a specific branch
nextflow run AfriGen-D/checkref -r development -profile docker
```

## Troubleshooting Installation

### Nextflow not found

**Problem**: `nextflow: command not found`

**Solutions**:
1. Ensure Nextflow is in your PATH:
   ```bash
   echo 'export PATH=$PATH:/path/to/nextflow' >> ~/.bashrc
   source ~/.bashrc
   ```
2. Or use absolute path:
   ```bash
   /path/to/nextflow run AfriGen-D/checkref
   ```

### Docker permission denied

**Problem**: `Got permission denied while trying to connect to the Docker daemon socket`

**Solution**: Add user to docker group:
```bash
sudo usermod -aG docker $USER
# Log out and log back in for changes to take effect
```

### Java version issues

**Problem**: Nextflow requires Java 11 or later

**Solution**: Install OpenJDK:
```bash
# Ubuntu/Debian
sudo apt-get install openjdk-11-jdk

# macOS
brew install openjdk@11

# Check version
java -version
```

### Container pull issues

**Problem**: Cannot pull Docker container

**Solutions**:
1. Check internet connection
2. Check Docker is running: `docker ps`
3. Manually pull container:
   ```bash
   docker pull mamana/vcf-processing:latest
   ```

## Next Steps

- [Quick Start](/guide/quick-start) - Run your first analysis
- [Configuration](/guide/configuration) - Configure for your system
- [Input Files](/guide/input-files) - Prepare your input data
