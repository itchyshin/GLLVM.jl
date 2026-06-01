# After Task: Structured Poisson Orthogonal Probes

## Goal

Add a controlled alternative probe strategy for the structured Poisson SLQ
trace-gradient workbench without changing the default fitted path.

## Implemented

Added internal scaled orthogonal Gaussian probes via `GLLVM._orthogonal_probes`
and wired `bench/structured_poisson_trace_gradient_bench.jl` with
`--probe-kind=rademacher|orthogonal`. The benchmark CSV now records
`probe_kind`, and `bench/README.md` documents orthogonal probes as a
probe-study control rather than a default algorithm.

## Mathematical Contract

For `p` traits and `m <= p` probes, `_orthogonal_probes` returns a dense
`p x m` matrix `P` with `P'P = pI`. Those frozen probes feed the same SLQ
approximation used by the structured Schur determinant and trace-gradient
prototype: the determinant-gradient term is approximated with frozen probes for
`tr(S_u^{-1} dS_u)`, so timing evidence must be interpreted together with value
and gradient error.

## Files Changed

- `src/structured_schur.jl` — added `_orthogonal_probes`.
- `test/test_structured_schur.jl` — added scaled-Gram, SLQ-compatibility, and
  malformed-input tests for orthogonal probes.
- `bench/structured_poisson_trace_gradient_bench.jl` — added
  `--probe-kind=` and row-level `probe_kind` output.
- `bench/README.md` — documented the optional probe strategy.
- `docs/dev-log/check-log.md` — recorded tests, benchmarks, lane checks, and
  audit notes.

## Tests Added

The new tests would fail without this helper: they check shape, scaled
orthogonality, compatibility with `_slq_logdet`, and the `nprobes > p`
`ArgumentError` path.

## Benchmark Numbers

Smoke paths:

| probe kind | dense (s) | SLQ (s) | dense / SLQ | value diff | gradient relative error |
| --- | ---: | ---: | ---: | ---: | ---: |
| rademacher | 0.0098 | 0.0121 | 0.81x | 1.36e-01 | 6.79e-02 |
| orthogonal | 0.0851 | 0.0149 | 5.73x | 2.12e-01 | 6.44e-02 |

Large/frontier, `nprobes=4`, `lanczos_steps=20`, `reps=1`, `warmups=2`:

| probe kind | cell | p | n | dense (s) | SLQ (s) | dense / SLQ | value diff | gradient relative error |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| rademacher | large | 320 | 160 | 0.1973 | 0.0837 | 2.36x | 6.15e-01 | 1.41e-01 |
| rademacher | frontier | 640 | 160 | 0.5337 | 0.1672 | 3.19x | 2.46e+00 | 3.18e-01 |
| orthogonal | large | 320 | 160 | 0.1815 | 0.0848 | 2.14x | 7.40e-01 | 1.49e-01 |
| orthogonal | frontier | 640 | 160 | 0.5460 | 0.1708 | 3.20x | 2.72e+00 | 3.34e-01 |

Large cell, `nprobes=16`, `lanczos_steps=20`, `reps=1`, `warmups=2`:

| probe kind | dense (s) | SLQ (s) | dense / SLQ | value diff | gradient relative error |
| --- | ---: | ---: | ---: | ---: | ---: |
| rademacher | 0.1591 | 0.2320 | 0.69x | 7.08e-01 | 6.98e-02 |
| orthogonal | 0.1582 | 0.2314 | 0.68x | 2.12e-01 | 6.61e-02 |

Interpretation: orthogonal probes are worth keeping as an experimental control.
They are not yet a better default: at four probes they were not more accurate on
the live large/frontier cells, and at 16 probes they improved noise modestly but
were slower than dense at `p=320`.

## R-Parity Verdict

Parity: N/A — this is an internal Julia benchmark/control for the structured
Poisson prototype and does not touch public R `gllvmTMB` parity surfaces.

## JET / Allocs / Aqua Verdicts

- JET: clean through the `Pkg.test()` quality gate.
- Allocs: no allocation gate added; this slice adds probe construction and
  benchmark controls, not a fitted hot-loop replacement.
- Aqua: clean through the `Pkg.test()` quality gate.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl")'
```

Focused result: `structured Schur operator` 36/36 pass;
`structured Schur SLQ logdet` 14/14 pass.

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --smoke --probe-kind=rademacher
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --smoke --probe-kind=orthogonal
```

Both benchmark CLI paths completed.

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --full --cells=large,frontier --probe-kind=rademacher --reps=1 --warmups=2
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --full --cells=large,frontier --probe-kind=orthogonal --reps=1 --warmups=2
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --full --cells=large --probe-kind=rademacher --nprobes=16 --reps=1 --warmups=2
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --full --cells=large --probe-kind=orthogonal --nprobes=16 --reps=1 --warmups=2
```

Probe comparison benchmarks completed and produced the tables above.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2308 pass, 1 existing broken sparse-phy precision placeholder, 2
expected quality placeholders in the direct core environment, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Full result: 2320 pass, 1 existing broken sparse-phy precision placeholder,
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
new public status claim. The
performance scan finds existing Gaussian/gllvmTMB speedup claims and historical
internal structured benchmark records; this report labels the orthogonal-probe
result as optional internal evidence only.

## GitHub Issue Maintenance

No issue action was taken. Open PR #59 is the separate
`claude/package-work-catchup-mQiZM` draft lane for Delta-Gamma, ZIP/ZINB, and
non-Gaussian CIs; this task did not touch that lane.

## What Did Not Go Smoothly

The orthogonal probe idea was less exciting than hoped at the four-probe
operating point. It is useful as a variance-control experiment, but the live
numbers argue against promoting it to the default fast path.

## Team Learning

Probe-strategy changes should be logged as timing-plus-error evidence. A
strategy that looks clever algebraically still has to earn its place against
the dense baseline and the simplest frozen Rademacher probes.

## Remaining Risks

- Probe choice is still a local benchmark decision; fitted ADEMP evidence is
  needed before any public structured SLQ default changes.
- Orthogonal probes are dense and generated by modified Gram-Schmidt; for very
  large `p`, generation cost and memory should be revisited if probes are built
  repeatedly.
- This is Julia-only internal evidence, not R `gllvmTMB` parity.

## Known Limitations

This slice does not implement adaptive probe budgets, randomized low-variance
estimators beyond orthogonal Gaussian probes, or a public structured
non-Gaussian API.

## Next Command

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --full --cells=frontier --probe-kind=rademacher --nprobes=8 --reps=3 --warmups=3
```

## Rose Verdict

Rose verdict: PASS WITH NOTES — the optional probe control is verified and
documented, but the evidence does not support making it the default.
