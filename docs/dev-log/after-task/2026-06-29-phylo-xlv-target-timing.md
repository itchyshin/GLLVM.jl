# After Task: phylo X_lv DRAC target timing instrumentation

**Date**: `2026-06-29`
**Executed by**: Codex, live toolchain lane.
**Branch**: `codex/phylo-xlv-drac-launcher-20260628` in
`/private/tmp/gllvmjl-phylo-xlv`.

## Purpose

The Phase 3 DRAC campaign needs to separate model-fit time from interval time
before launching production arrays. The p=200, K=2 canaries showed that the fit
can converge, but `B_lv` Wald intervals are the current wall-time bottleneck and
phylo-signal intervals are still unusable in the one-seed diagnostics.

## Changes

- Added a `ci_seconds` column to `bench/phylo_xlv_drac_task.jl` result rows.
- Added `--targets` to the task runner with `B_lv`, `phylo_signal`, `all`, and
  `none` options.
- Made `--targets none` write an explicit fit-only row with
  `ci_status=fit_only` after a converged fit.
- Threaded `PHYLO_XLV_TARGETS` through `bench/phylo_xlv_drac_submit.sh` and
  recorded it in session metadata.
- Added mean fit seconds and mean CI seconds to
  `bench/phylo_xlv_drac_summarise.jl`.
- Recorded the validation and the latest Nibi p=200, K=2 status in
  `docs/dev-log/check-log.md`.

## Validation

```sh
julia --project=. bench/phylo_xlv_drac_task.jl --help
bash -n bench/phylo_xlv_drac_submit.sh
d=$(mktemp -d); julia --project=. bench/phylo_xlv_drac_task.jl --write-params "$d/params.csv" --reps 1 --lambdas 0 --n-species 3 --n-sites 3 --K 1 --scenarios main; julia --project=. bench/phylo_xlv_drac_task.jl --params "$d/params.csv" --outdir "$d/results" --task-id 1 --targets none --dry-run; julia --project=. bench/phylo_xlv_drac_task.jl --params "$d/params.csv" --outdir "$d/results" --task-id 1 --targets all --dry-run
d=$(mktemp -d); julia --project=. bench/phylo_xlv_drac_task.jl --write-params "$d/params.csv" --reps 1 --lambdas 0 --n-species 3 --n-sites 8 --K 1 --scenarios main; julia --project=. bench/phylo_xlv_drac_task.jl --params "$d/params.csv" --outdir "$d/results" --task-id 1 --targets none --iterations 20 --force; julia --project=. bench/phylo_xlv_drac_summarise.jl --results "$d/results"; cat "$d/results/result_000001.csv"
```

Results: help text rendered; shell syntax check passed; `--targets none` and
`--targets all` both dry-ran on a tiny generated parameter file; a tiny actual
fit-only task converged in 12 iterations, wrote the new `ci_seconds` column, and
summarised successfully.

## DRAC State

At the latest poll, Nibi job `16923927_1` was still running at `00:59:33` wall
time. The fit had already converged in 47 iterations after `1394.49` seconds,
and the job remained in the `B_lv` Wald CI step. Rorqual job `14901949_1`
previously completed the same p=200, K=2 one-seed diagnostic in `03:59:54` with
usable B_lv Wald rows but unusable phylo-signal rows.

## Not Run

No production DRAC array was launched from this instrumentation slice. Full
`Pkg.test()` was not run because the change is bench orchestration only and the
targeted runner/wrapper/summariser validations exercised the changed behavior.

## Claim Boundary

IN: target-level timing instrumentation for the DRAC coverage harness. PARTIAL:
p=200, K=2 interval wall time remains unresolved, and phylo-signal intervals
remain unusable in the current one-seed diagnostics. OUT: any >=500 reps/cell
coverage claim, public `gllvmTMB` phylo grammar exposure, non-Gaussian phylo
X_lv, and Model B.
