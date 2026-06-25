# After Task: Predictor-Informed Latent Scores C1

Date: 2026-06-25

## Goal

Add the smallest Julia-side analogue of the R `gllvmTMB`
`latent(..., lv = ~ x)` C1 implementation: ordinary Gaussian, unit-tier
predictor-informed latent-score means, with point-estimate post-fit extractors
and no interval or broader parity claim.

## Implemented

- Added an explicit Gaussian negative log-likelihood for
  `z_total[s, :] = X_lv[s, :] * alpha_lv + z_innovation[s, :]`.
- Added `fit_gaussian_gllvm(...; X_lv = X_lv, alpha_lv_init = ...)` for the
  ordinary Gaussian unit-tier path.
- Stored `pars.alpha_lv` and the fitted `theta_packed` for reproducibility.
- Extended `getLV(fit, y; X_lv, component = :mean/:innovation/:total)` so the
  score decomposition is visible.
- Extended Gaussian `predict`, `fitted`, and `residuals` to accept `X_lv`.
- Added `extract_lv_effects(fit)` / `lv_effects(fit)` for the rotation-stable
  trait-effect matrix `B_lv = Lambda * alpha_lv'`.
- Guarded `confint`, `profile_ci`, and `bootstrap_ci` for `X_lv` fits because
  interval calibration is not admitted in this C1 slice.
- Updated the model page and changelog with `PARTIAL` wording only.

## Scope Boundary

IN: ordinary Gaussian unit-tier point-estimate support for predictor-informed
latent-score means.

PARTIAL: score decomposition and rotation-stable trait effects are algebra-tested,
but not recovery/coverage validated.

OUT: W-tier, diagonal random effects, phylogenetic/source-specific blocks,
non-Gaussian families, REML, R bridge promotion, interval calibration, and broad
R-Julia parity claims.

## Files Changed

- `src/likelihood.jl`
- `src/fit.jl`
- `src/postfit.jl`
- `src/confint.jl`
- `src/confint_profile.jl`
- `src/confint_bootstrap.jl`
- `src/GLLVM.jl`
- `test/test_lv_predictor.jl`
- `test/runtests.jl`
- `docs/src/model.md`
- `docs/src/changelog.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-25-lv-predictor-c1.md`

## Tests Added

`test/test_lv_predictor.jl` covers:

- fitted `alpha_lv` shape and storage;
- `getLV` mean/innovation/total algebra;
- `extract_lv_effects(fit) == fit.pars.Λ * fit.pars.alpha_lv'`;
- `predict` / `fitted` reconstruction;
- AIC/BIC free-parameter counting;
- CI guard errors;
- AD-friendliness of the explicit `gaussian_lv_nll_packed`;
- clear errors for unsupported C1 combinations.

## Checks Run

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_lv_predictor.jl
```

Result: `24/24` pass.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no -e 'include("test/test_fixed_effects.jl"); include("test/test_postfit.jl")'
```

Result: fixed effects `18/18` pass; post-fit blocks all pass, including
ordination core `96/96`, predict/fitted `9/9`, residuals `10/10`, AIC/BIC
`8/8`, Poisson `163/163`, NB `160/160`, Beta `215/215`, Gamma `215/215`,
Ordinal `216/216`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no -e 'include("test/test_confint.jl"); include("test/test_confint_profile.jl"); include("test/test_confint_bootstrap.jl")'
```

Result: Wald CI `14/14`, profile CI `4/4`, bootstrap CI `9/9`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no -e 'using Pkg; Pkg.instantiate()'
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/runtests.jl
```

Result: full local test suite passed with `4519` pass, `3` broken, `4522`
total in `31m25.4s`. The run reported that Aqua and JET are not available in
this direct `test/runtests.jl` environment and should be run through
`Pkg.test()` for the full battery.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: package test suite passed with `4531` pass, `1` broken, `4532` total
in `36m58.2s`. This run used the temporary `Pkg.test()` environment with Aqua
and JET available.

```sh
/Users/z3437171/.juliaup/bin/julia --project=docs --startup-file=no docs/make.jl
```

Result: Documenter/VitePress build completed. The run reported pre-existing
invalid-local-link warnings in the docs navigation and npm audit warnings from
the VitePress dependency tree; neither warning class was introduced by this
slice.

## Deliberately Not Run

- No Julia branch was pushed and no PR was opened. `gllvmTMB` PR #558 is open
  and green, and GLLVM.jl draft PR #113 is also open; this repo also says no
  push without explicit maintainer instruction.

## Rose Verdict

PASS WITH NOTES. The implementation moves the Julia engine toward the R C1
surface without claiming intervals, non-Gaussian support, or bridge parity. The
next gate is sequencing: merge/park the active PRs, then run GitHub Actions and
open a focused PR when the one-PR discipline allows it.
