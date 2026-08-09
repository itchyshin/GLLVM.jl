# After-task: ZIP+X Identity Arc 0 (capacity S3, docs-only)

**Date:** 2026-08-09  
**Lane:** `docs/zip-x-identity-20260809`  
**Worktree:** `.worktrees/gllvmjl-post-bb-x-capacity-handover-20260809`  
**Base tip:** `8112e533` (`feat/betabinomial-grouped-ci-20260808` / PR #197 S2)  
**Decision:** `docs/dev-log/decisions/2026-08-09-zip-x-identity.md`  
**Plan:** `docs/dev-log/plans/2026-08-07-post-bb-x-capacity-programme.md`

## Goal

Land ACCEPTED ZIP+X Identity Arc 0 — **docs-only**. No ZIP engine, no ZIP
bridge X admit, no ZIP light RCall. Close the post-#192 capacity programme
board pointer past S1–S3 and **STOP**.

## What shipped

1. Decision note ACCEPTED with twin-asymmetry fence (gllvmTMB ZIP/ZINB cut;
   no `family_to_id` ZIP arm).
2. Locked estimand: shared site-X with **separate** `γ^z` / `γ^c`, retain
   `Λ_z = 0`; count part keeps `Λ_c`.
3. Board / AGENTS / check-log / LOOP closeout pointing past this programme.

## Verification

| Check | Result |
|---|---|
| Decision file on disk, Status = ACCEPTED | **yes** |
| Twin asymmetry paragraph | **yes** (known-limitations + `family_to_id`) |
| `src/` ZIP engine / bridge X / light cell in this diff | **none** |
| Rose fence explicit | **yes** |

## Rose verdict

**OK to claim:** ZIP+X Identity Arc 0 ACCEPTED (docs-only), Julia-forward /
twin-asymmetric.

**Not OK:** ZIP engine · bridge ZIP X · twin Δ · ADEMP · ZINB+X · full family
parity.

Rose verdict: **PASS** — programme STOP before any ZIP engine.

## Programme status

| Rung | State |
|---|---|
| S1 Species-XB Binomial | **MERGED** #196 @ `6aa8e0cb` |
| S2 BB grouped CI | **PR #197** (merge-on-green) |
| S3 ZIP+X Identity | **this landing** |
| ZIP engine | **STOP** — fresh `/arc-creation` only |
