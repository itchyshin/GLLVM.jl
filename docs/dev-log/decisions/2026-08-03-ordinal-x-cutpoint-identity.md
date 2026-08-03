# Decision: Ordinal + X cutpoint / identity (twin with gllvmTMB)

**Date:** 2026-08-03  
**Status:** ACCEPTED (Arc 0 docs; Ada judgment on Ultra-plan Q1–Q3 — Landing
WAIT; default YES; parallel docs from `origin/main`)  
**Lane:** `docs/ordinal-x-identity-20260803`  
**Depends on:** no-X per-trait ordinal bridge target
(`fit_ordinal_gllvm_pertrait`); Gamma/NB2+X identity pattern (#174 /
`2026-08-03-gamma-x-dispersion-identity.md`). **Does not** depend on Gamma
engine land or #177 (OWED landings outside this note).

## Problem

Ordinal has **no Gamma-like dispersion φ**. The estimand under identity is
the **cutpoint / threshold convention** plus how shared site-X enters η.
Public no-X Julia already defaults to **per-trait** cutpoints (twin target).
Shared site-X for ordinal is still a **documented engine gap** on the Julia
bridge — not a silent shared-cutpoint fallback.

| Surface | Cutpoints (no-X) | Cutpoints / mean under shared site-X |
|---|---|---|
| R / gllvmTMB `ordinal_probit` (fid 14) | **per-trait** τ₁=0 fixed; **K−2** free log-spacings | same cutpoint packing; site-X via shared `X_fix * b_fix` |
| Julia `fit_gllvm(...; family=Ordinal())` | **per-trait** via `fit_ordinal_gllvm_pertrait` | — |
| Julia bridge no-X `ordinal` / `ordinal_probit` | **per-trait** | — |
| Julia `fit_ordinal_gllvm` (`OrdinalFit`) | **shared** cutpoints (C−1 free base+incs) — comparator only | optional `X_lv` (LV predictor; **not** site-X γ) |
| Julia bridge / `@formula` + site-X | — | **no covariate kernel** — loud reject |

So under X the twin is **incomplete on Julia**, not inconsistent the way
pre-#174 NB2/Beta were (shared φ vs per-trait). The risk for Arc 1 is
shipping the wrong cutpoint identity or inventing light RCall before a
kernel exists. This note locks the target **before** any
`fit_ordinal_*_cov` work.

## Twin evidence (live `gllvmTMB` checkout @ `ab49638b` / `origin/main` `d53dfa29`)

1. **Family** — fid 14 `ordinal_probit` (`src/gllvmTMB.cpp:241–243`;
   `R/enum.R:20`).
2. **τ₁ = 0 fixed; K−2 free** — man: τ₀=−∞, τ₁=0, τ₂…τ_{K−1}, τ_K=+∞;
   “K-category trait therefore estimates K − 2 free cutpoints”
   (`man/ordinal_probit.Rd:24–26`, `:44–46`).
3. **Packing** — `PARAMETER_VECTOR(ordinal_log_increments)`; per-trait
   `n_ordinal_cuts_per_trait(t) = K_t − 2`; reconstruct
   `cuts(0)=0` then `+= exp(delta)` (`src/gllvmTMB.cpp:650–659`,
   `:2152–2167`).
4. **Setup** — `R/fit-multi.R:2403–2415` builds cutpoint metadata for fid 14.
5. **Site-X** — shared fixed-effect LP `eta_fix = X_fix * b_fix` applies
   before the fid-14 likelihood branch (`src/gllvmTMB.cpp:664–667`,
   `:2149+`). Twin does **not** switch to a different cutpoint identity when
   site covariates are present.
6. **JuliaCall gate** — twin documents Julia-engine ordinal-X as gated
   (`R/julia-bridge.R:2723–2728`), confirming the gap is on the Julia
   side, not a twin refusal of site-X for `ordinal_probit`.

Do **not** confuse RESPONSE fid-14 with the missing-predictor ORDERED path
(K−1 free `theta_ord`; cpp `:2247–2251`).

## Julia route map (this repo @ `0e241215`)

- No-X public: `fit_gllvm` → `fit_ordinal_gllvm_pertrait`
  (`src/families/fit_gllvm.jl:17`, `:144`).
- Bridge no-X: `ordinal` / `ordinal_probit` → per-trait fitter
  (`src/bridge.jl:1054–1058`); capability note per-trait default (`:562`).
- Per-trait packing: `τ[t,1]=0`; K−2 free log-spacings
  (`src/families/ordinal.jl:308–324`); init absorbs first threshold into β
  (`:327–351`). **Matches twin τ₁=0 / K−2.**
- Shared comparator: `_unpack_cutpoints` free base → C−1 free
  (`src/families/ordinal.jl:298–306`); docstring keeps it non-default
  (`:549–554`).
- Bridge / formula site-X: Ordinal **absent** from `_BRIDGE_X_FAMILIES`
  (`src/bridge.jl:171–173`, `:183–184`); X + ordinal → ArgumentError
  (`:393–405`). No `Ordinal` row in `fit_gllvm_cov` dispersion markers
  (`src/families/covariates.jl:103–108`).

