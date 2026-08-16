# Decision: Tweedie no-X `fit_gllvm` identity — shared `fit_tweedie` vs public `TweedieED`

**Date:** 2026-08-16
**Status:** ACCEPTED as a decision record; **engine admit NOT admitted** (gate T6 fails today)
**Lane:** `cursor/tweedie-identity-20260816`
**Tip probed:** `7254edda` (post-#233 delta no-X surface admit, CI green)
**Depends on:** NB1 + BetaBinom no-X `fit_gllvm` Identity
`2026-08-16-nb1-betabinom-fit-gllvm-identity.md` (#230), which named `TweedieED` as
the third unexported grouped-arm marker and deferred it to "its own arc, own G0" —
this is that arc. Student-t no-X admit (#232) is the **shape precedent** invoked and
then rejected below.
**Do not** re-open #230 / #232. **Do not** invent a twin `gllvmTMB` light Δ for any
surface in this note. **Do not** touch `src/bridge.jl`. **Do not** widen or reseed the
existing Tweedie tests to make the engine gate pass.

## Problem

Tweedie is the last one-part family with a complete Laplace engine, a grouped
fitter, post-fit methods, CIs, and a `simulate` method that is still unreachable
through the unified `fit_gllvm` entry point with a bare marker — and hence through
no-X `@formula`, which falls through to it.

The obvious fix is the #232 Student-t shape: export the marker, add one
`_fit_gllvm` arm, ship. That is **wrong here for two independent reasons**. First,
the marker's second field is the Tweedie **power**, and the twin's family object
uses that exact argument to *pin* the power — so a tag-payload reading of the field
would silently do the opposite of what the twin does with the same call. Second,
and decisively, the underlying fitter does not currently earn a public entry point:
on its own shipped test cell it returns `converged = true` at a point ~9 orders of
magnitude worse in log-likelihood than a neighbouring start (§T6).

### Live surface map (probed at `7254edda`, not inferred)

| Surface | Tweedie | Dispersion / power estimand |
|---|---|---|
| Named shared fitter `fit_tweedie_gllvm` | **shipped** | shared scalar `φ`, single estimated power |
| Named grouped fitter `fit_tweedie_gllvm_grouped` | **shipped** | per-group `φ`, single **shared** estimated power |
| `fit_gllvm(disp_group = :species)` | **works** → `TweedieGroupedFit` | per-trait `φ`, shared power |
| `fit_gllvm` bare marker | **ArgumentError** | — |
| `@formula` no-X (`q == 0`) | **ArgumentError** (falls through) | — |
| `@formula` + X | **absent** (no Tweedie branch) | — |
| R bridge no-X / +X | **absent** (`"tweedie"` on no bridge list) | — |
| Marker exported? | **no** (`TweedieED` internal) | — |

Verbatim probe (`julia --project=. …` at `7254edda`, p=4, n=8, K=1):

```
--- marker export status (after `using GLLVM`) ---
TweedieED         not exported
NB1               EXPORTED
BetaBinom         EXPORTED
ZIB               EXPORTED
StudentTFamily    EXPORTED
DeltaGamma        EXPORTED
--- zero-arg / one-arg constructors? ---
TweedieED()       NO (MethodError)
TweedieED(1.0)    NO (MethodError)
--- field names ---
TweedieED         (:φ, :p)
TweedieFit        (:β, :Λ, :φ, :p, :link, :loglik, :converged, :iterations)
TweedieGroupedFit (:β, :Λ, :φ, :power, :group, :link, :loglik, :converged, :iterations)
--- fit_gllvm bare marker (no disp_group) ---
bare marker       ArgumentError: fit_gllvm: family TweedieED is not implemented yet …
--- fit_gllvm disp_group = :species ---
disp_group        OK -> TweedieGroupedFit    power = 1.5000019470302997   G = 4
--- is the marker's (φ, power) read at all? ---
TweedieED(1.0, 1.05)  -> power 1.5000019470302997  loglik -1.3543019235661346e7
TweedieED(99.0, 1.95) -> power 1.5000019470302997  loglik -1.3543019235661346e7
identical loglik? true  identical power? true
--- power-init keyword names across the two fitters ---
scalar p_init       OK
scalar power_init   MethodError: no method matching fit_tweedie_gllvm(…; power_init=…)
grouped power_init  OK
grouped p_init      MethodError: no method matching fit_tweedie_gllvm_grouped(…; p_init=…)
fit_gllvm p_init    MethodError: no method matching fit_tweedie_gllvm_grouped(…; p_init=…)
--- @formula no-X (q = 0) with the Tweedie marker ---
formula no-X      ArgumentError: fit_gllvm: family TweedieED is not implemented yet …
```

## Why this is not surgical like Student-t #232

| # | Student-t #232 | Tweedie |
|---|---|---|
| 1 | Marker `StudentTFamily` already exported, with zero-arg and one-arg constructors | `TweedieED` unexported; **both** fields mandatory (`TweedieED()` and `TweedieED(1.0)` are `MethodError`) ⇒ export is a public-API addition (AGENTS.md rule 3 cascade) *and* needs constructors |
| 2 | Marker name is already a public-quality name | `TweedieED` is an internal implementation name (ED = exponential dispersion); exporting locks it (§T5) |
| 3 | `ν` structural ⇒ forwarded; unambiguous | The power is **neither** clearly structural nor clearly a payload: the fitters estimate it, the twin lets the user pin it, and the marker field looks exactly like the twin's pin (§T2) |
| 4 | One fitter, one keyword convention | Two fitters with **different** keyword names for the same quantity (`p_init` vs `power_init`), neither accepting the other (§T3) |
| 5 | Engine healthy; the admit exposed a working fitter | The fitter returns start-pinned, sentinel, and out-of-contract results while reporting `converged = true` (§T6) |

A sixth asymmetry *reduces* scope: like #230 and unlike #218, **the bridge needs no
admission** — but for the opposite reason. `"tweedie"` is on **no** bridge family
list at all, so there is nothing to admit and nothing to fence beyond "do not open
it" (§Bridge fence).

## Decision

### T1 — Marker `φ` is a tag payload, ignored on every route; `φ` is always estimated

Identical to #230 C1, and now backed by direct evidence rather than precedent:
`TweedieED(1.0, 1.05)` and `TweedieED(99.0, 1.95)` produce **bitwise identical**
`loglik` and `power` through the live `disp_group` route (probe above). The field
is already inert on the one public route Tweedie has.

Locked: no forwarding, and **not** as `φ_init`. The `φ_init` / warm-start keywords
already exist on both fitters; a marker seed would create a second source for one
value and make a nominally inert field path-dependent (#230 C1, verbatim).

### T2 — The power is **pin-capable**, not a tag payload: `TweedieED`'s second field must mean "fix the power here", or not exist

This is the decision this note exists to make, and it is the one place where reading
the twin changes the answer.

Twin semantics (read-only reference, `gllvmTMB` local checkout):

- `tweedie <- function(link = "log", p = NULL)` (`R/families.R:438`). `p = NULL`
  (default) ⇒ the power is **estimated**; a numeric `p` ⇒ the power is **pinned**.
- The pin is implemented by mapping the TMB parameter out:
  `tmb_params$logit_p_tweedie[…] <- qlogis(p_pin − 1)` with `tmb_map$logit_p_tweedie`
  set to `NA` for pinned traits (`R/fit-multi.R:4697–4717`).
- Same reparameterisation as ours: `PARAMETER_VECTOR(logit_p_tweedie)` with
  `p = 1 + invlogit(·)` (`src/gllvmTMB.cpp:802–803`, `:2228–2233`).
- The twin states the reason in-source: *"the power, dispersion phi, and any
  random-effect variance sit on a shared ridge, so fixing p is the standard way to
  stabilise variance-component recovery"* (`R/families.R:450–452`).

GLLVM.jl today has **no** way to fix the power: both fitters always estimate it,
seeded by `p_init` / `power_init` (`src/families/tweedie.jl:220`, `:228`;
`src/families/grouped_dispersion.jl:1542–1545`). So `TweedieED(φ, p)` is a marker
whose second field is *named and typed* like the twin's pin and *behaves* like an
ignored tag.

**Locked:** the public marker must not carry an inert power field. Exactly one of:

- **T2a (recommended).** Give the marker an *optional, honest* power:
  `TweedieED(; p = nothing)` semantics — `nothing` ⇒ estimated (today's behaviour),
  a number in (1,2) ⇒ **pinned**, which requires a real `p_fixed` capability in both
  fitters (drop `ξ` from the packed vector, hold the power at the supplied value).
  This is additive, matches the twin argument-for-argument, and is the only reading
  under which a user transferring a `tweedie(p = 1.5)` habit gets what they expect.
  It is **engine work**, not a dispatch arm.
- **T2b (fallback).** Ship a power-free public marker (§T5) and keep the power
  estimated-only, with the pin recorded as owed. Acceptable only if T2a is
  explicitly deferred **and** the docstring says the power is always estimated and
  the twin's `p =` has no Julia equivalent yet.

**Rejected: keep `TweedieED(φ, p)` as a two-field tag-payload marker (the NB1 shape).**
NB1's inert `φ` is harmless because no twin surface reads `nbinom1(φ = …)` as a pin.
Tweedie's `p` is the opposite: the twin's identically-named, identically-ranged
argument *is* a pin. A public `fit_gllvm(Y; family = TweedieED(1.0, 1.5))` that
silently estimates the power would be a same-name-opposite-meaning trap — and,
given §T6, a trap that lands the user on the exact start-pinned failure mode.

**Rejected: power as structural, always fixed (the `StudentTFamily(ν)` / `ZIB(N)` shape).**
That would remove the estimated power the twin defaults to, and break `TweedieFit.p`
as a reported estimate along with the Wald/profile CI endpoints already routed for it.

### T3 — Unify the power-init keyword before the admit: `power_init` everywhere

`fit_tweedie_gllvm` takes `p_init` (`src/families/tweedie.jl:192`);
`fit_tweedie_gllvm_grouped` takes `power_init`
(`src/families/grouped_dispersion.jl:1550`). Neither accepts the other's name
(probe above). Consequences today:

- `fit_gllvm(Y; family = …, disp_group = :species, p_init = 1.2)` leaks a raw
  `MethodError` out of a public entry point, naming an internal fitter.
- A single `_fit_gllvm` arm cannot forward one user-facing name to both fitters.

**Locked:** `power_init` is the surviving name (it does not collide with `p` = number
of species, the universal convention in this codebase — which `fit_tweedie_gllvm`
already works around by binding `p_sp = size(Y, 1)` at `tweedie.jl:196`). `p_init`
stays as a deprecated
alias on `fit_tweedie_gllvm` for one release. This is a rule-3 convention cascade and
must land **before or with** the admit, not after.

### T4 — Dispersion grouping default: **per-trait `φ`**, via the API-B coerce; power stays **shared**, and that gap is stated, not claimed away

Extend the `fit_gllvm` coerce (`src/families/fit_gllvm.jl:119–123`) to include the
Tweedie marker: `disp_group === nothing` ⇒ `:species`. The grouped arm already exists
(`fit_gllvm.jl:238–239`) and already returns `TweedieGroupedFit`, so — as with NB1 in
#230 — **Tweedie needs strictly less plumbing than BetaBinom did**; no bare
`_fit_gllvm` arm should be added, because the coerce makes it unreachable and it
would advertise the shared-`φ` estimand.

Per-trait `φ` matches the twin: `PARAMETER_VECTOR(log_phi_tweedie)` is length
`n_traits` (`src/gllvmTMB.cpp:802`).

**But the power does not match, and this must be said plainly.** The twin's
`logit_p_tweedie` is *also* a length-`n_traits` vector (`gllvmTMB.cpp:803`) — a
**per-trait power**. Our grouped fitter estimates a **single shared** power by
construction (one `ξ` in the packed vector,
`src/families/grouped_dispersion.jl:1419–1421`, `:1600`). So the admitted route is
twin-aligned on `φ` and **not** twin-aligned on the power.

**Locked:** the admit may claim per-trait `φ` alignment only. Per-trait power is
**out of scope** and must be recorded as a known estimand gap in
`docs/src/gllvmtmb-parity.md`, not silently folded into a "twin-aligned" claim.
(`gllvmtmb-parity.md:96` currently compares only the power *start* — 1.1 vs 1.5 — and
does not mention that the twin's power is per-trait. That row is now known to be
incomplete; correcting it is part of the cascade.)

### T5 — Marker naming, export, and constructors

`TweedieED` is an internal name (`src/families/tweedie.jl:15–20`, commented "A plain
marker — NOT a Distributions type"). It is not exported (`src/GLLVM.jl:185`, `:194`
export the fitters and result types only). Exporting it as-is locks three defects:

1. **The name.** Every other public marker reads as a family (`NB1`, `BetaBinom`,
   `ZIB`, `ZIPoisson`, `StudentTFamily`, `DeltaGamma`); `TweedieED` reads as an
   implementation detail. **Locked:** export as `Tweedie`, with `TweedieED` retained
   internally (or aliased) so the family pieces and `grouped_dispersion.jl` are
   untouched. Probed at `7254edda`: `Distributions` exports no `Tweedie` and `GLLVM`
   defines no such name, so the export is collision-free today — re-run Aqua after it
   lands anyway, as #230 C4 required for `BetaBinom`.
2. **The field name `p`.** It collides with the codebase-wide `p` = number of
   species, and the two result structs already disagree with each other:
   `TweedieFit.p` is the power while `TweedieGroupedFit.power` is the power (probe
   above). **Locked:** the public marker's field is `power`; harmonising
   `TweedieFit.p` → `TweedieFit.power` is a **breaking** change to a public struct
   and is therefore **out of scope here** — record it, do not sneak it in.
3. **No convenience constructor.** `Tweedie()` must exist (matching `NB1()`,
   `BetaBinom()`, `StudentTFamily()`, `DeltaGamma()`), meaning "estimate `φ`,
   estimate the power" under T2a.

### T6 — Engine-health gate: the admit may not open until `fit_tweedie_gllvm` stops returning start-pinned, sentinel, and out-of-contract fits

This is a **blocking precondition**, not a style note. Probed at `7254edda` on the
**shipped test cell verbatim** (`test/test_tweedie.jl:48–70`, `Random.seed!(2024)`,
p=5, n=40, K=2):

```
DEFAULT fit (p_init = 1.5):
  φ̂ = 0.9999999999228959   p̂ = 1.5000000018073405
  loglik = -3.8886709205772174e11   converged = true  iters = 7
  passes the shipped assertions? isfinite=true 1<p<2=true φ>0=true

--- same data, other power starts (does the answer move?) ---
  p_init=1.1   -> p̂=1.25195   φ̂=2.07988    loglik=-569.739961      conv=true
  p_init=1.3   -> p̂=1.3       φ̂=1.0        loglik=-1090.07221      conv=true
  p_init=1.5   -> p̂=1.5       φ̂=1.0        loglik=-3.88867092e11   conv=true
  p_init=1.7   -> p̂=1.0       φ̂=3.24777e54 loglik=-1.0e12          conv=true
  p_init=1.9   -> p̂=1.0       φ̂=2.2042099999999998e205  loglik=-1.0e12  conv=true
```

Four distinct defects, all reported as `converged = true`:

1. **Start-pinned.** At the default start, `φ̂` and `p̂` are within `1e-9` of
   `(φ_init, p_init) = (1.0, 1.5)`: the optimiser never moves the dispersion pair.
2. **Nine orders of magnitude left on the table.** The same data from `p_init = 1.1`
   reaches `loglik = −569.7` versus `−3.889e11` from the default start.
3. **Sentinel leakage.** `loglik = -1.0e12` is `negll`'s internal failure sentinel
   (`src/families/tweedie.jl:234`, `:236`) negated and returned as a maximised
   Laplace log-likelihood. It is finite, so no assertion catches it.
4. **Out-of-contract estimate.** `p̂ = 1.0` violates the documented open interval
   `p ∈ (1,2)` asserted by `TweedieFit`'s own docstring
   (`src/families/tweedie.jl:149–152`); it is `ξ → −∞` with `φ̂ ≈ 2e205`, i.e. a
   diverged run reported as converged.

Corroborating: at fixed `(β̂, Λ̂, p̂)` from the default fit, the Laplace marginal
improves monotonically from `−1.21e14` at `φ = 0.1` to `−7.79e8` at `φ = 16`, so the
returned point is not even a local optimum in `φ` alone.

**Prior partial record, credited.** `docs/dev-log/check-log.md:592–614` (2026-08-03)
already found "the fitted power `p` pinned at its `p_init=1.5` default … a
knife-edge-flat likelihood ridge in `(φ, p)`" and repaired it **by changing the DGP
seed** in `test_confint_family.jl` (35 → 3). What is new here: the pinning is not a
seed-specific CI flake but the **default behaviour on the family's own shipped test
cell**; it costs ~9 orders of magnitude of log-likelihood; and two of five power
starts produce a boundary `p̂ = 1.0` with a sentinel log-likelihood.

**Why the test suite is green anyway.** `test/test_tweedie.jl:64–69` asserts only
`isa TweedieFit`, `isfinite(loglik)`, `1 < p < 2`, `φ > 0`, and `size(Λ)` — with the
explicit comment "no recovery thresholds" (`:46`). All four defects pass those
assertions at the default start. This is exactly the failure mode the
recovery-over-`pdHess` guard exists to catch: a converged fit is not a validated fit.

**Gate (all four required before the engine arc's G0 may open):**

- **G-a** A power start sweep over `p_init ∈ {1.1, 1.3, 1.5, 1.7, 1.9}` on the
  shipped cell agrees on `(φ̂, p̂)` to a stated tolerance, or the fitter reports
  non-convergence instead of a number.
- **G-b** No public result ever carries the `1e12` sentinel: exhausting the objective
  must set `converged = false` (and ideally warn), never return `−1e12` as `loglik`.
- **G-c** `p̂` is strictly inside `(1,2)` or the fit is flagged; a boundary run is a
  failure, not a result.
- **G-d** An ADEMP recovery check on `(φ, power)` at a sane cell, per AGENTS.md
  design rule 1 — the existing tests have none.

T2a's power pin is the twin's own stabiliser for exactly this ridge and is the most
likely route through G-a.

## Bridge fence — nothing owed, and nothing to open

`"tweedie"` appears on **no** bridge list — not `_BRIDGE_ONEPART_FAMILIES`, not
`_BRIDGE_X_FAMILIES`, not `_BRIDGE_GROUPED_DISPERSION_FAMILIES`. `src/bridge.jl` has
**zero** occurrences of the string at `7254edda`.

**Therefore the fence is: do not touch `src/bridge.jl` in this arc — at all.** Unlike
#218 (which owed a bridge admission) and #230 (where the bridge was already
complete), here the family is simply absent from the bridge, and adding it is a
separate arc with its own Identity and its own parity evidence. **No twin Δ is
invented for any Tweedie surface**, and no R-parity claim follows from anything in
this note.

## Formula cascade — opens by construction

`gllvm(@formula(y ~ 1), …)` with `q == 0` falls straight through to `fit_gllvm`
(`src/formula.jl:106–109`), and `formula.jl` has **no** Tweedie branch, so the no-X
`@formula` surface opens automatically in whichever PR lands the `fit_gllvm` admit —
the #218 → #220 split is not available, exactly as in #230. `@formula` **with** X
stays closed (no `_cov` Tweedie route exists) and is out of scope.

## Rejected alternatives

| Option | Why rejected |
|---|---|
| Export `TweedieED` + one `_fit_gllvm` arm (the #232 Student-t shape) | Exposes a start-pinned fitter (§T6) behind the flagship entry, locks an internal marker name, and ships an inert power field that the twin reads as a pin |
| Treat the marker's power as a tag payload (the #230 NB1 shape) | NB1's `φ` has no twin pin semantics; Tweedie's `p` does — same name, same range, opposite behaviour |
| Treat the power as structural, always fixed (the `StudentTFamily(ν)` shape) | Removes the estimated power the twin defaults to; breaks `TweedieFit.p` and the Tweedie Wald/profile CI endpoints already routed for it |
| Marker power → `power_init` seed | No shipped marker seeds an init (#230 C1); makes a documented-inert field path-dependent; and under §T6 the seed *is* the answer, which is precisely the bug |
| Add a bare `_fit_gllvm(::TweedieED, …)` → `fit_tweedie_gllvm` | Unreachable once the T4 coerce is in place, and advertises the shared-`φ` estimand against the per-trait twin default |
| Claim twin alignment on the power under T4 | The twin's power is per-trait (`gllvmTMB.cpp:803`); ours is shared. Alignment holds for `φ` only |
| Land the admit now and fix the optimiser later | The admit is what makes the defect reachable from the documented entry point; order matters |
| Reseed or relax `test/test_tweedie.jl` so the gate passes | Tolerance/seed laundering of a real defect (AGENTS.md rule 5). The 2026-08-03 seed swap already spent that move once |
| Rename `TweedieFit.p` → `.power` in this arc | Breaking change to a public struct; record it, do not bundle it |
| Admit `"tweedie"` to `src/bridge.jl` | Absent from every bridge list; separate arc, separate Identity, needs parity evidence this note does not have |

## Out of scope

- The bridge (`src/bridge.jl`) — Tweedie absent everywhere; separate arc.
- `@formula` **with** X for Tweedie; any `_cov` Tweedie route.
- Per-trait Tweedie power (the twin's `logit_p_tweedie` vector) — its own arc.
- Renaming `TweedieFit.p` → `.power` (breaking).
- Any R-parity claim, twin light Δ, coverage or ADEMP certificate for Tweedie.
- Re-opening #230 / #232; the ZIB+X debt still OWED from #218.

## Ownership (later engine arc)

- **OWN:** `src/families/tweedie.jl` (power pin under T2a, `power_init` rename with
  `p_init` alias, sentinel/convergence repair under G-b/G-c, public constructors);
  `src/families/grouped_dispersion.jl` (Tweedie block only — `power_init` already
  correct); `src/families/fit_gllvm.jl` (T4 coerce, error lists, docstring); a new
  focused test file plus the ADEMP recovery check (G-d); the rule-3 docs cascade
  (`docs/src/response-families.md:89–98`, `:327`, `docs/src/tutorial.md:82–123`,
  `docs/src/gllvmtmb-parity.md:96`, README family list); this note.
- **CONDUCTOR:** `src/GLLVM.jl` export block (shared choke point — coordinate).
- **NOT:** `src/bridge.jl`; the `formula.jl` dispatch body (its docstring only);
  `test/test_confint_family.jl` (the 2026-08-03 seed repair stands; do not re-litigate
  it in this arc); any parallel two-part / ZIB lane.

## Rose fence

**OK to claim now (from this note alone):** that the Tweedie `fit_gllvm` identity is
decided and recorded; that the marker's `φ` is provably inert on the live route; that
`TweedieED` is unexported and the bare-marker / no-X `@formula` routes error; that
the twin pins the power via `tweedie(p = )` and carries per-trait `φ` **and**
per-trait power; that the shipped Tweedie fitter is start-pinned on its own test cell.

**NOT OK to claim:** that Tweedie is admitted, reachable, or "surface complete"; any
R-parity result or twin Δ; any coverage / ADEMP evidence; that the power can be
fixed today; that the grouped route is twin-aligned on the power; that the engine
defect in §T6 is repaired.

## STOP / CONTINUE

Identity **ACCEPTED** → **STOP**. The engine admit does **not** open in a follow-up
PR from this arc. It was scoped as "surgical like Student-t #232"; §T2, §T3, §T5, and
above all §T6 show it is not — the admit would put a fitter that returns
`converged = true` on a diverged, sentinel, or start-pinned point behind the
package's flagship entry point.

The engine arc's G0 may open only when **T2 (power pin or an honest power-free
marker), T3 (`power_init` unified), T4 (per-trait coerce, no bare arm, power gap
stated), T5 (public name + constructors)** are agreed on the branch tip **and
G-a…G-d in T6 pass**. T6 is the load-bearing one: it is an engine-repair arc with a
surface admit attached, not a surface admit.
