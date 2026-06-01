# After Task: Structured Poisson Block Gradient

## Goal

Make the internal fixed-covariance structured Poisson fitter use a genuinely
fast dense-logdet implicit gradient instead of a full joint ForwardDiff Jacobian.

## Implemented

The dense-logdet structured Poisson gradient now uses block formulas for the
Laplace log-determinant derivative, solves the implicit adjoint through the
existing Schur operator, and packs only the lower-triangular loading parameters.
The ForwardDiff-based implicit path remains as the fallback for non-dense
determinant methods. The private fitter API is unchanged.

## Mathematical Contract

For fixed structured precision `Q` and site mode `x = (u, z_1, ..., z_n)`, the
code differentiates
`q(θ, x) = ℓ(y | θ, x) - 0.5 u'Q u / σ² - 0.5Σᵢ zᵢ'zᵢ - 0.5 logdet(H)`
at the mode `F(x, θ) = 0`, using the envelope/implicit gradient
`dq/dθ = q_θ - F_θ'F_x^{-T}q_x`. The joint negative mode Hessian `H = -F_x`
is solved through the Schur complement
`S_u = Q / σ² + diag(Wsum) - Σᵢ WᵢΛ(I + Λ'WᵢΛ)^{-1}Λ'Wᵢ`.
This follows the Laplace/envelope principle used by TMB-style methods
(Kristensen et al. 2016) without copying any external code.

## Files Changed

- `src/families/structured_poisson.jl` — added the block dense-logdet gradient,
  joint Schur solve helper, and ForwardDiff fallback split.
- `test/test_structured_poisson_laplace.jl` — added dense-adjoint equivalence
  tests for the block Schur solve.
- `bench/README.md` — updated the structured Poisson benchmark wording from
  implicit scaffold to block implicit gradient.
- `docs/dev-log/check-log.md` — recorded tests, benchmarks, scans, and lane
  checks.

## Tests Added

Added two assertions in `structured Poisson implicit gradient`: the block Schur
adjoint must match the old dense `Fx' \ qx` solve under both dense and CG Schur
solves. This satisfies the independent-calculation clause because it compares
the new block solve against the explicitly materialized dense Jacobian.

## Benchmark Numbers

Maintainer Mac, fitted structured Poisson benchmark, `iterations=6`, `reps=3`,
`warmups=1`:

| cell | path | finite (s) | block implicit (s) | speedup | abs loglik diff |
| --- | --- | ---: | ---: | ---: | ---: |
| small p=5 n=8 K=1 | dense | 0.0068 | 0.0011 | 6.18x | 1.02e-09 |
| small p=5 n=8 K=1 | CG | 0.0063 | 0.0010 | 6.30x | 1.02e-09 |
| medium p=8 n=12 K=2 | dense | 0.0330 | 0.0025 | 13.20x | 4.71e-08 |
| medium p=8 n=12 K=2 | CG | 0.0281 | 0.0029 | 9.69x | 4.71e-08 |

Exploratory larger CG cells:

| p | n | K | finite (s) | block implicit (s) | speedup | abs loglik diff |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 12 | 16 | 2 | 0.0702 | 0.0038 | 18.51x | 6.47e-08 |
| 20 | 25 | 2 | 0.2972 | 0.0098 | 30.48x | 1.87e-08 |

## R-Parity Verdict

Parity: N/A — this is an internal fixed-covariance structured Poisson prototype,
not a public `gllvmTMB`-equivalent fitter surface. Existing non-Gaussian
gllvmTMB comparison scripts were not modified.

## JET / Allocs / Aqua Verdicts

- JET: clean through `Pkg.test()` quality gate.
- Allocs: not run separately; benchmark timings are fitted wall-clock evidence.
- Aqua: clean through `Pkg.test()` quality gate.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Focused result: 83 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2297 pass, 1 existing broken sparse-phy precision placeholder, 2
expected quality placeholders in the direct core environment, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Full result: 2309 pass, 1 existing broken sparse-phy precision placeholder,
quality 12/12 pass, 0 fail, 0 error.

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|gllvmTMB" README.md docs/src docs/dev-log/check-log.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
```

`git diff --check` was clean. The private-upload trace scan had no matches.
The stale-wording scan still finds the user-provided AGENTS.md "Gaussian only"
snapshot and historical check-log entries; those were not edited. The
performance scan finds existing Gaussian/gllvmTMB claims and historical
internal benchmark records; this new report labels the claim as internal
structured Poisson evidence only.

## GitHub Issue Maintenance

No issue action was taken. Open PR #59 is the separate
`claude/package-work-catchup-mQiZM` draft lane for Delta-Gamma, ZIP/ZINB, and
non-Gaussian CIs; this task did not touch that lane.

## What Did Not Go Smoothly

The first Schur-adjoint-only patch was correct but slower on the tiny/medium
benchmark because `q_x`, `q_θ`, and `F_θ` were still built by ForwardDiff. The
speedup appeared only after replacing those remaining AD blocks with direct
Poisson block formulas.

## Team Learning

For structured non-Gaussian speedups, Schur solves alone are not enough; the
trace/leverage terms must also be block-analytic.

## Remaining Risks

- The block gradient is exact for `logdet_method = :dense`; SLQ determinant
  gradients still fall back to the joint ForwardDiff path and are not the
  large-p final algorithm.
- The prototype is still private fixed-covariance structured Poisson, not a
  public family/fitter API.
- R `gllvmTMB` parity is not applicable for this internal structured path yet.

## Known Limitations

This slice does not implement the stochastic trace-gradient path needed for
large-p SLQ structured dependence, and it does not add user-facing structured
non-Gaussian syntax.

## Next Command

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --gradient=implicit
```

## Rose Verdict

Rose verdict: PASS WITH NOTES — dense-logdet structured Poisson now has a
verified block implicit gradient, but large-p SLQ trace gradients remain future
work.
