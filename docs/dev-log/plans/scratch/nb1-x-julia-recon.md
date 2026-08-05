# S1 — Julia recon: NB1 routes + bridge X gap

**Date:** 2026-08-05  
**Repo tip (plan branch base):** `origin/main` @ `13d97b13` (+ plan commits)

## No-X routes

| Path | Behaviour | Cite |
|---|---|---|
| Bridge no-X `family="nb1"` | **`fit_nb1_gllvm_grouped(..., group=1:p)`** — per-trait φ | `src/bridge.jl:952–954` |
| `fit_nb1_gllvm_grouped` | default `group = 1:p`; packing `[β; vec(Λ); log φ_1…log φ_G]` | `src/families/grouped_dispersion.jl:1207–1219` |
| Shared named fitter | `fit_nb1_gllvm` — single shared φ | `src/families/negbin1.jl:105–117` |
| `fit_gllvm(...; family=NB1())` | **not** in default `_fit_gllvm` table — needs `disp_group` to reach grouped | `src/families/fit_gllvm.jl:139–152`, `:159` |
| Docstring | NB1 listed under `disp_group` → `fit_nb1_gllvm_grouped` | `src/families/fit_gllvm.jl:43` |
| NB/Beta coerce | `disp_group=nothing` → `:species` for NB/Beta **only** (not NB1) | `src/families/fit_gllvm.jl:82–83` |

**No-X twin-facing path:** bridge → per-trait grouped. Shared `fit_nb1_gllvm`
is opt-in. **No Gamma-style Option B shared default** for NB1 bridge.

## +X routes (gap)

| Path | Behaviour | Cite |
|---|---|---|
| Bridge + X | **ArgumentError** — nb1 “documented follow-up” / no covariate fitter | `src/bridge.jl:397–410` |
| `_BRIDGE_X_FAMILIES` | poisson, binomial, negbinomial, beta, gamma, ordinal… — **no nb1** | `src/bridge.jl:174–175` |
| `@formula` + X | NB2/Beta/Gamma/Ordinal → `*_grouped_cov` / pertrait_cov; else `fit_gllvm_cov` | `src/formula.jl:116–128` |
| `fit_nb1_gllvm_grouped_cov` | **absent** | (contrast NB2/Beta/Gamma in `grouped_dispersion.jl`) |
| Test lock | `test/test_bridge_x.jl:374–377` expects throw on `family="nb1"` + `X` | |
| X light parity | no NB1 `@testset` in `test/parity/test_x_covariate_parity.jl` | |

## Scale map (for Arc 1)

Julia `NB1(φ)`: `Var = μ(1+φ)` (`src/families/negbin1.jl:1–18`). Same φ as twin
`exp(log_phi_nbinom1)`. Do not confuse with NB2 `r` where public φ=1/r.

## Implication for Arc 0

Identity must lock **+X default = per-trait φ + shared γ** before any
`fit_nb1_*_cov`. No-X already twin-aligned via bridge grouped — short
consistency subsection only (Q2).
