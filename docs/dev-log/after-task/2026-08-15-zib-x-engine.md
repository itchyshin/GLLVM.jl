# After-task: ZIB+X engine Arc 0

**Date:** 2026-08-15  
**Branch:** `cursor/zib-x-catchup-20260815`  
**Worktree:** `.worktrees/gllvmjl-zib-x-20260815`  
**Base:** PR #208 tip `0041f769` — the ZIB+X Identity **with** required amendments
R1 (shared scalar `N`) and R2 (bridge fence, route (b)). The branch was originally
cut from `origin/main` @ `2914cc18`, which predates the ceiling review; it was
rebased so the Identity is inherited rather than re-authored.

## Delivered

- Rebase onto the R1+R2 Identity tip; the two locally cherry-picked copies of the
  ceiling review and the amendments were dropped, leaving **one** Identity doc
  (byte-identical to #208's) owned by PR #208
- `ZIBCovFit` + `fit_zib_gllvm_cov` appended in `src/families/twopart.jl`, carrying
  the shared **scalar** `N` contract only (`N::Integer` kwarg → `N::Int` field →
  scalar into `zib_marginal_loglik_laplace`); no `N_{ts}` matrix, no edit to
  `struct ZIB` or `_zi_Icc_binom`
- Focused tests `test/test_zib_x_identity.jl` — FD ≤1e-6
- `docs/dev-log/handover/2026-08-15-zib-x-ADMIT.md` (moved off the repo root) for
  shared choke points, splitting *ready* admits from **OWED** ones

## Explicit non-claims

- No twin light Δ / R-parity
- No shared-file admit in this PR; `src/bridge.jl` untouched (R2 fence held)
- No `fit_gllvm` / `@formula` admit — ZIB has no no-X entry point on either, so an
  X-only admit would leapfrog; both are OWED behind a frontend arc
- Rose public claim awaits Sol/Opus APPROVED

## Rose

**OK owned lane** for mechanical clone + FD evidence. Public capability-status claim blocked until Sol/Opus + conductor admit.
