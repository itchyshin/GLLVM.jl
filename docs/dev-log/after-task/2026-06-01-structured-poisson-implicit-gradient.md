# After Task: Structured Poisson Implicit Gradient

## Goal

Replace Optim finite-difference gradients in the private structured Poisson
fitted prototype with a verified implicit-gradient path.

## Implemented

Added `_structured_poisson_implicit_value_grad`, a private joint-mode
implicit-gradient helper for the fixed-covariance structured Poisson Laplace
objective. It packs the shared structured random effect `u`, all site latent
variables `z`, and the fitted parameters into one implicit system, then applies
the adjoint formula `q_theta - F_theta' * (F_x' \\ q_x)`. The private fitted
helper now defaults to `gradient=:implicit`; the previous Optim finite
difference path remains available with `gradient=:finite`.

## Mathematical Contract

For fixed precision `Q`, fixed `sigma2`, and packed parameters
`theta = [beta; vec_lower(Lambda)]`, the value is unchanged:

```text
log p(Y | theta, Q, sigma2) ~= ell(Y | beta + uhat + Lambda Zhat)
    - 0.5 * (||Zhat||^2 + sigma^-2 uhat'Q uhat
             + sum_s logdet(A_s) + logdet(S_u))
    + 0.5 * logdet(sigma^-2 Q).
```

The mode equation is `F(x, theta) = 0`, where
`x = [u; vec(Z)]`, `F_u = sum_s(y_s - mu_s) - sigma^-2 Q u`, and
`F_{z_s} = Lambda'(y_s - mu_s) - z_s`. The gradient is computed from the
implicit-function adjoint, avoiding differentiation through the Fisher-scoring
iterations.

## Files Changed

src:

- `src/families/structured_poisson.jl` - adds joint-mode packing, `q/F`
  construction, implicit value/gradient helper, and `gradient=:implicit`
  fitter wiring.

test:

- `test/test_structured_poisson_laplace.jl` - checks implicit gradient vs
  central finite differences and finite-vs-implicit fitted agreement.

bench:

- `bench/structured_poisson_fit_bench.jl` - adds `--gradient=finite|implicit`.
- `bench/README.md` - documents the implicit default and finite comparator.

docs:

- `docs/dev-log/check-log.md` - records evidence for this slice.
- `docs/dev-log/after-task/2026-06-01-structured-poisson-implicit-gradient.md`
  - this audit.

## Tests Added

The new tests would have failed before this slice because no structured
implicit-gradient helper or `gradient` switch existed. They verify the
implicit gradient against central finite differences at `<= 1e-6`, check the
implicit fitted path reaches the same likelihood as the finite-difference path,
and exercise the malformed gradient selector.

## Benchmark Numbers

Structured Poisson fitted benchmark, finite-difference gradient:

| cell | p | n | K | iterations | dense (s) | CG (s) | dense / CG | abs loglik diff | calls |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 5 | 8 | 1 | 6 | 0.0069 | 0.0060 | 1.15x | 1.02e-09 | 8/8 |
| medium | 8 | 12 | 2 | 6 | 0.0334 | 0.0278 | 1.20x | 4.71e-08 | 9/9 |

Structured Poisson fitted benchmark, implicit gradient:

| cell | p | n | K | iterations | dense (s) | CG (s) | dense / CG | abs loglik diff | calls |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 5 | 8 | 1 | 6 | 0.0018 | 0.0018 | 1.00x | 9.24e-13 | 8/8 |
| medium | 8 | 12 | 2 | 6 | 0.0058 | 0.0057 | 1.01x | 2.67e-12 | 9/9 |

Before/after gradient speedup:

| cell | path | finite (s) | implicit (s) | speedup |
| --- | --- | ---: | ---: | ---: |
| small | dense | 0.0069 | 0.0018 | 3.83x |
| small | CG | 0.0060 | 0.0018 | 3.33x |
| medium | dense | 0.0334 | 0.0058 | 5.76x |
| medium | CG | 0.0278 | 0.0057 | 4.88x |

Exploratory warm larger CG cells:

| p | n | K | finite (s) | implicit (s) | speedup | abs loglik diff |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 12 | 16 | 2 | 0.0329-0.0348 | 0.0133-0.0134 | 2.45x-2.60x | 2.88e-07 |
| 20 | 25 | 2 | 0.1535 | 0.0714 | 2.15x | 1.60e-07 |

Interpretation: this is the first true structured implicit-gradient slice.
It is a verified fitted speedup, but the current implementation still builds a
dense joint ForwardDiff Jacobian. The large-p target remains a matrix-free
structured adjoint.

## R-Parity Verdict

Parity: N/A - this is a private Julia-only fixed-covariance structured Poisson
prototype. It is not yet a public `gllvmTMB` comparable fitted model, and the
comparison repo was not modified.

## JET / Allocs / Aqua Verdicts

- JET: clean via `Pkg.test()` quality gate, 12/12 pass.
- Allocs: benchmarked at fitted wall-time level; no allocation gate added
  because this is a scaffold for the eventual matrix-free adjoint.
- Aqua: clean via `Pkg.test()` quality gate, 12/12 pass.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --gradient=finite --out=/tmp/structured-poisson-fit-implicit-slice-finite-full.csv
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --gradient=implicit --out=/tmp/structured-poisson-fit-implicit-slice-implicit-full.csv
julia --project=. --startup-file=no test/runtests.jl
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Observed focused tallies:

```text
structured Schur operator                    | 36/36 pass
structured Schur SLQ logdet                  | 9/9 pass
structured Poisson Laplace prototype         | 13/13 pass
structured Poisson implicit gradient         | 4/4 pass
structured Poisson internal fitter           | 18/18 pass
structured Poisson sigma-to-zero reduction   | 1/1 pass
```

Observed core tally:

```text
julia --project=. --startup-file=no test/runtests.jl
2295 pass, 3 expected broken placeholders, 0 fail, 0 error.

julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
Testing GLLVM tests passed.
2307 pass, 1 expected broken placeholder, 0 fail, 0 error.
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
  to a private structured implicit-gradient scaffold and says the large-p
  matrix-free adjoint is still future work.
- Private-source trace scan: no matches in tracked repo content checked for
  this slice.

## GitHub Issue Maintenance

No issue action taken. Draft PR #59 remains the separate non-Gaussian CI /
extra-family lane.

## What Did Not Go Smoothly

The simple ForwardDiff-through-Newton idea was rejected earlier because its
gradient did not match central finite differences. The implicit scaffold is
more code, but the derivative target is now explicit and testable.

## Team Learning

Noether now has the joint structured mode equation in code. Karpinski's next
target should be replacing the dense joint ForwardDiff Jacobian with a
matrix-free structured adjoint that reuses the Schur operator and site blocks.

## Remaining Risks

- The fitter is still private and fixed-covariance only.
- The implicit helper builds a dense joint Jacobian and is not the large-p
  matrix-free algorithm.
- Determinants are exact dense in the fitted benchmark; SLQ remains a separate
  approximate determinant lane.
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

Rose verdict: PASS WITH NOTES - the private structured fitted path now has a
verified implicit-gradient default and local fitted speedup, but the large-p
matrix-free structured adjoint and R `gllvmTMB` parity remain future gates.
