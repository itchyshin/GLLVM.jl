# True-parity programme — maintainer board (2026-09-14, updated 2026-09-15)

**STATE:** **IN PROGRESS** — #323, matched-θ **(C)**, §2 Hessian **(A)** disposed (Ada defaults). **Ledger gap inventory done**. **arcG Julia-only disposition** ACCEPTED (this PR #358 / gllvmTMB #1284). **Still open:** S4 probe, D3 Stage **1**, **`Project.toml` `0.3.0`**, Delta dispersion paste; open PRs #355/#356/#357/#361; **#359/#360 merged**.

**Rehydrate:** `origin/main` · frozen oracle `b4d5fee64def88bc768dda1f1f77c29b295edd86` · **`Project.toml` stays `0.3.0`**.

---

## Disposed (2026-09-15 — Ada default)

| Item | Outcome | Decision |
|------|---------|----------|
| **[#323](https://github.com/itchyshin/GLLVM.jl/issues/323)** Frozen R smoke | **Waived (B)** — advisory CI stays non-gating | [`2026-09-14-advisory-frozen-r-smoke-323-pending.md`](decisions/2026-09-14-advisory-frozen-r-smoke-323-pending.md) **ACCEPTED** |
| **matched-θ** `beta_logit`, `nb2_log` | **Permanent OUT (C)** — each-own-optimum only | [`2026-09-14-matched-theta-beta-nb2-pending.md`](decisions/2026-09-14-matched-theta-beta-nb2-pending.md) **ACCEPTED** |
| **§2 Hessian** Binomial/cloglog + Tweedie grouped | **Ratify `:observed` (A)** — receipts + defaults signed | [`2026-09-15-second-order-hessian-s2-pending.md`](decisions/2026-09-15-second-order-hessian-s2-pending.md) **ACCEPTED** |
| **Julia-only arcG / DRAC** (parity_ledger CLOSURE) | **ACCOUNTED** — Julia-beyond diagnostics; not owed to R | [`2026-09-15-julia-only-arcg-disposition.md`](decisions/2026-09-15-julia-only-arcg-disposition.md) **ACCEPTED** |

**Reverse:** Shinichi may paste `reopen #323`, `reject matched-θ C`, **`reject §2 hessian A`**, or **`reject arcG disposition`** in chat; agents must revert on explicit reverse only.

---

## Still open — paste-ready replies

### S4 public-formula probe (**held**)

Recorder on origin: [gllvmTMB PR #1283](https://github.com/itchyshin/gllvmTMB/pull/1283) (`97214679c`). Second explicit yes only (`LOOP/GOAL.md` QS4).

```
S4 probe yes
```

### D3 `loading_profile` (T5 row 8)

**Scout:** [PR #341](https://github.com/itchyshin/GLLVM.jl/pull/341) · **Stage 0 merged** [PR #345](https://github.com/itchyshin/GLLVM.jl/pull/345).  
**Stage 1:** paste **`G0 Stage 1`** only.

### Ledger / capability gaps (item 3)

**Inventory:** [`2026-09-15-true-parity-ledger-gap-inventory.md`](after-task/2026-09-15-true-parity-ledger-gap-inventory.md). **Rank 7 done** (arcG disposition). In flight: [#356](https://github.com/itchyshin/GLLVM.jl/pull/356) Tweedie SO, [#357](https://github.com/itchyshin/GLLVM.jl/pull/357) bridge receipts, [#355](https://github.com/itchyshin/GLLVM.jl/pull/355) aliases (watch Julia shard fails).

### Second-order Delta follow-up

**Receipt:** [`2026-09-15-second-order-delta-followup.md`](after-task/2026-09-15-second-order-delta-followup.md).  
**PENDING:** paste `accept delta dispersion A`.

### Version

**`Project.toml` remains `0.3.0`** (D-183).

### Optional — re-run #323 on Totoro

```
ack Totoro D-139 #323 Track A
```

---

## Agent rules

- **No Totoro / D-139** without `ack Totoro D-139 #323 Track A|B`.
- **Do not** run S4 probe without **`S4 probe yes`**.
- **Do not** bump `Project.toml` or claim full 0.7 / §7 complete.
- **Do not** cite matched-θ for `beta_logit` / `nb2_log` default cells.
- **Do not** treat arcG/DRAC diagnostics as a coverage certificate or R-owed port.
- **No gllvmTMB engine surgery** (TMB/likelihood); tools disposition PRs OK.
