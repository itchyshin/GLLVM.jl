# Arcs — overnight-a43-20260817 (G0 approved; Shinichi GOAL wins)

Status: todo / doing / done / blocked. Gate = needs a human before it can proceed.

| # | arc | status | gate? |
|---|-----|--------|-------|
| A0 | Identity-adjacent decision `docs/dev-log/decisions/2026-08-18-aghq-a43-gate.md` @ `b2d646fc` | done | — |
| A1 | Tests that `_aghq_stage1a_reject_extra` fail-loud is the gate at k>1 (`test/test_aghq_gate.jl` @ `5b4d9666`; 34/34) | done | — |
| A2 | check-log + after-task; Rose fence: not a TMB gate port; not an estimator; rows stay `missing` (Ada) | done | — |
| A3 | PR #253 MERGED @ `3d5acba0` (head `06c3ef17`). PR CI SUCCESS. Eligibility half only. | done | closed |
| A4(3) eligibility | declared-kwargs fail-loud lock (#253); honesty follow-up after Opus MIXED | done | — |
| A4(3) affordability | `k^d` / `d ≤ 5` cost bound | **open** | — |

**Overnight /goal DONE on eligibility.** Affordability is still **open**.
NEXT = later G0. Do not start A4(4) from this marker.

## Fence (do not start)

- A4(3) affordability / `k^d` / `d ≤ 5` engine (open; `#253` did not close it)
- A4(4) adaptation loop as engine
- A4(5) report honesty as surface / public `aghq=`
- leftover-1 `none × dep()` · CV · Tweedie · multinomial · ledger promote · Totoro/DRAC
- TMB `.aghq_gate` min-fill / `spHess` port
- Closed Stage-1b LOOP (`21e24e97`) · Dropbox checkout
- Omitted-kwargs detection / `row_effects=false` vs `unique_latent=false` (later engine)
