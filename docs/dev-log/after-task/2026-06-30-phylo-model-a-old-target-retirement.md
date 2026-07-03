# After Task: Phylo Model A old-target retirement

## Goal

Update the durable Phylo Model A design record after the negative
profile_truth canary so the project no longer points to profile-LR as the next
rescue for the old target.

## Implemented

Updated the redesign decision note and Design 73 to record that the
task-8 entry-71 profile_truth canary converged and missed truth
(`LR = 9.9918 > 3.8415`). The old population-`B_lv` interval target is now
treated as retired for v1 source-specific phylo `lv` exposure unless the
maintainer chooses structural redesign or a narrower regime with fresh evidence.
Mission Control's claim guard was also updated so it no longer says the next
step is a profile-LR canary.

## Mathematical Contract

No likelihood or estimator changed. The decision follows the one-df
profile-LR truth-inclusion check:
`2 * (nll_constrained(B_lv = truth) - nll_mle) <= qchisq(level, 1)`. The
observed weak-cell canary failed that condition for the selected entry.

## Files Changed

- `docs/dev-log/decisions/2026-06-30-phylo-model-a-redesign-plan.md`
- `docs/dev-log/decisions/2026-06-30-phylo-model-a-council-final.md`
- `docs/design/73-predictor-informed-latent-scores.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-30-phylo-model-a-old-target-retirement.md`
- gllvmTMB dashboard: `docs/dev-log/dashboard/status.json`

## Tests Added

None. This is a design/status update after an already-run diagnostic canary.

## Benchmark Numbers

N/A - no code path or benchmark target changed.

## R-Parity Verdict

Parity: N/A - no R bridge, likelihood, fitter, or CI implementation changed.

## JET / Allocs / Aqua Verdicts

- JET: not run - documentation/status-only change.
- Allocs: not run - no hot path changed.
- Aqua: not run - no package metadata or exports changed.

## Checks Run

```sh
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json >/dev/null
rg -n "profile-LR B_lv canary|next admissible step is a profile-LR|ready to scale|partial support|source-specific.*covered" docs/dev-log/decisions/2026-06-30-phylo-model-a-redesign-plan.md docs/design/73-predictor-informed-latent-scores.md /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json
git diff --check -- docs/dev-log/decisions/2026-06-30-phylo-model-a-redesign-plan.md docs/design/73-predictor-informed-latent-scores.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-30-phylo-model-a-old-target-retirement.md
julia --project=. test/test_phylo_xlv.jl
```

The stale-target search is expected to return no live recommendation that the
next step is a profile-LR canary for the old target. Historical/log mentions are
allowed when they describe the failed canary.

Focused phylo Model A tests passed again: `25/25` in `1m03.6s`.

## Consistency Audit

Design 73, the redesign decision note, the council-final decision, and Mission
Control now agree: public source-specific phylo `lv` remains blocked; the old
interval target should not receive more same-route compute; the next decision is
structural redesign, narrower supported regime, or v1 retirement.

## GitHub Issue Maintenance

No GitHub action was taken. PR #127 remains closed/parked as blocked evidence.

## What Did Not Go Smoothly

The result is negative rather than a finished feature. The useful outcome is
claim control: the project no longer has a plausible-looking profile-LR rescue
queued for a target whose first adversarial truth-inclusion check failed.

## Team Learning

Rose's role is to convert a failed canary into a product boundary quickly, before
old "next step" language becomes accidental roadmap.

## Remaining Risks

- A narrower phylo Model A regime might still be useful, but no such regime is
  validated yet.
- The current decision is local documentation/status; no maintainer-facing PR or
  GitHub issue comment was made.
- Full package tests were not run because this was documentation/status only.

## Known Limitations

This does not implement structural redesign, does not validate a smaller domain,
and does not change R grammar. It only prevents the old blocked target from
being treated as pending support.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && rg -n "next admissible step is a profile-LR|profile-LR B_lv canary|partial support|source-specific.*covered" docs/dev-log/decisions docs/design docs/dev-log/check-log.md
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - stale profile-LR-next wording is retired, but
phylo Model A remains blocked until structural redesign, narrower-regime
evidence, or v1 retirement is explicitly chosen.
