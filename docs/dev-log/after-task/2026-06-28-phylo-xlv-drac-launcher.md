# After Task: phylo X_lv Model A DRAC launcher scaffold

**Date**: `2026-06-28`
**Executed by**: Codex, live toolchain lane.
**Branch**: `codex/phylo-xlv-drac-launcher-20260628` in
`/private/tmp/gllvmjl-phylo-xlv`.

## Purpose

Move Phase 3 from a smoke-only local script toward a DRAC-ready coverage
campaign for Gaussian phylo Model A: predictor-informed latent scores (`X_lv`)
with trait-axis phylogenetic covariance. This is launcher and result-plumbing
work only; it does not create production coverage evidence.

## Changes

- Added `bench/phylo_xlv_drac_task.jl`, a one-seed-per-task Julia runner. It can
  write the full parameter grid and run a selected array row via
  `SLURM_ARRAY_TASK_ID`, `PHYLO_XLV_TASK_ID`, or `--task-id`.
- Added explicit Pagel-style covariance transformation
  `Sigma_pagel = lambda * Sigma + (1 - lambda) * I`, avoiding the earlier smoke
  script's ambiguous use of `lambda` for the phylogenetic loading matrix.
- Added long-format result rows for `B_lv` and phylogenetic signal with
  convergence, usable CI denominator, coverage, bias, RMSE, and error status.
- Added `bench/phylo_xlv_drac_summarise.jl`, which reports task-level coverage
  with MCSE plus entry-level coverage and usable-entry counts.
- Added `bench/phylo_xlv_drac_submit.sh`, a write-only-by-default SLURM array
  helper that writes params, session metadata, and an sbatch script under the
  requested output directory. It calls `sbatch` only with `--submit`.

## Validation

```sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_params_tiny.csv --reps 2 --lambdas 0,0.5 --n-species 4,5 --n-sites 20 --K 1,2 --scenarios main,null_alpha0,null_phylo0
```

Wrote 40 tiny probe tasks.

```sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_params_tiny.csv --outdir /tmp/phylo_xlv_results_tiny --task-id 1 --dry-run
bash -n bench/phylo_xlv_drac_submit.sh
PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=0 PHYLO_XLV_N_SPECIES=4 PHYLO_XLV_N_SITES=20 PHYLO_XLV_K=1 PHYLO_XLV_SCENARIOS=main,null_phylo0 PHYLO_XLV_TIME=0-00:15 PHYLO_XLV_MEM=2G PHYLO_XLV_THROTTLE=4 bench/phylo_xlv_drac_submit.sh --out /tmp/phylo_xlv_submit_probe
```

Dry-run parsing passed; shell syntax passed; write-only submit probe wrote
params, sbatch, and session metadata.

```sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_submit_probe/meta/phylo_xlv_params.csv --outdir /tmp/phylo_xlv_results_submit_probe --task-id 1 --methods wald --iterations 80 --force
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_submit_probe/meta/phylo_xlv_params.csv --outdir /tmp/phylo_xlv_results_submit_probe --task-id 2 --methods wald --iterations 80 --force
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_results_submit_probe
```

Two toy task runs completed (`main` and `null_phylo0`, p=4, n_sites=20, K=1).
The summariser read 4 result rows and reported usable `B_lv` Wald rows. The
toy phylogenetic-signal transformed-Wald rows had no usable intervals because
the fitted H² was on the boundary; the result is recorded as
`partial_or_failed`.

## Not Run

Full `Pkg.test()`, GitHub CI, DRAC `sbatch`, profile/bootstrap methods, and the
>=500 reps/cell production campaign were not run. Totoro/DRAC was not reachable
non-interactively from this session.

## Claim Boundary

IN: DRAC launcher and summariser plumbing, plus local toy file-format smokes.
PARTIAL: production array sizing, `seff` right-sizing, profile/bootstrap cost
calibration, and H² boundary behavior. OUT: calibrated Model A coverage,
R-side `phylo_latent(..., lv=~x)` exposure, non-Gaussian phylo `X_lv`, and
Model B.
