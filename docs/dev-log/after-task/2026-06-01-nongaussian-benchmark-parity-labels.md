# After Task: Non-Gaussian Benchmark Parity Labels

## Goal

Make the local `gllvmTMB` benchmark harness label non-Gaussian smoke rows with
the specific reason they are not yet strict likelihood-parity evidence.

## Implemented

`bench/non_gaussian_gllvmtmb_bench.jl` now reports family-specific agreement
statuses for NegBin, Beta, and Gamma instead of collapsing them into the generic
parameterization-audit label. No fitter source, package API, public docs, or
likelihood code changed.

## Mathematical Contract

The benchmark still fits Julia and R `gllvmTMB` on the same simulated data. The
new labels do not change the fitted objective; they make the interpretation of
the comparison explicit: NegBin differs by dispersion scope, Beta differs by
precision scope, Gamma needs a sigma/shape likelihood audit, and Ordinal uses a
non-equivalent link.

## Files Changed

- `bench/non_gaussian_gllvmtmb_bench.jl` - sharpened `agreement_status`.
- `docs/dev-log/check-log.md` - evidence ledger entry for the label audit.
- `docs/dev-log/after-task/2026-06-01-nongaussian-benchmark-parity-labels.md`
  - this audit report.

## Tests Added

No package tests were added. This is a benchmark-harness interpretation change
only, and the verification is the smoke benchmark output plus R parameter-name
introspection.

## Benchmark Numbers

Fresh smoke command from the current tree:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --smoke --families=negbin,beta,gamma,ordinal --reps=1 --warmups=1 --out=/tmp/non-gaussian-gllvmtmb-status-labels-2026-06-01-rerun.csv
```

Median elapsed seconds:

| family | Julia (s) | gllvmTMB (s) | R / Julia | agreement status |
| --- | ---: | ---: | ---: | --- |
| NegBin | 0.0348 | 0.5860 | 16.85x | `dispersion_scope_mismatch_r_trait_specific` |
| Beta | 0.0158 | 0.5580 | 35.29x | `precision_scope_mismatch_r_trait_specific` |
| Gamma | 0.0161 | 0.4940 | 30.59x | `gamma_sigma_eps_shape_audit_needed` |
| Ordinal | 0.1090 | 0.4830 | 4.43x | `non_equivalent_link` |

These timings are smoke evidence only. The important result for this slice is
that the CSV rows now carry the correct interpretive labels.

## R-Parity Verdict

Parity: labels clarified, not resolved. Gaussian/Binomial/Poisson remain the
same-data comparable rows from the broader smoke harness; NegBin, Beta, Gamma,
and Ordinal are now explicitly marked with their non-parity reason.

## JET / Allocs / Aqua Verdicts

- JET: N/A - benchmark-harness label change only.
- Allocs: N/A - no source hot path changed.
- Aqua: N/A - no package metadata or exported API changed.

## CI And Bootstrap Status

No confidence-interval, bootstrap, CI, or package source code was edited. No
branch CI was run because this branch was not pushed.

## Checks Run

Temporary R parameter-name introspection on `gllvmTMB` 0.2.0 showed:

```text
NB par length: 15
"b_fix" x5, "theta_rr_B" x5, "log_phi_nbinom2" x5
Beta par length: 15
"b_fix" x5, "theta_rr_B" x5, "log_phi_beta" x5
Gamma par length: 11
"b_fix" x5, "log_sigma_eps" x1, "theta_rr_B" x5
```

The current-tree smoke benchmark completed and wrote
`/tmp/non-gaussian-gllvmtmb-status-labels-2026-06-01-rerun.csv`.

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "dispersion_scope_mismatch|precision_scope_mismatch|gamma_sigma_eps_shape_audit_needed|same_data_parameterization_audit_needed" bench/non_gaussian_gllvmtmb_bench.jl docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-nongaussian-benchmark-parity-labels.md
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over tracked public artifacts: clean.
- Placeholder rerun scan: clean for the guard patterns used in this audit.
- Status-label scan: expected current harness/report hits plus older historical
  benchmark-ledger rows that retain their original generic status wording. The
  generic fallback remains in `agreement_status` for unknown future family
  names.
- GitHub lane check: open PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM`; this slice did not edit that lane.

## GitHub Issue Maintenance

No issue action was taken. This is local benchmark-harness evidence hygiene.

## What Did Not Go Smoothly

The earlier generic label was too blunt: it correctly avoided false parity
claims, but it hid the concrete reason each family still needs audit work.

## Team Learning

Hopper: R parameter names show trait-specific dispersion/precision for the
smoke NB/Beta cells. Fisher: speed rows need a separate agreement-status column
so a fast row cannot be mistaken for strict likelihood parity.

## Remaining Risks

- The full small/medium/large benchmark grid has not been rerun.
- NegBin/Beta/Gamma parity is still unresolved; only the benchmark labels are
  more precise.
- Ordinal remains a timing smoke because the links differ.

## Known Limitations

No family parameterization was changed, no public claim was promoted, and no R
benchmark dependency was added to package tests.

## Next Command

```sh
git status --short --branch
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - benchmark labels are now specific and audited, but this does not resolve the underlying non-parity items.
