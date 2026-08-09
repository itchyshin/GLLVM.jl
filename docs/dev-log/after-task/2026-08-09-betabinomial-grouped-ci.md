# After-task: BetaBinomial grouped(_cov) CI (capacity S2)

**Date:** 2026-08-09  
**Lane:** `feat/betabinomial-grouped-ci-20260808`  
**Worktree:** `.worktrees/gllvmjl-betabinomial-grouped-ci-20260808`  
**Base:** `origin/main` @ `6aa8e0cb` (Merge #196, Species-XB Binomial)  
**LOOP:** `lanes/post-bb-x-capacity-20260807/LOOP/`  
**Plan:** `docs/dev-log/plans/2026-08-07-post-bb-x-capacity-programme.md`

## Goal

Wire `_family_ci` for `BetaBinomialGroupedFit` and `BetaBinomialGroupedCovFit`,
thread trials `N`, keep the finite-difference Hessian (BB Laplace has no OH),
and lift `_bridge_ci_guard_betabinomial` so bridge `ci_method` ≠ `"none"`
routes Wald/profile/bootstrap for supported methods.

## Implemented

1. **`_family_ci`** for grouped + grouped_cov BB, packing mirrors
   `NB1GroupedCovFit` / `BetaGroupedCovFit`: `[β; (γ_free); pack(Λ); log φ_g]`.
   Trials `N` are data (not stored on the fit). Mask is threaded.
2. Unions `_GroupedDispersionFit` / `_GroupedDispersionCovFit` admit the BB
   types. `_bridge_compute_ci_cov` now includes
   `BetaBinomialGroupedCovFit` (and `NB1GroupedCovFit`, already assembled).
3. **Bridge:** deleted `_bridge_ci_guard_betabinomial`; no-X path calls
   `_bridge_compute_ci_ng`; X path uses existing `_bridge_assemble_grouped_cov`
   CI route. `_BRIDGE_NO_CI_FAMILIES` is ordinal-only; BB joins
   `_BRIDGE_MASK_CI_FAMILIES`. Capabilities note: CI routed (FD Hessian);
   residuals/simulate still unwired.
4. **Tests:** native Wald smoke + missing-`X` throw; bridge no-X / X / mask
   Wald; capabilities golden updated.

## Mathematical Contract

Beta-binomial Laplace marginal with grouped Beta precision `φ[group[t]]`
(`betabinomial_grouped_marginal_loglik_laplace`); Wald SEs from the
central-difference Hessian of that packed objective. Dispersion CIs are
exp-back-transformed (`:log` kind), same as Beta/NB1 grouped.

## Files Changed

- `src/confint_family.jl` — unions + two `_family_ci` adapters
- `src/bridge.jl` — guard lift, no-X CI, capabilities, cov Union, note
- `test/test_confint_family.jl` — grouped + grouped_cov Wald
- `test/test_bridge_capabilities.jl` — CI flags + honest note
- `test/test_bridge_x.jl` — X Wald parity; drop fail-loud fence
- `test/test_bridge_grouped_dispersion.jl` — no-X Wald smoke
- `test/test_bridge_missing_mask.jl` — mask Wald cell
- `docs/dev-log/after-task/2026-08-09-betabinomial-grouped-ci.md`
- `docs/dev-log/check-log.md`, `docs/dev-log/coordination-board.md`,
  `AGENTS.md` snapshot, LOOP checkpoint/arcs

## Tests Added

- grouped Wald: estimate = MLE; intervals bracket when finite; unknown method
  throws (failure path).
- grouped_cov Wald: requires `X`; `gamma[1]` + `phi[g]` match MLE.
- bridge X Wald vs native `confint` max abs diff `< 1e-8`.
- bridge no-X / mask Wald smoke.

## Benchmark Numbers

`N/A — no hot-path change` — CI layer is post-fit FD Hessian, not the Laplace
inner loop.

## R-Parity Verdict

`Parity: N/A — change does not touch the parity surface` (no light RCall cell;
S1 already landed #196). Bridge CI vs native Julia `confint` ≤ 1e-8.

## JET / Allocs / Aqua Verdicts

- JET: not run locally (CI `Pkg.test()` owns Aqua/JET)
- Allocs: N/A — no inner-loop change
- Aqua: deferred to CI

## Checks Run

```
test/test_bridge_capabilities.jl          130 pass / 130 total   0.4s
test/test_bridge_grouped_dispersion.jl    131 pass / 131 total  17.0s
test/test_bridge_missing_mask.jl           89 pass /  89 total  26.2s
test/test_confint_family.jl               163 pass / 163 total  7m04s
test/test_bridge_x.jl                     248 pass / 248 total  34.6s
```

Tolerance widen: **none**. Full `Pkg.test()` deferred to GitHub CI (laptop;
do not run two Julia processes).

## Consistency Audit

`rg` `_bridge_ci_guard_betabinomial` — gone from `src/`; historical plans /
after-tasks retain the old fail-loud cite.  
`rg` `NOT routed yet` in `src/bridge.jl` + `test/test_bridge_capabilities.jl`
— no remaining BB hit. Ordinal CI still fenced.

## GitHub Issue Maintenance

No issue action — S2 is the locked capacity programme rung, not a new issue.

## What Did Not Go Smoothly

S2 worktree needed `Pkg.instantiate()` (fresh checkout). Sandbox blocked
`~/.julia/compiled` pidfile — tests ran unsandboxed. Subagent could not
`move_agent_to_root`; edits used the existing S2 worktree by absolute path.

## Team Learning

Lift the bridge CI guard only after native `confint` smoke is green — the
#192 fail-loud guard did its job.

## Remaining Risks

- Profile/bootstrap are routed by the generic `_family_ci` layer but only
  Wald was smoke-tested for BB grouped(_cov) (same pattern as other grouped
  families: profile/bootstrap smoke stays on Gamma in
  `test_bridge_grouped_dispersion.jl`).
- FD Hessian can be non-PD; tests already allow non-finite bounds (no
  `pd_hessian` demand).
- Residuals/simulate for BB remain unwired (`_BRIDGE_NO_SCALAR_POSTFIT_FAMILIES`).

## Known Limitations

≠ full family parity ≠ ADEMP/coverage ≠ analytic OH for BB Laplace ≠
ZIP engine ≠ ZIP light RCall ≠ Tweedie+X ≠ Phylo #127.

## Next Command

Merge PR2 on CI green, then S3 ZIP+X Identity **docs-only** from
`origin/main`. Do **not** start a ZIP engine.

## Rose Verdict

Rose verdict: **PASS WITH NOTES** — BB grouped(_cov) Wald/profile/bootstrap
CI routed (FD Hessian); residuals/simulate still unwired; not full family
parity; not ADEMP.
