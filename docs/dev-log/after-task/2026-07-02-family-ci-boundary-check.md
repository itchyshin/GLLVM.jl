# After Task: Family CI Boundary Check

## Goal

Verify the remaining confidence-interval surfaces after the LV/source/bridge
guard work, without changing source code or widening claims.

## Implemented

No implementation changed. This was a verification and evidence-boundary slice:
the focused Gaussian, profile, bootstrap, derived, and transformed-Wald CI tests
were run and recorded, while the broad non-Gaussian family CI bundle was
interrupted after repeating the known slow ZIB bootstrap-refit path.

## Mathematical Contract

The checked CI surfaces retain their existing contracts: Gaussian parameter
intervals use Wald, profile-likelihood, or parametric-bootstrap calibration;
derived bounded quantities use transformed-Wald intervals on Fisher-z/logit
scales where implemented; family CI bootstrap refits simulate from the fitted
model and refit each replicate. This slice did not alter likelihoods,
parameterization, or interval formulas.

## Files Changed

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-family-ci-boundary-check.md`

## Tests Added

None. Existing focused tests were used as boundary checks.

Tests-of-tests clause: existing tests include truth-bracketing fixtures,
deterministic bootstrap checks, bounded-transform checks, malformed-transform
errors, and public-accessor equivalence checks.

## Verification

```sh
julia --project=. --startup-file=no test/test_confint.jl
# confint | 14 pass

julia --project=. --startup-file=no test/test_confint_profile.jl
# profile CI | 4 pass

julia --project=. --startup-file=no test/test_confint_bootstrap.jl
# parametric bootstrap CI | 9 pass

julia --project=. --startup-file=no test/test_confint_derived_wald.jl
# transformed-Wald CIs for derived bounded quantities | 115 pass

julia --project=. --startup-file=no test/test_confint_derived.jl
# derived-quantity CIs | 45 pass

julia --project=. --startup-file=no test/test_confint_family.jl
# interrupted; not counted as passing
```

The repeated `test/test_confint_family.jl` interrupt landed in the
zero-inflated-binomial bootstrap-refit path:

```text
src/families/twopart.jl:1018 zib_marginal_loglik_laplace
src/families/twopart.jl:1102 fit_zib_gllvm
src/confint_family.jl:1260 ZIB refit
src/confint_family.jl:1572 threaded bootstrap loop
```

Allocation count before the interrupt was `1,505,014,869`, so this broad test is
not a practical focused gate in the current shape.

## Benchmark Numbers

N/A - no hot-path implementation changed. The broad family CI run exposed a
test-cost boundary rather than a benchmarked optimization.

## R-Parity Verdict

Parity: N/A - this slice did not touch Gaussian marginal likelihood, profile,
init, fitter, or CI implementation.

## JET / Allocs / Aqua Verdicts

- JET: not run - no source change.
- Allocs: not run as a benchmark - interrupted broad family CI reported
  `1,505,014,869` allocations before Ctrl-C.
- Aqua: not run - no dependency, export, or Project.toml change.

## Remaining Risks

- The broad non-Gaussian family CI bundle remains too slow/noisy to use as a
  nightly focused gate.
- ZIB bootstrap refits need a separate cost-control slice before the full family
  CI file can be treated as green evidence.
- These results do not alter the phylo Model A weak-cell conclusion; bootstrap
  rescue remains retired for that route.

## Next Command

```sh
git diff --check -- docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-02-family-ci-boundary-check.md
```

Rose verdict: PASS WITH NOTES - focused CI surfaces are green, but broad
non-Gaussian family CI bootstrap remains a documented cost boundary.
