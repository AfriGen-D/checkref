# Resource Usage

Typical resource requirements for CheckRef processes.

## Process Resources

| Process | CPUs | Memory | Time (typical) |
|---------|------|--------|----------------|
| VALIDATE_VCF_FILES | 1 | 4 GB | 5 min |
| CHECK_ALLELE_SWITCH | 1 | 4-8 GB | 30 min - 2 h |
| REMOVE_SWITCHED_SITES | 1 | 4 GB | 10-30 min |
| CORRECT_SWITCHED_SITES | 1 | 4 GB | 10-30 min |
| VERIFY_CORRECTIONS | 1 | 4 GB | 30 min - 2 h |
| CREATE_SUMMARY | 1 | 2 GB | 5 min |

## Factors Affecting Runtime

- **VCF size**: Larger files take longer
- **Number of variants**: More variants = more comparisons
- **Reference panel size**: Larger panels = more memory
- **Chromosome**: chr1 (largest) takes longest

## Optimization Tips

1. Run whole genome in parallel (all chromosomes at once)
2. Use local fast storage for work directory
3. Increase CPUs for CHECK_ALLELE_SWITCH to 2-4
4. Use SSD storage for better I/O
5. Enable `-resume` for failed runs

## Resource Planning

**Small dataset** (1 chromosome):
- Total time: 1-2 hours
- Peak memory: 8 GB
- Storage: 10 GB

**Whole genome** (22 autosomes):
- Total time: 4-8 hours (parallel)
- Peak memory: 8 GB per chromosome
- Storage: 100-500 GB

## See Also

- [Configuration](/guide/configuration) - Resource customization
- [Running](/guide/running) - Execution best practices
