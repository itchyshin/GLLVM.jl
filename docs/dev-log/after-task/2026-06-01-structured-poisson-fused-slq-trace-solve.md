# After Task: Structured Poisson Fused SLQ Trace Solve

## Goal

Remove avoidable repeated work from the structured Poisson SLQ trace-gradient
path by reusing the Lanczos basis already built for `logdet(S_u)`.

## Implemented

Added `_slq_logdet_invprobes`, an internal helper that returns both the SLQ
log-determinant estimate and the corresponding Lanczos approximation to
`S_u^{-1}R`. Wired the structured Poisson trace-gradient path with
`trace_solve=:lanczos`, leaving the previous explicit solve path as the default
`trace_solve=:solve`. The trace-gradient benchmark now exposes
`--trace-solve=solve|lanczos` and records the choice in CSV output.

## Mathematical Contract

For each probe `r`, Lanczos builds `Q_m T_m Q_m'` for the Schur operator
`S_u`. The existing SLQ logdet estimate uses
`||r||^2 e_1' log(T_m) e_1`; the new fused path also computes
`S_u^{-1}r ≈ ||r|| Q_m T_m^{-1} e_1`. With a full scaled identity probe basis
and `m = p`, this must recover the exact dense `S_u \ R` solve up to numerical
roundoff.

## Files Changed

- `src/structured_schur.jl` — added the fused SLQ logdet/inverse-probe helper.
- `src/families/structured_poisson.jl` — added optional
  `trace_solve=:lanczos` for the SLQ trace-gradient path and internal fitter.
- `test/test_structured_schur.jl` — added full-basis inverse-probe exactness
  and malformed-probe tests.
- `test/test_structured_poisson_laplace.jl` — added full-basis fused
  trace-gradient exactness and invalid `trace_solve` tests.
- `bench/structured_poisson_trace_gradient_bench.jl` — added
  `--trace-solve=` and CSV output.
- `bench/README.md` — documented the fused benchmark option.
- `docs/dev-log/check-log.md` — recorded tests, benchmarks, scans, and lane
  checks.

## Tests Added

The new tests would fail without the helper and wiring. They check exact
full-basis recovery against `S_u \ R`, fused structured Poisson value/gradient
agreement with the dense/block gradient to `1e-6`, CSV-compatible benchmark
wiring, and malformed `trace_solve` / probe dimensions.

## Benchmark Numbers

Large/frontier trace-gradient comparison, `nprobes=4`, `lanczos_steps=20`,
`reps=1`, `warmups=2`:

| trace solve | cell | p | n | dense (s) | SLQ (s) | dense / SLQ | value diff | gradient relative error |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| solve | large | 320 | 160 | 0.1599 | 0.0873 | 1.83x | 6.15e-01 | 1.41e-01 |
| solve | frontier | 640 | 160 | 0.5523 | 0.1719 | 3.21x | 2.46e+00 | 3.18e-01 |
| lanczos | large | 320 | 160 | 0.1785 | 0.0700 | 2.55x | 6.15e-01 | 1.41e-01 |
| lanczos | frontier | 640 | 160 | 0.5628 | 0.1341 | 4.20x | 2.46e+00 | 3.18e-01 |

Frontier comparison, `nprobes=8`, `lanczos_steps=20`, `reps=1`, `warmups=2`:

| trace solve | cell | p | n | dense (s) | SLQ (s) | dense / SLQ | value diff | gradient relative error |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| solve | frontier | 640 | 160 | 0.5606 | 0.2729 | 2.05x | 1.55e-01 | 1.36e-01 |
| lanczos | frontier | 640 | 160 | 0.5937 | 0.1970 | 3.01x | 1.55e-01 | 1.36e-01 |

The fused path preserved the same value and gradient approximation for fixed
probes while reducing SLQ trace-gradient time by about 20-30% on the large
cells tested.

## R-Parity Verdict

Parity: N/A — this is an internal Julia fast path for a private
fixed-covariance structured Poisson prototype and does not touch public R
`gllvmTMB` parity surfaces.

## JET / Allocs / Aqua Verdicts

- JET: clean through the `Pkg.test()` quality gate.
- Allocs: no zero-allocation gate added; this slice removes repeated solve work
  but still allocates Lanczos work arrays as before.
- Aqua: clean through the `Pkg.test()` quality gate.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Focused result: 101 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --smoke --trace-solve=lanczos --out=/tmp/structured-poisson-trace-fused-smoke.csv
head -2 /tmp/structured-poisson-trace-fused-smoke.csv
```

Smoke benchmark and CSV header/row succeeded; the header includes
`trace_solve`.

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --full --cells=large,frontier --trace-solve=solve --reps=1 --warmups=2
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --full --cells=large,frontier --trace-solve=lanczos --reps=1 --warmups=2
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --full --cells=frontier --trace-solve=solve --nprobes=8 --reps=1 --warmups=2
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --full --cells=frontier --trace-solve=lanczos --nprobes=8 --reps=1 --warmups=2
```

Benchmarks completed and produced the tables above.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2315 pass, 1 existing broken sparse-phy precision placeholder, 2
expected quality placeholders in the direct core environment, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Full result: 2327 pass, 1 existing broken sparse-phy precision placeholder,
quality 12/12 pass, 0 fail, 0 error.

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
```

`git diff --check` was clean after code and documentation edits. The
private-source trace scan found no matches in tracked repo content. The
stale-wording scan is expected to find the user-provided AGENTS.md
"Gaussian only" snapshot plus historical check-log entries; this slice adds no
new public status claim. The performance scan finds existing Gaussian/gllvmTMB
speedup claims and historical internal structured benchmark records; this
report labels the fused-Lanczos result as internal trace-gradient evidence only.

## GitHub Issue Maintenance

No issue action was taken. Open PR #59 is the separate
`claude/package-work-catchup-mQiZM` draft lane for Delta-Gamma, ZIP/ZINB, and
non-Gaussian CIs; this task did not touch that lane.

## What Did Not Go Smoothly

Jacobi preconditioning was tested as a quick side probe and was slower because
the diagonal setup dominated the saved CG iterations. Sparse base preconditioning
looked promising in scratch timing but needs an allocation-conscious in-place
implementation before it deserves a code slice.

## Team Learning

For stochastic trace gradients, the cleanest speedups come from reusing work
already paid for. The Lanczos basis gives both `log(S_u)` and an inverse-probe
approximation, so the next algorithm should keep coupling value and gradient
work rather than bolting on separate solves.

## Remaining Risks

- The fused path shares the same stochastic approximation error as the SLQ
  probes; fitted ADEMP evidence is still needed before a public default changes.
- Approximate inverse-probe gradients may need more Lanczos steps than logdet
  estimates on harder covariance structures.
- This is Julia-only internal evidence, not R `gllvmTMB` parity.

## Known Limitations

This slice does not implement adaptive probe budgets, preconditioned CG, or a
public structured non-Gaussian API.

## Next Command

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --full --cells=large,frontier --trace-solve=lanczos --nprobes=8 --reps=3 --warmups=3
```

## Rose Verdict

Rose verdict: PASS WITH NOTES — fused Lanczos removes repeated trace-probe
solve work and is verified against exact full-basis checks, but public defaults
still need fitted stability evidence.
