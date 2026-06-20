# Bridge method capability metadata

Date: 2026-06-15

## Goal

Expose enough Julia-side bridge metadata for the R-first `gllvmTMB` ledger to
verify method-level bridge claims, not only fit admission.

## Files Changed

- `src/bridge.jl`
- `test/test_bridge_capabilities.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-15-bridge-method-capability-metadata.md`

## What Changed

`bridge_capabilities()` now reports:

- `ci_no_x_wald`
- `ci_no_x_profile`
- `ci_no_x_bootstrap`
- `postfit_coef`
- `postfit_fit_stats`
- `postfit_summary`
- `postfit_predict`
- `postfit_residuals`
- `postfit_simulate`
- `postfit_ordination`

The CI columns are explicitly scoped to complete one-part no-covariate fits.
Mixed-family, masked-response, and non-Gaussian-X intervals remain outside this
metadata claim.

## Tests

```sh
~/.juliaup/bin/julia --project=. -e 'using GLLVM; caps=GLLVM.bridge_capabilities(); @assert :ci_no_x_wald in propertynames(caps); @assert :postfit_predict in propertynames(caps); println(length(caps.family), " capability rows")'
```

Result: `10 capability rows`.

```sh
~/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: `19/19 pass` in `0.2s`.

Paired R bridge test:

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'
```

Result in `gllvmTMB`: `FAIL 0 | WARN 0 | SKIP 0 | PASS 519` in `68.9s`.

## Rose Verdict

PASS WITH NOTES. This is a metadata and test-surface update only. It does not
change estimates, log-likelihoods, CIs, REML, or optimizer behavior. REML remains
Gaussian-only; AI-REML remains a future exact-Gaussian speed target, not a
non-Gaussian claim.
