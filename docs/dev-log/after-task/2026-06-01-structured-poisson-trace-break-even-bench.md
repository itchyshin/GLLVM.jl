# After Task: Structured Poisson Trace Break-Even Bench

## Goal

Make the structured Poisson trace-gradient benchmark safer for true dense/SLQ
crossover studies around the exact-dense cutoff.

## Implemented

`bench/structured_poisson_trace_gradient_bench.jl` now has `--break-even` mode
with cells at `p = 640, 1024, 1536, 2048`, plus `--skip-dense` for exploratory
SLQ-only timing above the exact-dense comfort zone. Rows with skipped dense
reference now print `NA` in stdout and record `missing` in dense speed/accuracy
CSV fields. `bench/README.md` documents the new command and warns that
probe-kind comparisons should be run sequentially.

## Mathematical Contract

No likelihood or gradient formula changed. The benchmark still compares the
same exact dense block-gradient reference against the same frozen-probe
SLQ/Lanczos trace-gradient approximation for the internal fixed-covariance
structured Poisson Laplace prototype.

## Files Changed

- `bench/structured_poisson_trace_gradient_bench.jl` - added break-even cells,
  `--break-even`, `--skip-dense`, `missing` dense fields, and NA stdout
  formatting.
- `bench/README.md` - documented break-even mode, skip-dense exploratory runs,
  and the sequential benchmark warning.
- `docs/dev-log/check-log.md` - evidence ledger entry.
- `docs/dev-log/after-task/2026-06-01-structured-poisson-trace-break-even-bench.md`
  - this audit report.

## Tests Added

No package tests were added because this is a benchmark CLI/control-surface
slice. Behaviour was checked by help output, a dense frontier break-even run, a
skip-dense giant run, CSV inspection, and an invalid-cell failure path.

## Benchmark Numbers

Discarded evidence: concurrent Rademacher/orthogonal frontier runs inflated
dense timings to roughly 30 seconds and made SLQ appear about 150x faster. Those
parallel timings are not treated as evidence.

Sequential frontier run:

```text
Structured Poisson trace-gradient benchmark (break-even); reps=3, warmups=2, probe_kind=orthogonal, nprobes=8, steps=20, trace_solve=lanczos, dense=true
frontier p= 640 n= 160 K=2 dense=  0.0946 s  slq=  0.1897 s  speedup=   0.50x  valuediff=1.78e-01  gradrel=1.13e-01
```

SLQ-only larger exploratory run:

```text
Structured Poisson trace-gradient benchmark (break-even); reps=3, warmups=2, probe_kind=orthogonal, nprobes=16, steps=20, trace_solve=lanczos, dense=false
giant    p=1024 n= 256 K=2 dense=      NA s  slq=  0.7845 s  speedup=      NA  valuediff=NA  gradrel=NA
```

Interpretation: at `p=640`, exact dense still wins on this machine. The current
large-p story should remain "use exact dense below the cutoff; use SLQ for true
larger-p or memory-avoidance studies", not a blanket 100x speedup claim.

Sequential edge sweep after the harness commit:

```text
giant    p=1024 n= 256 K=2 dense=  0.2910 s  slq=  0.7843 s  speedup=   0.37x  valuediff=7.29e-01  gradrel=9.89e-02
huge     p=1536 n= 320 K=2 dense=  0.6524 s  slq=  1.4708 s  speedup=   0.44x  valuediff=2.31e-01  gradrel=1.37e-01
xlarge   p=2048 n= 512 K=2 dense=  1.4356 s  slq=  3.2011 s  speedup=   0.45x  valuediff=4.48e-01  gradrel=1.69e-01
```

Interpretation: the current exact-dense cutoff at `p=2048` is conservative in
the right direction for this trace-gradient configuration; SLQ is not faster up
to the cutoff under sequential load.

## R-Parity Verdict

Parity: N/A - this is an internal fixed-covariance benchmark harness change,
not a public R `gllvmTMB` parity surface.

## JET / Allocs / Aqua Verdicts

- JET: not rerun specifically for this benchmark-only slice; package code was
  not edited.
