# Plan vs actual — M2 remainder S1/S2 (2026-09-06)

**Plan:** `docs/dev-log/plans/2026-09-06-true-parity-m2-autonomous-multiday-arc.md` (#303)  
**Branch:** `cursor/m2-s1s2-remainder-20260906` from `origin/main` @ `b37af6f0`  
**Worktree:** `~/local-scratch/lanes/GLLVM.jl-m2-s1s2-remainder-20260906`  
**Destination:** B signed; this file is leave-able **A only**.

## Cross-family receipt matrix

| Slice | Cell | eoo/schema flag | SE rel | vcov Fro rel | CI Δ | Warnings / disposition |
|---|---|---|---|---|---|---|
| M2-S1 | poisson (schema) | schema PASS | 5.81e-6 | 1.09e-5 | 5.27e-6 | §5 keys present; se=TRUE `sd_report` yes |
| M2-S2 | binomial_logit | PASS | 5.33e-6 | 6.44e-6 | 7.17e-6 | A7 **partial** (toy EOO only) |
| M2-S2 | beta_logit | PASS | 2.22e-6 | 5.99e-6 | 3.29e-6 | A9 **partial** (EOO; matched θ blocked) |
| M2-S2 | nb2_log | PASS-WITH-WARNINGS | 2.12e-6 | 0.380 (cond-scaled) | 1.06e-6 | A11 **partial**; Julia not converged; both `pdHess` false; r[1], r[3] boundary; R `sqrt(diag(cv))` NaN warning |

Gaussian and Poisson EOO smokes from #294/#295 were **not re-run** as claim evidence; S1 reused the Poisson cell only to prove schema + se=TRUE dispatch.

## Explicitly still blocked / not this arc

- M2-R2 matched coordinates (A9/A11 close) — needs a **new G0**
- Totoro / DRAC / T4 relaunch
- Merge of #297 / #298 / #301 / #303 / #304
- no true-parity, coverage, or recovery claim
- `check-log.md` (ownership collides with #297/#298/#301)
- `src/` and gllvmTMB engine files

## Live R caveat

This machine loaded **gllvmTMB 0.7.1** (`~/Library/R/arm64/4.6/library/gllvmTMB`),
not frozen 0.7.0 `b4d5fee6`. Diagnostic only.

## No T4 contamination

No `t4-p6-out` / `t4-p6-grid-out` was generated or staged on this branch.
