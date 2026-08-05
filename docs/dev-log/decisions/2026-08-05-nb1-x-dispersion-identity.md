# Decision: NB1 + X dispersion identity (twin with gllvmTMB)

**Date:** 2026-08-05  
**Status:** ACCEPTED (Arc 0 docs; G0 Q1–Q3: per-trait+X if twin confirms;
no-X short subsection; START HERE on execute)  
**Lane:** `cursor/nb1-x-identity-arc0-fffd` (PR #185)  
**Depends on:** #169–#181 X/cohort precedents (esp. #174 NB2/Beta+X identity;
#178 Gamma+X). Theme: **R–Julia parity** (light gllvmTMB track).

## Problem

Public / twin-facing NB1 no-X already estimates **per-trait** linear-variance
φ via the bridge → `fit_nb1_gllvm_grouped`. Fixed-effect X for NB1 is **not
wired**: bridge rejects `family="nb1"` + `X` as a documented follow-up, and
there is no `fit_nb1_gllvm_grouped_cov`.

| Surface | Dispersion (no-X) | Dispersion (shared site-X) |
|---|---|---|
| R / gllvmTMB `nbinom1()` (fid 15) | **per-trait** `φ_t = exp(log_phi_nbinom1[t])` | same TMB vector under site-X formulas |
| Julia bridge no-X `family="nb1"` | **per-trait** via `fit_nb1_gllvm_grouped` | — |
| Julia `fit_nb1_gllvm` (named) | **shared** scalar φ | — |
| Julia bridge / `@formula` + X | — | **no kernel** (ArgumentError) |
| Julia `fit_nb1_gllvm_grouped_cov` | — | **absent** |

Without an identity lock, any future light RCall NB1+X cell risks comparing
unlike estimands (shared-φ Julia vs per-trait R), the same failure mode #174
blocked for NB2/Beta.

## Twin evidence (fresh `gllvmTMB` `origin/main` @ `5bf18ab3`)

Cited from raw `main` fetch (cloud recon; see
`docs/dev-log/plans/scratch/nb1-x-twin-recon.md`):

1. **Family id** — fid 15 = NB1; Var = μ(1+φ); **per-trait φ via
   `log_phi_nbinom1`** (`src/gllvmTMB.cpp:355–356`).
2. **TMB parameter** — `PARAMETER_VECTOR(log_phi_nbinom1); // length n_traits`
   (`src/gllvmTMB.cpp:800`).
3. **Likelihood** — `log_v_minus_mu = log_mu + log_phi_nbinom1(t)`
   (`src/gllvmTMB.cpp:2369–2379`).
4. **Warmstart** — “NB2 / NB1 / Gamma / Tweedie **per-trait** dispersion”;
   `log_phi_nbinom1 = .clamp_log_phi(rep(0.0, n_traits))`
   (`R/fit-multi.R:4034–4039`).
5. **Site-X** — shared `X_fix * b_fix` (`src/gllvmTMB.cpp:206`, `:636`, `:848`).

## Julia route map (this repo @ `13d97b13` + lane)

See `docs/dev-log/plans/scratch/nb1-x-julia-recon.md`.

- Bridge no-X: `fit_nb1_gllvm_grouped` (`src/bridge.jl:952–954`).
- Shared named: `fit_nb1_gllvm` (`src/families/negbin1.jl:105–117`).
- Bridge + X: ArgumentError; nb1 not in `_BRIDGE_X_FAMILIES`
  (`src/bridge.jl:174–175`, `:397–410`); test lock
  `test/test_bridge_x.jl:374–377`.
- Formula + X routes NB2/Beta/Gamma/Ordinal cov paths; NB1 falls through /
  has no grouped_cov (`src/formula.jl:116–128`).

## Twin rule (non-negotiable)

GLLVM.jl mirrors gllvmTMB on **API and capabilities**, not on engine code.
Bridge execution remains **R→Julia only** (JuliaCall); RCall parity cells are
opt-in developer oracles. No engine surgery on gllvmTMB from this repo.

## Decision (API B under X)

**Choose per-trait NB1 φ as the public / twin-default path when shared site-X
is present**, matching gllvmTMB `log_phi_nbinom1` and the NB2/Beta/Gamma+X
precedent (#174 / #178).

Concretely:

1. **Public twin default (with X):** per-trait `φ_t` + shared site-X slopes
   `γ` (same shared-X formula shape as the existing X cohort).
2. **Shared-φ + X** remains an explicit opt-in (future single-group /
   `fit_gllvm_cov`-style path) — **not** the public twin default under X.
3. **No-X consistency (short):** already twin-aligned via bridge →
   `fit_nb1_gllvm_grouped`. Retain named shared `fit_nb1_gllvm` as opt-in.
   **No** Gamma-style Option B flip is required for NB1 no-X.
4. **Light parity cells** for NB1+X land only after an engine path that
   implements (1) exists and is FD/identity-checked; rtol stays `1e-6`
   (no silent widen).

## Rejected alternatives

| Option | Why rejected |
|---|---|
| Keep / invent shared φ as twin default under X | Breaks twin with `log_phi_nbinom1` length `n_traits` |
| Compare light logLik of shared-φ Julia to per-trait R | False parity; estimands differ |
| Skip identity and jump to engine | Same class of risk #174 blocked |
| Bundle Gamma no-X Option B / Tweedie / ZIP / Ordinal redo | Out of scope; hard fence |
| “Full family parity” from this note | Claim inflation |

## Engine shape (next implementation arc — not this doc’s code)

Preferred surgical path (confirm in Arc 1 Ultra Plan):

- Add `fit_nb1_gllvm_grouped_cov` mirroring
  `fit_nb_gllvm_grouped_cov` / `fit_beta_gllvm_grouped_cov` /
  `fit_gamma_gllvm_grouped_cov` (`η = β + Xγ + Λz`, θ packing with per-group
  `log φ`).
- Route bridge X and `@formula`+X for `nb1` / `nbinom1` through that path when
  dispersion is per-trait (future public default under X).
- Keep a shared-φ + X path as explicit opt-in.
- Identity checks before any RCall cell:
  - G=1 grouped+X with `hessian=:fisher` ≈ shared cov Fisher path (spirit of
    #172 / #175).
  - Constant `φvec` marginal with X offset equals shared cov marginal.

## Rose fence

**OK to claim after implementation + green light cells:**  
“NB1 + shared site-X light logLik under **per-trait** φ, twin to gllvmTMB
`nbinom1` / `log_phi_nbinom1`.”

**Not OK (this decision alone does not unlock):**

- full family parity;
- shared-φ Julia vs per-trait R light cells;
- ADEMP / coverage claims;
- Gamma no-X Option B flip;
- Tweedie / ZIP / ZINB / hurdle +X;
- `X_lv` NB1 redesign;
- Phylo Model A;
- any claim that Arc 0 docs imply engine or RCall green.

## Follow-ups

1. Engine Arc 1: `fit_nb1_gllvm_grouped_cov` (+ identity tests) — **only after**
   this note remains ACCEPTED.
2. Parity Arc 2: NB1+X light RCall cell(s), rtol `1e-6`, only after (1).
3. Optional later: coerce `fit_gllvm(...; family=NB1())` default
   `disp_group` like NB/Beta (ergonomics only; not required for twin bridge).
