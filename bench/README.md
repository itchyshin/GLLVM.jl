# Benchmark suite

In-process performance suite for the `gllvmTMB.jl` Gaussian GLLVM
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

## JIT vs steady-state

`BenchmarkTools.@benchmarkable` does a single untimed warmup call
before the timed samples, so the reported median is steady-state. The
overall wall-clock of `bench/run.jl` includes a one-time JIT cost
(~tens of seconds the first time the package compiles); subsequent
invocations within the same Julia session are warm.
