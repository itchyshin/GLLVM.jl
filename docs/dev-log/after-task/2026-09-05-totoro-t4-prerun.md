# After-task — T4 Totoro pre-run programme (stub)

**Date:** 2026-09-05  
**Branch:** `cursor/totoro-t4-prerun-20260905`  
**Lane:** Cursor · worktree `GLLVM.jl-gllvm-twin-20260904`  
**Lease:** `docs/dev-log/plans/`, `docs/dev-log/core070/`, `tools/t4_totoro_gaussian_prerun.sh`, `.unlazy/totoro-t4-prerun/`

## Scope

| Item | Deliverable | Status |
|---|---|---|
| Plan | `docs/dev-log/plans/2026-09-05-totoro-t4-prerun-programme.md` | **DONE** |
| Gates | `.unlazy/totoro-t4-prerun/GATES.md` | **DONE** |
| Launcher on branch | `tools/t4_totoro_gaussian_prerun.sh` (from day-2) | **DONE** |
| Gaussian launch | `GLLVM_TOTORO_LAUNCH=1` | **DONE** — receipt PASS |
| Gaussian receipt | JSON + MD under `docs/dev-log/core070/` | **DONE** |
| Poisson launch | `GLLVM_TOTORO_LAUNCH=1` | **DONE** — receipt PASS |
| Poisson receipt | JSON + MD under `docs/dev-log/core070/` | **DONE** |
| NB2 | cell 3/3 | **READY** (G2 PASS; Ada default queue) |
| Draft PR | plan + launch evidence | **OPEN** |

## Claim boundary

Receipts inform RSZ scaling and second-order tolerance viability — **NOT** true-parity or gate-tier
promotion.

## Launch status

| Field | Value |
|---|---|
| Attempted | 2026-09-05 |
| Totoro SSH | OK (`totoro`, load ~0.1) |
| Command | `GLLVM_TOTORO_LAUNCH=1 tools/t4_totoro_gaussian_prerun.sh` |
| First attempt | **BLOCKED** — remote dir missing (`mkdir -p` fix) |
| Retry log | `logs/t4-gaussian-prerun-launch-20260905-retry2.log` |
| Remote status | **COMPLETE** (`EXIT:0`, DONE line) |
| Receipt | `docs/dev-log/core070/t4-prerun-gaussian-receipt-2026-09-05.{json,md}` |
| G1 | **PASS** — vcov_fro_rel 1.3e−5; seff ~47 s total |

## Poisson launch status

| Field | Value |
|---|---|
| Attempted | 2026-09-05 |
| Command | `GLLVM_TOTORO_LAUNCH=1 tools/t4_totoro_poisson_prerun.sh` |
| Launch log | `logs/t4-poisson-prerun-launch-20260905-1312.log` |
| Remote status | **COMPLETE** (`EXIT:0`, DONE line) |
| Receipt | `docs/dev-log/core070/t4-prerun-poisson-receipt-2026-09-05.{json,md}` |
| G2 | **PASS** — vcov_fro_rel 1.6e−5; max_rel_dSE 5.9e−6; seff ~107 s total |

## Follow-up

1. ~~Gaussian receipt + G1~~ **DONE**
2. ~~Poisson launch + receipt + G2~~ **DONE**
3. NB2 cell 3/3 when continuing (not launched this slice)
4. Full 12-cell grid blocked until G3 PASS + D-139 re-estimate

## Reviewers

- **Ada:** programme shape
- **Rose:** receipt prose (no true-parity overclaim) — at receipt commit
