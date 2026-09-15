# True-parity programme — maintainer board (2026-09-14, updated 2026-09-15)

**STATE:** **IN PROGRESS** — #323 and matched-θ **disposed** via **AGENT-APPLIED Ada defaults** (reversible until Shinichi reverses). **Ledger gap inventory done** (item 3 — [`2026-09-15-true-parity-ledger-gap-inventory.md`](after-task/2026-09-15-true-parity-ledger-gap-inventory.md); **≠** closing gaps). **Still open:** S4 probe, D3 Stage **1** only (Stage **0** on main #345), **`Project.toml` `0.3.0`**.

**Rehydrate:** `origin/main` · frozen oracle `b4d5fee64def88bc768dda1f1f77c29b295edd86` · **`Project.toml` stays `0.3.0`**.

---

## Disposed (2026-09-15 — Ada default)

| Item | Outcome | Decision |
|------|---------|----------|
| **[#323](https://github.com/itchyshin/GLLVM.jl/issues/323)** Frozen R smoke | **Waived (B)** — advisory CI stays non-gating | [`2026-09-14-advisory-frozen-r-smoke-323-pending.md`](decisions/2026-09-14-advisory-frozen-r-smoke-323-pending.md) **ACCEPTED** |
| **matched-θ** `beta_logit`, `nb2_log` | **Permanent OUT (C)** — each-own-optimum only | [`2026-09-14-matched-theta-beta-nb2-pending.md`](decisions/2026-09-14-matched-theta-beta-nb2-pending.md) **ACCEPTED** |

**Reverse:** Shinichi may paste `reopen #323` or `reject matched-θ C` (or choose A/B) in chat; agents must revert decision records and board on explicit reverse only.

---

## Still open — paste-ready replies

### S4 public-formula probe (**held**)

Recorder on origin: [gllvmTMB PR #1283](https://github.com/itchyshin/gllvmTMB/pull/1283) (`97214679c`). Second explicit yes only (`LOOP/GOAL.md` QS4).

```
S4 probe yes
```

### D3 `loading_profile` (T5 row 8)

**Scout:** [PR #341](https://github.com/itchyshin/GLLVM.jl/pull/341) · **Stage 0 merged** [PR #345](https://github.com/itchyshin/GLLVM.jl/pull/345) @ `2fd0cec8` — [`2026-09-15-loading-profile-d3-stage0.md`](after-task/2026-09-15-loading-profile-d3-stage0.md).  
**Stage 1 (maintainer G0 only):** paste **`G0 Stage 1`** — public export, fitter pins, ledger; **no auto-build**.

### Ledger / capability gaps (item 3)

**Inventory:** [`2026-09-15-true-parity-ledger-gap-inventory.md`](after-task/2026-09-15-true-parity-ledger-gap-inventory.md) — `FREE=0` spreadsheet vs **122** needs-surface / **47** partial-pending / capability **planned|missing** rows; ranked next slices (excludes Stage 1 / S4).

### Version

**`Project.toml` remains `0.3.0`** (D-183). No bump until joint G11 / true-parity version proposal is accepted.

### Optional — re-run #323 on Totoro (supersedes waive only if maintainer reopens)

Launch pack: [`docs/dev-log/after-task/2026-09-14-issue-323-totoro-launch-pack.md`](after-task/2026-09-14-issue-323-totoro-launch-pack.md)

```
ack Totoro D-139 #323 Track A
```

---

## Agent rules (post–Ada-default slice)

- **No Totoro / D-139** without `ack Totoro D-139 #323 Track A|B` (waive does not forbid future run; it closes programme gate without spend today).
- **Do not** run S4 probe without **`S4 probe yes`**.
- **Do not** bump `Project.toml` or claim full 0.7 parity / programme §7 complete.
- **Do not** cite matched-θ pass/fail for `beta_logit` / `nb2_log` default cells (each-own-optimum only).
