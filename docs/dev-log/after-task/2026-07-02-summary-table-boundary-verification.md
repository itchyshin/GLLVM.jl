# After Task: Summary Table Boundary Verification

## Goal

Verify the summary / coefficient-table post-fit surface after the LV and
post-fit documentation cleanup slices.

## Implemented

No source behavior changed. The current docs already match the tested contract:
`coef_table` wraps Wald `confint`, adds `z` and `pvalue`, preserves standard
errors and bounds, and forwards selectors such as `parm`.

## Mathematical Contract

N/A - no likelihood, inference, or table calculation changed.

## Files Changed

docs:

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-summary-table-boundary-verification.md`

## Tests Added

None.

## Benchmark Numbers

N/A.

## R-Parity Verdict

N/A - no R bridge behavior changed.

## JET / Allocs / Aqua Verdicts

- JET: not run.
- Allocs: not run.
- Aqua: not run.

## Checks Run

```sh
julia --project=. --startup-file=no test/test_summary_table.jl
# Summary / coefficient table | 14 pass

sed -n '1,220p' test/test_summary_table.jl
sed -n '1,180p' src/summary_table.jl
rg -n "coef_table|summary_table|coefficient table|Summary / coefficient|coef\\(|pvalue|p-value|std_error|z statistic|two-sided" README.md docs/src src test
```

## Consistency Audit

The docs and implementation agree that `coef_table` is a presentation layer over
Wald confidence intervals, not a separate inference method. Non-finite standard
errors produce `NaN` `z` and `pvalue`, and `parm` forwarding is covered.

## GitHub Issue Maintenance

No issue or PR action taken.

## What Did Not Go Smoothly

Nothing material.

## Team Learning

Rose: no patch is needed when the docs already match the tested behavior; record
the verification and keep moving.

## Remaining Risks

- Full `Pkg.test()` is still not available from tonight's run.

## Known Limitations

This is verification-only.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && julia --project=. --startup-file=no test/test_structural_confint.jl
```

## Rose Verdict

Rose verdict: OK. No overclaim found in the summary-table docs touched by this
audit.
