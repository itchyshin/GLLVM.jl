# Overnight true-parity handover (2026-09-15 → 2026-09-16)

**Lane:** Ada (Cursor), overnight conductor, ~17:00 MDT-ongoing window.
**Rehydrate (wake tip):** `origin/main` @ **`b68aa3da9`** (#390). Historical body below still
names earlier tips (`9d021de63`, etc.) where that was accurate at write time. `Project.toml`
stays `0.3.0`. Goal **NOT** complete. `#357` (foreign bridge PR) untouched throughout; do not edit
it without Shinichi's explicit say.

## Rose recheck WARN (2026-09-15 ~22:00 MDT) - supersedes stale DRAFT / local-EOO lines

- **#384** is Ready + MERGEABLE (no longer DRAFT / CONFLICTING). Still **HOLD**.
- **#391** is a second Ready + MERGEABLE Tweedie estimated-power (EOO) PR. Still **HOLD**.
- Policy from **#385 / #388**: that work was to stay local pending explicit maintainer push
  authorization. Both open EOO PRs wait on Shinichi authorizing **one** and closing the other.
  **Do not merge #384 or #391** from this lane.
- Board / checkpoint claims of "#384 DRAFT" or "EOO local/unpushed" are **STALE** (corrected in
  the morning wake tip). Morning wake:
  [`2026-09-16-morning-wake-briefing.md`](2026-09-16-morning-wake-briefing.md).
- Paste gates unchanged. Goal incomplete.

**Update (post-initial-handover, same lane):** #378 (Tweedie shared-power SO cell) merged; the
morning briefing was refreshed directly (no evidence the named refresh agent had run); a small
board/checkpoint tip (#383) corrected the two docs #378's own diff didn't touch. Later tips
#385-#390 landed. Remaining ungated engine work is the dual EOO HOLD above; everything else is
paste-gated or foreign (#357). See DONE / IN PROGRESS / OWED below.

## DONE this overnight tranche

Merged to `main`, in order:

- **#367** Student-t fixed-ν native Wald `_CIFit` (`9d300783c`) → PARTIAL (native Wald only).
- **#372** SO toy receipts inventory for PARTIAL native-Wald holdouts (`104c43d37`).
- **#373** post-#367 true-parity tip: board / holdouts / AGENTS refresh (`83990686d`).
- **#374** BetaBinomial shared-φ SO cell + tests (`eeb7e0926`) → PARTIAL (native Wald; φ block
  unpaired in live Δ).
- **#375** morning paste briefing draft for 2026-09-16 (`ab8891e06`).
- **#376** six holdout paired SO cells (`47fcb23ee`): lognormal, ordinal-pertrait-probit,
  truncated-Poisson, truncated-NB2, multinomial-FE, Student-t-fixed-ν - each → PARTIAL (native
  Wald + paired SO cell, β/`b_fix` block only). Live Δ `se_max_relative_delta`: lognormal 8.3e-6,
  ordinal-probit 9.5e-6, trunc-Poisson 8.9e-6, trunc-NB2 **9.8e-2** (documented parameterisation
  mismatch - Julia shared `r` vs R per-trait dispersion, not promoted to D1), multinomial-FE
  5.4e-6, Student-t-fixed-ν 3.0e-6.
- **#377** post-#374 true-parity tip (board/checkpoint/merge-receipt) - landed with stale content
  (written before #376 merged; still said #376 CONFLICTING) (`e47430735`).
- **#379** board/checkpoint/check-log refresh correcting #377's stale #376 status to MERGED, and
  recording the in-progress Tweedie EOO lane (`bf83d5f75`). Docs-only; Documenter-only CI (no
  Julia matrix triggered on this docs-only diff).

**Closed without merging:**

- **#380** - a second, independently-opened docs-tip PR duplicating #379's exact slice; went
  CONFLICTING the moment #379 landed. Closed with a comment pointing to #379 as the landed
  equivalent, to avoid two competing docs-tip PRs re-fighting the same content.

**Multi-agent note:** this was a genuinely concurrent night - #374 and #376 were each merged by
another lane (likely Grace) the instant their CI went green, faster than this lane's own poll-then-
merge loop could act; #379/#380 were two independently-opened duplicates of the same board-tip
slice from two different lanes. No conflicts landed on `main`; the redundant PR (#380) was closed
rather than merged.

**Continued after the above, same lane:**

- **#382** - morning-paste-briefing refresh (`2a97043a9`). The named refresh agent (`7a3f8015`)
  showed no activity on its scratch copy since 16:47 MDT, so this lane refreshed
  `docs/dev-log/owed/2026-09-16-morning-paste-briefing.md` directly rather than leave it stale;
  docs-only, Documenter-only CI.
- **#378** - Tweedie shared-power SO cell (option A; `b_fix`/β block only, power plug-in), merged
  at `67247f520`. All 8 Julia shards passed (slowest shard 1h7m27s); advisory Frozen R smoke
  failed as expected (accepted per standing rule); Grace babysat the merge. Own after-task file:
  `docs/dev-log/after-task/2026-09-16-tweedie-shared-power-so.md`.
- **#383** - post-#378 board/checkpoint tip (`9d021de63`). #378's own diff already covered
  `check-log.md` and the holdouts doc; this tip corrected only the two files it hadn't touched
  (`docs/dev-log/2026-09-14-true-parity-pending-board.md`, `LOOP/checkpoint.md`), which still
  described Tweedie as local-only/unpushed. Docs-only; Documenter-only CI.

As of `9d021de63`, this lane's ungated queue is effectively exhausted - see IN PROGRESS and OWED
below for what's left.

## IN PROGRESS (not yet merged): Rose WARN supersedes the DRAFT/CONFLICTING narrative below

**Current (wake tip):** two Ready+MERGEABLE EOO PRs, both **HOLD** under #385/#388 push-auth:

- **#384** `feat(second-order): Tweedie species estimated-power Wald CI`
  (`cursor/tweedie-species-power-so-a0ce`). Ready + MERGEABLE. **HOLD**. Do not merge.
- **#391** `feat(second-order): Tweedie estimated-power SO cells (PARTIAL)`
  (`feat/tweedie-estimated-power-so-20260915`). Ready + MERGEABLE. **HOLD**. Do not merge.

Shinichi must authorize **one** and close the other (or close both). Neither is merged as of
`b68aa3da9` + this wake tip.

**Historical triage (kept for the overnight race story; mechanics are obsolete):** #384 opened
~02:15 MDT as DRAFT/CONFLICTING while #385 (~02:18 MDT, merged) recorded the same Tweedie
estimated-power work as deliberately local/unpushed. #388 flagged the push-authorization conflict.
Those mechanical blockers (DRAFT, CONFLICTING, no CI) no longer describe tip state; the **policy
HOLD** still does.

## OWED

Two kinds of "not done": four paste-gated items, one foreign PR, and the dual EOO policy HOLD
(#384/#391).

**Paste-gated - do not start without the matching string, and do not bump `Project.toml`:**

```text
accept delta dispersion A
```
Unlocks Delta-lognormal / Delta-Gamma per-trait dispersion path (Julia shared vs R per-trait
dispersion mismatch; PR #347 measured FAIL).

```text
G0 Stage 1
```
Unlocks D3 `loading_profile` Stage 1 (Stage 0 already merged in #345).

```text
S4 probe yes
```
Second explicit yes for the S4 public-formula probe against gllvmTMB PR #1283's recorder. Does
not authorise R engine edits.

```text
ack Totoro D-139 #323 Track A
```
Authorises the optional Totoro run for the advisory Frozen R #323 smoke under the recorded D-139
estimate. For T4 realistic-size second-order work specifically, use an explicit D-139 ack naming
the T4 grid before spending Totoro time.

**Foreign - do not edit:**

- **#357** (`feat/lognormal-truncpois-loglik-receipts-20260915`) - foreign bridge PR wiring
  lognormal + truncated-Poisson logLik receipts. CONFLICTING against this lane's docs edits on
  `check-log.md` only. **Left untouched all night**, per standing instruction. Do not edit without
  Shinichi's explicit say.

**Policy HOLD (not paste-gated, but not free to merge):**

- **#384** and **#391** (see IN PROGRESS / Rose WARN) - Ready+MERGEABLE, still **HOLD** until
  Shinichi authorizes one EOO PR and closes the other (#385/#388).

## Morning briefing refresh - DONE (wake tip; Rose WARN)

- Wake path: `docs/dev-log/handover/2026-09-16-morning-wake-briefing.md` (this tip).
- Paste twin: `docs/dev-log/owed/2026-09-16-morning-paste-briefing.md` (refreshed to tip
  `b68aa3da9` + Rose WARN; earlier #375/#382 drafts superseded).
- Named refresh agent `7a3f8015` stalled; Ada delivered the wake briefing directly.
- Paste-string content unchanged (Delta dispersion A / G0 Stage 1 / S4 probe yes / Totoro D-139).

## Checks run this tranche

- `git fetch origin`; `git rev-parse origin/main` (repeated, before every merge decision).
- `gh pr list --state open`; `gh pr view <n> --json mergeable,mergeStateStatus,files,body,state`
  (repeated, to detect duplicate/stale docs-tip PRs before acting).
- `gh api repos/itchyshin/GLLVM.jl/actions/runs/<id>/jobs` polling loops (2-3 min cadence) for
  #376 and #378's CI, merging on green once Documenter + all 8 Julia shards passed (Frozen R
  advisory failure accepted per standing rule).
- `gh pr ready 379` (was opened as Draft) before `gh pr merge 379 --squash --delete-branch`.
- `gh pr close 380 --comment ...` after confirming its diff duplicated #379's already-merged
  content.

## Rose fence

This handover records merge/close bookkeeping and CI-monitoring receipts only. It is **not** a
ledger promotion, **not** a §7 programme-parity claim, and does not clear any of the paste gates
above. The six #376 cells and the #374/#378 shared-dispersion cells remain **β/`b_fix`-block-only**
live Δ pairings - dispersion parameters (σ, r, φ, power) are documented as unpaired or
parameterisation-mismatched, not silently promoted. The #384/#391 HOLD above is a push-authorization policy fence (#385/#388), not a review of
statistical content. Goal **not** complete.
