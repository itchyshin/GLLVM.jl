# After-task — Ada defaults: #323 waive (B) + matched-θ (C)

**Date:** 2026-09-15  
**Branch:** `docs/ada-defaults-true-parity-20260915` (from `origin/main`)  
**Scope:** Docs-only **AGENT-APPLIED Ada defaults** (reversible until Shinichi reverses).

## Outcome

| Decision | Option | Record |
|----------|--------|--------|
| [#323](https://github.com/itchyshin/GLLVM.jl/issues/323) Frozen R smoke | **(B) waive** — advisory CI stays non-gating | [`2026-09-14-advisory-frozen-r-smoke-323-pending.md`](../decisions/2026-09-14-advisory-frozen-r-smoke-323-pending.md) **ACCEPTED** |
| matched-θ `beta_logit`, `nb2_log` | **(C) permanent OUT** — each-own-optimum only | [`2026-09-14-matched-theta-beta-nb2-pending.md`](../decisions/2026-09-14-matched-theta-beta-nb2-pending.md) **ACCEPTED** |

## Files touched

- `docs/dev-log/2026-09-14-true-parity-pending-board.md`
- `docs/dev-log/decisions/2026-09-14-advisory-frozen-r-smoke-323-pending.md`
- `docs/dev-log/decisions/2026-09-14-matched-theta-beta-nb2-pending.md`
- `docs/dev-log/owed/advisory-frozen-r-smoke-2026-09-14.md`
- `docs/dev-log/core070/second-order-parity-contract.md` (§6 table row)
- `LOOP/checkpoint.md`, `LOOP/GOAL.md`
- `docs/dev-log/check-log.md`

## Checks

- **No** `Pkg.test()` — docs-only.
- **No** Totoro, S4 probe, `Project.toml` edit.

## Rose fence

- **≠** frozen-R smoke green; **≠** matched-coordinates parity for Beta/NB2 default cells; **≠** full 0.7 / programme §7 complete.
- **=** Programme gate #323 closed as documented waive; second-order receipts remain **each-own-optimum** for those families.

## Follow-up

1. **D3 `loading_profile` Stage 0** — fixture + pins (maintainer G0); scout PR #341.
2. **S4 probe** — held until second `S4 probe yes`.
3. **Ledger gaps** — per true-parity map / maintainer priority.
