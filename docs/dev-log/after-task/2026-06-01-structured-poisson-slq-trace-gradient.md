# After Task: Structured Poisson SLQ Trace Gradient

## Goal

Move the internal structured Poisson fitter from dense-only block gradients
toward the large-p stochastic determinant path.

## Implemented

Added a frozen-probe SLQ trace-gradient path for `_structured_poisson_implicit_value_grad`
when `logdet_method = :slq`, or `:auto` selects SLQ above the dense cutoff. The
new path estimates the Schur log-determinant derivative through probe solves
instead of materializing dense `S_u^{-1}`. With scaled identity probes and full
Lanczos steps it recovers the exact dense block gradient; with Rademacher probes
it gives a deterministic fitted benchmark path when probes are frozen by the
fitter.

## Mathematical Contract

For `logdet(S_u)`, the exact differential is `tr(S_u^{-1} dS_u)`. The new code
uses frozen probes `r_j` and Schur solves `x_j = S_u^{-1} r_j` to estimate
observation leverage terms as
`mean_j (d_ts' r_j)(d_ts' x_j)`, where
`d_ts = e_t - W_iΛ(I + Λ'W_iΛ)^{-1}λ_t`. With the scaled identity basis this is
the exact dense trace; with Rademacher probes it is the Hutchinson trace
estimator used by the SLQ determinant prototype. The mode/envelope equation is
unchanged from the dense block gradient and follows the TMB/Kristensen et al.
Laplace principle.

## Files Changed

- `src/families/structured_poisson.jl` — added the SLQ trace-gradient path and
  routed `:slq`/large-`:auto` gradient calls to it.
- `test/test_structured_poisson_laplace.jl` — added exact full-basis SLQ
  value/gradient checks against the dense block gradient.
- `bench/structured_poisson_fit_bench.jl` — added `--logdet`, `--nprobes`, and
  `--lanczos-steps`; added a larger default fitted benchmark cell.
- `bench/README.md` — documented the SLQ fitted benchmark options.
- `docs/dev-log/check-log.md` — recorded tests, benchmarks, scans, and lane
  checks.

## Tests Added

Six assertions were added to `structured Poisson implicit gradient`: SLQ
full-basis value agreement, finite gradients, and dense/CG SLQ gradient
agreement against the dense block gradient. This satisfies the independent
calculation clause because scaled identity probes reduce the stochastic trace
formula to the exact dense trace.

## Benchmark Numbers

Maintainer Mac, fitted structured Poisson benchmark, `iterations=6`.

SLQ finite-difference to SLQ trace-gradient speedup:

| cell | path | finite SLQ (s) | trace SLQ (s) | speedup | abs loglik diff |
| --- | --- | ---: | ---: | ---: | ---: |
| small p=5 n=8 K=1 | dense mode | 0.0123 | 0.0018 | 6.83x | 1.34e-09 |
| small p=5 n=8 K=1 | CG mode | 0.0116 | 0.0022 | 5.27x | 1.34e-09 |
| medium p=8 n=12 K=2 | dense mode | 0.0625 | 0.0047 | 13.30x | 7.03e-08 |
| medium p=8 n=12 K=2 | CG mode | 0.0577 | 0.0057 | 10.12x | 7.03e-08 |
| large p=20 n=25 K=2 | dense mode | 0.9753 | 0.0309 | 31.56x | 2.16e-07 |
| large p=20 n=25 K=2 | CG mode | 0.8171 | 0.0313 | 26.11x | 2.16e-07 |

Single gradient-evaluation scaling, CG mode, 4 frozen probes:

| p | n | K | dense gradient (s) | SLQ trace gradient (s) | dense / SLQ |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 80 | 80 | 2 | 0.0094 | 0.0126 | 0.75x |
| 160 | 120 | 2 | 0.0386 | 0.0360 | 1.07x |
| 320 | 160 | 2 | 0.1658 | 0.1119 | 1.48x |
| 640 | 160 | 2 | 0.5749 | 0.1794 | 3.20x |

## R-Parity Verdict

Parity: N/A — this is an internal fixed-covariance structured Poisson prototype,
not a public `gllvmTMB`-equivalent fitter surface. Existing non-Gaussian
gllvmTMB comparison scripts were not modified.

## JET / Allocs / Aqua Verdicts

- JET: clean through `Pkg.test()` quality gate.
- Allocs: not run separately; fitted and single-gradient wall-clock benchmarks
  were recorded.
- Aqua: clean through `Pkg.test()` quality gate.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Focused result: 89 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2303 pass, 1 existing broken sparse-phy precision placeholder, 2
expected quality placeholders in the direct core environment, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Full result: 2315 pass, 1 existing broken sparse-phy precision placeholder,
quality 12/12 pass, 0 fail, 0 error.

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
```

`git diff --check` was clean. The private-upload trace scan had no matches.
The stale-wording scan still finds the user-provided AGENTS.md "Gaussian only"
snapshot and historical check-log entries; those were not edited. The
performance scan finds existing Gaussian/gllvmTMB claims and historical
internal benchmark records; this new report labels the claim as internal
structured Poisson SLQ trace-gradient evidence only.

## GitHub Issue Maintenance

No issue action was taken. Open PR #59 is the separate
`claude/package-work-catchup-mQiZM` draft lane for Delta-Gamma, ZIP/ZINB, and
non-Gaussian CIs; this task did not touch that lane.

## What Did Not Go Smoothly

SLQ is slower than exact dense gradients on tiny fitted cells, because probe
solves and Lanczos overhead dominate. The speed crossover appears only around
`p≈160` in the single-gradient timing.

## Team Learning

For large-p structured non-Gaussian fitting, the determinant path must report
both stochastic accuracy and timing; a faster trace estimator is not useful if
its probe budget is too noisy for optimization.

## Remaining Risks

- Rademacher-probe SLQ gradients are stochastic approximations; fitted optimizer
  stability still needs a larger ADEMP-style probe-budget study.
- The prototype remains private fixed-covariance structured Poisson, with no
  public structured non-Gaussian syntax.
- The trace path does not yet include variance-reduction or adaptive probe
  budgeting.

## Known Limitations

This slice supplies the large-p determinant-gradient substrate but does not make
SLQ the default fitted path, does not compare against R `gllvmTMB`, and does not
claim final 100x structured-model speedups.

## Next Command

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --gradient=implicit --logdet=slq --nprobes=4 --lanczos-steps=20
```

## Rose Verdict

Rose verdict: PASS WITH NOTES — exact full-basis checks and full suite pass,
but stochastic probe-budget accuracy remains a follow-up before public use.
