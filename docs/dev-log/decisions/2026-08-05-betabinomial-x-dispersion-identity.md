# Decision: BetaBinomial + X dispersion identity (twin with gllvmTMB)

**Date:** 2026-08-05  
**Status:** ACCEPTED (Arc 0 docs-only; G0 packaging A of post-NB1 closeout)  
**Lane:** `docs/betabinomial-x-identity-20260805` (Identity PR after Species-XB)  
**Depends on:** #169–#186 X/cohort precedents (esp. #174 NB2/Beta+X; #178 Gamma+X;
#185 NB1+X Identity). Theme: **R–Julia parity** (light gllvmTMB track).  
**Programme:** `lanes/post-nb1-closeout-20260805/LOOP/` (packaging A; **no engine**).

## Problem

Julia already has a named BetaBinomial GLLVM fitter
(`fit_beta_binomial_gllvm`) with a **shared** scalar precision `φ`. The public
bridge **does not** admit `betabinomial` / `beta_binomial` on the one-part or
shared-X surfaces. Twin gllvmTMB estimates **per-trait** `φ_t` via
`log_phi_betabinom` under the same site-X formulas used by the rest of the
one-part cohort.

| Surface | Dispersion (no-X) | Dispersion (shared site-X) |
|---|---|---|
| R / gllvmTMB `betabinomial` (fid 8) | **per-trait** `φ_t = exp(log_phi_betabinom[t])` | same TMB vector under site-X |
| Julia bridge no-X | — | **absent** (not in `_BRIDGE_ONEPART_FAMILIES`) |
| Julia `fit_beta_binomial_gllvm` (named) | **shared** scalar φ | — |
| Julia bridge / `@formula` + X | — | **no kernel** (not in `_BRIDGE_X_FAMILIES`) |
| Julia `fit_beta_binomial_gllvm_grouped` / `_grouped_cov` | — | **absent** |

Without an identity lock, any future light RCall BetaBinomial+X cell risks
comparing unlike estimands (shared-φ Julia vs per-trait R) — the failure mode
#174 blocked for NB2/Beta and #185 for NB1.

## Twin evidence (local `gllvmTMB` @ `ab49638b`)

Cited in `docs/dev-log/plans/scratch/betabinomial-x-twin-recon.md`:

1. **Family id** — fid **8** = `betabinomial` (`R/fit-multi.R:276`).
2. **TMB parameter** — `PARAMETER_VECTOR(log_phi_betabinom); // length n_traits`
   (`src/gllvmTMB.cpp:629`).
3. **Likelihood** — `a = μ·φ`, `b = (1−μ)·φ`; `phi_bb = exp(log_phi_betabinom(t))`
   (`src/gllvmTMB.cpp:2081–2083`).
4. **Warmstart** — `log_phi_betabinom = .clamp_log_phi(rep(1.0, n_traits))`
   (`R/fit-multi.R:3585–3590`).
5. **Link** — logit only (`R/fit-multi.R:315`).
6. **Site-X** — shared fixed-effect design under the same one-part X path as the
   rest of the twin cohort (no BetaBinomial-specific X exclusion).

## Why not Tweedie / Exponential next

- **Tweedie:** twin user path is intentionally fail-loud
  (`R/fit-multi.R:1474–1477` — reserved diagnostic escape). Poor light-oracle
  target for the next +X rung.
- **Exponential:** thin special case of Gamma (α=1); weak as a ladder rung when
  Gamma+X is already landed.
- **JuliaStats GLMM surface:** MixedModels.jl / GLM.jl do **not** provide a
  BetaBinomial GLMM family; twin `gllvmTMB` remains the load-bearing authority
  (`log_phi_betabinom`).

## Julia route map (post-#186 / hygiene tip)

- Named shared: `fit_beta_binomial_gllvm` (`src/families/beta_binomial.jl`).
- Bridge one-part / X: **not** listed in `_BRIDGE_ONEPART_FAMILIES` or
  `_BRIDGE_X_FAMILIES` (`src/bridge.jl`).
