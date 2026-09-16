# Overnight true-parity handover (2026-09-15 → 2026-09-16)

**Lane:** Ada (Cursor), overnight conductor, ~17:00 MDT–ongoing window.
**Rehydrate:** `origin/main` @ `9d021de63` (#383, on top of #382/#378/#379/#376/#374). `Project.toml`
stays `0.3.0`. Goal **NOT** complete. `#357` (foreign bridge PR) untouched throughout — do not edit
it without Shinichi's explicit say.

**Update (post-initial-handover, same lane):** #378 (Tweedie shared-power SO cell) merged; the
morning briefing was refreshed directly (no evidence the named refresh agent had run); a small
board/checkpoint tip (#383) corrected the two docs #378's own diff didn't touch. The ungated queue
this lane can act on is now effectively **exhausted** — everything remaining past a
draft/conflicting sibling PR (#384, see below) is paste-gated or foreign (#357). See DONE / IN
PROGRESS / OWED below for the current, corrected state.

## DONE this overnight tranche

Merged to `main`, in order:

- **#367** Student-t fixed-ν native Wald `_CIFit` (`9d300783c`) → PARTIAL (native Wald only).
- **#372** SO toy receipts inventory for PARTIAL native-Wald holdouts (`104c43d37`).
- **#373** post-#367 true-parity tip: board / holdouts / AGENTS refresh (`83990686d`).
- **#374** BetaBinomial shared-φ SO cell + tests (`eeb7e0926`) → PARTIAL (native Wald; φ block
  unpaired in live Δ).
- **#375** morning paste briefing draft for 2026-09-16 (`ab8891e06`).
- **#376** six holdout paired SO cells (`47fcb23ee`): lognormal, ordinal-pertrait-probit,
  truncated-Poisson, truncated-NB2, multinomial-FE, Student-t-fixed-ν — each → PARTIAL (native
  Wald + paired SO cell, β/`b_fix` block only). Live Δ `se_max_relative_delta`: lognormal 8.3e-6,
  ordinal-probit 9.5e-6, trunc-Poisson 8.9e-6, trunc-NB2 **9.8e-2** (documented parameterisation
  mismatch — Julia shared `r` vs R per-trait dispersion, not promoted to D1), multinomial-FE
  5.4e-6, Student-t-fixed-ν 3.0e-6.
- **#377** post-#374 true-parity tip (board/checkpoint/merge-receipt) — landed with stale content
  (written before #376 merged; still said #376 CONFLICTING) (`e47430735`).
- **#379** board/checkpoint/check-log refresh correcting #377's stale #376 status to MERGED, and
  recording the in-progress Tweedie EOO lane (`bf83d5f75`). Docs-only; Documenter-only CI (no
  Julia matrix triggered on this docs-only diff).

**Closed without merging:**

- **#380** — a second, independently-opened docs-tip PR duplicating #379's exact slice; went
  CONFLICTING the moment #379 landed. Closed with a comment pointing to #379 as the landed
  equivalent, to avoid two competing docs-tip PRs re-fighting the same content.

**Multi-agent note:** this was a genuinely concurrent night — #374 and #376 were each merged by
another lane (likely Grace) the instant their CI went green, faster than this lane's own poll-then-
merge loop could act; #379/#380 were two independently-opened duplicates of the same board-tip
slice from two different lanes. No conflicts landed on `main`; the redundant PR (#380) was closed
rather than merged.

**Continued after the above, same lane:**

- **#382** — morning-paste-briefing refresh (`2a97043a9`). The named refresh agent (`7a3f8015`)
  showed no activity on its scratch copy since 16:47 MDT, so this lane refreshed
  `docs/dev-log/owed/2026-09-16-morning-paste-briefing.md` directly rather than leave it stale;
  docs-only, Documenter-only CI.
- **#378** — Tweedie shared-power SO cell (option A; `b_fix`/β block only, power plug-in), merged
  at `67247f520`. All 8 Julia shards passed (slowest shard 1h7m27s); advisory Frozen R smoke
  failed as expected (accepted per standing rule); Grace babysat the merge. Own after-task file:
  `docs/dev-log/after-task/2026-09-16-tweedie-shared-power-so.md`.
- **#383** — post-#378 board/checkpoint tip (`9d021de63`). #378's own diff already covered
  `check-log.md` and the holdouts doc; this tip corrected only the two files it hadn't touched
  (`docs/dev-log/2026-09-14-true-parity-pending-board.md`, `LOOP/checkpoint.md`), which still
  described Tweedie as local-only/unpushed. Docs-only; Documenter-only CI.

As of `9d021de63`, this lane's ungated queue is effectively exhausted — see IN PROGRESS and OWED
below for what's left.

## IN PROGRESS (not yet merged)

None owned by this lane as of this update. One sibling PR is open and **held**, not in flight:

- **#384** — `feat(second-order): Tweedie species estimated-power Wald CI`
  (`cursor/tweedie-species-power-so-a0ce`), opened ~02:15 MDT by another Cursor lane (Grace),
  **DRAFT**. Triaged this update: content follows the same pattern as #374/#376/#378 (wires
  `TweediePerTraitPowerFit` into `_family_ci`, adds `cell_tweedie_species` + smoke, PARTIAL
  `b_fix`/β-block-only claim, no `Project.toml` bump, `#357` untouched, focused tests claimed
  22 pass / 1 R-skip in the PR body) and looks well-scoped and ungated on content alone. **Held
  DRAFT, not promoted to ready-for-review**, for two mechanical reasons, not a content objection:
  (1) `mergeStateStatus=DIRTY` / `mergeable=CONFLICTING` against current `main` — it was branched
  before #383 landed and touches the same `LOOP/checkpoint.md` + board lines #383 already edited;
  (2) `gh pr checks 384` reports **no checks have run at all** (draft PRs may not trigger this
  repo's CI), so there is no green-CI evidence yet, only the PR body's self-reported local test
  count. Rebasing #384 is the PR owner's/Grace's job, not this lane's scope to expand into; this
  lane did not touch #384's branch. Re-check `gh pr checks 384` and `gh pr view 384 --json
  mergeable,mergeStateStatus` after a rebase before promoting it to ready-for-review.

## OWED

Two kinds of "not done": four paste-gated items, one foreign PR, and one mechanical (not
paste-gated) blocker on a sibling PR.

**Paste-gated — do not start without the matching string, and do not bump `Project.toml`:**

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

**Foreign — do not edit:**

- **#357** (`feat/lognormal-truncpois-loglik-receipts-20260915`) — foreign bridge PR wiring
  lognormal + truncated-Poisson logLik receipts. CONFLICTING against this lane's docs edits on
  `check-log.md` only. **Left untouched all night**, per standing instruction. Do not edit without
  Shinichi's explicit say.

**Mechanical, not paste-gated:**

- **#384** (see IN PROGRESS above) — needs a rebase past `main` @ `9d021de63` and a green CI run
  before it can be promoted to ready-for-review. This is a merge-conflict + missing-CI-evidence
  blocker, not a policy gate; it does not need a Shinichi paste to clear, just the PR owner's
  rebase.

## Morning briefing refresh — DONE (superseding the earlier "content stale" note)

- Path: `docs/dev-log/owed/2026-09-16-morning-paste-briefing.md` (drafted in #375, `ab8891e06`;
  refreshed in #382, `2a97043a9`).
- The named refresh agent (`7a3f8015`) showed no activity on its scratch copy
  (`/Users/z3437171/local-scratch/gllvm-morning-paste-20260916`) since 16:47 MDT, so **this lane
  refreshed the file directly in #382** rather than assume the scheduled ~04:50 Denver refresh
  would still happen. The file now names `origin/main` @ `56b1a9f6f` (#381) as its last live
  refresh point — one merge behind the current `9d021de63` (#383) tip, since #378/#383 landed
  after #382. Whoever reads this near/after 04:50 Denver should still re-run the refresh commands
  in the briefing file if more has landed since `9d021de63`.
- Paste-string content in the file (Delta dispersion A / G0 Stage 1 / S4 probe yes / Totoro D-139
  ack) is unchanged and still correct as gate text.

## Checks run this tranche

- `git fetch origin`; `git rev-parse origin/main` (repeated, before every merge decision).
- `gh pr list --state open`; `gh pr view <n> --json mergeable,mergeStateStatus,files,body,state`
  (repeated, to detect duplicate/stale docs-tip PRs before acting).
- `gh api repos/itchyshin/GLLVM.jl/actions/runs/<id>/jobs` polling loops (2–3 min cadence) for
  #376 and #378's CI, merging on green once Documenter + all 8 Julia shards passed (Frozen R
  advisory failure accepted per standing rule).
- `gh pr ready 379` (was opened as Draft) before `gh pr merge 379 --squash --delete-branch`.
- `gh pr close 380 --comment ...` after confirming its diff duplicated #379's already-merged
  content.

## Rose fence

This handover records merge/close bookkeeping and CI-monitoring receipts only. It is **not** a
ledger promotion, **not** a §7 programme-parity claim, and does not clear any of the paste gates
above. The six #376 cells and the #374/#378 shared-dispersion cells remain **β/`b_fix`-block-only**
live Δ pairings — dispersion parameters (σ, r, φ, power) are documented as unpaired or
parameterisation-mismatched, not silently promoted. The #384 triage above is a merge-readiness
check, not a review of its statistical content — it was not opened by this lane and has not been
independently re-derived. Goal **not** complete.
