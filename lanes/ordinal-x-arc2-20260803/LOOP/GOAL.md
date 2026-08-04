# GOAL — ordinal-x-arc2-20260803 (IMMUTABLE — re-read every arc)

## Mission

Ordinal+X light RCall Arc 2: one shared site-X logLik cell vs live gllvmTMB
`ordinal_probit` at rtol `1e-6`, using Arc 1 `fit_ordinal_gllvm_pertrait_cov`
(per-trait cutpoints τ₁=0 / K−2 + shared γ). No engine redesign.

## Headline

Extend `fit_gllvmtmb_parity_loglik_x` for `:ordinal` / `ordinal_probit` and
land one `@testset` in the shared-X cohort.

## Invariants

- Write lane: `.worktrees/gllvmjl-ordinal-x-arc2-20260803` on
  `parity/ordinal-x-arc2-20260803` (from engine tip until #180 merges).
- rtol `1e-6` fixed; DGP/seed/link repair preferred over tolerance widen.
- Match twin **probit** (`ProbitLink()` / `ordinal_probit()`).
- FENCES: no engine redesign; no ADEMP; no Option B shared-cutpoint; no
  “full family parity”; no Dropbox protected writes; no `git add -A`; no
  push without ask.
- Verify = printed Δ logLik, not exit code alone.
- Compute = laptop RCall.

## Authoritative WHAT

`LOOP/ultra-plan.md` (= `docs/dev-log/plans/2026-08-03-ordinal-x-arc2-ultra-plan.md`).

## Definition of done

1. `:ordinal` accepted by `fit_gllvmtmb_parity_loglik_x` (`ordinal_probit()`).
2. Ordinal+X `@testset` Pass at rtol 1e-6 with pasted Δ (or honest OWED).
3. Narrow docs + check-log + after-task + Rose fence.
4. Commits by path; **no push** until Shinichi asks.
