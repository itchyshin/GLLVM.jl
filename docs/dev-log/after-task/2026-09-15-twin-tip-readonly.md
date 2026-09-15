# After-task — Hopper twin tip read-only bank (lease fallback)

**Date:** 2026-09-15  
**Lane:** Cursor / Hopper (read-only twin snapshot; no engine edits)  
**Written:** lease **REFUSED** — active holder `cursor:mac-true-parity-367` on `docs/dev-log/,LOOP/`  
**Intended repo path (when lease free):** `GLLVM.jl/docs/dev-log/after-task/2026-09-15-twin-tip-readonly.md`

## Twin heads (read-only)

| Side | Tip | Notes |
|------|-----|-------|
| gllvmTMB | **`fba20d613`** | R twin `origin/main` reference for parity tooling |
| GLLVM.jl | rehydrate from board / handover | Julia twin; not mutated in this slice |

Frozen oracle for R parity joins remains **`b4d5fee64def88bc768dda1f1f77c29b295edd86`** (unchanged by this note).

## Measured / landed (safe to cite)

- **`tools/parity_ledger.R` — CLOSURE: PASS** on gllvmTMB @ twin tip above, after arcG disposition.
- **gllvmTMB PR #1284 merged** — `ACCOUNTED` disposition for the Julia-only arcG row (paired with GLLVM.jl #358 decision).
- **arcG** is **Julia-only** — DRAC Wald coverage diagnostics live on the Julia side; R ledger records disposition, not an R implementation debt for that row.

## Rose fence — do **not** claim from this bank

| Topic | Status |
|-------|--------|
| **S4 public-formula probe** | **NOT run** — recorder gllvmTMB **#1283** / `97214679c`; needs second explicit maintainer yes |
| **Full true-parity / programme §7 closure** | **NOT complete** — paste-gated items remain on pending board |
| **arcG as R-owed coverage or calibrated Wald certificate** | **NOT claimed** — Julia-only diagnostic disposition only; ≠ interval coverage parity |

## Evidence pointers (read-only)

- GLLVM.jl: `docs/dev-log/after-task/2026-09-15-julia-only-arcg-disposition.md`
- GLLVM.jl: `docs/dev-log/decisions/2026-09-15-julia-only-arcg-disposition.md`
- gllvmTMB: `tools/parity_ledger.R` (post-#1284)
- Programme board: `docs/dev-log/2026-09-14-true-parity-pending-board.md`

## Checks run this slice

```text
lane_lease.sh --claim GLLVM.jl --paths docs/dev-log/after-task/2026-09-15-twin-tip-readonly.md
# REFUSED (cursor:mac-true-parity-367)
# → this file banked outside repo per D-88 / Ada lease
```

## Follow-up

- When `docs/dev-log/` lease is free: copy or merge this note to the intended after-task path; optional tiny docs-only PR from a worktree.
- No PR required for this fallback write.
