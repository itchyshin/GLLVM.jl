# True-parity programme: maintainer board (2026-09-14, updated 2026-09-16)

STATE: **IN PROGRESS**. **Mac Studio owns programme (STARTED 2026-09-15).** #323, matched-θ **(C)**, §2 Hessian **(A)** disposed (Ada defaults). Ledger gap inventory done. arcG Julia-only disposition ACCEPTED (#358 + gllvmTMB #1284). Still open: S4 probe, D3 Stage 1, `Project.toml` `0.3.0`, Delta dispersion paste. Merged: #362 OrdinalPerTrait Wald (`c1962c5d`), #356 TweedieGrouped Wald (`569cd873`), #361 Lognormal/TruncPois/TruncNB2 Wald (`efc24554`), #355 parity_ledger aliases (`e87a4670`), #364/#365 board tips, **#366 MultinomialFit Wald** (`c1842dd69`), **#369 Mac handover** (`c00e9345`), **#370 Mac STARTED** (`c459751b`), **#371 goal+ultra-plan** (`9519b3e28`), **#367 Student-t fixed-ν Wald** (`9d300783c`), **#372/#373 SO inventory + post-#367 tips**, **#374 BetaBinomial shared-φ SO cell** (`eeb7e092`) → **PARTIAL (native Wald; φ unpaired)**, **#376 six holdout SO cells** (`47fcb23e`) → **PARTIAL (native Wald + paired toy Δ)**, **#377/#379 tips** (board correction), **#381 overnight handover**, **#382 morning-briefing refresh**, **#378 Tweedie shared-power SO cell** (`67247f52`) → **PARTIAL (option A; β/`b_fix` block only, power plug-in — not paired)**. Foreign: **#357** (do not edit). Paste-blocked; goal **not** complete.

Rehydrate: `origin/main` tip after `#378` `67247f52` (on top of `#374`/`#376`/`#379`/`#381`/`#382`); gllvmTMB `origin/main` @ `fba20d613`; frozen oracle `b4d5fee64def88bc768dda1f1f77c29b295edd86`; **`Project.toml` stays `0.3.0`**.

---

## Disposed (2026-09-15, Ada default)

