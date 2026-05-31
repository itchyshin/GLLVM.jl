# After Task: Non-Gaussian ForwardDiff Gradients

Superseded note (later 2026-05-31): this slice was immediately followed by the
implicit dense-Laplace gradient slice, which keeps ForwardDiff as the gradient
oracle but no longer differentiates through the inner Fisher-scoring iterations
inside the fitters.

## Goal

Remove Optim finite-difference gradients from the implemented non-Gaussian
fitters, verify their packed-objective gradients against finite differences,
and add a reproducible GLLVM.jl vs R `gllvmTMB` benchmark driver.

## Implemented

The six non-Gaussian fitters now call `Optim.optimize(...; autodiff = :forward)`.
The shared dense Laplace accumulator and ordinal Laplace mode/loglik scratch
arrays now preserve the element type flowing through the objective, so
ForwardDiff Dual values reach the dense `\` and `logdet` path. Objective penalty
returns use `oftype` to avoid dropping Dual values on guarded failure paths.

## Mathematical Contract

For each site `s`, the non-Gaussian marginal remains the existing dense Laplace
approximation

```text
log p(y_s | θ) ≈ ℓ(y_s | zhat_s, θ) - 0.5 zhat_s'zhat_s
                - 0.5 logdet(I + Λ'W_sΛ),
```

where `zhat_s` is found by the existing Fisher-scoring mode equation. This
slice changes the outer optimizer gradient source from Optim's finite
differences to ForwardDiff through the same objective; it does not change the
likelihood parameterisation or public API. The implicit/envelope gradient
remains a future lane if ForwardDiff stops winning at larger cells.

## Files Changed

- `src/families/binomial.jl`
- `src/families/poisson.jl`
- `src/families/negbin.jl`
- `src/families/beta.jl`
- `src/families/gamma.jl`
- `src/families/ordinal.jl`
- `src/families/laplace.jl`
- `test/test_family_forwarddiff_gradients.jl`
- `test/runtests.jl`
- `bench/non_gaussian_gllvmtmb_bench.jl`
- `bench/README.md`
- `CLAUDE.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-31-non-gaussian-forwarddiff-gradients.md`

No edits were made to `src/sparse_phy_grad.jl` or `src/em_phylo.jl`.

## Tests

- `julia --project=. --startup-file=no -e 'include("test/test_family_forwarddiff_gradients.jl")'`
  passed: 18/18.
- `julia --project=. --startup-file=no test/runtests.jl` exited 0. The direct
  core environment reported the expected Aqua/JET placeholders as broken.
- `julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'` passed. Manual
  tally from emitted summaries: 1750 pass, 1 existing broken sparse-phy
  precision check, 0 fail, 0 error.

The new test compares `ForwardDiff.gradient` to a central finite-difference
gradient for binomial, Poisson, negative-binomial, Beta, Gamma, and ordinal
packed objectives with a ≤ 1e-6 gate.

## Benchmarks

Before/after Julia smoke, p = 5, n = 60, K = 1, 6 L-BFGS iterations:

| family | finite diff (s) | ForwardDiff (s) | speedup |
| --- | ---: | ---: | ---: |
| binomial | 0.0916 | 0.0049 | 18.7x |
| poisson | 0.0696 | 0.0052 | 13.4x |
| negative-binomial | 0.0808 | 0.0093 | 8.7x |
| beta | 0.0896 | 0.0148 | 6.1x |
| gamma | 0.0926 | 0.0131 | 7.1x |
| ordinal | 0.0514 | 0.0105 | 4.9x |

R-vs-Julia warmed smoke used R 4.5.2 and `gllvmTMB` 0.2.0:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --smoke --iterations=80 --reps=1 --warmups=1
```

| family | Julia (s) | gllvmTMB (s) | R / Julia | agreement |
| --- | ---: | ---: | ---: | --- |
| gaussian | 0.0003 | 0.5120 | 1640.6x | logLik comparable, abs delta = 5.38e-9 |
| binomial | 0.0142 | 0.5150 | 36.2x | logLik comparable, abs delta = 3.61e-9 |
| poisson | 0.0339 | 0.5060 | 14.9x | logLik comparable, abs delta = 3.10e-9 |
| negative-binomial | 0.0195 | 0.6400 | 32.9x | parameterisation audit needed |
| beta | 0.0331 | 0.6100 | 18.4x | parameterisation audit needed |
| gamma | 0.0219 | 0.5070 | 23.1x | parameterisation audit needed |
| ordinal | 0.1083 | 0.5570 | 5.1x | non-equivalent link |

The full small/medium/large grid is implemented behind `--full` but was not run
in this slice.

## R-Parity Verdict

Parity smoke is clean for Gaussian, binomial, and Poisson on the p = 5, n = 60,
K = 1 cell, with absolute log-likelihood differences around 1e-9. Negative
binomial, Beta, and Gamma are deliberately marked
`same_data_parameterization_audit_needed` in the benchmark output until the
R-side dispersion conventions and parameter counts are pinned down. Ordinal is
marked `non_equivalent_link` because GLLVM.jl is cumulative-logit while
`gllvmTMB` exposes `ordinal_probit()`.

## JET / Allocs / Aqua

JET: clean through `Pkg.test()` quality block.

Aqua: clean through `Pkg.test()` quality block.

Allocs: not run; `Allocs` is not installed in the active project. This remains
a Phase 1.3 quality-battery follow-up rather than a blocker for this gradient
slice.

## Documentation And Provenance

Docstrings for all six fitters now describe ForwardDiff rather than
finite-difference gradients. `bench/README.md` documents the new R comparison
driver and its caveats. `CLAUDE.md` was updated to remove stale "Gaussian only"
guidance and to keep future agents out of the old Takahashi swap lane.

Private-source audit: the private trace scan over tracked repo content returned
no matches. No private source path or private manuscript metadata was added.

## Remaining Risks

- The full planned small/medium/large R-vs-Julia grid was not run; only the
  warmed smoke cell was run.
- Negative-binomial, Beta, and Gamma need a Hopper/Fisher parameterisation audit
  against R `gllvmTMB` before their log-likelihood differences can be interpreted
  as parity or regression.
- Ordinal cannot be a likelihood-parity comparison until the link functions
  match.
- `AGENTS.md` still has a stale "Gaussian only" snapshot, but it was not edited
  because that file marks AGENTS edits as maintainer-approval-required.
- Allocs.jl is not present in the active project, so allocation proof remains a
  separate quality-battery task.

## Rose Verdict

Rose verdict: PASS WITH NOTES — the fast-gradient implementation, gradient
checks, recovery tests, full `Pkg.test()`, smoke benchmark, and private-source
audit passed; full-grid R benchmarking and family-parameterisation audits remain
named follow-ups.
