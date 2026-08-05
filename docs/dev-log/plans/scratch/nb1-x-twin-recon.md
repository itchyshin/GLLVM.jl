# S0 — Twin recon: gllvmTMB NB1 / `nbinom1` under site-X

**Date:** 2026-08-05  
**Twin tip:** `gllvmTMB` `origin/main` @ `5bf18ab3`  
**Source:** raw fetch of `src/gllvmTMB.cpp` + `R/fit-multi.R` from
`https://github.com/itchyshin/gllvmTMB` (cloud VM; no local clone mount).

## Public family name

- R family constructor: **`nbinom1()`** (fid **15**).
- Comments also describe “NB1 negative binomial type-1”.
- GLLVM.jl bridge keys: `"nb1"` / `"nbinom1"` → `"nb1"`.

## Dispersion packing (load-bearing)

| Item | Cite |
|---|---|
| Family id | `src/gllvmTMB.cpp:355–356` — fid 15 = NB1; Var = μ(1+φ); **per-trait φ via `log_phi_nbinom1`** |
| TMB parameter | `src/gllvmTMB.cpp:800` — `PARAMETER_VECTOR(log_phi_nbinom1); // length n_traits (or 1 if unused)` |
| Likelihood | `src/gllvmTMB.cpp:2369–2379` — fid==15; `log_v_minus_mu = log_mu + log_phi_nbinom1(t)` |
| Warmstart | `R/fit-multi.R:4034–4039` — “NB2 / NB1 / Gamma / Tweedie **per-trait** dispersion”; `log_phi_nbinom1 = .clamp_log_phi(rep(0.0, n_traits))` |
| Map when unused | `R/fit-multi.R:4680–4690` — map off length-`n_traits` vector when no fid-15 rows |
| Family table | `R/fit-multi.R:369–370`, `:434` — `nbinom1 = 15L` |

**Verdict:** public ordinary NB1 / `nbinom1` on twin main is **per-trait φ**
(`log_phi_nbinom1` length `n_traits`). Same spirit as NB2/Gamma under X.

## Site-X / shared slopes

Twin shared fixed effects enter via `X_fix * b_fix`
(`src/gllvmTMB.cpp:206`, `:636`, `:848`). Site covariates are shared slopes
across traits (same X-cohort shape as NB2/Gamma/Ordinal+X decisions). No
evidence that NB1 under site-X collapses to a scalar φ by default.

## Scale

Twin / gllvm NB1: `Var = μ(1+φ) = μ + φ·μ` with `φ = exp(log_phi_nbinom1)`.
Matches Julia `NB1(φ)` / `negbin1.jl` comments (gllvm `negative.binomial1`).

## Implication for Arc 0

Twin confirms **API B under X** candidate: **per-trait φ_t + shared site-X γ**.
Do **not** compare a future shared-φ Julia+X path to per-trait R as “parity.”
