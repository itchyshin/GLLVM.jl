# Decision: ZIB bridge admission — Identity (no-X first; shared scalar `N::Int`)

**Date:** 2026-08-16
**Status:** ACCEPTED (Arc 0, docs-only — no engine code in this note)
**Lane:** `docs/zib-bridge-identity-20260816`
**Tip probed:** `ef96463b` (post-#226 NB1/BetaBinom Identity)
**Depends on:** ZIB+X Identity `2026-08-15-zib-x-identity.md` (#208), **with**
its required amendments **R1** (shared scalar `N` is a load-bearing lock) and
**R2** (bridge fence, route **(b)**); ZIB no-X `fit_gllvm` admit (#218); ZIB no-X
`@formula` admit (#220); ADMIT handover `2026-08-15-zib-x-ADMIT.md`, conductor
item 3.
**Do not** re-open #208's Identity — the shared-scalar-`N` lock is inherited, not
re-decided here. **Do not** invent a twin `gllvmTMB` light RCall Δ for any ZIB
surface: the twin has no ZIB at all. **Do not** touch `src/bridge.jl`,
`src/families/fit_gllvm.jl`, `src/formula.jl`, or any test in *this* note's PR —
it is docs-only, and PR #227 owns the `fit_gllvm` / `@formula` surfaces.

## Problem

ZIB now has **two** engines (`fit_zib_gllvm`, `fit_zib_gllvm_cov`) and **two**
public Julia surfaces without X (`fit_gllvm(Y; family = ZIB(N))` from #218,
`@formula(y ~ 1)` from #220). The R bridge is the one public surface where ZIB
is absent *entirely* — `"zib"` is not a recognised family string, so the failure
is not "unsupported route" but "unknown family".

The ADMIT handover already chose the route: **(b) no-X bridge first, then X**,
with the trials contract called out as the open question. This note settles what
"no-X bridge first" concretely means, because three things do **not** transfer
from the `zip` / `zinb` arms that an engine arc would otherwise clone.

### Live surface map (probed at `ef96463b`, not inferred)

| Surface | ZIP | ZINB | ZIB |
|---|---|---|---|
| Engine, no X | `fit_zip_gllvm` | `fit_zinb_gllvm` | `fit_zib_gllvm` (`twopart.jl:1308`) |
| Engine, +X | `fit_zip_gllvm_cov` | `fit_zinb_gllvm_cov` | `fit_zib_gllvm_cov` (`:1386`) |
| Marker | `struct ZIPoisson end` | `struct ZINegBin end` | `struct ZIB; N::Int; end` (`:1209`) |
| `fit_gllvm` no-X | shipped | shipped | **shipped** (#218) |
| `@formula` no-X | shipped | shipped | **shipped** (#220) |
| `@formula` +X | shipped | shipped | explicit `ArgumentError` (`formula.jl:147–150`) |
| Bridge family key | `"zip"` (`bridge.jl:146`) | `"zinb"` (`:147–148`) | **throws — unknown family** |
| `_BRIDGE_ONEPART_FAMILIES` | yes (`:168`) | yes (`:169`) | **no** |
| `_BRIDGE_X_FAMILIES` | yes (`:187`) | yes (`:187`) | **no** |
| No-X CI engine | `_family_ci(::ZIPFit)` | `_family_ci(::ZINBFit)` | **`_family_ci(::ZIBFit)` exists** (`confint_family.jl:1708`) |
| +X CI engine | `ZIPCovFit ∈ _CIFit` (`:45`) | `ZINBCovFit ∈ _CIFit` (`:45`) | **`ZIBCovFit ∉ _CIFit`** |

Verbatim probe (`julia --project=. …` at `ef96463b`; read-only, no fits):

```
--- bridge family-key admission ---
zib                       -> THROWS: ArgumentError: bridge_fit: unsupported family "zib" …
zero_inflated_binomial    -> THROWS: ArgumentError: bridge_fit: unsupported family "zero_inflated_binomial" …
zip                       -> "zip"
zinb                      -> "zinb"
betabinomial              -> "betabinomial"

--- zib membership in bridge lists ---
_BRIDGE_ONEPART_FAMILIES    zib in? false   zip in? true
_BRIDGE_X_FAMILIES          zib in? false   zip in? true
_BRIDGE_TRIALS_FAMILIES     zib in? false   zip in? false
_BRIDGE_MASK_FAMILIES       zib in? false   zip in? false
_BRIDGE_NO_CI_X_FAMILIES    zib in? false   zip in? false

--- bridge_capabilities family column ---
families: gaussian, poisson, binomial, binomial_probit, binomial_cloglog,
negbinomial, nb1, beta, gamma, betabinomial, ordinal, ordinal_probit, zip, zinb,
mixed-family vector

--- CI union membership (type-level) ---
ZIBFit    <: GLLVM._CIFit  : true
ZIBCovFit <: GLLVM._CIFit  : false
ZIPCovFit <: GLLVM._CIFit  : true
ZINBCovFit<: GLLVM._CIFit  : true

--- fit_zib_gllvm kwargs (mask? offset?) ---
kwargs: [:K, :N, :offset, :g_tol, :iterations, :newton_maxiter, :newton_tol]
cov kwargs: [:X, :K, :N, :γ_fixed, :g_tol, :iterations, :newton_maxiter, :newton_tol]

--- postfit extractor coverage (ZIB vs ZIP vs ZINB) ---
predict       ZIBFit=true  ZIPFit=true  ZINBFit=true
residuals     ZIBFit=true  ZIPFit=true  ZINBFit=true
simulate      ZIBFit=false ZIPFit=false ZINBFit=false
getLV         ZIBFit=true  ZIPFit=true  ZINBFit=true
sigma_y_site  ZIBFit=false ZIPFit=false ZINBFit=false
correlation   ZIBFit=false ZIPFit=false ZINBFit=false
communality   ZIBFit=false ZIPFit=false ZINBFit=false

--- _bridge_compute_ci_cov accepted fit types ---
Union{BetaBinomialGroupedCovFit, BetaGroupedCovFit, GammaGroupedCovFit,
GllvmCovFit, NB1GroupedCovFit, NBGroupedCovFit, ZINBCovFit, ZIPCovFit}
```

## Why "mirror ZIP/ZINB" is not licence on its own

Most of the ZIP arm *does* transfer: identical postfit coverage (`predict`,
`residuals`, `getLV` present; `sigma_y_site` / `correlation` / `communality`
absent, so the `_bridge_assemble_ng` `MethodError` fallback to `ΛΛᵀ` plus its
honest note applies verbatim), no `mask` kwarg, and a working no-X `_family_ci`.
Two things do not, and both are load-bearing.

| # | ZIP / ZINB | ZIB |
|---|---|---|
| 1 | Marker is an **empty struct**; the fitters take no trials argument, so the bridge's `N` is simply unused | Marker and both fitters carry a **shared scalar `N::Int`**. The bridge's only `N` convention is the `p×n` `cbind(success, failure)` matrix (`_BRIDGE_TRIALS_FAMILIES`, `:177`), which is the `N_{ts}` contract #208 explicitly **rejected** |
| 2 | `ZIPCovFit` / `ZINBCovFit` ∈ `_CIFit` **and** ∈ the `_bridge_compute_ci_cov` Union (`:310–312`) — the +X arm routes all three CI methods | `ZIBCovFit` ∈ **neither** (probed). A cloned ZIP+X arm would `MethodError` on any `ci_method != "none"` |

A third asymmetry sits outside the code and shapes the claim wording: the twin
`gllvmTMB` **cut** ZIP/ZINB, which is why their bridge notes read *"no twin light
RCall Δ (twin ZIP cut)"* (`:606`, `:608`). The twin has **no ZIB at all**
(`docs/design/capability-status.md:108`). Same outcome — no Δ — for a different
reason, so the ZIP wording must not be copied verbatim.

## Decision

### B1 — Scope: **no-X only**, and `"zib"` becomes a real family key

Add `"zib"` to `_BRIDGE_ONEPART_FAMILIES` (`:155–170`), add an alias row to
`_bridge_family_key` (`:132–153`), add the family to the unsupported-family
message (`:152`), and add a no-X dispatch arm on the `zip` pattern (`:1134–1152`).
Do **not** add `"zib"` to `_BRIDGE_X_FAMILIES` (`:186–187`) in the same arc.

Alias set, mirroring the density of the `zip` / `zinb` rows:
`("zib", "zibinomial", "zero_inflated_binomial", "zi_binomial")`. Both `"zib"`
and `"zero_inflated_binomial"` throw today (probed), so every one of these is a
pure addition.

Why the split is real work and not bureaucracy: the X arm additionally needs a
`_bridge_fit_onepart_cov` branch (`:1268` pattern), a `_bridge_assemble_zib_cov`
assembler (`:1383` pattern), **and** the CI resolution in **B4**. Landing both at
once repeats precisely the leapfrog that #208's amendment R2 fenced.

### B2 — Trials transport: shared scalar `N::Int`, **required**, uniformity-validated; `zib` stays **out** of `_BRIDGE_TRIALS_FAMILIES`

**Transport.** `bridge_fit`'s existing `N` argument, normalised to one `Int`
before it reaches `fit_zib_gllvm(Yi; K = K, N = Ni)`:

- `N isa Number` → `round(Int, N)`.
- `N` a `p×n` array → admitted **only if every entry is equal**, then collapsed
  to that scalar. R's `cbind(success, failure)` route naturally produces a
  matrix, so rejecting matrices outright would make the R surface unusable.
- entries differ → `ArgumentError` naming ZIB's shared-scalar contract. **Never
  silently take `N[1,1]`** — that would fit a different model than the caller
  asked for and is the exact door #208 item 3 closed.
- `N === nothing` → `ArgumentError`. See below.

**`N` is required; do not inherit the binomial default.** Every existing trials
route defaults `N === nothing → fill(1, p, n)` (`:892`, `:1103`, `:1219`,
`:1548`). For ZIB that default is not conservative — it silently selects the
zero-inflated **Bernoulli**, where `(β^z, β^c)` is **exactly aliased**. Probed at
`ef96463b` by direct evaluation of `zib_marginal_loglik_laplace` with `Λc = 0`
(the cell where the Laplace marginal is exact), sweeping `(π, μ)` along the curve
`(1 − π)·μ = 0.30`:

| π | μ | loglik, `N = 1` | loglik, `N = 6` |
|---|---|---|---|
| 0.05 | 0.31579 | −81.77669485045925 | −313.3261113114871 |
| 0.15 | 0.35294 | −81.77669485045925 | −287.7036309703195 |
| 0.25 | 0.40000 | −81.77669485045926 | −266.2723020112423 |
| 0.40 | 0.50000 | −81.77669485045925 | −244.31724754312538 |

At `N = 1` the log-likelihood is constant to ~1e-14 (roundoff) along the whole
curve — only the product `(1 − π)·μ` is identified, so `β^z` and `β^c` are not.
The same sweep spans ~69 nats at `N = 6`. With `Λc ≠ 0` the aliasing is weak
rather than exact, which is **worse** at a public boundary, not better: the
optimiser converges to an arbitrary point on a near-flat ridge and reports it
with no warning.

**Keep `zib` out of `_BRIDGE_TRIALS_FAMILIES`.** That tuple drives the
`cbind_binomial` capability column (`:570`). Listing ZIB there would advertise to
R users that the per-observation `cbind` convention is honoured — i.e. exactly
the `N_{ts}` contract #208 rejected. The uniform-matrix acceptance in **B2** is a
transport convenience, not a per-observation contract, and must not be advertised
as one. The shared-scalar requirement is carried in the capability `notes` string
instead (**B5**).

### B3 — Missing-response masks: not wired; keep `zib` out of `_BRIDGE_MASK_FAMILIES`

`fit_zib_gllvm` has no `mask` kwarg (probed:
`[:K, :N, :offset, :g_tol, :iterations, :newton_maxiter, :newton_tol]`), the same
as ZIP and ZINB. Leave `"zib"` out of `_BRIDGE_MASK_FAMILIES` (`:470–473`) and
out of `_BRIDGE_MASK_CI_FAMILIES` (`:478–481`); the generic guard in
`_bridge_fit_onepart` (`:655–659`) then raises before any fit runs.

Note for the engine arc so it does not mis-read the ZIP arm: the family-named
`throw` **inside** the ZIP/ZINB arms (`:1136–1137`, `:1155–1156`) is
**redundant** given that guard. Mirroring it for ZIB is fine for consistency and
gives a family-named message, but it is not load-bearing — do not treat its
absence as a bug, and do not build anything on it.

### B4 — Confidence intervals: no-X routes all three methods; +X is **blocked by a missing engine**, not by a policy fence

**No-X — nothing new to write.** `ZIBFit ∈ _TwoPartFit ⊂ _CIFit`
(`confint_family.jl:36`, `:45`) and `_family_ci(::ZIBFit, Y)` is implemented with
`nll` / `sim` / `refit` (`:1708–1738`), so
`_bridge_compute_ci_ng(fit, Float64.(Yi), nothing, ci_method, …)` works exactly
as the ZIP arm's call at `:1140–1142`. Pass `N = nothing` to the CI helper and to
`_bridge_assemble_ng`: ZIB's trials count lives on the fit object (`fit.N`), and
the assembler's `N` argument is a covariance-extractor argument, not a trials
argument. `ci_no_x_wald` / `_profile` / `_bootstrap` therefore report **true**
for `zib` with no extra work.

**+X — recorded for the second arc, and it must not be papered over.**
`ZIBCovFit ∉ _CIFit` and is absent from the `_bridge_compute_ci_cov` Union
(`:310–312`), both probed. When the X arc opens it must pick one, explicitly:

1. add `_family_ci(::ZIBCovFit, Y; X)` on the `ZIPCovFit` pattern (`:1554`) and
   extend both Unions — a real engine addition with its own FD verification; or
2. add `"zib"` to `_BRIDGE_NO_CI_X_FAMILIES` (`:190`, currently `()`, with the
   comment "Empty: ZIP+X and ZINB+X now route CI" — which will need editing) so
   `ci_x_*` honestly reports **false**.

Cloning the ZIP+X arm without doing either ships a route that `MethodError`s the
moment an R user passes `ci_method = "wald"`.

### B5 — Capability row and note wording

`bridge_capabilities()` (`:545–625`) derives most columns from list membership,
so **B1**'s single-tuple admission does most of the work correctly:
`cbind_binomial` false (**B2**), `missing_response` false (**B3**), `ci_no_x_*`
true (**B4**), `ci_x_*` false while `zib ∉ x_families`, `fixed_effect_X` false.

One column needs a decision. `postfit_residuals` and `postfit_simulate` are both
derived from the same `_BRIDGE_NO_SCALAR_POSTFIT_FAMILIES` set (`:491`, `:558`),
so admitting `zib` makes both **true**. `residuals(::ZIBFit)` exists
(`postfit.jl:1990`) — correct. **`simulate` has no `ZIBFit` method** — and,
probed, none for `ZIPFit` or `ZINBFit` either, both of which are already
advertised `true`. So this is an inherited inaccuracy, not one ZIB introduces.

**Preferred resolution:** add a narrow `_BRIDGE_NO_SIMULATE_FAMILIES =
("zip", "zinb", "zib")` used by the `postfit_simulate` column only. Two lines,
strictly a claim *narrowing* with no behaviour change, and it makes all three
zero-inflated rows honest at once instead of propagating the gap. **Fallback**,
if the merge conductor declines to touch the `zip` / `zinb` rows in this arc:
mirror them for ZIB and record the shared gap as its own follow-up with its own
G0. What is **not** available is inheriting `true` silently and saying nothing.

**Draft `notes` string** for the `zib` row (`:605` pattern), to be landed
verbatim unless the engine arc finds it false:

> two-part ZIB bridge family (Julia-forward / twin-asymmetric); no-X routes
> `fit_zib_gllvm` with Wald/profile/bootstrap CI and one **shared scalar trials
> count `N`** (not per-observation `cbind`); fixed-effect-X, missing-response
> masks, and CI under X remain follow-ups; **no twin light RCall Δ — the twin
> `gllvmTMB` has no ZIB, so a Δ would be invented** (contrast ZIP/ZINB, which the
> twin cut); route support is narrower than full R-user parity.

The parenthetical matters: reusing ZIP's "(twin ZIP cut)" would misattribute the
reason and quietly imply a twin ZIB once existed.

## Twin fence

`gllvmTMB` has **no ZIB**. There is therefore no light RCall Δ to run, none to
owe, and none that may be invented — this is the `censored_poisson` situation
(**forbidden**), not the `lognormal` one (**owed**). Light RCall is admitted only
where the twin admits the family; ZIB is not such a case, no matter how closely
the bridge arm resembles ZIP's.

`docs/design/capability-status.md:105–108` already states this correctly. The
engine arc updates that note's OWED list (dropping bridge no-X once it lands) and
**adds no parity or Δ row**.

## Rejected alternatives

| Option | Why rejected |
|---|---|
| Admit `zib` to `_BRIDGE_ONEPART_FAMILIES` **and** `_BRIDGE_X_FAMILIES` in one arc | Repeats the leapfrog #208 R2 fenced, and the X arm has no CI engine (**B4**) — it would ship a route that `MethodError`s under `ci_method != "none"` |
| Add `zib` to `_BRIDGE_TRIALS_FAMILIES` | Sets the `cbind_binomial` column true, advertising the per-observation `N_{ts}` contract that #208 item 3 rejects; ZIB's `N` is one shared `Int` (`twopart.jl:1209`) |
| Accept a `p×n` `N` and take `N[1, 1]` | Silently fits a different model than the caller specified — the failure mode the uniformity check exists to catch |
| Reject `p×n` `N` outright | Breaks the R `cbind(success, failure)` call shape for a caller whose trials genuinely are uniform; the uniformity check is the narrow admission |
| Inherit `N === nothing → fill(1, p, n)` (the binomial default at `:892` / `:1103`) | At `N = 1` ZIB is the ZI-Bernoulli and `(β^z, β^c)` is exactly aliased — loglik flat to ~1e-14 along `(1−π)μ = const` (table in **B2**) |
| Change `struct ZIB` or `_zi_Icc_binom` to take a trials matrix | Re-opens #208's inherited lock from a bridge arc; `N_{ts}` needs its own Identity if ever pursued |
| Clone the ZIP+X CI call for ZIB+X | `ZIBCovFit ∉ _CIFit` and ∉ the `_bridge_compute_ci_cov` Union (both probed) |
| Wire masks by mirroring `_BRIDGE_MASK_FAMILIES` | `fit_zib_gllvm` has no `mask` kwarg (probed); ZIP/ZINB are excluded for the same reason |
| Inherit `postfit_simulate = true` silently | No `simulate(::ZIBFit)` method exists; the column is shared with `zip`/`zinb`, so the honest fix narrows all three (**B5**) |
| Copy ZIP's "(twin ZIP cut)" note clause | Misattributes the reason: the twin cut ZIP/ZINB but never had ZIB |
| Run any light RCall Δ for ZIB | No twin ZIB exists; a Δ would be fabricated |
| Land ZIB bridge admission inside PR #227 | #227 owns `fit_gllvm` / `@formula` surfaces; `src/bridge.jl` is a merge-conductor choke point and a separate G0 |

## Out of scope

- **ZIB+X on the bridge** — second arc, own G0, gated on the **B4** CI choice.
- `_family_ci(::ZIBCovFit)` — an engine addition with its own FD verification.
- ZIB+X through `fit_gllvm` / `@formula` (still fenced at `formula.jl:147–150`).
- Missing-response masks for any zero-inflated family (needs a masked ZIB
  Laplace marginal first).
- Per-observation trials `N_{ts}` for ZIB — needs its own Identity.
- Fixing `postfit_simulate` for `zip` / `zinb` beyond the two-line narrowing in
  **B5**.
- Any twin `gllvmTMB` parity claim, light RCall Δ, ADEMP, or coverage certificate.
- Anything in PR #227's lane.

## Ownership (bridge engine arc)

- **OWN:** a new focused bridge test file; the `docs/design/capability-status.md`
  OWED-list update; `docs/dev-log/check-log.md`; the after-task report; this note.
- **CONDUCTOR:** `src/bridge.jl` — every edit in **B1**–**B5** lands there, and
  it is a shared choke point. Coordinate; do not open it from a parallel lane.
- **NOT:** `src/families/twopart.jl` (no engine change is required by this note);
  `src/families/fit_gllvm.jl`; `src/formula.jl`; `src/GLLVM.jl`; anything PR #227
  touches.

## Rose fence

**OK to claim after the bridge engine arc:** "The R bridge accepts
`family = \"zib\"` for **no-X** fits, routing `fit_zib_gllvm` with
Wald/profile/bootstrap CI payloads and one **shared scalar** trials count `N`,
which is **required** at the boundary."

**NOT OK to claim:** any `gllvmTMB` parity, light RCall Δ, or twin comparison for
ZIB (the twin has no ZIB); ZIB+X through the bridge; CI under X; missing-response
masks; per-observation `cbind` trials; bridge-routed `simulate`; any ADEMP or
coverage result; that #208's `N` lock was revisited.

## STOP / CONTINUE

Identity **ACCEPTED** → **CONTINUE** to the bridge engine arc. Its G0 may open
only with **B1–B5** present on the branch tip. **B2** (shared scalar `N`,
required, uniformity-validated, *not* in `_BRIDGE_TRIALS_FAMILIES`) and **B4**
(no +X CI engine exists) are the two failure modes this note exists to close: a
bridge arc built on a copy of this note predating either is **not admitted**.
