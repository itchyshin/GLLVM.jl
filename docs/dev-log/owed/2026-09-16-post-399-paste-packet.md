# True-parity paste packet (post-#399 Delta A DRAFT scaffold)

> **Superseded tip:** use [`2026-09-16-post-402-paste-packet.md`](2026-09-16-post-402-paste-packet.md) (DRAFT #402 Stage1/S4/Totoro runbooks).

<!-- slop-ok: paste-packet field labels (**STATE:** / Tip / Twin) match prior owed packets -->

STATE: **IN PROGRESS**. Do **not** mark the programme or `/goal` complete.

**Rehydrate:** `git fetch origin main && git rev-parse origin/main`  
Tip (2026-09-16): **`b1c048f2f`** (`docs: post-#397 paste packet tip @ 8d74f8007 (#398)`; engine #391 @ `c4dba35c4`).

**Twin:** gllvmTMB `origin/main` @ `02b46cfc8`; frozen oracle `b4d5fee64def88bc768dda1f1f77c29b295edd86`; **`Project.toml` stays `0.3.0`**.

**Board:** [`2026-09-14-true-parity-pending-board.md`](../2026-09-14-true-parity-pending-board.md)  
**Supersedes tip SHA in:** [`2026-09-16-post-397-paste-packet.md`](2026-09-16-post-397-paste-packet.md) (four paste strings unchanged; tip was `8d74f8007` / packet tip `b1c048f2f`).

---

## Adversarial scorecard (2026-09-16 @ `b1c048f2f` + DRAFT #399)

| Named item | Verdict | Evidence |
|------------|---------|----------|
| Ledger gap | **DONE** (inventory) | [`after-task/2026-09-15-true-parity-ledger-gap-inventory.md`](../after-task/2026-09-15-true-parity-ledger-gap-inventory.md); ranked next slices are Totoro / Stage 1 / foreign / large surfaces, not a free cloud engine bite |
| §2 A (delta dispersion) | **PASTE-GATED** (DRAFT scaffold) | Decision still **PENDING_ACCEPTANCE**. Pre-paste Option A scaffold is **DRAFT [#399](https://github.com/itchyshin/GLLVM.jl/pull/399)** — do **not** mark ready / do **not** merge / do **not** claim ACCEPTED. Paste `accept delta dispersion A` unlocks the four post-paste steps below. |
| #347 Delta shared-η Wald | **DONE** | MERGED `3091fe613` (2026-09-15); species / per-trait follow-on waits on Delta paste |
| D3 Stage 1 | **PASTE-GATED** | Stage 0 on main (#345); needs `G0 Stage 1` (no pre-paste Stage 1 DRAFT — Stage 1 *is* the G0-gated export) |
| S4 public-formula probe | **PASTE-GATED** | Needs `S4 probe yes` |
| Totoro #323 Track A / T4 | **PASTE-GATED** | Needs `ack Totoro D-139 #323 Track A` (or D-139 ack naming T4) |
| #357 bridge logLik | **FOREIGN** | Leave alone (even if MERGEABLE / CI green) |
| #363 / #314 | **SKIP** | CONFLICTING DRAFT; not true-parity |
| GP-1 / free-ν / Λ raw / joint Tweedie power / BB φ pairing | **OUT + cloud-fenced** | No paste string; do not invent from cloud |

**Ungated implementable engine slice:** **none**. Leftover ours green PRs to merge: **none**. Open ours DRAFT (not ready): **[#399](https://github.com/itchyshin/GLLVM.jl/pull/399)** waits for paste.

---

## Cloud fence (verified)

Ungated cloud engine queue **exhausted** after **#391** and docs tips **#393 through #398**. DRAFT **#399** is a pre-paste Option A scaffold only — cloud / this lane **must not** mark it ready, merge it, or claim Delta A accepted. Also **must not** start Stage 1, S4, Totoro, GP-1, free-ν, Λ raw, `Project.toml` bump, or **#357** edits without the exact Shinichi pastes below.

**Rose fence:** Docs and SO receipts ≠ ACCEPTED Delta A ≠ D1 pass ≠ true-parity destination ≠ §7 complete ≠ bridge CI lift (#357) ≠ Core070 `FREE=0` as parity.

---

## Paste → unlocks → first action (Shinichi only)

Copy **exact** strings into chat. Agents must not start the row without the paste.

| Paste (exact) | What happens after paste |
|---------------|--------------------------|
| `accept delta dispersion A` | Unlocks **DRAFT [#399](https://github.com/itchyshin/GLLVM.jl/pull/399)** post-paste closeout (do **not** treat paste as already-done ACCEPTED). Four remaining steps: (1) append **ACCEPTED (A)** block to [`decisions/2026-09-15-delta-dispersion-alignment-pending.md`](../decisions/2026-09-15-delta-dispersion-alignment-pending.md); (2) flip public fitter / `fit_gllvm` default to **`:species`** + postfit vector-σ/α; (3) remeasure **D1** on SO cells (no rtol widen); (4) mark **ready** + **merge** on green. |
| `G0 Stage 1` | Start D3 `loading_profile` Stage 1 (public surface + fitter pin + ledger rebind after Stage 0 #345). No pre-paste Stage 1 DRAFT — Stage 0 already froze the substrate. |
| `S4 probe yes` | Run S4 public-formula probe vs gllvmTMB #1283 recorder (`97214679c`); **no** R TMB/likelihood edits. |
| `ack Totoro D-139 #323 Track A` | Launch optional Totoro #323 Track A under recorded D-139; T4 realistic-size needs an ack that names that grid. |

Alternatives for Delta (only if **not** choosing A): `accept delta dispersion B` / `C` / `C+B`. See [`decisions/2026-09-15-delta-dispersion-alignment-pending.md`](../decisions/2026-09-15-delta-dispersion-alignment-pending.md). Choosing B/C/C+B means **do not** merge #399 as-is.

---

## Already on `origin/main` (engine + recent tips) + open DRAFT

| Item | PR | SHA / URL | Status |
|------|----|-----------|--------|
| #347 Delta shared-η Wald | [#347](https://github.com/itchyshin/GLLVM.jl/pull/347) | `3091fe613` | **DONE** (shared path); species OUT until paste |
| Tweedie estimated-power SO | [#391](https://github.com/itchyshin/GLLVM.jl/pull/391) | `c4dba35c4` | **PARTIAL** (option A; #384 CLOSED) |
| Paste-queue STOP + tips | #393 through #397 | through `8d74f8007` | Docs |
| Post-#397 paste packet tip | [#398](https://github.com/itchyshin/GLLVM.jl/pull/398) | `b1c048f2f` | Docs; tip SHA (this packet refreshes pastes at that tip) |
| Delta Option A scaffold | [#399](https://github.com/itchyshin/GLLVM.jl/pull/399) | DRAFT | **DRAFT** — waits for paste `accept delta dispersion A`; not ready; not ACCEPTED |

---

## Quick refresh

```bash
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
git fetch origin main && git rev-parse origin/main
gh pr view 399 --json state,isDraft,title,url
gh pr list --state open --limit 15
```

Expected tip: **`b1c048f2f`** until this tip merges; then this tip's merge SHA. #399 stays DRAFT until paste; #357 foreign (leave alone); #363/#314 CONFLICTING DRAFT skip; no further ungated cloud slices until a paste above.
