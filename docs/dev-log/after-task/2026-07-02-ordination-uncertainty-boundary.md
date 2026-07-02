# After Task: Ordination Uncertainty Boundary

## Goal

Expose the tested ordination-score uncertainty route in user-facing docs while
keeping its scope clear: fixed-parameter, conditional score uncertainty, not full
refit-level parameter uncertainty.

## Implemented

- Added a short `ordination_uncertainty` section to `docs/src/working-with-a-fit.md`.
- Documented the returned `scores`, `lower`, and `upper` matrices.
- Stated that the fitted parameters are held fixed and that the route is limited
  to single-`Y` one-part non-Gaussian ordination fits with scalar response means.

## Mathematical Contract

N/A - no likelihood, score, bootstrap, or plotting behavior changed.

## Files Changed

docs:

- `docs/src/working-with-a-fit.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-ordination-uncertainty-boundary.md`

## Tests Added

None.

## Benchmark Numbers

N/A.

## R-Parity Verdict

No R bridge claim. This is a Julia post-fit documentation boundary.

## JET / Allocs / Aqua Verdicts

- JET: not run.
- Allocs: not run.
- Aqua: not run.

## Checks Run

```sh
julia --project=. --startup-file=no test/test_ordination_uncertainty.jl
# ordination types: run + recover structure | 16 pass
# ordination_uncertainty: per-site score intervals | 20 pass

julia --project=docs --startup-file=no docs/make.jl
# completed successfully; emitted pre-existing local-link warnings and npm audit warnings

rg -n 'ordination_uncertainty|conditional bootstrap|fitted parameters held fixed|full refit-level parameter uncertainty|Poisson, NB2, Beta, Gamma|score intervals' docs/src/working-with-a-fit.md docs/src/tutorial.md docs/src/gllvmtmb-parity.md README.md
# only the new bounded working-with-a-fit wording appears

git diff --check -- docs/src/working-with-a-fit.md
# clean, no output
```

## Consistency Audit

The docs now say explicitly that `ordination_uncertainty` is conditional on the
fitted parameters and applies to Poisson, NB2, Beta, Gamma, Exponential, and
Binomial single-`Y` ordination fits. It is not described as full parameter
uncertainty or source-specific LV support.

## GitHub Issue Maintenance

No issue or PR action taken.

## What Did Not Go Smoothly

Nothing material.

## Team Learning

Florence: biplot intervals need a clear target. Fisher: fixed-parameter score
uncertainty must not be presented as refit-level parameter uncertainty.

## Remaining Risks

- Full `Pkg.test()` is still not available from tonight's run.
- The docs build still emits pre-existing local-link warnings unrelated to this
  slice.

## Known Limitations

This is documentation-only.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && julia --project=. --startup-file=no test/test_unified_api.jl
```

## Rose Verdict

Rose verdict: OK. The new user-facing wording is bounded and matches the focused
test contract.
