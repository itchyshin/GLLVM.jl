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
| Julia `fit_zib_gllvm` / `ZIBFit` | per-trait `βz`, `Λ_z = 0` | per-trait `βc` + `Λc` | **shared scalar `N::Int`** | **absent** |
| Julia bridge one-part / X | — | — | — | **not admitted** (`zib` ∉ `_BRIDGE_*`) |
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
   (shared `γ^c`; per-trait `β^c`; reduced-rank `Λ_c`).
3. **Trials (load-bearing lock):** one **shared scalar `N`** for all traits and
   sites, carried exactly as no-X ZIB carries it — `struct ZIB` holds `N::Int`
   (`src/families/twopart.jl:1209`). A **per-observation trials matrix
   `N_{ts}`** is **not** the default and is **rejected for this arc**: it would
   force edits to the family marker (`ZIB`) and the count-part information
   kernel `_zi_Icc_binom(π, μ, N)` (`:1192`), both outside this note's
   "ZIB cov append" ownership scope. Do **not** cargo-cult the `p×n` trials
   matrix from `fit_beta_binomial_gllvm_grouped_cov`
   (`src/families/beta_binomial.jl:642`) — that is a different family with a
   different admitted bridge contract. Same treatment ZINB+X gave shared
   scalar `r`; `N_{ts}` needs its own decision if ever pursued.
4. **Mixture** unchanged from existing ZIB / two-part design (structural zero × Binomial).
5. **Packing (v1):** `[βz; γz; βc; γc; pack(Λc)]` with offsets
   `Oz = Xγ^z` / `Oc = Xγ^c` into the existing ZIB Laplace marginal
   (shared scalar `N` stays a fixed input, not a packed parameter).
6. **`γ_fixed`:** same both-parts mask contract as `fit_zip_gllvm_cov`.
7. **Light RCall / twin Δ:** **forbidden** until twin ZIB **lands** and this
   Identity is re-checked ("lands", not "restored" — ZIB never had a twin
   surface to restore).

## Rejected alternatives

| Option | Why rejected |
|---|---|
| Skip Identity; jump to engine | Same class of risk ZIP+X blocked |
| Invent twin ZIB/ZIP light Δ | Twin cut — false parity |
| X on count only as silent default | Breaks ZIP+X dual-`γ` lock |
| Free `Λ_z` as default under X | Breaks v1 two-part default |
| Per-trait dispersion for ZIB | Binomial count has fixed `N`; no φ |
| Per-observation trials matrix `N_{ts}` | Needs its own decision; would touch `struct ZIB` (`N::Int`) + `_zi_Icc_binom`, beyond a cov append. Shared scalar `N` is the lock (estimand item 3) |
| Admit `zib` to `_BRIDGE_X_FAMILIES` with this arc | Would leapfrog a no-X bridge surface ZIB has never had (`zib` ∈ neither `_BRIDGE_ONEPART_FAMILIES` nor `_BRIDGE_X_FAMILIES`); fenced as follow-up OWED |

## Out of scope

- ZIP+X / ZINB+X re-open
- ADEMP / coverage
- **Bridge admission for `zib` (one-part *and* X) — follow-up OWED.** Today
  `zib` is in **neither** `_BRIDGE_ONEPART_FAMILIES` nor `_BRIDGE_X_FAMILIES`
  (`src/bridge.jl:155`, `:186`), while `zip` and `zinb` are in **both**. This
  arc must **not** leapfrog: "clone ZIP+X" is licence for the *fitter* shape
  only, not for bridge admission. Chosen route: **(b) fence bridge admit as a
  separate follow-up**, no-X `zib` bridge first, then X — *not* (a) admit no-X
  in this Identity. Rationale: a no-X `zib` admit is **not** docs + one list
  entry. It needs a family-alias arm (`:146` pattern), the one-part list, a
  `bridge_fit` dispatch arm (`:1134` pattern), an assemble arm (`:1268`
  pattern), a `bridge_capabilities` entry (`:605`), **plus** a trials contract
  reconciling ZIB's shared scalar `N::Int` against the bridge's `p×n`
  `cbind(success, failure)` matrix convention (`_BRIDGE_TRIALS_FAMILIES`,
  `:177`) — which collides with estimand item 3. Bridge admit therefore gets
  its own arc and its own G0.
- Shared choke points — merge-conductor only (`src/bridge.jl` is one)
- truncated_nbinom2 (owned elsewhere)
- lognormal / censored_poisson (sibling lanes)

## Ownership (engine Wave2)

- **OWN:** ZIB cov append in `src/families/twopart.jl`, `test/test_zib_x*.jl` (new), this decision
- **NOT:** parallel edit with another twopart editor; shared choke points until admit

## STOP / CONTINUE

Identity ACCEPTED → **CONTINUE** to ZIB+X engine cloning `fit_zip_gllvm_cov` onto ZIB.
No twin Δ. Public claim waits for FD ≤1e-6 + focused tests + ledger note + Rose fence.

**Wave2 engine gate (2026-08-15).** The Wave2 ZIB+X engine arc may open its G0
only with amendments **R1** (shared scalar `N`) and **R2** (bridge fence, route
(b)) present on the PR #208 branch tip. Any engine work built on an Identity
copy that predates the ceiling review is **not** admitted: it carries neither
the trials lock nor the bridge fence, which are the two failure modes the
review was run to close.

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

### Amendments applied (2026-08-15, docs-only)

Both required amendments are now **on this branch tip** — the locked estimand is
otherwise unaltered, and no engine code was touched.

| Amendment | Landed as | Where |
|---|---|---|
| **R1** — shared scalar `N` load-bearing | Numbered lock (estimand item 3, mirroring ZINB+X shared `r`) + explicit rejection of per-observation `N_{ts}` | §Julia estimand item 3; §Rejected alternatives row; surface table now reads **shared scalar `N::Int`** |
| **R2** — bridge fence explicit | Bridge row **not admitted** (`zib` ∉ `_BRIDGE_*`) + "Out of scope" entry choosing route **(b) fence bridge admit as follow-up OWED** | §surface table; §Out of scope; §Rejected alternatives row |
| Advisory wording | "until twin ZIB **lands**" replaces "restored" | §Julia estimand item 7 |

**R2 route choice, evidence-backed:** route (b), *not* (a). A no-X `zib` bridge
admit is **not** trivial docs + one list entry — it needs a family-alias arm,
the one-part list, `bridge_fit` + assemble dispatch arms, a
`bridge_capabilities` entry, **and** a trials-contract reconciliation between
`ZIB`'s scalar `N::Int` and the bridge's `p×n` `cbind(success, failure)`
convention. Bridge admit is therefore fenced as a separate arc with its own G0.

Re-numbering note: the trials lock was inserted as item **3**, so mixture /
packing / `γ_fixed` / light-Δ shifted to items **4–7**. Downstream references to
"item 4" (cov append) in the verification table above now point at item **5**
(packing); the substance is unchanged.

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
