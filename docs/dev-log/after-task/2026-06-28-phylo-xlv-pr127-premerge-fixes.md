# After Task: phylo X_lv Model A PR #127 pre-merge fixes

**Date**: `2026-06-28`
**Executed by**: Codex, live toolchain lane.
**Branch**: `claude/phylo-xlv-modelA-20260627` in `/private/tmp/gllvmjl-phylo-xlv`.

## Purpose

Draft PR #127 intentionally admits Gaussian Model A: predictor-informed latent
scores (`X_lv`) composed with a phylogenetic trait-covariance block. The PR CI
was failing because one older C1 test still expected that combination to throw.
The member audit also found two public-claim risks: bootstrap sign flipping for
`B_lv`, and 30-40 replicate smoke comments that described intervals as
"calibrated".

## Changes

- Updated `test/test_lv_predictor.jl` so W-tier and diagonal random-effect
  combinations still fail loudly, `X_lv + K_phy` without `Σ_phy` fails loudly,
  and `X_lv + K_phy + Σ_phy` has a small Model A admission smoke.
- Updated `src/fit.jl` docstring and errors: the `X_lv` path now says Model A
  phylogenetic blocks are admitted with `Σ_phy`, while W-tier and diagonal
  random-effect blocks remain unsupported. The docstring also states that
  fixed-effect `X + X_lv` is point-estimate only because `confint_lv_effects`
  rejects it.
- Removed the bootstrap sign flip in `src/confint_family.jl`. `B_lv =
  Lambda * alpha'` is already rotation/sign stable; flipping bootstrap
  replicates would hide bad refits rather than diagnosing them.
- Reworded `bench/phylo_xlv_coverage.jl` to call the existing 30-40 replicate
  results smoke evidence only. Full interval calibration still requires the
  DRAC campaign.

## Validation

```sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_phylo_xlv.jl
```

Before edits: PASS, `phylo × X_lv (Model A) 15/15`.

```sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_lv_predictor.jl
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_phylo_xlv.jl
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_lv_ci.jl
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/runtests.jl
```

After edits: PASS, `test_lv_predictor.jl 27/27`, `test_phylo_xlv.jl 15/15`,
`test_lv_ci.jl 114/114`, and core `test/runtests.jl 4863 pass, 3 broken, 4866
total` in `45m16.3s`.

## Not Run

Full `Pkg.test()` / Aqua / JET and GitHub CI rerun were not run because this
GLLVM.jl branch is still high-risk/draft and project rules say not to push
without an explicit maintainer instruction. DRAC was not launched from this
local Mac/Totoro-free session.

## Claim Boundary

IN: local pre-merge fixes for Model A test/doc/comment consistency and bootstrap
behavior. PARTIAL: PR #127 still needs full CI, DRAC >=500 reps/cell coverage,
Rose audit, and maintainer design/sign-off. OUT: public `gllvmTMB`
`phylo_latent(..., lv=~x)` support, non-Gaussian phylo X_lv, Model B,
fixed-effect `X + X_lv` intervals, and any calibrated-interval claim.
