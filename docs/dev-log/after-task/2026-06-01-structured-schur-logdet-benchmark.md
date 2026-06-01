# After Task: Structured Schur Logdet Benchmark

## Goal

Turn the structured Schur/SLQ substrate into a measurable fast-algorithm
workbench for dense-versus-SLQ determinant decisions.

## Implemented

Added `bench/structured_schur_logdet_bench.jl`, a Julia-only benchmark that
constructs sparse-precision structured Schur fixtures, compares exact dense
`logdet(S_u)` with frozen-probe SLQ, reports dense/SLQ speedup and SLQ relative
error, and optionally writes CSV output. Updated `bench/README.md` with the run
commands and interpretation.

## Mathematical Contract

The benchmark exercises the internal Schur determinant block

```text
S_u x = σ⁻² Qx + (sum_s w_s) .* x
        - sum_s D_s Λ (I + Λ' D_s Λ)⁻¹ Λ' D_s x,
```

using exact dense `logdet(S_u)` as the small/medium-`p` reference and
frozen-probe SLQ as the large-`p` approximation.

## Files Changed

bench:

- `bench/structured_schur_logdet_bench.jl` — new benchmark harness.
- `bench/README.md` — documents smoke/full runs and the probe/step trade-off.

docs:

- `docs/dev-log/check-log.md` — benchmark numbers and verification evidence.
- `docs/dev-log/after-task/2026-06-01-structured-schur-logdet-benchmark.md` —
  this audit.

## Tests Added

No package tests were added because this slice adds a benchmark harness, not new
library behaviour. Existing structured Schur tests were rerun and continue to
cover exact dense, exact-basis SLQ, auto selector branches, malformed inputs,
and sparse precision preservation.

## Benchmark Numbers

Default speed-oriented grid, 4 frozen Rademacher probes and 20 Lanczos steps:

| cell | p | n | K | dense (s) | SLQ (s) | dense / SLQ | relative error |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| smoke | 80 | 12 | 2 | 0.0008 | 0.0009 | 0.95x | 5.371e-3 |
| small | 80 | 20 | 2 | 0.0013 | 0.0013 | 0.96x | 4.382e-3 |
| medium | 160 | 40 | 2 | 0.0083 | 0.0043 | 1.94x | 2.776e-3 |
| large | 320 | 80 | 3 | 0.0743 | 0.0189 | 3.92x | 3.018e-3 |
| frontier | 640 | 160 | 3 | 0.5886 | 0.0734 | 8.02x | 2.825e-4 |

Accuracy-oriented sweep with 8 probes and 20 steps:

| cell | p | n | K | dense (s) | SLQ (s) | dense / SLQ | relative error |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| large | 320 | 80 | 3 | 0.0764 | 0.0375 | 2.04x | 4.717e-4 |
| frontier | 640 | 160 | 3 | 0.5849 | 0.1440 | 4.06x | 6.225e-4 |

Verdict: dense remains correct and fastest at p≈80; SLQ becomes useful by
p≈160 and reaches 4–8x on the larger benchmark cells. This is determinant-only
evidence, not a fitted-model speed claim.

## R-Parity Verdict

Parity: N/A — this benchmark does not change any public fitted likelihood or R
`gllvmTMB` comparable API.

## JET / Allocs / Aqua Verdicts

- JET: package quality gate passed through `Pkg.test()`; no new package source
  path was added in this slice.
- Allocs: benchmark records `dense_bytes` and `slq_bytes` in CSV output; no
  package allocation claim was made.
- Aqua: clean via `Pkg.test()` quality block, 12/12 pass.

## Checks Run

```sh
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --smoke --reps=3
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --full --reps=3
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --full --cells=large,frontier --reps=3 --nprobes=8 --lanczos-steps=20
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --smoke --reps=1 --out=/tmp/structured-schur-smoke.csv
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl")'
julia --project=. --startup-file=no test/runtests.jl
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
git diff --check
```

Observed tallies:

```text
structured Schur operator             | 22/22 pass
structured Schur SLQ logdet           | 9/9 pass
core manual tally                     | 2257 pass, 1 existing broken, 2 expected quality placeholders, 0 fail, 0 error
Pkg.test manual tally                 | 2257 pass, 1 existing broken, 0 fail, 0 error
Pkg.test quality                      | 12/12 pass
Testing GLLVM tests passed
```

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
  speedup notes; no fitted structured-model speed claim was added.

## GitHub Issue Maintenance

No issue action taken. Draft PR #59 is still the active non-Gaussian CI /
extra-family lane, and this benchmark stayed out of those files.

## What Did Not Go Smoothly

The first timing pass let allocation measurement contaminate tiny p=80 timings
and produced bogus 100x-class values. The benchmark now warms the measured path
and allocation probe separately, with three default warmups; the recorded
numbers above are the corrected ones.

## Team Learning

Fisher and Karpinski should treat p≈160 as the first plausible dense-to-SLQ
switch point for this fixture, then tune probe/step counts against fitted
objective stability rather than determinant error alone.

## Remaining Risks

- This is determinant-only evidence; it is not yet a structured non-Gaussian
  fitted-model benchmark.
- SLQ objective smoothness under L-BFGS is still untested.
- Probe-count tuning is fixture-dependent; the default 4-probe setting is a
  speed-oriented starting point, not a universal accuracy guarantee.

## Known Limitations

The benchmark uses a sparse tridiagonal precision fixture, not a full
phylogenetic node-frame precision, and it does not compare to R `gllvmTMB`.

## Next Command

```sh
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --full --reps=3
```

## Rose Verdict

Rose verdict: PASS WITH NOTES — benchmark evidence is useful and reproducible,
but it proves only the determinant subproblem, not full structured
non-Gaussian fitting.
