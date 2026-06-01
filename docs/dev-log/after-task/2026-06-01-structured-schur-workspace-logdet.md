# After Task: Structured Schur Workspace And Sparse Logdet

## Goal

Remove avoidable structured Poisson objective overhead from Schur operator
construction and sparse structured-precision log determinants.

## Implemented

Added `_SchurUOperatorWorkspace`, a reusable internal workspace for Schur
operator construction that keeps per-site `A_s` matrices, Cholesky wrappers,
and `Wsum` storage alive across mode iterations. The allocating constructor
still exists for simple calls. Also changed the structured Poisson precision
log determinant to factor the precision in native storage, so sparse structured
precisions are no longer densified for `logdet(Q)`.

## Mathematical Contract

The structured Poisson Laplace objective is unchanged:

```text
log p(Y | theta) ~= ell(Y | beta + u + Lambda Z)
    - 0.5 * (||Z||^2 + sigma^-2 u'Q u + logdet(A) + logdet(S_u))
    + 0.5 * logdet(sigma^-2 Q),
```

with `A_s = I + Lambda' W_s Lambda` and
`S_u = sigma^-2 Q + sum_s W_s - sum_s W_s Lambda A_s^-1 Lambda' W_s`.
This slice only changes storage reuse and the factorization route for
`logdet(Q)`; focused tests compare workspace and non-workspace Schur operators,
sparse and dense precision log determinants, and the existing dense/CG
objective references.

## Files Changed

src:

- `src/structured_schur.jl` - adds `_SchurUOperatorWorkspace` and a
  workspace-aware `_SchurUOperator` constructor.
- `src/families/structured_poisson.jl` - uses the Schur workspace in the mode
  loop and avoids dense conversion in `_structured_poisson_logdet_precision`.

test:

- `test/test_structured_schur.jl` - checks workspace and allocating Schur
  operators agree and validates malformed workspace dimensions.
- `test/test_structured_poisson_laplace.jl` - checks sparse and dense precision
  log determinants agree.

docs:

- `docs/dev-log/check-log.md` - records test, benchmark, and allocation
  evidence.
- `docs/dev-log/after-task/2026-06-01-structured-schur-workspace-logdet.md` -
  this audit.

## Tests Added

The new tests would have failed before this slice because the reusable Schur
workspace did not exist and the sparse-native precision logdet path was not
explicitly covered. They compare against the existing allocating/dense
references and include malformed workspace dimensions.

## Benchmark Numbers

Schur operator construction:

| cell | allocating constructor (s) | workspace constructor (s) | allocating bytes | workspace bytes |
| --- | ---: | ---: | ---: | ---: |
| p=80, n=80, K=2 | 7.80e-5 | 6.75e-5 | 12,704 | 1,688 |
| p=160, n=120, K=2 | 1.93e-4 | 1.78e-4 | 17,040 | 120 |
| p=320, n=160, K=3 | 5.27e-4 | 5.74e-4 | 28,640 | 120 |

Exact CG+dense objective probe versus the previous committed checkpoint:

| cell | previous median (s) | current median (s) | previous bytes | current bytes | allocation reduction |
| --- | ---: | ---: | ---: | ---: | ---: |
| p=80, n=80, K=2 | 0.0095 | 0.0090 | 645,864 | 486,512 | 24.7% |
| p=160, n=120, K=2 | 0.0383 | 0.0362 | 2,050,040 | 1,568,016 | 23.5% |

Full objective benchmark:

| cell | p | n | K | dense (s) | CG + dense (s) | CG + SLQ (s) | dense / CG+dense | dense / CG+SLQ | CG+dense abs diff | CG+SLQ abs diff |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 40 | 40 | 2 | 0.0047 | 0.0020 | 0.0027 | 2.42x | 1.73x | 9.55e-11 | 4.73e-1 |
| medium | 80 | 80 | 2 | 0.0303 | 0.0088 | 0.0088 | 3.46x | 3.45x | 4.91e-11 | 6.36e-1 |
| large | 160 | 120 | 2 | 0.1559 | 0.0361 | 0.0239 | 4.32x | 6.52x | 0.00e+00 | 9.13e-1 |

