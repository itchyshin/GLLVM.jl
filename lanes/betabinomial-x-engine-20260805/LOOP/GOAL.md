# GOAL — betabinomial-x-engine-20260805 (IMMUTABLE — re-read at the top of EVERY arc)

## Mission
Implement ACCEPTED BetaBinomial+X Identity as `fit_beta_binomial_gllvm_grouped`
+ `_grouped_cov` (per-trait φ + shared site-X γ, trials `N`), wire bridge /
`@formula`, land one light gllvmTMB BetaBinomial+X logLik cell @ rtol `1e-6`
(or honest OWED), then STOP.

## Headline
Next light-parity ladder rung after NB1 — Identity locked (#191); engine only.

## Invariants
- One lane; workspace =
  `.worktrees/gllvmjl-betabinomial-x-engine-20260805` on
  `cursor/betabinomial-x-engine-arc12-20260805` from `origin/main` @ `d5d61cb7`.
- G0 LOCKED: combined Arc 1+2; merge-on-green yes; FD-outer first (OH only if
  R Δ needs it).
- Laplace stays in `beta_binomial.jl` (custom FD + `N`); do not reuse
  `_beta_grouped_loglik_site`.
- Stage by name; never `git add -A`; Dropbox checkout PROTECTED.
- No silent rtol widen; ≠ full family parity; ≠ ADEMP; ≠ Tweedie/ZIP this run.

## Authoritative WHAT
`lanes/betabinomial-x-engine-20260805/LOOP/ultra-plan.md`  
(source: `docs/dev-log/plans/2026-08-05-betabinomial-x-engine-arc12-ultra-plan.md`)

## Definition of done
Grouped(+cov) exported; identity suite green; bridge/formula admit
`betabinomial`; light cell Δ≤1e-6 or OWED; after-task + check-log + board STOP.
