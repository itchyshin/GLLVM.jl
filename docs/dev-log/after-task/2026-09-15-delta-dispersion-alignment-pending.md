# After-task — Delta dispersion alignment PENDING decision (docs-only)

**Date:** 2026-09-15  
**Lane:** Cursor / Ada  
**Branch:** `docs/delta-dispersion-alignment-pending-20260915`  
**Worktree:** `~/local-scratch/gllvm-delta-disp-pending-20260915` (isolated from Dropbox shared checkout)  
**Base:** `origin/main` @ `3091fe613`  
**Scope:** Maintainer **PENDING** decision doc only — **no** `src/`, **no** tolerance change, **no** `Project.toml` bump.

## Rose fence

- **≠** D1 pass, covered promotion, Stage 1 / S4 / Totoro, programme §7, or true-parity destination.  
- **≠** ACCEPTED disposition until Shinichi pastes a reply phrase from the decision file.  
- **=** Records options **A / B / C** and Ada recommendation for Delta shared vs R per-trait dispersion after PR #347 measured **FAIL**.

## What landed

| File | Purpose |
|------|---------|
| [`docs/dev-log/decisions/2026-09-15-delta-dispersion-alignment-pending.md`](../decisions/2026-09-15-delta-dispersion-alignment-pending.md) | PENDING fork: align per-trait **(A)**, fence shared forever **(B)**, SO EOO-only / matched-θ OUT **(C)** |

## Evidence wired into the decision

- After-task: [`2026-09-15-second-order-delta-followup.md`](2026-09-15-second-order-delta-followup.md) (logLik Δ ≈ −1.92; SE rel Δ 0.145–0.212).  
- Julia: `disp_group` `:shared` | `:species` in `fit_delta_*_gllvm`; `_family_ci` **shared only** (read-only verify @ `3091fe613`).  
- Pattern: [`2026-09-14-matched-theta-beta-nb2-pending.md`](../decisions/2026-09-14-matched-theta-beta-nb2-pending.md), [`2026-08-02-nb2-beta-x-dispersion-identity.md`](../decisions/2026-08-02-nb2-beta-x-dispersion-identity.md).

## Checks run

```text
(docs-only — no Pkg.test(); CI Documenter + Julia shards on PR)
```

## Recommended maintainer default

**Letter:** **(A)** — `accept delta dispersion A`  
**Paste line:** `accept delta dispersion A`

## Next (after acceptance)

1. **(A):** bounded arc — `_family_ci` `:species`, default cells `disp_group=:species`, remeasure D1 without rtol widen.  
2. **(B) or C+B:** update second-order contract fences only; Delta D1 stays blocked on default cells.  
3. Ranked programme: T4 realistic-size SO (Totoro) remains separate; do not conflate with this fork.

## Lane isolation

**PLATFORM:** Cursor | **LANE:** `docs/delta-dispersion-alignment-pending-20260915` | **OTHER LANES:** did not touch forward-export #350, t11 #351, twin-bridge #353, feat/second-order-delta on Dropbox.
