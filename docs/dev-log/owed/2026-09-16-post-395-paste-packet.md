# True-parity paste packet (post-#395)

**STATE:** **IN PROGRESS**. Do **not** mark the programme or `/goal` complete.

**Rehydrate:** `git fetch origin main && git rev-parse origin/main`  
**Tip (2026-09-16):** **`d2353b013`** — `docs: post-#395 paste packet + tip @ e7f869932 (#396)` (engine #391 @ `c4dba35c4`; #395 CI receipt @ `e7f869932`)

**Twin:** gllvmTMB `origin/main` @ `02b46cfc`; frozen oracle `b4d5fee64def88bc768dda1f1f77c29b295edd86`; **`Project.toml` stays `0.3.0`**.

**Board:** [`2026-09-14-true-parity-pending-board.md`](../2026-09-14-true-parity-pending-board.md)

---

## Cloud fence (verified)

Ungated cloud engine queue **exhausted** after **#391** (Tweedie estimated-power SO) and docs tips **#393–#396**. Cloud / this lane **must not** start Stage 1, S4, Totoro, Delta implementation, GP-1, free-ν, Λ raw, `Project.toml` bump, or **#357** edits without the exact Shinichi pastes below.

**Rose fence:** Docs and SO receipts ≠ true-parity destination ≠ §7 complete ≠ bridge CI lift (#357) ≠ Core070 `FREE=0` as parity.

---

## Already on `origin/main` (this tranche)

| Item | PR / merge | SHA (squash or tip) | Status |
|------|------------|---------------------|--------|
| BetaBinomial shared-φ SO cell | [#374](https://github.com/itchyshin/GLLVM.jl/pull/374) | `eeb7e092` | **PARTIAL** (native Wald; β block only; φ unpaired in live Δ) |
| Six holdout paired SO cells | [#376](https://github.com/itchyshin/GLLVM.jl/pull/376) | `47fcb23e` | **PARTIAL** (β / `b_fixed` blocks; six families) |
| FORWARD / TWIN_ALIAS ledger hygiene | [#387](https://github.com/itchyshin/GLLVM.jl/pull/387) | `8321d5ce6` | Docs/tooling; three deferred alias rows documented |
| Ungated-queue verify + board tips | [#389](https://github.com/itchyshin/GLLVM.jl/pull/389) / [#390](https://github.com/itchyshin/GLLVM.jl/pull/390) | `7619fd5e9` / `b68aa3da9` | Docs only |
| Paste-queue STOP + board @ #391 | [#393](https://github.com/itchyshin/GLLVM.jl/pull/393) / [#394](https://github.com/itchyshin/GLLVM.jl/pull/394) | `df852f6b2` / `947656d12` | Cloud STOP recorded |
| Tweedie estimated-power SO (shared + species) | [#391](https://github.com/itchyshin/GLLVM.jl/pull/391) | `c4dba35c4` | **PARTIAL** (option A; β/`b_fixed`; `eoo_claimed=false`; Rose winner over **#384** **CLOSED**) |
| #391 CI receipt + after-task | [#395](https://github.com/itchyshin/GLLVM.jl/pull/395) | `e7f869932` | Docs only |
| Post-#395 paste packet tip | [#396](https://github.com/itchyshin/GLLVM.jl/pull/396) | `d2353b013` | Docs only; tip SHA |

Receipts: [`after-task/2026-09-16-tweedie-estimated-power-so.md`](../after-task/2026-09-16-tweedie-estimated-power-so.md), [`after-task/2026-09-16-six-holdout-so-cells.md`](../after-task/2026-09-16-six-holdout-so-cells.md), [`after-task/2026-09-16-paste-queue-stop.md`](../after-task/2026-09-16-paste-queue-stop.md).

---

## Paste → unlocks → first action (Shinichi only)

Copy **exact** strings into chat. Agents must not start the row without the paste.

| Paste (exact) | Unlocks | First file / PR action |
|---------------|---------|-------------------------|
| `accept delta dispersion A` | Delta per-trait (`:species`) dispersion default + SO path toward honest D1 remeasure | Mark **ACCEPTED** in [`decisions/2026-09-15-delta-dispersion-alignment-pending.md`](../decisions/2026-09-15-delta-dispersion-alignment-pending.md); then bounded engine slice: `src/confint_family.jl` + `tools/core070_second_order/` Delta cells (see [`after-task/2026-09-15-second-order-delta-followup.md`](../after-task/2026-09-15-second-order-delta-followup.md)) |
| `G0 Stage 1` | D3 **`loading_profile`** Stage 1 (public surface after Stage 0 #345) | Continue from scout [#341](https://github.com/itchyshin/GLLVM.jl/pull/341): `src/` fitter pin + public API + ledger rebind; plan in maintainer decision set |
| `S4 probe yes` | Second explicit yes for S4 public-formula probe (`LOOP/GOAL.md` QS4) | Probe driver vs gllvmTMB [#1283](https://github.com/itchyshin/gllvmTMB/pull/1283) recorder (`97214679c`); **no** R TMB/likelihood edits |
| `ack Totoro D-139 #323 Track A` | Optional advisory Frozen R #323 Track A under D-139 | Launch documented Totoro batch only after ack; T4 realistic-size second-order needs a separate D-139 ack naming that grid |

Alternatives for Delta (only if **not** choosing A): `accept delta dispersion B` / `C` / `C+B` — see the pending decision doc.

---

## Foreign: [#357](https://github.com/itchyshin/GLLVM.jl/pull/357)

**Status:** **OPEN** foreign. **Do not edit** from the true-parity cloud/Mac paste lane (even if MERGEABLE / CI green).

**Owning lane must:** rebase `feat/lognormal-truncpois-loglik-receipts-20260915` onto current `origin/main` (`d2353b013`), keep `docs/dev-log/check-log.md` append-only clean, re-push, and re-run CI. Bridge work stays in `src/bridge.jl` + tests.

---

## Skipped (unrelated)

Open DRAFT: **#363** (cloud agent env), **#314** (handover). Not true-parity scope.

---

## Quick refresh

```bash
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
git fetch origin main && git rev-parse origin/main
gh pr list --state open --limit 15
```

Expected tip: **`d2353b013`**; #357 foreign (leave alone); #363/#314 CONFLICTING DRAFT skip; no further ungated cloud slices until a paste above.
