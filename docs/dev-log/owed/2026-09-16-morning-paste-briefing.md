# GLLVM.jl Morning Briefing — 2026-09-16

Status: **IN PROGRESS**. Do **not** claim the true-parity goal complete.

Last live refresh I could perform: **2026-09-16 00:55 UTC (18:55 MDT 2026-09-15)** from `gh pr list`,
`git fetch origin main`, and `origin/main`. This is close to, but not yet, the 04:50 MDT morning
window — rerun the refresh commands below before pasting if more time has passed since this note
was written.

`origin/main`: `56b1a9f6f` (`docs(handover): overnight true-parity handover (2026-09-15 -> 2026-09-16) (#381)`).

## Paste Strings Still Needed

Use these as separate lines in chat when Shinichi chooses to unlock each gate. Unchanged from the
prior refresh.

```text
accept delta dispersion A
```

Unlocks the Delta-lognormal / Delta-Gamma per-trait dispersion path. Until accepted, Delta second-order D1 is still OUT because Julia shared dispersion and R per-trait dispersion are different models.

```text
G0 Stage 1
```

Unlocks D3 `loading_profile` Stage 1 after Stage 0. Without this, the missing `loading_profile` surface stays blocked.

```text
S4 probe yes
```

Gives the second explicit yes for the S4 public-formula probe against the gllvmTMB #1283 recorder. This does not authorise R engine edits.

```text
ack Totoro D-139 #323 Track A
```

Authorises the optional Totoro run for the advisory Frozen R #323 Track A smoke under the recorded D-139 estimate. For T4 realistic-size second-order work, use an explicit D-139 ack naming the T4 grid before spending Totoro time.

## What Overnight Finished (since the 16:45 MDT refresh)

- #367 **merged**: Student-t fixed-ν native Wald `_CIFit`, PARTIAL native Wald only.
- #372 **merged**: SO toy receipts inventory for PARTIAL native-Wald rows.
- #373 **merged**: board / holdouts / AGENTS refresh after #367.
- #374 **merged** (`eeb7e0926`): BetaBinomial shared-φ SO toy cell + test → PARTIAL native Wald;
  φ block unpaired in live Δ.
- #375 **merged**: this briefing's first draft.
- #376 **merged** (`47fcb23ee`): six holdout paired SO cells (lognormal, ordinal-pertrait-probit,
  truncated-Poisson, truncated-NB2, multinomial-FE, Student-t-fixed-ν) → each PARTIAL native Wald +
  paired SO cell, β/`b_fix` block only. Truncated-NB2 live Δ se_rel ≈ 9.8e-2 is a documented
  dispersion-parameterisation mismatch (Julia shared `r` vs R per-trait), not a D1 promotion.
- #377 **merged** (`e47430735`): a board/checkpoint tip, but written before #376 merged — landed
  with stale "#376 CONFLICTING" text.
- #379 **merged** (`bf83d5f75`): corrected #377's stale #376 status to MERGED; recorded the
  in-progress Tweedie EOO lane.
- #380 **closed, not merged**: an independently-opened duplicate of #379's exact slice; went
  CONFLICTING once #379 landed.
- #381 **merged** (`56b1a9f6f`): the overnight handover doc,
  `docs/dev-log/handover/2026-09-16-overnight-true-parity-handover.md` — read that first for full
  detail; this briefing summarises it.

## Still Open / In Progress

- **#378** (`feat/tweedie-shared-power-so-20260916`, based on `47fcb23ee`): Tweedie shared-power SO
  cell (option A; β/`b_fix` block only, power plug-in). **OPEN, not yet merged** as of this refresh.
  Grace has been babysitting its merge; it took a fixup push mid-CI (a first run was cancelled, a
  second run started ~00:51 UTC). Check `gh pr view 378 --json state,mergedAt,mergeCommit` before
  assuming it landed. If it merges before the next refresh: (a) confirm whether its own diff already
  carries an after-task file and holdouts-doc update (it should, per the pattern of #374/#376), and
  (b) only open a new small board-tip PR if the board/`LOOP/checkpoint.md` text is still stale after
  that — do not duplicate #378's own bookkeeping.

## What Remains

- #357 remains **CONFLICTING** and foreign; leave it alone unless Shinichi explicitly says
  otherwise. Bridge CI lift still waits there.
- #363 and #314 remain unrelated/conflicting; skip.
- Delta species/per-trait dispersion remains paste-gated by `accept delta dispersion A`.
- D3 Stage 1 remains paste-gated by `G0 Stage 1`.
- S4 remains paste-gated by `S4 probe yes`.
- Totoro work remains D-139 gated.
- `Project.toml` stays `0.3.0`.
- Do not claim second-order §7 complete, full 0.7 parity, `v0.true-parity`, or Core070 `FREE=0` as
  true parity.

## Morning Refresh Commands

Run near 04:50 America/Denver before paste if possible:

```bash
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
git fetch origin main
git log --oneline -5 origin/main
gh pr list --limit 20 --state open
gh pr view 378 --json state,mergedAt,mergeCommit
```

Expected as of this refresh: `origin/main` at `56b1a9f6f`; open PR #378 (Tweedie, check
merge status); #357/#363/#314 conflicting or unrelated.
