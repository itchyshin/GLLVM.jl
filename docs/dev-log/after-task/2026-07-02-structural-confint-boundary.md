# After Task: Structural Confint Boundary

## Goal

Continue the structural-model portion of the LV/post-LV goal by verifying the
structural confidence-interval surface and correcting tutorial wording that
overstated bootstrap availability.

## Implemented

- Updated the tutorial inference section so all-three-method support is limited
  to the rows that actually have Wald/profile/bootstrap routes.
- Documented that `QuadraticFit` and `RowEffectFit` have Wald/profile intervals
  but no bootstrap route.
- Documented that species-covariate, fourth-corner, RRR, and constrained
  ordination fits use dedicated Wald helpers because their designs are not stored
  in the fit object.

## Mathematical Contract

N/A - no likelihood, interval calculation, or method dispatch changed.

## Files Changed

docs:

- `docs/src/tutorial.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-structural-confint-boundary.md`

## Tests Added

None.

## Benchmark Numbers

N/A.

## R-Parity Verdict

No new R bridge claim. This is a Julia documentation boundary correction.

## JET / Allocs / Aqua Verdicts

- JET: not run.
- Allocs: not run.
- Aqua: not run.

## Checks Run

```sh
julia --project=. --startup-file=no test/test_structural_confint.jl
# Structural-model inference tables | 45 pass

julia --project=docs --startup-file=no docs/make.jl
# completed successfully; emitted pre-existing local-link warnings and npm audit warnings

rg -n 'All three methods accept.*RowEffectFit|GllvmCovFit`, `RowEffectFit|bootstrap route|dedicated Wald helpers|QuadraticFit.*RowEffectFit' docs/src/tutorial.md docs/src/confidence-intervals.md docs/src/gllvmtmb-parity.md
# only the new structural boundary wording remains

git diff --check -- docs/src/tutorial.md
# clean, no output
```

## Consistency Audit

The tutorial now matches `src/confint_family.jl`: structural adapters for
quadratic and row-effect fits have bootstrap stubs that intentionally error,
while design-dependent structural models use dedicated Wald helpers.

## GitHub Issue Maintenance

No issue or PR action taken.

## What Did Not Go Smoothly

Nothing material.

## Team Learning

Rose: "all three methods" is too strong unless bootstrap dispatch is proven.
Curie: focused structural tests are enough for this claim-boundary slice.

## Remaining Risks

- Full `Pkg.test()` is still not available from tonight's run.
- The docs build still emits pre-existing local-link warnings unrelated to this
  slice.

## Known Limitations

This is documentation-only.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && julia --project=. --startup-file=no test/test_ordination_uncertainty.jl
```

## Rose Verdict

Rose verdict: OK. The public structural-inference wording is now narrower and
matches the tested method boundary.
