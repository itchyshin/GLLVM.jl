# After-task: Post-NB1 hygiene (S1)

**Date:** 2026-08-05  
**Lane:** `cursor/post-nb1-hygiene-20260805`  
**Programme:** `docs/dev-log/plans/2026-08-05-post-nb1-closeout-programme-ultra-plan.md`  
**Base:** `main` @ `a100cc63` (#186 MERGED)

## Goal

Close NB1+X ledger fiction (OWED / awaiting merge) and make the light NB1+X
parity cell loadable under `test/parity` (`Distributions`).

## What shipped

1. Board / AGENTS / capability-status / gllvmtmb-parity: #186 MERGED + live Δ
   abs ≈ `1.531e-9` (seed=48).
2. After-task `2026-08-05-nb1-x-engine-arc12.md` verification row updated.
3. `test/parity/test_x_covariate_parity.jl`: `using Distributions`; nest
   Gamma/NB1/Ordinal inside outer `@testset`.
4. `test/parity/Project.toml`: `Distributions` dep + compat.
5. LOOP kit under `lanes/post-nb1-closeout-20260805/LOOP/`.

## Verification

| Check | Result |
|---|---|
| Grep board for “NB1 … OWED / awaiting merge” | cleared for #186 fiction |
| Live Δ evidence | retained from local focused oracle 2026-08-05 |
| Tolerance widen | **none** |

## Rose verdict

**OK** — ledger matches evidence.  
**Not OK:** Species-XB still unpushed until S2; BetaBinomial Identity until S3;
full family parity; ADEMP.

## Next

S2 — rebase `parity/species-xb-light-20260804` onto this tip; push/PR; merge on CI green (G0 yes).
