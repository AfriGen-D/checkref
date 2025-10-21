# Parameters Reference

Complete reference of all CheckRef parameters.

## Required Parameters

### --targetVcfs

**Type**: String  
**Required**: Yes  
**Default**: None

Target VCF file(s) to check for allele switches.

**Supported formats**:
- Single file: `"sample.vcf.gz"`
- Glob pattern: `"/path/to/vcfs/*.vcf.gz"`
- Comma-separated: `"chr1.vcf.gz,chr2.vcf.gz,chr3.vcf.gz"`

**Examples**:
```bash
# Single file
--targetVcfs "chromosome_22.vcf.gz"

# Glob pattern (recommended for multiple files)
--targetVcfs "/data/vcfs/sample_chr*.vcf.gz"

# Comma-separated list
--targetVcfs "chr1.vcf.gz,chr2.vcf.gz,chr3.vcf.gz"

# Absolute path with glob
--targetVcfs "/full/path/to/data/*.vcf.gz"
```

**Requirements**:
- Files must be valid VCF format (v4.0+)
- Gzipped (`.vcf.gz`) recommended
- Chromosome must be detectable from filename
- Files must not be empty or corrupted

**Chromosome Detection**:
CheckRef automatically extracts chromosome from filename:
- ✅ `sample_chr1.vcf.gz` → chr1
- ✅ `data.22.vcf.gz` → chr22
- ✅ `chrX.vcf.gz` → chrX
- ❌ `sample.vcf.gz` → Cannot detect (will warn)

---

### --referenceDir

**Type**: String  
**Required**: Yes  
**Default**: None

Directory containing reference panel legend files.

**Examples**:
```bash
# Local directory
--referenceDir "/data/reference_panels/"

# Network path
--referenceDir "/mnt/shared/1000G_legends/"

# Relative path (not recommended)
--referenceDir "../references/"
```

**Requirements**:
- Directory must exist and be readable
- Must contain legend files matching `--legendPattern`
- Legend files must have chromosome information
- Files can be gzipped or uncompressed

**Legend File Format**:
```
id              position   a0   a1
1:100000:A:G    100000     A    G
1:150000:C:T    150000     C    T
```

Or with CHROM column:
```
CHROM  POS      ID            REF  ALT
chr1   100000   1:100000:A:G  A    G
chr1   150000   1:150000:C:T  C    T
```

---

## Output Parameters

### --outdir

**Type**: String  
**Required**: No  
**Default**: `./results`

Main output directory for all results.

**Examples**:
```bash
# Default
--outdir results

# Custom directory
--outdir "/scratch/checkref_output"

# Dated output
--outdir "results_$(date +%Y%m%d)"
```

**Output structure**:
```
outdir/
├── allele_switch_results/
├── summary_files/
├── fixed_vcfs/
└── logs/
```

**Subdirectory Parameters**:

You can customize individual output directories:

```bash
params {
    outdir = "results"
    allele_switch_results = "${outdir}/switches"
    summary_files = "${outdir}/summaries"
    fixed_vcfs = "${outdir}/corrected"
    logs = "${outdir}/pipeline_logs"
}
```

---

## Analysis Parameters

### --fixMethod

**Type**: String  
**Required**: No  
**Default**: `remove`  
**Options**: `remove`, `correct`

Method to fix detected allele switches.

**Options**:

**`remove`** (default):
- Removes sites with allele switches
- Produces smaller VCF files
- Output: `*.noswitch.vcf.gz`
- Use when: You want to exclude problematic sites

**`correct`**:
- Swaps REF↔ALT alleles to match reference
- Keeps all sites
- Marks corrected sites with `SWITCHED=1` in INFO
- Output: `*.corrected.vcf.gz`
- Use when: You want to keep all sites but fix orientation

**Examples**:
```bash
# Remove switched sites (default)
--fixMethod remove

# Correct switched sites
--fixMethod correct
```

**Output Comparison**:

Input VCF: 10,000 variants, 100 switches detected

| Fix Method | Output Variants | Notes |
|------------|----------------|-------|
| `remove` | 9,900 | 100 sites removed |
| `correct` | 10,000 | 100 sites corrected, marked with SWITCHED=1 |

---

### --legendPattern

**Type**: String  
**Required**: No  
**Default**: `*.legend.gz`

Glob pattern to match legend files in reference directory.

**Examples**:
```bash
# Default (matches *.legend.gz)
--legendPattern "*.legend.gz"

# Uncompressed legend files
--legendPattern "*.legend"

# Custom naming
--legendPattern "1000G_*.legend.gz"
--legendPattern "reference_panel_*.leg.gz"

# Multiple extensions
--legendPattern "*.legend.{gz,txt.gz}"
```

**Pattern Matching**:

Files must match this pattern AND contain chromosome information:

