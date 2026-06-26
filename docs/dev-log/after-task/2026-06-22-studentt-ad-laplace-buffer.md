# After Task: Student-t PR #113 AD-compatible Laplace buffers

## Goal

Diagnose the draft GLLVM.jl PR #113 CI failure and prepare a local, reviewable
fix candidate without pushing. All four CI jobs failed in the Student-t test
block with a `MethodError: no method matching Float64(::ForwardDiff.Dual...)`
inside the generic dense-Laplace mode finder.

## Root Cause

`_laplace_mode()` in `src/families/laplace.jl` reused per-call Newton buffers
allocated as `Float64`: `z`, `Λz`, `η`, `μ`, `me`, score, Fisher weights, `WΛ`,
`Amat`, and `g`. The Student-t gradient test differentiates
`studentt_marginal_loglik_laplace()` with respect to packed `β`, `Λ`, and
`log σ`; therefore `Λ * z`, the linear predictor, and downstream score/Hessian
entries can be ForwardDiff dual numbers. The failure was a buffer element-type
bug, not a likelihood or tolerance problem.

## Implemented

- Changed `_laplace_mode()` to promote a local buffer element type `T` from the
  response, trial, loading, intercept, and offset element types.
- Allocated the mode, predictor, score, weight, Hessian, and RHS buffers as
  `Vector{T}` / `Matrix{T}`.
- Replaced masked zeros and identity additions with `zero(T)` / `one(T)`.
- Left the Student-t likelihood, fixed degrees-of-freedom design, optimiser,
  and test threshold unchanged.

## Files Changed

- `src/families/laplace.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-22-studentt-ad-laplace-buffer.md`

## Checks Run

```sh
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

Result: clean dependency setup in the scratch worktree; no tracked dependency
files changed.

```sh
julia --project=. test/test_studentt.jl
```

Result: `Student-t (heavy-tailed continuous, fixed ν)` **17/17 pass**. The
ForwardDiff-vs-central-FD marginal gradient check reported max relative error
`6.4151837495491755e-9` against the `1e-6` gate.

```sh
julia --project=. test/runtests.jl
```

Result: started but manually interrupted after the Student-t block had passed
and while the suite was inside the unrelated zero-inflated optimisation block.
This is not reported as a pass.

```sh
julia --project=. -e 'include("test/test_studentt.jl"); include("test/test_missing_predictor_poisson.jl"); include("test/test_beta_laplace.jl"); include("test/test_gamma_laplace.jl")'
```

Result: Student-t `17/17`, missing-predictor Poisson `3/3`,
missing-predictor Binomial `3/3`, Beta Laplace `2/2`, Gamma Laplace `2/2` pass.

## Deliberately Not Run

- Full `Pkg.test()` was not run.
- Full `test/runtests.jl` did not complete locally.
- Documenter was not rebuilt because no docs pages or docstrings changed.
- The patch was not pushed; GLLVM.jl requires explicit maintainer instruction
  before pushing to a PR branch.

## Review Notes

Gauss: the change is numerical plumbing only. It keeps the Fisher-scoring
equations and SPD Newton system intact.

Noether: the symbolic likelihood and Student-t score/weight formulas were not
changed.

Grace: the exact GitHub CI blocker should be rechecked by pushing this candidate
to PR #113 and letting the matrix run.

Rose: pass with notes. The full suite remains unverified locally, so the patch
must not be described as CI-green until GitHub reruns it.
