# After Task: ZIB/Tweedie Postfit Doc Boundary

## Goal

Continue the post-LV capability cleanup by aligning the public post-fit and
response-family docs with the tested ZIB, Tweedie, beta-hurdle, ordered-beta,
and public `simulate` boundaries.

## Implemented

- Added omitted `fit_beta_hurdle_gllvm`, `fit_zib_gllvm`, and
  `fit_ordered_beta_gllvm` examples to the response-family two-part/mixture
  section.
- Narrowed the parity table's public `simulate` row from broad "non-Gaussian" to
  selected scalar-mean GLM-style, Tweedie, and covariate fits.
- Tightened the tutorial's `simulate` wording to match the implemented public
  methods.

## Mathematical Contract

N/A - no likelihood, optimiser, post-fit method, or sampler changed.

## Files Changed

docs:

- `docs/src/gllvmtmb-parity.md`
- `docs/src/response-families.md`
- `docs/src/tutorial.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-zib-tweedie-postfit-doc-boundary.md`

## Tests Added

None.

## Benchmark Numbers

N/A.

## R-Parity Verdict

No new R bridge claim. The changed wording keeps public `simulate` narrower than
the internal two-part bootstrap-CI samplers.

## JET / Allocs / Aqua Verdicts

- JET: not run.
- Allocs: not run.
- Aqua: not run.

## Checks Run

```sh
julia --project=. --startup-file=no test/test_postfit_zib_tweedie.jl
# ZIB post-fit (zero-inflated binomial) | 17 pass
# Tweedie post-fit (compound Poisson-Gamma) | 20 pass

julia --project=. --startup-file=no test/test_beta_hurdle.jl
# beta-hurdle GLLVM | 53 pass

julia --project=. --startup-file=no test/test_ordered_beta.jl
# Ordered-beta family | 21 pass

julia --project=docs --startup-file=no docs/make.jl
# completed successfully; emitted pre-existing local-link warnings and npm audit warnings

rg -n 'simulate\\(fit, n\\).*GLM \\+ covariate|✅ non-Gaussian \\| `simulate|from a fitted model \\(useful|fit_zib_gllvm\\(Y;.*K = 2\\)|fit_beta_hurdle_gllvm|fit_ordered_beta_gllvm|selected non-Gaussian|public `simulate` methods are not universal' docs/src README.md
# only intentional current docs hits remain

git diff --check -- docs/src/gllvmtmb-parity.md docs/src/tutorial.md docs/src/response-families.md
# clean, no output
```

## Consistency Audit

The docs now expose the implemented family examples without implying universal
public `simulate` coverage for every two-part fit. ZIB/Tweedie post-fit remains
backed by focused tests; two-part public simulation remains a separate method
surface.

## GitHub Issue Maintenance

No issue or PR action taken.

## What Did Not Go Smoothly

The first stale-phrase search failed because of shell quoting around backticks;
it was rerun with single quotes.

## Team Learning

Rose: a family can have internal simulation for bootstrap CI without having a
public `simulate(fit, ...)` method. Hopper: parity tables should say selected
rows when method dispatch is not universal.

## Remaining Risks

- Full `Pkg.test()` is still not available from tonight's run.
- The docs build still emits pre-existing local-link warnings unrelated to this
  slice.

## Known Limitations

This is documentation-only.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && julia --project=. --startup-file=no test/test_summary_table.jl
```

## Rose Verdict

Rose verdict: OK for this slice. The changed wording is narrower and better
aligned with the implemented public methods.
