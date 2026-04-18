<!-- markdownlint-configure-file { "MD024": { "siblings_only": true } } -->

# Error codes

This page documents every code that `checkref` emits in
`fedimpute_error.json` on failure. The descriptor schema is defined in
the FedImpute repo
([docs/PIPELINE_ERROR_SCHEMA.md](https://github.com/mamanambiya/federated-imputation-system/blob/microservices-migration/docs/PIPELINE_ERROR_SCHEMA.md)).

**Codes are stable.** Once published here they keep the same meaning
forever. If behaviour needs to change in a breaking way, we issue a new
code rather than redefine an old one.

When the FedImpute UI shows a typed error card, its "Error docs ↗"
button links directly to the section for that code
(e.g. `docs/errors.md#build_mismatch`), so the anchor slugs are
effectively a public contract -- don't rename headings.

---

## `BUILD_MISMATCH`

**Severity**: `user_error`
**Remediation**: run the `vcf-liftover` workflow, then resubmit

The VCF's genome build differs from the reference panel's. For example:
your VCF has chromosomes named `20` (GRCh37/hg19) while the panel uses
`chr20` (GRCh38/hg38), or vice versa.

### How to fix

Run the
[VCF Liftover](https://github.com/AfriGen-D/vcf-liftover) workflow to
convert your VCF to the panel's build, then resubmit to Allele Switch
Checker. The FedImpute UI offers a one-click "Run vcf-liftover →" button
for this case with the source/target builds prefilled.

If you cannot liftover your data, the only alternative is to select a
reference panel that matches your VCF's build. Availability depends on
the node.

### Structured error example

```json
{
  "code": "BUILD_MISMATCH",
  "severity": "user_error",
  "summary": "NO MATCHES FOUND -- Build mismatch -- VCF is b37 (GRCh37/hg19), reference panel is b38 (GRCh38/hg38).",
  "remediation": {
    "kind": "run_workflow",
    "workflow_slug": "vcf-liftover",
    "params": { "source_build": "b37", "target_build": "b38" },
    "hint": "Run VCF Liftover (b37 -> b38) on your VCF, then resubmit."
  }
}
```

---

## `CHROMOSOME_MISMATCH`

**Severity**: `user_error`
**Remediation**: choose a panel that covers your chromosomes

Your VCF and the reference panel share the same genome build, but the
chromosomes in your VCF do not appear in the panel. For example, your
VCF covers `chr1` but the selected panel is chromosome-22-only.

### How to fix

- Check which chromosomes your VCF contains (`bcftools query -f '%CHROM\n' your.vcf.gz | sort -u`)
- Pick a reference panel whose `reference_panels` list includes those chromosomes
- Or subset your VCF to only the chromosomes the panel covers and submit per-chromosome

The FedImpute UI lists the chromosomes each panel covers on the panel
selection step.

---

## `NO_VCF_DETECTED`

**Severity**: `user_error`

The workflow started but no VCF files were discovered at the
`--targetVcfs` input path. This is normally a service-side routing bug
rather than something the user can fix directly.

### How to fix

- If you uploaded through the FedImpute UI, click **Retry**; the file
  may not have finished transferring to the compute node.
- If the retry fails too, file an issue so we can investigate the
  upload routing.

---

## `NO_LEGEND_DETECTED`

**Severity**: `user_error`

The workflow started but no reference legend files were discovered. The
`--referenceDir` and `--legendPattern` parameters are likely
misconfigured on the service side.

### How to fix

This is a **service configuration issue**, not a user problem. Please
report it by filing an issue on this repo with the job ID -- it means
whoever runs your FedImpute node has an outdated panel registration.

---

## `MATCHING_FAILED`

**Severity**: `user_error`

Fallback code for a no-match situation that the auto-classifier could
not identify as build mismatch, chromosome mismatch, or missing inputs.
The pipeline hit the "no VCF/legend pairs matched" condition but the
details do not fit any of the more specific buckets above.

### How to fix

Inspect the structured error's `detail` field (or the Logs tab in the
FedImpute UI) for the list of detected VCF chromosomes and legend
files. Usually the cause is one of:

- `chr`-prefix inconsistency that wasn't cleanly b37-vs-b38 (e.g. a
  subset of chromosomes using the prefix and others not)
- A `legendPattern` that matched files from a different panel
- An empty or corrupt VCF

If you see a pattern that looks like a generalisable case, please open
an issue so we can extend the classifier to promote it to a named code.

---

## Changelog

- **v1.1.0** -- Introduced `BUILD_MISMATCH`, `CHROMOSOME_MISMATCH`,
  `NO_VCF_DETECTED`, `NO_LEGEND_DETECTED`, and `MATCHING_FAILED` as
  part of the `fedimpute_error.json` structured-error adoption.
