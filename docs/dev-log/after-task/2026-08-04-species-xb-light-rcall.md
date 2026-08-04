# After-task: Species-XB light RCall Arc 0 (Poisson)

**Date:** 2026-08-04  
**Lane:** `parity/species-xb-light-20260804`  
**Worktree:** `.worktrees/gllvmjl-species-xb-arc0-20260804`  
**Base:** `origin/main` @ `a92c5040` (#181)  
**LOOP:** `lanes/species-xb-light-20260804/LOOP/`  
**Arc card:** `docs/dev-log/plans/2026-08-04-species-xb-light-rcall-arc-card.md`

## Goal

Prove Julia `fit_gllvm_speciescov` (per-trait `B`) matches live gllvmTMB
`(0 + trait):x` for Poisson at rtol `1e-6`. No B-engine rebuild; no ADEMP;
no full-family-parity claim.

## What shipped

1. `fit_gllvmtmb_parity_loglik_species_x` — R formula
   `value ~ 0 + trait + (0 + trait):x + latent(...)` (Arc 0: `:poisson` only).
2. `test/parity/test_species_x_parity.jl` — Poisson q=1 cell via
   `fit_gllvm_speciescov`.
3. Under-run hygiene: board/AGENTS/#181 MERGED; parity README Ordinal+X claimed;
   ROADMAP §1 “B next” → engine landed / light RCall next.
4. LOOP kit + check-log + this after-task.

## Verification

| Check | Result |
|---|---|
| Poisson species-XB (seed=48, p=5, K=1, n=80) | **Δ ≈ 4.20e-9** (rtol 1e-6) |
| Julia converged | **true** (`loglik ≈ -768.711834789`) |
| gllvmTMB converged | **true** (`logLik ≈ -768.711834793`) |
| Tolerance widen | **none** |
| `src/` B-engine redesign | **none** |

## Rose verdict

**OK** to claim: “Poisson species-XB light logLik under per-trait `B`, twin to
gllvmTMB `(0 + trait):x`.”

**Not OK:** multi-family species-XB cohort; X_lv; ADEMP/coverage; full family
parity; B-engine redesign claim.

## Remaining OWED

- Push / PR when Shinichi asks.
- Later rungs (separate G0): Binomial/Gaussian species-XB; dispersion families
  only with identity if needed.

## Next

`START A FRESH TASK` for push/PR — do not redo the Poisson cell.
