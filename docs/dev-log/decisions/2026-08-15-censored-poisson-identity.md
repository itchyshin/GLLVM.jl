# Decision: censored_poisson Identity (Julia-forward engine; twin R-only)

**Date:** 2026-08-15  
**Status:** ACCEPTED (Wave1 / Arc 0 docs-only → engine on owned files) — **amended 2026-08-15 by ceiling review (APPROVED; see Amendment)**  
**Lane:** `cursor/censored-poisson-identity-20260815`  
**Programme:** `lanes/gllvmjl-parallel-family-catchup-20260815/LOOP/`  
**Depends on:** G0 parallel catch-up; truncated_poisson Identity pattern (support/link discipline).  
**Do not** invent ZIP/ZINB twin Δ; **do not** claim twin engine parity; **do not** ADEMP.

## Problem

Ledger row `censored_poisson` is `missing`. Twin gllvmTMB exports an R
constructor `censored_poisson(link = "log")` in `R/families.R`, but a repo
search finds **no** `family_id` / cpp dens arm for censored Poisson in
`src/gllvmTMB.cpp` and **no** `family_to_id` admission in `fit-multi.R`'s
supported list (abort message lists truncated_poisson / truncated_nbinom2 /
delta_* etc., not censored_poisson).

Without an Identity lock, a Julia engine risks (a) inventing a twin light Δ
against a non-fitting surface, (b) conflating **zero-truncated** Poisson
(fid 10, already implemented) with **right/left/interval censoring**, or
(c) advertising bridge parity before the estimand is locked.

## Twin cites (load-bearing — asymmetric)

Verified against twin `gllvmTMB` @ `114a227e` during the 2026-08-15 ceiling
review (see Amendment below).

| Surface | Evidence |
|---|---|
| Constructor | `gllvmTMB/R/families.R:467` `censored_poisson(link = "log")` — **log link only**; returns a `family` object with name `"censored_poisson"` |
| Enum | `R/enum.R` carries `truncated_poisson = 10L`, `truncated_nbinom2 = 11L` and **no** censored id |
| cpp dens | **No** censored arm in `src/gllvmTMB.cpp` (zero matches for `censor`) |
| `family_to_id` | **Not** in the `fit-multi.R:436-439` "Unsupported family" supported list (live fit path does not admit it) |
| Debt register | `docs/design/35-validation-debt-register.md:150` FAM-16 = **`blocked`**, constructor-only, must fail loud |
| Fail-loud test | `tests/testthat/test-enum-runtime-ids.R:28-58` asserts `censored_poisson` is absent from the runtime enum **and** errors before admission |
| **Documented estimand** | `docs/design/02-family-registry.md:183` support `{0,1,2,…}` "with interval censoring"; `docs/design/03-likelihoods.md:519-522` "supports right-/left-/interval-censoring"; `docs/design/105-va-family-densities.md` §7 gives per-row-type densities, EVA terms, and underflow hazards |
| Related twin | `truncated_poisson` fid 10 is a **different** estimand (zero-truncation, y≥1) |

**Fence:** Twin admits a **constructor name plus a written design spec**, but
has **no compiled dens and no runtime admission** — FAM-16 is `blocked` and the
twin's own test suite requires `gllvmTMB()` to fail loud. There is therefore
**no live twin fit to Δ against**. This Identity is **Julia-forward** for the
engine; light RCall Δ is **forbidden** until twin lands a real dens + Identity
re-check.

The twin spec is **interval** censoring (right, left, and interval rows). This
Identity ships the **right-censored subset** of that documented spec — a scope
reduction, *not* a divergent estimand (see Amendment §2).

## Julia estimand (this Identity) — right-censored counts at known limits

Lock a **right-censored Poisson** observation model suitable for count data
with known upper reporting limits (common ecology / lab “≥ C” coding), distinct
from zero-truncation:

| Item | Lock |
|---|---|
| Response encoding | Integer counts `y ≥ 0`; optional per-observation censor flag / limit `C` (engine API may pass a parallel matrix/mask — exact signature is engine detail, estimand is below) |
| Uncensored obs | Contribute `log Poisson(y; μ)` with `μ = exp(η)` |
| Right-censored obs at limit `C` | Contribute `log P(Y ≥ C)` for `C ≥ 1`. **Estimand:** `log(1 − F_{Pois(μ)}(C−1))`. **Evaluate** via the Poisson–gamma dual in log space, `logcdf(Gamma(C, 1), μ)` — the naive survival form underflows to `-Inf` for `μ ≪ C` and must not be the evaluated path (Amendment §3). `C = 0` carries **no information** (`P(Y ≥ 0) = 1`, contribution exactly `0`); engine **fails loud** rather than accepting it |
| Linear predictor | `η = β + Λz` (+ optional offset); **log link only** |
| Mean parameter | Untruncated `μ = exp(η)` |
| Dispersion | none |
| Relation to truncated_poisson | **Different family** — truncation renormalises support `{1,2,…}`; censoring keeps support `{0,1,…}` and adds survival contributions |

