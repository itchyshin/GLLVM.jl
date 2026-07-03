# After Task: phylo X_lv summariser bootstrap denominator

**Date**: `2026-06-29`
**Executed by**: Codex, live DRAC lane.
**Branch**: `codex/phylo-xlv-drac-launcher-20260628` in
`/private/tmp/gllvmjl-phylo-xlv`.

## 1. Goal

Expose the existing `bootstrap_converged` result field in
`bench/phylo_xlv_drac_summarise.jl`, so capped and uncapped bootstrap canaries
report how many bootstrap refits converged.

## 2. Implemented

- Added a `bootstrap ok` column to the DRAC summary table.
- Summed non-empty `bootstrap_converged` values within each summary group.
- Printed `NA` for non-bootstrap or older result rows that do not contain the
  field.

## 3a. Decisions and Rejected Alternatives

The task runner already writes `bootstrap_converged`, so the fitting path was
left untouched. The denominator (`n_boot`) lives in session metadata rather
than each result row; this slice reports the available numerator and keeps the
run-specific denominator in the recorded session file.

## 4. Files Touched

- `bench/phylo_xlv_drac_summarise.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-phylo-xlv-summariser-bootstrap-denominator.md`

## 5. Checks Run

```sh
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_summariser_bootstrap_probe/results
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_summariser_wald_probe/results
git diff --check
Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-29-phylo-xlv-summariser-bootstrap-denominator.md
```

## 6. Tests of the Tests

The bootstrap probe contains `bootstrap_converged=27`; the summary must print
`bootstrap ok` as `27`. The Wald probe leaves the field blank; the summary must
print `NA`.

## 7a. Issue Ledger

- Fixed: returned bootstrap canaries can now be summarized for converged refit
  count without manually opening the CSV.
- Deferred: result rows still do not store the requested `n_boot` denominator;
  use `meta/session.txt` for that value.

## 8. Consistency Audit

This is a post-processing/reporting change only. It does not change the DGP,
fitting, CI computation, or result CSV schema.

## 9. What Did Not Go Smoothly

Nothing material. The need became visible because the active capped/uncapped
bootstrap canaries are timing and denominator probes, not merely coverage rows.

## 10. Known Residuals

The active Nibi, Narval, and Rorqual canaries still have no result rows at this
checkpoint.

## 11. Team Learning

Fisher: coverage tables need denominator visibility before they can support a
method decision.

Grace: put canary decision fields in the default summary path, not only in raw
CSV rows.
