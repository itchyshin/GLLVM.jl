# Benchmark suite

In-process performance suite for the `GLLVM.jl` Gaussian GLLVM
engine. Built on `BenchmarkTools.jl`, layout patterned after
[`MixedModels.jl/bench`](https://github.com/JuliaStats/MixedModels.jl/tree/main/bench).

## Run

```bash
julia --project=bench -e 'using Pkg; Pkg.develop(path = "."); Pkg.instantiate()'
julia --project=bench bench/run.jl
```

The first command only needs to run once (after `bench/Project.toml`
changes); it wires the bench environment to the in-tree package
checkout. After that, `bench/run.jl` is the only thing you need.

## Cells

The 6 cells mirror the external R-vs-Julia benchmark in
`gllvmTMB-julia-bench/report/grid-bench.md`:

| id              | n_sites | n_species | K | X       |
|-----------------|--------:|----------:|--:|:-------:|
| `c01_small_noX` |  20     |  5        | 1 | no      |
| `c02_small_X`   |  20     |  5        | 1 | yes     |
| `c03_med_noX`   |  80     | 10        | 2 | no      |
| `c04_med_X`     |  80     | 10        | 2 | yes     |
| `c05_large_noX` | 200     | 20        | 2 | no      |
| `c06_large_X`   | 200     | 20        | 2 | yes     |

Each cell runs `fit_gaussian_gllvm(y; K, X)` end-to-end. The
`+X` cells use a per-trait intercept design (`q = p`).

## Why in-process

The external `gllvmTMB-julia-bench/` harness is end-to-end (R fit +
subprocess invocation + serialisation) and takes minutes per cell.
This in-process suite runs the Julia engine alone, in milliseconds,
so PERF / PERF+ / PERF++ optimisations can be evaluated quickly.

## Non-Gaussian gllvmTMB Comparison

`bench/non_gaussian_gllvmtmb_bench.jl` is the row-level benchmark driver for the
fast non-Gaussian gradient track. It generates one simulated p×n response matrix
per family/cell, fits the same data in GLLVM.jl and R `gllvmTMB`, and records
wall time, convergence, iteration counts, objective/gradient calls when exposed,
log-likelihood, parameter count, median speedup, and an `agreement_status`
column.

Cheap smoke run:

```bash
julia --project=. bench/non_gaussian_gllvmtmb_bench.jl --smoke
```

Planned full grid:

```bash
julia --project=. bench/non_gaussian_gllvmtmb_bench.jl --full --out=non-gaussian-gllvmtmb.csv
```

The full grid uses small `(p = 10, n = 100, K = 1)`, medium
`(p = 30, n = 500, K = 2)`, and large `(p = 80, n = 2000, K = 3)` cells. It
uses 3 warmup fits, then 10 repetitions for small/medium and 3 repetitions for
large. Gaussian, binomial, and Poisson rows are marked
`same_data_loglik_comparable`. Negative-binomial, Beta, and Gamma rows are marked
`same_data_parameterization_audit_needed` until the R-side dispersion /
parameter-count conventions are pinned down. Ordinal rows are marked
`non_equivalent_link`: GLLVM.jl currently fits a cumulative-logit ordinal model,
while `gllvmTMB` exposes `ordinal_probit()`, so those rows are timing smoke
rather than likelihood parity.

## Structured Schur Logdet

`bench/structured_schur_logdet_bench.jl` is the Julia-only benchmark for the
planned large-`p` structured non-Gaussian determinant path. It constructs a
sparse tridiagonal precision plus per-site weights, then compares exact dense
`logdet(S_u)` against frozen-probe SLQ on the internal Schur operator.

Cheap smoke run:

```bash
julia --project=. bench/structured_schur_logdet_bench.jl --smoke
```

Full local grid:

```bash
julia --project=. bench/structured_schur_logdet_bench.jl --full --out=structured-schur-logdet.csv
```

Rows report construction time, dense logdet time, SLQ time, dense/SLQ speedup,
and SLQ relative error. The default grid uses 4 frozen Rademacher probes and 20
Lanczos steps, which is intentionally a speed-oriented operating point; use
`--nprobes=` and `--lanczos-steps=` to inspect the accuracy/speed trade-off.
This benchmark is not an R `gllvmTMB` parity test; it is the fast-algorithm
workbench for deciding when the structured determinant should switch from exact
dense to approximate SLQ.

## Structured Poisson Laplace Prototype

`bench/structured_poisson_laplace_bench.jl` is the Julia-only benchmark for the
first full structured non-Gaussian objective prototype. It compares exact dense
mode solve + dense `logdet(S_u)` against matrix-free CG mode solve with either
dense or SLQ `logdet(S_u)`.

Cheap smoke run:

```bash
julia --project=. bench/structured_poisson_laplace_bench.jl --smoke
```

Full local grid:

```bash
julia --project=. bench/structured_poisson_laplace_bench.jl --full --out=structured-poisson-laplace.csv
```

Rows report full objective-evaluation time, not just determinant time. The
`cg+dense` column isolates the Schur-step solve speedup; `cg+slq` adds the
approximate determinant path.

## Structured Poisson Fitted Prototype

`bench/structured_poisson_fit_bench.jl` is the Julia-only fitted-model benchmark
for the private fixed-covariance structured Poisson prototype. It estimates
`β` and lower-triangular `Λ` for a supplied sparse precision and fixed
`sigma2`, comparing the exact dense mode solve with the matrix-free CG mode
solve under the exact dense determinant. The private fitter keeps a fitted-mode
cache by default so neighbouring optimizer probes warm-start from the previous
Laplace mode.

Cheap smoke run:

```bash
julia --project=. bench/structured_poisson_fit_bench.jl --smoke
```

Full local grid:

```bash
julia --project=. bench/structured_poisson_fit_bench.jl --full --out=structured-poisson-fit.csv
```

The fitter defaults to the private dense-logdet block implicit gradient. Use
`--gradient=finite` to time the previous Optim finite-difference path on the
same cells. Use `--logdet=slq --nprobes=4 --lanczos-steps=20` to exercise the
frozen-probe stochastic trace-gradient path used for the large-p determinant
prototype.

Rows report fitted wall time, final log-likelihood agreement, objective-call
counts, and dense/CG fitted speedup. This is still not an R `gllvmTMB` parity
test; it is the bridge from objective-level timing to fitted structured-model
timing before public API wiring.

### Structured Poisson Trace-Gradient Scaling

`structured_poisson_trace_gradient_bench.jl` isolates one gradient evaluation
for the internal fixed-covariance structured Poisson prototype. It compares the
exact dense block gradient against the frozen-probe SLQ trace gradient and
reports both timing and gradient relative error.

```bash
julia --project=. bench/structured_poisson_trace_gradient_bench.jl --smoke
julia --project=. bench/structured_poisson_trace_gradient_bench.jl --full --out=structured-poisson-trace-gradient.csv
```

The default probe strategy is frozen Rademacher probing. Use
`--probe-kind=orthogonal` to compare against scaled orthogonal Gaussian probes
when studying stochastic-trace accuracy; this is a probe-study control, not the
default operating point. `--nprobes=` and `--lanczos-steps=` control the usual
speed/accuracy trade-off.

This benchmark is deliberately Julia-only: it answers where the large-p
structured determinant path starts to beat dense `S_u^{-1}` materialization,
not whether the public fit agrees with R `gllvmTMB`.

## JIT vs steady-state

`BenchmarkTools.@benchmarkable` does a single untimed warmup call
before the timed samples, so the reported median is steady-state. The
overall wall-clock of `bench/run.jl` includes a one-time JIT cost
(~tens of seconds the first time the package compiles); subsequent
invocations within the same Julia session are warm.
