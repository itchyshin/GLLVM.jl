# Plan vs Actual — truncated_nbinom2 Identity→Engine

**Date:** 2026-08-15  
**Plan:** `docs/dev-log/plans/2026-08-15-truncated-nbinom2-identity-engine.md`  
**Lane:** `cursor/truncated-nbinom2-20260815`

## Actuals

| Field | Value |
|---|---|
| Recommended / actual | 6–9 h / ~2–3 h wall (overlap with #205 CI wait; Identity+engine+focused) |
| Requested / used | autonomous keep-going / keep-going `7b6ad608` |
| Rungs completed | S1 Identity · S2 Engine · S3 Tests · S4 Ledger · S5 Close (docs); S0 #205 merge pending CI |
| Under-run event | Shared-`r` + HurdleNB reuse shortened engine vs greenfield estimate |
| Calibration | truncated_poisson clone estimate held; Dual-typed `TruncatedNegBin2{T}` one repair pass |
| Metric movement | `planned` −1 / `implemented` +1 (`truncated_nbinom2`) |
| Result | Focused **11/11 Pass**; ledger flip; after-task written; PR pending post-#205 rebase |
| Next arc | Arc1b per-trait / light RCall · or REML promote · or truncated confint |

## Melissa note

Plan Ada default (shared-`r` Arc1) executed as written. Twin light Δ deferred (allowed, not required). Rose fences intact.
