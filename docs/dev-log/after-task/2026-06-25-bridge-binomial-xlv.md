## 1. Goal

Extend the predictor-informed latent-score route from Gaussian-only bridge rows
to the binary rows Shinichi flagged as high priority: binomial logit, probit,
and cloglog. Keep the route point-estimate only and do not imply CI,
missing-response, fixed-effect `X` + `X_lv`, mixed-family, or broader
non-Gaussian parity.

## 2. Implemented

- Added `fit_binomial_gllvm(...; X_lv = X_lv, alpha_lv_init = ...)`.
- Added `binomial_lv_nll_packed()` for the packed objective
  `eta = beta + Lambda * (X_lv * alpha_lv + z_innovation)'`.
- Stored `alpha_lv` and `theta_packed` on `BinomialFit` for X_lv fits while
  preserving the old six-argument constructor for existing callers.
- Extended `getLV()` for `BinomialFit` with
  `component = :mean/:innovation/:total`.
- Extended `predict()`, `residuals()`, `simulate()`, `extract_lv_effects()`,
  and `lv_effects()` to work with binomial X_lv fits.
- Added `bridge_fit()` keys `binomial_probit` and `binomial_cloglog`; the
  existing `binomial` key remains logit.
- Returned `lv_effects`, raw `alpha_lv`, `scores_mean`, and
  `scores_innovation` for binary X_lv bridge rows.
- Kept `confint()` and bridge CI requests rejected for binomial X_lv fits.
- Corrected the non-X binomial fitter so the logit-only analytic gradient is
  used only for `LogitLink()` no-offset fits; probit/cloglog use finite
  differences.
- Updated Documenter model/parity/changelog prose, the capability reporter, the
  capability ledger test, and the check log.

## 3a. Decisions and Rejected Alternatives

- Used the existing Laplace core with a parameter-dependent offset
  `Lambda * alpha_lv' * X_lv[s, :]`. This avoids a parallel binary likelihood
  implementation while making the symbolic model explicit.
- Kept `lv_effects = Lambda * alpha_lv'` as the primary reported estimand. Raw
  `alpha_lv` is retained for diagnostics but is latent-axis dependent.
- Added explicit bridge family keys for `binomial_probit` and
  `binomial_cloglog` rather than hiding link choice in an untyped option.
- Rejected CI routing for this slice because the existing non-Gaussian CI
  engines reconstruct the old `[beta; Lambda]` layout.
- Rejected response masks with bridge `X_lv` even though the native objective
  can use masks; the R bridge needs a separate parity gate before advertising
  that combination.

## 4. Files Touched

- `src/families/binomial.jl`
- `src/postfit.jl`
- `src/bridge.jl`
- `src/confint_family.jl`
- `src/simulate_fit.jl`
- `test/test_bridge_lv_predictor.jl`
- `test/test_bridge_capabilities.jl`
- `docs/src/model.md`
- `docs/src/gllvmtmb-parity.md`
- `docs/src/changelog.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-25-bridge-binomial-xlv.md`

## 5. Checks Run

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.instantiate()'
```

Result: dependencies instantiated in the fresh worktree; no `Project.toml` or
`Manifest.toml` diff remained.

```sh
julia --project=. --startup-file=no test/test_bridge_lv_predictor.jl
```

Result: `bridge predictor-informed latent-score X_lv 94/94` pass.

```sh
julia --project=. --startup-file=no test/test_binomial_fit.jl
```

Result: `fit_binomial_gllvm — recovery 8/8` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: `bridge capabilities ledger 44/44` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_ci.jl
```

Result: `bridge CI routing 64/64` pass.

```sh
julia --project=. --startup-file=no test/test_simulate.jl
```

Result: `simulate(fit) 5/5` pass.

```sh
julia --project=. --startup-file=no test/test_postfit.jl
```

Result: post-fit sections passed: ordination core 96/96, predict/fitted 9/9,
residuals 10/10, AIC/BIC/show 8/8, Poisson 163/163, NB 160/160, Beta 215/215,
Gamma 215/215, Ordinal 216/216.

```sh
git diff --check
```

Result: clean.

```sh
rg -n "Gaussian-only|Gaussian only|non-Gaussian X_lv|complete-response ordinary Gaussian|X_lv.*Gaussian-only|Gaussian X_lv" src test docs/src docs/dev-log/after-task/2026-06-25-bridge-binomial-xlv.md docs/dev-log/check-log.md README.md CHANGELOG.md
```

Result: remaining matches are historical log/report entries, REML
Gaussian-only boundaries, the native Gaussian fitter's own docstring, the
Gaussian-specific bridge test name, and guarded "non-binomial non-Gaussian"
wording.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: first full-suite run failed after `4595` pass, `0` fail, `1` error,
and `1` broken in `46m20.7s`. The failure exposed an unintended regression:
the initial binomial X_lv guard required positive `K` for all binomial fits,
which blocked the existing no-latent `K = 0` masked-CI bridge route in
`test/test_bridge_missing_mask.jl`.

