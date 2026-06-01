# After Task: Structured Schur Dense Materialization

## Goal

Trim avoidable dense Schur materialization allocation in the internal
structured Poisson Laplace prototype without changing the likelihood surface.

## Implemented

`_schur_u_dense` now delegates to `_schur_u_dense!`, which fills caller-owned
matrix and vector workspaces, writes columns with explicit loops, and
symmetrizes in place. This avoids the previous `S + S'` and broadcast
temporaries. The exact dense mode solve also factors the returned `Symmetric`
Schur matrix directly instead of copying it back into a plain `Matrix`.

## Mathematical Contract

The Schur complement itself is unchanged:

```text
S_u = sigma^-2 Q + sum_s W_s - sum_s W_s Lambda A_s^-1 Lambda' W_s
```

with `A_s = I + Lambda' W_s Lambda`. This slice only changes how the dense
matrix representation of `S_u` is materialized before exact Cholesky
factorization. Focused tests compare the in-place and allocating paths against
the existing dense reference.

## Files Changed

src:

- `src/structured_schur.jl` - adds `_schur_u_dense!` and in-place dense Schur
  symmetrization.
- `src/families/structured_poisson.jl` - removes an extra `Matrix` copy before
  exact dense Schur Cholesky factorization.

test:

- `test/test_structured_schur.jl` - checks that in-place dense materialization
  agrees with `_schur_u_dense` and rejects malformed work matrices.

docs:

- `docs/dev-log/check-log.md` - records focused tests and benchmark evidence.
- `docs/dev-log/after-task/2026-06-01-structured-schur-dense-materialization.md`
  - this audit.

## Tests Added

The new test covers `_schur_u_dense!` directly. It verifies equality with the
existing dense Schur reference to `1e-10` and checks a malformed work matrix
throws `DimensionMismatch`.

## Benchmark Numbers

Dense Schur materialization, fixed seed, BLAS threads set to 1:

| p | n | K | dense build (s) | dense build bytes | build + logdet (s) | build + logdet bytes |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 80 | 80 | 2 | 0.004513 | 59,280 | 0.004519 | 110,528 |
| 160 | 120 | 2 | 0.024074 | 220,528 | 0.024098 | 425,376 |
| 320 | 160 | 3 | 0.156511 | 850,384 | 0.147645 | 1,669,632 |

Allocation reduction versus the pre-slice checkpoint in the same session:

| p | dense build bytes before | dense build bytes after | build + logdet bytes before | build + logdet bytes after |
| ---: | ---: | ---: | ---: | ---: |
| 80 | 162,768 | 59,280 | 214,144 | 110,528 |
| 160 | 630,256 | 220,528 | 835,088 | 425,376 |
| 320 | 2,488,912 | 850,384 | 3,308,144 | 1,669,632 |

Full internal structured Poisson objective benchmark:

| cell | p | n | K | dense (s) | CG + dense (s) | CG + SLQ (s) | dense / CG+dense | dense / CG+SLQ | CG+dense abs diff | CG+SLQ abs diff |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 40 | 40 | 2 | 0.0047 | 0.0020 | 0.0028 | 2.40x | 1.71x | 9.55e-11 | 4.73e-1 |
| medium | 80 | 80 | 2 | 0.0420 | 0.0103 | 0.0093 | 4.07x | 4.49x | 4.91e-11 | 6.36e-1 |
| large | 160 | 120 | 2 | 0.1661 | 0.0363 | 0.0242 | 4.58x | 6.87x | 0.00e+00 | 9.13e-1 |

Exploratory larger structured Poisson objective cell, p=320, n=160, K=3:

| path | median seconds | speedup vs dense | abs diff vs dense |
| --- | ---: | ---: | ---: |
| dense | 0.9383 | 1.00x | 0.00e+00 |
| CG + dense | 0.1886 | 4.97x | 1.46e-11 |
| CG + SLQ | 0.0754 | 12.44x | 1.16e+00 |

Interpretation: this is a storage and exact-factorization cleanup. The bigger
speedups still need the algorithmic lane: CG for exact mode solves and a
stable approximate determinant policy for large structured `p`.

## R-Parity Verdict

Parity: N/A - this remains an internal Julia-only structured Poisson prototype,
not a public `gllvmTMB` comparable fitter. The comparison repo was not
modified.

## JET / Allocs / Aqua Verdicts

- JET: clean via `Pkg.test()` quality block, 12/12 pass.
- Allocs: dense Schur build bytes dropped from 2,488,912 to 850,384 at p=320;
  build-plus-logdet bytes dropped from 3,308,144 to 1,669,632.
- Aqua: clean via `Pkg.test()` quality block, 12/12 pass.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
julia --project=. --startup-file=no bench/structured_poisson_laplace_bench.jl --full --reps=5 --warmups=3 --out=/tmp/structured-poisson-laplace-dense-copyless.csv
julia --project=. --startup-file=no -e '<fixed-seed dense Schur materialization allocation probe>'
julia --project=. --startup-file=no test/runtests.jl
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
git diff --check
```

Observed focused tallies:

```text
structured Schur operator                    | 36/36 pass
structured Schur SLQ logdet                  | 9/9 pass
structured Poisson Laplace prototype         | 13/13 pass
structured Poisson sigma-to-zero reduction   | 1/1 pass
```

Observed full-suite tallies:

```text
core parsed tally       | 2273 pass, 3 expected broken placeholders, 0 fail, 0 error
Pkg.test parsed tally   | 2285 pass, 1 existing broken, 0 fail, 0 error
Pkg.test quality        | 12/12 pass
Testing GLLVM tests passed
```

## CI And Bootstrap Status

No confidence-interval or bootstrap implementation changed in this slice. Draft
PR #59 remains the active non-Gaussian CI / extra-family lane.

## Consistency Audit

Scans run:

```sh
git diff --check
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
<private-source trace scan over tracked repo content>
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean.
- No private-source trace in tracked repo content.
- The stale-wording scan still finds the user-provided AGENTS.md "Gaussian only"
  snapshot and prior check-log entries. It was not edited because AGENTS.md
  changes require maintainer approval.
- Performance wording is confined to benchmark evidence and existing historical
  speedup notes. The new numbers are internal objective and allocation timings,
  not fitted-model or R-parity claims.
- Open PR #59 remains the separate non-Gaussian CI / extra-family lane.

## GitHub Issue Maintenance

No issue action taken.

## What Did Not Go Smoothly

A first timing rerun showed a p=160 dense-logdet spike under 16 BLAS threads.
A direct old-vs-new comparison showed bit-identical matrices and normal
Cholesky timings; with BLAS threads set to 1 the timing was stable. The spike
was treated as benchmark noise rather than algorithmic evidence.

## Team Learning

Karpinski's next target is no longer the final symmetrization temporary; it is
the remaining O(p^2) dense exact determinant path and the policy layer that
decides when SLQ is acceptable. Fisher should keep CG+dense as the exact
reference while SLQ bias is tuned.

## Remaining Risks

- This is still an internal Poisson-only prototype.
- SLQ remains approximate and needs optimizer-stability checks.
- The largest speedups will come from structured determinant policy and
  production fitter wiring, not this allocation cleanup alone.

## Known Limitations

The benchmark grid uses a simple sparse tridiagonal precision fixture and does
not compare to R `gllvmTMB`. The performance claim is internal objective-level
evidence only.

## Next Command

```sh
julia --project=. --startup-file=no test/runtests.jl
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - allocation is reduced, exact CG/dense agreement
is preserved, and local gates are green. The note remains that fitted-model and
R-parity speed claims are still future work.
