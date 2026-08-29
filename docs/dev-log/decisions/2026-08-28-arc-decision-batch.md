# Maintainer decision batch — the full-parity gates (2026-08-28)

All four open decision gates answered by the maintainer in one sitting
(interactive session, 2026-08-28), unblocking the ultracode run to full
capability parity with gllvmTMB 0.7.0.

| # | Gate | Decision |
|---|---|---|
| 1 | Tweedie curvature flip | **FLIP to `:observed`** |
| 2 | Binomial probit curvature flip | **FLIP to `:observed`** (cloglog stays Fisher — intrinsic saturation pathology, guard shipped #272) |
| 3 | PR #272 | Merge on green (merged 2026-08-28 17:56Z) |
| 4 | Delta-family identity (Arc 3) | **Twin identity MODE**: add the shared-single-predictor parameterisation as the parity-comparable mode; keep the current two-predictor form available |
| 5 | AGHQ | **UNPARK** — in scope for full parity |
| 6 | L47 none×dep | **PROMOTE** — ledger + docs work |
| 7 | Non-Gaussian REML | **STAYS REJECTED** |
| 8 | Delta latent-scale advertising | **STAYS REJECTED** |

## Maintainer's rider on the flips

> "can gllvmTMB do them — if they can we can do it — eh?? — get some good
> help; Ranga or DRM.jl seems to be able to do"

Interpretation and execution requirements bound to the flip slices:

- **The parity rationale is structural**: TMB's `MakeADFun(..., random=)`
  differentiates the joint negative log-likelihood, so gllvmTMB's Laplace
  log-det carries the OBSERVED conditional curvature for every family it
  ships — including Tweedie and Binomial-probit. "They can" is true by
  construction, not by a per-family switch.
- Each flip slice must (a) verify the hand-derived observed weight against a
  central finite difference of the actual conditional log-density (≤ 1e-6),
  (b) consult DRM.jl's `_laplace_d1/d2/d3` AD-gated derivative contract
  (`DRM.jl/src/sparse_laplace_glmm.jl`) as the pattern/oracle where the
  family overlaps, and (c) follow the executed coupled-change template
  (default + specialised weight + coupled analytic-gradient log-det where
  one exists + grouped-route alignment + census/contract/docs cascade in the
  same commit).

## Consequences queued

- Arc 1 closes fully once both flips land (census `KNOWN_OPEN` empties;
  `DEFERRED_BY_DECISION` keeps GP-1; Binomial cloglog remains the documented
  intrinsic exception).
- Arc 3 delta cells proceed under the twin-identity-mode design.
- Arc 5 planning may now include AGHQ unpark and the L47 promotion; the two
  `rejected` rows stay rejected and the parity claim will say so.
