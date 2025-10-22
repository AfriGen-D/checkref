# Subworkflows

CheckRef is organized as a single cohesive workflow without separate subworkflows. All processes are directly integrated into the main workflow for simplicity and ease of maintenance.

## Main Workflow Components

The pipeline consists of the following main process groups:

### 1. Validation Processes
- **VALIDATE_VCF**: Checks VCF file integrity and format
- Ensures files are not empty, corrupted, or malformed
- Validates required VCF headers and structure

### 2. Detection Processes
- **DETECT_CHROMOSOME**: Automatically identifies chromosome from filename
- **MATCH_VCF_TO_LEGEND**: Pairs VCF files with corresponding reference legend files
- Handles various chromosome naming conventions

### 3. Analysis Processes
- **CHECK_ALLELE_SWITCH**: Core allele switch detection
- Compares REF/ALT alleles between target and reference
- Identifies MATCH, SWITCH, COMPLEMENT, and OTHER categories

### 4. Correction Processes
Two mutually exclusive correction methods:

**REMOVE_SWITCHED_SITES**:
- Removes variants with allele switches
- Creates cleaned VCF files
- Preserves only matching variants

**CORRECT_SWITCHED_SITES**:
- Swaps REF↔ALT alleles at switched sites
- Adds SWITCHED=1 flag to INFO field
- Maintains all variants while fixing orientation

### 5. Verification Processes
- **VERIFY_CORRECTIONS**: Validates that corrections were applied correctly
- Re-runs allele switch detection on corrected files
- Ensures no remaining switches in output

### 6. Aggregation Processes
- **CREATE_SUMMARY**: Combines per-chromosome results
- Generates aggregate statistics across all chromosomes
- Produces final summary reports

## Process Dependencies

The workflow follows this dependency chain:

```
VALIDATE_VCF
    ↓
DETECT_CHROMOSOME
    ↓
MATCH_VCF_TO_LEGEND
    ↓
CHECK_ALLELE_SWITCH
    ↓
[REMOVE_SWITCHED_SITES OR CORRECT_SWITCHED_SITES]
    ↓
VERIFY_CORRECTIONS
    ↓
CREATE_SUMMARY
```

## Parallel Processing

Multiple VCF files are processed in parallel through the workflow, with Nextflow automatically managing:
- Process scheduling
- Resource allocation
- Data flow between processes
- Error handling and retry logic

## Future Enhancements

Potential subworkflow candidates for future refactoring:
- **QC Subworkflow**: Quality control and validation steps
- **Detection Subworkflow**: Chromosome detection and matching
- **Correction Subworkflow**: Allele switch fixing logic
- **Reporting Subworkflow**: Summary generation and visualization
