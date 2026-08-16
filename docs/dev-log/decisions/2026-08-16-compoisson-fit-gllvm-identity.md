# Decision: COM-Poisson no-X `fit_gllvm` identity (marker `ν` is a tag payload)

**Date:** 2026-08-16
**Status:** ACCEPTED (Arc 0 — locks the tag-vs-pin question; engine admit is a
**second** PR, scoped below)
**Lane:** `cursor/compoisson-identity-20260816`
**Tip probed:** `d70a6a25` (merge of #237, Hurdle-Poisson no-X surface admit)
**Depends on:** NB1 + BetaBinom no-X Identity
`2026-08-16-nb1-betabinom-fit-gllvm-identity.md` (#226 / #230) for the tag-payload
convention; Student-t no-X admit (#232) as the **contrast** (same Greek letter,
opposite role); Hurdle-Poisson no-X admit (#237) as the **shape precedent** for
the engine PR.
**Do not** re-open #232 / #234 / #237. **Do not** invent a twin `gllvmTMB` light
Δ. **Do not** touch `src/bridge.jl`. **Do not** open `src/families/tweedie.jl`
(Tweedie grouped-health lane #238).

## Why this family, not Hurdle-NB or Ordered-beta

#237 closed the last *empty-marker* `_fit_gllvm` admit. The remaining
marker-field families on the north-star list are Hurdle-NB (`r`), COM-Poisson
(`ν`), and Ordered-beta (`φ` plus cutpoints). One Identity, cheapest first.

Read off `origin/main` @ `d70a6a25` plus twin `.valid_family`
(`gllvmTMB/R/enum.R`, ids 0–16) and the 2026-08-16 gap sheet. Tweedie is out of
lane (#234 Identity; #238 grouped-health).

| Candidate | Marker exported? | Fields | Twin | Why not this slice |
|---|---|---|---|---|
| **COM-Poisson** | **yes** (`COMPoisson`) | one estimated `ν` | **not in twin** | — **this slice** |
| Hurdle-NB (`HurdleNB`) | **no** | one estimated `r` | not in twin | export is a public-API addition (AGENTS.md rule 3 cascade) on top of the same tag lock |
| Ordered-beta (`OrderedBeta`) | **no** | three estimated fields (`c0`, `c1`, `φ`) | not in twin | export + three-field Identity; not cheapest |

COM-Poisson is the cheapest remaining admit **after** the tag-vs-pin lock:
marker already exported, one named fitter, tests already in `runtests.jl`, twin
has no CMP family so there is no pin semantics to invent (the Tweedie trap).

Hurdle-NB is the same Identity *shape* (`r` tag, always estimated) but is
strictly more expensive because `HurdleNB` is unexported. Ordered-beta is a
later slice.

## Problem

`COMPoisson` has a complete, tested Laplace engine (`fit_compoisson_gllvm`,
`test/test_com_poisson.jl` already included from `runtests.jl`) and an
**already-exported** marker, but no `_fit_gllvm` arm. No-X `@formula` falls
through to `fit_gllvm` (`formula.jl:106–111`), so both public surfaces error.

The marker carries `ν`. The named fitter **estimates** `ν` (packed as `log ν`,
seeded by `ν_init = 1.0`). The same Greek letter is **structural** on
`StudentTFamily(ν)` (#232): fixed, forwarded, a separate `nu` keyword is
rejected. Shipping an arm without locking that contrast would make
`COMPoisson(2.0)` look like "pin underdispersion" when the fitter will estimate
`ν` anyway.

### Live surface map (probed at `d70a6a25`, not inferred)

| Surface | COM-Poisson | `ν` estimand |
|---|---|---|
| Named fitter `fit_compoisson_gllvm` | **shipped** | shared scalar `ν`, always estimated (`ν_init` seeds) |
| `fit_gllvm` bare marker | **ArgumentError** | — |
| `@formula` no-X (`q == 0`) | **ArgumentError** (falls through) | — |
| `@formula` + X | **absent** (no COM-Poisson branch) | — |
| R bridge no-X / +X | **absent** (no `compoisson` / `CMP` symbol in `bridge.jl`) | — |
| Marker exported? | **yes** | — |
| Zero-arg constructor? | **no** (`COMPoisson()` is `MethodError`) | — |
| Twin `gllvmTMB` | **not in** `.valid_family` (ids 0–16) | no pin to invent |

Verbatim probe (`julia --project=. …` at `d70a6a25`, p=4, n=8, K=1):

```
--- marker export status (after `using GLLVM`) ---
COMPoisson            EXPORTED
HurdleNB              not exported
HurdlePoisson         EXPORTED
OrderedBeta           not exported
ZIPoisson             EXPORTED
NB1                   EXPORTED
--- constructors ---
COMPoisson()          MethodError: no method matching COMPoisson()
COMPoisson(1.0)       OK  fields=(:ν,)
COMPoisson(2.0)       OK  fields=(:ν,)
HurdleNB()            MethodError
HurdleNB(5.0)         OK  fields=(:r,)
OrderedBeta()         MethodError
OrderedBeta(-1,1,8)   OK  fields=(:c0, :c1, :φ)
--- fit_gllvm no-X ---
COMPoisson(1.0)       ArgumentError: fit_gllvm: family COMPoisson is not implemented yet …
COMPoisson(2.0)       ArgumentError: fit_gllvm: family COMPoisson is not implemented yet …
HurdleNB(5.0)         ArgumentError: fit_gllvm: family HurdleNB is not implemented yet …
OrderedBeta(-1,1,8)   ArgumentError: fit_gllvm: family OrderedBeta is not implemented yet …
HurdlePoisson()       OK -> HurdlePoissonFit
--- @formula no-X (q = 0) ---
COMPoisson(1.0)       ArgumentError: fit_gllvm: family COMPoisson is not implemented yet …
HurdleNB(5.0)         ArgumentError: fit_gllvm: family HurdleNB is not implemented yet …
--- named fitter ---
fit_compoisson_gllvm  defined
```

The two `COMPoisson(1.0)` / `COMPoisson(2.0)` calls error **before** any
likelihood evaluation — the marker field is not read today because there is no
arm. The named fitter never takes a `COMPoisson` instance: `ν` enters as the
`ν_init` keyword (`com_poisson.jl:278–309`), then is re-estimated.

## Why this *is* surgical after the locks (unlike Tweedie #234)

| # | Tweedie #234 (STOP) | COM-Poisson (this note) |
|---|---|---|
| 1 | Marker unexported; both fields mandatory | Marker **already exported** |
| 2 | Twin `tweedie(p = …)` **pins** the power | Twin has **no** COM-Poisson family — no pin to invent |
| 3 | Two fitters, `p_init` vs `power_init` disagree | One fitter, one keyword (`ν_init`) |
| 4 | Default start reports `converged = true` at a sentinel loglik | Shipped tests include the `ν = 1 ⇒ Poisson` anchor (`test_com_poisson.jl`) and a smoke fit |
| 5 | `ν` on `StudentTFamily` is structural — Tweedie power is neither | COM-Poisson `ν` is **estimated**, so the NB1/ZIP tag reading applies; the Student-t reading is the rejected alternative |

A sixth asymmetry *reduces* scope: **the bridge needs no admission**. There is
no `compoisson` string on any bridge family list (`rg` of `src/bridge.jl` is
empty). Do not open `bridge.jl`.

## Decision

### C1 — Marker `ν` is a tag payload, ignored on every route; `ν` is always estimated

The marker's `ν` field is **never read** by `fit_gllvm` / `@formula`. It is not
forwarded, and it is **not** used as `ν_init`. `ν` is estimated on every public
route, always.

This is the shipped house convention for *estimated* marker fields, not a new
one:

- `_fit_gllvm(::NB1, …)` never exists; the grouped arm drops `φ` (#230 C1).
- `_fit_gllvm(::DeltaLogNormal, …)` / `::DeltaGamma` drop `σ` / `α` (#233).
- `_fit_gllvm(::NegativeBinomial, …)` / `::Beta` / `::GeneralizedPoisson1` bind
  `::T` and drop the field.
- `ZIPoisson` / `HurdlePoisson` are empty — the ZIP/hurdle pattern for a
  no-payload marker. COM-Poisson is the same pattern **plus** an inert field.

**The Student-t contrast (same letter, opposite role).**
`StudentTFamily(ν)` forwards `ν` because it is **structural**: it defines the
likelihood and is held fixed (`fit_gllvm.jl:196–208`; #232). COM-Poisson `ν` is
the dispersion exponent the named fitter already estimates on `log ν`
(`com_poisson.jl:263–265`, `:309–330`). Treating `COMPoisson(ν)` like
`StudentTFamily(ν)` would *pin* a free parameter the engine does not pin.

**Rejected: marker `ν` → `ν_init`.** No shipped marker seeds an init. The
fitter already exposes `ν_init` (default `1.0`, the Poisson anchor). A marker
seed would create a second source for one value, require a precedence rule, and
make a field documented as inert path-dependent — identical calls returning
numerically different fits (#230 C1, verbatim).

**Rejected: `ν` as structural / pin-capable (the Student-t / Tweedie-T2 shape).**
There is no twin pin. Inventing one would be a twin Δ. The named fitter has no
`ν_fixed` path. Pinning would also break `COMPoissonFit.ν` as a reported
estimate.

### C1b — Zero-arg convenience: `COMPoisson() = COMPoisson(1.0)`

Additive. `COMPoisson()` is `MethodError` today. The dummy `1.0` is the Poisson
anchor and the fitter's own `ν_init` default, so the public call reads
`fit_gllvm(Y; family = COMPoisson(), K = 2)` — matching `NB1()`, `ZIPoisson()`,
`HurdlePoisson()`, `DeltaGamma()`. The engine PR lands this next to the arm.

### C2 — One `_fit_gllvm(::COMPoisson)` arm → `fit_compoisson_gllvm`

There is exactly one no-X fitter and no grouped-dispersion sibling. No API-B
coerce. No `_fit_gllvm_grouped(::COMPoisson)` arm. `disp_group` stays the
generic "not supported" error.

No-X `@formula` opens by fall-through (`formula.jl:111`). Do **not** open
`src/formula.jl`.

### C3 — No bridge. No twin Δ.

Twin `.valid_family` has no COM-Poisson / CMP / Conway–Maxwell entry (ids 0–16
at the local `gllvmTMB` checkout). The gap sheet already marks `com_poisson` as
Julia-forward. A light RCall Δ would be invented. `src/bridge.jl` stays closed.

### C4 — No +X, no `row_eff`, no `disp_group`

Those routes do not work today and this admit does not open them. Same fence as
#237.

## Engine-admit change set (second PR, after this note)

Surgical, Hurdle-Poisson #237 shape, **after** C1–C4:

| File | Change |
|---|---|
| `src/families/com_poisson.jl` | `COMPoisson() = COMPoisson(1.0)`; docstring states `ν` is a tag payload |
| `src/families/fit_gllvm.jl` | `_fit_gllvm(::COMPoisson)` → `fit_compoisson_gllvm`; docstring + availability string |
| `test/test_com_poisson.jl` | no-X `fit_gllvm` + `@formula` smoke (loglik match vs named fitter; `COMPoisson()` ≡ `COMPoisson(9.0)` tag-inert) |
| `docs/src/response-families.md` | table row + unified-entry paragraph + example (COM-Poisson is currently **absent** from this page) |
| `docs/src/tutorial.md` | `fit_gllvm` route; no-X fence |
| `README.md` | surface mention |
| `docs/design/capability-status.md` | evidence pointer + OWED fence (status cell stays `implemented`) |
| `docs/dev-log/check-log.md` | entry |

`src/GLLVM.jl` does **not** need an export edit (`COMPoisson` is already
exported). `src/formula.jl`, `src/bridge.jl`, and `src/families/tweedie.jl` are
**not** opened.

## Deferred (not this Identity, not the engine PR)

- Hurdle-NB Identity + export + arm (same tag lock for `r`; more files).
- Ordered-beta Identity (`c0`, `c1`, `φ`).
- COM-Poisson +X / `disp_group` / `row_eff`.
- Any bridge string or twin Δ.
- Tweedie public-marker / power-pin work (#234 / #238).

## Rose fence

Status cell `com_poisson` stays `implemented` (engine + test already existed).
No R-parity, ADEMP, or coverage claimed. Twin has no COM-Poisson family — a
light Δ would be invented.

Rose verdict for **this** note: PASS — locks only; no engine code.
)
