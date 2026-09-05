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
| Poisson / NB2 | cells 2–3 | **READY** (G1 PASS; Ada default queue) |
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

## Follow-up (days 1–2)

1. Poll per programme doc §Days 1–2.
2. Commit Gaussian receipt; check G1 in GATES.md.
3. If PASS → queue Poisson (Ada default); else ping Shinichi.

## Reviewers

- **Ada:** programme shape
- **Rose:** receipt prose (no true-parity overclaim) — at receipt commit
