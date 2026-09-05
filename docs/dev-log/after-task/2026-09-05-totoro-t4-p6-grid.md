# After-task: T4 P6 12-cell Totoro grid (2026-09-05)

**Status:** **COMPLETE — 12/12 PASS** (each-own-optimum contract).  
**Branch:** `cursor/totoro-t4-p6-grid-20260905`  
**Tip (cell-12 receipt):** `cd1ab320`  
**PR:** [#297](https://github.com/itchyshin/GLLVM.jl/pull/297) — mark ready after this closeout (do **not** merge without maintainer authority)  
**Worktree:** `/Users/z3437171/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904`  
**Authority:** Shinichi G0 2026-09-05 (12-cell P6 grid); plan `docs/dev-log/plans/2026-09-05-totoro-t4-prerun-programme.md`  
**Claim boundary:** receipts inform realistic-size scaling and second-order tolerances — **NOT** true-parity or gate-tier promotion.

## Scope

12 cells: family ∈ {gaussian, poisson, nb2} × p ∈ {20, 50} × n ∈ {500, 2000}, K=2, seed=42.  
Totoro parallel (8-way). Receipts under `docs/dev-log/core070/t4-p6-*-receipt-2026-09-05.{json,md}`; artefacts under `docs/dev-log/core070/t4-p6-out/`.

## Integrator checklist

- [x] #296 merged to main (prerun programme + G1–G3 receipts)
- [x] Branch `cursor/totoro-t4-p6-grid-20260905` pushed
- [x] Draft PR open (#297) → ready after closeout commit
- [x] Sibling: `tools/t4_totoro_p6_grid.sh` launcher
- [x] Sibling: Totoro launch + poll loop (launch log `logs/t4-p6-grid-launch-20260905-1353.log`)
- [x] Sibling: `.unlazy/totoro-t4-p6-grid/GATES.md` — **G2/G3 PASS**
- [x] **12/12** cell receipts committed (incl. `nb2_p50_n2000_K2` @ `cd1ab320`)
- [x] check-log entry
- [x] Rose read-only on receipt prose (no true-parity wording)
- [x] `gh pr ready 297` — after closeout push (merge withheld)

## Receipt tally (on-disk)

**Count:** `ls docs/dev-log/core070/t4-p6-*-receipt-2026-09-05.json | wc -l` → **12**

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
| 12 | nb2 | 50 | 2000 | **PASS** | `t4-p6-nb2-p50-n2000-K2-receipt-2026-09-05.json` |

## PASS table (12/12 — from committed receipts)

Wall times in seconds (total = Julia fit + Julia confint + R fit). Deltas from each-own-optimum smoke. **Do not promote** beyond claim boundary.

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
| 12 | nb2 | 50 | 2000 | **PASS** | 6578 | 2064.8 | 3897.8 | 615.7 | 4.83e-07 | 1.20e-04 | 5.08e-05 |

### Cell 12 highlight (`nb2_p50_n2000_K2`)

- Julia fit ~2065 s; Julia confint ~3898 s; R fit ~616 s
- logLik Δ ≈ 4.8e-7; vcov Fro rel ≈ 1.2e-4; max rel dSE ≈ 5.1e-05
- Receipt: `docs/dev-log/core070/t4-p6-nb2-p50-n2000-K2-receipt-2026-09-05.{json,md}`

## Full seff (12 cells)

| Aggregate | Value |
|---|---|
| Serial sum (JL fit + JL confint + R fit) | **~11 920 s (~199 min / ~3.3 h)** |
| Heaviest cell | nb2 p50 n2000 — **6578 s** (~110 min) |
| Next heaviest | poisson p50 n2000 — 1926 s; nb2 p50 n500 — 1334 s |
| Pre-run G4 estimate (8-core wall) | ~23–30 min |
| Measured note | Serial sum ≫ 8-core estimate because NB2 large cells dominate; Julia confint is the main cost on non-Gaussian arms |

Parallel wall on Totoro was launch-to-last-receipt (8-way), not equal to the serial sum. Record for scaling: cell 12 alone is longer than the original 8-core pre-run guess for the whole grid.

## Outcome

| Item | Target | Result |
|---|---|---|
| Receipts on disk | 12 JSON + 12 MD | **12/12** |
| All PASS within EOO contract | 12/12 or FAIL disposition | **12/12 PASS** |
| GATES G2 / G3 | PASS | **PASS** |
| PR ready for review | `gh pr ready 297` | done at closeout (merge withheld) |
| True-parity / gate-tier claim | **NOT claimed** | honoured |

## Stop conditions hit

(none)

## Explicitly NOT claimed / NOT next

- True-parity promotion
- Gate-tier clearance
- Merge of #297 without maintainer authority

## Reviewers

- **Ada:** integrator closeout — 12/12 PASS + seff from on-disk receipts
- **Rose:** receipt / after-task prose — claim boundary held (RSZ + EOO only)

## Next step

1. **Maintainer:** review / merge [PR #297](https://github.com/itchyshin/GLLVM.jl/pull/297) when CI is green (merge is maintainer authority only — agents do not merge).
2. **Do not** launch cells beyond this 12-cell grid from this programme, and **do not** treat these receipts as a true-parity or gate-tier claim.
3. **Planning note:** G4’s 8-core wall guess (~23–30 min) was low — cell 12 alone was ~6578 s (~110 min); use measured seff for any future Totoro sizing.
4. **Programme:** return to the existing true-parity track (M2 / θ-map research) when ready — no new Totoro launch invented here. Rose receipt prose already done on this closeout.
