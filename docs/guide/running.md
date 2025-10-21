# Running the Pipeline

This guide covers running CheckRef in various scenarios and understanding the execution process.

## Basic Execution

### Standard Run

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "/data/vcfs/*.vcf.gz" \
    --referenceDir "/data/reference/" \
    --outdir results \
    -profile docker
```

### With Custom Parameters

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "/data/vcfs/*.vcf.gz" \
    --referenceDir "/data/reference/" \
    --fixMethod correct \
    --legendPattern "*.legend.txt.gz" \
    --outdir results \
    -profile docker
```

## Monitoring Execution

### Real-time Progress

Nextflow shows real-time progress:

```
N E X T F L O W  ~  version 23.10.0
Launching `AfriGen-D/checkref` [silly_euler] DSL2 - revision: abc1234

executor >  local (15)
[3a/f8b234] process > VALIDATE_VCF_FILES (chr1:validation)     [100%] 22 of 22 ✔
[7b/2cd901] process > CHECK_ALLELE_SWITCH (chr1:sample)        [ 95%] 21 of 22
[4c/5ef123] process > CORRECT_SWITCHED_SITES (chr1:sample)     [ 90%] 20 of 22
[8d/9ab456] process > VERIFY_CORRECTIONS (chr1:verification)   [ 85%] 19 of 22
[1e/6cd789] process > CREATE_SUMMARY                           [  0%] 0 of 1
```

### Check Running Processes

```bash
# List all Nextflow processes
ps aux | grep nextflow

# Monitor resource usage
top -u $USER
```

## Resume Functionality

### Resume After Failure

If the pipeline stops or fails, resume from the last successful step:

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/ref/" \
    -profile docker \
    -resume
```

### How Resume Works

- Nextflow caches each process execution in the `work/` directory
- On resume, completed processes are skipped
- Only failed or new processes are re-executed
- Saves time and computational resources

### Clean Start (No Resume)

To start fresh without using cache:

```bash
# Remove work directory
rm -rf work/

# Run without -resume
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/ref/" \
    -profile docker
```

## Execution Modes

### Local Execution

Run on your local machine:

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/ref/" \
    -profile docker
```

### HPC Execution (SLURM)

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/ref/" \
    -profile singularity,hpc \
    -c slurm.config
```

### Background Execution

Run in the background:

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/ref/" \
    -profile docker \
    -bg > checkref.log 2>&1
```

Check progress:
```bash
tail -f checkref.log
```

## Output and Logging

### Nextflow Log

Nextflow creates a `.nextflow.log` file in the launch directory:

```bash
# View log
less .nextflow.log

# Follow log in real-time
tail -f .nextflow.log

# Search for errors
grep ERROR .nextflow.log
```

### Pipeline Output

Pipeline messages appear in two places:

1. **Standard output**: Real-time progress
2. **Log files**: Detailed process logs in `work/` directories

### Process-Specific Logs

Each process has its own log files:

```bash
# Find work directory for a process
ls -la work/*/*

# View process stdout
cat work/3a/f8b234*/file.command.out

# View process stderr
cat work/3a/f8b234*/file.command.err

# View command executed
cat work/3a/f8b234*/file.command.sh
```

## Execution Reports

### Generate Reports

Reports are generated automatically (configured in `nextflow.config`):

```
results/reports/
├── execution_report.html    # Resource usage and timing
├── timeline_report.html     # Timeline visualization
└── dag_report.html          # Workflow diagram
```

### Viewing Reports

Open in web browser:
```bash
firefox results/reports/execution_report.html
```

## Troubleshooting Execution

### Pipeline Hangs

If the pipeline appears stuck:

1. Check if processes are running:
   ```bash
   ps aux | grep nextflow
   ```

2. Check system resources:
   ```bash
   htop  # or top
   ```

3. Check cluster queue (if using HPC):
   ```bash
   squeue -u $USER
   ```

### Process Failures

When a process fails:

1. Locate the work directory from error message
2. Check error logs:
   ```bash
   cat work/xx/xxxxxx/.command.err
   cat work/xx/xxxxxx/.command.log
   ```

3. Check the command that was run:
   ```bash
   cat work/xx/xxxxxx/.command.sh
   ```

4. Try running the command manually for debugging

### Resource Errors

**Out of Memory**:
```bash
# Increase memory for specific process
process {
    withName: CHECK_ALLELE_SWITCH {
        memory = 16.GB
    }
}
```

**Timeout**:
```bash
# Increase time limit
process {
    withName: CHECK_ALLELE_SWITCH {
        time = 12.h
    }
}
```

## Cleanup

### Remove Work Directory

After successful completion:

```bash
# This saves disk space
rm -rf work/
```

**Warning**: Only do this if you don't need to resume!

### Clean Nextflow Cache

```bash
# Remove all cached metadata
nextflow clean -f

# Remove specific run
nextflow clean [run_name] -f
```

## Best Practices

1. **Always use `-resume`** when re-running after failures
2. **Keep work directory** until pipeline completes successfully
3. **Monitor resources** to optimize configuration
4. **Use background execution** for long-running jobs
5. **Check logs** if something goes wrong
6. **Generate reports** to understand performance

## Next Steps

- [Troubleshooting](/guide/troubleshooting) - Resolve common issues
- [Configuration](/guide/configuration) - Optimize settings
- [Output Files](/guide/output-files) - Understanding results
