# Process Flow

Detailed description of each process in the CheckRef pipeline.

## Process Execution Order

1. **VALIDATE_VCF_FILES** - Parallel (one per VCF)
2. **CHECK_ALLELE_SWITCH** - Parallel (one per chromosome)
3. **REMOVE_SWITCHED_SITES** or **CORRECT_SWITCHED_SITES** - Parallel
4. **VERIFY_CORRECTIONS** - Parallel
5. **CREATE_SUMMARY** - Single process (aggregates all)

## Parallelization

CheckRef automatically parallelizes across chromosomes:

- 22 autosomes + X, Y, MT can run simultaneously
- Each chromosome is independent
- No cross-chromosome dependencies
- Linear scaling with available resources

## Error Handling

- Failed VCF validation → Skip chromosome
- Build mismatch detected → Graceful exit with message
- Process failure → Can resume with `-resume`
- Verification failure → Reported in logs

## See Also

- [Modules](/api/modules) - Process details
- [Resource Usage](/workflow/resources) - CPU/memory needs
