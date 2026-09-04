# After-task: Option A parity closeout — S3 partial (2026-09-04)

## Scope

Continue Option A without D6: AGHQ reclassify batch (D4 DEFAULTED), export-gap honesty,
grouping design defaults (D5), Rose-facing doc refresh.

## Outcome

- **8 AGHQ rows reclassified** out of required set (`intentionally_excluded` + evidence)
- **14 AGHQ bind rows** — plan only (`t8-aghq-bind-next-slice.md`); no fake receipts
- **Ledger:** REQUIRED 505→497, FREE=0, aghq BLOCKED_SPEC_DEFECT 22→14
- **Export gap:** `export-gap-honesty-2026-09-04.md` (FORWARD=77, REVERSE=85 @ b4d5fee6)
- **Grouping:** D5 defaults recorded in `t12-grouping-levels-design.md`; D6 relay still OPEN
- **Rose targets updated:** `true-parity-decision-map.md`, `gllvmtmb-parity.md`, ultra-plan status

## Checks

```sh
python3 tools/core070_ledger_counts.py docs/dev-log/core070/required-source-case-map.json
python3 tools/parity_ledger.py --ref b4d5fee64def88bc768dda1f1f77c29b295edd86
```

## Still open (Shinichi)

| Item | Why |
|---|---|
| **D6** | Grouping importance + ZI trio relays — not defaulted |
| **T7** | Real-data repo pick (urbanisation_map vs avian_trait_scales) |
| **T9** | Promotion authority (Rose draft vs maintainer sentence) |
| **T10** | Phylo transport Q1–Q4 |
| **T14** | NB2 Wald NaN fixture strategy (F1/F2/F3) |
| **14 AGHQ binds** | Need R public-fit receipts (local/Totoro) |
| **S5** | Real-data workflow — blocked on T7 + #1236 |
| **S7** | arcG — separate coverage arc |

## PRs

- GLLVM.jl #280 (this slice — JL docs + ledger JSON)
- gllvmTMB #1268 (no new commits this slice)

True parity **not** claimed.
