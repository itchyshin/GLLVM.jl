# GLLVM.jl ↔ gllvmTMB capability gap sheet — 2026-08-16

**Purpose.** One durable, honest sheet for the north star: *GLLVM.jl as capable
as `gllvmTMB`, and faster*. It names what the R twin admits, what Julia admits,
and where Julia is short — so the next arc is chosen from evidence rather than
from momentum.

**Base.** Every code claim below was read off `origin/main` @ `ef332643` (merge of
#216). The sheet lands on `24c7625b` (merge of #217); `git diff ef332643..24c7625b`
touches **one** dev-log file and **zero** paths under `src/` or `test/`, so the
verification carries over unchanged. Twin read at `gllvmTMB` @ `114a227e`,
`DESCRIPTION` Version **0.6.0**.

**Sources.**

- `docs/design/capability-status.md` (Julia MC ledger, this repo)
- `docs/dev-log/handover/2026-08-16-overnight-catchup-handoff.md` (overnight OWED)
- `docs/dev-log/handover/2026-08-15-zib-x-ADMIT.md` (route-(b) fences)
- Twin engine truth: `gllvmTMB/R/enum.R` (`.valid_family`), `gllvmTMB/NAMESPACE`
  (154 exports), `gllvmTMB/R/aghq-*.R`, `R/cv-*.R`,
  `gllvmTMB/docs/dev-log/2026-07-12-capability-audit-gapmap.md`

## Reading rules (fences, not decoration)

- **No invented twin Δ.** A "twin status" cell here is read off twin *code*
  (`.valid_family`, `NAMESPACE`) or a twin dev-log, never inferred from the
  Julia side. Where the twin does **not** admit a capability, the Julia row is
  *Julia-forward* and carries **no** parity obligation.
- **`implemented` in the Julia MC ledger means engine + test.** It does **not**
  mean the capability is reachable from `fit_gllvm`, `@formula`, or the R
  bridge. This sheet separates those axes explicitly, because the ledger does
  not — that separation is the single most actionable finding below.
- Nothing here promotes or demotes a `docs/design/capability-status.md` row.
  Ledger edits belong to a Rose pass, not to this plan file.

## The headline

The family *count* is no longer the gap. Julia admits **more** distinct
response families than the twin (the twin's `.valid_family` is 17 entries;
Julia additionally carries ZIP/ZINB/ZIB, hurdle, ordered-beta, COM-Poisson,
censored Poisson, GP1). **Exactly one twin family has no Julia engine at all:
`multinomial`.**

The real gap has moved to three other places:

1. **Surface reachability.** Several Julia families have an engine + test but
   cannot be reached from the user-facing entry points. That is a capability
   gap to a *user* even though the ledger reads `implemented`.
2. **Estimator breadth.** The twin ships AGHQ (four `R/aghq-*.R` modules incl.
   an auto-gate) and cross-validation (`R/cv-internal.R`, `R/cv-metrics.R`).
   Julia has neither — no `aghq` or `crossval` symbol anywhere under `src/`.
3. **Covariance grammar depth.** The twin exports a `scalar()` mode and
   `*_slope()` constructors across sources. Julia's grid has no `scalar` row
   at all, and no keyworded random slopes.

## 1. Response families

Twin column is `.valid_family` in `gllvmTMB/R/enum.R` (ids 0–16). Julia column
is `docs/design/capability-status.md` plus a code check of
`src/families/fit_gllvm.jl`, `src/formula.jl`, `src/bridge.jl` on `ef332643`.

| Family | Twin status | Julia status | Blocker | Next arc |
|---|---|---|---|---|
| gaussian | admitted (id 0) | implemented; `fit_gllvm` + `@formula` + bridge | — | — |
| binomial | admitted (id 1) | implemented; all three surfaces | — | — |
| poisson | admitted (id 2) | implemented; all three surfaces | — | — |
| lognormal | admitted (id 3) | implemented; `fit_gllvm` + `@formula` no-X | not in `_BRIDGE_ONEPART_FAMILIES`; light RCall Δ OWED | bridge no-X `lognormal` (twin fid 3 exists, so a twin Δ is legitimate here) |
| Gamma | admitted (id 4) | implemented; all three surfaces | — | — |
| nbinom2 | admitted (id 5) | implemented; all three surfaces | — | — |
| tweedie | admitted (id 6) | implemented (engine + grouped-dispersion route) | **no `_fit_gllvm(::Tweedie)` arm**; absent from `@formula` and bridge | surface admit: `fit_gllvm`/`@formula` no-X, then bridge |
| Beta | admitted (id 7) | implemented; all three surfaces | — | — |
| betabinomial | admitted (id 8) | implemented; `@formula` X arm + bridge (one-part + X) | **no `_fit_gllvm(::BetaBinom)` no-X arm** — reachable under X but not without it | small no-X `fit_gllvm` admit (trials `N` contract already settled by bridge) |
| student | admitted (id 9) | implemented (engine + `test_studentt.jl`) | no `fit_gllvm` / `@formula` / bridge arm | surface admit arc |
| truncated_poisson | admitted (id 10) | implemented; `fit_gllvm` + `@formula` no-X | not on bridge | bridge no-X (twin fid 10) |
| truncated_nbinom2 | admitted (id 11) | implemented; `fit_gllvm` + `@formula` no-X | shared scalar `r` ≡ twin `φ`; **per-trait `log_phi_truncnb2` is Arc1b OWED**; not on bridge | per-trait dispersion, then bridge (twin fid 11) |
| delta_lognormal | admitted (id 12) | implemented (engine) | no `fit_gllvm` / `@formula` / bridge arm; latent-scale correlation advertising is `rejected` | surface admit arc (two-part) |
| delta_gamma | admitted (id 13) | implemented (engine) | same as above | surface admit arc (two-part) |
| ordinal_probit / cumulative_logit | admitted (id 14) | implemented; all three surfaces | — | — |
| nbinom1 | admitted (id 15) | implemented; `@formula` X arm + bridge | no no-X `_fit_gllvm(::NB1)` arm | small no-X admit (mirrors betabinomial) |
| **multinomial** | **admitted (id 16)**; `export(multinomial)`; twin NEWS records it as a new *unordered categorical* family | **missing — no Julia engine** | genuinely absent: no likelihood, no marker, no test | the only remaining *family-shaped* twin gap; needs an Identity + engine arc, not a surface admit |
| zip / zinb | **not in twin** (`.valid_family` has no ZI entries) | implemented; all three surfaces incl. CI-under-X | Julia-forward | — (no twin Δ ever) |
| **zib** | **not in twin** | engine only (`fit_zib_gllvm`, `fit_zib_gllvm_cov`) | **`ZIB` marker not exported**; no arm in `fit_gllvm.jl`, `formula.jl`, `bridge.jl` (all three verified empty on `ef332643`) | **no-X ZIB surface arc — see §5** |
| hurdle_poisson / hurdle_nbinom2 | not in twin | implemented (engine) | Julia-forward; surface reachability unverified | low priority |
| ordered_beta / beta_hurdle | not in twin | implemented (engine) | Julia-forward | low priority |
| censored_poisson | **not in twin** (constructor-only) | implemented; `fit_gllvm` + `@formula` no-X | light RCall Δ **FORBIDDEN** | — |
| com_poisson | not in twin | implemented (engine + `test_com_poisson.jl`) | no surface arm | low priority |
| exponential / GP1 | not in twin as ids | implemented; `fit_gllvm` arms present | Julia-forward | — |

**Surface-reachability summary (the actionable slice).** `_fit_gllvm` has 15
arms: Normal, Binomial, Poisson, TruncatedPoisson, CensoredPoisson,
TruncatedNegBin2, Lognormal, NegativeBinomial, Beta, Ordinal, Gamma,
Exponential, GeneralizedPoisson1, ZIPoisson, ZINegBin. Families with an engine
but **no** `fit_gllvm` arm: **NB1, BetaBinom, Tweedie, student, com_poisson,
delta_gamma, delta_lognormal, hurdle_*, ordered_beta, ZIB.** `@formula` no-X
inherits `fit_gllvm` (fall-through at `src/formula.jl:104`), so every one of
those is invisible from `@formula` no-X too.

## 2. Covariance structure grid

Twin constructors from `NAMESPACE`: base `indep`/`dep`/`latent`/`scalar`;
`phylo_{indep,dep,latent,scalar,rr,slope,unique}`;
`animal_{indep,dep,latent,scalar,slope,unique}`;
`spatial_{indep,dep,latent,scalar,unique}`;
`kernel_{indep,dep,latent,scalar,unique}`.

| Capability | Twin status | Julia status | Blocker | Next arc |
|---|---|---|---|---|
| none × indep | exported | implemented | — | — |
| none × dep (unstructured trait cov, no LV) | exported | planned | no unstructured `dep()` path without LV | mid-term |
| none × latent | exported | implemented | — | — |
| phylogenetic × {indep, latent} | exported | implemented (3 equivalent representations) | — | — |
| phylogenetic × dep | exported | planned | — | mid-term |
| animal × indep | exported | implemented (Gaussian via `relatedness_cov`) | — | — |
| animal × {dep, latent} | exported | planned | — | mid-term |
| spatial × {indep, latent} | exported | implemented (SPDE latent for non-Gaussian) | — | — |
| spatial × dep | exported | planned | — | mid-term |
| kernel × {indep, dep, latent} | exported (+ `make_cross_kernel`, `diagnose_kernel_separability`) | planned | whole source missing | mid-term |
| **`scalar()` mode (all five sources)** | **exported for all five sources** | **absent from the Julia grid entirely** — not even a `planned` row | Julia grammar has no `scalar` mode concept | ledger row first (Rose), then design |
| **`*_slope()` (phylo/animal)** | **exported** | absent; ledger's "keyworded random slopes" is `planned` | — | mid-term |
| `*_unique()` / `common=` modifiers | exported for four sources | not represented as rows | — | ledger row first |
| `phylo_rr` | exported | not represented | — | low |
| Phylo Model A public `lv` intervals | — | **rejected** for advertising | deliberate fence | never |

The twin's own 2026-07-12 gap map is worth reading beside this: it reports the
twin's structured grid has *no family guard*, so twin structure×family cells are
broad but thinly **tested** for non-Gaussian. Julia should not treat twin
breadth as twin *validation*.

## 3. Estimation, intervals, evidence

| Capability | Twin status | Julia status | Blocker | Next arc |
|---|---|---|---|---|
| ML (Laplace / closed-form Gaussian) | default | implemented | — | — |
| **AGHQ** | **shipped**: `R/aghq-control.R`, `aghq-gate.R`, `aghq-auto-ridge.R`, `aghq-report.R` (incl. auto-decide gate) | **missing** — no `aghq` symbol under `src/` | whole estimator absent | Identity ACCEPTED 2026-08-17 (`docs/dev-log/decisions/2026-08-17-aghq-identity.md`); engine campaign still unpaid — do not start without a fresh `/arc-creation` |
| REML | Gaussian-only pilot | code exists (`src/reml.jl`, `fit_gaussian_reml`, bridge `reml=true`) but **no dedicated package test** → ledger `planned` | test-shaped, not engine-shaped | cheap: add `test_reml.jl`, then promote |
| Non-Gaussian REML | — | **rejected** (deliberate) | — | never |
| **Cross-validation** | **shipped**: `R/cv-internal.R`, `R/cv-metrics.R`, `data-cv-fixture.R` | **missing** — no `crossval` symbol under `src/` | absent | mid-term |
| Wald / profile / bootstrap intervals | present | implemented (all three, incl. derived quantities) | — | — |
| Simulation-validated coverage certificate (broad grid) | partial in twin | **missing** | compute campaign (Totoro/DRAC), not a code arc | Phase-2 style campaign |
| VA / ELBO | not R-default | implemented (selected families) | Julia-forward | — |

## 4. Data handling and special capabilities

| Capability | Twin status | Julia status | Blocker | Next arc |
|---|---|---|---|---|
| Fixed-effect `X`, species-specific coefficients, fourth-corner | present | implemented | — | — |
| Row effects fixed / random | present | implemented | — | — |
| Grouped dispersion (`disp.group`) | present | implemented | — | — |
| Missing responses (NA / mask) | `miss_control()` exported; twin gap map logs a **binomial `cbind` + `response="include"` crash** (T1.1) | implemented | — | — (do **not** port the twin bug) |
| Missing predictor `mi()` | present via `miss_control` | planned (FIML modules exist under `src/missing_predictor_*.jl`) | ledger/verify mismatch | Rose verify pass |
| Keyworded random slopes | exported (`phylo_slope`, `animal_slope`); twin gap map flags `unit_obs`/`cluster2` tiers as **zero slope support** (T2.1) | planned | — | mid-term; the twin is itself incomplete here |
| Mixed-family response vector | present | ledger says `planned`, but `src/families/mixed.jl` + `fit_mixed_gllvm` + `test_bridge_mixed.jl` all exist and the bridge row reads `implemented` | **ledger inconsistency** | Rose verify pass — either promote the native row or state why the native path is thinner than the bridge |
| Quadratic response, concurrent/constrained/RRR | present | implemented | — | — |
| `@formula` / long+wide (fixed effects) | R formula grammar | implemented, **continuous covariates only** (`src/formula.jl:113–115` rejects non-numeric) | categorical covariates unsupported in the Julia front-end | real user-facing gap; small-to-mid arc |

## 5. Recommended next arc

**Take the no-X ZIB surface arc** — `ZIB` marker export + `_fit_gllvm(::ZIB)` +
`@formula` no-X route — exactly as the overnight handoff and the ZIB+X ADMIT
route-(b) fence specify, **before** any ZIB bridge or ZIB+X surface admit.

Verified on `ef332643`, not assumed: `src/GLLVM.jl:209` exports
`fit_zib_gllvm` / `ZIBFit` / `fit_zib_gllvm_cov` / `ZIBCovFit` /
`zib_marginal_loglik_laplace` and **not** the `ZIB` marker; `rg ZIB` returns
**zero** hits in `src/families/fit_gllvm.jl`, `src/formula.jl`, and
`src/bridge.jl`. So ZIB today has a working X engine and no no-X user surface —
the exact leapfrog the ADMIT fence exists to prevent.

**Why this over the alternatives**, given the gap sheet:

- *Not `multinomial`* (the only true twin family gap): it needs a full Identity
  → likelihood → engine → test chain for an unordered categorical response.
  That is a campaign, not one arc, and it does not clear an existing fence.
- *Not AGHQ or CV* (the largest twin-shaped gaps): same objection, larger. Both
  deserve their own campaign after the surface debt is paid.
- *Not the 5-family surface sweep* (NB1, BetaBinom, Tweedie, student, delta_*):
  explicitly out of scope — no parallel wave. ZIB is the one with a standing,
  documented OWED and a named design gate.
- ZIB carries a **real design decision**, which is why it is an arc and not a
  one-line dispatch: `struct ZIB` carries `N::Int`
  (`src/families/twopart.jl:1209`), whereas `ZIPoisson` and `ZINegBin` are
  empty markers. The arc must decide how the shared scalar `N` reaches
  `fit_gllvm` / `@formula` without breaking the Identity trials lock. The
  ZIP/ZINB wiring pattern does **not** transfer as-is.

**Arc sketch (G0 scope).**

- **In:** export `ZIB`; `_fit_gllvm(::ZIB)` → `fit_zib_gllvm`; add ZIB to the
  availability message at `src/families/fit_gllvm.jl:166`; decide + document the
  scalar-`N` transport for `fit_gllvm` / `@formula`; no-X `@formula` route
  (inherited via the `:104` fall-through once the arm exists); focused test;
  decision note under `docs/dev-log/decisions/`.
- **Out:** bridge admission (own arc, own G0, no-X first — Identity R2); ZIB+X
  on `fit_gllvm` / `@formula`; `confint(ZIBCovFit)`; any twin light Δ (the twin
  has no ZIB — a Δ would be invented).
- **Definition of done:** identity check (zero-X ≈ no-X), packed FD gradient
  ≤ 1e-6, focused test wired into `runtests.jl`, decision note, after-task
  report, Rose verdict.

**Status: in flight.** The narrowest slice of this arc — export `ZIB`, add the
`_fit_gllvm(::ZIB)` arm forwarding the marker-borne scalar `N`, availability
string, docstring line, and a `fit_gllvm` smoke test — is open as
[#218](https://github.com/itchyshin/GLLVM.jl/pull/218). That PR deliberately
excludes `src/formula.jl` and `src/bridge.jl`, so the `@formula` and bridge rows
in §1 stay **OWED** and the route-(b) fence still holds for both.

**Second-priority follow-ups**, in cost order, for whoever picks up after:
(a) `test_reml.jl` — unblocks a ledger promote for code that already exists;
(b) the mixed-family and `mi()` ledger-verify pass — resolves two stale rows at
zero engine cost; (c) the no-X `fit_gllvm` arms for NB1 and BetaBinom — both
already have X routes, so the no-X hole is small and odd-shaped.

## Explicit non-claims

- No twin light Δ is asserted anywhere in this sheet.
- No `docs/design/capability-status.md` row is promoted or demoted here.
- No ADEMP / coverage certificate is claimed for any row marked `implemented`.
- Twin rows are read from twin code and twin dev-logs only; where the twin is
  itself untested (its own gap map's Tier 3), twin breadth is not twin evidence.
