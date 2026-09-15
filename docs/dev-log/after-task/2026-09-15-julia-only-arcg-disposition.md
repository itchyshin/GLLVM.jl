# After-task — Julia-only arcG disposition (parity_ledger CLOSURE)

**Date:** 2026-09-15  
**Lane:** Cursor / Ada (`honest-070-true-parity` `/goal` rank 7)  
**GLLVM.jl branch:** `docs/julia-only-arcg-disposition-20260915` @ `origin/main`  
**gllvmTMB branch:** `docs/julia-only-arcg-disposition-20260915` @ `origin/main`  
**Scope:** Disposition only — **no** engine, **no** `Project.toml`, **no** covered promotion.

## Rose fence

- **≠** coverage certificate · **≠** true parity destination · **≠** Stage 1 / S4 / Totoro.
- **=** R `parity_ledger.R` CLOSURE can pass once the ACCOUNTED row lands on gllvmTMB.

## Measured before

```text
Rscript tools/parity_ledger.R   # CLOSURE: FAIL
# 1 Julia-only row(s) have no disposition: Julia-only arcG / DRAC Wald coverage diagnostics
```

## What landed

| Repo | Change |
|------|--------|
| GLLVM.jl | Decision ACCEPTED: `docs/dev-log/decisions/2026-09-15-julia-only-arcg-disposition.md` |
| gllvmTMB | `ACCOUNTED` entry in `tools/parity_ledger.R` (normalized key) |

## Verify (after gllvmTMB commit)

```text
cd gllvmTMB && Rscript tools/parity_ledger.R | tail -20
# expect: CLOSURE: PASS … (or FAIL only for unrelated near-misses)
```

## Follow-up

- Merge both PRs when green.
- Pending board: mark inventory rank 7 done.
