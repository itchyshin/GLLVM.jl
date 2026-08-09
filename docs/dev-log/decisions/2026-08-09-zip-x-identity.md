# Decision: ZIP + X identity (Julia-forward; twin asymmetric)

**Date:** 2026-08-09  
**Status:** ACCEPTED (Arc 0 docs-only; capacity programme S3 of post-#192)  
**Lane:** `docs/zip-x-identity-20260809` (Identity PR after S2 #197)  
**Depends on:** #169–#196 X/cohort precedents; two-part design
`docs/superpowers/specs/2026-05-31-two-part-families-design.md`; capacity plan
`docs/dev-log/plans/2026-08-07-post-bb-x-capacity-programme.md`.  
**Programme:** `lanes/post-bb-x-capacity-20260807/LOOP/` (**no ZIP engine**).

## Problem

Julia already has a named no-X ZIP fitter (`fit_zip_gllvm` / `ZIPFit`) with
structural-zero logits `βz`, count intercepts `βc`, count loadings `Λc`, and
the v1 default `Λ_z = 0`. The public bridge does **not** admit `zip` on the
one-part or fixed-effect-X surfaces. Twin gllvmTMB **cut ZIP/ZINB** from the
0.2.0 family list — there is no live twin light-oracle path and no
`family_to_id` entry for ZIP.

Without an identity lock, a future ZIP+X engine risks inventing an estimand
(which linear predictors get site-X; whether `Λ_z` stays 0) that later conflicts
with twin ZIP when it returns, or with CRAN `gllvm` ZIP+X conventions.

| Surface | Zero / occurrence | Count / value | Shared site-X |
|---|---|---|---|
| R / gllvmTMB ZIP | **absent** (cut 0.2.0) | **absent** | **absent** |
| Julia `fit_zip_gllvm` / `ZIPFit` | per-trait `βz`, `Λ_z = 0` | per-trait `βc` + `Λc` | **absent** |
| Julia bridge one-part / X | — | — | **not admitted** (`zip` ∉ `_BRIDGE_*`) |
| Julia `fit_zip_gllvm_*_cov` | — | — | **absent** |

## Twin asymmetry (load-bearing fence)

This Identity is **Julia-forward / twin-asymmetric**. Twin evidence at
decision time (local `gllvmTMB`):

1. **ZIP/ZINB cut** — `docs/dev-log/known-limitations.md` (≈L146–148):
   “Zero-inflated families (ZINB / ZIP). Cut from the 0.2.0 family list;
   planned for a later phase.”
2. **No `family_to_id` ZIP arm** — `R/fit-multi.R` `family_to_id` switch lists
   gaussian…nbinom1/multinomial and aborts on unsupported families; ZIP is not
   among the supported constructors in the abort message.

Therefore:

- Do **not** invent a twin light logLik Δ for ZIP+X.
- Do **not** claim R-parity for ZIP until twin ZIP lands and an Identity
  re-check runs.
- Secondary authority for shape: Julia two-part design §2.2 + CRAN `gllvm`
  ZIP (`Λ_z = 0` default; structural-zero mixture) — not a twin file:line for X.

## Julia route map (this tip @ `8112e533` / post-#196)

- Named no-X: `fit_zip_gllvm` / `ZIPFit`
  (`src/families/twopart.jl` — packed `[βz; βc; pack(Λc)]`, `Λ_z = 0`).
- Bridge one-part / X: `zip` **not** in `_BRIDGE_ONEPART_FAMILIES` or
  `_BRIDGE_X_FAMILIES` (`src/bridge.jl`).
- No `fit_zip_gllvm_grouped_cov` / shared-X kernel.
- Confint for no-X `ZIPFit` already exists in `confint_family.jl` (two-part
  adapter); that is **not** ZIP+X.

## Twin rule (non-negotiable)

GLLVM.jl mirrors gllvmTMB on **API and capabilities**, not on engine code.
When twin ZIP is absent, Julia may still lock a **forward** Identity so the
next engine arc does not invent estimands — but must not claim twin parity.
Bridge execution remains **R→Julia only** (JuliaCall); RCall parity cells are
opt-in developer oracles. No engine surgery on gllvmTMB from this repo.

## Decision (ZIP under shared site-X)

**Choose a two-part shared site-X identity that keeps the v1 ZIP latent
structure (`Λ_z = 0`) and puts shared site covariates on both linear
predictors**, with **separate** shared slope vectors:

1. **Structural-zero logit:**  
   `η^z_{ts} = β^z_t + Σ_k X[t,s,k] · γ^z_k`  
   (`Λ_z` remains **0** — no occurrence latent loadings under this Identity).
2. **Count log-mean:**  
   `η^c_{ts} = β^c_t + Σ_k X[t,s,k] · γ^c_k + (Λ_c z_s)_t`  
   (shared `γ^c`; per-trait `β^c`; reduced-rank `Λ_c` as today).
3. **Mixture mass** unchanged from §2.2 of the two-part design  
   (`P(y=0) = π0 + (1−π0)·e^{−μ}`, etc.).
4. **Public / bridge default under X (when an engine exists):** the shape in
   (1)–(2). Opt-in alternatives (X on count only; free `Λ_z`; shared single `γ`
   forced equal across parts) are **not** the default and need their own
   decision if pursued.
5. **Light RCall / twin Δ:** **forbidden** until twin ZIP is restored and this
   Identity is re-checked against the twin estimand. rtol stays `1e-6` when
   that day comes (no silent widen).

## Rejected alternatives

| Option | Why rejected |
|---|---|
| Skip Identity; jump to ZIP+X engine | Same class of risk #174/#185/#191 blocked |
| Pretend twin ZIP light Δ exists | Twin ZIP cut — false parity |
| X on count only as silent default | Leaves `π0` unaddressed under covariates; Fisher lock was both parts |
| Free `Λ_z` as default under X | Breaks v1 ZIP default / two-part design; larger engine |
| ZINB+X / hurdle+X / Tweedie+X as this Identity | Out of scope (G0 = ZIP+X only) |
| “Full family parity” from this note | Claim inflation |

## Engine shape (next implementation arc — **not this doc’s code**)

Preferred surgical path (confirm in a fresh `/arc-creation` / Ultra Plan after
this programme STOPs):

- Add `fit_zip_gllvm_cov` (name may shift) packing  
  `[βz; γ^z; βc; γ^c; pack(Λc)]` with offsets from `Xγ^z` / `Xγ^c` into the
  existing ZIP Laplace marginal (`Λ_z = 0` retained).
- Admit bridge / `@formula` ZIP+X only after FD/identity checks against this
  note.
- Re-check twin ZIP status at that G0 before any light RCall cell.

## Rose fence

**OK to claim after this decision lands:** “ZIP+X Identity Arc 0 ACCEPTED
(docs-only): shared site-X with separate `γ^z` / `γ^c`, `Λ_z = 0`,
Julia-forward / twin-asymmetric.”

**Not OK:** ZIP engine shipped · ZIP bridge X admitted · ZIP light RCall Δ ·
twin parity · ADEMP / coverage · ZINB+X / hurdle+X / Tweedie+X · full family
parity.

## Provenance

- Capacity programme G0 (#194) locked Identity family = ZIP+X docs-only.
- Twin cut cite: gllvmTMB `docs/dev-log/known-limitations.md` (ZIP/ZINB).
- Julia no-X substrate: `fit_zip_gllvm` / `ZIPFit` in `src/families/twopart.jl`.
- Shape authority: `docs/superpowers/specs/2026-05-31-two-part-families-design.md`
  §2.2 (ZIP mixture; `Λ_z = 0`).
