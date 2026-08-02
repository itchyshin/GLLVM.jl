# Decision: NB2 / Beta + X dispersion identity (twin with gllvmTMB)

**Date:** 2026-08-02  
**Status:** ACCEPTED (Arc 0 on `main` via #174; Arc 1 engine on
`fix/nb2-beta-x-grouped-cov-20260802`)  
**Lane:** `docs/nb2-beta-x-identity-20260802`  
**Depends on:** #169 (default-route per-trait φ, no-X); #170 (shared-X light logLik G/Bin/Pois only)

## Problem

Public no-X NB2/Beta now default to **per-trait** dispersion (`fit_gllvm` →
`disp_group=:species` → grouped fitters), matching gllvmTMB. Fixed-effect X for
the same families still goes through `fit_gllvm_cov`, which estimates a **single
shared** `r` / `φ`. Bridge X rows for NB2/Beta use that shared path.

So the twin is inconsistent:

| Surface | Dispersion under X |
|---|---|
| R / gllvmTMB public default (intended twin) | per-trait φ (disp.group) |
| Julia `fit_gllvm` no-X | per-trait φ |
| Julia `fit_gllvm_cov` / bridge X | **shared** scalar φ |

Light RCall NB2/Beta+X cells were correctly **fenced** until this identity is
chosen. Without a lock, any parity cell would compare unlike estimands.

## Twin rule (non-negotiable)

GLLVM.jl mirrors gllvmTMB on **API and capabilities**, not on engine code.
Bridge execution remains **R→Julia only** (JuliaCall); RCall parity cells are
opt-in developer oracles.

## Decision (API B under X)

**Choose per-trait dispersion as the public / twin-default path for NB2 and Beta
when fixed-effect X is present**, matching no-X API B and gllvmTMB `disp.group`.

Concretely:

1. **Public twin default (with X):** per-trait `r_t` / `φ_t` + shared site-X
   slopes `γ` (same X formula shape as the G/Bin/Pois X cohort:
   `value ~ 0 + trait + x + latent(..., unique=FALSE)` on the R side).
2. **Shared-dispersion + X** remains available as an explicit opt-in (named
   shared fitter + covariate path, or `disp_group` forced to one group) — not
   the public default.
3. **Gamma+X** is out of this decision (Gamma no-X default is still shared /
   bridge-special; do not silently flip Gamma here).
4. **Light parity cells** for NB2+X and Beta+X land only after an engine path
   that implements (1) exists and is FD/identity-checked; rtol stays `1e-6`
   (no silent widen).

## Rejected alternatives

| Option | Why rejected |
|---|---|
| Keep shared φ as default under X | Breaks twin with no-X API B and with gllvmTMB disp.group |
| Compare light logLik of shared-φ Julia to per-trait R | False parity; estimands differ |
| Flip Gamma in the same PR | Separate identity; fence |

## Engine shape (next implementation arc — not this doc’s code)

Preferred surgical path (to confirm in implementation plan):

- Extend the grouped NB2/Beta Laplace objective to accept the same shared-X
  linear predictor used by `fit_gllvm_cov` (`η = β + Xγ + Λz`), **or**
- Add `fit_nb_gllvm_grouped_cov` / `fit_beta_gllvm_grouped_cov` thin wrappers
  that reuse grouped dispersion packing + cov offset machinery.
- Route bridge X for `negbinomial` / `beta` through that path when `disp_group`
  is per-trait (default).
- Keep `fit_gllvm_cov(...; family=NegativeBinomial()/Beta())` as the **shared**
  φ + X opt-in unless a later rename cascade says otherwise.

Identity checks before any RCall cell:

- G=1 grouped+X with `hessian=:fisher` ≈ shared `fit_gllvm_cov` (Fisher), same
  spirit as #172 one-group no-X identity.
- Constant `rvec` / `φvec` marginal with X offset equals shared cov marginal.

## Rose fence

**OK to claim after implementation + green light cells:**  
“NB2/Beta + shared site-X light logLik under **per-trait** φ, twin to
gllvmTMB disp.group.”

**Not OK:** full family parity; shared-φ Julia vs per-trait R; ADEMP/coverage;
Gamma+X flip; Phylo Model A.

## Follow-ups

1. Ultra-plan with bite-sized tasks (this lane).
2. Engine PR (separate) implementing the chosen path + identity tests.
3. Parity PR: NB2+X and Beta+X light cells (rtol 1e-6) only after (2).