- Allocs: N/A - no package hot path changed.
- Aqua: not rerun specifically for this benchmark-only slice; package code was
  not edited.

## CI And Bootstrap Status

No confidence-interval or bootstrap code was edited. The preceding full package
gate on this branch passed quality 12/12; this slice changes only benchmark
scripts and logs.

## Checks Run

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --help
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=frontier --trace-solve=lanczos --probe-kind=orthogonal --nprobes=8 --lanczos-steps=20 --reps=3 --warmups=2 --out=/tmp/structured-poisson-trace-break-even-frontier-dense-seq.csv
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=giant --skip-dense --trace-solve=lanczos --probe-kind=orthogonal --nprobes=16 --lanczos-steps=20 --reps=3 --warmups=2 --out=/tmp/structured-poisson-trace-break-even-giant-skipdense.csv
head -n 2 /tmp/structured-poisson-trace-break-even-frontier-dense-seq.csv
head -n 2 /tmp/structured-poisson-trace-break-even-giant-skipdense.csv
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=nope --skip-dense --reps=1 --warmups=0
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=giant --trace-solve=lanczos --probe-kind=orthogonal --nprobes=16 --lanczos-steps=20 --reps=1 --warmups=1 --out=/tmp/structured-poisson-trace-break-even-giant-dense-seq.csv
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=huge --trace-solve=lanczos --probe-kind=orthogonal --nprobes=16 --lanczos-steps=20 --reps=1 --warmups=1 --out=/tmp/structured-poisson-trace-break-even-huge-dense-seq.csv
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=xlarge --trace-solve=lanczos --probe-kind=orthogonal --nprobes=16 --lanczos-steps=20 --reps=1 --warmups=1 --out=/tmp/structured-poisson-trace-break-even-xlarge-dense-seq.csv
```

Benchmark CLI result: help, dense break-even mode, skip-dense mode, CSV
recording, and invalid-cell validation all behaved as expected.

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Focused result: 122 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2336 pass, 1 existing broken sparse-phy precision placeholder, 2
expected quality placeholders in the direct core environment, 0 fail, 0 error.

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-trace-break-even-bench.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-trace-break-even-bench.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean after this report.
- Private-source trace scan over tracked public artifacts: no matches.
- Placeholder rerun scan: no stale rerun/fill-result placeholders.
- Stale-wording scan: expected historical and command-pattern hits only.
- Performance-claim scan: expected historical benchmark records, existing
  Gaussian/gllvmTMB claims, and this corrected internal benchmark evidence
  only; no public 100x structured speed claim was added.
- GitHub lane check: PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM` lane; no PR or issue was modified.

## GitHub Issue Maintenance

No issue action was taken. This slice keeps the structured determinant
benchmark lane honest and does not change public family support, CI/bootstrap,
or R parity surfaces.

## What Did Not Go Smoothly

Parallel benchmark runs looked exciting but were wrong: resource contention
inflated the dense reference by two orders of magnitude. The fix is mundane but
important: add a safer break-even mode and explicitly warn that probe-kind
timing comparisons must be sequential.

## Team Learning

Rose/Fisher/Karpinski: speedup evidence has to be collected under comparable
load. A 100x-looking number from parallel benchmark contention is worse than no
number because it points the algorithm lane in the wrong direction.

## Remaining Risks

- `--skip-dense` records timing only; it cannot validate value or gradient
  accuracy.
- The true crossover above `p=2048` still needs sequential dense evidence where
  feasible, or a separate accuracy proxy when dense is too expensive.
- This is benchmark infrastructure, not a new structured determinant algorithm.

## Known Limitations

No public structured non-Gaussian formula/API, no R `gllvmTMB` parity benchmark,
and no non-Gaussian CI/bootstrap implementation changed in this slice.

## Next Command

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=xlarge --skip-dense --trace-solve=lanczos --probe-kind=orthogonal --nprobes=32 --lanczos-steps=20 --reps=3 --warmups=2
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - the benchmark now supports safer break-even and
SLQ-only exploration; remaining notes concern true crossover evidence above
`p=640` and eventual public structured non-Gaussian parity work.
