# After-task: T4 P6 12-cell Totoro grid (2026-09-05)

**Status:** IN PROGRESS — grid launched 2026-09-05 13:53 MDT; 7/12 cells DONE (poll @ 14:02).  
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
- [x] Sibling: Totoro launch + poll loop (launch log `logs/t4-p6-grid-launch-20260905-1353.log`)
- [ ] Sibling: `.unlazy/totoro-t4-p6-grid/GATES.md` (12 leaves)
- [ ] Sibling: plan appendix (measured seff vs estimate)
- [ ] 12/12 cell receipts committed (7/12 PASS committed; Gaussian arm complete; Poisson p=20 arm complete; NB2 p=20 n=500 only)
- [ ] check-log entry
- [ ] Rose read-only on receipt prose (no true-parity wording)

## Cell tally

| # | Family | p | n | Status | Receipt |
|---|--------|---|---|--------|---------|
| 1 | gaussian | 20 | 500 | **PASS** | `t4-p6-gaussian-p20-n500-K2-receipt-2026-09-05.json` |
| 2 | gaussian | 20 | 2000 | **PASS** | `t4-p6-gaussian-p20-n2000-K2-receipt-2026-09-05.json` |
| 3 | gaussian | 50 | 500 | **PASS** | `t4-p6-gaussian-p50-n500-K2-receipt-2026-09-05.json` |
| 4 | gaussian | 50 | 2000 | **PASS** | `t4-p6-gaussian-p50-n2000-K2-receipt-2026-09-05.json` |
| 5 | poisson | 20 | 500 | **PASS** | `t4-p6-poisson-p20-n500-K2-receipt-2026-09-05.json` |
| 6 | poisson | 20 | 2000 | **PASS** | `t4-p6-poisson-p20-n2000-K2-receipt-2026-09-05.json` |
| 7 | poisson | 50 | 500 | running | — |
| 8 | poisson | 50 | 2000 | running | — |
| 9 | nb2 | 20 | 500 | **PASS** | `t4-p6-nb2-p20-n500-K2-receipt-2026-09-05.json` |
| 10 | nb2 | 20 | 2000 | running | — |
| 11 | nb2 | 50 | 500 | running | — |
| 12 | nb2 | 50 | 2000 | running | — |

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
