# T4 realistic-size — D-139 Totoro estimate (2026-09-05)

**Status:** ESTIMATE ONLY — **not launched**, not queued on Totoro.  
**Slice:** M2-S3 (`m2-slice-table-2026-09-05.md`)  
**Programme authority:** P6 Ada-default — Gaussian, Poisson, NB2; p∈{20,50}; n∈{500,2000};
one pre-run cell per family before full grid (`true-parity-programme-decision-map-2026-09-05.md` §P6).  
**Compute doctrine:** D-139 (estimate before launch); D-50 (campaigns off GitHub Actions); D-220
(campaigns never block Cursor lane).

---

## Pre-run cell specification (first launch candidate)

This document sizes **cell 1 of 3** pre-runs — the day-1 programme target for row A2
(`family/GAUSSIAN-IDENTITY-2SO`).

| Field | Value |
|---|---|
| Family | Gaussian identity, ordinary `latent()` bare |
| Shape | **p = 20**, **n = 500**, **K = 2** (latent dimensions) |
| Seed | Single fixed seed (proposed: `42`; match parity harness convention) |
| Formula | R: `0 + trait ~ 1 + latent(1 \| unit, d = 2)` long-format; Julia: matched call shape |
| Comparison tier | **Each-own-optimum** (shipped claim tier per `second-order-parity-contract.md` §4) |
| Quantities | SE (β or σ_eps per fixture convention), fixed vcov block, Wald CI endpoints |
| Oracle | gllvmTMB 0.7.0 @ `b4d5fee64def88bc768dda1f1f77c29b295edd86` |
| R control | `gllvmTMBcontrol(n_init = 1L, se = TRUE)` |
| Julia | `confint(fit, Y)` after independent MLE fit |
| Hessian | Observed / Laplace-marginal on both sides (Gaussian: exact NLL + FD Hessian in Julia) |
| Record | `cond(H)_R`, `native_condition_number`, fixture shape, wall times — not gated |

**Not in pre-run:** matched-coordinates tier; multi-seed grid; Poisson/NB2 (cells 2–3, M2-S4).

---

## Scaling basis (measured anchors)

| Anchor | Shape | R fit | Julia fit | Julia confint | Source |
|---|---|---:|---:|---:|---|
| Toy 2SO pre-run | p=5, K=2, n=80 | 0.63 s | 9.38 s | 5.86 s | `second-order-prerun-2026-09-02.md` |
| Toy 2SO pre-run | p=5, K=2, n=60 | 0.60–0.91 s | 5–12 s | 1.4–2.0 s | same (Poisson/Binomial/Beta/NB2) |

**Scale factors p=20, n=500 vs p=5, n=80:**

| Dimension | Ratio | Effect on Gaussian fit (approx.) |
|---|---:|---|
| n (sites) | 500/80 ≈ **6.3×** | Likelihood / Cholesky per site — roughly linear in n |
| p (traits) | 20/5 = **4×** | Trait-covariance work — between O(p²) and O(p³) depending on kernel |
| K (fixed) | 1× | K=2 unchanged |
| Parameters | ~64 vs ~16 packed θ | Hessian **4× linear → ~16×** FD cost for confint |

**Combined rough multiplier (Julia):** 6 × (4–8) × (1–2 JIT amortised on Totoro) → **~25–50×**
toy wall time for fit; confint similar order.

**Mid estimate (Julia, warm-ish process on Totoro):**

| Step | Low | Mid | High |
|---|---:|---:|---:|
| Data simulate + I/O | 5 s | 15 s | 30 s |
| R fit + sdreport | 2 s | 8 s | 20 s |
| Julia fit | 60 s | 180 s | 480 s |
| Julia confint (FD Hessian) | 30 s | 120 s | 300 s |
| Compare + write receipt | 10 s | 30 s | 60 s |
| **Total wall (1 core)** | **~2 min** | **~6 min** | **~15 min** |

**Memory:** toy p=5 cells used ≪1 GB. At p=20, n=500, K=2 expect **≤2 GB** RSS (dense
p×p trait blocks × n sites); request **4 GB** Slurm/Totoro envelope for safety.

**Conditioning:** Panel C recorded cond(H) ~1e6 at toy shape with rotation-invariant discrepancy
2.2e-2 (`second-order-parity-contract.md` §4). At p=20, n=500 expect **higher** cond(H) —
tolerances scale by `cond(H)_R/1e3` (signed contract); record both sides, do not gate pre-run.

---

## D-139 verdict for this cell

| Criterion | Assessment |
|---|---|
| D-139 ≤30 min local smoke? | **No** — mid estimate ~6 min on Totoro, high ~15 min; within 30 min only at optimistic bound |
| D-139 >30 min → plan + pre-run + approval? | **Yes** — this document is the plan; launch requires maintainer OK after reading estimate |
| Totoro vs DRAC? | **Totoro** — single cell, ≤8 cores, no queue (D-50, compute-routing skill) |
| DRAC trigger | Not warranted for one cell; full 12-cell T4 grid might use DRAC array if serial >4 h |

