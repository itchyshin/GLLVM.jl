# After Task: Bridge Missing-Response Mask

**Branch**: `codex/high-rate-poisson-safeguard`
**Date**: `2026-06-15`
**Roles (engaged)**: `Ada / Hopper / Gauss / Fisher / Rose`

## 1. Goal

Add the minimal `GLLVM.bridge_fit` hook required by the R-first
`gllvmTMB` missing-response bridge slice, while keeping unsupported masked cells
explicit and preserving complete-data behavior.

## 2. Implemented

- `bridge_fit(...; mask = M)` accepts a `p x n` observed-cell mask for no-X
  one-part non-Gaussian families.
- All-true masks normalize to the existing complete-data path.
- Gaussian masks, X+mask fits, mixed-family masks, and masked CI requests fail
  before fitting.
- `getLV()` and latent-scale link-residual summaries now accept the mask so
  bridge scores/correlations are not influenced by sentinel placeholders.

## 3. Files Changed

- `src/bridge.jl`
- `src/postfit.jl`
- `src/link_residual.jl`
- `test/test_bridge_missing_mask.jl`
- `test/runtests.jl`
- `docs/src/gllvmtmb-parity.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-15-bridge-missing-response-mask.md`

## 3a. Decisions and Rejected Alternatives

Decision: mask support is bridge-level and no-X first. Rationale: family
fitters already honor masks, but covariate and CI refit paths need additional
data contracts. Rejected alternative: compute bridge scores without masks after
mask-aware fitting. Confidence: high for the current hook.

## 4. Checks Run

- `~/.juliaup/bin/julia --project=. test/test_bridge_missing_mask.jl`:
  `17/17 pass` in `15.5s`.
- `~/.juliaup/bin/julia --project=. test/test_bridge_x.jl`:
  `52/52 pass` in `18.9s`.
- `~/.juliaup/bin/julia --project=. test/test_bridge_ci.jl`:
  `66/66 pass` in `46.1s`.
- `~/.juliaup/bin/julia --project=. -e 'using Test, GLLVM, Distributions; include("test/test_missing_data.jl")'`:
  `34/34 pass` in `12.5s`.
- `~/.juliaup/bin/julia --project=. test/test_postfit.jl`:
  all emitted postfit blocks passed.
- `~/.juliaup/bin/julia --project=. test/test_confint_family.jl`:
  `122/122 pass` in `4m15.5s`.
- Live paired R bridge file from `gllvmTMB`:
  `150/150 pass` against this checkout.

## 5. Tests of the Tests

`test/test_bridge_missing_mask.jl` checks native-vs-bridge Poisson parity,
sentinel invariance, all-true complete-data identity, and unsupported masked
combinations.

## 6. Consistency Audit

`docs/src/gllvmtmb-parity.md` now marks response masks as initial/no-X/
non-Gaussian bridge support and keeps Gaussian, X+mask, masked-CI, and
mixed-family mask routes as follow-ups.

## 7. Roadmap Tick

Phase 6 response-missing bridge hook: first Julia transport slice banked.

## 7a. GitHub Issue Ledger

No GitHub issue was mutated; pushing/commenting is maintainer-gated.

## 8. What Did Not Go Smoothly

Running `test/test_missing_data.jl` directly without loading `Distributions`
errors because the standalone file assumes the full `test/runtests.jl` include
context. The fair standalone rerun loaded `Distributions` explicitly and passed.

## 9. Team Learning

Gauss: post-fit summaries need the same mask as the likelihood. Hopper: the
bridge should stay flat (`Matrix{Bool}`) and avoid Julia structs crossing to R.
Fisher: masked confidence intervals need their own refit/status path. Rose:
Poisson R-live evidence is banked, broader family parity remains partial.

## 10. Known Limitations And Next Actions

Next slices: per-family R-live mask parity, masked CI-status/refit support,
Gaussian masks, and X+mask support if the model contract is agreed.
