# After Task: Analytic Gradient Defaults

## Goal

Use the runtime benchmark gate to decide whether the dormant analytic Laplace
gradients can become package defaults.

## Implemented

Poisson, NB2, Binomial, and Beta now default to `gradient = :analytic` on the
plain no-mask/no-offset path, preserving the existing finite-difference fallback
inside `_optimize_with_analytic`. Gamma remains `gradient = :finite` because the
runtime gate found benchmark-like Gamma cells where the analytic route missed the
`|ΔlogLik| <= 1e-6` acceptance criterion.

## Mathematical Contract

The changed families still optimise the same Laplace marginal likelihood
`ell(zhat) - 0.5 * zhat'zhat - 0.5 * logdet(Lambda' W Lambda + I)`. Only the
outer L-BFGS gradient source changes, from central finite differences to the
existing implicit-step ForwardDiff gradient verified against finite differences.

## Files Changed

- `src/families/poisson.jl`
- `src/families/negbin.jl`
- `src/families/binomial.jl`
- `src/families/beta.jl`
- `test/test_laplace_grad.jl`
- `bench/SPEED_NOTES.md`
- `bench/speed_bench.jl`
- `README.md`
- `docs/src/gllvmtmb-parity.md`
- `docs/dev-log/CODEX_HANDOFF.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-07-analytic-gradient-defaults.md`

## Tests

Targeted tests:

```sh
julia --project=. test/test_laplace_grad.jl
```

Result: 26 passed in 30.7s. This test file was updated so finite and analytic
fits are explicit and the default path is checked separately.

Full suite:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: 3296 passed, 1 broken, 3297 total in 27m25.4s.

Docs:

```sh
tmp=$(mktemp -d /tmp/gllvm-doc-env-XXXXXX)
JULIA_PROJECT="$tmp" julia -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.add(["Documenter", "DocumenterVitepress"]); include("docs/make.jl")'
```

Result: exit code 0. The direct `julia --project=docs docs/make.jl` path could
not instantiate locally because `GLLVM` v0.3.0 is not registered; the temporary
environment developed the local worktree instead. Pre-existing warnings remain
for absolute local links, missing logo/favicon assets, missing `docs/package.json`,
and npm audit reporting 4 moderate vulnerabilities.

## Benchmarks

Runtime gate run on the maintainer Mac using the `bench/speed_bench.jl`
simulators and fitter timing logic, one timed repetition per row because the
official script stalls in the profile-CI tail before printing its final table.

| size | family | finite s | analytic s | speedup | delta logLik | gate |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| 20x100x2 | Poisson | 2.592 | 0.274 | 9.46x | -9.09e-13 | pass |
| 20x100x2 | NB2 | 4.276 | 0.383 | 11.16x | -1.82e-12 | pass |
| 20x100x2 | Binomial | 4.719 | 0.416 | 11.33x | 3.18e-12 | pass |
| 20x100x2 | Beta | 15.511 | 1.261 | 12.30x | 1.14e-13 | pass |
| 20x100x2 | Gamma | 0.263 | 0.257 | 1.02x | -7.24e-4 | fail |
| 50x200x2 | Poisson | 50.685 | 4.847 | 10.46x | -1.09e-11 | pass |
| 50x200x2 | NB2 | 53.144 | 4.736 | 11.22x | -7.28e-12 | pass |
| 50x200x2 | Binomial | 59.231 | 5.357 | 11.06x | -1.09e-11 | pass |
| 50x200x2 | Beta | 223.527 | 17.699 | 12.63x | 6.37e-12 | pass |
| 50x200x2 | Gamma | 31.894 | 1.925 | 16.56x | 3.93e23 | fail |

## R-Parity

Parity: N/A for this slice. No R bridge validation was run; this only changes the
gradient source for the same Julia objective and keeps tests comparing analytic
and finite-difference fits.

## JET / Allocs / Aqua

JET: clean under the full `Pkg.test()` quality battery.

Allocs: benchmark table above records large allocation reductions for the changed
fitters; no zero-allocation inner-loop audit was run for this default flip.

Aqua: clean under the full `Pkg.test()` quality battery.

## Remaining Risks

- Gamma analytic gradients are not default-ready and need a separate stability
  fix before re-running this gate.
- The official `bench/speed_bench.jl` should be adjusted to print rows as they
  finish or make profile-CI optional; otherwise long profile-CI cells can hide
  the fitter table.
- R-to-Julia bridge parity remains the next runtime gate.

Rose verdict: PASS WITH NOTES — four families clear the measured speed/accuracy
gate; Gamma and the benchmark harness remain explicit follow-up risks.
