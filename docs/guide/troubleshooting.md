# Troubleshooting

This guide helps you resolve common issues with CheckRef.

## Common Issues

### 1. No VCF Files Found

**Error**:
```
ERROR ~ No such variable: Exception evaluating property 'size' for java.util.ArrayList
```

**Cause**: No VCF files match the provided pattern

**Solutions**:

1. Check the file path is correct:
   ```bash
   ls /path/to/vcfs/*.vcf.gz
   ```

2. Use absolute paths:
   ```bash
   --targetVcfs "/full/path/to/vcfs/*.vcf.gz"
   ```

3. Use quotes around glob patterns:
   ```bash
   --targetVcfs "*.vcf.gz"  # Correct
   --targetVcfs *.vcf.gz    # May not work
   ```

4. For comma-separated files:
   ```bash
   --targetVcfs "file1.vcf.gz,file2.vcf.gz,file3.vcf.gz"
   ```

### 2. No Reference Legend Files Found

**Error**:
```
ERROR ~ No reference legend files found with pattern: /path/*.legend.gz
```

**Cause**: No legend files found in reference directory

**Solutions**:

1. Verify reference directory exists and contains legend files:
   ```bash
   ls /path/to/reference/*.legend.gz
   ```

2. Check legend file pattern:
   ```bash
   # If your legend files have different extension
   --legendPattern "*.legend.txt.gz"
   --legendPattern "*.leg.gz"
   ```

3. Ensure files have .legend.gz extension or update pattern

### 3. Chromosome Naming Mismatch

**Issue**: VCF files are processed but no matches with legend files

**Cause**: Chromosome naming inconsistency

**Example Problem**:
- VCF files: `sample_chr1.vcf.gz` (with 'chr' prefix)
- Legend files: `ref_1.legend.gz` (without 'chr' prefix)

**Solutions**:

1. **Option A**: Rename files to match:
   ```bash
   # Add 'chr' prefix to legend files
   for f in *.legend.gz; do
       mv "$f" "chr_$f"
   done
   ```

2. **Option B**: Remove 'chr' prefix from VCF names:
   ```bash
   # Remove 'chr' from VCF filenames
   for f in chr*.vcf.gz; do
       mv "$f" "${f#chr}"
   done
   ```

3. **Check chromosome in VCF header**:
   ```bash
   bcftools view -h sample.vcf.gz | grep "##contig"
   ```

### 4. Genome Build Mismatch

**Message**:
```
╔════════════════════════════════════════════╗
║       GENOME BUILD MISMATCH DETECTED       ║
╚════════════════════════════════════════════╝
```

**Cause**: VCF and legend files use different genome builds (e.g., hg19 vs hg38)

**Evidence**:
- REF alleles differ at the same position
- Example: Position 100000 is `A` in VCF but `G` in legend

**Solutions**:

1. **Use matching genome builds** - Ensure both files use same build

2. **Convert genome build** with liftOver:
   ```bash
   # Install UCSC tools
   # Download chain file for hg19 to hg38
   wget http://hgdownload.cse.ucsc.edu/goldenPath/hg19/liftOver/hg19ToHg38.over.chain.gz
   
   # Convert VCF to hg38
   java -jar picard.jar LiftoverVcf \
       I=input_hg19.vcf.gz \
       O=output_hg38.vcf.gz \
       CHAIN=hg19ToHg38.over.chain.gz \
       REJECT=rejected_variants.vcf.gz \
       R=hg38.fasta
   ```

3. **Verify genome build**:
   ```bash
   # Check VCF positions against known variants
   bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\n' input.vcf.gz | head
   
   # Compare with reference
   # Positions should match between VCF and legend
   ```

### 5. VCF Validation Failures

**Error**: VCF file fails validation checks

**Check validation report**:
```bash
cat results/logs/validation/chr*_validation_report.txt
```

**Common validation failures**:

#### Empty or Corrupted VCF

**Error**: File is too small or corrupted

**Solutions**:
```bash
# Test gzip integrity
gunzip -t file.vcf.gz

# If corrupted, regenerate or re-download
# Check file size
ls -lh file.vcf.gz  # Should be >100 bytes
```

#### Invalid VCF Format

**Error**: Invalid VCF format

**Solutions**:
```bash
# Validate VCF with bcftools
bcftools view -h file.vcf.gz

# Check for common issues
# - Missing ##fileformat header
# - Malformed header lines  
# - Invalid column structure

# Fix with bcftools
bcftools view file.vcf.gz -Oz -o fixed.vcf.gz
```

#### No Variant Data

**Warning**: File contains headers but no variants

**Solutions**:
```bash
# Check if VCF has data lines
bcftools view -H file.vcf.gz | wc -l

# If truly empty, chromosome may not have variants
# This is OK - CheckRef will skip it
```

### 6. Docker/Singularity Issues

#### Docker Permission Denied