Fix applied: ordinary binomial fits now allow `K >= 0`; only X_lv fits require
positive latent dimension `K > 0`.

```sh
julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
```

Result: `masked missing-response bridge 83/83` pass after the guard fix.

```sh
julia --project=. --startup-file=no test/test_bridge_lv_predictor.jl
julia --project=. --startup-file=no test/test_binomial_fit.jl
julia --project=. --startup-file=no test/test_bridge_ci.jl
```

Result after the guard fix: `bridge predictor-informed latent-score X_lv 94/94`,
`fit_binomial_gllvm - recovery 8/8`, and `bridge CI routing 64/64` pass.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: rerun started after the guard fix, reached the late VA-vs-Laplace
blocks, then was interrupted at Shinichi's stop request before completion.
No Julia test process remained running after interruption.

## 6. Tests of the Tests

- The packed-objective test compares `binomial_lv_nll_packed()` to the existing
  offset Laplace likelihood for logit, probit, and cloglog. If the X_lv offset
  is transposed, omitted, or link-specific code drifts, the equality check
  fails.
- The native binary X_lv test simulates multi-trial binomial data with genuine
  latent innovation variation, then checks convergence, `B_lv` recovery
  correlation, score decomposition, prediction, and direct `confint()` rejection
  for all three links.
- The bridge test fits `binomial`, `binomial_probit`, and `binomial_cloglog`
  with `X_lv` and checks link names, model tags, score algebra, payload shapes,
  note wording, native simulation behavior, and bridge CI / mask /
  simultaneous fixed-effect `X` rejection.
- The capability ledger locks the new binary link rows, including
  `predictor_informed_lv` and `cbind_binomial`.

## 7a. Issue Ledger

- Fixed: Julia had no binomial `X_lv` native or bridge route.
- Fixed: `bridge_capabilities()` reported `X_lv` as Gaussian-only.
- Fixed: the binomial fitter could use the logit-only analytic gradient for
  probit/cloglog no-X fits.
- Deferred: R-side `gllvmTMB(..., engine = "julia")` still needs to map
  binomial link objects to the new Julia bridge keys and lift the current
  Gaussian-only `X_lv` gate.
- Deferred: CI/profile/bootstrap support for binary `X_lv` remains gated.

## 8. Consistency Audit

- Current GLLVM.jl PR state before this branch: draft PR #113
  (`claude/studentt-105-20260620`) was open, merge-dirty, and overlaps
  `docs/dev-log/check-log.md`, `src/GLLVM.jl`, `src/families/laplace.jl`, and
  `test/runtests.jl`. This branch was pushed as a backup, but no competing PR
  was opened.
- Prose updates keep the scope as Gaussian plus binomial logit/probit/cloglog
  point estimates only.
- REML / AI-REML wording was not introduced.
- No R validation row was promoted from this Julia-only work.

## 9. What Did Not Go Smoothly

- The first deterministic binary test fixture exposed a real scale weakness:
  `alpha_lv` could inflate while `Lambda` shrank, preserving `B_lv` but leaving
  the optimizer on a flat ridge. The test fixture was replaced with stochastic
  multi-trial data carrying real latent innovation variation, which identified
  the loading scale and produced converged fits for all three links.
- Full `Pkg.test()` exposed that the first guard for binary X_lv was too broad:
  it rejected `K = 0` for existing no-latent binomial bridge/CI routes. The
  correction keeps `K = 0` legal for no-X/no-latent fits and requires positive
  `K` only when `X_lv` is supplied.
- The fresh worktree initially lacked instantiated Julia dependencies. Running
  `Pkg.instantiate()` fixed the local environment and left no dependency-file
  changes.

## 10. Known Residuals

- Full `Pkg.test()` has not completed green after the guard fix. The first run
  exposed and then fixed the `K = 0` regression above; the rerun was interrupted
  at the maintainer stop request.
- Documenter build has not been run for this local branch.
- The R package still gates `engine = "julia"` X_lv to Gaussian; a follow-up
  `gllvmTMB` PR must map binomial logit/probit/cloglog links to the new Julia
  bridge keys and test the R object contract.
- Response masks, simultaneous fixed-effect `X` + `X_lv`, mixed-family rows,
  intervals, and non-binomial non-Gaussian X_lv routes remain deliberately
  blocked.
- The open draft Student-t PR #113 must be settled or rebased before opening a
  clean PR for this branch under the one-open-PR discipline.

## 11. Team Learning

- Binary `X_lv` tests need both the trait-scale mean effect and genuine latent
  innovation variation; otherwise `B_lv` can look right while `alpha_lv` and
  `Lambda` slide along a weak scale direction.
- Link variants should be explicit bridge keys when the R side must preserve
  semantic differences such as logit/probit/cloglog.
- Point-estimate routes and interval routes should remain separate status axes
  whenever the parameter layout changes.