```bash
# ✅ Will match with default pattern
ref_chr1.legend.gz
1000G_chr22.legend.gz
panel_1.legend.gz

# ❌ Won't match with default pattern
ref_chr1.leg.gz          # Different extension
panel_chr1.txt           # Not gzipped
```

---

## Resource Parameters

### --maxCpus

**Type**: Integer  
**Required**: No  
**Default**: `4`

Maximum number of CPUs per process.

**Examples**:
```bash
# Default
--maxCpus 4

# High-performance server
--maxCpus 16

# Limited resources
--maxCpus 2
```

**Notes**:
- Applies to all processes unless overridden in config
- Most CheckRef processes use 1 CPU
- `CHECK_ALLELE_SWITCH` can benefit from 2 CPUs

---

### --maxMemory

**Type**: String (with unit)  
**Required**: No  
**Default**: `8.GB`

Maximum memory per process.

**Examples**:
```bash
# Default
--maxMemory 8.GB

# High-memory node
--maxMemory 32.GB

# Limited resources
--maxMemory 4.GB
```

**Units**: GB, MB, KB, TB

**Typical Usage**:
- `VALIDATE_VCF_FILES`: 4GB
- `CHECK_ALLELE_SWITCH`: 4-8GB
- `CORRECT_SWITCHED_SITES`: 4GB
- `CREATE_SUMMARY`: 2GB

---

### --maxTime

**Type**: String (with unit)  
**Required**: No  
**Default**: `24.h`

Maximum time per process.

**Examples**:
```bash
# Default
--maxTime 24.h

# Short jobs
--maxTime 4.h

# Long-running HPC jobs
--maxTime 72.h
```

**Units**: h (hours), m (minutes), d (days)

**Typical Timing**:
- Small chromosome (chr22): 10-30 minutes
- Large chromosome (chr1): 1-4 hours
- Whole genome: 4-12 hours total

---

## Institutional Config Parameters

These parameters are for advanced institutional configurations (nf-core style).

### --custom_config_version

**Type**: String  
**Required**: No  
**Default**: `master`  
**Hidden**: Yes

Git commit ID for institutional configs.

---

### --custom_config_base

**Type**: String  
**Required**: No  
**Default**: `https://raw.githubusercontent.com/nf-core/configs/master`  
**Hidden**: Yes

Base directory for institutional configs.

---

### --config_profile_name

**Type**: String  
**Required**: No  
**Default**: None  
**Hidden**: Yes

Institutional config name.

---

### --config_profile_description

**Type**: String  
**Required**: No  
**Default**: None  
**Hidden**: Yes

Institutional config description.

---

## Parameter File

Instead of passing parameters on command line, use a parameter file:

**params.yaml**:
```yaml
targetVcfs: "/data/vcfs/*.vcf.gz"
referenceDir: "/data/reference/"
fixMethod: "correct"
outdir: "results"
legendPattern: "*.legend.gz"
maxCpus: 8
maxMemory: "16.GB"
maxTime: "12.h"
```

**Usage**:
```bash
nextflow run AfriGen-D/checkref \
    -params-file params.yaml \
    -profile docker
```

---

## Complete Parameter Table

| Parameter | Type | Default | Required | Description |
|-----------|------|---------|----------|-------------|
| `--targetVcfs` | string | | ✅ | Target VCF file(s) |
| `--referenceDir` | string | | ✅ | Reference legend directory |
| `--outdir` | string | `./results` | | Output directory |
| `--fixMethod` | string | `remove` | | Fix method: 'remove' or 'correct' |
| `--legendPattern` | string | `*.legend.gz` | | Legend file pattern |
| `--maxCpus` | integer | `4` | | Max CPUs per process |
| `--maxMemory` | string | `8.GB` | | Max memory per process |
| `--maxTime` | string | `24.h` | | Max time per process |
| `--help` | boolean | `false` | | Show help message |

---

## Examples

### Minimal Example

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "*.vcf.gz" \
    --referenceDir "/ref/" \
    -profile docker
```

### Full Example

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "/data/vcfs/sample_chr*.vcf.gz" \
    --referenceDir "/data/1000G_legends/" \
    --fixMethod correct \
    --legendPattern "*.legend.gz" \
    --outdir "/results/checkref_20251021" \
    --maxCpus 8 \
    --maxMemory "16.GB" \
    --maxTime "12.h" \
    -profile docker \
    -resume
```

### HPC Example

```bash
nextflow run AfriGen-D/checkref \
    --targetVcfs "\$SCRATCH/vcfs/*.vcf.gz" \
    --referenceDir "\$SCRATCH/reference/" \
    --fixMethod correct \
    --outdir "\$SCRATCH/results" \
    -profile singularity,hpc \
    -c cluster.config
```

---

## Next Steps

- [Profiles](/api/profiles) - Execution profiles
- [Modules](/api/modules) - Pipeline processes
- [Configuration](/guide/configuration) - Advanced configuration
