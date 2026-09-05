# Wedge A — bridge ACC scout (Ayumi `urbanisation_map`)

**Date:** 2026-09-05 · **Depth:** thin scout (G0-2 **A**) · **NOT implementing full**
bridge expansion (#1236) or programme §7.

## Objective

Prove or honestly block one Ayumi-style real-workflow cell via R→Julia bridge
(`engine = "julia"`) on the T7-default repo `urbanisation_map`, using a
documented non-interactive `Rscript` path (ACC class `ACC-BRIDGE-RSCRIPT` from
`real-workflow-acceptance-lessons.md`).

## Recon summary

| Item | Finding |
|---|---|
| Data | `/Users/z3437171/Dropbox/Github Local/urbanisation_map/data/processed/model_matrix_primary.rds` — **present** (191 reviews × 54 cols). |
| Model template | `traits(...) ~ 1 + latent(1 \| review, d = 2, unique = FALSE)`, `unit = "review"`, `binomial(probit)` — single reduced-rank block, **no** phylo/spatial/animal/kernel. |
| Bridge admission | **Admitted** on the narrow R surface (`parity-next-bridge-admit-20260905.md`); would **BLOCK** only on `GJL-GATE-STRUCTURED-TERMS` if structured terms were required — they are not for this cell. |
| Prior evidence | ACC-URBMAP-01 (2026-09-01, Totoro) reported logLik agreement with flagged loading crossproduct; this scout re-measures locally at thin depth. |

Indicator set: 51 columns (primary matrix minus `level_individual`; no
`main_pruning.csv` in local clone — scout fallback per path scout).

## Attempt

**ACC id:** `ACC-URBMAP-BRIDGE-RSCRIPT`

**Command:**

```bash
cd "/Users/z3437171/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904" && \
GLLVM_JL_PATH="/Users/z3437171/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904" \
GLLVMTMB_R_PATH="/Users/z3437171/local-scratch/lanes/gllvmTMB-gllvm-twin-20260904" \
AYUMI_URBMAP_ROOT="/Users/z3437171/Dropbox/Github Local/urbanisation_map" \
JULIA_PROJECT="/Users/z3437171/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904" \
JULIA_HOME="$HOME/.juliaup/bin" \
Rscript tools/wedge_a_acc_urbanisation_scout.R
```

Runner: `tools/wedge_a_acc_urbanisation_scout.R` (TMB baseline then
`engine = "julia"`; writes machine receipt on exit).

## Measured result — **PASS** (thin scout)

| Quantity | TMB | Julia bridge |
|---|---:|---:|
| logLik | −4417.36975075 | −4417.36975059 |
| \|Δ logLik\| | — | **1.628×10⁻⁷** |
| convergence | 0 | bridge object returned |
| wall (s) | 58.7 | 363.8 |
| max_gradient (TMB health) | 3.33×10⁻⁴ | not surfaced on bridge object |

Julia emitted a Laplace saturation warning (3/9741 cells; ‖Λ̂‖ ≈ 5.86) — same
pathology class flagged in ACC-URBMAP-01; **not** counted as a bridge refusal.

Machine receipt:
`docs/dev-log/core070/acc-bridge-urbanisation-receipt-2026-09-05.json`

Log:
`logs/wedge-a-acc-urbanisation-scout-2026-09-05.log`

## What this does **not** claim

- Programme section 7 or an unqualified parity claim (harness + real-workflow
  acceptance programme incomplete).
- Full catch-up surface / 0.7.1 export port / #1236 bridge expansion.
- Loading crossproduct, coef-name, or extractor symmetry (ACC classes 4–5;
  prior ACC-URBMAP-01 flagged 2.2×10⁻² on ΛΛᵀ).
- Production Ayumi workflow parity (`n_init = 5`, constraint refits, bootstrap
  inference — out of thin-scout scope).

## Minimal admitted cell (reference only)

The narrow bridge also admits the synthetic long-format Poisson smoke documented
in `parity-next-bridge-admit-20260905.md`; that cell was **not** used for this
ACC PASS — this receipt is tied to `urbanisation_map` only.
