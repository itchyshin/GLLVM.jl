# After Task: Structured Poisson Laplace Prototype

## Goal

Move the structured non-Gaussian fast-algorithm lane from determinant-only
evidence to a full internal Poisson Laplace objective with a matrix-free
mode-solve option.

## Implemented

Added an internal structured Poisson Laplace prototype under
`src/families/structured_poisson.jl`. The prototype jointly solves response
structured random effects and site latent factors, evaluates the joint Laplace
marginal, supports dense Schur and matrix-free CG mode solves, and can use
either exact dense or SLQ Schur log determinants. Added tests for dense/SLQ
agreement, CG/dense agreement, malformed inputs, and the sigma-to-zero
reduction back to the existing independent Poisson Laplace marginal. Added a
Julia-only benchmark harness and README notes for the objective-level timing
grid.

## Mathematical Contract

For response matrix `Y`, loading matrix `Lambda`, fixed response intercepts
`beta`, site factors `Z`, response effect `u`, and structured precision `Q`,
the prototype evaluates the Laplace approximation

```text
log p(Y | theta) ~= ell(Y | beta + u + Lambda Z)
    - 0.5 * (||Z||^2 + sigma^-2 u'Q u + logdet(A) + logdet(S_u))
    + 0.5 * logdet(sigma^-2 Q),
```

where `A_s = I + Lambda' W_s Lambda` and
`S_u = sigma^-2 Q + sum_s W_s - sum_s W_s Lambda A_s^-1 Lambda' W_s`.
The mode equation is the usual Laplace/Fisher score equation for `u` and each
site factor, matching the Kristensen et al. style "differentiate the marginal,
not extra outer finite differences" direction already used elsewhere in this
branch.

## Files Changed

src:

- `src/GLLVM.jl` - includes the internal structured Poisson prototype.
- `src/structured_schur.jl` - adds a matrix-free CG solve helper for the
  existing Schur operator.
- `src/families/structured_poisson.jl` - new internal objective prototype.

test:

- `test/runtests.jl` - wires the new structured Poisson tests.
- `test/test_structured_schur.jl` - checks CG against the dense Schur solve and
  malformed arguments.
- `test/test_structured_poisson_laplace.jl` - new dense/SLQ/CG/reduction tests.

bench/docs:

- `bench/structured_poisson_laplace_bench.jl` - new objective benchmark.
- `bench/README.md` - documents smoke/full runs.
- `docs/dev-log/check-log.md` - records evidence and benchmark numbers.
- `docs/dev-log/after-task/2026-06-01-structured-poisson-laplace-prototype.md`
  - this audit.

## Tests Added

The new tests would have failed before this slice because the structured
Poisson objective and Schur CG helper did not exist. They also satisfy the
"tests of the tests" requirement through independent dense comparisons,
malformed input checks, and a boundary-style sigma-to-zero reduction against
the existing independent Poisson Laplace implementation.

## Benchmark Numbers

Full local grid, three measured repetitions after two warmups:

| cell | p | n | K | dense (s) | CG + dense (s) | CG + SLQ (s) | dense / CG+dense | dense / CG+SLQ | CG+dense abs diff | CG+SLQ abs diff |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 40 | 40 | 2 | 0.0050 | 0.0022 | 0.0030 | 2.31x | 1.69x | 9.55e-11 | 4.73e-1 |
| medium | 80 | 80 | 2 | 0.0903 | 0.0097 | 0.0098 | 9.31x | 9.26x | 4.55e-11 | 6.36e-1 |
| large | 160 | 120 | 2 | 0.1772 | 0.0394 | 0.0279 | 4.49x | 6.35x | 0.00e+00 | 9.13e-1 |

Interpretation: matrix-free CG preserves the exact dense-logdet objective to
floating-point noise and gives 2.3x to 9.3x objective-evaluation speedups on
this grid. The SLQ determinant path is faster on the larger cell but is still
an approximate objective, with absolute log-likelihood differences around
0.5-0.9 under the deliberately cheap four-probe setting.

