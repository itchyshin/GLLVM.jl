# M2-S1 se=TRUE schema smoke — 2026-09-06

**Contract:** `docs/dev-log/core070/second-order-parity-contract.md` §5  
**Claim boundary:** M2 remainder smoke — **NOT** programme §7, coverage, recovery, or true-parity.

## What this proves

The Poisson toy cell (`run_one_cell("poisson")`) dispatched R `gllvmTMBcontrol(se=TRUE)`,
returned `sd_report`, and wrote every contract §5 receipt key including the previously
missing `derived_quantity` and `r_objective`. No `src/` or R-engine edit.

## Measured

| Field | Value |
|---|---|
| `schema_smoke_pass` | true |
| `r_has_sd_report` / `se_true_dispatched` | true |
| missing §5 keys | none |
| SE rel Δ | 5.81e-6 |
| vcov Fro rel Δ | 1.09e-5 |
| CI endpoint Δ | 5.27e-6 |
| wall | 26.1 s |

Live R package on this machine was **gllvmTMB 0.7.1**, not the frozen 0.7.0
`b4d5fee6` oracle. Recorded as a diagnostic caveat, not a re-freeze.

## Artifacts

- JSON: `docs/dev-log/core070/se-true-schema-smoke-receipt-2026-09-06.json`
- Driver: `tools/core070_second_order/smoke_se_true_schema.jl`
