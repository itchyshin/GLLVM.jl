# GLLVM.jl Morning Briefing — 2026-09-16

Status: **IN PROGRESS**. Do **not** claim the true-parity goal complete.

Last live refresh I could perform: **2026-09-15 16:45 MDT** from `gh pr list`, `git fetch origin main`, and `origin/main`. This is **not** a 2026-09-16 04:50 MDT refresh; rerun the refresh before pasting if the morning window has arrived.

`origin/main`: `83990686d0` (`docs: post-#367 true-parity tip (board, holdouts, AGENTS) (#373)`).

## Paste Strings Still Needed

Use these as separate lines in chat when Shinichi chooses to unlock each gate.

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

## What Overnight Likely Finished

- #367 **merged**: Student-t fixed-ν native Wald `_CIFit`, now PARTIAL native Wald only.
- #373 **merged**: board / holdouts / AGENTS refresh after #367; this is the current `origin/main` tip at `83990686d0`.
- #374 is open and mergeable: BetaBinomial shared-φ second-order toy cell + test. The branch after-task says focused test **10 pass / 0 fail / 1 broken** (R skip), with no `confint_family.jl` edits and no §7 claim.
- #372 is open and mergeable: SO toy receipts inventory for PARTIAL native-Wald rows.

## What Remains

- Merge or babysit #374 and #372 only if their checks settle cleanly and the active lane still owns them.
- #357 remains **CONFLICTING** and foreign; leave it alone unless Shinichi explicitly says otherwise. Bridge CI lift still waits there.
- #363 and #314 remain unrelated/conflicting; skip.
- Delta species/per-trait dispersion remains paste-gated by `accept delta dispersion A`.
- D3 Stage 1 remains paste-gated by `G0 Stage 1`.
- S4 remains paste-gated by `S4 probe yes`.
- Totoro work remains D-139 gated.
- `Project.toml` stays `0.3.0`.
- Do not claim second-order §7 complete, full 0.7 parity, `v0.true-parity`, or Core070 `FREE=0` as true parity.

## Morning Refresh Commands

Run near 04:50 America/Denver before paste if possible:

```bash
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
git fetch origin main
git log --oneline -5 origin/main
gh pr list --limit 20 --state open
```

Expected as of my refresh: `origin/main` at `83990686d0`, open PRs #374 and #372 mergeable, #357/#363/#314 conflicting or unrelated.
