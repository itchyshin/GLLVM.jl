# After-task audit: augmented phylogenetic Poisson Laplace prototype

Date: 2026-06-03

## Goal

Move the phylogenetic non-Gaussian benchmark off the dense tip-precision
shortcut by adding an internal Poisson Laplace route that uses the augmented
tree precision directly, and make the benchmark capable of estimating the
scalar phylogenetic variance for `gllvmTMB` smoke comparison.

## Files changed

- `src/families/structured_poisson.jl`
  - Added internal `_phylo_poisson_*` helpers, root-dropped augmented precision
    mapping, leaf-only Poisson score/weight evaluation, dense/CG mode solve,
    Laplace value, and finite-difference `_fit_phylo_poisson_laplace`.
- `test/test_structured_poisson_laplace.jl`
  - Added augmented-tree fixed-sigma equivalence, dense-vs-CG, scalar-variance
    fitter smoke, and malformed-input tests.
- `bench/phylo_poisson_gllvmtmb_bench.jl`
  - Retargeted `bm-tree` to the augmented-tree Julia path.
  - Kept `ar1-sparse` on the structured precision proxy route.
  - Added `--estimate-julia-sigma2`.
- `bench/results/phylo-poisson-augmented-smoke.csv`
- `bench/results/phylo-poisson-augmented-estimate-smoke.csv`
- `bench/results/phylo-poisson-augmented-estimate-smoke-100.csv`
- `docs/dev-log/check-log.md`

## Tests added

New testset: `augmented phylogenetic Poisson Laplace prototype`.

Assertions:

- augmented-tree Laplace value matches dense tip-precision structured Poisson
  at fixed `sigma2`;
- dense and CG mode solves agree;
- scalar-variance finite-difference fitter returns finite positive `sigma2`
  and does not reduce the likelihood;
- dimension and argument guards throw.

## Commands and results

```sh
julia --project=. test/test_structured_poisson_laplace.jl
```

Result: all structured Poisson tests passed; new augmented testset `15/15`
passed.

```sh
julia --project=. test/runtests.jl
```

Result: exit code 0. Direct core run passed; the quality block kept the usual
Aqua/JET placeholders broken because those packages are only loaded by
`Pkg.test()`.

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

## Benchmark numbers

Fixed-sigma smoke:

```sh
julia --project=. bench/phylo_poisson_gllvmtmb_bench.jl --smoke --structures=bm-tree --iterations=25 --warmups=1 --reps=1 --out=bench/results/phylo-poisson-augmented-smoke.csv
```

```text
julia-cg 0.022220625 s, loglik -62.24416145604612, fixed_sigma2=0.35
gllvmTMB 0.462 s, loglik -58.7028024325027
speed ratio r/cg 20.7915x
```

Scalar-variance smoke:

```sh
julia --project=. bench/phylo_poisson_gllvmtmb_bench.jl --smoke --structures=bm-tree --estimate-julia-sigma2 --iterations=100 --warmups=1 --reps=1 --out=bench/results/phylo-poisson-augmented-estimate-smoke-100.csv
```

```text
julia-cg 0.069024792 s, loglik -58.70280243238997, estimated_sigma2=1.6093182946555366e-10
gllvmTMB 0.426 s, loglik -58.7028024325027
speed ratio r/cg 6.1717x
```

## R parity verdict

Smoke parity is now plausible for the tiny `bm-tree` Poisson cell when Julia
also estimates scalar `sigma2`: log-likelihoods match R `gllvmTMB` to roundoff
on the 100-iteration smoke run.

This is not yet a public parity claim. The current Julia scalar-variance route
uses finite-difference outer gradients and has only smoke-scale evidence.

Cross-project tracking issue #13 was updated:
<https://github.com/itchyshin/GLLVM.jl/issues/13#issuecomment-4610093863>.

## JET / Allocs / Aqua verdicts

- Aqua: passed through `Pkg.test()` quality block.
- JET: passed through `Pkg.test()` quality block.
- Allocs: no separate Allocs.jl gate was run for this finite-difference
  prototype. The route remains internal until analytic gradients and Workflow Q
  are complete.

## Rose audit verdict

OK for internal prototype and benchmark harness update.

Blockers before public promotion:

- analytic outer gradient for scalar phylogenetic variance;
- ADEMP recovery test against known data-generating parameters;
- Workflow Q multi-shape checks, including balanced and caterpillar trees;
- larger sequential benchmark rerun against `gllvmTMB`;
- user-facing docs only after the above pass.

## Remaining risks

- The scalar-variance fitter is finite-difference and slower than the intended
  analytic path.
- The current benchmark smoke cell is tiny; it verifies wiring and parity shape
  but not scaling.
- Fixed-sigma speed rows are useful for algorithm timing but not likelihood
  parity against R, because R estimates the scalar variance.

## Next command

```sh
julia --project=. bench/phylo_poisson_gllvmtmb_bench.jl --full --structures=bm-tree --estimate-julia-sigma2 --warmups=1 --reps=3 --out=bench/results/phylo-poisson-augmented-estimate-full.csv
```
