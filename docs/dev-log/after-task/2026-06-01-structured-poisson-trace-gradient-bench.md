# After Task: Structured Poisson Trace-Gradient Bench

## Goal

Make the large-p structured Poisson determinant-gradient tradeoff visible and
trim an avoidable allocation in the dense and SLQ gradient loops.

## Implemented

Added `bench/structured_poisson_trace_gradient_bench.jl`, which isolates one
structured Poisson gradient evaluation and reports dense block time, SLQ
trace-gradient time, value difference, and gradient relative error. Also reused
the `K×K` site inverse workspace inside dense block and SLQ trace gradient loops
instead of allocating one small matrix per site.

## Mathematical Contract

The benchmark compares the exact dense block gradient against the frozen-probe
SLQ trace-gradient estimator for the same fixed-covariance structured Poisson
Laplace surface. The estimator is the Hutchinson approximation to
`tr(S_u^{-1} dS_u)` with frozen probes, so timing evidence must be read together
with gradient relative error.

## Files Changed

- `src/families/structured_poisson.jl` — reused the per-site `K×K` inverse
  workspace in dense and SLQ gradient loops.
- `bench/structured_poisson_trace_gradient_bench.jl` — new dense-vs-SLQ
  gradient scaling benchmark with CSV output.
- `bench/README.md` — documented the trace-gradient benchmark.
- `docs/dev-log/check-log.md` — recorded tests, benchmarks, scans, and lane
  checks.

## Tests Added

No new unit test was needed because this slice does not change the mathematical
contract; the existing structured Poisson full-basis SLQ gradient test still
guards correctness. The new benchmark script was smoke-run and CSV output was
checked.

## Benchmark Numbers

Allocation/timing spot check for one SLQ trace-gradient call at `p=160,n=120,K=2`:

| state | time (s) | allocated bytes |
| --- | ---: | ---: |
| before | 0.03400 | 869920 |
| after | 0.03400 | 858496 |

Trace-gradient scaling benchmark, `reps=1`, `warmups=2`, `nprobes=4`,
`lanczos_steps=20`:

| cell | p | n | dense (s) | SLQ (s) | dense / SLQ | value diff | gradient relative error |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 80 | 80 | 0.0098 | 0.0121 | 0.81x | 1.36e-01 | 6.79e-02 |
| medium | 160 | 120 | 0.0379 | 0.0358 | 1.06x | 4.18e-01 | 7.70e-02 |
| large | 320 | 160 | 0.1583 | 0.0855 | 1.85x | 3.99e-01 | 1.07e-01 |
| frontier | 640 | 160 | 0.5423 | 0.1730 | 3.13x | 7.84e-01 | 1.62e-01 |

## R-Parity Verdict

Parity: N/A — this benchmark is internal Julia evidence for a fixed-covariance
structured Poisson prototype and does not touch public R parity surfaces.

## JET / Allocs / Aqua Verdicts

- JET: clean through `Pkg.test()` quality gate.
- Allocs: small improvement in the measured SLQ trace-gradient call, from
  869920 to 858496 bytes.
- Aqua: clean through `Pkg.test()` quality gate.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_poisson_laplace.jl")'
```

Focused result: 44 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --smoke --out=/tmp/structured-poisson-trace-gradient-smoke.csv
head -2 /tmp/structured-poisson-trace-gradient-smoke.csv
```

Smoke benchmark and CSV header/row succeeded.

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --full --reps=1 --warmups=2
```

Full benchmark succeeded and produced the scaling table above.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2303 pass, 1 existing broken sparse-phy precision placeholder, 2
expected quality placeholders in the direct core environment, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Full result: 2315 pass, 1 existing broken sparse-phy precision placeholder,
quality 12/12 pass, 0 fail, 0 error.

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
```

`git diff --check` was clean. The private-upload trace scan had no matches.
The stale-wording scan still finds the user-provided AGENTS.md "Gaussian only"
snapshot and historical check-log entries; those were not edited. The
performance scan finds existing Gaussian/gllvmTMB claims and historical
internal benchmark records; this new report labels the claim as internal
structured Poisson trace-gradient scaling evidence only.

## GitHub Issue Maintenance

No issue action was taken. Open PR #59 is the separate
`claude/package-work-catchup-mQiZM` draft lane for Delta-Gamma, ZIP/ZINB, and
non-Gaussian CIs; this task did not touch that lane.

## What Did Not Go Smoothly

The allocation cleanup was smaller than hoped: the dominant allocations are now
elsewhere in mode/logdet/Schur work. The benchmark script is the more valuable
output of this slice.

## Team Learning

Trace-gradient claims need a paired timing/error table; otherwise the fastest
probe budget could quietly be too noisy for fitting.

## Remaining Risks

- The four-probe SLQ gradient is visibly approximate; probe-budget tuning still
  needs fitted ADEMP evidence.
- The benchmark is Julia-only and internal; no R `gllvmTMB` parity claim is
  made.
- Further allocation work should target mode/logdet workspace reuse, not just
  the tiny site inverse.

## Known Limitations

This slice does not make SLQ the default fitted path and does not implement
adaptive probe selection or variance reduction.

## Next Command

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --full --reps=1 --warmups=2
```

## Rose Verdict

Rose verdict: PASS WITH NOTES — benchmark evidence is now durable, but probe
accuracy must be studied before public structured SLQ fitting.
