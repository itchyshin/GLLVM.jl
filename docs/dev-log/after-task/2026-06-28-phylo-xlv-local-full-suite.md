# After Task: phylo X_lv Model A local full-suite verification

**Date**: `2026-06-28`
**Executed by**: Codex, live toolchain lane.
**Branch**: `codex/phylo-xlv-drac-launcher-20260628` in `/private/tmp/gllvmjl-phylo-xlv`.

## Purpose

Strengthen the local evidence for draft PR #127 after the stale remote CI
failure was diagnosed. The previous check-log entry had targeted evidence for
`test_lv_predictor.jl`, `test_phylo_xlv.jl`, and `test_lv_ci.jl`; this slice ran
the full package test suite including the quality-tool test environment.

## Changes

- Appended a check-log entry recording the full local `Pkg.test()` result.
- Appended a second check-log entry recording the local Documenter build result.
- No engine, API, benchmark, or test files were changed.
- No push was made; the GLLVM.jl project rule still requires explicit maintainer
  instruction before pushing this local branch.

## Validation

```sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: PASS. Full `Pkg.test()` completed in `50m14.4s` with `4875` passing
tests, `1` broken test, and `4876` total test outcomes.

Additional liveness checks during the long quiet section showed the Julia test
runner was CPU-bound, and a macOS `sample` showed execution in Julia/JIT/test
code rather than an idle hang.

```sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=docs docs/make.jl
```

Result: PASS after instantiating the docs environment against the local checkout.
Documenter completed and Vitepress reported `build complete in 4.89s`; deployment
was skipped locally. Warnings were limited to pre-existing local-link, optional
asset/package, chunk-size, and npm-audit warnings.

## Not Run

GitHub CI rerun, public Documenter deployment on the local head, DRAC `sbatch`,
and the >=500 reps/cell production coverage campaign were not run.

## Claim Boundary

IN: local branch `33557ff` now has targeted tests, full local `Pkg.test()` green,
and a local Documenter build that completes. PARTIAL: remote PR #127 CI is still
red on old head `b87a522` until the local commits are pushed or the PR branch is
updated. OUT: 3-OS CI green on the local commits, deployed docs on the local
commits, DRAC coverage, calibrated Model A interval coverage, and any R-side
`phylo_latent(..., lv=~x)` exposure.
