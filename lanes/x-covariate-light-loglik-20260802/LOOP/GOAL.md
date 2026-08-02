# GOAL — x-covariate-light-loglik-20260802 (IMMUTABLE — re-read at the top of EVERY arc)

## Mission

Land the first cohort of **X / covariate light gllvmTMB logLik parity cells**
on GLLVM.jl: Gaussian, Binomial (Bernoulli), and Poisson, each with **q = 1
shared site covariate**, green under `GLLVM_PARITY_TESTS=1` with retained
ΔlogLik evidence at rtol `1e-6`.

## Headline

Extend the no-X light oracle surface with three shared-X cells via a new RCall
helper + Julia `fit_gaussian_gllvm(; X=)` / `fit_gllvm_cov` pairing.

## Invariants

- One lane; write only in worktree
  `.worktrees/gllvmjl-x-covariate-light-loglik-20260802` on branch
  `parity/x-covariate-light-loglik-20260802`.
- Shared site slope identity: R formula uses `+ x` (not `(0 + trait):x`).
- Keep no-X `fit_gllvmtmb_parity_loglik` intact.
- No silent tolerance widening.
- No push without maintainer instruction; no auto-merge.
- Do not edit Dropbox stale fork `claude/jl-bridge-capabilities-20260619`.

## Fence (out of scope)

NB2/Beta+X (shared φ ≠ per-trait default); Gamma; Ordinal+X; X+mask;
species-specific XB; X_lv; ADEMP; #129/#128; Totoro/DRAC; “full family parity”;
`test_grouped_dispersion.jl:61` bug lane.

## Authoritative WHAT

`LOOP/ultra-plan.md` and
`docs/dev-log/plans/2026-08-02-gllvm-x-covariate-light-loglik-ultra-plan.md`.

## Definition of done

- Helper + 3 cells committed locally.
- Parity LOG shows ΔlogLik for each cell; ≥2/3 green at rtol 1e-6 (honest block
  for any red).
- After-task + check-log + board + plan-actual with Rose fence.
- LOOP checkpoint STATE reflects completion.