| Item | Outcome | Decision |
|------|---------|----------|
| [#323](https://github.com/itchyshin/GLLVM.jl/issues/323) Frozen R smoke | Waived (B); advisory CI stays non-gating | [`2026-09-14-advisory-frozen-r-smoke-323-pending.md`](decisions/2026-09-14-advisory-frozen-r-smoke-323-pending.md) ACCEPTED |
| matched-θ beta_logit, nb2_log | Permanent OUT (C); each-own-optimum only | [`2026-09-14-matched-theta-beta-nb2-pending.md`](decisions/2026-09-14-matched-theta-beta-nb2-pending.md) ACCEPTED |
| §2 Hessian Binomial/cloglog + Tweedie grouped | Ratify `:observed` (A); receipts + defaults signed | [`2026-09-15-second-order-hessian-s2-pending.md`](decisions/2026-09-15-second-order-hessian-s2-pending.md) ACCEPTED |
| Julia-only arcG / DRAC (parity_ledger CLOSURE) | ACCOUNTED; Julia-beyond diagnostics; not owed to R | [`2026-09-15-julia-only-arcg-disposition.md`](decisions/2026-09-15-julia-only-arcg-disposition.md) ACCEPTED |

Reverse: Shinichi may paste `reopen #323`, `reject matched-θ C`, `reject §2 hessian A`, or `reject arcG disposition` in chat; agents must revert on explicit reverse only.

---

## Still open: paste-ready replies

### S4 public-formula probe (held)

Recorder on origin: [gllvmTMB PR #1283](https://github.com/itchyshin/gllvmTMB/pull/1283) (`97214679c`). Second explicit yes only (`LOOP/GOAL.md` QS4).

```
S4 probe yes
```

### D3 loading_profile (T5 row 8)

Scout: [PR #341](https://github.com/itchyshin/GLLVM.jl/pull/341). Stage 0 merged [PR #345](https://github.com/itchyshin/GLLVM.jl/pull/345).  
Stage 1: paste `G0 Stage 1` only.

### Ledger / capability gaps (item 3)

Inventory: [`2026-09-15-true-parity-ledger-gap-inventory.md`](after-task/2026-09-15-true-parity-ledger-gap-inventory.md). Rank 7 done (arcG; #358/#1284). Aliases landed (#355). Foreign: [#357](https://github.com/itchyshin/GLLVM.jl/pull/357) bridge logLik receipts — CONFLICTING on `check-log.md` only; do not edit from this lane.

### Second-order follow-up

Receipts: Delta shared-η [#347](after-task/2026-09-15-second-order-delta-followup.md); OrdinalPerTrait / TweedieGrouped / Lognormal+Trunc* on main (#362/#356/#361); **MultinomialFit** native Wald on main (#366); **Student-t fixed-ν** native Wald on main (#367); **BetaBinomial shared-φ** SO cell on main ([#374](after-task/2026-09-15-betabinomial-shared-phi-so.md), `eeb7e092`); **six holdout paired SO cells** on main ([#376](after-task/2026-09-16-six-holdout-so-cells.md), `47fcb23e`) → **PARTIAL (native Wald + toy Δ)**; **Tweedie shared-power SO cell** on main ([#378](after-task/2026-09-16-tweedie-shared-power-so.md), `67247f52`) → **PARTIAL (option A; `b_fix`/β block only, power plug-in, not jointly estimated — not paired in live Δ; contract §4 D1 not claimed)**. Bridge CI lift still waits on #357.  
Delta SO species dispersion: still OUT until paste `accept delta dispersion A`.  
BB shared-φ: **PARTIAL** (native Wald + `betabinomial_shared` toy cell; **β block only** — per-trait φ on R not paired in live Δ).  
Six-family holdout live-Δ: **MERGED** (#376) — Lognormal / OrdinalPerTrait / TruncPois / TruncNB2 / Multinomial FE / Student-t fixed-ν paired toy cells (β[] blocks; TruncNB2 large se_rel documented as shared-`r` vs R per-trait φ).  
Tweedie shared-power: **MERGED** (#378) — `cell_tweedie_shared`, option A (plug-in power, not jointly estimated); `b_fix`/β block only; species estimated-power `TweediePerTraitPowerFit` Wald is explicit follow-up, not this PR.  
Still OUT / open: GP-1 ruling / Student-t free ν / Λ raw / Tweedie **estimated** (jointly-optimised, not plug-in) power.

### Version

Project.toml remains 0.3.0 (D-183).

### Optional: re-run #323 on Totoro

```
ack Totoro D-139 #323 Track A
```

### T4 realistic-size second-order

Blocked on D-139 ack before Totoro spend (no separate paste string beyond an explicit D-139 ack in chat).

---

## Agent rules

- **Mac owns true-parity (STARTED 2026-09-15).** #374+#376+#378 MERGED (Tweedie shared-power SO cell landed, option A only); **Mac owns next ungated** slice (cloud does not start engine/Wald). Natural candidate: species estimated-power `TweediePerTraitPowerFit` Wald (#378's own follow-up), or FORWARD/TWIN_ALIAS hygiene (#350/#355 tool rows).
- No Totoro / D-139 without `ack Totoro D-139 #323 Track A|B` (or an explicit D-139 ack naming the T4 grid).
- Do not run S4 probe without `S4 probe yes`.
- Do not bump Project.toml or claim full 0.7 / §7 complete.
- Do not cite matched-θ for beta_logit / nb2_log default cells.
- Do not treat arcG/DRAC diagnostics as a coverage certificate or R-owed port.
- No gllvmTMB engine surgery (TMB/likelihood); tools disposition PRs OK.
- Do not edit #357 unless Shinichi pastes otherwise.
- Skipped unrelated opens: #363 env, #314 handover. Cloud fence: no GP-1 / free-ν / Λ raw / Delta paste / Stage1 / S4 / Totoro / Project.toml from cloud.
