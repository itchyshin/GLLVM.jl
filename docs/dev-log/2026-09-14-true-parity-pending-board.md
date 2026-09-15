# True-parity programme: maintainer board (2026-09-14, updated 2026-09-15)

STATE: **IN PROGRESS**. **Mac Studio owns programme (STARTED 2026-09-15).** #323, matched-θ **(C)**, §2 Hessian **(A)** disposed (Ada defaults). Ledger gap inventory done. arcG Julia-only disposition ACCEPTED (#358 + gllvmTMB #1284). Still open: S4 probe, D3 Stage 1, `Project.toml` `0.3.0`, Delta dispersion paste. Merged: #362 OrdinalPerTrait Wald (`c1962c5d`), #356 TweedieGrouped Wald (`569cd873`), #361 Lognormal/TruncPois/TruncNB2 Wald (`efc24554`), #355 parity_ledger aliases (`e87a4670`), #364/#365 board tips, **#366 MultinomialFit Wald** (`c1842dd69`), **#369 Mac handover** (`c00e9345`), **#370 Mac STARTED** (`c459751b`), **#371 goal+ultra-plan** (`9519b3e28`), **#367 Student-t fixed-ν Wald** (`9d300783c`) → **PARTIAL (native Wald)**. Foreign: #357 CONFLICTING (do not edit). Paste-blocked; goal **not** complete.

Rehydrate: `origin/main` @ `9d300783c` (#367); gllvmTMB `origin/main` @ `fba20d613`; frozen oracle `b4d5fee64def88bc768dda1f1f77c29b295edd86`; **`Project.toml` stays `0.3.0`**.

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

Receipts: Delta shared-η [#347](after-task/2026-09-15-second-order-delta-followup.md); OrdinalPerTrait / TweedieGrouped / Lognormal+Trunc* on main (#362/#356/#361); **MultinomialFit** native Wald on main (#366); **Student-t fixed-ν** native Wald on main (#367, `9d300783c`) → **PARTIAL (native Wald)**. Bridge CI lift still waits on #357.  
Delta SO species dispersion: still OUT until paste `accept delta dispersion A`.  
Next ungated: BB shared-φ SO **cell/test only** (already in `_CIFit`; see [`plans/2026-09-15-betabinomial-shared-phi-so.md`](plans/2026-09-15-betabinomial-shared-phi-so.md)). GP-1 ruling / Student-t free ν / Λ raw: still OUT.

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

- **Mac owns true-parity (STARTED 2026-09-15).** #367 MERGED; next ungated is BB shared-φ cell/test (no `confint_family.jl` edits).
- No Totoro / D-139 without `ack Totoro D-139 #323 Track A|B` (or an explicit D-139 ack naming the T4 grid).
- Do not run S4 probe without `S4 probe yes`.
- Do not bump Project.toml or claim full 0.7 / §7 complete.
- Do not cite matched-θ for beta_logit / nb2_log default cells.
- Do not treat arcG/DRAC diagnostics as a coverage certificate or R-owed port.
- No gllvmTMB engine surgery (TMB/likelihood); tools disposition PRs OK.
- Do not edit #357 unless Shinichi pastes otherwise.
- Skipped unrelated opens: #363 env, #314 handover.
