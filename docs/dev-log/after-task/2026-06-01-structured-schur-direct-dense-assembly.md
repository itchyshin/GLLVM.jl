# After Task: Structured Schur Direct Dense Assembly

## Goal

Make the exact dense structured Schur determinant path faster before pushing
harder on stochastic large-p determinants.

## Implemented

`_schur_u_dense` now assembles the Schur complement directly as
`Q / sigma2 + Diagonal(Wsum) - sum_i B_i A_i^{-1} B_i'`, where
`B_i = Diagonal(W_i) Lambda`, instead of applying the operator to every basis
vector. The sparse `Symmetric(SparseMatrixCSC)` precision case now has a direct
copy/scale path, and the existing internal `_schur_u_dense!` scratch-argument
method remains available after dimension checks.

## Mathematical Contract

For fixed site weights, the structured precision over the shared structured
effect is the Schur complement of the joint `(U, Z)` Laplace Hessian. Each site
contributes `Diagonal(W_i) - Diagonal(W_i) Lambda A_i^{-1} Lambda' Diagonal(W_i)`,
with `A_i = I + Lambda' Diagonal(W_i) Lambda`. Direct assembly therefore
matches the previous basis-vector operator construction up to floating-point
roundoff.

## Files Changed

- `src/structured_schur.jl` - direct dense Schur assembly and sparse precision
  copy specialization.
- `docs/dev-log/check-log.md` - recorded tests, benchmarks, and audit scans.
- `docs/dev-log/after-task/2026-06-01-structured-schur-direct-dense-assembly.md`
  - this audit report.

## Tests Added

Added a structured Schur regression check for `Symmetric(sparse(...), :L)`
precision storage so the new sparse precision copy specialization is exercised
on both triangle orientations. Existing structured Schur tests also compare the
dense matrix, sparse precision storage, CG solves, exact full-basis SLQ logdet,
and structured Poisson implicit gradients against independent
dense/finite-difference references.

## Benchmark Numbers

Direct in-process median timer comparing the previous basis-vector dense
assembly against the new direct assembly on identical operators:

| p | n | K | old basis-vector dense (s) | direct dense (s) | old / direct | max abs diff |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 80 | 80 | 2 | 0.00369 | 0.00014 | 26.45x | 4.44e-16 |
| 160 | 120 | 2 | 0.02183 | 0.00091 | 24.07x | 1.42e-14 |
| 320 | 160 | 2 | 0.11519 | 0.00468 | 24.61x | 1.42e-14 |
| 320 | 160 | 3 | 0.14154 | 0.00547 | 25.87x | 6.66e-16 |

Structured Schur logdet benchmark:

| cell | p | n | K | dense exact (s) | SLQ (s) | dense / SLQ | relerr |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 80 | 20 | 2 | 0.0002 | 0.0095 | 0.02x | 2.119e-03 |
| medium | 160 | 40 | 2 | 0.0008 | 0.0319 | 0.03x | 7.706e-04 |
| large | 320 | 80 | 3 | 0.0035 | 0.1469 | 0.02x | 5.466e-04 |
| frontier | 640 | 160 | 3 | 0.0186 | 0.5673 | 0.03x | 1.449e-04 |

Structured Poisson trace-gradient benchmark:

| state | cell | p | n | K | dense (s) | SLQ (s) | dense / SLQ | value diff | grad rel |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| before | large | 320 | 160 | 2 | 0.1652 | 0.0647 | 2.55x | 6.15e-01 | 1.41e-01 |
| before | frontier | 640 | 160 | 2 | 0.5805 | 0.1283 | 4.53x | 2.46e+00 | 3.18e-01 |
| after | large | 320 | 160 | 2 | 0.0462 | 0.0657 | 0.70x | 6.15e-01 | 1.41e-01 |
| after | frontier | 640 | 160 | 2 | 0.1220 | 0.1336 | 0.91x | 2.46e+00 | 3.18e-01 |

Fitted dense-logdet calibration:

| cell | p | n | K | dense mode (s) | CG mode (s) | dense / CG | abs loglik diff |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 5 | 8 | 1 | 0.0009 | 0.0009 | 1.07x | 9.95e-14 |
| medium | 8 | 12 | 2 | 0.0017 | 0.0020 | 0.88x | 4.15e-12 |
| large | 20 | 25 | 2 | 0.0051 | 0.0079 | 0.65x | 9.09e-13 |

## R-Parity Verdict

Parity: N/A - this internal structured Schur substrate is not a public
`gllvmTMB` parity surface.

## JET / Allocs / Aqua Verdicts

- JET: clean through the `Pkg.test()` quality gate.
- Allocs: no zero-allocation claim; the direct dense path allocates two `p x K`
  workspaces and removes the old `p` operator-matvec dense construction.
- Aqua: clean through the `Pkg.test()` quality gate.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Focused result: 112 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2326 pass, 1 existing broken sparse-phy precision placeholder, 2
expected quality placeholders in the direct core environment, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Full result: 2338 pass, 1 existing broken sparse-phy precision placeholder,
quality 12/12 pass, 0 fail, 0 error.

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-direct-dense-assembly.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-direct-dense-assembly.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over tracked repo content: no matches.
- Placeholder rerun scan: no stale rerun/fill-result placeholders remain after
  this update.
- Stale-wording scan: expected hits only - the user-provided AGENTS.md
  "Gaussian only" snapshot, historical check-log command/result records, and
  this scan command.
- Performance-claim scan: expected hits only - existing Gaussian/gllvmTMB
  claims, historical internal speed records, benchmark-script column names, and
  this report's internal structured Schur/Poisson benchmark evidence. This
  slice adds no R `gllvmTMB` parity claim and no public 20x-100x structured
  speedup claim.
- GitHub lane check: open PR #59 is still the separate draft
  formula/family/CIs catch-up lane; no issue or PR was modified.

## GitHub Issue Maintenance

No issue action was taken. Open PR #59 remains the separate draft formula and
family catch-up lane; this task did not overlap it.

## What Did Not Go Smoothly

The benchmark result flips the earlier dense-vs-SLQ intuition for current
frontier cells: exact dense construction is now so cheap that SLQ is not the
right default below the next large-p break-even study.

## Team Learning

Gauss/Karpinski lesson: before making a stochastic determinant path more
complicated, make the exact dense baseline very efficient and then recompute
the break-even point.

## Remaining Risks

- Exact dense still uses dense Cholesky for `logdet(S_u)`, so very-large-p
  structured dependence still needs a matrix-free path.
- The direct dense path allocates two `p x K` matrices per construction.
- No R `gllvmTMB` comparison is attached to this internal structured substrate.

## Known Limitations

This slice does not add adaptive SLQ probes, a preconditioner, public
structured non-Gaussian API wiring, or R benchmark cells.

## Next Command

```sh
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --full --cells=frontier --reps=5 --warmups=5 --nprobes=16 --lanczos-steps=40
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - direct dense Schur assembly is exact, tested,
and much faster on current internal cells, but very-large-p determinant
break-even evidence is still open.
