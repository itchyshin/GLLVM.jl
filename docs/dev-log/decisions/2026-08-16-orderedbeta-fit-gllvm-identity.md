# Decision: Ordered-beta no-X `fit_gllvm` identity (marker `φ` + cutpoints are tag payloads)

**Date:** 2026-08-16
**Status:** ACCEPTED (Arc 0 — locks tag-vs-pin, cutpoint packing, and export;
engine admit is a **second** PR, scoped below, **not** taken in this note)
**Lane:** `cursor/orderedbeta-identity-20260816`
**Tip probed:** `d70a6a25` (merge of #237, Hurdle-Poisson no-X surface admit)
**Depends on:** NB1 + BetaBinom no-X Identity
`2026-08-16-nb1-betabinom-fit-gllvm-identity.md` (#226 / #230) for the tag-payload
`φ` convention; Student-t no-X admit (#232) as the **contrast** (structural pin);
Ordinal+X cutpoint Identity `2026-08-03-ordinal-x-cutpoint-identity.md` (#179) as
the **rejected packing import**; Hurdle-Poisson no-X admit (#237) as the **shape
precedent** for a later engine PR; COM-Poisson Identity
`2026-08-16-compoisson-fit-gllvm-identity.md` (#239) as the **sibling lane** that
already deferred this family.
**Do not** re-open #179 / #226 / #230 / #232 / #234 / #237 / #239. **Do not**
invent a twin `gllvmTMB` light Δ. **Do not** touch `src/bridge.jl`. **Do not**
open `src/families/tweedie.jl` (Tweedie grouped-health lane #238). **Do not**
compete on Hurdle-NB or COM-Poisson — those lanes own `r` / `ν`.

## Why this family, not Hurdle-NB or COM-Poisson

#237 closed the last *empty-marker* `_fit_gllvm` admit. The remaining
marker-field families on the north-star list are Hurdle-NB (`r`), COM-Poisson
(`ν`), and Ordered-beta (`φ` plus cutpoints). #239 already claimed COM-Poisson
as the cheapest remaining admit. This lane takes the family #239 deferred.

Read off `origin/main` @ `d70a6a25` plus twin `.valid_family`
(`gllvmTMB/R/enum.R`, ids 0–16) and the 2026-08-16 gap sheet. Tweedie is out of
lane (#234 Identity; #238 grouped-health).

| Candidate | Marker exported? | Fields | Twin | Why this slice / not |
|---|---|---|---|---|
| COM-Poisson (`COMPoisson`) | **yes** | one estimated `ν` | **not in twin** | **#239 owns this** — do not compete |
| Hurdle-NB (`HurdleNB`) | **no** | one estimated `r` | not in twin | export cascade on top of the same tag lock; another lane may own it |
| **Ordered-beta (`OrderedBeta`)** | **no** | three estimated fields (`c0`, `c1`, `φ`) | not in twin | — **this slice** |

Ordered-beta is the remaining three-field Identity: unexported marker, shared
scalar cutpoints packed as `(c0, Δ = log(c1 − c0), log φ)`, named fitter already
in `runtests.jl`, twin has no ordered-beta family so there is no pin semantics
to invent (the Tweedie / Ordinal trap).

## Problem

`OrderedBeta` has a complete, tested Laplace engine (`fit_ordered_beta_gllvm`,
`test/test_ordered_beta.jl` already included from `runtests.jl:137`) and an
already-exported *fitter* / *result* (`fit_ordered_beta_gllvm`, `OrderedBetaFit`
at `src/GLLVM.jl:220`), but the **marker is unexported** and there is no
`_fit_gllvm` arm. No-X `@formula` falls through to `fit_gllvm`
(`formula.jl:106–111`), so both public surfaces error.

The marker carries three fields. The named fitter **estimates all three**. The
same Greek letter `φ` is a tag payload on `NB1` / `Beta` / `BetaBinom` (#230 C1)
and a Tweedie *power-adjacent* trap on `TweedieED` (#234). The same word
"cutpoint" is a **twin pin** on Ordinal (`τ₁ = 0`, K−2 free log-spacings; #179).
Shipping an arm without locking those contrasts would make
`OrderedBeta(-1, 1, 8)` look like "pin the cuts and the precision" when the
fitter will estimate them anyway — or, worse, import Ordinal's `τ₁ = 0` pin
onto a family the twin does not have.

The marker docstring already says the right thing and must not be contradicted:

> Used only as a tag for the dedicated ordered-beta Laplace path.
> (`ordered_beta.jl:29–30`)

### Live surface map (probed at `d70a6a25`, not inferred)

| Surface | Ordered-beta | `c0`, `c1`, `φ` estimand |
|---|---|---|
| Named fitter `fit_ordered_beta_gllvm` | **shipped** | shared scalar `c0 < c1` and shared scalar `φ`, always estimated (`c0_init` / `c1_init` / `φ_init` seed) |
| `fit_gllvm` bare marker | **ArgumentError** | — |
| `@formula` no-X (`q == 0`) | **ArgumentError** (falls through) | — |
| `@formula` + X | **absent** (no Ordered-beta branch) | — |
| R bridge no-X / +X | **absent** (no `ordered_beta` symbol; `"ordered"` already aliases **ordinal**) | — |
| Marker exported? | **no** | — |
| Zero-arg constructor? | **no** (`OrderedBeta()` is `UndefVarError` after `using GLLVM`; `GLLVM.OrderedBeta()` is `MethodError`) | — |
| Twin `gllvmTMB` | **not in** `.valid_family` (ids 0–16) | no pin to invent |
| `disp_group` | **ArgumentError** (generic "not supported") | — |
| `row_eff` | **MethodError** (`_cov_default_link(::OrderedBeta)`) | — |

Verbatim probe (`julia --project=. …` at `d70a6a25`, p=4, n=8, K=1):

```
--- marker export status (after `using GLLVM`) ---
OrderedBeta         not exported
COMPoisson          EXPORTED
HurdleNB            not exported
HurdlePoisson       EXPORTED
BetaHurdle          not exported
ZIPoisson           EXPORTED
NB1                 EXPORTED
StudentTFamily      EXPORTED
--- constructors ---
OrderedBeta()         UndefVarError: `OrderedBeta` not defined
OrderedBeta(-1,1,8)   OK  fields=(:c0, :c1, :φ) values=(-1.0, 1.0, 8.0)
OrderedBeta(0,2,3)    OK  fields=(:c0, :c1, :φ) values=(0.0, 2.0, 3.0)
COMPoisson()          MethodError
COMPoisson(1.0)       OK  fields=(:ν,)
HurdleNB()            MethodError
HurdleNB(5.0)         OK  fields=(:r,)
BetaHurdle()          MethodError
BetaHurdle(8.0)       OK  fields=(:φ,)
HurdlePoisson()       OK  fields=()
--- fit_gllvm no-X ---
OrderedBeta(-1,1,8)   ArgumentError: fit_gllvm: family OrderedBeta is not implemented yet …
OrderedBeta(0,2,3)    ArgumentError: fit_gllvm: family OrderedBeta is not implemented yet …
COMPoisson(1.0)       ArgumentError: fit_gllvm: family COMPoisson is not implemented yet …
HurdleNB(5.0)         ArgumentError: fit_gllvm: family HurdleNB is not implemented yet …
HurdlePoisson()       OK -> HurdlePoissonFit
--- @formula no-X (q = 0) ---
OrderedBeta(-1,1,8)   ArgumentError: fit_gllvm: family OrderedBeta is not implemented yet …
HurdleNB(5.0)         ArgumentError: fit_gllvm: family HurdleNB is not implemented yet …
--- named fitter ---
fit_ordered_beta_gllvm  defined
kwargs: K, c0_init, c1_init, mask, β_init, Λ_init, φ_init, g_tol, iterations, …
--- disp_group / row_eff ---
disp_group=:species   ArgumentError: disp_group … not supported for family OrderedBeta
row_eff=:random       MethodError: no method matching _cov_default_link(::GLLVM.OrderedBeta)
```

The two `OrderedBeta(-1,1,8)` / `OrderedBeta(0,2,3)` calls error **before** any
likelihood evaluation — the marker fields are not read today because there is no
arm. The named fitter never takes an `OrderedBeta` instance: `c0`, `c1`, `φ`
enter as the `c0_init` / `c1_init` / `φ_init` keywords (`ordered_beta.jl:260–264`),
then are re-estimated.

`fit_gllvm.jl:232` already names the gap in the fallback comment
("remaining hurdle / ordered-beta").

## Cutpoint packing (lock; do not import Ordinal)

The named fitter packs one **shared** pair of cutpoints plus precision
(`ordered_beta.jl:191–195`, `:294–300`):

```
θ = [β(p); pack_lambda(Λ)(rr); c0; Δ; log φ]
c1 = c0 + exp(Δ)          # order constraint
φ  = exp(log φ)           # positivity
```

Init (`ordered_beta.jl:290–292`): `c0_init = -1.0`, `c1_init = 1.0`,
`φ_init === nothing → log(10.0)`, `Δ0 = log(max(c1_init − c0_init, 1e-3))`.
There is no inner constructor on `OrderedBeta`, so `c0 < c1` is **not**
validated on the marker — another reason the marker must not be forwarded as
a pin or as an init.

This is **not** the Ordinal twin packing (#179):

| | Ordinal (twin fid 14) | Ordered-beta (this family) |
|---|---|---|
| Twin family? | **yes** (`ordinal_probit`) | **no** |
| Cutpoint scope | **per-trait** public default | **shared** scalars `c0`, `c1` |
| Pin | `τ₁ = 0`; K−2 free log-spacings | **none** — `c0` is free |
| Reconstruction | `cuts(0)=0` then `+= exp(δ)` | `c1 = c0 + exp(Δ)` |
| Grouped sibling? | per-trait vs shared comparator | **no** grouped-cutpoint fitter |

**Rejected: import `τ₁ = 0` onto Ordered-beta.** That pin exists because the
twin's ordinal_probit likelihood is invariant to a location shift that β
already absorbs. Ordered-beta has no twin family. Inventing the pin would be
a twin Δ. The shipped fitter estimates `c0` freely; pinning it would break
`OrderedBetaFit.c0` as a reported estimate and change the likelihood the
tests already lock (`test_ordered_beta.jl`).

**Rejected: per-trait cutpoints as the `fit_gllvm` default.** There is no
per-trait Ordered-beta fitter. API-B coerce-to-`:species` is the NB1/Beta
pattern (#230 C2) and does not apply — `disp_group` already errors, and there
is nothing to coerce to.

## Why this is *not* surgical after the locks (unlike COM-Poisson #239 / Hurdle-Poisson #237)

| # | Hurdle-Poisson #237 / COM-Poisson #239 | Ordered-beta (this note) |
|---|---|---|
| 1 | COM-Poisson marker **already exported**; Hurdle-Poisson paid one export | Marker **unexported** — public-API addition ⇒ AGENTS.md rule 3 cascade in the same engine PR |
| 2 | One estimated field (`ν`) or empty marker | **Three** estimated fields; tag-inert tests must cover `c0`, `c1`, **and** `φ` jointly |
| 3 | Twin has no CMP / hurdle family — no pin to invent | Twin has no ordered-beta family — no pin to invent (**same**, good) |
| 4 | One fitter, one keyword | One fitter, **three** init keywords (`c0_init`, `c1_init`, `φ_init`) plus an internal `c1 → Δ` conversion |
| 5 | Student-t `ν` is the rejected structural reading | Student-t `ν` **and** Ordinal `τ₁ = 0` are both rejected readings |

A sixth asymmetry *reduces* scope: **the bridge needs no admission**.
`rg` of `src/bridge.jl` has no `ordered_beta` / `OrderedBeta` symbol. The
string `"ordered"` already aliases **ordinal** (`bridge.jl:146`). Do not open
`bridge.jl`. Do not add an `"ordered"` or `"ordered_beta"` bridge key.

Because of (1) and (2), the engine admit is **not** taken in this session.
Identity first; engine only after this note is on `main` and after any
COM-Poisson engine PR has cleared the shared `fit_gllvm.jl` / docs cascade
(#239 C2).

## Decision

### C1 — Marker `φ` is a tag payload, ignored on every route; `φ` is always estimated

The marker's `φ` field is **never read** by `fit_gllvm` / `@formula`. It is not
forwarded, and it is **not** used as `φ_init`. `φ` is estimated on every public
route, always.

This is the shipped house convention for *estimated* marker fields, not a new
one:

- `_fit_gllvm(::NB1, …)` never exists; the grouped arm drops `φ` (#230 C1).
- `_fit_gllvm(::DeltaLogNormal, …)` / `::DeltaGamma` drop `σ` / `α` (#233).
- `_fit_gllvm(::NegativeBinomial, …)` / `::Beta` / `::GeneralizedPoisson1` bind
  `::T` and drop the field.
- `ZIPoisson` / `HurdlePoisson` are empty — the ZIP/hurdle pattern for a
  no-payload marker. Ordered-beta is the same pattern **plus** three inert
  fields.

**The Student-t contrast (same letter-class, opposite role).**
`StudentTFamily(ν)` forwards `ν` because it is **structural**: it defines the
likelihood and is held fixed (`fit_gllvm.jl:196–208`; #232). Ordered-beta `φ`
is the Beta precision the named fitter already estimates on `log φ`
(`ordered_beta.jl:290`, `:300`). Treating `OrderedBeta(c0, c1, φ)` like
`StudentTFamily(ν)` would *pin* a free parameter the engine does not pin.

**Rejected: marker `φ` → `φ_init`.** No shipped marker seeds an init. The
fitter already exposes `φ_init` (default `10.0` via `log(10)`). A marker seed
would create a second source for one value, require a precedence rule, and
make a field documented as inert path-dependent — identical calls returning
numerically different fits (#230 C1, verbatim).

**Rejected: `φ` as structural / pin-capable (the Student-t / Tweedie-T2 shape).**
There is no twin pin. Inventing one would be a twin Δ. The named fitter has no
`φ_fixed` path. Pinning would also break `OrderedBetaFit.φ` as a reported
estimate.

### C1-cuts — Marker `c0`, `c1` are tag payloads, not pins, not inits

Same rule as C1, applied to the cutpoints. Both are estimated. The marker
values are never read, never forwarded, never used as `c0_init` / `c1_init`.
The engine PR's tag-inert test is
`OrderedBeta(-1, 1, 8)` ≡ `OrderedBeta(0, 2, 3)` on the same `Y` (loglik and
`(c0, c1, φ)` agree to the named-fitter tolerance).

Packing stays inside `fit_ordered_beta_gllvm`: free `c0`, monotone
`Δ = log(c1 − c0)`, `log φ`. The dispatcher does not convert `c1` to `Δ`.

**Rejected: marker cutpoints → `c0_init` / `c1_init`.** Same second-source
failure as C1, plus a `c1 → Δ` conversion the dispatcher must not own, plus
the marker does not even validate `c0 < c1`.

**Rejected: pin `c0` (the Ordinal `τ₁ = 0` import).** See packing table above.
No twin ordered-beta family; a pin would be invented.

### C1b — Zero-arg convenience: `OrderedBeta() = OrderedBeta(-1.0, 1.0, 10.0)`

Additive, **owed on the engine PR**, not this note. `OrderedBeta()` is
unreachable today (unexported + no zero-arg method). The dummy
`(-1.0, 1.0, 10.0)` matches the fitter's own `c0_init` / `c1_init` / `φ_init`
defaults, so the public call reads
`fit_gllvm(Y; family = OrderedBeta(), K = 2)` — matching `NB1()`,
`ZIPoisson()`, `HurdlePoisson()`, `DeltaGamma()`. The engine PR lands this
next to the export and the arm.

### C2 — One `_fit_gllvm(::OrderedBeta)` arm → `fit_ordered_beta_gllvm`

There is exactly one no-X fitter and no grouped-dispersion / per-trait-cutpoint
sibling. No API-B coerce. No `_fit_gllvm_grouped(::OrderedBeta)` arm.
`disp_group` stays the generic "not supported" error.

No-X `@formula` opens by fall-through (`formula.jl:111`). Do **not** open
`src/formula.jl`.

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
already maps to ordinal (`bridge.jl:146`). An `"ordered_beta"` key is not
owed. Do not reuse `"ordered"` for this family.

### C4 — No +X, no `row_eff`, no `disp_group`

Those routes do not work today and this admit does not open them. Same fence as
#237.

### C5 — Export locks (engine PR executes; this note only locks)

Today (`src/GLLVM.jl:220`): `fit_ordered_beta_gllvm`, `OrderedBetaFit`,
`ordered_beta_marginal_loglik_laplace` are exported; **`OrderedBeta` is not**.

The engine PR **must** export `OrderedBeta`. Because that is a public-API
addition, AGENTS.md rule 3 requires the cascade **in the same PR**:
`fit_gllvm` docstring, availability string, `docs/src/response-families.md`
(the table row already names the *named* fitter only), `docs/src/tutorial.md`,
README family list, and tests. Re-run Aqua after the export.

This Identity PR does **not** export anything.

**Naming.** `OrderedBeta` does not collide with a `Distributions` type (unlike
`BetaBinom` vs `BetaBinomial`). No second public name.

**Do not export** `BetaHurdle` or `HurdleNB` from this lane.

## Engine-admit change set (second PR, after this note)

Hurdle-Poisson #237 shape **plus** the C5 export cascade, **after** C1–C5,
and **after** #239's engine PR has cleared `fit_gllvm.jl` if that PR is in
flight:

| File | Change |
|---|---|
| `src/GLLVM.jl` | export `OrderedBeta` |
| `src/families/ordered_beta.jl` | `OrderedBeta() = OrderedBeta(-1.0, 1.0, 10.0)`; docstring restates C1 / C1-cuts |
| `src/families/fit_gllvm.jl` | `_fit_gllvm(::OrderedBeta)` → `fit_ordered_beta_gllvm`; docstring + availability string |
| `test/test_ordered_beta.jl` | no-X `fit_gllvm` + `@formula` smoke (loglik match vs named fitter; `OrderedBeta()` ≡ `OrderedBeta(0, 2, 3)` tag-inert on `c0`, `c1`, **and** `φ`) |
| `docs/src/response-families.md` | unified-entry paragraph + example (table row already exists for the named fitter) |
| `docs/src/tutorial.md` | `fit_gllvm` route; no-X fence |
| `README.md` | surface mention |
| `docs/design/capability-status.md` | evidence pointer + OWED fence (status cell stays `implemented`) |
| `docs/dev-log/check-log.md` | entry |

`src/formula.jl`, `src/bridge.jl`, and `src/families/tweedie.jl` are **not**
opened. `src/families/com_poisson.jl` and Hurdle-NB files are **not** opened.

## Deferred (not this Identity, not the engine PR)

- COM-Poisson Identity + engine (#239 owns the Identity).
- Hurdle-NB Identity + export + arm (same tag lock for `r`; more files).
- Beta-hurdle Identity (`φ` tag; two-part).
- Ordered-beta +X / `disp_group` / `row_eff`.
- Any bridge string or twin Δ, including `"ordered"` / `"ordered_beta"`.
- Importing Ordinal's `τ₁ = 0` pin.
- Tweedie public-marker / power-pin work (#234 / #238).

## Rose fence

Status cell `ordered_beta / beta_hurdle` stays `implemented` (engine + test
already existed). No R-parity, ADEMP, or coverage claimed. Twin has no
ordered-beta family — a light Δ would be invented.

Rose verdict for **this** note: PASS — locks only; no engine code.
)