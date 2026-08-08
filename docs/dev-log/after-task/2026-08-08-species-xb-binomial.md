# After-task: Species-XB Binomial light RCall (capacity S1)

**Date:** 2026-08-08  
**Lane:** `parity/species-xb-binomial-20260808`  
**Worktree:** `.worktrees/gllvmjl-post-bb-x-capacity-20260808`  
**Base:** `origin/main` @ `d7f852df` (#195)  
**LOOP:** `lanes/post-bb-x-capacity-20260807/LOOP/`  
**Plan:** `docs/dev-log/plans/2026-08-07-post-bb-x-capacity-programme.md`

## Goal

Widen Species-XB light RCall from Poisson-only to Binomial Bernoulli
`(0 + trait):x` vs Julia `fit_gllvm_speciescov`, rtol `1e-6`. No `src/`
engine change. Gaussian optional under-run: **skipped** (`fit_gllvm_speciescov`
is Laplace non-Gaussian only).

## What shipped

1. `fit_gllvmtmb_parity_loglik_species_x` admits `:binomial` (`stats::binomial()`,
   N=1, no `weights`) alongside `:poisson`.
2. `test/parity/test_species_x_parity.jl` — Binomial q=1 Bernoulli cell
   (seed=49, p=5, K=1, n=80).
3. LOOP kit (S0) + recon notes + board/AGENTS/check-log + this after-task.

## Verification

| Check | Result |
|---|---|
| Binomial species-XB (seed=49, p=5, K=1, n=80, Bernoulli) | **Δ abs ≈ 1.322e-9** (rtol 1e-6) |
| Julia converged | **true** (`loglik ≈ -271.597100041`) |
| gllvmTMB converged | **true** (`logLik ≈ -271.597100042`) |
| Poisson species-XB regression (seed=48) | **Δ ≈ 4.20e-9** (unchanged) |
| Focused parity tally | **16 pass / 16 total** (5.6s after compile) |
| Tolerance widen | **none** |
| `src/` change | **none** |
| Gaussian species-XB | **skipped** (under-run / no speciescov Gaussian path) |

Command:

```sh
GLLVM_PARITY_TESTS=1 julia --project=test/parity -e '
using Pkg; Pkg.develop(path=".")
using GLLVM, RCall, Test, Random, LinearAlgebra, Statistics
include("test/parity/parity_helpers.jl")
include("test/parity/test_species_x_parity.jl")
'
```

Compute: laptop RCall (local R 4.6.0 + gllvmTMB 0.6.0). Totoro/DRAC not needed
for this light cell.

## Rose verdict

**OK** to claim: “Binomial species-XB light logLik under per-trait `B`, twin to
gllvmTMB `(0 + trait):x` (Bernoulli N=1).”

**Not OK:** full species-B multi-family cohort; Gaussian species-XB; X_lv;
ADEMP/coverage; full family parity; ZIP engine; BB grouped CI (S2, not this PR).

Rose verdict: **PASS WITH NOTES** — Gaussian explicitly skipped; S2/S3 still OWED.

## Remaining OWED

- PR1 merge-on-green (this landing).
- S2 BetaBinomial grouped CI + bridge guard lift.
- S3 ZIP+X Identity docs-only → board closeout → STOP.

## Next

Merge this PR on CI green, then S2 on a fresh branch from `origin/main`.
Do **not** start ZIP engine.
