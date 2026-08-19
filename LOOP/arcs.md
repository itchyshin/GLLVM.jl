# Arcs — gllvmjl-parity-beyond (G0 approved 2026-08-18)

Status: todo / doing / done / blocked. Gate = needs a human before it can proceed.

Do **not** start P2 / P3 / E / C / X in the P1 engine closeout.

| # | arc | status | gate? |
|---|-----|--------|-------|
| P1-Id | Multinomial / categorical Identity (docs only; twin fid 16; ledger stays `missing`) | done | ACCEPTED on this branch |
| P1-eng | Multinomial engine (`src/` + focused FD/tests). v1 FE softmax only | done | focused **41/41** after `GLLVM.Multinomial` qualify; ledger still `missing` |
| P2a | `truncated_nbinom2` Arc1b — twin fid 11, per-trait `log_phi_truncnb2`. Notes: `docs/design/capability-status.md` + `docs/dev-log/after-task/2026-08-15-truncated-nbinom2-identity-engine.md`. Later file: `src/families/truncated_nbinom2.jl` | todo | **OWED — do not start this arc** |
| P2b | `lognormal` bridge + light RCall Δ — twin fid 3. Notes: capability-status; reml after-task `docs/dev-log/after-task/2026-08-16-reml-promote-ledger-honesty.md` (“the one genuinely OWED bridge row”). **No Δ number exists.** Later file: `src/bridge.jl` | todo | **OWED — do not start this arc** |
| P3 | Tweedie T2–T5 unpaid; T6 **paid** (#236/#238). `fit_gllvm` admit **STOP**. Do not open T2–T5 files in P1 | todo | later G0 before any admit |
| E | AGHQ chips 2 → 3 → 4 after affordability `/goal` STOPs. A4(5) waits. Both AGHQ rows stay `missing` | blocked | **wait #255 / afford STOP**; do not touch `aghq_grid.jl` |
| C | Covariance grammar; cheapest first = `none × dep()`. File-disjoint from `aghq_grid.jl` | todo | after E (or Shannon-clear file-disjoint slice) |
| X | Broad-grid coverage certificate | blocked | Totoro/DRAC only if Shinichi sizes+asks |

## Owed-chip stamp (2026-08-18; live `origin/main` `3d5acba0`)

**Still OWED (fid-admitted):**

1. `truncated_nbinom2` Arc1b — twin fid 11, per-trait `log_phi_truncnb2`.
2. `lognormal` bridge + light RCall Δ — twin fid 3. No Δ number exists.

**Not restamped OWED:** `truncated_poisson` fid 10 — leftover cell only,
not an OWED stamp after reml honesty.

**Tweedie:** T6 paid. T2–T5 unpaid. Surface admit STOP.

## Fence (P1 engine, now landed)

- No invented twin Δ
- No `categorical()` alias
- No `aghq_grid.jl` / `test/test_aghq_gate.jl`
- No honesty worktree, no Dropbox checkout
- No Phase E / C / X
- No Tweedie T2–T5 files
- No P2a / P2b engine or bridge edits
- Ledger `multinomial / categorical` stays `missing`
