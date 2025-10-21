# Pipeline Modules

CheckRef consists of 6 main processes that work together to detect and correct allele switches.

## Process Overview

| Process | Purpose | Input | Output |
|---------|---------|-------|--------|
| VALIDATE_VCF_FILES | Validate VCF integrity | VCF files | Validation status |
| CHECK_ALLELE_SWITCH | Detect allele switches | VCF + Legend | Switch results |
| REMOVE_SWITCHED_SITES | Remove problematic sites | VCF + Switches | Cleaned VCF |
| CORRECT_SWITCHED_SITES | Correct allele orientations | VCF + Switches | Corrected VCF |
| VERIFY_CORRECTIONS | Verify fixes were successful | Fixed VCF + Legend | Verification report |
| CREATE_SUMMARY | Aggregate statistics | All summaries | Final report |

## 1. VALIDATE_VCF_FILES

**Purpose**: Validate VCF file integrity and format compliance before processing.

**Resources**:
- CPU: 1
- Memory: 4GB
- Time: 1h
- Container: `mamana/vcf-processing:latest`

**Checks Performed**:
1. File exists and is readable
2. File size >100 bytes
3. Gzip integrity (if .gz)
4. VCF format compliance (bcftools)
5. Contains variant data

**Outputs**:
- `{chr}_validation_status.txt` - PASSED/FAILED status
- `{chr}_validation_report.txt` - Detailed report

**Example Report**:
```
====================================
VCF VALIDATION REPORT FOR CHR chr22
====================================
File: sample_chr22.vcf.gz
✅ VALIDATION PASSED: File appears to be valid
File format: Valid VCF
Status: Ready for processing
```

## 2. CHECK_ALLELE_SWITCH

**Purpose**: Compare VCF alleles against reference legend to detect switches.

**Resources**:
- CPU: 1  
- Memory: 4GB
- Time: 4h
- Container: `mamana/vcf-processing:latest`

**Algorithm**:
1. Extract common positions between VCF and legend
2. Compare REF/ALT alleles at each position
3. Identify REF↔ALT switches
4. Detect genome build mismatches
5. Generate switch report

**Outputs**:
- `{chr}_{sample}_allele_switch_results.tsv` - Detected switches
- `{chr}_{sample}_allele_switch_summary.txt` - Statistics
- `{chr}_extracted.legend.gz` - Filtered legend
- `BUILD_MISMATCH_DETECTED` - Flag file (if build mismatch)

**Switch Detection Logic**:
- Match: VCF REF=A,ALT=G and Legend REF=A,ALT=G ✅
- Switch: VCF REF=A,ALT=G and Legend REF=G,ALT=A ⚠️
- Mismatch: VCF REF=A,ALT=G and Legend REF=T,ALT=C ❌ (build error)

## 3. REMOVE_SWITCHED_SITES

**Purpose**: Create VCF with switched sites removed (default fix method).

**Resources**:
- CPU: 1
- Memory: 4GB  
- Time: 1h
- Container: `mamana/vcf-processing:latest`

**Process**:
1. Convert switch positions to BED format (0-based)
2. Use bcftools to exclude switched sites
3. Index output VCF
4. Report number of sites removed

**Outputs**:
- `{chr}_{sample}.noswitch.vcf.gz` - Cleaned VCF
- `{chr}_{sample}.noswitch.vcf.gz.tbi` - Index

**Command**: 
```bash
bcftools view -T ^exclude_sites.bed input.vcf.gz -Oz -o output.noswitch.vcf.gz
```

## 4. CORRECT_SWITCHED_SITES

**Purpose**: Correct allele orientations by swapping REF↔ALT (alternative fix method).

**Resources**:
- CPU: 1
- Memory: 4GB
- Time: 1h
- Container: `mamana/vcf-processing:latest`

**Process**:
1. Parse switch results for sites to fix
2. Swap REF and ALT alleles
3. Mark corrected sites with `SWITCHED=1` in INFO
4. Update genotypes accordingly
5. Sort and index output

**Outputs**:
- `{chr}_{sample}.corrected.vcf.gz` - Corrected VCF
- `{chr}_{sample}.corrected.vcf.gz.tbi` - Index
- `fixed_count.txt` - Number of sites corrected
- `failed_count.txt` - Number of sites failed (build mismatches)

**VCF Modifications**:
```vcf
##INFO=<ID=SWITCHED,Number=0,Type=Flag,Description="Alleles were switched to match reference">
#CHROM  POS     REF  ALT  INFO
chr22   100000  G    A    SWITCHED=1
```

## 5. VERIFY_CORRECTIONS

**Purpose**: Re-run allele switch detection on fixed VCF to verify success.

**Resources**:
- CPU: 1
- Memory: 4GB
- Time: 1h
- Container: `mamana/vcf-processing:latest`

**Process**:
1. Run CHECK_ALLELE_SWITCH on fixed VCF
2. Count remaining switches
3. Generate verification report

**Expected Result**: Zero switches remaining

**Outputs**:
- `{chr}_verification_results.txt` - Verification report

**Success Report**:
```
====================================
VERIFICATION RESULTS FOR CHR chr22
====================================
✅ VERIFICATION PASSED: No allele switches detected
Total switches found: 0
```

## 6. CREATE_SUMMARY

**Purpose**: Aggregate statistics from all chromosomes into a single report.

**Resources**:
- CPU: 1
- Memory: 2GB
- Time: 30min

**Process**:
1. Collect all per-chromosome summaries
2. Extract and sum statistics
3. Calculate percentages
4. Generate aggregated report

**Outputs**:
- `all_chromosomes_summary.txt` - Complete summary

**Report Sections**:
- Individual chromosome results
- Aggregated totals across all chromosomes
- Overlap statistics
- Allele comparison results

## Process Dependencies

```
VALIDATE_VCF_FILES
    ↓
CHECK_ALLELE_SWITCH
    ↓
    ├─→ REMOVE_SWITCHED_SITES → VERIFY_CORRECTIONS
    │                              ↓
    └─→ CORRECT_SWITCHED_SITES → VERIFY_CORRECTIONS
                                   ↓
                            CREATE_SUMMARY
```

## Customizing Process Resources

Override default resources in config:

```groovy
process {
    withName: CHECK_ALLELE_SWITCH {
        cpus = 2
        memory = 8.GB
        time = 8.h
    }
}
```

## Next Steps

- [Parameters](/api/parameters) - All parameters
- [Profiles](/api/profiles) - Execution profiles
- [Workflow](/workflow/) - Detailed workflow documentation