### Explicit non-claims

- Not interval-censored / left-censored in v1 — **deferred, not rejected**: both
  are in the twin's documented spec, so the response encoding must stay
  forward-compatible with per-row `(L, U)` bounds (Amendment §4). Adding those
  row types needs an Identity extension, not a new family.
- Not twin-parity / light RCall until twin dens exists.
- Not a rename of truncated_poisson.
- Public claim is **"Julia-forward; twin constructor-only (FAM-16 blocked)"** —
  never "matches gllvmTMB".

## Rejected alternatives

| Option | Why rejected |
|---|---|
| Skip Identity; ship engine as “like truncated” | Different estimand; Rose overclaim |
| Invent twin Δ vs constructor-only surface | No live dens — false parity |
| Treat as truncated_poisson alias | Breaks truncation Identity / twin fid 10 |
| Left/interval censoring as silent default | Underspecified without twin dens |

## Out of scope

- Twin engine surgery in gllvmTMB
- ZIP/ZINB/ZIB
- ADEMP / coverage
- Shared choke points — merge-conductor only
- truncated_nbinom2 (owned elsewhere)
- lognormal / ZIB+X (sibling lanes)

## Ownership (engine Wave2)

- **OWN:** `src/families/censored_poisson.jl` (new), `test/test_censored_poisson.jl` (new), this decision
- **NOT:** truncated_poisson.jl edits beyond necessary cross-refs; shared choke points until admit

## STOP / CONTINUE

Identity ACCEPTED → **CONTINUE** to Julia-forward censored_poisson engine on owned
files. Public claim must say **Julia-forward / twin constructor-only** until twin dens
lands. Verify = FD ≤1e-6 + focused tests (local tiny); no twin Δ.

---

## Amendment 2026-08-15 — ceiling review (APPROVED)

Ceiling judgment on the W1-censored-Id Identity (`6ab338f8`, PR #209) before the
W2 engine opens. Verdict **APPROVED**; the amendments above are mandatory and
already applied. Twin verified at `gllvmTMB` @ `114a227e`.

### §1 Fence upheld — no light Δ is available to invent

Every fence-critical cite re-verified independently: no censored id in `enum.R`,
zero `censor` matches in `src/gllvmTMB.cpp`, absent from the `fit-multi.R`
supported-family list, FAM-16 `blocked` in the debt register, and a twin test
that *requires* `gllvmTMB()` to fail loud on `censored_poisson()`. A light RCall
Δ is therefore not merely discouraged — it is **impossible** to construct
honestly. Julia-forward is the correct route.

### §2 Twin cites were understated, not overstated

The accepted text described the twin as admitting "a constructor name only".
The twin in fact carries a **written likelihood spec** (registry line 183,
`03-likelihoods.md` §Censored Poisson, and `105-va-family-densities.md` §7 with
per-row densities, EVA terms, and hazards). Understating twin support cannot
produce an overclaim, so this was not blocking — but it withheld directly
load-bearing guidance from the engine owner, and it framed right-vs-left/interval
as an open Julia choice when the twin had already specified interval censoring.

The locked right-censored contribution is **algebraically identical** to the
twin's documented density, by Poisson–gamma duality
`P(Y ≥ C | μ) = pgamma(μ; shape = C)`. Verified numerically (R, 9 cells):
agreement to ≤ 8e-12 wherever the naive form is finite. Right-censored-first is
therefore a **documented subset** of the twin spec, which is a materially
stronger position than the original text claimed.

### §3 Blocking-grade hazard in the locked evaluation form (fixed above)

The accepted text locked the contribution as `log(1 − F_{Pois(μ)}(C−1))`. That
form **catastrophically underflows** to `-Inf` in exactly the regime `μ ≪ C`:

| `μ` | `C` | `log(1 − F(C−1))` | `log pgamma(μ, C)` |
|---|---|---|---|
| 0.3 | 30 | `-Inf` | `-111.0677` |
| 3.7 | 30 | `-Inf` | `-38.9817` |
| 0.3 | 5 | `-11.056447867584` | `-11.056447867591` |

This is not hypothetical for a Laplace engine: `μ = exp(η)` is evaluated at
trial `η` during the mode solve and the outer optimisation, which routinely
visits values far from the data. An `-Inf` objective at a trial point breaks the
mode solve **and** silently poisons the FD gradient check that this Identity
names as its own verification gate. The twin's §7(e) documents the same hazard.

**Locked remedy — the log-space regularised incomplete gamma, not the
asymptote.** The primary path is `log P(Y ≥ C) = logcdf(Gamma(C, 1), μ)`
(Julia: `Distributions.logcdf`, or `SpecialFunctions.gamma_inc` in log space),
which is accurate across the whole range and finite where the naive survival
form has already underflowed.

The twin's §7(e) small-`μ` asymptote `C·log μ − μ − lgamma(C+1)` is **leading
order only** and must **not** be used as the differentiated path — measured
absolute error:

| `μ` | `C` | error vs exact |
|---|---|---|
| 0.05 | 10 | 4.6e-03 |
| 0.3 | 30 | 9.7e-03 |
| 3.7 | 30 | 1.3e-01 |

At 1e-2 to 1e-1 it would blow the Identity's own FD ≤ 1e-6 gate by four orders
of magnitude. Treat it as a sanity reference or a last-resort guard far below
the `logcdf` underflow threshold, with its error stated — never as the default.
The estimand row now separates **estimand** from **evaluation** accordingly.

### §4 Encoding must stay interval-ready

Because the twin spec is interval censoring, a v1 API of one scalar limit `C`
plus a flag does not forward-extend (interval rows need `(L, U)`). The Identity
wisely left the signature as engine detail, so nothing is over-committed — but
W2 must choose an encoding that admits `(L, U)` without a breaking change, or
accept a later API break under the convention-change cascade.

### §5 The locked path is **not** AD-clean — hand-coded derivatives required

Checked in this project's environment (`julia --project=.`, Julia 1.x,
Distributions 0.25, ForwardDiff 0.10):

