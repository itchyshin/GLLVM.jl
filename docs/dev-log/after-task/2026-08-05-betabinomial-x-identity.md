# After-task: BetaBinomial+X dispersion identity (Arc 0 docs)

**Date:** 2026-08-05  
**Lane:** `docs/betabinomial-x-identity-20260805`  
**Programme:** `lanes/post-nb1-closeout-20260805/LOOP/` (packaging A, S3)  
**Decision:** `docs/dev-log/decisions/2026-08-05-betabinomial-x-dispersion-identity.md`  
**Twin recon:** `docs/dev-log/plans/scratch/betabinomial-x-twin-recon.md`

## Goal

Lock the next-family +X identity before any engine: public twin default under
shared site-X = **per-trait** BetaBinomial `φ` + shared `γ`, twin to gllvmTMB
`betabinomial` / `log_phi_betabinom` (fid 8). Docs-only.

## What shipped

1. ACCEPTED decision (API B under X; shared-φ opt-in; no engine).
2. Twin cites at file:line (`gllvmTMB` @ `ab49638b`).
3. Explicit “why not Tweedie / Exponential” + JuliaStats gap note.
4. Rose fence: Identity ≠ engine ≠ light green ≠ full family parity ≠ ADEMP.

## Verification

| Check | Result |
|---|---|
| Twin fid / `log_phi_betabinom` cites | present in decision + scratch |
| `src/` engine / bridge admit | **none** |
| Tweedie chosen as next Identity | **rejected** (fail-loud user path) |
| MixedModels/GLM BetaBinomial GLMM | **absent** — twin remains authority |

## Rose verdict

**OK to claim:** “BetaBinomial+X Identity Arc 0 ACCEPTED — per-trait φ under
shared site-X is the twin default when an engine exists.”

**Not OK:** any engine, bridge admit, RCall green, or full-family-parity claim
from this note alone.

## Next

Fresh arc-creation / ultra-plan for BetaBinomial grouped(+cov) engine — **not**
in this programme. Programme S4: board START HERE + closeout after Species-XB
lands.
