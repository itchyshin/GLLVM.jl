# Advisory gllvmTMB 0.7.1 smoke — receipt only (2026-09-05)

**Not an oracle upgrade.** Frozen CI pin `b4d5fee6` (gllvmTMB 0.7.0) remains the
authority for parity receipts (`ci-oracle-reproducibility-finding.md`).

## What ran

Local install of gllvmTMB **0.7.1** from twin R source tree; Julia parity smoke via
`tools/advisory_r071_smoke.jl` targeting `test/parity/test_negbin_parity.jl`.

## Outcome

**Fail — receipt only.** NB2 grouped health gate errors (`original NB2 data changed` in
`test/parity/nb2_health.jl`); 3 pass / 1 fail / 1 error in negbin parity block.

Log: `logs/advisory-r071-smoke-20260905-0516.log`.

## Disposition impact

Does **not** change §6 holdout statuses. Confirms advisory-build health gate is
noisier than pinned oracle; NB2-log batch-1 remains **PARTIAL (SO)** not upgraded.
