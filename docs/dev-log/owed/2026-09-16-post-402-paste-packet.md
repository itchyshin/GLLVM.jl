# True-parity paste packet (post-#402 paste-gated scaffolds)

<!-- slop-ok: paste-packet field labels (**STATE:** / Tip / Twin) match prior owed packets -->

STATE: **IN PROGRESS**. Do **not** mark the programme or `/goal` complete.

**Rehydrate:** `git fetch origin main && git rev-parse origin/main`  
Tip (2026-09-16): **`62d36ca06`** (pre-**#402** runbook merge; engine #391 @ `c4dba35c4`).

**Twin:** gllvmTMB `origin/main` @ `02b46cfc8`; frozen oracle `b4d5fee64def88bc768dda1f1f77c29b295edd86`; **`Project.toml` stays `0.3.0`**.

**Board:** [`2026-09-14-true-parity-pending-board.md`](../2026-09-14-true-parity-pending-board.md)  
**Supersedes:** [`2026-09-16-post-399-paste-packet.md`](2026-09-16-post-399-paste-packet.md) (adds DRAFT **#402** runbooks for Stage 1 / S4 / Totoro; four paste strings unchanged).

---

## Adversarial scorecard (2026-09-16 @ `62d36ca06` + #402 runbooks / DRAFT #399)

| Named item | Verdict | Evidence |
|------------|---------|----------|
| Ledger gap | **DONE** (inventory) | [`after-task/2026-09-15-true-parity-ledger-gap-inventory.md`](../after-task/2026-09-15-true-parity-ledger-gap-inventory.md) |
| §2 A (delta dispersion) | **PASTE-GATED** | DRAFT **[#399](https://github.com/itchyshin/GLLVM.jl/pull/399)**; paste `accept delta dispersion A` |
| D3 Stage 1 | **PASTE-GATED** (runbook ready) | **[#402](https://github.com/itchyshin/GLLVM.jl/pull/402)** + [`plans/2026-09-16-d3-loading-profile-stage1-paste-gated-scaffold.md`](../plans/2026-09-16-d3-loading-profile-stage1-paste-gated-scaffold.md); paste `G0 Stage 1` |
| S4 public-formula probe | **PASTE-GATED** (runbook ready) | **#402** + [`plans/2026-09-16-s4-probe-julia-checklist-paste-gated.md`](../plans/2026-09-16-s4-probe-julia-checklist-paste-gated.md); paste `S4 probe yes` |
| Totoro #323 Track A | **PASTE-GATED** (runbook ready) | **#402** + [`plans/2026-09-16-totoro-323-track-a-runbook-paste-gated.md`](../plans/2026-09-16-totoro-323-track-a-runbook-paste-gated.md); paste `ack Totoro D-139 #323 Track A` |
| #357 bridge logLik | **DONE** | MERGED on `main` @ `5ee6dc596` (lognormal + truncated-Poisson bridge logLik receipts) |
| #363 / #314 | **SKIP** | CONFLICTING DRAFT |
| Ungated CI | **#401** node24 | **DONE** @ `c33745302` |

**Ungated implementable engine slice:** **none**. DRAFT **#399** (engine). **#402** lands runbooks only (paste still required for execution).

---

## Paste → unlocks → first action (Shinichi only)

| Paste (exact) | DRAFT / runbook | After paste |
|---------------|-----------------|-------------|
| `accept delta dispersion A` | **[#399](https://github.com/itchyshin/GLLVM.jl/pull/399)** | ACCEPTED block + engine closeout + D1 remeasure (see post-#399 packet) |
| `G0 Stage 1` | **[#402](https://github.com/itchyshin/GLLVM.jl/pull/402)** Stage 1 plan | New implementation PR from scaffold; not merge #402 as engine |
| `S4 probe yes` | **#402** S4 checklist | Run isolated Julia probe vs #1283 `97214679c`; no R `src/` edits |
| `ack Totoro D-139 #323 Track A` | **#402** Totoro runbook | Codex Track A on Totoro per launch pack |

---

## Quick refresh

```bash
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
git fetch origin main && git rev-parse origin/main
gh pr view 399 --json isDraft,url
gh pr view 402 --json isDraft,url
gh pr checks 401
```

Expected tip after #402 merge: this packet's merge SHA. Goal **not** complete.
