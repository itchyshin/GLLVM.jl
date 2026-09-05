# T4 Totoro pre-run programme — multi-day plan (2026-09-05)

**Status:** APPROVED for compute-go (Shinichi 2026-09-05).  
**Lane:** `cursor/totoro-t4-prerun-20260905` · worktree `GLLVM.jl-gllvm-twin-20260904`  
**Authority:** P6 Ada-default (`true-parity-programme-decision-map-2026-09-05.md` §P6); D-139 estimate
before launch; D-50 (campaigns off GitHub Actions); D-220 (campaigns never block Cursor chat).  
**Oracle (read-only):** gllvmTMB 0.7.0 @ `b4d5fee64def88bc768dda1f1f77c29b295edd86`.  
**Claim boundary:** receipts inform realistic-size scaling and second-order tolerances at RSZ — **NOT**
a true-parity or gate-tier promotion claim.

---

## Goal (leave-this-and-return)

Run **three single-cell Totoro pre-runs** (Gaussian → Poisson → NB2), each at **p=20, n=500, K=2,
seed=42**, record measured wall times (`seff`), and only then re-estimate the full **12-cell P6 grid**
(Gaussian/Poisson/NB2 × p∈{20,50} × n∈{500,2000}). Do **not** launch the 12-cell grid until all
three family pre-runs have PASS receipts with `seff`.

**Success for this programme slice:** Gaussian pre-run receipt committed; Poisson and NB2 queued only
after Gaussian PASS; `.unlazy/totoro-t4-prerun/GATES.md` leaves checked; maintainer can resume from
this file after 2–3 days away.

---

## Day 0 — sync and dry-run (≤30 min agent time)

