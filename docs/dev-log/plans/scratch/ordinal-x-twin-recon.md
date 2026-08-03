# Twin recon — ordinal_probit cutpoint + X surface (S0)

**Date:** 2026-08-03  
**Twin path:** `/Users/z3437171/Dropbox/Github Local/gllvmTMB`  
**Tips cited:** local HEAD `ab49638b`; `origin/main` `d53dfa29` (fresh fetch
2026-08-03). Line cites below match the live checkout used for `rg`/`sed`
(content identical on the ordinal_probit surface for these blocks).

## Family identity

- Public ordinal RESPONSE = **`ordinal_probit()`**, TMB fid **14**
  (`R/enum.R:20`; `src/gllvmTMB.cpp:241–243`; `R/fit-multi.R:282`).
- Link = probit only (`R/fit-multi.R:323`).

## Cutpoint convention (load-bearing)

| Rule | Evidence |
|---|---|
| τ₀ = −∞, **τ₁ = 0 fixed**, τ_K = +∞ | `man/ordinal_probit.Rd:24–26`; `src/gllvmTMB.cpp:2152–2164` |
| **K − 2 free** cutpoints per trait (τ₂…τ_{K−1}) | same man page; cpp `K_minus_2 = n_ordinal_cuts_per_trait(t)` `:2158` |
| Packing = **per-trait log-spacings** `ordinal_log_increments` | `PARAMETER_VECTOR(ordinal_log_increments)` `src/gllvmTMB.cpp:650–659` |
| Reconstruction: `cuts(0)=0`; then `+= exp(delta)` | `src/gllvmTMB.cpp:2164–2167` |
| Metadata: `n_ordinal_cuts_per_trait`, `ordinal_offset_per_trait` | `src/gllvmTMB.cpp:264–276`; built in `R/fit-multi.R:2403–2415` |
| Tidy extractor `effect="cutpoint"` / `extract_cutpoints` | `R/methods-gllvmTMB.R:800–812`; `man/extract_cutpoints.Rd:34` |

**Not** the missing-predictor ORDERED path (`theta_ord`, K−1 free base) —
cpp explicitly contrasts that with fid-14 (`src/gllvmTMB.cpp:2247–2251`).

## Formula / site-X surface

- Twin multi-fit uses shared fixed-effect LP `eta_fix = X_fix * b_fix`
  for all families including fid 14 (`src/gllvmTMB.cpp:664–667` then
  likelihood branch `fid == 14` at `:2149+`). Site covariates enter as
  **shared** slopes in `b_fix`, not as a separate ordinal-only X kernel.
- `ordinal_probit` is a first-class supported family in `fit-multi`
  (`R/fit-multi.R:286` support list).
- JuliaCall bridge **gates ordinal-X CIs** and documents ordinal-X as not
  yet on the Julia engine CI allow-list
  (`R/julia-bridge.R:2723–2728` — “NB1-X, ordinal-X, mixed-family-X …
  remain gated”). That is a **Julia engine gap**, not a twin TMB refusal of
  site-X for ordinal_probit.

## Implication for Ordinal+X identity

Twin public default under site-X = **same per-trait cutpoints (τ₁=0, K−2
log-spacings) + shared site-X γ** that no-X `ordinal_probit` already uses.
No evidence of a different cutpoint identity when X is present. Safe to
mirror Gamma/NB2 “API B under X” for cutpoints (per-trait) + shared γ.
