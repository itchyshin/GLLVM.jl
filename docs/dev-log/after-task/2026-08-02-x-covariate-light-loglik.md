# After-task — X/covariate light logLik cohort 1

**Date:** 2026-08-02  
**Lane:** `x-covariate-light-loglik-20260802`  
**Branch:** `parity/x-covariate-light-loglik-20260802`  
**Base:** `origin/main` @ `4d19c503` (#169 merge)  
**Twin:** gllvmTMB `/tmp/gllvmtmb-parity-x-loglik-20260802` @ `910ebd54`  
**R lib:** `/tmp/R-gllvmtmb-x-parity-20260802` (via `GLLVM_PARITY_R_LIBS`)  
**Rose verdict:** **PASS WITH NOTES** — light logLik with **shared site X** for
Gaussian / Binomial / Poisson only. Not full family parity; NB2/Beta+X fenced.

## Goal

First cohort of X/covariate light gllvmTMB logLik parity cells (q=1 shared site
covariate), rtol `1e-6`, no silent tolerance widening.

## What landed

| Slice | Change |
|---|---|
| S0 | Worktree + branch from `origin/main`; twin recreate @ `910ebd54` |
| S1 | `fit_gllvmtmb_parity_loglik_x` + `parity_site_design`; twin `.libPaths` prepend; no-X helper intact |
| S2 | `test_x_covariate_parity.jl` (3 cells) + `runparity.jl` include + README |
| S3 | Live parity LOG — 3/3 X cells green at rtol 1e-6 |
| Close | LOOP kit; plan copy; after-task; check-log; board; plan-actual |

## Evidence (read Δ from log, not exit code)

Log: `docs/dev-log/x-covariate-parity-full-20260802.log` (also `/tmp/x-covariate-parity-full.log`)

```text
no-X suite (prior): 63/63 assertions green
Gaussian+X  Δ≈1.19e-9   Pass 6/6
Binomial+X  Δ≈3.40e-9   Pass 6/6
Poisson+X   Δ≈1.23e-9   Pass 6/6
X cohort                        18/18
```

Binomial DGP repaired once (seed 421 / n=30 → R runaway-loading warning); final
cell uses seed 431 / n=80 / milder loadings. **rtol unchanged at 1e-6.**

## Rose fence

Claim: **light logLik with shared site X** for Gaussian, Binomial, Poisson.  
Do **not** claim: NB2/Beta+X; Gamma+X; Ordinal+X; species-specific XB; X_lv;
ADEMP; coverage; “full family parity.”

## Next

Push/PR when maintainer asks. Optional later: NB2/Beta+X after shared-vs-per-trait
φ identity is designed; `test_grouped_dispersion.jl:61` remains a separate bug lane.
