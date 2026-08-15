# Decision: ZIB + X identity (Julia-forward; twin asymmetric)

**Date:** 2026-08-15  
**Status:** ACCEPTED (Wave1 / Arc 0 docs-only → engine on owned files)  
**Lane:** `cursor/zib-x-identity-20260815`  
**Programme:** `lanes/gllvmjl-parallel-family-catchup-20260815/LOOP/`  
**Depends on:** ZIP+X Identity `2026-08-09-zip-x-identity.md` + engine;
ZINB+X Identity `2026-08-13-zinb-x-identity.md` (clone shape only); G0 parallel catch-up.  
**Clone from:** ZIP+X dual-`γ` + `Λ_z = 0`; keep no-X ZIB `N`-trials contract.  
**Do not** invent ZIP/ZINB twin Δ; **do not** re-open ZIP+X / ZINB+X Identities.

## Problem

Julia already has a named no-X ZIB fitter (`fit_zib_gllvm` / `ZIBFit`) with
structural-zero logits `βz`, count success-logits `βc`, count loadings `Λc`,
fixed trials `N`, and the v1 default `Λ_z = 0`. ZIP+X ships as
`fit_zip_gllvm_cov` / `ZIPCovFit` with separate shared slopes `γz` / `γc`.
There is **no** `fit_zib_gllvm_cov` / `ZIBCovFit`. Twin gllvmTMB **cut ZIP/ZINB**
(and has no live ZIB twin surface) — inventing a twin light Δ would violate Rose.

Without an Identity lock, a ZIB+X engine risks a different X grammar than ZIP+X
(X on count only; free `Λ_z`; single forced-equal `γ`) or silently borrowing
NB/Beta per-trait dispersion conventions that do not apply to binomial counts.

| Surface | Zero / occurrence | Count / value | Trials | Shared site-X |
|---|---|---|---|---|
| R / gllvmTMB ZIB | **absent** (ZIP/ZINB cut; no ZIB fid) | **absent** | — | **absent** |
| Julia `fit_zib_gllvm` / `ZIBFit` | per-trait `βz`, `Λ_z = 0` | per-trait `βc` + `Λc` | fixed `N` | **absent** |
| Julia ZIP+X (`ZIPCovFit`) | separate `γ^z`, `Λ_z = 0` | separate `γ^c` + `Λc` | — | **shipped** |
| Julia `fit_zib_gllvm_cov` | — | — | — | **absent** |

## Twin asymmetry (load-bearing fence)

This Identity is **Julia-forward / twin-asymmetric**.

1. Twin ZIP/ZINB cut from the 0.2.0 family list (known-limitations).
2. No twin `family_to_id` arm for ZIB / ZIP / ZINB in the live abort list pattern.
3. Therefore: **do not** invent twin light logLik Δ for ZIB+X; **do not** claim
   R-parity until twin ZIB lands and this Identity is re-checked.
4. Secondary authority: two-part design §2.2 + shipped ZIP+X dual-`γ` Identity +
   existing no-X ZIB (`N`, binomial count block).

## Julia estimand (this Identity)

**Choose the ZIP+X dual-`γ` shape with binomial count + fixed `N`:**

1. **Structural-zero logit:**  
   `η^z_{ts} = β^z_t + Σ_k X[t,s,k] · γ^z_k`  
   (`Λ_z` remains **0**).
2. **Count success logit:**  
   `η^c_{ts} = β^c_t + Σ_k X[t,s,k] · γ^c_k + (Λ_c z_s)_t`  
   (shared `γ^c`; per-trait `β^c`; reduced-rank `Λ_c`; binomial `N` as no-X ZIB).
3. **Mixture** unchanged from existing ZIB / two-part design (structural zero × Binomial).
4. **Packing (v1):** `[βz; γz; βc; γc; pack(Λc)]` with offsets
   `Oz = Xγ^z` / `Oc = Xγ^c` into the existing ZIB Laplace marginal.
5. **`γ_fixed`:** same both-parts mask contract as `fit_zip_gllvm_cov`.
6. **Light RCall / twin Δ:** **forbidden** until twin ZIB restored.

## Rejected alternatives

| Option | Why rejected |
|---|---|
| Skip Identity; jump to engine | Same class of risk ZIP+X blocked |
| Invent twin ZIB/ZIP light Δ | Twin cut — false parity |
| X on count only as silent default | Breaks ZIP+X dual-`γ` lock |
| Free `Λ_z` as default under X | Breaks v1 two-part default |
| Per-trait dispersion for ZIB | Binomial count has fixed `N`; no φ |

## Out of scope

- ZIP+X / ZINB+X re-open
- ADEMP / coverage
- Shared choke points — merge-conductor only
- truncated_nbinom2 (owned elsewhere)
- lognormal / censored_poisson (sibling lanes)

## Ownership (engine Wave2)

- **OWN:** ZIB cov append in `src/families/twopart.jl`, `test/test_zib_x*.jl` (new), this decision
- **NOT:** parallel edit with another twopart editor; shared choke points until admit

## STOP / CONTINUE

Identity ACCEPTED → **CONTINUE** to ZIB+X engine cloning `fit_zip_gllvm_cov` onto ZIB.
No twin Δ. Public claim waits for FD ≤1e-6 + focused tests + ledger note + Rose fence.
