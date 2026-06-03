# After-task audit: augmented Poisson log-sigma gradient check

Date: 2026-06-03

## Goal

Add the first analytic scalar-variance derivative target for the internal
augmented-tree phylogenetic Poisson path: `d loglik / d log(sigma2)` at fixed
`β` and `Λ`.

## Files changed

- `src/families/structured_poisson.jl`
  - Added `_phylo_poisson_hessian_inverse_dense`.
  - Added `_phylo_poisson_logsigma2_value_grad_dense`.
- `test/test_structured_poisson_laplace.jl`
  - Added central finite-difference verification against
    `_phylo_poisson_marginal_loglik_laplace`.
- `docs/dev-log/check-log.md`

## Tests added

The existing augmented phylogenetic Poisson testset now checks that the dense
analytic `log(sigma2)` derivative matches a central finite difference to
`1e-5`.

## Commands and results

```sh
julia --project=. test/test_structured_poisson_laplace.jl
```

Result:

```text
augmented phylogenetic Poisson Laplace prototype | 17/17 pass
```

```sh
julia --project=. test/runtests.jl
```

Result: exit code 0; no failures. The direct core runner keeps the usual
Aqua/JET placeholders broken because the full quality environment is loaded by
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

No new benchmark was run for this derivative-only slice. The helper
materializes the full dense Hessian inverse and is meant as a correctness
target, not a speed path.

## R parity verdict

No new R comparison. This slice strengthens the Julia scalar-variance
derivative needed for the next R-parity-capable fitter but does not change the
R smoke benchmark numbers.

## JET / Allocs / Aqua verdicts

- Aqua: passed through `Pkg.test()`.
- JET: passed through `Pkg.test()`.
- Allocs: not run separately. The helper is explicitly dense and small-cell
  only.

## Rose audit verdict

PASS WITH NOTES. The derivative check is correct on the focused fixture and is
safe to keep internal. It is not the final scalable optimizer gradient.

## Remaining risks

- The helper forms `H^{-1}` densely and should not be used for large-`p`
  Workflow Q.
- The outer fitter still uses finite differences for `β`, `Λ`, and
  `log(sigma2)`.
- The scalable next step is to reuse Schur/Woodbury traces instead of dense
  inverse materialization.

## Next command

```sh
julia --project=. test/test_structured_poisson_laplace.jl
```
