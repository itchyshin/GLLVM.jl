# After Task: Structured Poisson Mode Cache

## Goal

Reduce repeated inner-mode work in the private structured Poisson fitted
prototype without changing the likelihood surface.

## Implemented

Added warm-start support to `_structured_poisson_mode` and threaded it through
the structured Poisson marginal and private fitted helper. The fitted helper now
uses `mode_cache=true` by default, keeping the previous `u` and `z` modes as
the initial point for the next optimizer probe. A `mode_cache=false` switch
keeps the cold-start path available for tests and diagnostics.

## Mathematical Contract

The optimized objective is unchanged:

```text
log p(Y | theta, Q, sigma2) ~= ell(Y | beta + uhat + Lambda Zhat)
    - 0.5 * (||Zhat||^2 + sigma^-2 uhat'Q uhat
             + sum_s logdet(A_s) + logdet(S_u))
    + 0.5 * logdet(sigma^-2 Q).
```

Only the starting values for the Fisher-scoring mode solve changed. The cached
and cold-start fitted paths are required to agree to the existing fitted
tolerance.

## Files Changed

src:

- `src/families/structured_poisson.jl` - adds `U_init`, `Z_init`, `U_store`,
  `Z_store`, and fitted `mode_cache` wiring.

test:

- `test/test_structured_poisson_laplace.jl` - checks cached/cold fitted
  agreement and malformed cache-shape errors.

bench:

- `bench/README.md` - notes that the fitted prototype benchmark uses the mode
  cache by default.

docs:

- `docs/dev-log/check-log.md` - records evidence for this slice.
- `docs/dev-log/after-task/2026-06-01-structured-poisson-mode-cache.md` -
  this audit.

## Tests Added

The new assertions would have failed before this slice because the structured
mode solver had no cache inputs and the fitted helper had no `mode_cache`
switch. The test verifies cached and cold CG fits agree, records the returned
cache flag, and checks malformed `U_init` and `Z_init` shapes.

## Benchmark Numbers

Baseline is commit `f6630b9`, before fitted-mode caching. Measurements used the
same benchmark script and local machine.

| cell | p | n | K | path | before (s) | after (s) | speedup | abs loglik diff |
| --- | ---: | ---: | ---: | --- | ---: | ---: | ---: | ---: |
| smoke | 5 | 8 | 1 | dense | 0.0099 | 0.0049 | 2.02x | 3.51e-08 |
| smoke | 5 | 8 | 1 | CG | 0.0096 | 0.0045 | 2.13x | 3.51e-08 |
| small | 5 | 8 | 1 | dense | 0.0138 | 0.0068 | 2.03x | 1.02e-09 |
| small | 5 | 8 | 1 | CG | 0.0133 | 0.0059 | 2.25x | 1.02e-09 |
| medium | 8 | 12 | 2 | dense | 0.0779 | 0.0344 | 2.26x | 4.71e-08 |
| medium | 8 | 12 | 2 | CG | 0.0722 | 0.0267 | 2.70x | 4.71e-08 |

Interpretation: this is a constant-factor fitted-path speedup. It does not
remove Optim finite differences and is not the final structured 20x-100x
algorithm.

## R-Parity Verdict

Parity: N/A - this is a private Julia-only fixed-covariance structured Poisson
prototype. It is not yet a public `gllvmTMB` comparable fitted model, and the
comparison repo was not modified.

## JET / Allocs / Aqua Verdicts

- JET: clean via `Pkg.test()` quality gate, 12/12 pass.
- Allocs: benchmarked at fitted wall-time level; no allocation gate added
  because this is still a private Optim finite-difference bridge.
- Aqua: clean via `Pkg.test()` quality gate, 12/12 pass.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --smoke --out=/tmp/structured-poisson-fit-cache-smoke.csv
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --out=/tmp/structured-poisson-fit-cache-full.csv
julia --project=. --startup-file=no test/runtests.jl
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Observed focused tallies:

```text
structured Schur operator                    | 36/36 pass
structured Schur SLQ logdet                  | 9/9 pass
structured Poisson Laplace prototype         | 13/13 pass
structured Poisson internal fitter           | 14/14 pass
structured Poisson sigma-to-zero reduction   | 1/1 pass
```

Observed suite tallies:

```text
julia --project=. --startup-file=no test/runtests.jl
2287 pass, 3 expected broken placeholders, 0 fail, 0 error.

julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
Testing GLLVM tests passed.
2299 pass, 1 expected broken placeholder, 0 fail, 0 error.
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
  to an internal constant-factor fitted-path speedup and says it is not the
  20x-100x structured algorithm.
- Private-source trace scan: no matches in tracked repo content checked for
  this slice.

## GitHub Issue Maintenance

No issue action taken. Draft PR #59 remains the separate non-Gaussian CI /
extra-family lane.

## What Did Not Go Smoothly

ForwardDiff-through-Newton was tested first and rejected for this path: it ran
on the dense reference fixture, but its gradient did not match central finite
differences. That keeps the next true gradient step in the implicit/envelope
lane rather than a simple `autodiff=:forward` switch.

## Team Learning

Fisher has a stable cached-vs-cold equality check. Karpinski's next target is
still the structured implicit/envelope gradient, now with less noise from
unnecessary cold-start mode solves.

## Remaining Risks

- The fitter is private and fixed-covariance only.
- Optim still uses finite-difference gradients.
- Cache warm starts assume the inner mode solve reaches the same fixed point;
  the test protects the small reference fixture, not every future structured
  model shape.
- No R `gllvmTMB` parity claim exists yet for this structured fitted path.

## Known Limitations

The benchmark fixture uses a simple sparse tridiagonal precision and small
iteration budgets. The results are internal fitted-timing evidence, not
end-to-end product claims.

## Next Command

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - cached and cold-start fitted paths agree and
the speedup is verified locally, but this remains a private finite-difference
bridge with no R `gllvmTMB` parity claim yet.