| Step | Action | Owner | Done when |
|---|---|---|---|
| 0.1 | `git fetch origin && git checkout cursor/totoro-t4-prerun-20260905 && git rebase origin/main` | agent | HEAD @ `47d35d70` (includes #294 + #295) |
| 0.2 | Confirm #294 @ `cffd5c8f` and #295 @ `47d35d70` merged | agent | recorded in check-log |
| 0.3 | Read estimate: `docs/dev-log/core070/t4-totoro-estimate-2026-09-05.md` | agent | — |
| 0.4 | Dry-run launcher (must exit 0, no network): `tools/t4_totoro_gaussian_prerun.sh` | agent | prints rsync + ssh block only |
| 0.5 | Claim lane lease on `docs/dev-log/plans/`, `docs/dev-log/core070/`, `tools/t4_totoro_gaussian_prerun.sh` | agent | `GRANTED` |
| 0.6 | Ping test: `ssh -o ControlPath=~/.ssh/cm/snakagaw@totoro.biology.ualberta.ca:22 snakagaw@totoro.biology.ualberta.ca hostname` | agent | `totoro` |

**Main sync note (2026-09-05):** #294 merged @ `cffd5c8f`. #295 closed unmerged; Poisson 2SO smoke
receipt already on main via day-1 path.

---

## Day 0–1 — launch Gaussian pre-run ONLY

**Cell 1 of 3** — row A2 (`GAUSSIAN-IDENTITY-2SO`), each-own-optimum tier.

| Field | Value |
|---|---|
| Family | Gaussian identity, ordinary `latent()` |
| Shape | p=20, n=500, K=2 |
| Seed | 42 |
| Host | `totoro.biology.ualberta.ca` |
| Resources | 1 core, 4 GB envelope, ~30 min wall margin |
| Remote layout | `/home/snakagaw/core070-aghq-20260830/t4-prerun-01/repo/` |
| Launcher | `tools/t4_totoro_gaussian_prerun.sh` |

**Launch command (the only authorised submit for day 0–1):**

```bash
cd /Users/z3437171/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904
GLLVM_TOTORO_LAUNCH=1 tools/t4_totoro_gaussian_prerun.sh 2>&1 | tee logs/t4-gaussian-prerun-launch-$(date +%Y%m%d-%H%M).log
```

What it does: rsync repo (excludes `.git`, `.julia`, local smoke dirs) → ssh remote run → Julia
`tools/core070_realistic_size_cell.jl gaussian 20 500 2 42` → R
`tools/core070_realistic_size_cell.R gaussian 20 500 2 42`.

**Do NOT launch:** Poisson, NB2, or any second cell until Gaussian receipt is PASS (gate below).

---

## Days 1–2 — poll, pull, commit receipt

### Poll (repeat every 4–8 h while away; safe to skip overnight if launch log shows completion)

```bash
TOTORO_SOCK="$HOME/.ssh/cm/snakagaw@totoro.biology.ualberta.ca:22"
REMOTE="/home/snakagaw/core070-aghq-20260830/t4-prerun-01/repo"

# 1) Is the remote run still alive?
ssh -o "ControlPath=${TOTORO_SOCK}" snakagaw@totoro.biology.ualberta.ca \
  'pgrep -af "core070_realistic_size_cell" || echo NO_ACTIVE_CELL'

# 2) Tail remote logs (if any)
ssh -o "ControlPath=${TOTORO_SOCK}" snakagaw@totoro.biology.ualberta.ca \
  "tail -40 ${REMOTE}/logs/* 2>/dev/null || ls -la ${REMOTE}/out/"

# 3) Pull outputs when DONE line seen in launch log or remote out/ populated
rsync -avz -e "ssh -o ControlPath=${TOTORO_SOCK}" \
  snakagaw@totoro.biology.ualberta.ca:${REMOTE}/out/ \
  docs/dev-log/core070/t4-prerun-out/gaussian/
```

### Receipt commit (after pull)

1. Write `docs/dev-log/core070/t4-prerun-gaussian-receipt-2026-09-05.json` — fields mirror toy 2SO
   receipts (`se_max_relative_delta`, `vcov_frobenius_relative_delta`, `ci_endpoint_max_delta`,
   `r_condition_number`, `native_condition_number`, `wall_*_sec`, `eoo_smoke_pass`, `claim_boundary`).
2. Write companion `.md` note with human-readable PASS/FAIL and **seff summary** (total wall, Julia
   fit, Julia confint, R fit).
3. Update `.unlazy/totoro-t4-prerun/GATES.md` leaf G1.
4. Append `docs/dev-log/check-log.md`; extend after-task stub
   `docs/dev-log/after-task/2026-09-05-totoro-t4-prerun.md`.

**Receipt PASS criteria (informing, not gate-tier promotion):**

- Both sides converged; outputs present.
- Each-own-optimum deltas recorded (pass/fail against `second-order-parity-contract.md` rtol with
  cond(H) scaling — record, do not widen silently).
- `seff` wall times logged for D-139 re-estimate of cells 2–3 and full grid.

---

## Gate — Poisson and NB2 (cells 2–3)

**Ada default:** queue next family **only after** prior receipt PASS.

| Gate | Condition | Next action |
|---|---|---|
| G1 → G2 | Gaussian receipt PASS + `seff` recorded | Clone launcher pattern for Poisson (`family=poisson` same shape); maintainer ping optional if auto-continuing |
| G2 → G3 | Poisson receipt PASS | NB2 pre-run (`family=nb2`); watch NB2 boundary dispersion (toy finding: Julia vcov can NaN) |
| G3 → grid | All three receipts PASS | **Stop and re-estimate** 12-cell grid with measured `seff`; Shinichi G0 before full P6 launch |

**Pre-authorised in plan (Ada default):** agent may queue Poisson after Gaussian PASS without a new
chat message, but must commit Gaussian receipt first and note the gate crossing in check-log.

**NOT authorised:** 12-cell P6 grid, multi-seed campaigns, DRAC array, or any true-parity claim.

Poisson/NB2 launch shape (when gated open):

```bash
# After writing tools/t4_totoro_poisson_prerun.sh (copy Gaussian script, FAMILY=poisson)
GLLVM_TOTORO_LAUNCH=1 tools/t4_totoro_poisson_prerun.sh

# NB2 similarly — FAMILY=nb2
```

Until family-specific scripts land, remote one-liner is acceptable:

```bash
ssh -o "ControlPath=${TOTORO_SOCK}" snakagaw@totoro.biology.ualberta.ca bash -s <<'REMOTE'
cd /home/snakagaw/core070-aghq-20260830/t4-prerun-01/repo
export JULIA_NUM_THREADS=1 OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1
export JULIA_DEPOT_PATH=/home/snakagaw/.julia:/home/snakagaw/codex/julia_depot
export R_LIBS=/home/snakagaw/core070-aghq-20260830/oracle-build-01/library
/home/snakagaw/.julia/juliaup/julia-1.10.10+0.x64.linux.gnu/bin/julia --project=. \
  tools/core070_realistic_size_cell.jl poisson 20 500 2 42
Rscript --vanilla tools/core070_realistic_size_cell.R poisson 20 500 2 42
REMOTE
```

---

## Stop conditions

| Stop | Trigger | Action |
|---|---|---|
| S1 | Totoro SSH/rsync fails twice | Document blocker in after-task; leave exact retry command for Shinichi |
| S2 | Remote Julia/R error (missing depot, oracle lib, OOM) | Capture stderr in `docs/dev-log/core070/t4-prerun-gaussian-fail-*.md`; do not retry blindly |
| S3 | Gaussian receipt FAIL on tolerance | Record cond(H) and deltas; **do not** widen tolerances; ping Shinichi before Poisson |
| S4 | Wall time > 30 min on Totoro | Note in receipt; re-estimate before cells 2–3 (D-139) |
| S5 | Foreign lane edits same paths | Shannon check; narrow lease or wait |

---

## Who to ping

| Situation | Ping |
|---|---|
| Gaussian PASS, auto-queue Poisson OK | Optional — check-log entry sufficient (Ada default) |
| Gaussian FAIL or infra blocker | **Shinichi** (chat or coordination board) |
| NB2 Julia vcov NaN (expected risk) | **Shinichi** — disposition before grid |
| Full 12-cell grid estimate ready | **Shinichi G0** (D-139) |
| True-parity / gate-tier wording question | **Rose** read-only scan on receipt prose |

---

## Resume after 2–3 days away (Shinichi checklist)

1. Open this file and `.unlazy/totoro-t4-prerun/GATES.md`.
2. `git pull` on branch `cursor/totoro-t4-prerun-20260905`; read latest check-log entry.
3. Check launch log under `logs/t4-gaussian-prerun-launch-*.log` (local) or poll commands above.
4. If Gaussian receipt committed and G1 checked → Poisson either running or done; follow G2.
5. If nothing launched → run the **Launch command** in Day 0–1 (compute-go already given).
6. Draft PR for the branch — receipts may land as follow-up commits on same PR.

**One-liner status:**

```bash
cd /Users/z3437171/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904
git log -1 --oneline
ls docs/dev-log/core070/t4-prerun-gaussian-receipt-*.json 2>/dev/null || echo "NO GAUSSIAN RECEIPT YET"
grep -l "GLLVM_TOTORO_LAUNCH" logs/t4-gaussian-prerun-launch-*.log 2>/dev/null | tail -1
```

---

## Cross-links

| Artifact | Path |
|---|---|
| D-139 estimate | `docs/dev-log/core070/t4-totoro-estimate-2026-09-05.md` |
| Launcher | `tools/t4_totoro_gaussian_prerun.sh` |
| Cell drivers | `tools/core070_realistic_size_cell.{jl,R}` |
| Second-order contract | `docs/dev-log/core070/second-order-parity-contract.md` |
| Gate leaves | `.unlazy/totoro-t4-prerun/GATES.md` |
| M2 slice table | `docs/dev-log/core070/m2-slice-table-2026-09-05.md` |
| After-task | `docs/dev-log/after-task/2026-09-05-totoro-t4-prerun.md` |

---

## Timeline sketch

| Day | Expected state |
|---|---|
| 0 | Plan merged; dry-run OK; Gaussian launch submitted |
| 1 | Poll; pull `out/`; draft receipt if complete |
| 2 | Commit Gaussian receipt; queue Poisson if PASS |
| 3–4 | Poisson receipt; queue NB2 if PASS |
| 5+ | Three `seff` values → revised 12-cell estimate → Shinichi G0 for grid |

---

## Launch log (filled by agent)

| Field | Value |
|---|---|
| Launch attempted | 2026-09-05 |
| Launch command | `GLLVM_TOTORO_LAUNCH=1 tools/t4_totoro_gaussian_prerun.sh` |
| Local log | `logs/t4-gaussian-prerun-launch-20260905-retry2.log` |
| Status | **COMPLETE** — G1 PASS; Poisson may queue |

### Poisson launch (cell 2/3)

| Field | Value |
|---|---|
| Launch attempted | 2026-09-05 |
| Launch command | `GLLVM_TOTORO_LAUNCH=1 tools/t4_totoro_poisson_prerun.sh` |
| Local log | `logs/t4-poisson-prerun-launch-20260905-1312.log` |
| Status | **COMPLETE** — G2 PASS; NB2 may queue |
