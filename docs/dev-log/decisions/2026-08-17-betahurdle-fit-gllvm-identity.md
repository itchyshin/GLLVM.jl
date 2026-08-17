# Decision: Beta-hurdle no-X `fit_gllvm` identity (marker `φ` is a tag payload)

**Date:** 2026-08-17
**Status:** ACCEPTED (Arc 0 — locks the tag-vs-pin question and the export;
engine admit is a **second** PR, scoped below, **not** taken in this note)
**Lane:** `cursor/betahurdle-identity-20260817`
**Tip probed:** `e0eabb6f` (merge of #238, grouped Tweedie engine-health)
**Depends on:** NB1 + BetaBinom no-X Identity
`2026-08-16-nb1-betabinom-fit-gllvm-identity.md` (#226 / #230) for the tag-payload
`φ` convention; Hurdle-Poisson no-X admit (#237) as the **empty-marker sibling**;
Hurdle-NB Identity `2026-08-17-hurdlenb-fit-gllvm-identity.md` as the
**one-field two-part tag precedent**; Ordered-beta Identity
`2026-08-16-orderedbeta-fit-gllvm-identity.md` (#240) as the **export-cascade
precedent** (same Greek letter `φ`, different family). COM-Poisson engine #241
is in flight on `fit_gllvm.jl` — this note does not open that file.
**Do not** re-open #226 / #230 / #234 / #237 / #238 / #239 / #240. **Do not**
invent a twin `gllvmTMB` light Δ. **Do not** touch `src/bridge.jl`. **Do not**
open `src/families/tweedie.jl`. **Do not** compete on COM-Poisson engine (#241),
Hurdle-NB engine, or Ordered-beta engine.

## Why this family, not Hurdle-NB engine or Ordered-beta engine

#237 closed the last *empty-marker* `_fit_gllvm` admit. #239 / #240 locked
COM-Poisson (`ν`) and Ordered-beta (`c0`, `c1`, `φ`). Hurdle-NB Identity is
the sibling one-field two-part lock (`r`). This note takes the remaining
two-part precision tag: Beta-hurdle (`φ`).

Read off `origin/main` @ `e0eabb6f` plus twin `.valid_family`
(`gllvmTMB/R/enum.R`, ids 0–16) and the 2026-08-16 gap sheet. Tweedie is out of
lane (#234 Identity; #236 / #238 health; T2–T5 unpaid — no `fit_gllvm` surface
admit). COM-Poisson engine is #241 (do not open `fit_gllvm.jl` here).

| Candidate | Marker exported? | Fields | Twin | Why this slice / not |
|---|---|---|---|---|
| COM-Poisson (`COMPoisson`) | **yes** | one estimated `ν` | **not in twin** | **#239 Identity; #241 engine** — do not compete |
| Hurdle-NB (`HurdleNB`) | **no** | one estimated `r` | not in twin | **sibling Identity** — do not export from this lane |
| Ordered-beta (`OrderedBeta`) | **no** | three estimated fields | not in twin | **#240 Identity**; engine waits for #241 |
| **Beta-hurdle (`BetaHurdle`)** | **no** | one estimated `φ` | not in twin | — **this slice** |

Beta-hurdle is the remaining one-field two-part tag-payload Identity:
occurrence Bernoulli × positive Beta, named fitter already in `runtests.jl`,
twin has no beta-hurdle / ordered-beta family so there is no pin semantics to
invent (the Tweedie trap). The same Greek letter `φ` is a tag on `NB1` /
`Beta` / `BetaBinom` / Ordered-beta (#230 / #240) and a Tweedie
power-adjacent trap on `TweedieED` (#234).

## Problem

`BetaHurdle` has a complete, tested two-part Laplace engine
(`fit_beta_hurdle_gllvm`, `test/test_beta_hurdle.jl` already included from
`runtests.jl:109`) and an already-exported *fitter* / *result*
(`fit_beta_hurdle_gllvm`, `BetaHurdleFit` at `src/GLLVM.jl:203`), but the
**marker is unexported** and there is no `_fit_gllvm` arm. No-X `@formula`
falls through to `fit_gllvm` (`formula.jl:106–111`), so both public surfaces
error.

The marker carries `φ`. The named fitter **estimates** `φ` (packed as
`log φ`, method-of-moments start from positive-part logit residuals, fallback
`5.0` when `nres ≤ 1` at `beta_hurdle.jl:273`). There is **no** `φ_init`
keyword. Shipping an arm without locking the tag reading would make
`BetaHurdle(8.0)` look like "pin the Beta precision" when the fitter will
estimate `φ` anyway — or, worse, invent a `φ_init` the named fitter does not
expose.

The marker docstring already says it is a marker for the dedicated path and
must not be contradicted:

> Marker for the Beta-hurdle two-part family
> (`beta_hurdle.jl:32–36`)

### Live surface map (probed at `e0eabb6f`, not inferred)

| Surface | Beta-hurdle | `φ` estimand |
|---|---|---|
| Named fitter `fit_beta_hurdle_gllvm` | **shipped** | shared scalar `φ`, always estimated (MoM start; fallback `5.0`; **no** `φ_init`) |
| `fit_gllvm` bare marker | **ArgumentError** | — |
| `@formula` no-X (`q == 0`) | **ArgumentError** (falls through) | — |
| `@formula` + X | **absent** (no Beta-hurdle branch) | — |
| R bridge no-X / +X | **absent** (no `beta_hurdle` / `hurdle_beta` symbol in `bridge.jl`) | — |
| Marker exported? | **no** | — |
| Zero-arg constructor? | **no** (`BetaHurdle()` is `UndefVarError` after `using GLLVM`; `GLLVM.BetaHurdle()` is `MethodError`) | — |
| Twin `gllvmTMB` | **not in** `.valid_family` (ids 0–16) | no pin to invent |
| `disp_group` | **ArgumentError** (generic "not supported") | — |
| `row_eff` | **MethodError** (`_cov_default_link(::BetaHurdle)`) | — |

Verbatim probe (`julia --project=. --startup-file=no`, p=4, n=4, K=1) at
`e0eabb6f` (same session as the Hurdle-NB Identity probe):

```
--- marker export status (after using GLLVM) ---
HurdleNB             not exported
HurdlePoisson        EXPORTED
BetaHurdle           not exported
OrderedBeta          not exported
COMPoisson           EXPORTED
--- constructors ---
BetaHurdle()           MethodError: no method matching GLLVM.BetaHurdle()
BetaHurdle(8.0)        OK  fields=(:φ,) values=(8.0,)
HurdleNB(5.0)          OK  fields=(:r,) values=(5.0,)
--- fit_gllvm no-X ---
BetaHurdle(8.0)        ArgumentError: fit_gllvm: family BetaHurdle is not implemented yet …
HurdleNB(5.0)          ArgumentError: fit_gllvm: family HurdleNB is not implemented yet …
HurdlePoisson()        OK -> HurdlePoissonFit
--- @formula no-X (q = 0) ---
BetaHurdle(8.0)        ArgumentError: fit_gllvm: family BetaHurdle is not implemented yet …
--- named fitter ---
fit_beta_hurdle_gllvm  defined
kwargs: K, g_tol, iterations, newton_maxiter, newton_tol
--- disp_group / row_eff ---
disp_group=:species   ArgumentError: disp_group … not supported for family BetaHurdle
row_eff=:random       MethodError: no method matching _cov_default_link(::GLLVM.BetaHurdle)
```

The `BetaHurdle(8.0)` call errors **before** any likelihood evaluation — the
marker field is not read today because there is no arm. The named fitter never
takes a `BetaHurdle` instance: `φ` is packed as `log φ` from a data-dependent
MoM start (`beta_hurdle.jl:257–273`, `:288`), then re-estimated.

`fit_gllvm.jl:232` already names the gap in the fallback comment
("remaining hurdle / ordered-beta").

## Why this is surgical after the locks (unlike Tweedie #234)

| # | Tweedie #234 (STOP) | Beta-hurdle (this note) |
|---|---|---|
| 1 | Marker unexported; both fields mandatory | Marker unexported — **one** estimated field; export is C5, paid on the engine PR |
| 2 | Twin `tweedie(p = …)` **pins** the power | Twin has **no** beta-hurdle family — no pin to invent |
| 3 | Two fitters, `p_init` vs `power_init` disagree | One fitter, **no** `φ_init` keyword at all |
| 4 | Default start reports `converged = true` at a sentinel loglik | Shipped tests include a Λ=0 density anchor and a smoke fit (`test_beta_hurdle.jl`) |
| 5 | Power is neither tag nor structural in the house sense | Beta-hurdle `φ` is **estimated**, so the NB1 / Beta / Ordered-beta tag reading applies |

A sixth asymmetry *reduces* scope: **the bridge needs no admission**. `rg` of
`src/bridge.jl` has no `beta_hurdle` / `BetaHurdle` symbol. Do not open
`bridge.jl`. Do not reuse `"ordered"` (already ordinal, #240 C3).

Because of (1), the engine admit is **not** taken in this session. Identity
first; engine only after this note is on `main` and after #241 has cleared
`fit_gllvm.jl`. The engine is surgical **only if** it stays Hurdle-Poisson
#237 shape plus the C5 export — same cost as Hurdle-NB, cheaper than
Ordered-beta (one field, no include move: `beta_hurdle.jl` is already before
`fit_gllvm.jl` at `src/GLLVM.jl:60–62`).

## Decision

### C1 — Marker `φ` is a tag payload, ignored on every route; `φ` is always estimated

The marker's `φ` field is **never read** by `fit_gllvm` / `@formula`. It is not
forwarded, and it is **not** used as an init. `φ` is estimated on every public
route, always.

This is the shipped house convention for *estimated* marker fields, not a new
one:

- `_fit_gllvm(::NB1, …)` never exists; the grouped arm drops `φ` (#230 C1).
- `_fit_gllvm(::DeltaLogNormal, …)` / `::DeltaGamma` drop `σ` / `α` (#233).
- `_fit_gllvm(::NegativeBinomial, …)` / `::Beta` / `::GeneralizedPoisson1` bind
  `::T` and drop the field.
- Ordered-beta Identity (#240 C1) drops marker `φ` (and the cutpoints).
- `ZIPoisson` / `HurdlePoisson` are empty — the ZIP/hurdle pattern for a
  no-payload marker. Beta-hurdle is the same pattern **plus** an inert field.

**The Student-t contrast (same letter-class, opposite role).**
`StudentTFamily(ν)` forwards `ν` because it is **structural**: it defines the
likelihood and is held fixed (`fit_gllvm.jl:196–208`; #232). Beta-hurdle `φ`
is the Beta precision the named fitter already estimates on `log φ`
(`beta_hurdle.jl:288`, `:313`). Treating `BetaHurdle(φ)` like
`StudentTFamily(ν)` would *pin* a free parameter the engine does not pin.

**Rejected: marker `φ` → a new `φ_init`.** The named fitter has no `φ_init`
keyword. Inventing one so the marker can seed it would be a fitter API change
and a second source for one value. The usual start is data-dependent MoM;
a marker seed would make identical calls return numerically different fits
(#230 C1, verbatim). The engine PR must not add `φ_init`.

**Rejected: `φ` as structural / pin-capable (the Student-t / Tweedie-T2 shape).**
There is no twin pin. Inventing one would be a twin Δ. The named fitter has no
`φ_fixed` path. Pinning would also break `BetaHurdleFit.φ` as a reported
estimate.

### C1b — Zero-arg convenience: `BetaHurdle() = BetaHurdle(5.0)`

Additive, **owed on the engine PR**, not this note. `BetaHurdle()` is
unreachable today (unexported + no zero-arg method). The dummy `5.0` is the
only shipped constant in the fitter (MoM fallback when `nres ≤ 1` at
`beta_hurdle.jl:273`). It is **not** an init seed — C1 already forbids reading
the marker. The public call reads
`fit_gllvm(Y; family = BetaHurdle(), K = 2)` — matching `NB1()`,
`ZIPoisson()`, `HurdlePoisson()`, `DeltaGamma()`. The engine PR lands this
next to the export and the arm.

### C2 — One `_fit_gllvm(::BetaHurdle)` arm → `fit_beta_hurdle_gllvm`

There is exactly one no-X fitter and no grouped-dispersion sibling. No API-B
coerce. No `_fit_gllvm_grouped(::BetaHurdle)` arm. `disp_group` stays the
generic "not supported" error.

No-X `@formula` opens by fall-through (`formula.jl:111`). Do **not** open
`src/formula.jl`.

`beta_hurdle.jl` is already included **before** `fit_gllvm.jl`
(`src/GLLVM.jl:60–62`). The engine PR does **not** move an include.

`row_eff` today is a raw `MethodError`. The engine PR must **not** add a
row-effect route. Replacing that `MethodError` with a clear "not supported"
`ArgumentError` is allowed only if it is a one-line family-list edit with no
new kernel; otherwise leave it. This Identity does not require the cleanup.

### C3 — No bridge. No twin Δ.

Twin `.valid_family` has no ordered-beta / beta-hurdle / Kubinec entry (ids
0–16 at the local `gllvmTMB` checkout, `R/enum.R:5–23`). The gap sheet already
marks `ordered_beta / beta_hurdle` as Julia-forward. A light RCall Δ would be
invented. `src/bridge.jl` stays closed.

**Export / alias lock on the bridge (do not execute here):** `"ordered"`
already maps to ordinal (`bridge.jl:146`; #240 C3). An `"ordered_beta"` or
`"beta_hurdle"` key is not owed. Do not reuse `"ordered"` for this family.

### C4 — No +X, no `row_eff`, no `disp_group`

Those routes do not work today and this admit does not open them. Same fence as
#237.

### C5 — Export locks (engine PR executes; this note only locks)

Today (`src/GLLVM.jl:203`): `fit_beta_hurdle_gllvm`, `BetaHurdleFit`,
`beta_hurdle_marginal_loglik_laplace` are exported; **`BetaHurdle` is not**.

The engine PR **must** export `BetaHurdle`. Because that is a public-API
addition, AGENTS.md rule 3 requires the cascade **in the same PR**:
`fit_gllvm` docstring, availability string, `docs/src/response-families.md`
(the table row already names the *named* fitter only), `docs/src/tutorial.md`,
README family list, and tests. Re-run Aqua after the export.

This Identity PR does **not** export anything.

**Naming.** `BetaHurdle` does not collide with a `Distributions` type. No
second public name.

**Do not export** `HurdleNB` or `OrderedBeta` from this lane.

## Engine-admit change set (second PR, after this note)

Hurdle-Poisson #237 shape **plus** the C5 export cascade, **after** C1–C5,
and **after** #241 has cleared `fit_gllvm.jl`. Surgical only if it stays that
shape:

| File | Change |
|---|---|
| `src/GLLVM.jl` | export `BetaHurdle` |
| `src/families/beta_hurdle.jl` | `BetaHurdle() = BetaHurdle(5.0)`; docstring restates C1 |
| `src/families/fit_gllvm.jl` | `_fit_gllvm(::BetaHurdle)` → `fit_beta_hurdle_gllvm`; docstring + availability string |
| `test/test_beta_hurdle.jl` | no-X `fit_gllvm` + `@formula` smoke (loglik match vs named fitter; `BetaHurdle()` ≡ `BetaHurdle(80.0)` tag-inert) |
| `docs/src/response-families.md` | unified-entry paragraph + example (table row already exists for the named fitter) |
| `docs/src/tutorial.md` | `fit_gllvm` route; no-X fence |
| `README.md` | surface mention |
| `docs/design/capability-status.md` | evidence pointer + OWED fence (status cell stays `implemented`) |
| `docs/dev-log/check-log.md` | entry |

`src/formula.jl`, `src/bridge.jl`, and `src/families/tweedie.jl` are **not**
opened. `src/families/twopart.jl` (Hurdle-NB), `com_poisson.jl`, and
`ordered_beta.jl` are **not** opened. No include move.

## Deferred (not this Identity, not the engine PR)

- COM-Poisson engine (#241 owns `fit_gllvm.jl` until it merges).
- Hurdle-NB Identity + engine (sibling lane; `r` tag).
- Ordered-beta engine (#240 Identity; waits for #241; include move required —
  `ordered_beta.jl` is **after** `fit_gllvm.jl`).
- Beta-hurdle +X / `disp_group` / `row_eff`.
- Adding a `φ_init` keyword to `fit_beta_hurdle_gllvm`.
- Any bridge string or twin Δ, including `"ordered"` / `"beta_hurdle"`.
- Tweedie public-marker / power-pin work (#234 / #236 / #238; T2–T5 unpaid).

## Rose fence

Status cell `ordered_beta / beta_hurdle` stays `implemented` (engine + test
already existed). No R-parity, ADEMP, or coverage claimed. Twin has no
beta-hurdle family — a light Δ would be invented.

Rose verdict for **this** note: PASS — locks only; no engine code.
