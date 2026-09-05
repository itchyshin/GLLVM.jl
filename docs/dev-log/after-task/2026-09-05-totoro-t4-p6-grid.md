# After-task: T4 P6 12-cell Totoro grid (2026-09-05)

**Status:** IN PROGRESS — integrator lane open; siblings own launcher/poll/gates.  
**Branch:** `cursor/totoro-t4-p6-grid-20260905`  
**Worktree:** `/Users/z3437171/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904`  
**Authority:** Shinichi G0 2026-09-05 (12-cell P6 grid); plan `docs/dev-log/plans/2026-09-05-totoro-t4-prerun-programme.md`  
**Claim boundary:** receipts inform realistic-size scaling and second-order tolerances — **NOT** true-parity or gate-tier promotion.

## Scope

12 cells: family ∈ {gaussian, poisson, nb2} × p ∈ {20, 50} × n ∈ {500, 2000}, K=2, fixed seeds.  
Totoro parallel (8-way). Output under `docs/dev-log/core070/t4-grid-out/`.

## Integrator checklist

- [ ] #296 merged to main (prerun programme + G1–G3 receipts)
- [ ] Branch `cursor/totoro-t4-p6-grid-20260905` pushed
- [ ] Draft PR open (stitch sibling commits)
- [ ] Sibling: `tools/t4_totoro_p6_grid.sh` launcher
- [ ] Sibling: Totoro launch + poll loop
- [ ] Sibling: `.unlazy/totoro-t4-p6-grid/GATES.md` (12 leaves)
- [ ] Sibling: plan appendix (measured seff vs estimate)
- [ ] 12/12 cell receipts committed
- [ ] check-log entry
- [ ] Rose read-only on receipt prose (no true-parity wording)

## Cell tally

| # | Family | p | n | Status | Receipt |
|---|--------|---|---|--------|---------|
| 1 | gaussian | 20 | 500 | pending | — |
| 2 | gaussian | 20 | 2000 | pending | — |
| 3 | gaussian | 50 | 500 | pending | — |
| 4 | gaussian | 50 | 2000 | pending | — |
| 5 | poisson | 20 | 500 | pending | — |
| 6 | poisson | 20 | 2000 | pending | — |
| 7 | poisson | 50 | 500 | pending | — |
| 8 | poisson | 50 | 2000 | pending | — |
| 9 | nb2 | 20 | 500 | pending | — |
| 10 | nb2 | 20 | 2000 | pending | — |
| 11 | nb2 | 50 | 500 | pending | — |
| 12 | nb2 | 50 | 2000 | pending | — |

## Resume (Shinichi, ~2 days)

```bash
cd /Users/z3437171/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904
git checkout cursor/totoro-t4-p6-grid-20260905 && git pull
ls docs/dev-log/core070/t4-grid-out/*/receipt.json 2>/dev/null | wc -l
grep -c PASS .unlazy/totoro-t4-p6-grid/GATES.md 2>/dev/null || echo "gates not yet"
tail logs/t4-p6-grid-launch-*.log
```

## Stop conditions hit

(none yet)

## Follow-up

- Re-estimate full grid seff after first 4 cells if wall times diverge from pre-run estimate.
- NB2 vcov NaN disposition before promoting any NB2 row.