**Recommendation:** treat as **>30 min campaign class** (conservative: high bound 15 min still
passes 30 min, but Hessian failure retry + JIT cold start can exceed); **queue on Totoro after
maintainer approval**, not in Cursor chat.

---

## Full T4 grid (reference — not day-1)

After three pre-runs (Gaussian, Poisson, NB2 @ p=20, n=500):

| Grid | Cells | Serial estimate (mid) | Totoro 8-core parallel |
|---|---|---:|---|
| 3 families × p{20,50} × n{500,2000} | **12** | 12 × 6 min ≈ **72 min** | ≈ **15–25 min** |
| + Poisson/NB2 Laplace overhead | — | ×1.5–3 vs Gaussian | same |

Poisson/NB2 pre-runs inherit toy anchor: Julia fit ~6–12 s at p=5 → expect **~3–10 min** mid
per cell at p=20, n=500 (Laplace mode solve dominates).

**Full grid launch:** only after M2-S3 and M2-S4 pre-run receipts; D-139 re-estimate with
measured `seff` from pre-runs.

---

## Proposed Totoro job shape (queue spec — DO NOT SUBMIT)

```
Host:     totoro.biology.ualberta.ca
Cores:    1 (OPENBLAS/OMP/JULIA_NUM_THREADS=1)
Memory:   4G
Wall:     00:30:00 requested (mid ~6 min; margin for JIT + Hessian retry)
Account:  local snakagaw (no Slurm)
Layout:   rsync repo → run scripts → write receipt TOML/MD under dev-log or scratch
Oracle:   frozen gllvmTMB 0.7.0 build (CORE070 pin)
Outputs:  local + copy receipt into docs/dev-log/core070/ (via lane after poll)
```

**Scripts (to be written in M2-S3 build slice, not day-1):**

1. `gen_data.jl` — simulate Gaussian latent model p=20, n=500, K=2, seed=42  
2. `r_fit.R` — fit + sdreport + cond(H) extract  
3. `julia_fit.jl` — fit + confint + receipt fields per §5 contract  
4. `compare_second_order.jl` — SE / vcov / CI deltas + write cell receipt  

Pattern follows `second-order-prerun-2026-09-02.md` remote layout
(`.../se-prerun-01/` on Totoro).

---

## Queue vs launch status

| Action | Status | Date |
|---|---|---|
| Write estimate (this doc) | **DONE** | 2026-09-05 |
| Maintainer review / approval | **PENDING** | — |
| Write run scripts (M2-S3) | **NOT STARTED** | blocked on harness M2-S1 or thin ad-hoc path |
| Submit Totoro job | **DO NOT LAUNCH** | per day-1 scope + D-139 |
| Poll results into gate-tier receipt | **NOT STARTED** | after launch + completion |

---

## Risks called before launch

1. **Gaussian β alignment** — toy fixture centres Y (no Julia β); p=20 realistic cell should use
   explicit intercept pairing or compare σ_eps / derived quantities only
   (`second-order-prerun-2026-09-02.md` §Limits).
2. **Julia JIT** — first-process penalty inflates wall time; Totoro script should warm once or
   use `--project=.` PackageCompiler is out of scope.
3. **cond(H) scaling** — pre-run may fail each-own-optimum tolerance at high cond(H) while still
   informing whether tolerances are viable at RSZ — record, do not widen silently.
4. **NB2 (later pre-run)** — boundary dispersion can NaN whole Julia vcov while R block-tolerates
   (`second-order-prerun-2026-09-02.md` finding 1); not applicable to Gaussian cell 1.

---

## One-paragraph Totoro recommendation (estimate summary)

Queue **one** Totoro job (1 core, 4 GB, 30 min wall request) for the Gaussian pre-run cell
**p=20, n=500, K=2, seed=42** after maintainer approves this estimate and M2-S1 harness wiring
(or an explicitly scoped thin script path) is ready. Mid wall time **~6 minutes**, high **~15
minutes** — borderline under D-139's 30-minute smoke line, so treat as a **campaign-class** run
(Totoro, not Cursor chat). Do **not** launch the 12-cell P6 grid until this cell and the Poisson
and NB2 pre-runs return receipts with measured `seff` times. Full grid serial mid-estimate **~72
minutes** ( **~15–25 minutes** at 8-way Totoro parallelism) assumes pre-run scaling holds.

---

## Cross-links

| Artifact | Path |
|---|---|
| M2 slice table | `m2-slice-table-2026-09-05.md` |
| Gate-tier row A2/A3 | `true-parity-gate-tier-2026-09-05.md` |
| P6 T4 grid decision | `true-parity-programme-decision-map-2026-09-05.md` §P6 |
| Second-order contract | `second-order-parity-contract.md` |
| Toy 2SO pre-run timings | `second-order-prerun-2026-09-02.md` |
| Compute routing skill | `~/shinichi-brain/skills/compute-routing/SKILL.md` (D-139, D-143) |
