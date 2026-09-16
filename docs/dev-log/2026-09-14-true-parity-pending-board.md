# True-parity programme: maintainer board (2026-09-14, updated 2026-09-16)

STATE: **IN PROGRESS**. **Mac Studio owns programme (STARTED 2026-09-15).** #323, matched-θ **(C)**, §2 Hessian **(A)** disposed (Ada defaults). Ledger gap inventory done. arcG Julia-only disposition ACCEPTED (#358 + gllvmTMB #1284). Still open: S4 probe, D3 Stage 1, `Project.toml` `0.3.0`, Delta dispersion paste.

CLOUD STOP (2026-09-16): Ungated cloud queue **exhausted** after **#391** + docs through **#403**. Tip @ **`a86817209`**. DRAFTs **[#399](https://github.com/itchyshin/GLLVM.jl/pull/399)** (Delta A engine) and **[#402](https://github.com/itchyshin/GLLVM.jl/pull/402)** (Stage1/S4/Totoro runbooks) are pre-paste scaffolds only; do **not** mark ready / merge / claim ACCEPTED. Ungated CI: **[#401](https://github.com/itchyshin/GLLVM.jl/pull/401)** node24 (merge when green). Cloud does **not** start Stage 1 / S4 / Totoro execution, GP-1, free-ν, Λ raw, or `Project.toml` bump. Open: **#357** foreign leave alone; **#363/#314** CONFLICTING DRAFT skip. Next requires Shinichi pastes only. Goal **not** complete.

Merged SO tranche: #374/#376/#378 + **#391** Tweedie estimated-power SO (shared+species; Rose winner over #384) @ **`c4dba35c4`**. Docs through #398. **#384** **CLOSED** superseded. **Canonical paste table:** [`owed/2026-09-16-post-399-paste-packet.md`](owed/2026-09-16-post-399-paste-packet.md).