## Twin rule (non-negotiable)

GLLVM.jl mirrors gllvmTMB on **API and capabilities**, not on engine code.
Bridge execution remains **R→Julia only** (JuliaCall); RCall parity cells are
opt-in developer oracles. No engine surgery on gllvmTMB from this repo.

## Decision (API B under X — cutpoint form)

**Choose per-trait ordinal cutpoints as the public / twin-default path when
shared site-X is present**, matching gllvmTMB `ordinal_probit` (τ₁=0, K−2
log-spacings per trait) and Julia’s existing no-X default. Site covariates
enter as **shared** slopes `γ` (same shared-X formula shape as the
G/Bin/Pois / NB2/Beta / Gamma+X cohort).

Concretely:

1. **Public twin default (with X):** per-trait cutpoints (τ₁=0 fixed; K−2
   free log-spacings per trait; per-trait intercepts as today) + shared
   site-X `γ`. Link: bridge `ordinal_probit` stays **probit**; bridge
   `ordinal` may remain cumulative-logit — do not claim cross-link machine
   parity (twin man already notes logit vs probit scale).
2. **Shared-cutpoint + X** is **not** the twin default. Keep
   `fit_ordinal_gllvm` / `OrdinalFit` as an explicit Julia-side comparator
   (and any future shared+X opt-in must be named as such). Do **not** route
   public bridge X through shared cutpoints.
3. **No-X default:** **retain** per-trait (`fit_gllvm` / bridge). No silent
   flip. Shared-cutpoint remains opt-in / test comparator only.
4. **Light parity cells** for Ordinal+X land only after an engine path that
   implements (1) exists and is FD/identity-checked; rtol stays `1e-6`
   (no silent widen). Twin RCall cells must use matching link
   (probit↔probit).

## Rejected alternatives

| Option | Why rejected |
|---|---|
| Shared-cutpoint as twin default under X | Breaks twin with fid-14 per-trait τ₁=0 / K−2 packing |
| Compare light logLik of shared-cutpoint Julia to per-trait R | False parity; estimands differ |
| Invent Ordinal+X engine / RCall in this Arc 0 | Out of scope; docs-only |
| Cargo-cult Gamma “dispersion identity” wording | Ordinal has no φ; estimand is cutpoints + X path |
| Treat `X_lv` on `OrdinalFit` as site-X γ | Different design; fence |
| Silent change to no-X shared vs per-trait | No inconsistency to flip; retain per-trait |
| Ordinal+X / ADEMP / Phylo Model A / “full family parity” / dual-PR Gamma tip | Hard fence |
| Force-merge #177 or push Gamma tip in this lane | G0 Q1 = WAIT; outside GOAL |

## Engine shape (next implementation arc — not this doc’s code)

Preferred surgical path (confirm in Ultra-plan for Arc 1):

- Add `fit_ordinal_gllvm_pertrait_cov` (name TBD) mirroring the grouped_cov
  pattern: `η = β + Xγ + Λz` with **per-trait** cutpoint packing unchanged
  (τ₁=0 / K−2 log-spacings).
- Route bridge X and `@formula`+X for `ordinal` / `ordinal_probit` through
  that path (probit key → `ProbitLink()`).
- Keep shared-cutpoint `fit_ordinal_gllvm` as comparator; do not make it the
  public X default.
- Identity checks before any RCall cell:
  - Constant / degenerate X offset: per-trait+X marginal equals no-X
    per-trait at the same cutpoint θ (same spirit as NB2/Beta/Gamma G=1
    identities).
  - FD gradient ≤ 1e-6 on the packed cov objective.

## Rose fence

**OK to claim after implementation + green light cells:**  
“Ordinal + shared site-X light logLik under **per-trait** cutpoints
(τ₁=0, K−2 log-spacings), twin to gllvmTMB `ordinal_probit` / shared
`X_fix`.”

**Not OK (this decision alone does not unlock):**

- full family parity;
- shared-cutpoint Julia vs per-trait R light cells;
- ADEMP / coverage claims;
- Ordinal+X engine or RCall green from docs alone;
- `X_lv` redesign as a substitute for site-X;
- Phylo Model A;
- silent no-X shared/per-trait flip;
- Gamma land / #177 merge as content of this note;
- any claim that Arc 0 docs imply engine or RCall green.

## Follow-ups

1. Engine Arc 1: per-trait ordinal + shared site-X cov fitter (+ identity
   tests) — **only after** this note remains ACCEPTED.
2. Parity Arc 2: Ordinal+X light RCall cell(s), rtol `1e-6`, matching link,
   only after (1).
3. **Named (orthogonal):** NB1+X still “no covariate kernel” — separate
   identity/engine lane; not bundled here.
4. **OWED outside this GOAL:** push/PR Gamma preferred tip
   `parity/gamma-x-arc2-20260803`; merge #177 when Julia CI green — do not
   dual-PR `fix/gamma-x-grouped-cov-20260803`.
