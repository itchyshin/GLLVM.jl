# GOAL — gamma-x-arc2-20260803 (IMMUTABLE — re-read every arc)

## Mission

Gamma+X light RCall Arc 2: one shared site-X logLik cell vs live gllvmTMB at
rtol `1e-6`, using Arc 1 `fit_gamma_gllvm_grouped_cov` with
`group=collect(1:p)` and default `hessian=:observed`. No engine redesign.

## Headline

Close the twin gap Arc 0/1 opened for Gamma under X — light oracle only.

## Invariants

- Write lane: `.worktrees/gllvmjl-gamma-x-arc2-20260803` on
  `parity/gamma-x-arc2-20260803` (stacked on engine tip `ca2b2c0b`).
- rtol `1e-6` fixed; DGP/seed repair preferred over tolerance widen.
- FENCES: no Arc 1 redo; no Option B; no Ordinal+X; no ADEMP; no #177 merge;
  no Dropbox writes; no `git add -A`; no push without ask; ≠ full family parity.
- Verify = printed Δ logLik, not exit code alone.
- Compute = laptop.

## Definition of done

1. `:gamma` accepted by `fit_gllvmtmb_parity_loglik_x` (`stats::Gamma(link="log")`).
2. Gamma+X `@testset` Pass at rtol 1e-6 with pasted Δ.
3. Narrow docs + surgical check-log + after-task + Rose fence.
4. Commits by path; **no push**.