- `logcdf(Gamma(C, 1.0), μ)` reproduces R's `pgamma(μ, C, log.p = TRUE)` to all
  printed digits and stays finite where the naive form gives `-Inf`. ✔
- `ForwardDiff.derivative` through it **fails**:
  `MethodError: no method matching _gammalogcdf(::ForwardDiff.Dual, ::ForwardDiff.Dual)`.
  ✘ The censored row therefore **cannot** be differentiated by wrapping the
  stable evaluation in ForwardDiff.

This is not an obstacle — the derivatives are closed-form and cheap, and match
the twin's §7(c). With `μ = exp(η)`, `S = P(Y ≥ C)`, `G = μ·dpois(C−1; μ)/S`:

```
d/dη  log S = G
d²/dη² log S = G·(C − μ − G)
```

FD-verified against central differences on `logcdf` in this repo across
`(μ, C) ∈ {(3.7,5), (0.3,30), (0.05,10), (25,30), (120,100)}`:
first derivative agrees to **≤ 3.4e-10**, curvature to **≤ 1.2e-6** (the looser
cells are FD truncation on small magnitudes, not formula error). Both hold
inside the regime where the naive survival form has already collapsed.

W2 should hand-code these — consistent with the repo's existing pattern of
hand-coded implicit dense-Laplace gradients rather than generic AD. Observed
`g2 < 0` at all five tested cells, which is favourable for the mode solve; this
is **not** a proof of global concavity in `η` and must not be claimed as one.

### Verdict

**APPROVED** for W2 engine on owned files
(`src/families/censored_poisson.jl`, `test/test_censored_poisson.jl`), with the
amendments above in force. Conditions on W2:

1. Implement the **stable** evaluation path (§3); include a focused test at
   `μ ≪ C` (e.g. `μ = 0.3, C = 30`) that would fail under the naive form.
2. Hand-code the §5 derivatives; do **not** attempt AD through `logcdf`.
3. FD ≤ 1e-6 must be checked **at a censored-row-dominated cell**, not only an
   uncensored one.
4. No twin Δ, no ADEMP, no ledger flip to `implemented` beyond
   "Julia-forward, twin constructor-only".
5. Encoding forward-compatible with `(L, U)` (§4).
6. `docs/dev-log/check-log.md` entry — **deliberately not written by this
   review**: it is a shared choke point across four parallel Wave-1 lanes, so it
   belongs to the merge conductor (per Out of scope above).

Not blocked: the estimand is correct and twin-consistent, and the fence is
conservative. The defects were evidence-completeness and numerical-form issues,
both repairable in docs, both repaired here.
