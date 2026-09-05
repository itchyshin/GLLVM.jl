# After-task: T4 P6 12-cell Totoro grid (2026-09-05)

**Status:** IN PROGRESS — **11/12** cell receipts on disk (all **PASS**); cell 12 (`nb2_p50_n2000_K2`) still **RUNNING** on Totoro @ poll 15:00 MDT.  
**Branch:** `cursor/totoro-t4-p6-grid-20260905`  
**PR:** [#297](https://github.com/itchyshin/GLLVM.jl/pull/297) — **draft** (not ready until 12/12 verified)  
**Worktree:** `/Users/z3437171/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904`  
**Authority:** Shinichi G0 2026-09-05 (12-cell P6 grid); plan `docs/dev-log/plans/2026-09-05-totoro-t4-prerun-programme.md`  
**Claim boundary:** receipts inform realistic-size scaling and second-order tolerances — **NOT** true-parity or gate-tier promotion.

## Scope

12 cells: family ∈ {gaussian, poisson, nb2} × p ∈ {20, 50} × n ∈ {500, 2000}, K=2, seed=42.  
Totoro parallel (8-way). Receipts under `docs/dev-log/core070/t4-p6-*-receipt-2026-09-05.{json,md}`; artefacts under `docs/dev-log/core070/t4-p6-out/`.

## Integrator checklist

- [ ] #296 merged to main (prerun programme + G1–G3 receipts)
- [x] Branch `cursor/totoro-t4-p6-grid-20260905` pushed
- [x] Draft PR open (#297)
- [x] Sibling: `tools/t4_totoro_p6_grid.sh` launcher
- [x] Sibling: Totoro launch + poll loop (launch log `logs/t4-p6-grid-launch-20260905-1353.log`; finalize poll `logs/t4-p6-poll-nb2-final-20260905-1458.log`)
- [ ] Sibling: `.unlazy/totoro-t4-p6-grid/GATES.md` (12 leaves — update when 12/12)
- [ ] Sibling: plan appendix (measured seff vs estimate)
- [ ] **12/12** cell receipts committed (**11/12** on disk; see tally)
- [ ] check-log entry
- [ ] Rose read-only on receipt prose (no true-parity wording)
- [ ] `gh pr ready 297` — **blocked** until cell 12 receipt verified on disk

## Receipt tally (on-disk only)

**Count:** `ls docs/dev-log/core070/t4-p6-*-receipt-2026-09-05.json | wc -l` → **11**

| # | Family | p | n | Status | Receipt JSON |
|---|--------|---|---|--------|--------------|
| 1 | gaussian | 20 | 500 | **PASS** | `t4-p6-gaussian-p20-n500-K2-receipt-2026-09-05.json` |
| 2 | gaussian | 20 | 2000 | **PASS** | `t4-p6-gaussian-p20-n2000-K2-receipt-2026-09-05.json` |
| 3 | gaussian | 50 | 500 | **PASS** | `t4-p6-gaussian-p50-n500-K2-receipt-2026-09-05.json` |
| 4 | gaussian | 50 | 2000 | **PASS** | `t4-p6-gaussian-p50-n2000-K2-receipt-2026-09-05.json` |
| 5 | poisson | 20 | 500 | **PASS** | `t4-p6-poisson-p20-n500-K2-receipt-2026-09-05.json` |
| 6 | poisson | 20 | 2000 | **PASS** | `t4-p6-poisson-p20-n2000-K2-receipt-2026-09-05.json` |
| 7 | poisson | 50 | 500 | **PASS** | `t4-p6-poisson-p50-n500-K2-receipt-2026-09-05.json` |
| 8 | poisson | 50 | 2000 | **PASS** | `t4-p6-poisson-p50-n2000-K2-receipt-2026-09-05.json` |
| 9 | nb2 | 20 | 500 | **PASS** | `t4-p6-nb2-p20-n500-K2-receipt-2026-09-05.json` |
| 10 | nb2 | 20 | 2000 | **PASS** | `t4-p6-nb2-p20-n2000-K2-receipt-2026-09-05.json` |
| 11 | nb2 | 50 | 500 | **PASS** | `t4-p6-nb2-p50-n500-K2-receipt-2026-09-05.json` |
| 12 | nb2 | 50 | 2000 | **RUNNING** | — (stub only: `t4-p6-grid-out/nb2_p50_n2000_K2/receipt-stub.json`) |

## PASS table (12/12 skeleton — fill from receipts)

Wall times in seconds. Deltas from each-own-optimum smoke. **Do not promote** beyond claim boundary.

| # | Family | p | n | Result | Total wall | JL fit | JL confint | R fit | \|ΔlogLik\| | vcov Fro rel | max rel dSE |
|---|--------|---|---|--------|----------:|-------:|-----------:|------:|------------:|-------------:|------------:|
| 1 | gaussian | 20 | 500 | **PASS** | 19 | 10.1 | 6.5 | 2.1 | 2.24e-07 | 1.30e-05 | 2.01e-06 |
| 2 | gaussian | 20 | 2000 | **PASS** | 26 | 9.9 | 9.0 | 7.0 | 7.18e-07 | 1.16e-05 | 1.90e-06 |
| 3 | gaussian | 50 | 500 | **PASS** | 42 | 9.9 | 23.3 | 8.5 | 3.65e-07 | 1.20e-05 | 1.79e-06 |
| 4 | gaussian | 50 | 2000 | **PASS** | 136 | 10.6 | 84.3 | 41.1 | 4.69e-08 | 2.38e-06 | 1.03e-06 |
| 5 | poisson | 20 | 500 | **PASS** | 54 | 10.8 | 39.8 | 3.1 | 2.59e-07 | 1.59e-05 | 5.94e-06 |
| 6 | poisson | 20 | 2000 | **PASS** | 188 | 16.8 | 158.7 | 12.8 | 1.93e-07 | 3.77e-05 | 1.91e-05 |
| 7 | poisson | 50 | 500 | **PASS** | 487 | 19.3 | 453.4 | 14.4 | 1.21e-06 | 7.25e-05 | 2.94e-05 |
| 8 | poisson | 50 | 2000 | **PASS** | 1926 | 51.6 | 1812.5 | 62.4 | 3.01e-06 | 2.07e-04 | 8.42e-05 |
| 9 | nb2 | 20 | 500 | **PASS** | 217 | 97.9 | 102.7 | 16.6 | 2.08e-07 | 1.25e-05 | 7.89e-06 |
| 10 | nb2 | 20 | 2000 | **PASS** | 912 | 400.3 | 386.7 | 124.9 | 7.91e-08 | 3.05e-05 | 2.27e-05 |
| 11 | nb2 | 50 | 500 | **PASS** | 1334 | 387.3 | 846.4 | 100.6 | 9.20e-07 | 4.95e-05 | 2.27e-05 |
| 12 | nb2 | 50 | 2000 | _TBD_ | — | — | — | — | — | — | — |

**Partial seff (11 cells, serial sum):** ~5 341 s (~89 min). Dominant cells: poisson p50 n2000 (1 926 s), nb2 p50 n500 (1 334 s), nb2 p20 n2000 (912 s). Cell 12 expected heaviest — re-estimate full-grid parallel wall after it lands.

## Outcome (when 12/12)

| Item | Target | Current |
|---|---|---|
| Receipts on disk | 12 JSON + 12 MD | **11/12** |
| All PASS within EOO contract | 12/12 or FAIL disposition | **11/11 PASS** |
| PR ready for review | `gh pr ready 297` | **no** — blocked at 11/12 |
| True-parity / gate-tier claim | **NOT claimed** | honoured |

## Stop conditions hit

(none — cell 12 in flight)

## Next steps

1. **Poll cell 12** — `tools/t4_p6_poll_nb2_p50_n2000_finalize.sh` or manual poll until `t4-p6-nb2-p50-n2000-K2-receipt-2026-09-05.json` exists on disk.
2. **Commit receipt 12** — pull remote artefact, run receipt writer; do not invent JSON locally.
3. **Fill row 12** in PASS table from committed receipt only.
4. **Re-estimate grid seff** — append measured 12-cell serial/parallel totals to plan appendix (compare to pre-run G4 estimate ~23–30 min @ 8-core).
5. **Closeout** — update GATES G2/G3 leaves, check-log, then `gh pr ready 297` **only after** 12/12 verified.
6. **Explicitly NOT next:** true-parity promotion, gate-tier clearance, or merge without maintainer authority.

## Resume (Shinichi)

```bash
cd /Users/z3437171/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904
git checkout cursor/totoro-t4-p6-grid-20260905 && git pull
ls docs/dev-log/core070/t4-p6-*-receipt-2026-09-05.json | wc -l   # expect 12
tail -f logs/t4-p6-poll-nb2-final-20260905-1458.log
```

## Reviewers

- **Ada:** integrator closeout prep — tally accurate @ 11/12
- **Rose:** receipt prose — no true-parity overclaim (pending final read)