- No `fit_beta_binomial_gllvm_grouped` / `_grouped_cov`.
- Stale comment risk: `src/GLLVM.jl` may still say “gllvm family 15” for
  beta_binomial; twin fid for BetaBinomial is **8** (fid 15 is nbinom1). Fix
  comments only in a later docs/engine arc — not required for this identity.

## Twin rule (non-negotiable)

GLLVM.jl mirrors gllvmTMB on **API and capabilities**, not on engine code.
Bridge execution remains **R→Julia only** (JuliaCall); RCall parity cells are
opt-in developer oracles. No engine surgery on gllvmTMB from this repo.

## Decision (API B under X)

**Choose per-trait BetaBinomial φ as the public / twin-default path when shared
site-X is present**, matching gllvmTMB `log_phi_betabinom` and the
NB2/Beta/Gamma/NB1+X precedent (#174 / #178 / #185).

Concretely:

1. **Public twin default (with X):** per-trait `φ_t` + shared site-X slopes `γ`
   (same shared-X formula shape as the existing X cohort).
2. **Shared-φ + X** remains an explicit opt-in (future single-group /
   named-shared cov path) — **not** the public twin default under X.
3. **No-X public default (when bridge admits the family):** per-trait φ via a
   future `fit_beta_binomial_gllvm_grouped` (or equivalent), mirroring the
   NB2/Beta/NB1 pattern. Named shared `fit_beta_binomial_gllvm` stays opt-in.
4. **Light parity cells** for BetaBinomial+X land only after an engine path that
   implements (1) exists and is FD/identity-checked; rtol stays `1e-6`
   (no silent widen).

## Rejected alternatives

| Option | Why rejected |
|---|---|
| Shared φ as twin default under X | Breaks twin with `log_phi_betabinom` length `n_traits` |
| Compare light logLik of shared-φ Julia to per-trait R | False parity; estimands differ |
| Skip identity and jump to engine | Same class of risk #174 blocked |
| Tweedie+X Identity / engine as next rung | Twin user path fail-loud; out of scope |
| Exponential+X as next Identity | Thin Gamma special case; defer |
| Bundle engine / bridge admit in this note | Hard fence — Identity-before-engine |
| “Full family parity” from this note | Claim inflation |

## Engine shape (next implementation arc — not this doc’s code)

Preferred surgical path (confirm in a future Arc 1 Ultra Plan):

- Add `fit_beta_binomial_gllvm_grouped` (+ `_grouped_cov`) mirroring the
  NB2/Beta/Gamma/NB1 grouped(+cov) Laplace packing (`η = β + Xγ + Λz`, per-group
  `log φ`, trials `N` retained).
- Admit bridge one-part + X keys for `betabinomial` / `beta_binomial` only after
  those kernels exist and identity-check.
- Keep named shared `fit_beta_binomial_gllvm` as explicit opt-in.
- Identity checks before any RCall cell:
  - G=1 grouped(+X) with Fisher Hessian ≈ shared (cov) Fisher path.
  - Constant `φvec` marginal equals shared marginal (with X offset when present).

## Rose fence

**OK to claim after implementation + green light cells:**  
“BetaBinomial + shared site-X light logLik under **per-trait** φ, twin to
gllvmTMB `betabinomial` / `log_phi_betabinom`.”

**Not OK (this decision alone does not unlock):**

- full family parity;
- shared-φ Julia vs per-trait R light cells;
- ADEMP / coverage claims;
- Tweedie / ZIP / ZINB / hurdle +X;
- any engine, bridge admit, or RCall green from Arc 0 docs alone;
- Phylo Model A.

## Follow-ups

1. Engine Arc 1: `fit_beta_binomial_gllvm_grouped` (+ `_grouped_cov`, identity
   tests) — **only after** this note remains ACCEPTED and Species-XB / hygiene
   landings are clear of the desk.
2. Parity Arc 2: BetaBinomial+X light RCall cell(s), rtol `1e-6`, only after (1).
3. Optional: fix stale “family 15” comment for beta_binomial vs twin fid 8.
