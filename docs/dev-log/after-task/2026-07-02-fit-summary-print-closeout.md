# After Task: Fit Summary/Print Capability Closeout

## Goal

Close one bounded post-fit capability lane after LV closeout by adding explicit
`summary(fit)` support and phylogenetic Gaussian rich display, without touching
likelihoods, formula grammar, source-specific `lv`, bridge parity claims, or
compute runs.

## Implemented

- Added compact `Base.summary` methods for `GllvmFit`, `PhyloGaussianFit`,
  one-part non-Gaussian fit objects, and two-part fit objects.
- Added `text/plain` display for `PhyloGaussianFit`.
- Updated the fit-working docs to show `summary(fit)` alongside rich REPL
  display.
- Added focused summary/display assertions to existing post-fit, two-part, and
  phylogenetic Gaussian tests.

## Mathematical Contract

N/A - display and summary plumbing only. No likelihood, parameterization,
interval, or structural-dependence model changed.

## Files Changed

- `src/postfit.jl`
- `test/test_postfit.jl`
- `test/test_delta_postfit.jl`
- `test/test_hurdle_poisson.jl`
- `test/test_hurdle_nb.jl`
- `test/test_fit_phylo.jl`
- `docs/src/working-with-a-fit.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-fit-summary-print-closeout.md`

## Tests Added

Summary/display assertions were added to existing testsets for Gaussian,
phylogenetic Gaussian, Binomial, Poisson, Negative Binomial, Beta, Gamma,
Ordinal, Delta-lognormal, Hurdle-Poisson, and Hurdle-NB fits.

## Benchmark Numbers

N/A - no hot path or compute path changed.

## R-Parity Verdict

Parity: N/A - this slice changes Julia-side display only and does not change the
R bridge contract.

## JET / Allocs / Aqua Verdicts

- JET: covered through `Pkg.test()` quality gate.
- Aqua: covered through `Pkg.test()` quality gate.
- Allocs: not run separately; no hot path changed.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'using GLLVM; println(summary(PhyloGaussianFit(0.1, 1.2, 0.3, 4.5, true, 7)))'
julia --project=. --startup-file=no test/test_postfit.jl
julia --project=. --startup-file=no test/test_delta_postfit.jl
julia --project=. --startup-file=no test/test_hurdle_poisson.jl
julia --project=. --startup-file=no test/test_hurdle_nb.jl
julia --project=. --startup-file=no test/test_fit_phylo.jl
julia --project=. --startup-file=no test/runtests.jl
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
julia --project=docs --startup-file=no docs/make.jl
git diff --check
rg -n "source-specific|phylo_latent|lv\\s*=\\s*~|partial support|ready to scale|active compute|PR #127|Model A|B_lv|alpha_lv" src test docs/src docs/dev-log/check-log.md docs/dev-log/after-task --glob '!docs/build/**' --glob '!docs/node_modules/**'
```

Results:

- Focused tests all passed.
- `test/runtests.jl` exited 0 with known broken placeholders only in the direct
  core environment.
- `Pkg.test()` exited 0; quality 12/12 passed and package tests printed
  `Testing GLLVM tests passed`.
- `docs/make.jl` exited 0; local Documenter/Vitepress build completed. Existing
  npm audit warnings did not fail the build.
- `git diff --check` was clean.
- Claim audit found only this slice's boundary text and an existing internal
  likelihood comment; no source-specific `lv` exposure or active compute claim
  was added.

## Consistency Audit

The change stays within display/post-fit plumbing. It does not promote phylo
Model A, does not change source-specific LV grammar, and does not introduce new
R parity language.

## GitHub Issue Maintenance

No GitHub issue or PR was modified.

## What Did Not Go Smoothly

The first check-log insertion matched an earlier repeated audit anchor; it was
removed and re-added at the true end of the check-log.

## Team Learning

For long check-log files with repeated audit anchors, append against a unique
section-specific line rather than a repeated final bullet.

## Remaining Risks

- `summary(fit)` is intentionally compact; detailed fit tables remain future
  formula/covariate-front-end work.
- Existing direct-core broken placeholders remain unrelated to this slice.

## Known Limitations

No new model capability, source-specific LV support, or bridge parity surface
was added.

## Next Command

```sh
git status --short
```

## Rose Verdict

Rose verdict: PASS - evidence supports this as a bounded summary/print
capability closeout with no overclaiming about phylo Model A, source-specific
LV grammar, or R parity.
