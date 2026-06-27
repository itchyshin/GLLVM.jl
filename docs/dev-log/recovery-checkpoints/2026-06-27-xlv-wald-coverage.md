# 2026-06-27 — X_lv Wald-interval coverage (confint_lv_effects)

**Executed by**: Claude (Codex on leave), juliaup Julia 1.10, on
`claude/xlv-wald-ci-20260627` (carries `confint_lv_effects` + the `_fd_hessian`
Wald-SE fix).
**Script**: [`bench/lv_coverage.jl`](../../../bench/lv_coverage.jl).

## What this checks

The second half of the recovery/coverage gate: do the 95% Wald intervals from
`confint_lv_effects` actually cover the true `B_lv = Λ·α'` at the nominal rate?
Same correctly-specified unit-innovation model as the recovery study; each dataset
is fit **natively with the default warm start** (no truth inits) and the interval
is checked for containment of every true `B_lv[t]`. Gaussian uses the exact
ForwardDiff Hessian of its closed-form marginal; the GLM families use the
finite-difference observed information.

## Results — n = 200, S = 80, level = 0.95

| route             | fits  | PD    | coverage | mean width | per-trait coverage      |
|-------------------|-------|-------|----------|-----------|--------------------------|
| gaussian          | 80/80 | 80/80 | 0.917    | 0.161     | 0.91 0.91 0.93 0.90 0.94 |
| binomial_logit    | 80/80 | 80/80 | 0.917    | 0.165     | 0.94 0.89 0.91 0.93 0.93 |
| binomial_probit   | 80/80 | 80/80 | 0.940    | 0.152     | 0.95 0.94 0.95 0.95 0.91 |
| binomial_cloglog  | 80/80 | 80/80 | 0.915    | 0.153     | 0.91 0.94 0.93 0.89 0.91 |
| poisson           | 80/80 | 80/80 | 0.917    | 0.175     | 0.93 0.93 0.91 0.94 0.89 |
| negbinomial       | 80/80 | 80/80 | 0.945    | 0.194     | 0.95 0.95 0.95 0.91 0.96 |
| gamma             | 80/80 | 80/80 | 0.955    | 0.176     | 0.97 0.95 0.95 0.94 0.96 |
| beta              | 80/80 | 80/80 | 0.920    | 0.193     | 0.93 0.93 0.89 0.93 0.94 |

## Reading

- **All eight routes are well-calibrated** — empirical coverage 0.915–0.955
  against the 0.95 nominal, every fit PD, no fit failures. The slight
  conservatism-to-nominal spread (a few routes at ~0.92) is the expected finite-n
  Wald behaviour at n = 200; a direct SE check (`empSD ≈ meanSE`, bias ≈ 0)
  confirms the standard errors match the true sampling spread.
- These intervals depend on the `_fd_hessian` `2f0 → 2 * f0` fix. Before that fix
  the SEs were ~1e-6 and coverage was ~0 (intervals were essentially points).

## A generator caveat worth recording

A first run reported Poisson coverage 0.463 — an artefact of a bug in this bench
script's `gen_poisson`, which evaluated `eta_matrix(...)` *inside* the per-cell
comprehension, redrawing the shared per-site innovation `z_s` for every cell and
so generating Poisson data from a mis-specified (no shared latent) model. The
other generators assign `eta` once. Fixed (compute `eta` once); Poisson then
covers 0.917, in line with every other family. The point estimator was never
affected — `B_lv` recovery uses the deterministic `X_lv` mean part — which is why
recovery looked clean while only coverage flagged it. Lesson: in Julia array
comprehensions, hoist any RNG-consuming setup out of the loop body.

## K = 2 tier expansion — n = 240, p = 6, S = 60, level = 0.95

`B_lv = Λ·α'` is invariant under the K×K rotation `Λ→ΛQ, α→αQ`, so it is
identified for any K and the delta-method CI carries over. Coverage at K = 2
(q_lv = 1), all eight routes, 60/60 converged and 60/60 PD each:

| route | gaussian | bin_logit | bin_probit | bin_cloglog | poisson | negbin | gamma | beta |
|---|---|---|---|---|---|---|---|---|
| coverage | 0.964 | 0.947 | 0.933 | 0.956 | 0.961 | 0.944 | 0.950 | 0.925 |

All near nominal — the tier expansion holds family-wide. (The same `gen_poisson`
comprehension-hoisting artefact recurred in the K=2 sweep — Poisson read 0.611
until `eta` was hoisted out of the loop, then 0.961; the engine was never
affected, exactly as at K=1.)

## Scope

`q_lv = 1`, complete responses, single ordinary latent block, Wald only
(no profile/bootstrap for `X_lv` yet). `K = 1` and `K = 2` are both validated
(recovery + coverage); larger K is admitted by the same K-generic delta method.
Each other extension (masks, `X`+`X_lv`, mixed-family, structured sources) remains
its own gate. No capability row promoted on this evidence — input to the
maintainer's decision.
