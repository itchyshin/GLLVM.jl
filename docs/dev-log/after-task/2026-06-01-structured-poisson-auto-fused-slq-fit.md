# After Task: Structured Poisson Auto Fused SLQ Fit

## Goal

Make the internal structured Poisson fitted SLQ path use the fused Lanczos
trace-gradient solve by default when the determinant path is SLQ.

## Implemented

`_fit_structured_poisson_laplace` now accepts `trace_solve=:auto` as its
default. The fitter maps that value to `:lanczos` for SLQ log-determinant fits
and to `:solve` for dense log-determinant fits, passes the effective choice into
the implicit-gradient objective, and records the effective value in the returned
fit object. The fitted benchmark script defaults to `--trace-solve=auto`, adds
the option to help text, and writes the effective trace solve in CSV output.

## Mathematical Contract

For the structured Poisson Laplace approximation, the fitted objective uses the
site-mode contribution and the structured random-effect Schur determinant
`logdet(S_u)`. When SLQ supplies the stochastic approximation to `logdet(S_u)`,
the fused path also reuses each Lanczos basis to approximate `S_u^{-1}r` for
the trace-gradient probe. With a full scaled identity probe basis and
`lanczos_steps = p`, the fitted auto path must agree with the explicit
`S_u \ R` solve path up to numerical tolerance.

## Files Changed

- `src/families/structured_poisson.jl` - added `trace_solve=:auto` mapping and
  recorded the effective fitted trace solve.
- `test/test_structured_poisson_laplace.jl` - added fitted SLQ auto-vs-solve
  checks with a full probe basis.
- `bench/structured_poisson_fit_bench.jl` - added `--trace-solve=auto`, CSV
  output, and effective-path recording.
- `bench/README.md` - documented the fitted benchmark default.
- `docs/dev-log/check-log.md` - recorded tests, benchmarks, scans, and lane
  checks.

## Tests Added

The internal fitter test now checks `trace_solve=:auto` on an SLQ fitted run,
verifies that the returned fit records `:lanczos`, and compares its fitted
log-likelihood to the explicit `trace_solve=:solve` path under a full-basis SLQ
setup. This would fail before the auto mapping and covers both the new behavior
and an independent exactness-style comparison.

## Benchmark Numbers

Fitted SLQ grid, `reps=1`, `warmups=1`, `iterations=6`:

| trace solve | cell | p | n | K | dense (s) | CG (s) | dense / CG | abs loglik diff |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| solve | small | 5 | 8 | 1 | 0.0018 | 0.0021 | 0.88x | 5.68e-14 |
| solve | medium | 8 | 12 | 2 | 0.0046 | 0.0111 | 0.42x | 4.55e-13 |
| solve | large | 20 | 25 | 2 | 0.0299 | 0.0302 | 0.99x | 2.39e-12 |
| auto -> lanczos | small | 5 | 8 | 1 | 0.0018 | 0.0017 | 1.06x | 5.68e-14 |
| auto -> lanczos | medium | 8 | 12 | 2 | 0.0043 | 0.0041 | 1.04x | 4.26e-13 |
| auto -> lanczos | large | 20 | 25 | 2 | 0.0275 | 0.0226 | 1.22x | 2.61e-12 |

On the CG fitted path, auto-vs-solve measured speedups were about 1.24x,
2.71x, and 1.34x on the small, medium, and large calibration cells.

Larger single-cell probe, `p=80`, `n=80`, `K=2`, `iterations=4`, fixed data and
probes:

```text
p=80 n=80 K=2 solve time=0.2508 effective=solve loglik=-9860.455381 calls=(8,5)
p=80 n=80 K=2 auto  time=0.1987 effective=lanczos loglik=-9860.455381 calls=(8,5) speedup=1.26x diff=1.819e-11
```

CSV smoke succeeded and recorded `trace_solve=lanczos` for
`--trace-solve=auto --logdet=slq`.

## R-Parity Verdict

Parity: N/A - this is an internal Julia fixed-covariance structured Poisson
prototype path and does not touch public R `gllvmTMB` parity surfaces.

## JET / Allocs / Aqua Verdicts

- JET: clean through the `Pkg.test()` quality gate.
- Allocs: no zero-allocation gate added; the change removes repeated trace
  solves for SLQ fitted gradients but does not claim zero allocation.
- Aqua: clean through the `Pkg.test()` quality gate.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_poisson_laplace.jl")'
```

Focused result: 52 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2319 pass, 1 existing broken sparse-phy precision placeholder, 2
expected quality placeholders in the direct core environment, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Full result: 2331 pass, 1 existing broken sparse-phy precision placeholder,
quality 12/12 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --logdet=slq --trace-solve=solve --reps=1 --warmups=1 --iterations=6
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --logdet=slq --trace-solve=auto --reps=1 --warmups=1 --iterations=6
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --smoke --logdet=slq --trace-solve=auto --reps=1 --warmups=1 --iterations=4 --out=/tmp/structured-poisson-fit-auto-smoke.csv
```

Benchmarks completed and produced the tables above; CSV smoke produced the
expected header and row.

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
  and this new internal structured Poisson fitted-benchmark evidence. This
  slice does not add an R `gllvmTMB` parity or public speed claim.

## GitHub Issue Maintenance

No issue action was taken. Open PR #59 remains the separate draft lane for
Delta-Gamma, ZIP/ZINB, and non-Gaussian CIs; this slice did not overlap it.

## What Did Not Go Smoothly

The first large-cell benchmark script printed top-level Julia values because
the quick REPL-style here-doc used plain assignments. The useful evidence was
still the final two timing lines, and the public benchmark script stays quiet.

## Team Learning

Fused value/gradient work should become the default design instinct for the
structured non-Gaussian lane: pay for a Krylov basis once, then extract every
safe estimator it can support.

## Remaining Risks

- The structured Poisson fitter is still private and fixed-covariance only.
- The calibration grid is intentionally small; public speed claims need the
  separate wider gllvmTMB comparison grid.
- Stochastic SLQ gradient accuracy still depends on probe count and Lanczos
  steps for harder covariance shapes.

## Known Limitations

This slice does not add adaptive probe budgets, preconditioned CG, public
structured non-Gaussian APIs, or R `gllvmTMB` comparison cells.

## Next Command

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --logdet=slq --trace-solve=auto --reps=3 --warmups=3 --iterations=10
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - the default fitted SLQ path now uses the fused
Lanczos trace solve and is covered by tests, full suite, and current benchmarks;
the remaining notes are private-prototype scope and need for wider comparison
benchmarks before public speed claims.
