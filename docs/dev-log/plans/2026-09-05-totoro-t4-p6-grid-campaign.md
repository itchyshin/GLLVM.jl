# T4 P6 grid campaign — 12-cell Totoro plan (2026-09-05)

**Status:** LAUNCHER READY — **not launched** (needs Shinichi G0).  
**Lane:** `cursor/totoro-t4-p6-grid-20260905` · worktree `GLLVM.jl-gllvm-twin-20260904`  
**Authority:** P6 Ada-default; pre-run G1–G3 PASS + G4 re-estimate in
`2026-09-05-totoro-t4-prerun-programme.md`.  
**Claim boundary:** receipts inform realistic-size scaling and second-order tolerances — **NOT**
true-parity or gate-tier promotion.

---

## Goal (leave-this-and-return)

Run the **full 12-cell P6 grid** on Totoro: Gaussian, Poisson, NB2 at p∈{20,50}, n∈{500,2000},
K=2, with **8-way GNU parallel**, per-cell receipts, and honest FAIL recording (grid continues on
cell failure). Pull outputs, run collector, update gate leaves.

**Success:** all 12 remote receipts present; pulled artifacts under `docs/dev-log/core070/t4-p6-grid-out/`;
summary table committed; gate leaves checked.

---

## Grid specification

| Dimension | Values |
|---|---|
| Families | gaussian, poisson, nb2 |
| p | 20, 50 |
| n | 500, 2000 |
| K | 2 (fixed) |
| Seeds | 42 (all cells; matches pre-run) |
| Cells | **12** |

**D-139 envelope (from pre-run G4):** serial mid ~3.0 h; **8-core parallel mid ~23–30 min** + rsync/JIT.

---

## Day 0 — dry-run and G0

| Step | Action | Done when |
|---|---|---|
| 0.1 | `git checkout cursor/totoro-t4-p6-grid-20260905 && git pull` | on grid branch |
| 0.2 | Dry-run: `tools/t4_totoro_p6_grid.sh` | exit 0, prints rsync + parallel spec |
| 0.3 | Confirm pre-run G1–G3 PASS receipts on prerun branch / #296 | recorded |
| 0.4 | **Shinichi G0** for grid launch | check G0 box in `.unlazy/totoro-t4-p6-grid/GATES.md` |

---

## Day 0–1 — launch grid (after G0 only)

```bash
cd /Users/z3437171/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904
GLLVM_TOTORO_LAUNCH=1 tools/t4_totoro_p6_grid.sh \
  2>&1 | tee logs/t4-p6-grid-launch-$(date +%Y%m%d-%H%M).log
```

Optional: `GLLVM_TOTORO_PARALLEL=4` to reduce Totoro load.

Remote layout: `/home/snakagaw/core070-aghq-20260830/t4-p6-grid-01/repo/`  
Drivers: `tools/core070_realistic_size_cell.{jl,R}` (same as pre-run).

**Do NOT launch** without `GLLVM_TOTORO_LAUNCH=1` and maintainer G0.

---

## Days 1–2 — poll, pull, collect

### Poll

```bash
TOTORO_SOCK="$HOME/.ssh/cm/snakagaw@totoro.biology.ualberta.ca:22"
REMOTE="/home/snakagaw/core070-aghq-20260830/t4-p6-grid-01/repo"

ssh -o "ControlPath=${TOTORO_SOCK}" snakagaw@totoro.biology.ualberta.ca \
  'pgrep -af "core070_realistic_size_cell|parallel" || echo NO_ACTIVE'

ssh -o "ControlPath=${TOTORO_SOCK}" snakagaw@totoro.biology.ualberta.ca \
  "ls -la ${REMOTE}/receipts/ 2>/dev/null; tail -5 ${REMOTE}/logs/*.log 2>/dev/null | tail -40"
```

### Pull (when `[p6-grid] DONE` in launch log)

```bash
rsync -avz -e "ssh -o ControlPath=${TOTORO_SOCK}" \
  snakagaw@totoro.biology.ualberta.ca:${REMOTE}/out/ \
  docs/dev-log/core070/t4-p6-grid-out/_merged_out/

rsync -avz -e "ssh -o ControlPath=${TOTORO_SOCK}" \
  snakagaw@totoro.biology.ualberta.ca:${REMOTE}/receipts/ \
  docs/dev-log/core070/t4-p6-grid-out/_receipts/
```

Split per-cell dirs (optional tidy):

```bash
# Example for one tag
TAG=gaussian_p20_n500_K2
mkdir -p "docs/dev-log/core070/t4-p6-grid-out/${TAG}"
cp docs/dev-log/core070/t4-p6-grid-out/_receipts/${TAG}.json \
   "docs/dev-log/core070/t4-p6-grid-out/${TAG}/"
cp docs/dev-log/core070/t4-p6-grid-out/_merged_out/${TAG}_* \
   "docs/dev-log/core070/t4-p6-grid-out/${TAG}/" 2>/dev/null || true
```

### Collect

```bash
python3 tools/core070_realistic_size_collect.py \
  docs/dev-log/core070/t4-p6-grid-out/_merged_out \
  docs/dev-log/core070/t4-p6-grid-out/_merged_out \
  --csv docs/dev-log/core070/t4-p6-grid-summary-2026-09-05.csv
```

(Filter `--cells` to a 12-row K=2 manifest if added later.)

---

## Resume after 2 days away

1. Open this file and `.unlazy/totoro-t4-p6-grid/GATES.md`.
2. `git pull` on `cursor/totoro-t4-p6-grid-20260905`; read latest check-log.
3. Check `logs/t4-p6-grid-launch-*.log` locally or poll commands above.
4. If G0 unchecked → **stop**; ping Shinichi for grid go.
5. If launch incomplete → re-run launch command (idempotent rsync; parallel skips finished cells only if receipts exist — otherwise manual disposition).
6. If receipts pulled → run collector, check 12 cell leaves, commit summary + after-task.

**One-liner status:**

```bash
cd /Users/z3437171/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904
git log -1 --oneline
ls docs/dev-log/core070/t4-p6-grid-out/_receipts/*.json 2>/dev/null | wc -l
grep -l "GLLVM_TOTORO_LAUNCH" logs/t4-p6-grid-launch-*.log 2>/dev/null | tail -1
```

---

## Stop conditions

| Stop | Trigger | Action |
|---|---|---|
| S1 | No Shinichi G0 | Do not set `GLLVM_TOTORO_LAUNCH=1` |
| S2 | SSH/rsync fails twice | Blocker in after-task; exact retry command for Shinichi |
| S3 | Single cell FAIL | Write FAIL receipt; **continue** grid; disposition in cell leaf |
| S4 | NB2 Julia vcov NaN | Record honest FAIL; ping Shinichi before claiming grid PASS |
| S5 | Wall > 2× G4 estimate | Note in summary; do not widen tolerances |

---

## Cross-links

| Artifact | Path |
|---|---|
| Pre-run programme | `docs/dev-log/plans/2026-09-05-totoro-t4-prerun-programme.md` |
| Launcher | `tools/t4_totoro_p6_grid.sh` |
| Gate leaves | `.unlazy/totoro-t4-p6-grid/GATES.md` |
| Cell drivers | `tools/core070_realistic_size_cell.{jl,R}` |
| Collector | `tools/core070_realistic_size_collect.py` |
| Second-order contract | `docs/dev-log/core070/second-order-parity-contract.md` |
| D-139 estimate | `docs/dev-log/core070/t4-totoro-estimate-2026-09-05.md` |
