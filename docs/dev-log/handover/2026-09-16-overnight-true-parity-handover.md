# Overnight true-parity handover (2026-09-15 → 2026-09-16)

**Lane:** Ada (Cursor), overnight conductor, ~17:00–~00:50 MDT window.
**Rehydrate:** `origin/main` @ `bf83d5f75` (#379, on top of #376/#374). `Project.toml` stays `0.3.0`.
Goal **NOT** complete. `#357` (foreign bridge PR) untouched throughout — do not edit it without
Shinichi's explicit say.

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

## IN PROGRESS (not yet merged)

- **#378** — Tweedie shared-power SO cell (option A; β/`b_fix` block only, power plug-in), on
  `feat/tweedie-shared-power-so-20260916`, based on `47fcb23ee`. Opened ~00:39 MDT. **Grace is
  babysitting this merge** — this lane did not merge it. At last check (~00:48 MDT): Documenter +
  `documenter/deploy` pass; all 8 Julia shards + the advisory Frozen R smoke still `pending`/
  `in_progress`, no failures observed. **Whoever picks this up next:** confirm `gh pr view 378
  --json state,mergedAt,mergeCommit` before assuming it landed, and check whether a follow-up
  board tip (analogous to #379) is needed to record the Tweedie cell as PARTIAL in
  `docs/dev-log/core070/second-order-holdouts-2026-09-04.md` + `LOOP/checkpoint.md` — only if that
  content isn't already covered by #378's own after-task file
  (`docs/dev-log/after-task/2026-09-16-tweedie-shared-power-so.md`, part of #378's diff).

## OWED (paste-gated; do not invent engine work around these)

Everything else on the board past Tweedie is paste-gated. Do **not** start Stage 1 / S4 / Totoro
work without the matching paste string below, and do not bump `Project.toml`.

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

- **#357** (`feat/lognormal-truncpois-loglik-receipts-20260915`) — foreign bridge PR wiring
  lognormal + truncated-Poisson logLik receipts. CONFLICTING against this lane's docs edits on
  `check-log.md` only. **Left untouched all night**, per standing instruction. Do not edit without
  Shinichi's explicit say.

## Morning briefing refresh — path confirmed, content stale

- Path: `docs/dev-log/owed/2026-09-16-morning-paste-briefing.md` (drafted in #375, `ab8891e06`).
  Sibling scratch copy: `/Users/z3437171/local-scratch/gllvm-morning-paste-20260916` (branch
  `docs/morning-paste-briefing-20260916`).
- **Content is stale as of this handover** — last live refresh recorded inside the file itself is
  "2026-09-15 16:45 MDT", and it names `origin/main` @ `83990686d0` (#373), i.e. **before** #374,
  #376, #377, #379 (and #378, if it lands). The file's own text already says "rerun the refresh
  before pasting if the morning window has arrived" — that refresh has not happened yet in this
  handover.
- Per earlier briefing (2026-09-15 ~17:17 MDT): a GPT agent is expected to refresh this file
  ~04:50 Denver, ahead of the 05:00 Denver stop. **This handover does not confirm that refresh
  ran** — whoever reads this near or after 04:50 Denver should check the file's own "Last live
  refresh" line before trusting its paste strings or DONE list, and refresh it themselves
  (`gh pr list`, `git fetch origin && git rev-parse origin/main`) if the GPT agent has not.
- Paste-string content in the file (Delta dispersion A / G0 Stage 1 / S4 probe yes / Totoro D-139
  ack) is unchanged and still correct as gate text; only the "last refreshed" tip and DONE list
  need updating.

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
parameterisation-mismatched, not silently promoted. Goal **not** complete.