## R-Parity Verdict

Parity: N/A - this is an internal Julia-only prototype and not a public
`gllvmTMB` comparable fitter yet. It should move to the separate
`gllvmTMB-julia-bench/` comparison repo only after the structured objective is
wired into a real fitter.

## JET / Allocs / Aqua Verdicts

- JET: package quality gate passed through `Pkg.test()`; no new JET report was
  added for this internal prototype.
- Allocs: no zero-allocation claim was made. The next performance slice should
  profile allocations in `_structured_poisson_mode` and `_schur_u_cg!`.
- Aqua: clean via `Pkg.test()` quality block, 12/12 pass.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
julia --project=. --startup-file=no bench/structured_poisson_laplace_bench.jl --full --out=/tmp/structured-poisson-laplace-full.csv
julia --project=. --startup-file=no bench/structured_poisson_laplace_bench.jl --smoke --reps=1 --out=/tmp/structured-poisson-laplace-smoke.csv
julia --project=. --startup-file=no test/runtests.jl
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
git diff --check
```

Observed tallies:

```text
structured Schur operator                    | 26/26 pass
structured Schur SLQ logdet                  | 9/9 pass
structured Poisson Laplace prototype         | 9/9 pass
structured Poisson sigma-to-zero reduction   | 1/1 pass
core manual tally                            | 2259 pass, 1 existing broken, 2 expected quality placeholders, 0 fail, 0 error
Pkg.test manual tally                        | 2271 pass, 1 existing broken, 0 fail, 0 error
Pkg.test quality                             | 12/12 pass
Testing GLLVM tests passed
```

## CI And Bootstrap Status

Existing confidence-interval and bootstrap tests stayed green in both direct
core and `Pkg.test()` runs, including:

```text
confint                       | 14/14 pass
profile CI                    | 4/4 pass
parametric bootstrap CI       | 9/9 pass
derived-quantity CIs          | 45/45 pass
profile_ci_derived phylo cell | 20/20 pass
```

No new CI/bootstrap API was added in this slice.

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
  speedup notes. The new structured Poisson numbers are internal objective
  timings, not fitted-model or R-parity claims.

## GitHub Issue Maintenance

No issue action taken. Draft PR #59 remains the active non-Gaussian CI /
extra-family lane, and this slice stayed out of that file set.

## What Did Not Go Smoothly

The first structured objective benchmark showed healthy speedups but also made
the approximation trade-off visible: four-probe SLQ is fast, yet not accurate
enough to call a production optimizer path. The useful immediate win is the CG
mode solve with exact dense logdet; SLQ needs a stability/tuning pass before it
can drive optimization.

## Team Learning

Karpinski should next reduce allocations in the mode loop and make the CG path
workspace-reusing. Fisher should tune the SLQ determinant against fitted
objective stability, not just determinant error. Ada should keep the prototype
internal until a real structured fitter and gllvmTMB comparison cell exist.

## Remaining Risks

- The prototype is Poisson-only and not wired into public fitters.
- SLQ objective smoothness under repeated optimizer steps is untested.
- CG currently allocates work vectors per solve; this is acceptable for a
  prototype, not for the 100x-style target.
- No R `gllvmTMB` comparison exists for this internal structured objective yet.

## Known Limitations

The benchmark grid is smaller than the eventual phylogenetic/spatial target and
uses a simple sparse tridiagonal precision fixture. It is a direction-of-travel
result, not a final structured-model performance claim.

## Next Command

```sh
julia --project=. --startup-file=no bench/structured_poisson_laplace_bench.jl --full --out=/tmp/structured-poisson-laplace-full.csv
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - internal prototype, tests, package gate, and
benchmark evidence are in place; remaining notes are limited to productionizing
the path and proving R-comparable fitted-model speedups later.
