# After Task: phylo X_lv bootstrap request metadata

**Date**: `2026-06-29`
**Executed by**: Codex, live DRAC lane.
**Branch**: `codex/phylo-xlv-drac-launcher-20260628` in
`/private/tmp/gllvmjl-phylo-xlv`.

## 1. Goal

Make future phylo `X_lv` DRAC result rows self-describing for bootstrap canary
decisions by recording the requested bootstrap count and bootstrap refit
iteration cap in the result CSV.

## 2. Implemented

- Added `n_boot` and `bootstrap_iterations` to the DRAC result schema.
- Added those values to every future task result row through the shared `base`
  tuple.
- Added `boot n` and `boot iter cap` columns to
  `bench/phylo_xlv_drac_summarise.jl`.
- Kept older result files backward-compatible: missing fields summarize as
  `NA`.

## 3a. Decisions and Rejected Alternatives

The current Nibi, Narval, and Rorqual canaries were already running with the
older result schema, so this change is for the next launches. I did not alter
the active jobs or relaunch them.

## 4. Files Touched

- `bench/phylo_xlv_drac_task.jl`
- `bench/phylo_xlv_drac_summarise.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-phylo-xlv-bootstrap-request-metadata.md`

## 5. Checks Run

```sh
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_boot_meta_params.csv --reps 1 --lambdas 0.5 --n-species 4 --n-sites 20 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260629
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_boot_meta_params.csv --outdir /tmp/phylo_xlv_boot_meta_results --task-id 1 --methods bootstrap --targets none --iterations 1 --n-boot 7 --bootstrap-iterations 11 --force
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_boot_meta_results
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_summariser_boot_meta_probe/results
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_summariser_old_schema_probe/results
git diff --check
Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-29-phylo-xlv-bootstrap-request-metadata.md
```

## 6. Tests of the Tests

The task-runner probe writes a real tiny result row whose header includes
`n_boot,bootstrap_iterations` and whose summary prints `boot n = 7` and
`boot iter cap = 11`. The new-schema summary probe must print `boot n = 30`,
`boot iter cap = 120`, and `bootstrap ok = 27`. The old-schema probe lacks the
new columns and must print `NA` for `boot n` and `boot iter cap` while still
printing `bootstrap ok = 27`.

## 7a. Issue Ledger

- Fixed: future bootstrap canary result rows carry both requested and converged
  bootstrap counts.
- Deferred: active canaries already running under the prior schema still need
  their denominator read from `meta/session.txt`.

## 8. Consistency Audit

This is a result-metadata/reporting change only. It does not change the DGP,
optimizer, likelihood, confidence interval calculation, or current active jobs.

## 9. What Did Not Go Smoothly

Nothing material. The change follows directly from the previous summarizer
slice, which exposed the converged count but still required session metadata
for the requested denominator.

## 10. Known Residuals

The active Nibi, Narval, and Rorqual timing canaries still need to be polled
and summarized when they return.

## 11. Team Learning

Fisher: interval canaries need requested denominator and achieved denominator
visible together.

Grace: write run settings into result rows as well as session metadata when
they are needed for triage.
