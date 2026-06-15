# After-task - Gamma analytic-gradient default

## Goal

Re-open the Gamma analytic-gradient default after the Laplace mode safeguard and
flip it only if the benchmark showed a speedup with `|delta logLik| <= 1e-6`.

## Files Changed

- `src/families/gamma.jl`
- `bench/speed_bench.jl`
- `bench/SPEED_NOTES.md`
- `docs/dev-log/CODEX_HANDOFF.md`
- `docs/dev-log/check-log.md`

## What Changed

`fit_gamma_gllvm` now defaults to `gradient = :analytic`, matching Poisson, NB2,
Binomial, and Beta. The existing guard remains: the analytic path is used only
for the no-mask/no-offset case, with the finite-difference optimiser path still
available explicitly and as the fallback for unsupported shapes.

The benchmark harness now has opt-in environment knobs for quick decision runs:
`GLLVM_SPEED_BENCH_GRID`, `GLLVM_SPEED_BENCH_REPS`, `GLLVM_SPEED_BENCH_ITERS`,
and `GLLVM_SPEED_BENCH_PROFILE_CI`. The default full grid and profile-CI timing
remain unchanged.

## Benchmark Evidence

The original full grid was interrupted after roughly 13 minutes while still in
the first grid cell, inside the Laplace mode hot loop. The quick decision grid
and one medium confirmation cell both cleared the Gamma default gate.

Quick grid:

```sh
GLLVM_SPEED_BENCH_GRID=quick GLLVM_SPEED_BENCH_REPS=1 GLLVM_SPEED_BENCH_ITERS=80 GLLVM_SPEED_BENCH_PROFILE_CI=0 /Users/z3437171/.juliaup/bin/julia --project=. bench/speed_bench.jl
```

Gamma: `10.09x` speedup at `8x40x1` with `delta logLik = 2.842e-14`; `9.68x`
speedup at `12x60x1` with `delta logLik = 2.842e-13`.

Medium cell:

```sh
GLLVM_SPEED_BENCH_GRID=20,100,2 GLLVM_SPEED_BENCH_REPS=1 GLLVM_SPEED_BENCH_ITERS=120 GLLVM_SPEED_BENCH_PROFILE_CI=0 /Users/z3437171/.juliaup/bin/julia --project=. bench/speed_bench.jl
```

Gamma: finite `10.8304s`, analytic `0.7590s`, speedup `14.27x`,
`delta logLik = -1.819e-12`.

## Checks Run

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_gamma_fit.jl
```

Result: `7/7 pass` in `10.7s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_gamma_laplace.jl
```

Result: `2/2 pass` in `2.2s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_laplace_grad.jl
```

Result: `26/26 pass` in `31.5s`; the Gamma finite-vs-analytic/default assertion
now explicitly sets `gradient = :finite` for the finite-difference reference and
checks the default against the analytic fit.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: `3761 pass, 1 broken, 0 failed, 0 errored` in `35m09.1s`.

## R-Parity Verdict

N/A - default optimiser-gradient route only. The fitted likelihood target is
unchanged and explicitly checked against the finite-difference optimiser by the
benchmark delta-logLik gate.

## JET / Allocs / Aqua Verdict

`Pkg.test()` passed, including the quality battery available in the test
sandbox. Pre-existing duplicate-helper warning noise remains in the test harness.

## Rose Verdict

PASS WITH NOTES. Gamma clears the analytic default benchmark gate and full
`Pkg.test()` after the flip. Remaining note: this is a Julia optimiser-gradient
default change only; R bridge parity was not rerun.

## Next Command

```sh
git diff --check
```
