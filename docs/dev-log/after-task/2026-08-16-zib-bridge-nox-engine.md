# After-task — ZIB no-X bridge engine (Identity #229, B1–B5)

**Date:** 2026-08-16
**Lane:** `cursor/zib-bridge-nox-20260816`, worktree from `origin/main` @ `f55b9568`
**Identity (locks):** `docs/dev-log/decisions/2026-08-16-zib-bridge-identity.md`
(ACCEPTED, MERGED #229). Inherits #208 amendments **R1** (shared scalar `N` is a
lock) and **R2** (bridge fence, route **(b)**); builds on the ZIB no-X
`fit_gllvm` (#218) and `@formula` (#220) admits.
**Reviewed as:** Ada (orchestration / claim wording), Gauss (bridge numerics),
Fisher (CI routing), Rose (claim-vs-evidence fence).

## Goal

Stated as a check before writing code: `bridge_fit(; y, family = "zib", d, N)`
returns the flat contract with a `loglik`, `alpha`, `beta_zero`, and `loadings`
that match a direct `fit_zib_gllvm(Y; K, N)` call to ≤ 1e-8, routes
Wald/profile/bootstrap CI payloads identical to native `confint(::ZIBFit)`, and
rejects every trials-contract violation at the boundary. **No-X only.**

## What landed

`src/bridge.jl` (the conductor choke point — the only source file touched):

- **B1 — `"zib"` is a real family key.** Four aliases (`zib`, `zibinomial`,
  `zero_inflated_binomial`, `zi_binomial`), added to `_BRIDGE_ONEPART_FAMILIES`
  and to the unsupported-family message, with a no-X dispatch arm returning the
  flat contract plus `beta_zero` and `trials`. `"zib"` is **not** in
  `_BRIDGE_X_FAMILIES`, so the existing X guard rejects X for this family.
- **B2 — trials transport.** New `_bridge_zib_trials(N, p, n)` normalises the
  boundary `N` to one `Int`: numbers round; a `p×n` `N` is admitted **only if
  uniform**, then collapsed (R's `cbind(success, failure)` naturally builds a
  matrix); unequal entries raise an `ArgumentError` naming the shared-scalar
  contract rather than silently taking `N[1, 1]`; `N === nothing` raises, because
  the binomial `fill(1, p, n)` default would silently select the zero-inflated
  **Bernoulli**, where `(βz, βc)` is aliased. `"zib"` stays **out** of
  `_BRIDGE_TRIALS_FAMILIES`, so `cbind_binomial` reports **false** — the
  uniform-matrix acceptance is transport convenience, not an advertised
  per-observation contract. A response-range guard (`0 ≤ y ≤ N`) was added
  alongside it.
- **B3 — masks.** `"zib"` stays out of `_BRIDGE_MASK_FAMILIES` /
  `_BRIDGE_MASK_CI_FAMILIES` (`fit_zib_gllvm` has no `mask` kwarg), with a
  family-named throw mirroring the ZIP/ZINB arms.
- **B4 — CI.** No-X routes all three methods through the existing
  `_family_ci(::ZIBFit)` via `_bridge_compute_ci_ng(fit, Float64.(Yi), nothing, …)`
  — `N = nothing` because ZIB's trials count lives on the fit object. `ci_x_*`
  stays **false**: `ZIBCovFit` is in neither `_CIFit` nor the
  `_bridge_compute_ci_cov` Union (verified live, below), so the +X arc must add
  that engine or fence itself explicitly before it can ship.
- **B5 — capability row.** Took the Identity's **preferred** resolution: a new
  `_BRIDGE_NO_SIMULATE_FAMILIES = ("zip", "zinb", "zib")` narrows the
  `postfit_simulate` column only. No `simulate` method exists for `ZIPFit`,
  `ZINBFit`, or `ZIBFit`, so this makes all three zero-inflated rows honest at
  once instead of propagating an inherited over-claim. Strictly a claim
  narrowing; no behaviour change. The Identity's draft `notes` string landed
  essentially verbatim.

### One deviation from the Identity, and why

**B4** suggested reusing `_bridge_assemble_ng` "exactly as the ZIP arm's call".
That is not available for ZIB: `_bridge_assemble_ng` reads `fit.link`, and
`ZIBFit`'s fields are `(βz, βc, Λc, N, loglik, converged, iterations)` — no
`link`. This arm therefore calls `_bridge_assemble` directly (the **ZINB** arm's
proven shape), with `link = "LogitLink"` and the `ΛcΛcᵀ` fallback for
`Sigma`/`correlation`/`communality` stated in the returned `note`. The numbers
are what `_bridge_assemble_ng`'s `MethodError` fallback would have produced; only
the plumbing differs.

**Adjacent finding, not fixed here (out of lane).** `ZIPFit` has no `link` field
either, so the existing ZIP **no-X** arm (`bridge.jl`, `key == "zip"`) reaches
`_bridge_assemble_ng` → `_bridge_link_name(fit.link)` and cannot succeed. No test
covers that route today — the ZIP bridge tests all exercise the **+X** arm, and
the capability columns are list-membership assertions rather than live fits. This
is a pre-existing defect on `main`, independent of ZIB; recorded here so the next
bridge arc can pick it up with its own G0 rather than discovering it from an R
user. Flagged as evidence (field list read from `src/families/twopart.jl:771`),
not speculation.

## Files changed

| File | Change |
| --- | --- |
| `src/bridge.jl` | B1–B5: family key + aliases, one-part membership, `_bridge_zib_trials`, no-X dispatch arm, `_BRIDGE_NO_SIMULATE_FAMILIES`, `zib` notes row, header/docstring contract for `N` and `trials` |
| `test/test_bridge_zib.jl` | **new** — focused ZIB bridge suite (77 tests) |
| `test/test_bridge_capabilities.jl` | golden updated: `zib` row, narrowed `postfit_simulate` column, dedicated `zib` assertions, all-three-ZI simulate check |
| `test/runtests.jl` | include the new file |
| `docs/design/capability-status.md` | OWED-list update: bridge no-X ZIB lands; ZIB+X / masks / `_family_ci(::ZIBCovFit)` remain OWED; twin Δ **forbidden**, not owed |
| `docs/dev-log/check-log.md` | entry for this arc |
| `docs/dev-log/after-task/2026-08-16-zib-bridge-nox-engine.md` | this report |

## Verification (actual output, not a summary)

Mac-LIGHT: **no local `Pkg.test()`** — GitHub CI is the verifier for the full
suite (incl. Aqua/JET). Focused local runs, all outside the sandbox on the
worktree environment:

```
$ julia --project=. test/test_bridge_zib.jl
ZIB bridge no-X Wald CI: max|Δ| vs native = 0.0 (≤1e-8)
Test Summary:               | Pass  Total   Time
ZIB bridge admission (no-X) |   77     77  18.2s

$ julia --project=. test/test_bridge_capabilities.jl
Test Summary:              | Pass  Total  Time
bridge capabilities ledger |  184    184  0.3s
```

Live capability probe (same environment), confirming every column the Identity
specified:

```
family col: …, zip, zinb, zib, mixed-family vector
zib idx=15
  fit_no_x=true fixed_X=false cbind=false mask=false xlv=false
  ci_no_x=(true, true, true) ci_mask=false ci_x=false
  predict=true resid=true simulate=false
  simulate col: gaussian, poisson, binomial, binomial_probit, binomial_cloglog,
                negbinomial, nb1, beta, gamma, mixed-family vector
  resid col:    … zip, zinb, zib, mixed-family vector
aliases: ["zib", "zib", "zib", "zib", "zib"]     # incl. "ZIB" (case/space normalised)
trials scalar=6 uniform=6
nothing  -> ArgumentError ok
unequal  -> ArgumentError ok
N=0      -> ArgumentError ok
simulate(ZIBFit) method? false
ZIBFit <: _CIFit: true   ZIBCovFit <: _CIFit: false
```

`GLLVM` precompiles clean with the new bridge code (`1 dependency successfully
precompiled`).

What the 77 tests cover: family-key aliases and membership in all six bridge
lists; the trials contract including every rejection path; the no-X point route
against `fit_zib_gllvm` at 1e-8 (`alpha`, `beta_zero`, `loadings`, `loglik`,
`df`, dispersion `NaN`, link, symmetric unit-diagonal `correlation`, `nobs`);
bit-equality of the uniform-`p×n`-`N` route with the scalar route; alias routing;
loud rejection of missing / non-uniform `N`, out-of-range `y`, mask, `X`, `X_lv`,
and `zib` inside a mixed-family vector; and the no-X Wald CI payload against
native `confint` (**max|Δ| = 0.0**).

## Workflow Q status

| Check | Verdict |
| --- | --- |
| FD verification ≤ 1e-6 | **N/A** — no new likelihood or gradient; the ZIB marginal and its FD gate landed with the engine (`test/test_zib_x_identity.jl`) |
| Cross-check vs in-repo reference ≤ 1e-8 | **PASS** — bridge vs `fit_zib_gllvm` at 1e-8; Wald CI vs native `confint` at Δ = 0.0 |
| R-parity via RCall | **FORBIDDEN, not owed** — `gllvmTMB` has no ZIB; a Δ would be fabricated |
| JET / Allocs / Aqua | **deferred to CI** (Mac-LIGHT); no new type unions or hot-loop code — the added helper is a scalar validator run once per fit |
| Multi-shape | **N/A** — no phylogenetic substrate touched |

## Rose fence

**OK to claim:** the R bridge accepts `family = "zib"` for **no-X** fits, routing
`fit_zib_gllvm` with Wald/profile/bootstrap CI payloads and one **shared scalar**
trials count `N`, which is **required** at the boundary.

**NOT OK to claim:** any `gllvmTMB` parity, light RCall Δ, or twin comparison for
ZIB; ZIB+X through the bridge; CI under X; missing-response masks; per-observation
`cbind` trials; bridge-routed `simulate`; any ADEMP or coverage result; that
#208's `N` lock was revisited.

## Remaining risks / follow-ups

1. **ZIB+X on the bridge** — needs the **B4** choice made explicitly: either
   `_family_ci(::ZIBCovFit)` plus both Unions, or `"zib"` in
   `_BRIDGE_NO_CI_X_FAMILIES` (currently `()`, with a comment that will need
   editing). Own G0.
2. **ZIP no-X bridge arm** — the `fit.link` defect above. Own G0.
3. **`simulate` for ZIP / ZINB / ZIB** — the column is now honest; the extractor
   gap remains.
4. **Bridge masks for any zero-inflated family** — needs a masked ZIB Laplace
   marginal first.
5. Per-observation trials `N_{ts}` for ZIB would need its own Identity; nothing
   here opens that door.

## Next command

```sh
gh pr checks --watch          # full CI is the verifier for this arc
```
