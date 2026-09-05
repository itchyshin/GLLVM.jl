# T4 P6 grid — gate leaves (12 cells)

**Programme:** `docs/dev-log/plans/2026-09-05-totoro-t4-p6-grid-campaign.md`  
**Pre-run authority:** `docs/dev-log/plans/2026-09-05-totoro-t4-prerun-programme.md` (G1–G3 PASS)  
**Unlazy owner lane:** `cursor/totoro-t4-p6-grid-20260905`  
**Claim boundary:** realistic-size scaling + each-own-optimum receipts — **NOT** true-parity or gate-tier promotion.

Check leaves in order. A single cell FAIL does **not** abort the grid; record FAIL receipt and continue.

---

## G0 — Plan, launcher, compute-go

- [ ] D-139 re-estimate read (pre-run G4: serial ~3 h, 8-core ~23–30 min)
- [ ] Campaign plan committed (`2026-09-05-totoro-t4-p6-grid-campaign.md`)
- [ ] Launcher dry-run exits 0 without network (`tools/t4_totoro_p6_grid.sh`)
- [x] **Shinichi G0** for 12-cell grid launch recorded (2026-09-05)
- [ ] Branch `cursor/totoro-t4-p6-grid-20260905` pushed

---

## G1 — Grid launch (12 cells, 8-way parallel)

**Shape:** Gaussian / Poisson / NB2 × p∈{20,50} × n∈{500,2000} × K=2  
**Launcher:** `GLLVM_TOTORO_LAUNCH=1 tools/t4_totoro_p6_grid.sh`  
**Remote:** `/home/snakagaw/core070-aghq-20260830/t4-p6-grid-01/repo/`

- [x] rsync completed (2026-09-05 13:53 MDT)
- [x] Remote GNU parallel `-j 8` started (or serial fallback logged)
- [x] Launch log archived under `logs/t4-p6-grid-launch-20260905-1353.log`
- [ ] All 12 remote receipts present (`receipts/<tag>.json`) — 4/12 cell outputs DONE @ poll 13:56

**G1 PASS:** launch submitted + remote run finished (any mix of PASS/FAIL cells)  
**G1 FAIL:** infra/rsync/ssh failure before receipts written → ping Shinichi

---

## G2 — Pull and per-cell receipts

- [ ] `out/` and `receipts/` pulled from Totoro
- [ ] Per-cell dirs under `docs/dev-log/core070/t4-p6-grid-out/<tag>/`
- [ ] Collector run (`tools/core070_realistic_size_collect.py`) on merged tree
- [ ] Summary table committed (`t4-p6-grid-summary-2026-09-05.csv` or `.md`)

---

## G3 — Programme closeout

- [ ] All 12 cell leaves checked or marked FAIL with disposition
- [ ] `docs/dev-log/check-log.md` entry
- [ ] After-task report (`docs/dev-log/after-task/2026-09-05-totoro-t4-p6-grid.md`)
- [ ] **Explicitly NOT claimed:** true-parity promotion, gate-tier clearance

---

## Cell leaves (12)

| # | Tag | Leaf |
|---|-----|------|
| 1 | `gaussian_p20_n500_K2` | `cells/gaussian_p20_n500_K2.md` |
| 2 | `gaussian_p20_n2000_K2` | `cells/gaussian_p20_n2000_K2.md` |
| 3 | `gaussian_p50_n500_K2` | `cells/gaussian_p50_n500_K2.md` |
| 4 | `gaussian_p50_n2000_K2` | `cells/gaussian_p50_n2000_K2.md` |
| 5 | `poisson_p20_n500_K2` | `cells/poisson_p20_n500_K2.md` |
| 6 | `poisson_p20_n2000_K2` | `cells/poisson_p20_n2000_K2.md` |
| 7 | `poisson_p50_n500_K2` | `cells/poisson_p50_n500_K2.md` |
| 8 | `poisson_p50_n2000_K2` | `cells/poisson_p50_n2000_K2.md` |
| 9 | `nb2_p20_n500_K2` | `cells/nb2_p20_n500_K2.md` |
| 10 | `nb2_p20_n2000_K2` | `cells/nb2_p20_n2000_K2.md` |
| 11 | `nb2_p50_n500_K2` | `cells/nb2_p50_n500_K2.md` |
| 12 | `nb2_p50_n2000_K2` | `cells/nb2_p50_n2000_K2.md` |

Seeds: **42** for all cells (matches pre-run convention); see `tools/t4_p6_cells.tsv`.

---

## Infra leaves

- [ ] Totoro SSH ping OK before launch
- [ ] Remote base distinct from `t4-prerun-01` (no collision)
- [ ] Lane lease released when slice idle
