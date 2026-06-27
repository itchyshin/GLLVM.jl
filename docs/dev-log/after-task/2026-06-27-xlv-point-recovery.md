# After Task: X_lv point-recovery validation (all eight routes)

**Date**: `2026-06-27`
**Executed by**: Claude (Codex on leave), juliaup Julia 1.10.
**Branch**: `claude/xlv-recovery-20260627`, off the family stack tip
`claude/beta-xlv-20260626` (HEAD `7d7b29d`) so all eight `X_lv` routes are present.

## 1. Goal

Close the **point-estimate half** of the recovery/coverage gate that the
`latent(..., lv = ~ x)` programme is nominally "gated by" but which no family
actually met. Establish, with a correctly-specified multi-seed study, that the
recovered trait-effect matrix `B_lv = Λ·α'` is unbiased for the data-generating
truth across every supported `X_lv` route.

## 2. Why it was needed (the gap)

- `test/test_lv_predictor.jl` checks only **mechanical identities** — score
  decomposition, shapes, and `B_lv = Λ·α'`, which is a tautology (`B_lv` is
  *defined* that way). It never compares `B̂_lv` to truth.
- `test/test_bridge_lv_predictor.jl` adds `cor(B̂_lv, B_true) > 0.9`, but that is
  **single-seed, correlation-only** and generated from a **misspecified** process
  (innovation `0.2·randn`, sd ≠ 1, while the estimator assumes `z_s ~ N(0,1)`).
  Correlation can survive that mismatch even when the magnitude is biased — which
  is exactly why the tests stop at correlation.

## 3. Implemented

- [`bench/lv_recovery.jl`](../../../bench/lv_recovery.jl) — a correctly-specified,
  multi-seed, n-sweepable recovery harness. Generates from the **unit-innovation**
  model the estimator assumes; fits through the user-facing `bridge_fit` with the
  **default warm start** (no truth inits — the real pipeline); reports per-trait
  bias, RMSE, sign-flip count, and the legacy `|cor|` proxy for each of the eight
  routes (gaussian, binomial logit/probit/cloglog, poisson, negbinomial, gamma,
  beta).
- [`docs/dev-log/recovery-checkpoints/2026-06-27-xlv-point-recovery.md`](../recovery-checkpoints/2026-06-27-xlv-point-recovery.md)
  — the evidence checkpoint (tables + reading + honest scope limits).

## 4. Result

At `n = 160`, `S = 40`: **every route recovers `B_lv` essentially unbiased** —
mean bias ≤ 0.004 in absolute value (≈1% of the average true effect), worst
single-trait bias 0.021 (NB2), full convergence (40/40), zero sign flips,
`|cor|` ≥ 0.993. The only structure is a faint negative bias on the largest
effect for the Laplace families; Gaussian (closed-form, no Laplace) is the
cleanest, identifying the residual as **finite-n Laplace bias**. The n-scaling
pass (`160 → 320 → 640`) is the direct test that it shrinks ~1/√n.

## 5. Checks Run

- `LV_REC_S=40 julia --project=. bench/lv_recovery.jl` → all 8 routes 40/40,
  tables in the checkpoint.
- n-scaling: `LV_REC_N="160,320,640" LV_REC_S=40 julia --project=. bench/lv_recovery.jl`
  → see checkpoint (consistency table).
- Read-only addition (bench + docs); no engine code touched, so the family test
  suites are unaffected.

## 6. Known Residuals / Next Gates

- **Intervals are not validated** — `confint(fit; X_lv)` still throws for every
  family. The next slice builds **Wald CIs** for the `X_lv` packed objective
  (delta-method onto `B_lv`), after which a **coverage** study (this same harness
  plus a containment check) closes the second half of the gate.
- `K = 1`, `q_lv = 1`, complete responses, single ordinary latent block, no `X`,
  no masks, no mixed-family, no structured sources — each its own gate.
- No capability/validation-debt row is promoted on this evidence; it is input to
  the maintainer's promotion + merge decision.

## 7. Team Learning

A "recovery test" that initialises at truth and/or generates from a misspecified
process and then checks only correlation is not a recovery test — it is a
smoke + rank-consistency test. The honest version generates from the model the
estimator assumes, starts from the default warm start, and checks **magnitude
(bias/RMSE) across seeds**. The gap here was invisible precisely because the
mechanical identity `B_lv = Λα'` always passes.
