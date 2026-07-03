# After Task: R + Julia v1 Gaussian fixed-effect X bridge

## Goal

Route Gaussian fixed-effect `X` point fits and selected Gaussian `X` CI payloads
through the local Julia bridge, while keeping non-Gaussian `X` rows fail-loud.

## Implemented

`bridge_fit(..., family = "gaussian", X = X)` now validates a
`p x n_sites x q` covariate array, passes it to `fit_gaussian_gllvm`, returns a
plain `mean_coef` payload, routes scores through `getLV(...; X = X)`, and
forwards the same `X` to Gaussian Wald/profile/bootstrap CI helpers. The
capability ledger marks `fixed_effect_X` and `ci_x_*` true for Gaussian only.
Every non-Gaussian family still throws on non-`nothing` `X`.

## Mathematical Contract

For the admitted Gaussian row, the fitted mean is
`mu[t, s] = sum_k X[t, s, k] beta[k]`, with the existing Gaussian GLLVM site
covariance and latent score reconstruction. No likelihood parameterisation,
loading orientation, or source-specific structural LV estimand changed.

## Files Changed

- `src/bridge.jl`
- `test/test_bridge_capabilities.jl`
- `test/test_bridge_fit.jl`
- `docs/dev-log/v1-contract/r-julia-v1-capability-matrix.md`
- `docs/dev-log/v1-contract/2026-07-03-bridge-drift-gates.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-03-r-julia-v1-gaussian-x-bridge.md`

## Tests Added

- `test/test_bridge_capabilities.jl`: real Gaussian `X` fit, selected
  Wald/profile/bootstrap CI payloads, and non-Gaussian `X` rejection. This
  exercises both success and failure-path clauses.
- `test/test_bridge_fit.jl`: Gaussian `X` bridge parity against direct
  `fit_gaussian_gllvm(...; X = X)` and direct `confint(...; X = X)`.

## Benchmark Numbers

N/A -- no hot likelihood path was changed. The slice wires an already-existing
Gaussian `X` engine path through the flat bridge.

## R-Parity Verdict

Within the current bridge contract: paired `gllvmTMB` live capability tests now
observe 57 registered drift rows, zero unregistered rows, and no Gaussian
`fixed_effect_X` / `ci_x_*` drift rows. This is not full R/Julia parity; R still
advertises selected non-Gaussian `X` rows that the local Julia bridge keeps
gated.

## JET / Allocs / Aqua Verdicts

- JET: not run -- bridge payload plumbing only; focused tests cover the changed
  behavior.
- Allocs: not run -- no hot loop or allocation-budgeted kernel changed.
- Aqua: not run -- no exports, dependencies, or Project.toml changes.

## Checks Run

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_capabilities.jl
# 90 passed, 0 failed

/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_fit.jl
# 193 passed, 0 failed

GLLVM_JL_PATH='/Users/z3437171/Dropbox/Github Local/GLLVM.jl' JULIA_HOME='/Users/z3437171/.juliaup/bin' Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge-live-capabilities.R")'
# 24 passed, 0 failed

Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge.R")'
# 410 passed, 14 expected live-GLLVM-path skips, 0 failed
```

Live drift printout:

```text
drift_rows=57
unregistered=0
```

## Consistency Audit

Scans run before commit:

```sh
rg -n "fixed-effect X.*local Julia rejects|local Julia has no X|61 registered|current.*61|ci_x_.*false" docs/dev-log/v1-contract docs/dev-log/check-log.md src/bridge.jl test/test_bridge_capabilities.jl test/test_bridge_fit.jl
rg -n "source-specific.*support|ready to expose|v1.0 complete|mixed-family CI|coverage calibration" docs/dev-log/v1-contract docs/dev-log/check-log.md src/bridge.jl
git diff --check -- src/bridge.jl test/test_bridge_capabilities.jl test/test_bridge_fit.jl docs/dev-log/v1-contract/r-julia-v1-capability-matrix.md docs/dev-log/v1-contract/2026-07-03-bridge-drift-gates.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-03-r-julia-v1-gaussian-x-bridge.md
```

Result: no diff whitespace errors. The first scan found only expected
historical 61-row references in earlier cbind entries. The second scan found
only explicit non-claims and remaining-gate wording; no ready-to-expose or
v1.0-complete wording was introduced.

## GitHub Issue Maintenance

No issue action was taken. This is a local v1 contract drift-reduction slice;
no push or PR was authorized.

## What Did Not Go Smoothly

The first Julia smoke used `julia` on PATH, but this shell does not expose it;
the verified command uses `/Users/z3437171/.juliaup/bin/julia`. Gaussian
bootstrap selection also uses the existing `parms` keyword, not `parm`, so the
bridge maps `ci_parm` to native `parms`.

## Team Learning

Hopper should continue reducing the bridge matrix row by row and keep the R
ledger clearly separated from the live local Julia surface.

## Remaining Risks

- Non-Gaussian `X` rows remain live drift.
- Response masks, mask+X, mixed-family vectors/CIs, source-specific `lv`, and
  `unique=` parity remain gated.
- Bootstrap is routed for Gaussian but remains secondary evidence, not coverage
  calibration.

## Known Limitations

This slice does not add non-Gaussian fixed-effect covariates, new model
semantics, source-specific structural LV syntax, mixed-family support, or any
public v1.0 completion claim.

## Next Command

```sh
GLLVM_JL_PATH='/Users/z3437171/Dropbox/Github Local/GLLVM.jl' JULIA_HOME='/Users/z3437171/.juliaup/bin' Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge-live-capabilities.R")'
```

## Rose Verdict

Rose verdict: PASS WITH NOTES -- Gaussian `X` bridge truth is now implemented
and tested; remaining LV/bridge parity rows are still gated and must not be
described as finished.
