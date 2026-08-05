# After-task: BetaBinomial+X combined Arc 1+2 (engine + bridge + light RCall)

**Date:** 2026-08-05
**Lane:** `cursor/betabinomial-x-engine-arc12-20260805` (worktree
`gllvmjl-betabinomial-x-engine-20260805`)
**Base:** `main` @ `d5d61cb7` (#191 ACCEPTED Identity)
**Decision:** `docs/dev-log/decisions/2026-08-05-betabinomial-x-dispersion-identity.md`
**G0:** combined Arc 1+2 = **yes**; merge-on-green = **yes**; FD-outer first = **yes**
**PR:** not yet opened — see Next

## Goal

Land twin API B under X for BetaBinomial: per-trait Beta precision φ + shared
site-X γ (trials `N` retained) via `fit_beta_binomial_gllvm_grouped` /
`_grouped_cov`, bridge/`@formula` admit, Julia identity tests, and one light
gllvmTMB `betabinomial()`+X logLik cell @ rtol `1e-6`.

## What shipped (this repo state)

Engine + bridge landed in prior commits on this same lane (not redone here,
per instruction):

1. **`05019f52`** — `BetaBinomialGroupedFit` / `fit_beta_binomial_gllvm_grouped`
   (per-group φ, no X) + `BetaBinomialGroupedCovFit` /
   `fit_beta_binomial_gllvm_grouped_cov` (per-group φ + shared site-X γ, FD
   outer L-BFGS — this family's Laplace core has no analytic-Hessian variant).
2. **`185d8847`** — bridge one-part + X admit for `betabinomial` /
   `beta_binomial`; trials `N` threaded via `_BRIDGE_TRIALS_FAMILIES`;
   `_bridge_ci_guard_betabinomial` (no CI transport yet — Rose-fenced).

This slice (**S5–S6**):

3. **`parity_helpers.jl`** — extended `fit_gllvmtmb_parity_loglik_x` with an
   optional `N::AbstractMatrix` keyword and `:betabinomial` family arm. `N` is
   threaded to R as the `weights` argument to `gllvmTMB()`, which interprets a
   numeric `weights` vector of length `nrow(data)` as the per-row trial count
   for binomial/beta-binomial rows (fid 1/8; `gllvmTMB` `R/fit-multi.R:2031–2045`,
   the "API (B)" alternative to `cbind(successes, failures)`).
4. **`test_x_covariate_parity.jl`** — one new `@testset "BetaBinomial + shared
   X (q=1)"` nested inside the existing outer `@testset` (matches the
   post-hygiene file pattern): per-trait φ (`group=collect(1:p)`), trials
   `N=8`, `fit_beta_binomial_gllvm_grouped_cov` vs
   `fit_gllvmtmb_parity_loglik_x(...; family=:betabinomial, N=N)`, rtol `1e-6`,
   no widen.
5. **Docs closeout** — check-log, coordination board, AGENTS.md Phase-state
   snapshot, capability-status.md, LOOP `arcs.md`/`checkpoint.md`, Arc Card
   Actuals (this file's sibling edits).

## Verification

| Check | Result |
|---|---|
| `test/test_betabinomial_x_identity.jl` | **12/12** |
| `test/test_bridge_x.jl` | **224/224** |
| `test/test_bridge_capabilities.jl` | **128/128** |
| Live BetaBinomial+X RCall (`GLLVM_PARITY_TESTS=1`, local R 4.6.0 + `gllvmTMB` 0.6.0) | **PASS** — isolated focused cell seed=49, p=5, K=1, n=120, N=8: jl=`-1166.9723540530015`, r=`-1166.9723540680063`, **abs Δ=`1.500e-8`**, **rel Δ=`1.286e-11`** @ rtol `1e-6` |
| Full `test/parity/test_x_covariate_parity.jl` cohort (all 9 families incl. new BB cell) | **65/65** (re-verified end-to-end, not just the new cell) |
| Tolerance widen | **none** |

Evidence commands (reproducible locally):

```sh
GLLVM_PARITY_TESTS=1 julia --project=test/parity -e '
using Pkg; Pkg.develop(path=pwd())
using GLLVM, RCall, Test, Random, LinearAlgebra, Statistics, Distributions
include(joinpath("test","parity","parity_helpers.jl"))
include(joinpath("test","parity","test_x_covariate_parity.jl"))'
```

## Rose verdict

**PASS WITH NOTES** — OK to claim: "BetaBinomial+X engine under **per-trait**
φ + shared γ + trials `N`, twin to gllvmTMB `betabinomial()` /
`log_phi_betabinom`; Julia identity green (12/12); bridge X green (224/224);
light RCall Δ ≪ 1e-6 (abs ≈1.50e-8, seed=49), full X-covariate cohort 65/65."

**Not OK (this task alone does not unlock):**

- full family parity for BetaBinomial;
- ADEMP / simulation-recovery coverage claims;
- CI transport (Wald/profile/bootstrap) for BB grouped — bridge explicitly
  guards this off (`_bridge_ci_guard_betabinomial`);
- Tweedie / ZIP / ZINB / hurdle+X (not touched this arc);
- Phylo Model A.

## Remaining OWED

- None for live Δ — the light cell ran live against local R + gllvmTMB, no
  faked or projected numbers.
- PR not yet opened for this lane; merge-on-green (G0) still pending the PR
  itself and CI.
- Confidence intervals for BetaBinomial grouped(_cov) remain unimplemented
  (guarded fail-loud by `_bridge_ci_guard_betabinomial`) — a future arc, not
  this one.

## Next

Open a PR for `cursor/betabinomial-x-engine-arc12-20260805` → `main`. After
merge, coordination-board START HERE moves to the next family; do not start
Tweedie/ZIP without a fresh Identity decision (per G0 exclusions).
