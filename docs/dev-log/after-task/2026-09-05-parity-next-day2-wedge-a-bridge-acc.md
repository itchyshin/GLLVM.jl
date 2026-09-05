# After-task — parity-next day-2 wedge A (bridge ACC scout)

**Date:** 2026-09-05  
**Branch:** `cursor/parity-next-wedge-a-20260905`  
**Base:** `origin/main` @ `e3d4bb0f` (includes day-1 trust fences #288 + plan #287)

## Scope

G0-2 wedge **A** at thin depth: one documented `Rscript` bridge attempt on
Ayumi-495 `urbanisation_map` flagship cell (`ACC-URBMAP-BRIDGE-RSCRIPT`).

## Outcome — **PASS**

The narrow R→Julia bridge completed non-interactively on local Ayumi data:

- Model: 51 binary indicators × 191 reviews, binomial probit, single
  `latent(1|review, d=2, unique=FALSE)` — **no** structured terms refused.
- TMB baseline: logLik = −4417.36975075, 58.7 s.
- Julia bridge: logLik = −4417.36975059, |Δ| = **1.628×10⁻⁷**, 363.8 s.
- Receipt: `docs/dev-log/core070/acc-bridge-urbanisation-receipt-2026-09-05.json`
- Scout narrative: `docs/dev-log/core070/acc-bridge-urbanisation-2026-09-05.md`
- Log: `logs/wedge-a-acc-urbanisation-scout-2026-09-05.log`

## Checks run

```sh
cd ~/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904
GLLVM_JL_PATH="$PWD" GLLVMTMB_R_PATH=~/local-scratch/lanes/gllvmTMB-gllvm-twin-20260904 \
AYUMI_URBMAP_ROOT="$HOME/Dropbox/Github Local/urbanisation_map" \
JULIA_PROJECT="$PWD" JULIA_HOME="$HOME/.juliaup/bin" \
Rscript tools/wedge_a_acc_urbanisation_scout.R
# exit 0; receipt status PASS
```

Unlazy leaf: `.unlazy/parity-next-20260905/gates/leaf-s6-wedge-a-bridge-acc.md`
(G1–G7 targets).

## Not claimed

- Programme section 7 / unqualified parity / full catch-up surface / #1236 expansion.
- Loading crossproduct or coef-shape parity (ACC-URBMAP-01 class 4–5 still open).
- Full real-data acceptance programme (T7) — this scout is one thin cell only.

## Follow-up

- Day-3: Melissa plan-actual + leaf V1 verify (parity-next package closeout).
- T7 full real-data acceptance programme still waits on bridge expansion scope
  (#1236) per decision map — this scout is one thin cell only.
