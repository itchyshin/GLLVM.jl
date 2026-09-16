# True-parity paste packet (post-#397 adversarial rehydrate)

> **Superseded tip:** use [`2026-09-16-post-399-paste-packet.md`](2026-09-16-post-399-paste-packet.md) (DRAFT #399 + four post-paste steps). Tip SHA below is historical.

<!-- slop-ok: paste-packet field labels (**STATE:** / Tip / Twin) match prior owed packets -->

STATE: **IN PROGRESS**. Do **not** mark the programme or `/goal` complete.

**Rehydrate:** `git fetch origin main && git rev-parse origin/main`  
Tip (2026-09-16): **`8d74f8007`** (`docs: post-#396 paste-only STOP tip @ d2353b013 (#397)`; engine #391 @ `c4dba35c4`).

**Twin:** gllvmTMB `origin/main` @ `02b46cfc8`; frozen oracle `b4d5fee64def88bc768dda1f1f77c29b295edd86`; **`Project.toml` stays `0.3.0`**.

**Board:** [`2026-09-14-true-parity-pending-board.md`](../2026-09-14-true-parity-pending-board.md)  
**Supersedes tip SHA in:** [`2026-09-16-post-395-paste-packet.md`](2026-09-16-post-395-paste-packet.md) (content of the four pastes unchanged; tip was `d2353b013`).

---

## Adversarial scorecard (2026-09-16 @ `8d74f8007`)

| Named item | Verdict | Evidence |
|------------|---------|----------|
| Ledger gap | **DONE** (inventory) | [`after-task/2026-09-15-true-parity-ledger-gap-inventory.md`](../after-task/2026-09-15-true-parity-ledger-gap-inventory.md); ranked next slices are Totoro / Stage 1 / foreign / large surfaces, not a free cloud engine bite |
| §2 A (delta dispersion) | **PASTE-GATED** | Decision still **PENDING_ACCEPTANCE**; paste `accept delta dispersion A` |
| #347 Delta shared-η Wald | **DONE** | MERGED `3091fe613` (2026-09-15); species / per-trait follow-on waits on Delta paste |
| D3 Stage 1 | **PASTE-GATED** | Stage 0 on main (#345); needs `G0 Stage 1` |
| S4 public-formula probe | **PASTE-GATED** | Needs `S4 probe yes` |
| Totoro #323 Track A / T4 | **PASTE-GATED** | Needs `ack Totoro D-139 #323 Track A` (or D-139 ack naming T4) |
| #357 bridge logLik | **FOREIGN** | Leave alone (even if MERGEABLE / CI green) |
| #363 / #314 | **SKIP** | CONFLICTING DRAFT; not true-parity |
| GP-1 / free-ν / Λ raw / joint Tweedie power / BB φ pairing | **OUT + cloud-fenced** | No paste string; do not invent from cloud |

**Ungated implementable engine slice:** **none** (re-checked after #397). Leftover ours green PRs to merge: **none**.

---

## Cloud fence (verified)

Ungated cloud engine queue **exhausted** after **#391** and docs tips **#393 through #397**. Cloud / this lane **must not** start Stage 1, S4, Totoro, Delta implementation, GP-1, free-ν, Λ raw, `Project.toml` bump, or **#357** edits without the exact Shinichi pastes below.

**Rose fence:** Docs and SO receipts ≠ true-parity destination ≠ §7 complete ≠ bridge CI lift (#357) ≠ Core070 `FREE=0` as parity.

---

## Paste → unlocks → first action (Shinichi only)

Copy **exact** strings into chat. Agents must not start the row without the paste.

| Paste (exact) | What happens after paste |
|---------------|--------------------------|
| `accept delta dispersion A` | Mark Delta decision **ACCEPTED (A)**; then bounded engine slice: `_family_ci` `:species` + default twin cells `disp_group=:species` + remeasure D1 (no rtol widen). |
| `G0 Stage 1` | Start D3 `loading_profile` Stage 1 (public surface + fitter pin + ledger rebind after Stage 0 #345). |
| `S4 probe yes` | Run S4 public-formula probe vs gllvmTMB #1283 recorder (`97214679c`); **no** R TMB/likelihood edits. |
| `ack Totoro D-139 #323 Track A` | Launch optional Totoro #323 Track A under recorded D-139; T4 realistic-size needs an ack that names that grid. |

Alternatives for Delta (only if **not** choosing A): `accept delta dispersion B` / `C` / `C+B`. See [`decisions/2026-09-15-delta-dispersion-alignment-pending.md`](../decisions/2026-09-15-delta-dispersion-alignment-pending.md).

---

## Already on `origin/main` (engine + recent tips)

| Item | PR | SHA | Status |
|------|----|-----|--------|
| #347 Delta shared-η Wald | [#347](https://github.com/itchyshin/GLLVM.jl/pull/347) | `3091fe613` | **DONE** (shared path); species OUT until paste |
| Tweedie estimated-power SO | [#391](https://github.com/itchyshin/GLLVM.jl/pull/391) | `c4dba35c4` | **PARTIAL** (option A; #384 CLOSED) |
| Paste-queue STOP + tips | #393 through #396 | through `d2353b013` | Docs |
| Post-#396 STOP tip | [#397](https://github.com/itchyshin/GLLVM.jl/pull/397) | `8d74f8007` | Docs; tip SHA (this packet refreshes pastes at that tip) |

---

## Quick refresh

```bash
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
git fetch origin main && git rev-parse origin/main
gh pr list --state open --limit 15
```

Expected tip: **`8d74f8007`**; #357 foreign (leave alone); #363/#314 CONFLICTING DRAFT skip; no further ungated cloud slices until a paste above.
