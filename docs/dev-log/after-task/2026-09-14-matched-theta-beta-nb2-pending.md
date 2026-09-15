# After-task — matched-θ disposition draft (`beta_logit`, `nb2_log`)

**Date:** 2026-09-14  
**Lane:** Cursor / Ada  
**Branch:** `docs/matched-theta-beta-nb2-pending` (from `origin/main` @ `d0cac7ae`)  
**Scope:** Docs-only **PENDING_ACCEPTANCE** decision — **no** acceptance, **no** `src/` / R engine, **no** Totoro, **no** `Project.toml` bump, **no** #323 waive.

## Deliverable

- [`docs/dev-log/decisions/2026-09-14-matched-theta-beta-nb2-pending.md`](../decisions/2026-09-14-matched-theta-beta-nb2-pending.md) — options **(A)** per-trait Julia φ, **(B)** shared-φ θ-map/fixture, **(C)** permanent matched-θ OUT with Rose fence; Ada default **(C)** if Shinichi delegates judgment while true-parity is paused on #323.

## Source

- Read-only inventory:
  [`2026-09-14-second-order-parity-inventory.md`](2026-09-14-second-order-parity-inventory.md) (matched-θ blocked cells table).

## Rose fence

- **≠** decision ACCEPTED until maintainer reply phrase (`accept matched-θ A|B|C`).
- **≠** programme §7, matched-coordinates promotion, or true-parity destination.
- **≠** #323 executed or waived.

## Checks run

- `git fetch origin main`; branch from `d0cac7ae`.
- **Not run:** `Pkg.test()`, Documenter (CI on PR).

## Follow-up (post-acceptance only)

- Update `second-order-parity-contract.md` §6 and `second-order-matched-coordinates-2026-09-04.md` per chosen option.
- Optional harness comment refresh in `tools/core070_second_order/` — separate slice after acceptance.
