# After Task: Structured Poisson Fitted Prototype

## Goal

Bridge the structured Poisson Laplace objective prototype into a private fitted
path so dense and CG mode solves can be compared at fitted-model level.

## Implemented

Added `_fit_structured_poisson_laplace`, a private fixed-covariance fitter that
estimates `β` and lower-triangular `Λ` for a supplied structured precision and
fixed `sigma2`. The fitter keeps the determinant exact (`logdet_method=:dense`)
for reference-quality fitted comparisons and allows `mode_solve=:dense` or
`:cg`. Added a fitted benchmark script that reports dense-vs-CG fitted timing,
final log-likelihood agreement, and objective-call counts.

## Mathematical Contract

For fixed precision `Q`, fixed `sigma2`, and packed parameters
`θ = [β; vec_lower(Λ)]`, the fitted objective maximizes the same structured
Poisson Laplace marginal already introduced:

```text
log p(Y | θ, Q, sigma2) ~= ell(Y | beta + uhat + Lambda Zhat)
    - 0.5 * (||Zhat||^2 + sigma^-2 uhat'Q uhat
             + sum_s logdet(A_s) + logdet(S_u))
    + 0.5 * logdet(sigma^-2 Q),
```

where `A_s = I + Lambda' W_s Lambda`, and `S_u` is the Schur complement after
eliminating site latent variables. This slice changes only optimization around
that marginal; it does not change the likelihood formula.

## Files Changed

src:

- `src/families/structured_poisson.jl` - adds private initial packing,
  objective, and fixed-covariance fitted helper.

test:

- `test/test_structured_poisson_laplace.jl` - checks dense and CG fitted paths
  agree, improve over the initial objective, and reject malformed inputs.

bench:

- `bench/structured_poisson_fit_bench.jl` - new Julia-only fitted benchmark.
- `bench/README.md` - documents the new fitted benchmark and its claim limits.

docs:

- `docs/dev-log/check-log.md` - records test and benchmark evidence.
- `docs/dev-log/after-task/2026-06-01-structured-poisson-fit-prototype.md` -
  this audit.

## Tests Added

The new fitter test would have failed before this slice because
`_fit_structured_poisson_laplace` did not exist. It verifies dense/CG fitted
agreement to `1e-5`, checks fitted log-likelihoods do not degrade from the
initial point, records objective calls, and exercises two failure paths:
invalid `K` and malformed `β_init`.

## Benchmark Numbers

Structured Poisson fitted benchmark smoke:

| cell | p | n | K | iterations | dense (s) | CG (s) | dense / CG | abs loglik diff | calls |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| smoke | 5 | 8 | 1 | 4 | 0.0099 | 0.0096 | 1.03x | 1.09e-10 | 6/6 |

Structured Poisson fitted benchmark full grid:

| cell | p | n | K | iterations | dense (s) | CG (s) | dense / CG | abs loglik diff | calls |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 5 | 8 | 1 | 6 | 0.0138 | 0.0133 | 1.04x | 2.14e-11 | 8/8 |
| medium | 8 | 12 | 2 | 6 | 0.0779 | 0.0722 | 1.08x | 1.07e-10 | 9/9 |

Exploratory larger fitted cells, two L-BFGS iterations:

| p | n | K | dense (s) | CG (s) | dense / CG | abs loglik diff | calls |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 20 | 25 | 2 | 0.4099 | 0.2669 | 1.54x | 2.59e-8 | 5/5 |
| 40 | 40 | 2 | 3.4018 | 1.6331 | 2.08x | 1.87e-8 | 6/6 |

Interpretation: fitted CG is already exact to small numerical differences and
faster as `p` grows, but the private fitter still uses finite-difference
gradients. This is the bridge to the next algorithmic multiplier, not the final
20x-100x structured claim.

## R-Parity Verdict

Parity: N/A - this is a private Julia-only fixed-covariance structured Poisson
prototype. It is not yet a public `gllvmTMB` comparable fitted model, and the
comparison repo was not modified.

## JET / Allocs / Aqua Verdicts

- JET: clean via `Pkg.test()` quality gate, 12/12 pass.
- Allocs: benchmarked at fitted wall-time level; no `@ballocated` gate added
  because Optim finite differences dominate this temporary private fitter.
- Aqua: clean via `Pkg.test()` quality gate, 12/12 pass.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_poisson_laplace.jl")'
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --smoke --out=/tmp/structured-poisson-fit-smoke.csv
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --out=/tmp/structured-poisson-fit-full.csv
julia --project=. --startup-file=no -e '<exploratory p=20 and p=40 fitted dense-vs-CG timing>'
julia --project=. --startup-file=no test/runtests.jl
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Observed focused tallies:

```text
structured Schur operator                    | 36/36 pass
structured Schur SLQ logdet                  | 9/9 pass
structured Poisson Laplace prototype         | 13/13 pass
structured Poisson internal fitter           | 9/9 pass
structured Poisson sigma-to-zero reduction   | 1/1 pass
```

Observed suite tallies:

```text
julia --project=. --startup-file=no test/runtests.jl
2282 pass, 3 expected broken placeholders, 0 fail, 0 error.

julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
Testing GLLVM tests passed.
2294 pass, 1 expected broken placeholder, 0 fail, 0 error.
quality | 12/12 pass
```

## CI And Bootstrap Status

Core and `Pkg.test()` are green locally. The confidence-interval, profile,
bootstrap, and derived-quantity test blocks passed in both suite runs. This
slice does not modify confidence-interval or bootstrap code.

## Consistency Audit

Final scans:

```sh
git diff --check
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
<private-source trace scan over tracked repo content>
```

Results:

- `git diff --check`: clean.
- Stale wording: known historical check-log entries plus the user-provided
  AGENTS.md "Gaussian only" snapshot; no new public status claim was added.
- Performance claims: existing Gaussian/gllvmTMB claims and historical
  non-Gaussian/structured speed notes remain; this report limits the new claim
  to internal fitted dense-vs-CG timing and says it is not the 20x-100x
  structured algorithm.
- Private-source trace scan: no matches in tracked repo content checked for
  this slice.

## GitHub Issue Maintenance

No issue action taken. Draft PR #59 remains the separate non-Gaussian CI /
extra-family lane.

## What Did Not Go Smoothly

The default fitted benchmark grid is intentionally tiny, so it shows only
modest speedups. The larger exploratory cells show the expected trend, but they
are not yet a stable benchmark grid or an R-parity claim.

## Team Learning

Fisher now has fitted-level dense/CG agreement evidence. Karpinski's next
target should be the structured implicit/envelope gradient, because finite
differences are now the dominant fitted-path cost.

## Remaining Risks

- The fitter is private and fixed-covariance only.
- It still uses Optim finite-difference gradients.
- Determinants are exact dense in the fitted benchmark; SLQ remains approximate
  and is not ready as an optimizer default.
- No R `gllvmTMB` parity claim exists yet for this structured fitted path.

## Known Limitations

The benchmark fixture uses a simple sparse tridiagonal precision and small
iteration budgets. The results are internal fitted-timing evidence, not
end-to-end product claims.

## Next Command

```sh
julia --project=. --startup-file=no test/runtests.jl
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - private fixed-covariance bridge is verified and
quality-clean, but finite-difference gradients remain the next bottleneck and
there is no R `gllvmTMB` parity claim for this private structured path yet.
