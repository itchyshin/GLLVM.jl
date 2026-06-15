# After-task - High-rate Poisson mode safeguard (#91)

## Goal

Reproduce and fix GLLVM.jl #91 on the integration branch: high-rate Poisson
`K >= 2` fits could drive one intercept far from the empirical log-mean scale
while still reporting optimizer convergence.

## Files Changed

- `src/families/laplace.jl`
- `test/test_poisson_fit.jl`
- `docs/dev-log/check-log.md`

## What Changed

The shared dense-Laplace mode solve now uses a safeguarded Fisher-scoring step
for cheap scalar families (`Poisson`, `Binomial`, `NegativeBinomial`, `Beta`,
`Gamma`, `Exponential`):

- full Newton steps are retained near the mode;
- larger steps are accepted only if they do not lower the conditional
  log-posterior;
- non-finite solves restart once from `z = 0`;
- heavier bespoke families keep the previous full-step path.

The new Poisson regression fixture reconstructs the #91 high-rate cell and
checks both fitted intercept scale and analytic-gradient correctness against a
central finite-difference gradient.

## Reproduction Evidence

Before the fix, the integration branch reproduced #91 with the reconstructed
seed-7002 / seed-70021 high-rate fixture:

```text
analytic_beta6 = -1.3725979588255058e6
beta06 = 2.046028486073364
analytic_maxabs = 1.3726000048539918e6
```

After the fix, three plausible draw-order variants stayed on scale:

```text
allZ_col beta6 = 1.8845273881056652, maxabs = 0.16150109796769874
interleaved_site beta6 = 1.9494694468357439, maxabs = 0.16824427830738942
global_seed_interleaved beta6 = 1.9931572688527104, maxabs = 0.1454864444226014
```

High-rate warm-start gradient evidence:

```text
maxabsdiff(analytic, finite_difference) = 1.0488242692119343e-6
diff norm = 2.2149188558598164e-6
```

## Checks Run

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_poisson_fit.jl
```

Result: `12/12 pass`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_poisson_laplace.jl
```

Result: `4/4 pass`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_laplace_grad.jl
```

Result: `26/26 pass`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_missing_response.jl
```

Result: `23/23 pass`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no -e 'using GLLVM, Test, Distributions, LinearAlgebra, Random; include("test/test_laplace_alloc_equiv.jl")'
```

Result: `7/7 pass`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_binomial_fit.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_nb_fit.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_beta_fit.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_gamma_fit.jl
```

Results: Binomial `8/8`, NB `7/7`, Beta `7/7`, Gamma `7/7` pass.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_beta_laplace.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_gamma_laplace.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_negbin_laplace.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_binomial_laplace.jl
```

Results: Beta `2/2`, Gamma `2/2`, NB `2/2`, Binomial `9/9` pass.

## Not Run / Interrupted

`test/test_missing_response_extra.jl` was started twice and interrupted after
several minutes. The interrupt stack was in long finite-difference fits for
Tweedie / row-effect wrappers, not the new safeguarded scalar-family branch.

Full `test/runtests.jl`, full `Pkg.test()`, and Documenter were not run for this
integration-branch patch yet.

## R-Parity Verdict

Not run. This is a Julia-engine numerical safeguard; R bridge parity is not
changed directly.

## JET / Allocs / Aqua Verdict

Not run. `test/test_laplace_alloc_equiv.jl` passed, but the full quality battery
is still pending.

## Rose Verdict

PASS WITH NOTES. The #91 failure is reproduced, fixed, and guarded by a
fit-scale regression plus analytic-vs-FD gradient evidence. This is not release
ready until full-suite and quality gates pass.

## Next Command

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/runtests.jl
```
