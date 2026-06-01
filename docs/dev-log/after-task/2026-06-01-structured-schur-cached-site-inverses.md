# After Task: Structured Schur Cached Site Inverses

## Goal

Reduce repeated tiny site-level solves in the structured Schur operator used by
the structured Poisson implicit-gradient prototype.

## Implemented

`_SchurUOperator` now stores the per-site inverse matrices `A_i^{-1}` alongside
the existing Cholesky factors. The workspace owns those buffers, refreshes them
when each operator is built, and the Schur matvec plus structured Poisson
block/trace/joint solve paths now use small dense matrix-vector products rather
than repeatedly solving the same tiny systems.

## Mathematical Contract

For each site, the Schur operator uses
`A_i = I_K + Λ' Diagonal(W_i) Λ`. The cached matrix must satisfy
`A_i^{-1} = cholesky(A_i) \ I_K` and all uses must be algebraically equivalent
to the previous `ldiv!` calls. The structured Poisson Laplace value and
implicit-gradient checks continue to compare dense, CG, SLQ, and fused-Lanczos
paths under exact full-basis probes.

## Files Changed

- `src/structured_schur.jl` - added `Ainvs` to the operator/workspace and used
  it in `_schur_u_mul!`.
- `src/families/structured_poisson.jl` - reused cached site inverses in the
  joint solve, dense block gradient, and SLQ trace-gradient path.
- `test/test_structured_schur.jl` - added explicit cached-inverse correctness
  and workspace-reuse checks.
- `docs/dev-log/check-log.md` - recorded tests, benchmarks, scans, and lane
  checks.

## Tests Added

The structured Schur operator test now checks each cached `A_i^{-1}` against an
explicit site-level inverse and verifies that workspace-built operators share
the reusable inverse buffers. This would fail without the new cached-inverse
storage and covers the independent-calculation clause.

## Benchmark Numbers

Fitted SLQ auto benchmark, `reps=3`, `warmups=3`, `iterations=10`:

| state | cell | p | n | K | dense (s) | CG (s) | dense / CG | abs loglik diff |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| before | small | 5 | 8 | 1 | 0.0063 | 0.0057 | 1.09x | 5.87e-12 |
| before | medium | 8 | 12 | 2 | 0.0067 | 0.0063 | 1.06x | 3.41e-12 |
| before | large | 20 | 25 | 2 | 0.0393 | 0.0317 | 1.24x | 5.34e-12 |
| after | small | 5 | 8 | 1 | 0.0030 | 0.0039 | 0.77x | 5.83e-12 |
| after | medium | 8 | 12 | 2 | 0.0045 | 0.0042 | 1.09x | 3.41e-12 |
| after | large | 20 | 25 | 2 | 0.0268 | 0.0225 | 1.19x | 5.12e-12 |

CG fitted-path times improved by about 1.46x, 1.50x, and 1.41x on the small,
medium, and large calibration cells. Dense timings also moved because the
dense-mode gradient path uses the same cached inverses, but the tiny-cell
ratios are noisy.

Trace-gradient benchmark, `large,frontier`, `nprobes=4`, `lanczos_steps=20`,
`trace_solve=lanczos`:

| state | cell | p | n | K | dense (s) | SLQ (s) | dense / SLQ | value diff | grad rel |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| before | large | 320 | 160 | 2 | 0.1616 | 0.0676 | 2.39x | 6.15e-01 | 1.41e-01 |
| before | frontier | 640 | 160 | 2 | 0.5584 | 0.1337 | 4.18x | 2.46e+00 | 3.18e-01 |
| after | large | 320 | 160 | 2 | 0.1593 | 0.0651 | 2.45x | 6.15e-01 | 1.41e-01 |
| after | frontier | 640 | 160 | 2 | 0.5268 | 0.1311 | 4.02x | 2.46e+00 | 3.18e-01 |

This is a modest repeated-matvec improvement: useful in fitted CG cells,
slightly positive in SLQ trace time, and roughly neutral on the frontier ratio.

## R-Parity Verdict

Parity: N/A - this is an internal Julia structured-Schur/structured-Poisson
prototype optimization and does not touch public R `gllvmTMB` parity surfaces.

## JET / Allocs / Aqua Verdicts

- JET: clean through the `Pkg.test()` quality gate.
- Allocs: no zero-allocation gate added; this slice trades a small cached
  matrix allocation per site for fewer repeated factor solves in hot matvecs.
- Aqua: clean through the `Pkg.test()` quality gate.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Focused result: 111 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2325 pass, 1 existing broken sparse-phy precision placeholder, 2
expected quality placeholders in the direct core environment, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Full result: 2337 pass, 1 existing broken sparse-phy precision placeholder,
quality 12/12 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --logdet=slq --trace-solve=auto --reps=3 --warmups=3 --iterations=10
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --full --cells=large,frontier --trace-solve=lanczos --reps=3 --warmups=3 --nprobes=4 --lanczos-steps=20
```

Benchmarks completed before and after the code change and produced the tables
above.

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over `README.md`, `docs/src`, `docs/dev-log`,
  `bench`, `src`, `test`, `CLAUDE.md`, and `AGENTS.md`: no matches.
- Stale-wording scan: expected hits only - the AGENTS.md Gaussian-only
  snapshot, historical check-log command/result records, and the newly recorded
  scan command itself. This slice adds no new public status claim.
- Performance-claim scan: expected hits only - existing Gaussian/gllvmTMB
  claims, historical internal benchmark records, benchmark-script column names,
  and this new internal structured Schur fitted/trace benchmark evidence. This
  slice does not add an R `gllvmTMB` parity or public speed claim.

## GitHub Issue Maintenance

No issue action was taken. Open PR #59 remains the separate draft formula and
family catch-up lane; this task did not overlap it.

## What Did Not Go Smoothly

The benchmark did not produce a uniform headline speedup. Cached inverses help
when Schur matvecs are reused heavily, but they add small setup work and the
frontier trace-gradient ratio is effectively neutral.

## Team Learning

For the structured path, optimize the actual reuse pattern: caching small
linear algebra is worthwhile when it feeds many Krylov and adjoint solves, but
must be benchmarked at both fitted and objective levels.

## Remaining Risks

- The private structured Poisson fitted grid is still deliberately small.
- Wider covariance-shape and probe-budget sweeps are still needed before any
  public speed claim.
- The cached inverses are algebraically equivalent but may not be the best
  memory trade-off for very large `n` and larger `K`.

## Known Limitations

This slice does not add adaptive probe counts, preconditioning, a public
structured non-Gaussian API, or R `gllvmTMB` comparison cells.

## Next Command

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --full --cells=large,frontier --probe-kind=orthogonal --trace-solve=lanczos --nprobes=8 --reps=3 --warmups=3
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - cached site inverses are tested and improve the
repeated-matvec fitted path, but the speedup is modest and should remain an
internal structured-prototype claim.