Rehydrate: GLLVM.jl `origin/main` @ **`a86817209`** (#403 tip; engine #391 @ `c4dba35c4`); gllvmTMB `origin/main` @ `02b46cfc8`; frozen oracle `b4d5fee64def88bc768dda1f1f77c29b295edd86`; **`Project.toml` stays `0.3.0`**. Noon wake: [`handover/2026-09-16-noon-true-parity-wake-briefing.md`](handover/2026-09-16-noon-true-parity-wake-briefing.md).

---

## Named-item scorecard (adversarial, tip `b1c048f2f` + DRAFT #399)

| Item | Verdict |
|------|---------|
| Ledger gap | **DONE** (inventory); remaining ranks are paste / Totoro / foreign / large surface |
| §2 A (delta dispersion) | **PASTE-GATED** — DRAFT [#399](https://github.com/itchyshin/GLLVM.jl/pull/399) scaffold; paste `accept delta dispersion A` |
| #347 | **DONE** (shared-η Wald MERGED); species follow-on paste-gated |
| D3 Stage 1 / S4 / Totoro | **PASTE-GATED** |
| #357 | **FOREIGN** (leave alone) |
| #363 / #314 | **SKIP** (CONFLICTING DRAFT) |

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

## Still open: paste-ready replies (Shinichi only)

Cloud ungated work is done. **Do not** start these without the exact paste in chat.

### S4 public-formula probe (held)

Recorder on origin: [gllvmTMB PR #1283](https://github.com/itchyshin/gllvmTMB/pull/1283) (`97214679c`). Second explicit yes only (`LOOP/GOAL.md` QS4).

```
S4 probe yes
```

### D3 loading_profile (T5 row 8)

Scout: [PR #341](https://github.com/itchyshin/GLLVM.jl/pull/341). Stage 0 merged [PR #345](https://github.com/itchyshin/GLLVM.jl/pull/345).  
Stage 1: paste `G0 Stage 1` only.

### Ledger / capability gaps (item 3)

Inventory: [`2026-09-15-true-parity-ledger-gap-inventory.md`](after-task/2026-09-15-true-parity-ledger-gap-inventory.md). Rank 7 done (arcG; #358/#1284). Aliases landed (#355). Foreign: [#357](https://github.com/itchyshin/GLLVM.jl/pull/357) bridge logLik receipts; do not edit from this lane.

### Second-order follow-up

Receipts: Delta shared-η [#347](after-task/2026-09-15-second-order-delta-followup.md) **MERGED**; OrdinalPerTrait / TweedieGrouped / Lognormal+Trunc* on main (#362/#356/#361); **MultinomialFit** native Wald on main (#366); **Student-t fixed-ν** native Wald on main (#367); **BetaBinomial shared-φ** SO cell on main ([#374](after-task/2026-09-15-betabinomial-shared-phi-so.md), `eeb7e092`); **six holdout paired SO cells** on main ([#376](after-task/2026-09-16-six-holdout-so-cells.md), `47fcb23e`) → **PARTIAL (native Wald + toy Δ)**; **Tweedie shared-power SO cell** on main ([#378](after-task/2026-09-16-tweedie-shared-power-so.md), `67247f52`) → **PARTIAL (option A)**; **Tweedie estimated-power SO (shared+species)** on main ([#391](https://github.com/itchyshin/GLLVM.jl/pull/391), `c4dba35c4`) → **PARTIAL (option A; Rose winner over #384)**. Bridge CI lift still waits on #357.  
Delta SO species dispersion: DRAFT [#399](https://github.com/itchyshin/GLLVM.jl/pull/399) scaffold only; still OUT / not ACCEPTED until paste `accept delta dispersion A` (then ACCEPTED block → public `:species` default → D1 remeasure → ready+merge).  
Still OUT / open: GP-1 ruling / Student-t free ν / Λ raw / Tweedie **jointly-optimised** power / BB φ pairing / Delta species dispersion paste.

### Version

Project.toml remains 0.3.0 (D-183).

### Optional: re-run #323 on Totoro

```
ack Totoro D-139 #323 Track A
```

### T4 realistic-size second-order

Blocked on D-139 ack before Totoro spend (no separate paste string beyond an explicit D-139 ack in chat).

---

## Exact Shinichi pastes required (cloud STOP)

| Paste (exact) | Unlocks (one line) |
|---------------|--------------------|
| `accept delta dispersion A` | Unlock DRAFT [#399](https://github.com/itchyshin/GLLVM.jl/pull/399): ACCEPTED block → public `:species` → D1 remeasure → ready+merge |
| `G0 Stage 1` | D3 `loading_profile` Stage 1 after Stage 0 #345 |
| `S4 probe yes` | S4 public-formula probe vs gllvmTMB #1283 (no R engine edits) |
| `ack Totoro D-139 #323 Track A` | Optional Totoro #323 Track A under D-139 |

Canonical packet: [`owed/2026-09-16-post-399-paste-packet.md`](owed/2026-09-16-post-399-paste-packet.md).

---

## Agent rules

- Mac owns true-parity (STARTED 2026-09-15). Tip @ **`b1c048f2f`** (#398). DRAFT **#399** waits for paste (not ready / not ACCEPTED). Cloud ungated **exhausted**; Shinichi pastes only for next work. **#384** **CLOSED** superseded.
- No Totoro / D-139 without `ack Totoro D-139 #323 Track A|B` (or an explicit D-139 ack naming the T4 grid).
- Do not run S4 probe without `S4 probe yes`.
- Do not bump Project.toml or claim full 0.7 / §7 complete.
- Do not cite matched-θ for beta_logit / nb2_log default cells.
- Do not treat arcG/DRAC diagnostics as a coverage certificate or R-owed port.
- No gllvmTMB engine surgery (TMB/likelihood); tools disposition PRs OK.
- Do not edit #357 unless Shinichi pastes otherwise.
- Skipped unrelated opens: #363 env, #314 handover. Cloud fence: no GP-1 / free-ν / Λ raw / Delta paste / Stage1 / S4 / Totoro / Project.toml from cloud.
