# Destination B — G9 S4 phylo_dep formula recorder push (gllvmTMB)

**Date:** 2026-09-14  
**Lane:** Cursor Ada slice (G0 authorised push only)  
**Executor:** push + draft PR; **no S4 probe run in this slice**

## Authorisation

Maintainer **G0:** publish gllvmTMB branch `codex/destination-b-s4-phylo-dep-formula-20260910` only — recorder / formula cascade already on local tip; **no merge to main**; **no probe campaign** in this step.

## Preflight

| Check | Result |
|---|---|
| `lane_preflight.sh` gllvmTMB | **FOREIGN LANE ACTIVE** (codex/cursor) — push scoped to named branch; Shinichi G0 overrides bleed for this publication |
| Local branch | `codex/destination-b-s4-phylo-dep-formula-20260910` |
| Tip commit | `97214679c94cc4a6b9e02d3c2b03ccce516027d8` (`97214679c` — *Retain S4 Julia probe failures*) |
| `git cat-file -t 97214679c` | `commit` |
| Pre-push remote | `origin/codex/destination-b-s4-phylo-dep-formula-20260910` **absent** |

## Push receipt

| Field | Value |
|---|---|
| Remote | `https://github.com/itchyshin/gllvmTMB.git` |
| Branch URL | `https://github.com/itchyshin/gllvmTMB/tree/codex/destination-b-s4-phylo-dep-formula-20260910` |
| `git ls-remote` tip | `97214679c94cc4a6b9e02d3c2b03ccce516027d8` |
| Draft PR | **#1283** — title states recorder-only / no probe |
| Merged to main | **No** |
| S4 isolated Julia probe executed | **No** |

## Scope fence (Rose)

- This step makes the **existing recorder branch fetchable**; it is **not** S4 parity closure, **not** DestB `FINAL-REVIEW`, and **not** permission to run `run-destination-b-s4-public-phylo-dep-isolated.R` without a **second maintainer G0**.
- Julia side remains **held** per `docs/dev-log/2026-09-13-destination-b-g2-closeout.md` §3 until probe is explicitly authorised.

## Next (maintainer)

1. Optional: review draft PR #1283 scope vs Destination B S4 gate.  
2. When ready: separate G0 for S4 probe (second yes).  
3. Absorb this receipt on `cursor/honest-070-destb` (local file; commit when lane allows).
