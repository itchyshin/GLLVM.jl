# After-task — T4 Totoro pre-run programme

**Date:** 2026-09-05  
**Branch:** `cursor/totoro-t4-prerun-20260905`  
**Lane:** Cursor · worktree `GLLVM.jl-gllvm-twin-20260904`  
**Lease:** `docs/dev-log/plans/`, `docs/dev-log/core070/`, `tools/t4_totoro_*_prerun.sh`, `.unlazy/totoro-t4-prerun/`

## Scope

| Item | Deliverable | Status |
|---|---|---|
| Plan | `docs/dev-log/plans/2026-09-05-totoro-t4-prerun-programme.md` | **DONE** |
| Gates | `.unlazy/totoro-t4-prerun/GATES.md` | **DONE** (G0–G4 re-estimate) |
| Gaussian launch + receipt | cell 1/3 | **DONE** — G1 PASS |
| Poisson launch + receipt | cell 2/3 | **DONE** — G2 PASS |
| NB2 launcher | `tools/t4_totoro_nb2_prerun.sh` | **DONE** |
| NB2 launch + receipt | cell 3/3 | **DONE** — G3 PASS |
| 12-cell grid re-estimate | G4 in GATES | **DONE** (estimate only) |
| 12-cell grid launch | P6 full grid | **NOT STARTED** (needs G0) |
| Draft PR | #296 | **OPEN** — receipts on branch |

## Claim boundary

Receipts inform RSZ scaling and second-order tolerance viability — **NOT** true-parity or gate-tier
promotion.

## Gaussian (G1)

| Field | Value |
|---|---|
| Receipt | `t4-prerun-gaussian-receipt-2026-09-05.{json,md}` |
| seff | ~47 s total; compute ~19 s |
| Result | **PASS** |

## Poisson (G2)

| Field | Value |
|---|---|
| Receipt | `t4-prerun-poisson-receipt-2026-09-05.{json,md}` |
| seff | ~107 s total; compute ~60 s |
| Result | **PASS** |

## NB2 (G3)

| Field | Value |
|---|---|
| Attempted | 2026-09-05 (resume after interrupted first attempt) |
| Command | `GLLVM_TOTORO_LAUNCH=1 tools/t4_totoro_nb2_prerun.sh` |
| Launch log | `logs/t4-nb2-prerun-launch-20260905-1330.log` |
| Remote status | **COMPLETE** (`EXIT:0`, DONE line) |
| Receipt | `t4-prerun-nb2-receipt-2026-09-05.{json,md}` |
| seff | ~306 s total; compute ~210 s (fit 95.2 s + confint 99.0 s + R 15.9 s) |
| Boundary / NaN vcov | **not triggered** (all dispersion_boundary false) |
| Result | **PASS** — vcov_fro_rel 1.25e−5; max_rel_dSE 7.89e−6 |

## G4 — revised 12-cell estimate

Three measured seff values → serial mid **~3.0 h** (was ~72 min in D-139); 8-core parallel mid
**~23–30 min**. Grid **NOT** launched.

## Goal closure

**Programme slice can close:** three PASS receipts + plan/GATES/after-task updated. Full P6 grid
remains queued for Shinichi G0.

## Reviewers

- **Ada:** programme complete for pre-run slice
- **Rose:** receipt prose — no true-parity overclaim
