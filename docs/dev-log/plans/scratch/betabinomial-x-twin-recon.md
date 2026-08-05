# Scratch: BetaBinomial+X twin recon (for Identity Arc 0)

**Date:** 2026-08-05  
**gllvmTMB tip:** `ab49638b` (local)

## Twin (load-bearing)

| Fact | Cite |
|---|---|
| Family id | fid **8** = `betabinomial` (`R/fit-multi.R:276`) |
| Parameter | `PARAMETER_VECTOR(log_phi_betabinom); // length n_traits` (`src/gllvmTMB.cpp:629`) |
| Likelihood | `a = μ·φ`, `b = (1−μ)·φ`; `phi_bb = exp(log_phi_betabinom(t))` (`:2081–2083`) |
| Warmstart | `log_phi_betabinom = .clamp_log_phi(rep(1.0, n_traits))` (`R/fit-multi.R:3585–3590`) |
| Link | logit only (`R/fit-multi.R:315`) |

## Why not Tweedie next

`fit-multi.R:1474–1477` — tweedie admitted only for diagnostic escape; **“tweedie stays reserved fail-loud for users.”**

## JuliaStats ecosystem (G0 #4)

- MixedModels.jl GLMM: Bernoulli / Binomial / Poisson only — **no BetaBinomial**.
- GLM.jl: no beta-binomial family.
- Distributions.jl: `BetaBinomial(n, α, β)` shapes — matches `a,b` story, not a fitter.
- Twin authority remains **gllvmTMB**.

## Julia GLLVM.jl gap (post-#186 tip)

- Named: `fit_beta_binomial_gllvm` — **shared** scalar φ.
- Bridge: **not** in `_BRIDGE_ONEPART_FAMILIES` / `_BRIDGE_X_FAMILIES`.
- No `fit_beta_binomial_gllvm_grouped` / `_grouped_cov`.
- Note: `src/GLLVM.jl` comment “gllvm family 15” for beta_binomial is **stale vs twin fid 8** (fid 15 is nbinom1 on gllvmTMB).

## Identity implication

Public twin default under shared site-X should be **per-trait φ** + shared γ (API B), mirroring NB2/Beta/NB1+X — locked in decision before any engine.
