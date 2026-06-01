# After Task: Structured Poisson Workspace Reuse

## Goal

Reduce allocation pressure in the internal structured Poisson Laplace prototype
without changing its likelihood surface or public API.

## Implemented

Reused score and weight matrices across structured Poisson mode iterations,
added a scratch-aware `_schur_u_cg!` method for matrix-free Schur solves, and
avoided redundant matrix/sparse-precision copies when storage already has the
target element type. The existing allocating CG wrapper remains available for
simple calls and tests, while the structured mode path now uses the scratch
entry point.

## Mathematical Contract

The mathematical objective is unchanged from the previous structured Poisson
prototype:

```text
log p(Y | theta) ~= ell(Y | beta + u + Lambda Z)
    - 0.5 * (||Z||^2 + sigma^-2 u'Q u + logdet(A) + logdet(S_u))
    + 0.5 * logdet(sigma^-2 Q),
```

with `A_s = I + Lambda' W_s Lambda` and
`S_u = sigma^-2 Q + sum_s W_s - sum_s W_s Lambda A_s^-1 Lambda' W_s`.
This slice changes storage reuse only; dense, CG, and sigma-to-zero tests still
anchor the same likelihood surface.

## Files Changed

src:

- `src/structured_schur.jl` - adds no-copy storage helpers and a scratch-aware
  `_schur_u_cg!` method.
- `src/families/structured_poisson.jl` - reuses score/weight matrices and CG
  scratch vectors in the structured Poisson mode path.

test:

- `test/test_structured_schur.jl` - checks scratch CG against the allocating
  CG wrapper and malformed scratch dimensions.
- `test/test_structured_poisson_laplace.jl` - checks the mutating Poisson
  score/weight helper against the allocating helper.

docs:

- `docs/dev-log/check-log.md` - records allocation, benchmark, and suite
  evidence.
- `docs/dev-log/after-task/2026-06-01-structured-poisson-workspace-reuse.md`
  - this audit.

## Tests Added

The new tests would have failed before this slice because the scratch-aware CG
method and mutating score/weight helper were not available. They compare the
new scratch paths to the existing allocating reference paths and cover malformed
scratch dimensions.

## Benchmark Numbers

Fixed-seed allocation/timing probe for exact CG+dense structured Poisson
objective:

| cell | before median (s) | after median (s) | before bytes | after bytes | time speedup | allocation reduction |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| p=80, n=80, K=2 | 0.0104 | 0.0095 | 1,429,560 | 645,864 | 1.10x | 54.8% |
| p=160, n=120, K=2 | 0.0386 | 0.0383 | 4,327,576 | 2,050,040 | 1.01x | 52.6% |

Full local objective benchmark, three measured repetitions after two warmups:

| cell | p | n | K | dense (s) | CG + dense (s) | CG + SLQ (s) | dense / CG+dense | dense / CG+SLQ | CG+dense abs diff | CG+SLQ abs diff |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 40 | 40 | 2 | 0.0047 | 0.0019 | 0.0027 | 2.43x | 1.72x | 9.55e-11 | 4.73e-1 |
| medium | 80 | 80 | 2 | 0.0345 | 0.0089 | 0.0090 | 3.89x | 3.82x | 4.91e-11 | 6.36e-1 |
| large | 160 | 120 | 2 | 0.2190 | 0.0363 | 0.0262 | 6.04x | 8.35x | 0.00e+00 | 9.13e-1 |

Interpretation: exact CG+dense remains likelihood-equivalent to dense to
floating-point noise while halving allocation in the fixed probe. The cheap SLQ
path is fastest on the large cell but remains an approximate-objective path.

## R-Parity Verdict

Parity: N/A - this internal prototype is not yet a public `gllvmTMB` comparable
fitter. No R benchmark repo files were modified.

## JET / Allocs / Aqua Verdicts

- JET: package quality gate passed through `Pkg.test()`; no new JET report was
  added for this internal prototype.
- Allocs: improved in the exact CG+dense probe by 54.8% at p=80 and 52.6% at
  p=160.
- Aqua: clean via `Pkg.test()` quality block, 12/12 pass.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
julia --project=. --startup-file=no bench/structured_poisson_laplace_bench.jl --full --out=/tmp/structured-poisson-laplace-workspace-final.csv
julia --project=. --startup-file=no -e '<fixed-seed structured Poisson allocation probe>'
julia --project=. --startup-file=no test/runtests.jl
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
git diff --check
```

Observed tallies:

```text
structured Schur operator                    | 29/29 pass
structured Schur SLQ logdet                  | 9/9 pass
structured Poisson Laplace prototype         | 12/12 pass
structured Poisson sigma-to-zero reduction   | 1/1 pass
core manual tally                            | 2265 pass, 1 existing broken, 2 expected quality placeholders, 0 fail, 0 error
Pkg.test manual tally                        | 2277 pass, 1 existing broken, 0 fail, 0 error
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

A BLAS-backed score-loop variant looked plausible but slowed the benchmark,
especially the larger exact-CG cell. It was removed before final verification;
the committed version keeps the faster manual score loop plus workspace reuse.

## Team Learning

Karpinski should next attack the remaining allocations in Schur operator
construction, especially per-site `A_s` assembly and factorization. Fisher
should keep exact CG+dense as the correctness reference while SLQ tuning is
benchmarked against optimizer stability.

## Remaining Risks

- The structured Poisson path remains internal and Poisson-only.
- The exact CG path still allocates about 0.65 MB at p=80 and 2.05 MB at p=160;
  there is more engine work left before a 100x structured claim is plausible.
- SLQ remains approximate and is not yet safe as an optimizer objective without
  probe/seed/stability policy.

## Known Limitations

The benchmark grid uses a simple sparse tridiagonal precision fixture and does
not compare to R `gllvmTMB`. The performance claim is internal objective-level
evidence only.

## Next Command

```sh
julia --project=. --startup-file=no bench/structured_poisson_laplace_bench.jl --full --out=/tmp/structured-poisson-laplace-workspace-final.csv
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - allocation pressure is materially reduced and
all local gates passed; remaining notes are productionizing the structured
operator and proving fitted-model parity/speed later.