**Error**:
```
Got permission denied while trying to connect to the Docker daemon socket
```

**Solution**:
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and log back in
# Or use newgrp
newgrp docker
```

#### Cannot Pull Container

**Error**: Failed to pull Docker image

**Solutions**:

1. Check Docker is running:
   ```bash
   docker ps
   ```

2. Manually pull container:
   ```bash
   docker pull mamana/vcf-processing:latest
   ```

3. Check internet connection

4. Try Singularity instead:
   ```bash
   -profile singularity  # instead of docker
   ```

#### Singularity Not Found

**Error**: `singularity: command not found`

**Solutions**:

1. Load Singularity module (HPC):
   ```bash
   module load singularity
   ```

2. Install Singularity

3. Use Docker instead:
   ```bash
   -profile docker  # instead of singularity
   ```

### 7. Memory or Resource Issues

#### Out of Memory

**Error**: Process killed due to memory limit

**Solutions**:

1. Increase memory for specific process:
   ```groovy
   // custom.config
   process {
       withName: CHECK_ALLELE_SWITCH {
           memory = 16.GB  // Increase from default 4GB
       }
   }
   ```

2. Run with config:
   ```bash
   nextflow run AfriGen-D/checkref \
       --targetVcfs "*.vcf.gz" \
       --referenceDir "/ref/" \
       -c custom.config \
       -profile docker
   ```

#### Process Timeout

**Error**: Process exceeded time limit

**Solution**:
```groovy
// custom.config
process {
    withName: CHECK_ALLELE_SWITCH {
        time = 12.h  // Increase from default 4h
    }
}
```

### 8. Nextflow Issues

#### Nextflow Version Too Old

**Error**: Nextflow version requirement not met

**Solution**:
```bash
# Update Nextflow
nextflow self-update

# Or install latest version
curl -s https://get.nextflow.io | bash
```

#### Java Version Issues

**Error**: Nextflow requires Java 11 or later

**Solution**:
```bash
# Check Java version
java -version

# Install OpenJDK 11+
# Ubuntu/Debian
sudo apt-get install openjdk-11-jdk

# macOS
brew install openjdk@11
```

### 9. Verification Failures

**Issue**: Verification reports remaining switches after correction

**Check verification report**:
```bash
cat results/logs/verification/chr*_verification_results.txt
```

**Possible causes**:

1. **Build mismatch** - Some sites couldn't be corrected
   - Check for failed corrections in `correction_stats.txt`
   
2. **Bug in correction** - Report to developers
   - Include verification report
   - Include sample VCF and legend files

### 10. HPC/Cluster Issues

#### Jobs Not Submitting

**Check cluster queue**:
```bash
# SLURM
squeue -u $USER

# PBS
qstat -u $USER

# SGE
qstat -u $USER
```

**Solutions**:

1. Check queue name is correct in config
2. Verify account/project settings
3. Check cluster resource availability

#### Jobs Failing on HPC

**Check job logs**:
```bash
# Find SLURM logs
ls -la slurm-*.out

# Check for errors
grep -i error slurm-*.out
```

**Common fixes**:

1. Load required modules:
   ```bash
   module load singularity
   module load java/11
   ```

2. Set correct paths in config
3. Adjust resource requests

## Getting Additional Help

### 1. Check Nextflow Log

```bash
# View full Nextflow log
less .nextflow.log

# Search for errors
grep ERROR .nextflow.log
```

### 2. Check Process Logs

```bash
# Find work directory from error message
# Example: work/3a/f8b234abcd...

# Check stderr
cat work/3a/f8b234*/.command.err

# Check stdout
cat work/3a/f8b234*/.command.out

# Check the actual command
cat work/3a/f8b234*/.command.sh
```

### 3. Enable Debug Mode

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/ref/" \
    -profile docker \
    -with-trace \
    -with-report \
    -with-timeline
```

### 4. Report an Issue

If you can't resolve the issue:

1. Visit [GitHub Issues](https://github.com/AfriGen-D/checkref/issues)
2. Search for similar issues
3. Create a new issue with:
   - CheckRef version
   - Nextflow version  
   - Error message
   - Relevant log files
   - Command used
   - System information

### 5. Community Support

- **Discussions**: [GitHub Discussions](https://github.com/orgs/AfriGen-D/discussions)
- **Helpdesk**: [helpdesk.afrigen-d.org](https://helpdesk.afrigen-d.org)

## Debugging Tips

1. **Start small** - Test with one chromosome first
2. **Use test profile** - Verify installation works
3. **Check each input** - Validate VCF and legend files separately
4. **Enable verbose logging** - Use `-with-trace` and `-with-report`
5. **Don't delete work/** - Needed for debugging and resume

## Next Steps

- [Configuration](/guide/configuration) - Advanced configuration
- [Running](/guide/running) - Execution best practices
- [Examples](/examples/) - Working examples