Interpretation: the exact CG path is faster in absolute time and allocates less
than the previous checkpoint. The ratio speedups are lower than one earlier
noisy run because the dense baseline also became faster.

## R-Parity Verdict

Parity: N/A - this remains an internal Julia-only structured Poisson prototype,
not a public `gllvmTMB` comparable fitter. The comparison repo was not modified.

## JET / Allocs / Aqua Verdicts

- JET: package quality gate passed through `Pkg.test()`; no new JET report was
  added for this internal prototype.
- Allocs: exact CG+dense objective allocations improved by 24.7% at p=80 and
  23.5% at p=160 versus the previous checkpoint; Schur workspace construction
  drops to 120 bytes for the larger constructor cells.
- Aqua: clean via `Pkg.test()` quality block, 12/12 pass.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
julia --project=. --startup-file=no -e '<fixed-seed Schur operator construction probe>'
julia --project=. --startup-file=no -e '<fixed-seed structured Poisson allocation probe>'
julia --project=. --startup-file=no bench/structured_poisson_laplace_bench.jl --full --out=/tmp/structured-poisson-laplace-schurws-logdet.csv
julia --project=. --startup-file=no test/runtests.jl
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
git diff --check
```

Observed tallies:

```text
structured Schur operator                    | 34/34 pass
structured Schur SLQ logdet                  | 9/9 pass
structured Poisson Laplace prototype         | 13/13 pass
structured Poisson sigma-to-zero reduction   | 1/1 pass
core parsed tally                            | 2271 pass, 3 expected broken placeholders, 0 fail, 0 error
Pkg.test parsed tally                        | 2283 pass, 1 existing broken, 0 fail, 0 error
Pkg.test quality                             | 12/12 pass
Testing GLLVM tests passed
```

## CI And Bootstrap Status

CI/bootstrap blocks stayed green in both the direct core run and `Pkg.test()`:

```text
confint                       | 14/14 pass
profile CI                    | 4/4 pass
parametric bootstrap CI       | 9/9 pass
derived-quantity CIs          | 45/45 pass
profile_ci_derived phylo cell | 20/20 pass
```

No confidence-interval or bootstrap implementation changed in this slice.

## Consistency Audit

Scans run:

```sh
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p" README.md docs/src docs/dev-log/check-log.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
<private-source trace scan over tracked repo content>
```

Results:

- No private-source trace in tracked repo content.
- The stale-wording scan still finds the user-provided AGENTS.md "Gaussian only"
  snapshot. It was not edited because AGENTS.md changes require maintainer
  approval.
- Performance wording is confined to benchmark evidence and existing historical
  speedup notes. The new numbers are internal objective timings and allocation
  measurements, not fitted-model or R-parity claims.

## GitHub Issue Maintenance

No issue action taken. Draft PR #59 remains the active non-Gaussian CI /
extra-family lane, and this slice stayed out of that file set.

## What Did Not Go Smoothly

The Schur workspace improves allocation dramatically but not every constructor
cell is faster; p=320,K=3 was slightly slower in the constructor microbenchmark.
It is still useful in the structured Poisson mode path because the exact
objective allocation and timing probes both improved.

## Team Learning

Karpinski should next look above the constructor: the dense exact logdet path
still allocates `O(p^2)`, so production structured fitting needs either a better
exact sparse determinant path for appropriate precisions or an optimizer-stable
SLQ policy. Fisher should keep exact CG+dense as the likelihood reference while
that approximate path is tuned.

## Remaining Risks

- This is still an internal Poisson-only prototype.
- The Schur workspace mutates and returns operators backed by the workspace; it
  is appropriate inside one objective evaluation, not as a long-lived public
  object.
- SLQ remains approximate and needs optimizer-stability checks before it can be
  used for fitted structured models.

## Known Limitations

The benchmark grid uses a simple sparse tridiagonal precision fixture and does
not compare to R `gllvmTMB`. The performance claim is internal objective-level
evidence only.

## Next Command

```sh
julia --project=. --startup-file=no bench/structured_poisson_laplace_bench.jl --full --out=/tmp/structured-poisson-laplace-schurws-logdet.csv
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - sparse precision logdet and Schur construction
allocation are improved with all local gates green; remaining notes concern
productionizing the structured fitter and proving R-comparable speed later.
