# After-task — Option D matched-coordinates batch-1 pilot (2026-09-05)

## Scope

Parallel Option D slice: contract §4 matched-coordinates diagnostic at R-anchored θ
for batch-1 five-family window. Pilot tooling + receipts only — not programme §7 closure.

## Outcome

| Metric | Count |
|---|---:|
| Pass | **3** |
| Fail | **0** |
| Blocked | **2** |
| Skip | **0** |

| Cell | Status | se_max_rel | Notes |
|---|---|---:|---|
| gaussian | pass | 2.1e-7 | σ block; R `b_fix` excluded (Y pre-centred) |
| poisson | pass | 1.9e-7 | Direct `b_fix` + `theta_rr_B` map |
| binomial_logit | pass | 4.2e-8 | Direct `b_fix` + `theta_rr_B` map |
| beta_logit | blocked | — | R per-trait `log_phi_beta` (×p) vs Julia shared (×1) |
| nb2_log | blocked | — | R per-trait `log_phi_nbinom2` (×p) vs Julia shared (×1) |

Wall time ~74 s local (threads=1). Base post-#281 (`51e43a4a`).

## Checks run

```text
julia --project=. tools/core070_second_order/run_matched_batch1.jl
Artifacts: docs/dev-log/core070/second-order-matched-pilot-batch1-20260905/
summary.json pass_fail_blocked_skip = 3/0/2/0
```

## Files touched

- `tools/core070_second_order/theta_map.jl`, `run_matched_batch1.jl`, `common.jl`
- `docs/dev-log/core070/second-order-matched-pilot-batch1-20260905/` (summary + per-cell JSON)
- `docs/dev-log/core070/second-order-matched-pilot-batch1-20260905.md`
- `docs/dev-log/core070/second-order-matched-coordinates-2026-09-04.md` — disposition update
- `docs/dev-log/check-log.md` — append entry
- `docs/dev-log/after-task/2026-09-05-option-d-matched-coords-pilot.md` — this note

## Not claiming

- Programme-level second-order parity (contract §7)
- Full batch-1 matched tier (2/5 blocked on θ map)
- True parity or 0.7.1 surface port

## Follow-up

- Resolve per-trait vs shared dispersion before beta_logit / nb2_log matched tier
- Expand matched batch beyond batch-1 five-family window after θ-map blockers clear

Branch: `cursor/option-d-matched-coords-pilot-20260905`.
