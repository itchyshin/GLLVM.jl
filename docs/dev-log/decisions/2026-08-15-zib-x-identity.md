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

## Ceiling review (2026-08-15) — **APPROVED**

Ceiling judgment pass on this Identity @ `0625316a` (PR #208, Wave1 docs-only).
Verdict: **APPROVED for W1-admit.** Two amendments are **required before the
Wave2 ZIB+X engine arc's G0** (both docs-only; neither changes the locked
estimand below).

### Verified against the engine, not the prose

| Claim | Evidence | Verdict |
|---|---|---|
| No-X `fit_zib_gllvm` / `ZIBFit`: `βz`, `βc`, `Λc`, fixed `N`, `Λ_z = 0` | `src/families/twopart.jl:1254`, `:1308`; `Λz_ = zeros(p,K)` default at `:1243` | OK |
| Count part is a **logit** success probability, not a log-mean | `_tp_pieces(::ZIB, …)` `μ = logistic(ηc)`, `logpdf(Binomial(N, μ))` @ `:1213` | OK |
| ZIP+X ships dual-`γ` with packing `[βz; γz; βc; γc; pack(Λc)]` | `fit_zip_gllvm_cov` @ `:898` (slice offsets `:913–:917`) | OK |
| `γ_fixed` zeroes columns on **both** parts | `_fixed_zero_mask` / `_slice_fixed_X` / `_expand_fixed_zero` @ `:906`, `:938` | OK |
| `fit_zib_gllvm_cov` / `ZIBCovFit` absent | repo-wide `rg` finds the names only inside this note | OK |
| Item 4 implementable as a *cov append* | `twopart_marginal_loglik_laplace` already takes `offsetz` / `offsetc` @ `:124–:127` — no kernel change needed | OK |
| Twin has **no** ZIB surface | twin `gllvmTMB` @ `114a227e`: `rg -i '\bzib\b\|zeroinflated.?binom'` over `R/` + `src/` returns **nothing**; `known-limitations.md:146` cuts ZINB/ZIP only; `family_to_id` (`R/fit-multi.R:375`) has delta arms, no ZI arm | OK — stronger than claimed |

The twin fence is if anything **understated**: ZIP/ZINB were *cut from* the
0.2.0 list, whereas ZIB was never present at all. Prefer "until twin ZIB
**lands**" (§Twin asymmetry item 3) over "until twin ZIB **restored**"
(Julia estimand item 6) — "restored" implies a surface that never existed.

**Credit where the clone did not cargo-cult:** it carried ZIP+X's dual-`γ` /
`Λ_z = 0` shape while correctly *replacing* the count link (logit, not log-mean)
and correctly rejecting per-trait dispersion for a fixed-`N` binomial. That is
the axis on which a ZIP→ZIB clone usually fails.

### Required amendment R1 — lock the trials contract as load-bearing

`N` appears only parenthetically ("binomial `N` as no-X ZIB", item 2), and the
rejected-alternatives table rejects per-trait *dispersion* but never
**per-observation trials** `N_{ts}`. The pull toward a matrix `N` is live and
unfenced: the repo's only trials-family-under-X fitter,
`fit_beta_binomial_gllvm_grouped_cov` (`src/families/beta_binomial.jl:642`),
takes `N::Union{Nothing, AbstractMatrix{<:Real}}` and validates
`size(Nm) == (p, n)` — a **p×n per-observation** trials matrix — and
`betabinomial` is admitted in both `_BRIDGE_TRIALS_FAMILIES` and
`_BRIDGE_X_FAMILIES`. Meanwhile `struct ZIB` carries `N::Int` (`:1209`) and
`_zi_Icc_binom(π, μ, N)` assumes a scalar, so matrix `N` would require editing
the family marker and the information kernel — which contradicts this note's
own ownership scope ("ZIB cov append").

Amendment: promote **shared scalar `N` (not `N_{ts}`)** to a numbered
load-bearing lock, exactly as ZINB+X did for shared scalar `r`, and add a
rejected-alternatives row: *per-observation trials matrix `N_{ts}` — needs its
own decision; would touch `ZIB` + `_zi_Icc_binom`, beyond a cov append.*

### Required amendment R2 — state the bridge fence explicitly

Both sibling Identities carry a bridge row; this note's table omits it, and
"Out of scope" is silent on the bridge. Live state has drifted since the ZIP+X
note was written: `zip` and `zinb` are now in **both**
`_BRIDGE_ONEPART_FAMILIES` and `_BRIDGE_X_FAMILIES` (`src/bridge.jl:155`,
`:186`), while `zib` is in **neither**. So "clone ZIP+X" now reads as licence to
admit `zib` to `_BRIDGE_X_FAMILIES` — which would leapfrog a no-X bridge
surface ZIB has never had.

Amendment: add the row *Julia bridge one-part / X — **not admitted**
(`zib` ∉ `_BRIDGE_*`)*, and put bridge admission in "Out of scope" (it is
already excluded from Ownership).

### Advisory (not blocking)

- Clone fidelity: siblings carry explicit `## Rose fence` (OK / Not-OK claim
  lists) and `## Provenance` sections; this note folds both into the header and
  STOP/CONTINUE. Adding them would satisfy AGENTS.md rule 9 in the sibling form.
- The Programme path (`lanes/gllvmjl-parallel-family-catchup-20260815/LOOP/`) is
  a forward reference — it lives on the conductor branch (`66dc3e90`, PR #206),
  not in this worktree. It resolves at W1-admit; re-check after the merge.

### Fence held

No twin Δ invented for ZIB, ZIP, or ZINB. ZIP+X / ZINB+X Identities not
re-opened. Judgment only — the locked estimand above is unaltered by this
review. `truncated_nbinom2` untouched.
