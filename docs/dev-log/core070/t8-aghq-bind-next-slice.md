# T8 AGHQ bind — next slice (14 rows, receipts owed)

Status: **EXECUTED 2026-09-04** — all 14 rows bound via public `gllvmTMB()` fits.
Receipt: `aghq-public-policy-bind-receipt-2026-09-04.json` (sha256 in file).
Runner: `tools/core070_aghq_public_policy_bind.R`; ledger apply:
`tools/core070_aghq_public_policy_bind_apply.py`.

Oracle: frozen gllvmTMB 0.7.0 `b4d5fee6` for engine; policy reads may use R twin @
`origin/main` where noted in `t8-aghq-policy-rows-proposal.md`.

## Bindable rows (public R call → read fit$aghq)

| source_id | Public anchor | Risk |
|---|---|---|
| AGHQ-AUTO-K-BINOMIAL | `gllvmTMB(..., family=binomial(), latent(..., unique=FALSE), control=gllvmTMBcontrol(aghq="auto"))`; `fit$aghq$k` | low |
| AGHQ-AUTO-K-POISSON | same, `family=poisson()` | low |
| AGHQ-AUTO-K-GAUSSIAN | same, `family=gaussian()` | low |
| AGHQ-AUTO-K-NB2 | same, `family=nbinom2()` | low |
| AGHQ-AUTO-K-ORDINAL | same, `family=ordinal_probit()` | medium |
| AGHQ-AUTO-K-DELTA | same, `family=delta_gamma()` | medium |
| AGHQ-AUTO-K-TWEEDIE | same, `family=tweedie()` | medium |
| AGHQ-DEFAULT-OFF | `formals(gllvmTMBcontrol)$aghq` (no fit) | none |
| AGHQ-POLICY-OFF | fit + `aghq=FALSE`; `fit$aghq$used==FALSE` | low |
| AGHQ-POLICY-EXPLICIT | fit + `aghq=3L`; `fit$aghq$k==3` | low |
| AGHQ-POLICY-EXPLICIT-BYPASS-CUTOFF | fit + `aghq=9L`, n_traits≥20 | medium |
| AGHQ-POLICY-AUTO-ENFORCE-CUTOFF | `aghq="auto"`, n_traits=20; reason text | medium |
| AGHQ-POLICY-TRAITS19 | n_traits=19; AGHQ stays on | medium |
| AGHQ-POLICY-TRAITS20 | boundary duplicate of AUTO-ENFORCE-CUTOFF | medium |

## Done-when (per row)

1. Standalone R batch or smoke script runs the public call on a named fixture.
2. Receipt JSON + sha256 under `docs/dev-log/core070/` or `.unlazy/core070-aghq/`.
3. Ledger row: `executable_case_ids` populated, `disposition` removed, `evidence` cites receipt.
4. `python3 tools/core070_ledger_counts.py` → FREE=0.

## Blockers

- Local R + compiled TMB in twin worktree (capability proof per cursor handover).
- Medium-risk rows need p≥20 trait fixtures (size from existing core070 fixtures or new seed audit per T15).

Bind work is **optional catch-up** (compatibility tier only). AGHQ rows do **not** gate the
v0.true-parity claim unless the owner promotes them into gate-tier (M0-8 amendment below).

---

## Gate-tier disposition (2026-09-05 — M0-8 / P8)

**Authority:** G0 locked **2026-09-05** (`docs/dev-log/plans/2026-09-05-true-parity-ultra-plan.md`);
programme ticket **P8** (`true-parity-programme-decision-map-2026-09-05.md` §P8); map ticket
**M0-8**.

**Decision:** **Defer AGHQ from v0.true-parity gate-tier** unless owner explicitly promotes.

| Item | Disposition |
|---|---|
| 14 bindable AGHQ policy rows | Bound 2026-09-04 with receipts (`aghq-public-policy-bind-receipt-2026-09-04.json`) — **compatibility tier**, not gate-tier |
| T8 bind / ledger apply work | **Optional catch-up** — no programme blocker; run when twin R toolchain is convenient |
| AGHQ as integration engine for qualification | **Out of v0.true-parity claim** — Laplace remains default oracle path (G0 Q1) |
| Promotion path | Owner sentence or signed gate-tier amendment adding AGHQ rows |

**P8 status:** CLOSED — defer from gate-tier (research + decide complete for map clearance).

**M0-8 status:** CLOSED — strategy recorded in this file.

**Rationale:** True parity qualification runs against frozen 0.7.0 Laplace surface; AGHQ is
opt-in on R `main` and adds estimator variance not required for the gate-tier Ada default
(`true-parity-gate-tier-2026-09-05.md` §E).
