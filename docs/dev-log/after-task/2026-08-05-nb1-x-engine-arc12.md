# After-task: NB1+X combined Arc 1+2 (engine + light scaffold)

**Date:** 2026-08-05  
**Lane:** `cursor/nb1-x-engine-arc12-fffd` (PR #186)  
**Base:** `main` @ `210de76d` (#185 ACCEPTED identity)  
**Decision:** `docs/dev-log/decisions/2026-08-05-nb1-x-dispersion-identity.md`  
**G0:** OH default on R-facing path = **yes**; continue plan branch = **yes**

## Goal

Land twin API B under X for NB1: per-trait linear-variance φ + shared site-X
γ via `fit_nb1_gllvm_grouped_cov`, bridge/`@formula`, Julia identity tests,
and one light gllvmTMB `nbinom1`+X logLik cell @ rtol `1e-6`.

## What shipped

1. **OH Laplace weight** for grouped NB1 (`hessian=:observed`):
   `W = -μ·s_μ - (μ/φ)²·(trigamma(y+r)-trigamma(r))` under LogLink.
2. **`NB1GroupedCovFit` + `fit_nb1_gllvm_grouped_cov`** (default
   `hessian=:observed`; identity vs shared cov forces `:fisher`).
3. **Bridge / formula / confint:** `nb1` in `_BRIDGE_X_FAMILIES`;
   `_bridge_fit_onepart_cov` → grouped_cov; `@formula` `isa NB1` arm;
   `_family_ci(::NB1GroupedCovFit)`.
4. **Shared-φ opt-in:** `fit_gllvm_cov(...; family=NB1(φ))` via widened
   `GllvmCovFit.family::Any`.
5. **Tests:** `test/test_nb1_x_identity.jl`; bridge smoke expects success;
   parity helper `:nb1` → `nbinom1()`; light `@testset` seed=48.
6. **Docs:** board, AGENTS snapshot, check-log, parity table, capability
   evidence pointer, Arc Card Actuals.

## Verification

| Check | Result |
|---|---|
| `test/test_nb1_x_identity.jl` | **7/7** |
| `test/test_bridge_x.jl` | **208/208** |
| Live NB1+X RCall (`GLLVM_PARITY_TESTS=1`) | **PASS** — focused cell seed=48: jl=`-1110.8791732138086`, r=`-1110.87917321534`, abs Δ=`1.531e-9`, rel Δ=`1.379e-12` @ rtol `1e-6` (local 2026-08-05) |
| Tolerance widen | **none** |

## Rose verdict

**PASS WITH NOTES** — OK to claim: “NB1+X engine under **per-trait** φ +
shared γ, twin API B; Julia identity green; light RCall Δ ≪ 1e-6.”

**Not OK:** full family parity; ADEMP; Phylo Model A; second family in #186.

## Remaining OWED

- None for live Δ / merge (#186 MERGED @ `a100cc63`).
- Programme follow-on: Species-XB rebase/PR + BetaBinomial+X Identity
  (`docs/dev-log/plans/2026-08-05-post-nb1-closeout-programme-ultra-plan.md`).

## Next

Post-NB1 closeout programme (packaging A) — see coordination board START HERE.
