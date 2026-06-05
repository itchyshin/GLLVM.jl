# After Task: Pure-J1 CI Fast Paths

## Goal

Close the pure-J1 Gaussian confidence-interval speed slice by validating the
PPCA bootstrap refit shortcut and the fixed-sigma profile-likelihood shortcut
in the current worktree.

## Implemented

The bootstrap refit path now detects the pure J1 Gaussian case and rebuilds the
fit directly from PPCA plus `profile_recover`, avoiding generic optimizer setup.
The same refit helper is shared by parameter bootstrap and derived bootstrap.

`profile_ci(fit, "sigma_eps"; y=...)` now detects the same pure J1 case and
evaluates the fixed-sigma profile log-likelihood from sample-covariance
eigenvalues. Other parameters and all structured shapes continue to use the
existing constrained-refit route.

The opt-in parity scaffold also received two plumbing fixes so the runner can
reach live R: valid Julia `@test` syntax and an R-side `r_result` binding.

## Mathematical Contract

For the pure Gaussian rank-`K` PPCA model with no fixed effects or structured
random effects, the covariance eigenvalues under a fixed residual variance
`sigma_eps^2` are `max(lambda_i, sigma_eps^2)` for the leading fitted axes and
`sigma_eps^2` otherwise. The profile log-likelihood is evaluated from those
eigenvalues without changing the likelihood parameterization. This follows the
PPCA closed-form argument of Tipping and Bishop (1999).

## Files Changed

- `src/confint_bootstrap.jl` - added the pure-J1 PPCA direct refit and dispatch.
- `src/confint_derived.jl` - routed derived bootstrap refits through the shared
  Gaussian refit helper.
- `src/confint_profile.jl` - added the fixed-sigma PPCA profile-likelihood
  shortcut for `sigma_eps`.
- `test/test_confint_bootstrap.jl` - added fast-refit equivalence coverage.
- `test/test_confint_profile.jl` - added fixed-sigma log-likelihood equivalence
  coverage.
- `test/parity/test_gaussian_parity.jl` - fixed scaffold syntax/RCall plumbing
  so opt-in parity reaches numerical assertions.
- `docs/dev-log/check-log.md` - recorded the verification and parity verdict.

## Tests Added

The new bootstrap test proves the direct PPCA refit converges with zero
iterations, matches the generic Julia fit log-likelihood to `1e-8`, and matches
the fitted covariance to relative error below `1e-10`.

The new profile test compares the eigenvalue fixed-sigma log-likelihood against
the old constrained-refit result at a non-MLE `sigma_eps`, then verifies
`profile_ci(fit, "sigma_eps"; y=y)` returns finite bracketing bounds.

These tests would have failed before the new helpers existed.

## Benchmarks

Ad hoc `time_ns` median harness on Julia 1.10.0, fixture `p=8, K=2, n=300`:

```text
bootstrap_refit_generic_seconds=0.000271146 bytes=1738544
bootstrap_refit_fast_seconds=2.44165e-5 bytes=98320 speedup=11.1050x
fixed_sigma_constrained_seconds=0.003627625 bytes=44074928
fixed_sigma_eig_seconds=8.25e-6 bytes=6464 speedup=439.7121x
profile_ci_sigma_fast_seconds=1.8417e-5 bytes=13568
```

`BenchmarkTools` was not added to the package environment.

## R-Parity Verdict

The opt-in parity scaffold now runs through RCall from a temporary Julia
project, but the current CRAN `gllvm` call is not a passing oracle:

```text
Gaussian GLLVM parity: GLLVM.jl vs gllvmTMB | 2 pass, 27 fail, 0 error
```

Environment: R 4.5.2, `gllvm` 2.0.5, `gllvmTMB` 0.2.0.

This is recorded as a parity scaffold gap, not a pure-J1 CI regression. The new
fast paths are validated against the existing generic Julia implementation and
do not add a public R-parity claim.

## JET / Allocs / Aqua Verdicts

- JET: clean through `Pkg.test()` quality gate.
- Allocs: no formal Allocs.jl gate; local allocation evidence recorded in the
  benchmark block.
- Aqua: clean through `Pkg.test()` quality gate (`quality | 12/12 pass`).

## Checks Run

```sh
/Users/z3437171/.juliaup/bin/julialauncher --project=. test/test_confint_profile.jl
/Users/z3437171/.juliaup/bin/julialauncher --project=. test/test_confint_bootstrap.jl
/Users/z3437171/.juliaup/bin/julialauncher --project=. test/test_confint_derived.jl
```

Results: `profile CI | 9/9 pass`, `parametric bootstrap CI | 18/18 pass`,
`derived-quantity CIs | 48/48 pass`.

```sh
/Users/z3437171/.juliaup/bin/julialauncher --project=. test/runtests.jl
```

Result: exit code 0; 0 fail, 0 error, with the existing sparse-phy broken
placeholder and direct-environment quality placeholders.

```sh
/Users/z3437171/.juliaup/bin/julialauncher --project=. -e 'using Pkg; Pkg.test()'
```

Result: `quality | 12/12 pass`; `Testing GLLVM tests passed`.

```sh
/Users/z3437171/.juliaup/bin/julialauncher --project=docs docs/make.jl
```

Result: exit code 0; only existing local Vitepress/npm warnings remained.

```sh
git diff --check
```

Result: clean.

Stale-wording scans used:

```sh
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src CLAUDE.md
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/PERF-plus-design.md CLAUDE.md
rg -n "\]\(/[^)]+\)|layout: home|hero:|features:|https://https://" docs/src docs/make.jl
```

Results: no stale Gaussian-only/TODO or rendered-frontmatter/link-shape hits;
performance/gllvmTMB hits were expected existing status/benchmark text.

## Remaining Risks

- The R parity scaffold is still not release-grade. It now reaches numerical
  assertions, but the current CRAN `gllvm` call fails the provisional parity
  checks and needs a dedicated R-call/objective audit.
- The fast paths are intentionally pure-J1 only; structured, fixed-effect, and
  non-Gaussian CI routes still use the existing generic machinery.
- The branch is still behind `origin/codex/non-gaussian-fitter-gradients` by two
  commits, and there are unrelated/untracked `.claude/` and `bench/results/`
  artifacts in the worktree.

## Rose Verdict

Rose verdict: PASS WITH NOTES - pure-J1 Julia CI fast paths are verified and
benchmarked; R parity scaffold remains a blocker before any release-grade
parity claim.
