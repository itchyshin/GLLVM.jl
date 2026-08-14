# Decision: ZINB + X identity (Julia-forward; twin asymmetric)

**Date:** 2026-08-13  
**Status:** ACCEPTED (Arc 0 docs-only; after ZIP+X confint #201)  
**Lane:** `docs/zinb-x-identity-20260813`  
**Depends on:** ZIP+X Identity #198; ZIP+X engine #200; ZIP+X confint #201 @
`8abdd751`; two-part design
`docs/superpowers/specs/2026-05-31-two-part-families-design.md` §2.2 / §3.  
**Clone from:** `docs/dev-log/decisions/2026-08-09-zip-x-identity.md`.  
**Do not re-open** the ZIP+X Identity.

## Problem

Julia already has a named no-X ZINB fitter (`fit_zinb_gllvm` / `ZINBFit`) with
structural-zero logits `βz`, count intercepts `βc`, count loadings `Λc`, the
v1 default `Λ_z = 0`, and a **shared scalar** NB2 dispersion `r` packed as
`log r`. The public bridge does **not** admit `zinb` on the one-part or
fixed-effect-X surfaces. Twin gllvmTMB **cut ZIP/ZINB** from the 0.2.0 family
list — there is no live twin light-oracle path and no `family_to_id` entry for
ZINB.

Without an identity lock, a future ZINB+X engine risks inventing an estimand
that later conflicts with twin ZINB when it returns, or that silently copies
the **NB2 per-trait φ** default (that lock was twin-backed; ZINB has no twin
surface). The ZIP+X dual-`γ` shape is already ACCEPTED and shipped; ZINB+X
must reuse that occurrence/count split and **keep** the no-X shared-`r`
convention.

| Surface | Zero / occurrence | Count / value | Dispersion | Shared site-X |
|---|---|---|---|---|
| R / gllvmTMB ZINB | **absent** (cut 0.2.0) | **absent** | **absent** | **absent** |
| Julia `fit_zinb_gllvm` / `ZINBFit` | per-trait `βz`, `Λ_z = 0` | per-trait `βc` + `Λc` | **shared scalar `r`** (`log r`) | **absent** |
| Julia bridge one-part / X | — | — | — | **not admitted** (`zinb` ∉ `_BRIDGE_*`) |
| Julia `fit_zinb_gllvm_*_cov` | — | — | — | **absent** |
| Julia ZIP+X (`ZIPCovFit`, #200/#201) | separate `γ^z`, `Λ_z = 0` | separate `γ^c` + `Λc` | — | **shipped** (reuse this dual-`γ`) |

## Twin asymmetry (load-bearing fence)

This Identity is **Julia-forward / twin-asymmetric**. Twin evidence at
decision time (local `gllvmTMB` @ `9518d1bf`):

1. **ZIP/ZINB cut** — `docs/dev-log/known-limitations.md` (L146–148):
   “Zero-inflated families (ZINB / ZIP). Cut from the 0.2.0 family list;
   planned for a later phase.”
2. **No `family_to_id` ZINB arm** — `R/fit-multi.R` `family_to_id` switch
   (L416–439) lists gaussian…nbinom1/multinomial and aborts on unsupported
   families; ZIP/ZINB are not among the supported constructors in the abort
   message.
3. **`R/aghq-control.R` listing `"zip", "zinb"`** is a planned-family
   curvature heuristic, **not** a live fitter. It does not restore ZIP/ZINB.

Therefore:

- Do **not** invent a twin light logLik Δ for ZINB+X.
- Do **not** claim R-parity for ZINB until twin ZINB lands and an Identity
  re-check runs.
- Do **not** copy NB2/Beta per-trait φ (`2026-08-02-nb2-beta-x-dispersion-identity.md`)
  as the ZINB default. That choice was twin-backed (`disp.group`). ZINB has
  no twin surface; Julia no-X already uses shared `r`.
- Secondary authority for shape: Julia two-part design §2.2 / §3 + the
  shipped ZIP+X dual-`γ` Identity — not a twin file:line for X.

## Julia route map (this tip @ `8abdd751` / post-#201)

- Named no-X: `fit_zinb_gllvm` / `ZINBFit`
  (`src/families/twopart.jl`) — packed `[βz; βc; pack(Λc); log r]`,
  `Λ_z = 0`, **one shared scalar `r`**.
- Bridge one-part / X: `zinb` **not** in `_BRIDGE_ONEPART_FAMILIES` or
  `_BRIDGE_X_FAMILIES` (`src/bridge.jl`). ZIP is admitted; ZINB is not.
- No `fit_zinb_gllvm_cov` / shared-X kernel.
- Confint for no-X `ZINBFit` already exists in `confint_family.jl` (two-part
  adapter); that is **not** ZINB+X.
- **ZIP dual-`γ` reuse (shipped):** `fit_zip_gllvm_cov` / `ZIPCovFit` packs
  `[βz; γz; βc; γc; pack(Λc)]` with offsets `Oz = Xγ^z` / `Oc = Xγ^c` and
  `Λ_z = 0` (`2026-08-09-zip-x-identity.md`; engine #200; confint #201).
  ZINB+X should add `log r` to that packing, not invent a second X grammar.

## Twin rule (non-negotiable)

GLLVM.jl mirrors gllvmTMB on **API and capabilities**, not on engine code.
When twin ZINB is absent, Julia may still lock a **forward** Identity so the
next engine arc does not invent estimands — but must not claim twin parity.
Bridge execution remains **R→Julia only** (JuliaCall); RCall parity cells are
opt-in developer oracles. No engine surgery on gllvmTMB from this repo.

## Decision (ZINB under shared site-X)

**Choose a two-part shared site-X identity that keeps the v1 ZINB latent
structure (`Λ_z = 0`), puts shared site covariates on both linear
predictors with separate slope vectors, and retains the no-X shared
scalar `r` (log-scale):**

1. **Structural-zero logit:**  
   `η^z_{ts} = β^z_t + Σ_k X[t,s,k] · γ^z_k`  
   (`Λ_z` remains **0** — no occurrence latent loadings under this Identity).
2. **Count log-mean:**  
   `η^c_{ts} = β^c_t + Σ_k X[t,s,k] · γ^c_k + (Λ_c z_s)_t`  
   (shared `γ^c`; per-trait `β^c`; reduced-rank `Λ_c` as today).
3. **Dispersion (load-bearing lock):** one **shared scalar `r`** for all
   traits, optimised as `log r` (same packing tail as `fit_zinb_gllvm`).
   Per-trait `r_t` is **not** the default. That option needs its own
   decision if ever pursued, and must not be cargo-culted from NB2+X.
4. **Mixture mass** unchanged from §2.2 of the two-part design  
   (`P(y=0) = π0 + (1−π0)·(r/(r+μ))^r`, etc.).
5. **Public / bridge default under X (when an engine exists):** the shape in
   (1)–(3). Opt-in alternatives (X on count only; free `Λ_z`; shared single
   `γ` forced equal across parts; per-trait `r`) are **not** the default and
   need their own decision if pursued.
6. **Light RCall / twin Δ:** **forbidden** until twin ZINB is restored and
   this Identity is re-checked against the twin estimand. rtol stays `1e-6`
   when that day comes (no silent widen).

## Rejected alternatives

| Option | Why rejected |
|---|---|
| Skip Identity; jump to ZINB+X engine | Same class of risk #174/#185/#191/#198 blocked |
| Pretend twin ZINB light Δ exists | Twin ZINB cut — false parity |
| Copy NB2 per-trait φ as the ZINB+X default | Twin-backed for NB2 only; Julia ZINB no-X is shared `r`; two-part §3 says shared scalar |
| X on count only as silent default | Leaves `π0` unaddressed under covariates; ZIP lock was both parts |
| Free `Λ_z` as default under X | Breaks v1 ZINB / two-part design; larger engine |
| Hurdle+X / Tweedie+X as this Identity | Out of scope (G0 = ZINB+X only) |
| Re-open ZIP+X Identity | Already ACCEPTED #198 and shipped #200/#201 |
| “Full family parity” from this note | Claim inflation |

## Engine shape (next implementation arc — **not this doc’s code**)

Preferred surgical path (confirm in a fresh `/arc-creation` / Ultra Plan after
this Identity STOPs):

- Add `fit_zinb_gllvm_cov` (name may shift) packing  
  `[βz; γ^z; βc; γ^c; pack(Λc); log r]` with offsets from `Xγ^z` / `Xγ^c`
  into the existing ZINB Laplace marginal (`Λ_z = 0` retained; **shared
  scalar `r`** retained). Reuse the ZIP+X dual-`γ` / `_build_offset`
  substrate; do not invent a second X grammar.
- Admit bridge / `@formula` ZINB+X only after FD/identity checks against this
  note.
- Re-check twin ZINB status at that G0 before any light RCall cell. If twin
  ZINB is still cut, keep the Julia-forward fence.

## Rose fence

**OK to claim after this decision lands:** “ZINB+X Identity Arc 0 ACCEPTED
(docs-only): shared site-X with separate `γ^z` / `γ^c`, `Λ_z = 0`, **shared
scalar `r`** (log-scale), Julia-forward / twin-asymmetric.”

**Not OK:** ZINB engine shipped · ZINB bridge X admitted · ZINB light RCall Δ
· twin parity · ADEMP / coverage · free `Λ_z` · per-trait `r` as silent
default · hurdle+X / Tweedie+X · re-open ZIP Identity · full family parity.

## Provenance

- Clone: ZIP+X Identity `docs/dev-log/decisions/2026-08-09-zip-x-identity.md`
  (separate `γ^z`/`γ^c`, `Λ_z = 0`, twin-asymmetric).
- Twin cut cite: gllvmTMB `docs/dev-log/known-limitations.md` (ZIP/ZINB) +
  `R/fit-multi.R` `family_to_id` (no ZIP/ZINB arm) @ `9518d1bf`.
- Julia no-X substrate: `fit_zinb_gllvm` / `ZINBFit` in
  `src/families/twopart.jl` (`[βz; βc; pack(Λc); log r]`, `Λ_z = 0`).
- ZIP dual-`γ` reuse: `fit_zip_gllvm_cov` / `ZIPCovFit` (#200) +
  `confint(ZIPCovFit)` (#201).
- Shape authority: `docs/superpowers/specs/2026-05-31-two-part-families-design.md`
  §2.2 (ZINB mixture; `Λ_z = 0`) and §3 (`r` = 1, shared, log-scale).
- Contrast (do **not** copy): NB2/Beta+X Identity
  `2026-08-02-nb2-beta-x-dispersion-identity.md` (per-trait φ was twin-backed).
