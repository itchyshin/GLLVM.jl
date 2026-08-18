# Decision addendum: A4(3) affordability half closes

**Date:** 2026-08-18
**Status:** ACCEPTED — this slice **closes** the A4(3) **affordability** half
**Lane:** `cursor/lane-aghq-a43-afford-20260818`
**Does not replace:** `docs/dev-log/decisions/2026-08-18-aghq-a43-gate.md`
(#253 / #255 eligibility lock). Eligibility in that note stays
**declared-kwargs**.
**Depends on:** Identity `docs/dev-log/decisions/2026-08-17-aghq-identity.md`
§A4(3); gate lock (#253 @ `3d5acba0`); honesty PR #255 MERGED @
`81866b1a` (declared-kwargs)
**Do not** claim eligibility is now model inspection. **Do not** close
A4(4) or A4(5). **Do not** add a public `aghq=`. **Do not** promote
either AGHQ ledger row. **Do not** port TMB `spHess` / min-fill /
`.aghq_gate`. **Do not** invent `aghq_gate`.

## What this addendum does

A4(3) is two halves. #253 / #255 shipped and named the first. This
slice ships the second. #255 MERGED @ `81866b1a`; the three `#253`
`!isdefined` absence tests (`_aghq_kd_bound`, `_aghq_d_bound`,
`aghq_gate`) plus the #255 comments on those rows are **deleted**.

| Half | What it is | After this slice |
|---|---|---|
| Eligibility | `_aghq_stage1a_reject_extra` throws on **declared** extras | **Unchanged.** Stays declared-kwargs (#253 / #255). Omitted kwargs still do not fire the gate. Arc 3 (`false` vs `nothing`) stays later engine. |
| Affordability | cheap `k^d` / `d ≤ 5` cost bound on dense loadings-only `z_B` | **Closed** by `_aghq_kd_bound`. Coverage lives in `test/test_aghq_kd_bound.jl`. |

#255 correctly left affordability **open** on the gate note. This file
is the later lock. The "affordability remains open" sentences on the
gate note are historical (#253 / #255). Do not invent `aghq_gate`.

## Contract (cite; do not re-derive)

- State the bound as **tensor size** (`k^d`) or **latent dimension**
  (`d ≤ 5`) on a dense loadings-only `z_B` block — not a treewidth
  measurement. A complete graph on `d` nodes has treewidth `d − 1`, so
  twin `tw ≤ 4` is the analogue of `d ≤ 5` here.
- Fail-loud at `k > 1` when the bound is ineligible. `k = 1` still ≡
  Laplace.
- Name the helper without copying twin `.aghq_gate` / `aghq_gate`.
- Eligibility remains declared-kwargs. Do not wire omitted-kwargs
  detection (arc 3).
- Both AGHQ ledger rows stay `missing`. This is not an estimator.

## Out of this addendum

- Arc 3 gate wiring (`row_effects=false` throws vs
  `unique_latent=false` passes).
- A4(4) adaptation-loop / fit-time `k = 1` skip engine.
- A4(5) report honesty / public `aghq=`.
- TMB `.aghq_gate` / `spHess` / min-fill port.
- Ledger promote; twin Δ; Tweedie `fit_gllvm`.

## Rose fence (for sibling Rose — not a self-signed PASS)

Ada authored this addendum. Do **not** treat this file as a Rose PASS.
Sibling Rose must verify the fence claims in
`docs/dev-log/after-task/2026-08-18-aghq-a43-afford-close.md`.
