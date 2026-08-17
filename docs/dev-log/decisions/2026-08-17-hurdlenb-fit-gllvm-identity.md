# Decision: Hurdle-NB no-X `fit_gllvm` identity (marker `r` is a tag payload)

**Date:** 2026-08-17
**Status:** ACCEPTED (Arc 0 — locks the tag-vs-pin question and the export;
engine admit is a **second** PR, scoped below, **not** taken in this note)
**Lane:** `cursor/hurdlenb-identity-20260817`
**Tip probed:** `e0eabb6f` (merge of #238, grouped Tweedie engine-health)
**Depends on:** NB1 + BetaBinom no-X Identity
`2026-08-16-nb1-betabinom-fit-gllvm-identity.md` (#226 / #230) for the tag-payload
convention; Hurdle-Poisson no-X admit (#237) as the **empty-marker sibling** and
engine-PR shape; COM-Poisson Identity
`2026-08-16-compoisson-fit-gllvm-identity.md` (#239) as the **one-field tag
precedent**; Ordered-beta Identity
`2026-08-16-orderedbeta-fit-gllvm-identity.md` (#240) as the **export-cascade
precedent**. COM-Poisson engine #241 is in flight on `fit_gllvm.jl` — this note
does not open that file.
**Do not** re-open #226 / #230 / #234 / #237 / #238 / #239 / #240. **Do not**
invent a twin `gllvmTMB` light Δ. **Do not** touch `src/bridge.jl`. **Do not**
open `src/families/tweedie.jl`. **Do not** compete on COM-Poisson engine (#241)
or Ordered-beta engine.

## Why this family, not Beta-hurdle or Ordered-beta engine

#237 closed the last *empty-marker* `_fit_gllvm` admit. #239 / #240 locked
COM-Poisson (`ν`) and Ordered-beta (`c0`, `c1`, `φ`). The remaining
marker-field families on the north-star list are Hurdle-NB (`r`) and
Beta-hurdle (`φ`). One Identity, cheapest remaining field-lock first.

Read off `origin/main` @ `e0eabb6f` plus twin `.valid_family`
(`gllvmTMB/R/enum.R`, ids 0–16) and the 2026-08-16 gap sheet. Tweedie is out of
lane (#234 Identity; #236 / #238 health; T2–T5 unpaid — no `fit_gllvm` surface
admit). COM-Poisson engine is #241 (do not open `fit_gllvm.jl` here).

| Candidate | Marker exported? | Fields | Twin | Why this slice / not |
|---|---|---|---|---|
| COM-Poisson (`COMPoisson`) | **yes** | one estimated `ν` | **not in twin** | **#239 Identity; #241 engine** — do not compete |
| Ordered-beta (`OrderedBeta`) | **no** | three estimated fields | not in twin | **#240 Identity**; engine waits for #241 |
| **Hurdle-NB (`HurdleNB`)** | **no** | one estimated `r` | not in twin | — **this slice** |
| Beta-hurdle (`BetaHurdle`) | **no** | one estimated `φ` | not in twin | same tag shape; sibling Identity, not this file |

Hurdle-NB is the remaining one-field tag-payload Identity with an unexported
marker: named fitter already in `runtests.jl`, twin has no hurdle family so
there is no pin semantics to invent (the Tweedie trap). Beta-hurdle is the
same *shape* (`φ` tag) and is a later Identity.

## Problem

`HurdleNB` has a complete, tested two-part Laplace engine
(`fit_hurdle_nb_gllvm`, `test/test_hurdle_nb.jl` already included from
`runtests.jl:107`) and an already-exported *fitter* / *result*
(`fit_hurdle_nb_gllvm`, `HurdleNBFit` at `src/GLLVM.jl:199`), but the
**marker is unexported** and there is no `_fit_gllvm` arm. No-X `@formula`
falls through to `fit_gllvm` (`formula.jl:106–111`), so both public surfaces
error.

The marker carries `r`. The named fitter **estimates** `r` (packed as
`log r`, hardcoded start `log(10.0)` at `twopart.jl:525`). There is **no**
`r_init` keyword. Shipping an arm without locking the tag reading would make
`HurdleNB(5.0)` look like "pin the NB2 dispersion" when the fitter will
estimate `r` anyway — or, worse, invent an `r_init` the named fitter does not
expose.

### Live surface map (probed at `e0eabb6f`, not inferred)

| Surface | Hurdle-NB | `r` estimand |
|---|---|---|
| Named fitter `fit_hurdle_nb_gllvm` | **shipped** | shared scalar `r`, always estimated (hardcoded `log(10.0)` start; **no** `r_init`) |
| `fit_gllvm` bare marker | **ArgumentError** | — |
| `@formula` no-X (`q == 0`) | **ArgumentError** (falls through) | — |
| `@formula` + X | **absent** (no Hurdle-NB branch) | — |
| R bridge no-X / +X | **absent** (no `hurdle` / `hurdle_nb` symbol in `bridge.jl`) | — |
| Marker exported? | **no** | — |
| Zero-arg constructor? | **no** (`HurdleNB()` is `UndefVarError` after `using GLLVM`; `GLLVM.HurdleNB()` is `MethodError`) | — |
| Twin `gllvmTMB` | **not in** `.valid_family` (ids 0–16) | no pin to invent |
| `disp_group` | **ArgumentError** (generic "not supported") | — |
| `row_eff` | **MethodError** (`_cov_default_link(::HurdleNB)`) | — |

Verbatim probe (`julia --project=. --startup-file=no`, p=4, n=4, K=1) at
`e0eabb6f`:

```
--- marker export status (after using GLLVM) ---
HurdleNB             not exported
HurdlePoisson        EXPORTED
BetaHurdle           not exported
OrderedBeta          not exported
COMPoisson           EXPORTED
--- constructors ---
HurdleNB()             UndefVarError: `HurdleNB` not defined
HurdleNB(5.0)          OK  fields=(:r,) values=(5.0,)
HurdleNB(10.0)         OK  fields=(:r,) values=(10.0,)
BetaHurdle()           MethodError: no method matching GLLVM.BetaHurdle()
BetaHurdle(8.0)        OK  fields=(:φ,) values=(8.0,)
--- fit_gllvm no-X ---
HurdleNB(5.0)          ArgumentError: fit_gllvm: family HurdleNB is not implemented yet …
HurdleNB(10.0)         ArgumentError: fit_gllvm: family HurdleNB is not implemented yet …
BetaHurdle(8.0)        ArgumentError: fit_gllvm: family BetaHurdle is not implemented yet …
HurdlePoisson()        OK -> HurdlePoissonFit
--- @formula no-X (q = 0) ---
HurdleNB(5.0)          ArgumentError: fit_gllvm: family HurdleNB is not implemented yet …
--- named fitter ---
fit_hurdle_nb_gllvm  defined
kwargs: K, offset, g_tol, iterations, newton_maxiter, newton_tol
--- disp_group / row_eff ---
disp_group=:species   ArgumentError: disp_group … not supported for family HurdleNB
row_eff=:random       MethodError: no method matching _cov_default_link(::GLLVM.HurdleNB)
```

The two `HurdleNB(5.0)` / `HurdleNB(10.0)` calls error **before** any
likelihood evaluation — the marker field is not read today because there is no
arm. The named fitter never takes a `HurdleNB` instance: `r` is packed as
`log r` from a hardcoded `10.0` (`twopart.jl:525`), then re-estimated.

`fit_gllvm.jl:232` already names the gap in the fallback comment
("remaining hurdle / ordered-beta").

## Why this is surgical after the locks (unlike Tweedie #234)

| # | Tweedie #234 (STOP) | Hurdle-NB (this note) |
|---|---|---|
| 1 | Marker unexported; both fields mandatory | Marker unexported — **one** estimated field; export is C5, paid on the engine PR |
| 2 | Twin `tweedie(p = …)` **pins** the power | Twin has **no** hurdle family — no pin to invent |
| 3 | Two fitters, `p_init` vs `power_init` disagree | One fitter, **no** `r_init` keyword at all |
| 4 | Default start reports `converged = true` at a sentinel loglik | Shipped tests include the `r → ∞ ⇒` Hurdle-Poisson anchor (`test_hurdle_nb.jl`) and a smoke fit |
| 5 | Power is neither tag nor structural in the house sense | Hurdle-NB `r` is **estimated**, so the NB1 / ZIP / COM-Poisson tag reading applies |

A sixth asymmetry *reduces* scope: **the bridge needs no admission**. `rg` of
`src/bridge.jl` has no `hurdle` / `HurdleNB` symbol. Do not open `bridge.jl`.

Because of (1), the engine admit is **not** taken in this session. Identity
first; engine only after this note is on `main` and after #241 has cleared
`fit_gllvm.jl`.

## Decision

### C1 — Marker `r` is a tag payload, ignored on every route; `r` is always estimated

The marker's `r` field is **never read** by `fit_gllvm` / `@formula`. It is not
forwarded, and it is **not** used as an init. `r` is estimated on every public
route, always.

This is the shipped house convention for *estimated* marker fields, not a new
one:

- `_fit_gllvm(::NB1, …)` never exists; the grouped arm drops `φ` (#230 C1).
- `_fit_gllvm(::DeltaLogNormal, …)` / `::DeltaGamma` drop `σ` / `α` (#233).
- `_fit_gllvm(::NegativeBinomial, …)` / `::Beta` / `::GeneralizedPoisson1` bind
  `::T` and drop the field.
- `_fit_gllvm(::COMPoisson, …)` (#241, in flight) drops `ν`.
- `ZIPoisson` / `HurdlePoisson` are empty — the ZIP/hurdle pattern for a
  no-payload marker. Hurdle-NB is the same pattern **plus** an inert field.

**Rejected: marker `r` → a new `r_init`.** The named fitter has no `r_init`
keyword. Inventing one so the marker can seed it would be a fitter API change
and a second source for one value. Identical calls would return numerically
different fits (#230 C1, verbatim). The engine PR must not add `r_init`.

**Rejected: `r` as structural / pin-capable (the Student-t / Tweedie-T2 shape).**
There is no twin pin. Inventing one would be a twin Δ. The named fitter has no
`r_fixed` path. Pinning would also break `HurdleNBFit.r` as a reported
estimate.

### C1b — Zero-arg convenience: `HurdleNB() = HurdleNB(10.0)`

Additive, **owed on the engine PR**, not this note. `HurdleNB()` is
unreachable today (unexported + no zero-arg method). The dummy `10.0` matches
the fitter's own hardcoded start (`log(10.0)` at `twopart.jl:525`), so the
public call reads `fit_gllvm(Y; family = HurdleNB(), K = 2)` — matching
`NB1()`, `ZIPoisson()`, `HurdlePoisson()`, `DeltaGamma()`. The engine PR
lands this next to the export and the arm.

### C2 — One `_fit_gllvm(::HurdleNB)` arm → `fit_hurdle_nb_gllvm`

There is exactly one no-X fitter and no grouped-dispersion sibling. No API-B
coerce. No `_fit_gllvm_grouped(::HurdleNB)` arm. `disp_group` stays the
generic "not supported" error.

No-X `@formula` opens by fall-through (`formula.jl:111`). Do **not** open
`src/formula.jl`.

`twopart.jl` is already included **before** `fit_gllvm.jl`
(`src/GLLVM.jl:59–62`). The engine PR does **not** move an include.

`row_eff` today is a raw `MethodError`. The engine PR must **not** add a
row-effect route. Replacing that `MethodError` with a clear "not supported"
`ArgumentError` is allowed only if it is a one-line family-list edit with no
new kernel; otherwise leave it. This Identity does not require the cleanup.

### C3 — No bridge. No twin Δ.

Twin `.valid_family` has no hurdle / hurdle-NB / hurdle-Poisson entry (ids
0–16 at the local `gllvmTMB` checkout, `R/enum.R:5–23`). The gap sheet already
marks `hurdle_poisson / hurdle_nbinom2` as Julia-forward. A light RCall Δ
would be invented. `src/bridge.jl` stays closed.

### C4 — No +X, no `row_eff`, no `disp_group`

Those routes do not work today and this admit does not open them. Same fence as
#237.

### C5 — Export locks (engine PR executes; this note only locks)

Today (`src/GLLVM.jl:199`): `fit_hurdle_nb_gllvm`, `HurdleNBFit`,
`hurdle_nb_marginal_loglik_laplace` are exported; **`HurdleNB` is not**.

The engine PR **must** export `HurdleNB`. Because that is a public-API
addition, AGENTS.md rule 3 requires the cascade **in the same PR**:
`fit_gllvm` docstring, availability string, `docs/src/response-families.md`
(the table row already names the *named* fitter only), `docs/src/tutorial.md`,
README family list, and tests. Re-run Aqua after the export.

This Identity PR does **not** export anything.

**Naming.** `HurdleNB` does not collide with a `Distributions` type. No second
public name.

**Do not export** `BetaHurdle` or `OrderedBeta` from this lane.

## Engine-admit change set (second PR, after this note)

Hurdle-Poisson #237 shape **plus** the C5 export cascade, **after** C1–C5,
and **after** #241 has cleared `fit_gllvm.jl`:

| File | Change |
|---|---|
| `src/GLLVM.jl` | export `HurdleNB` |
| `src/families/twopart.jl` | `HurdleNB() = HurdleNB(10.0)`; docstring restates C1 |
| `src/families/fit_gllvm.jl` | `_fit_gllvm(::HurdleNB)` → `fit_hurdle_nb_gllvm`; docstring + availability string |
| `test/test_hurdle_nb.jl` | no-X `fit_gllvm` + `@formula` smoke (loglik match vs named fitter; `HurdleNB()` ≡ `HurdleNB(99.0)` tag-inert) |
| `docs/src/response-families.md` | unified-entry paragraph + example (table row already exists for the named fitter) |
| `docs/src/tutorial.md` | `fit_gllvm` route; no-X fence |
| `README.md` | surface mention |
| `docs/design/capability-status.md` | evidence pointer + OWED fence (status cell stays `implemented`) |
| `docs/dev-log/check-log.md` | entry |

`src/formula.jl`, `src/bridge.jl`, and `src/families/tweedie.jl` are **not**
opened. `src/families/com_poisson.jl`, `ordered_beta.jl`, and `beta_hurdle.jl`
are **not** opened. No include move.

## Deferred (not this Identity, not the engine PR)

- COM-Poisson engine (#241 owns `fit_gllvm.jl` until it merges).
- Ordered-beta engine (#240 Identity; waits for #241).
- Beta-hurdle Identity (`φ` tag; two-part) — sibling note, not this file.
- Hurdle-NB +X / `disp_group` / `row_eff`.
- Adding an `r_init` keyword to `fit_hurdle_nb_gllvm`.
- Any bridge string or twin Δ.
- Tweedie public-marker / power-pin work (#234 / #236 / #238; T2–T5 unpaid).

## Rose fence

Status cell `hurdle_poisson / hurdle_nbinom2` stays `implemented` (engine +
test already existed). No R-parity, ADEMP, or coverage claimed. Twin has no
hurdle family — a light Δ would be invented.

Rose verdict for **this** note: PASS — locks only; no engine code.
