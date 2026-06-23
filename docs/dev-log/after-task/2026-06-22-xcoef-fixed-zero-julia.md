# After Task: Fixed-zero shared X coefficients in GLLVM.jl

## Goal

Mirror the `gllvmTMB` `Xcoef_fixed` zero-constraint lane in the Julia twin after
R-side PR #536 landed. The Julia side should accept positional fixed-zero masks
for shared fixed-effect coefficients, fit only free coefficients, expand the
reported coefficient vector back to the full design length, and give the R bridge
enough status metadata to print fixed rows honestly.

## Implemented

- Added `src/fixed_coefficients.jl` with shared helpers for zero-mask parsing,
  free-column design slicing, full-vector expansion, and status labels.
- Added `β_fixed` to `fit_gaussian_gllvm()`. When `X` is present, fixed columns
  are removed from the optimisation design, `pars.β` is expanded with exact zero
  entries, and `pars.β_fixed` records which coefficients were fixed.
- Added `γ_fixed` to `fit_gllvm_cov()`, with the same free-column optimisation
  and full-vector return contract for one-part non-Gaussian fixed-effect-X fits.
- Updated AIC/BIC parameter counting so fixed-zero entries are not counted as
  estimated coefficients.
- Updated Gaussian and non-Gaussian CI adapters so Wald/profile/bootstrap
  intervals are requested and refit only for free coefficients while preserving
  original coefficient indices in displayed names.
- Updated the R bridge to accept `coef_fixed` / `xcoef_fixed` / `beta_fixed` /
  `gamma_fixed` options and return `mean_coef_status` or `gamma_status`.
- Updated README, changelog, and the `gllvmTMB` parity page.

## Reviewer Notes

- Ada/Hopper: the lane mirrors the R contract and stays endpoint-local; no
  optimiser, likelihood, or TMB-equivalent mathematical change.
- Boole/Emmy: Julia's public mask is positional because the engine sees
  `X[p,n,q]`; formula-name resolution belongs in the R bridge.
- Fisher/Grace: fixed entries are not in the optimised parameter vector or model
  degrees of freedom, and CIs are not reported as if they were estimated.
- Rose: this is not variable selection, not screening, and not a general
  nonzero-constraint system.
- Gauss/Noether: inactive for likelihood review because the likelihood kernels
  are unchanged; fixed columns are removed before the existing likelihood path.

## Files Changed

- `src/fixed_coefficients.jl` (new), `src/GLLVM.jl`, `src/fit.jl`,
  `src/families/covariates.jl`, `src/postfit.jl`.
- `src/confint.jl`, `src/confint_profile.jl`, `src/confint_bootstrap.jl`,
  `src/confint_family.jl`.
- `src/bridge.jl`.
- `test/test_fixed_effects.jl`, `test/test_covariates.jl`,
  `test/test_bridge_x.jl`.
- `README.md`, `docs/src/changelog.md`, `docs/src/gllvmtmb-parity.md`,
  `docs/dev-log/check-log.md`, and this after-task report.

## Checks Run

- `julia --project=. --startup-file=no -e 'using GLLVM; println("loaded")'`:
  package loaded cleanly.
- Focused fixed-X tests:
  `julia --project=. --startup-file=no -e 'include("test/test_fixed_effects.jl"); include("test/test_covariates.jl"); include("test/test_bridge_x.jl")'`
  passed with `18/18`, `30/30`, and `179/179`.
- Bootstrap regression:
  `julia --project=. --startup-file=no -e 'include("test/test_confint_bootstrap.jl")'`
  passed with `9/9`.
- Raw core suite:
  `julia --project=. --startup-file=no test/runtests.jl` passed with
  `4495` pass, `3` broken, `4498` total in 31m04.9s before the final
  docstring/unused-local cleanup.
- Full package test:
  `julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'` passed with
  `4507` pass, `1` broken, `4508` total in 36m15.0s.
- Documentation:
  `julia --project=docs --startup-file=no -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate(); include("docs/make.jl")'`
  completed. Existing absolute-link warnings and local npm audit warnings were
  observed; no build failure.
- Documentation rerun after the changelog edit:
  `julia --project=docs --startup-file=no docs/make.jl` completed with the same
  known warnings and no build failure.
- `git diff --check`: clean.
- Overclaim/stale scan:
  `rg -n "selects variables|automatic deletion|guarantees convergence|proves identifiability|validated item selection|separation solved|nonzero constraint|non-zero constraint|general constraint" README.md docs/src src test`
  returned no matches.

## Status / Next

Ready for a focused Julia PR stacked after the merged R-side `gllvmTMB` PR #536.
CI should verify the same package and Documenter gates on Ubuntu/macOS/Windows.
Do not expand this PR into variable screening, fixed non-zero values, formula
grammar, or broader bridge admission rows.
