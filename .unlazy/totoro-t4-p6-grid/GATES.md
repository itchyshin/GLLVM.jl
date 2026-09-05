# T4 P6 grid — gate leaves (12 cells)

**Programme:** `docs/dev-log/plans/2026-09-05-totoro-t4-p6-grid-campaign.md`  
**Pre-run authority:** `docs/dev-log/plans/2026-09-05-totoro-t4-prerun-programme.md` (G1–G3 PASS)  
**Unlazy owner lane:** `cursor/totoro-t4-p6-grid-20260905`  
**Claim boundary:** realistic-size scaling + each-own-optimum receipts — **NOT** true-parity or gate-tier promotion.

Check leaves in order. A single cell FAIL does **not** abort the grid; record FAIL receipt and continue.

---

## G0 — Plan, launcher, compute-go

- [x] D-139 re-estimate read (pre-run G4: serial ~3 h, 8-core ~23–30 min)
- [x] Campaign plan committed (`2026-09-05-totoro-t4-p6-grid-campaign.md`)
- [x] Launcher dry-run exits 0 without network (`tools/t4_totoro_p6_grid.sh`)
- [x] **Shinichi G0** for 12-cell grid launch recorded (2026-09-05)
- [x] Branch `cursor/totoro-t4-p6-grid-20260905` pushed

---

## G1 — Grid launch (12 cells, 8-way parallel)

**Shape:** Gaussian / Poisson / NB2 × p∈{20,50} × n∈{500,2000} × K=2  
**Launcher:** `GLLVM_TOTORO_LAUNCH=1 tools/t4_totoro_p6_grid.sh`  
**Remote:** `/home/snakagaw/core070-aghq-20260830/t4-p6-grid-01/repo/`

- [x] rsync completed (2026-09-05 13:53 MDT)
- [x] Remote GNU parallel `-j 8` started (or serial fallback logged)
- [x] Launch log archived under `logs/t4-p6-grid-launch-20260905-1353.log`
- [x] All 12 remote receipts present (`receipts/<tag>.json`) — **12/12 DONE**

**G1 PASS:** launch submitted + remote run finished (any mix of PASS/FAIL cells) — **PASS**  
**G1 FAIL:** infra/rsync/ssh failure before receipts written → ping Shinichi

---

## G2 — Pull and per-cell receipts — **PASS**

- [x] `out/` and `receipts/` pulled from Totoro
- [x] Per-cell dirs under `docs/dev-log/core070/t4-p6-grid-out/<tag>/` (and `t4-p6-out/` artefacts)
- [x] Collector / per-cell receipt writers produced 12× `{json,md}` under `docs/dev-log/core070/`
- [x] Summary PASS table in after-task `2026-09-05-totoro-t4-p6-grid.md` (full seff)

---

## G3 — Programme closeout — **PASS**

- [x] All 12 cell leaves checked — **12/12 PASS** (EOO contract)
- [x] `docs/dev-log/check-log.md` entry
- [x] After-task report (`docs/dev-log/after-task/2026-09-05-totoro-t4-p6-grid.md`)
- [x] **Explicitly NOT claimed:** true-parity promotion, gate-tier clearance

---

## Cell leaves (12) — all PASS

| # | Tag | Leaf | Result |
|---|-----|------|--------|
| 1 | `gaussian_p20_n500_K2` | `cells/gaussian_p20_n500_K2.md` | PASS |
| 2 | `gaussian_p20_n2000_K2` | `cells/gaussian_p20_n2000_K2.md` | PASS |
| 3 | `gaussian_p50_n500_K2` | `cells/gaussian_p50_n500_K2.md` | PASS |
| 4 | `gaussian_p50_n2000_K2` | `cells/gaussian_p50_n2000_K2.md` | PASS |
| 5 | `poisson_p20_n500_K2` | `cells/poisson_p20_n500_K2.md` | PASS |
| 6 | `poisson_p20_n2000_K2` | `cells/poisson_p20_n2000_K2.md` | PASS |
| 7 | `poisson_p50_n500_K2` | `cells/poisson_p50_n500_K2.md` | PASS |
| 8 | `poisson_p50_n2000_K2` | `cells/poisson_p50_n2000_K2.md` | PASS |
| 9 | `nb2_p20_n500_K2` | `cells/nb2_p20_n500_K2.md` | PASS |
| 10 | `nb2_p20_n2000_K2` | `cells/nb2_p20_n2000_K2.md` | PASS |
| 11 | `nb2_p50_n500_K2` | `cells/nb2_p50_n500_K2.md` | PASS |
| 12 | `nb2_p50_n2000_K2` | `cells/nb2_p50_n2000_K2.md` | PASS |

Seeds: **42** for all cells (matches pre-run convention); see `tools/t4_p6_cells.tsv`.

Cell 12 measured: JL fit ~2065 s, JL confint ~3898 s, R ~616 s; logLik Δ≈4.8e-7; vcov Fro≈1.2e-4.

---

## Infra leaves

- [x] Totoro SSH ping OK before launch
- [x] Remote base distinct from `t4-prerun-01` (no collision)
- [ ] Lane lease released when slice idle
