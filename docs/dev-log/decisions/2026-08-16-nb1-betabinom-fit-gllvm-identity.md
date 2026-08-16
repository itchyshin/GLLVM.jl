# Decision: NB1 + BetaBinom no-X `fit_gllvm` identity (surface admit; twin-aligned estimand)

**Date:** 2026-08-16
**Status:** ACCEPTED (Arc 0, docs-only — no engine code in this note)
**Lane:** `cursor/nb1-betabinom-identity-20260816`
**Tip probed:** `dc3609f1` (post-#224 REML + ledger, post-#225 handoff)
**Depends on:** NB1+X Identity `2026-08-05-nb1-x-dispersion-identity.md` (#185);
BetaBinomial+X Identity `2026-08-05-betabinomial-x-dispersion-identity.md` (#186);
ZIB no-X `fit_gllvm` admit (#218) + ZIB no-X `@formula` (#220) as **shape
precedent only**.
**Do not** re-open #185 / #186. **Do not** invent a twin `gllvmTMB` light Δ for
any surface in this note. **Do not** touch `src/bridge.jl`.

## Problem

`NB1` and `BetaBinom` have complete, tested, per-trait Laplace engines and are
already routed by **two** public surfaces — the R bridge (no-X *and* X) and
`@formula` **with** X. They are unreachable through the third: the unified
`fit_gllvm` entry point, and hence through `@formula` **without** X, which falls
through to it.

The obvious fix — export the markers and add a `_fit_gllvm` arm each, the ZIB
#218 shape — is **wrong here**, for a reason that only shows up when the three
surfaces are read together: the shipped surfaces default to **per-trait φ**,
while the one-line `_fit_gllvm` arm would default to **shared φ**. That ships
one family, reachable three ways, with two different estimands.

### Live surface map (probed at `dc3609f1`, not inferred)

| Surface | NB1 | BetaBinom | Dispersion estimand |
|---|---|---|---|
| R bridge no-X (`bridge.jl:990`, `:1105`) | **shipped** | **shipped** | **per-trait** (`group = collect(1:p)`) |
| R bridge + X (`_BRIDGE_X_FAMILIES`, `:186`) | **shipped** | **shipped** | **per-trait** grouped_cov |
| `@formula` + X (`formula.jl:137`, `:139`) | **shipped** | **shipped** | **per-trait** grouped_cov |
| `@formula` no-X (`formula.jl:102–107`) | **ArgumentError** | **ArgumentError** | — (falls through to `fit_gllvm`) |
| `fit_gllvm` bare marker | **ArgumentError** | **ArgumentError** | — |
| `fit_gllvm(disp_group = :species)` | **works** → `NB1GroupedFit` | **ArgumentError** (no `_fit_gllvm_grouped` arm) | per-trait |
| Named shared-φ fitter | `fit_nb1_gllvm` | `fit_beta_binomial_gllvm` | shared scalar φ |
| Marker exported? | **no** | **no** | — |

Verbatim probe (`julia --project=. …` at `dc3609f1`):

```
--- marker export status (after `using GLLVM`) ---
NB1                   not exported
BetaBinom             not exported
TweedieED             not exported
ZIB                   EXPORTED
ZIPoisson             EXPORTED
ZINegBin              EXPORTED
GeneralizedPoisson1   EXPORTED
Ordinal               EXPORTED
--- zero-arg constructor? ---
NB1()                 NO (MethodError)
BetaBinom()           NO (MethodError)
--- fit_gllvm no-X reachability (p=4,n=8,K=1) ---
NB1(1.0)              ArgumentError: fit_gllvm: family NB1 is not implemented yet …
BetaBinom(2.0)        ArgumentError: fit_gllvm: family BetaBinom is not implemented yet …
--- @formula no-X (q=0) ---
NB1(1.0)              ArgumentError: fit_gllvm: family NB1 is not implemented yet …
BetaBinom(2.0)        ArgumentError: fit_gllvm: family BetaBinom is not implemented yet …
--- disp_group route reachable today? ---
NB1 disp_group        OK -> NB1GroupedFit
BetaBinom disp_group  ArgumentError: disp_group … not supported for family BetaBinom
```

## Why this is not surgical like ZIB #218

ZIB #218 was **+53/−2 over 4 files** (`check-log.md`, `src/GLLVM.jl` +2/−1,
`src/families/fit_gllvm.jl` +8/−1, `test/test_zero_inflated.jl`). Four
properties made that possible; **none of the four holds here.**

| # | ZIB #218 | NB1 / BetaBinom |
|---|---|---|
| 1 | `ZIB` marker already exported — the `src/GLLVM.jl` edit was one line | Both markers **unexported**, and exporting is a public-API addition ⇒ AGENTS.md rule 3 convention cascade in the same PR |
| 2 | Marker field `N::Int` is **structural** — a fixed data input, forwarded verbatim (`fit_zib_gllvm(Y; N = family.N)`) | Marker field `φ` is an **estimated free parameter**. Forwarding it would pin a free parameter; ignoring it is right but leaves a mandatory, meaningless constructor argument |
| 3 | ZIB has exactly one no-X fitter ⇒ no dispersion-grouping choice existed | Two fitters each (shared φ / per-trait φ). The default is a **twin-alignment decision** already locked per-trait by #185 / #186 — a bare `_fit_gllvm` arm would silently pick the other one |
| 4 | Trials `N` is a shared **scalar** that fits on the marker | BetaBinom trials are a **p×n matrix** ⇒ needs a transport decision (item **C3**), and the fitters' silent `N = ones` default is **not safe** for a public entry point (see C3 evidence) |

A fifth asymmetry runs the other way and *reduces* scope: **the bridge needs no
admission** (see §Bridge fence), whereas #218 had to fence one.

## Decision

### C1 — φ convention: marker φ is a tag payload, ignored on every route; φ is always estimated

The marker's `φ` field is **never read** by any `fit_gllvm` / `@formula` route.
It is not forwarded, and it is **not** used as `φ_init`. φ is estimated on every
public route, always.

Evidence that this *is* the shipped house convention, not a new one:

- `_fit_gllvm(::NegativeBinomial, …)`, `_fit_gllvm(::Beta, …)`,
  `_fit_gllvm(::GeneralizedPoisson1, …)` all bind the marker with `::T` and drop
  the field (`fit_gllvm.jl:157`, `:158`, `:162`). The `fit_gllvm` docstring's own
  example passes `NegativeBinomial(1.0, 0.5)` and documents the result as
  per-species `r` — the field is decorative there today.
- The bridge says it in code: *"the dispersion field is re-estimated, so the init
  values here are irrelevant"* (`bridge.jl:192–193`), and passes literal dummies
  `NegativeBinomial(10.0, 0.5)`, `Beta(10.0, 1.0)`, `Gamma(2.0, 1.0)`.
- `ZIB` is the **only** marker whose field is forwarded, and its `N` is
  structural — never estimated. That is the discriminating property, not
  "markers carry fields".
- Both public NB1/BetaBinom routes already drop the field:
  `_fit_gllvm_grouped(::NB1, Y; kwargs...)` (`fit_gllvm.jl:180`) and
  `formula.jl:137–140`.

**Rejected: marker φ → `φ_init`.** No shipped marker seeds an init. All four
target fitters already expose a `φ_init` keyword, so the marker would create a
second source for one value, requiring a precedence rule and a disagreement
error — more surface than the admit itself. Worse, it would make a field
documented as inert **path-dependent**: identical calls returning numerically
different fits. Under C2 (per-trait) a scalar marker φ would additionally have
to broadcast across `G` groups, which has no defined meaning.

**C1b (recommended, additive).** Add zero-arg convenience constructors
`NB1() = NB1(1.0)` and `BetaBinom() = BetaBinom(1.0)` so the public call reads
`fit_gllvm(Y; family = NB1(), K = 2)` — matching `Poisson()`, `Beta()`,
`NegativeBinomial()`, `ZIPoisson()`. Purely additive (both currently
`MethodError`). Gate: the engine arc must confirm no *public* route reads
`family.φ` before landing it — verified true today for the two routes above; the
internal Laplace kernels construct their own `NB1(φ)` per iteration and are
unaffected.

### C2 — Dispersion grouping default: **per-trait**, via the API-B coerce (not a bare `_fit_gllvm` arm)

Extend the existing API-B coerce in `fit_gllvm` (`fit_gllvm.jl:89–91`) from
`(NegativeBinomial, Beta)` to include `NB1` and `BetaBinom`:
`disp_group === nothing` ⇒ `:species`.

Locked because all three shipped surfaces already say per-trait:

1. Twin `gllvmTMB`: `log_phi_nbinom1` and `log_phi_betabinom` are
   `PARAMETER_VECTOR`s of length `n_traits` — locked by #185 and #186.
2. Bridge no-X: `fit_nb1_gllvm_grouped(…; group = collect(1:p))` (`bridge.jl:990`),
   `fit_beta_binomial_gllvm_grouped(…; group = collect(1:p))` (`:1105`).
3. `@formula` + X: `fit_nb1_gllvm_grouped_cov` / `fit_beta_binomial_gllvm_grouped_cov`
   (`formula.jl:138`, `:140`).

Consequences the engine arc must implement (this is the actual change set, and
it is why "exports-only" is wrong):

- **No** `_fit_gllvm(::NB1, …)` / `_fit_gllvm(::BetaBinom, …)` arms are added.
  With the coerce in place they are unreachable; adding them would be dead code
  advertising the wrong estimand.
- **Add** `_fit_gllvm_grouped(::BetaBinom, …)` → `fit_beta_binomial_gllvm_grouped`.
  NB1's grouped arm already exists (`fit_gllvm.jl:180`; probe returns
  `NB1GroupedFit`), so **NB1 needs strictly less than BetaBinom** — do not
  assume symmetry when scoping.
- Update both error-message family lists (`fit_gllvm.jl:173`, `:187`).
- Shared φ remains reachable **only** through the named fitters
  `fit_nb1_gllvm` / `fit_beta_binomial_gllvm` — identical to the contract NB2 and
  Beta already carry.

**`row_eff` interaction — checked, not a regression.** The coerce makes
`row_eff != :none` collide with the now-set `disp_group`, raising the
"combination not yet supported" `ArgumentError` that NB2 already raises. Probed
at `dc3609f1`: `row_eff = :random` for NB1 and BetaBinom **already fails today**,
with a raw `MethodError` (`Cannot convert … GLLVM.NB1 to … Distribution`;
`no method matching _cov_default_link(::GLLVM.BetaBinom)`). The coerce therefore
replaces an unhandled `MethodError` with the family's clear `ArgumentError`. No
working route is closed.

### C3 — BetaBinom trials transport: `N` keyword passthrough, **required** at the boundary

**Transport:** a plain `N` keyword, carried by the existing `kwargs...` splat
into `fit_beta_binomial_gllvm_grouped(Y; K, group, N, …)`. No marker payload, no
new plumbing.

**Rejected: trials on the marker (`BetaBinom(φ, N)`, the ZIB shape).** ZIB's `N`
is a shared **scalar**; BetaBinom's is a **p×n matrix** (`beta_binomial.jl:318`,
`:479`, both validating `size(Nm) == (p, n)`). A p×n array on a dispatch tag is
heavy, breaks the shipped `BetaBinom(φ)` constructor used by `formula.jl:139` and
by all four BB fitters, and duplicates a data argument that already has a keyword
everywhere it is needed. #218 fenced the mirror-image mistake — do not
cargo-cult ZIB's marker-carried `N` back the other way.

**Require `N` at the `fit_gllvm` / `gllvm` boundary.** Do *not* inherit the
fitters' silent `N === nothing → fill(1, p, n)` default: at `N = 1` the
beta-binomial collapses exactly to `Bernoulli(μ)` and **φ is unidentifiable**.
Verified at `dc3609f1` by direct evaluation of `betabinomial_logp(1, 0.3, N, φ)`:

| φ | `N = 1` | `N = 6` |
|---|---|---|
| 0.5 | −0.5543552444685267 | −2.5010205376427157 |
| 5.0 | −0.5543552444685265 | −2.3188585456372204 |
| 50.0 | −0.5543552444684963 | −2.8840143315669584 |

At `N = 1` the log-density is flat in φ to ~3e-14 (roundoff); at `N = 6` the same
sweep spans ~0.57 nats. Inheriting the default would hand a user a per-trait φ
vector the likelihood cannot inform, with no warning. A missing `N` must raise a
clear `ArgumentError` naming the keyword.

Two things this deliberately does **not** do:

- **No scalar-`N` convenience** (`N::Number → fill(N, p, n)`, as `bridge.jl:1103–1104`
  does). Data-shape normalisation in the dispatcher is family-specific logic no
  other `fit_gllvm` family carries; if wanted it belongs in
  `src/families/beta_binomial.jl`, applied to all four BB fitters at once.
  Fenced as a follow-up.
- **No change to the named fitters' `N = ones` default.** That is a separate
  contract with its own tests, and the bridge depends on it at `:1103`. The
  requirement added here is a property of the *public entry point* only — a
  deliberate, documented divergence, not a fitter edit.

### C4 — Exports and naming

Export `NB1` and `BetaBinom` from `src/GLLVM.jl`. Because this is a public-API
addition, AGENTS.md rule 3 requires the cascade **in the same PR**: `fit_gllvm`
docstring, `formula.jl` docstring, `docs/src/response-families.md`,
`docs/src/tutorial.md`, README family list, and tests.

- **Naming.** `BetaBinom` is deliberately *not* `BetaBinomial`, to avoid
  colliding with `Distributions.BetaBinomial` (`beta_binomial.jl:30–33`). Once
  exported, `using GLLVM, Distributions` puts both names in scope; the docstring
  must state which is the GLLVM marker. Re-run Aqua after the export.
- **`TweedieED`** is the third unexported marker holding a grouped arm
  (`fit_gllvm.jl:181`) — same class, **out of scope here**, recorded so the next
  arc inherits it rather than rediscovering it.

## Bridge fence — the **inverse** of ZIB #218

ZIB was in **neither** `_BRIDGE_ONEPART_FAMILIES` nor `_BRIDGE_X_FAMILIES`, so
#218 had to fence bridge *admission* as owed follow-up work. Here both keys are
**already admitted**:

- `"nb1"`, `"betabinomial"` ∈ `_BRIDGE_ONEPART_FAMILIES` (`bridge.jl:162`, `:165`)
- `"nb1"`, `"betabinomial"` ∈ `_BRIDGE_X_FAMILIES` (`:186–187`)
- `"betabinomial"` ∈ `_BRIDGE_TRIALS_FAMILIES` (`:177`)
- both ∈ `_BRIDGE_GROUPED_DISPERSION_FAMILIES` (`:475–476`)

**Therefore the fence is: do not touch `src/bridge.jl` in this arc — at all.**
Nothing is owed there. The live risk is the opposite of ZIB's: an arc that sets
out to "unify the entry point" could rewrite the bridge's per-species route or
its `N` normalisation (`:1103–1104`) to match the new boundary rule. It must not.
`src/bridge.jl` is a shared choke point (merge-conductor only).

**Claim discipline that follows:** this arc changes **no** bridge behaviour and
therefore earns **no** new R-parity claim. The existing NB1+X and BetaBinomial+X
light Δ cells (`docs/design/capability-status.md:25–29`) stand exactly as
written; they are neither re-run nor restated. No twin Δ is invented for the
no-X `fit_gllvm` surface — it has no twin counterpart to compare against, since
`gllvmTMB` has no separate "unified entry point" surface.

## Formula cascade — opens by construction, cannot be deferred

`gllvm(@formula(y ~ 1), …)` with `q == 0` falls straight through to `fit_gllvm`
(`formula.jl:102–107`), which is why no-X NB1/BetaBinom raise the *same*
`ArgumentError` today (probed above). ZIB needed two PRs (#218 then #220) only
because `formula.jl` carries an explicit `family isa ZIB` branch that had to be
opened separately. NB1 and BetaBinom have **no such branch**, so the `fit_gllvm`
admit **automatically opens the `@formula` no-X surface in the same PR**.

Consequences: the engine arc must test *both* surfaces together, and the
check-log / ledger entry must claim both. There is no "fit_gllvm first, formula
later" split available here.

## Rejected alternatives

| Option | Why rejected |
|---|---|
| Exports-only + one-line `_fit_gllvm(::NB1, Y) = fit_nb1_gllvm(Y)` (the ZIB #218 shape) | Ships a **shared-φ** public default against the **per-trait** default locked by #185/#186 and already shipped on the bridge and `@formula`+X — one family, three surfaces, two estimands |
| Marker φ forwarded to the fitter | Pins a free parameter; ZIB's forwarding is licensed by `N` being *structural*, which φ is not |
| Marker φ as `φ_init` | No precedent; collides with the existing `φ_init` keyword; makes a nominally inert field path-dependent; undefined under per-trait `G > 1` |
| Shared φ as the `fit_gllvm` default, per-trait via `disp_group` | Inverts NB2/Beta's shipped contract and the twin default |
| Trials on the marker `BetaBinom(φ, N)` | p×n matrix on a dispatch tag; breaks the shipped `BetaBinom(φ)` constructor and `formula.jl:139`; ZIB's scalar `N` does not generalise |
| Inherit the fitters' silent `N = ones` default at the entry point | φ provably unidentifiable at `N = 1` (flat to ~3e-14; table in C3) — silently unidentified fit |
| Normalise scalar `N` inside `fit_gllvm` | Family-specific data shaping in the dispatcher; belongs in the family file, across all four BB fitters |
| Change the named fitters' `N = ones` default now | Separate contract with its own tests; `bridge.jl:1103` depends on it |
| Admit / edit `nb1` or `betabinomial` in `src/bridge.jl` | Already admitted on every relevant list; nothing is owed, and the file is a merge-conductor choke point |
| Bundle `TweedieED` (the third unexported marker) | Same class, own G0; scope creep |
| Split `@formula` no-X into a follow-up PR (the #220 shape) | Not available — `formula.jl` has no NB1/BetaBinom no-X branch; the surface opens by fall-through |
| Claim R-parity or a twin Δ from this arc | No bridge behaviour changes; no twin surface to compare |

## Out of scope

- `TweedieED` marker export / admit — own arc, own G0.
- `src/bridge.jl` — nothing owed; do not open (choke point).
- Shared-φ NB1/BetaBinom under `fit_gllvm` — named fitters only.
- Scalar-`N` convenience; any change to the fitters' `N = ones` default.
- ADEMP / coverage certificates; twin light Δ; re-opening #185 / #186.
- ZIB+X on any surface (still OWED from #218).

## Ownership (engine arc)

- **OWN:** `src/families/fit_gllvm.jl` (coerce list, `_fit_gllvm_grouped(::BetaBinom, …)`,
  `N`-required guard, error lists, docstring); `src/families/negbin1.jl` +
  `src/families/beta_binomial.jl` (C1b zero-arg constructors only); a new focused
  test file; the rule-3 docs cascade; this note.
- **CONDUCTOR:** `src/GLLVM.jl` export block (shared choke point — coordinate,
  as #218 did).
- **NOT:** `src/bridge.jl`; the `formula.jl` dispatch body (its docstring only);
  any parallel `twopart.jl` / ZIB lane.

## Rose fence

**OK to claim after the engine arc:** "NB1 and BetaBinom are reachable through
`fit_gllvm` and through `@formula` with no X, with **per-trait φ**, matching the
estimand already shipped on the bridge and on `@formula`+X; BetaBinom requires an
explicit p×n trials matrix `N`."

**NOT OK to claim:** any new R-parity or twin Δ; any coverage / ADEMP result; any
change in bridge behaviour; shared-φ availability through `fit_gllvm`; that
`TweedieED` is admitted; that BetaBinom accepts a scalar `N`.

## STOP / CONTINUE

Identity **ACCEPTED** → **CONTINUE** to the engine arc. Its G0 may open only with
**C1–C4** present on the branch tip: C1 (marker φ ignored, always estimated),
C2 (per-trait coerce; `_fit_gllvm_grouped(::BetaBinom)`; **no** bare
`_fit_gllvm` arms), C3 (`N` keyword, **required**, no marker payload, no scalar
normalisation), C4 (exports + rule-3 cascade). An engine arc built on a copy of
this note predating C2 or C3 is **not admitted**: those two are the failure modes
this note exists to close.
