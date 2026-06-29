# After Task: batched phylo-signal Wald timing helper

**Date**: `2026-06-29`
**Executed by**: Codex, live toolchain lane.
**Branch**: `codex/phylo-xlv-drac-launcher-20260628` in
`/private/tmp/gllvmjl-phylo-xlv`.

## Purpose

The Phase 3 DRAC diagnostics showed a likely performance trap: the benchmark
row for phylo-signal intervals called `phylo_signal_wald_ci()` once per trait,
and each public wrapper call can rebuild the full observed-information Hessian.
For p=200 this can mean up to 200 dense Hessians. The coverage campaign needs
one-Hessian-per-fit timing before any production array.

## Changes

- Added internal `_phylo_signal_wald_ci_all()` in
  `src/confint_derived_wald.jl`.
- Added a small internal `_transformed_wald_ci_with_sigma()` helper so all
  per-trait phylo-signal intervals can reuse one covariance matrix.
- Updated `bench/phylo_xlv_drac_task.jl` to use the batched helper when
  available, with a fallback to the existing public single-trait wrapper.
- Added a regression check in `test/test_confint_derived_wald.jl` that the
  batched helper agrees with the public single-trait wrapper for an interior
  phylo-signal trait.

## Validation

```sh
julia --project=. test/test_confint_derived_wald.jl
```

Passed: `115/115` in `22.9s`.

```sh
d=$(mktemp -d); julia --project=. bench/phylo_xlv_drac_task.jl --write-params "$d/params.csv" --reps 1 --lambdas 0 --n-species 3 --n-sites 8 --K 1 --scenarios main; julia --project=. bench/phylo_xlv_drac_task.jl --params "$d/params.csv" --outdir "$d/results" --task-id 1 --targets phylo_signal --iterations 20 --force; julia --project=. bench/phylo_xlv_drac_summarise.jl --results "$d/results"; cat "$d/results/result_000001.csv"
```

Passed: tiny target-only task converged in 12 iterations, wrote a
`phylo_signal` row with `ci_seconds=2.829`, and summarised successfully.

## DRAC State

Cancelled old-source target-only jobs before they entered the known per-trait
Hessian loop:

- Nibi `16926545_1`, cancelled after `00:23:17`.
- Rorqual `14909542_1`, cancelled after `00:17:29`.

Submitted replacement batched-source diagnostics from commit `451090c`:

- Nibi `16927325`;
- Rorqual `14909918`.

The old all-target Nibi job `16923927_1` remains running to measure the B_lv
Wald CI bottleneck.

## Not Run

Full `Pkg.test()` was not run because this is a narrow internal helper plus
benchmark-wiring change. The focused derived-CI test and target-only bench smoke
exercise the changed code path. No production DRAC array was launched.

## Claim Boundary

IN: one-Hessian batched phylo-signal interval timing for the DRAC harness.
PARTIAL: p=200, K=2 batched target results are still pending, and B_lv interval
timing remains unresolved. OUT: calibrated coverage, public R grammar exposure,
non-Gaussian phylo X_lv, and Model B.
