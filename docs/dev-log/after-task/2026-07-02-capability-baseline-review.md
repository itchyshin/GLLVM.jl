# After Task: Capability Baseline Review

## Goal

Set the seven-hour post-LV work block on a repo-grounded capability baseline
and fix one safe claim-boundary drift before any further implementation or
compute.

## Implemented

Added a capability-baseline review note and tightened the predictor-informed
latent-score design note so future source-specific phylo `lv` wiring cannot be
read as current admission guidance. This is a docs-only truth-sync slice; no
Julia source, likelihood code, R grammar, package API, PR state, or compute
changed.

## Mathematical Contract

No mathematical contract changed. The standing contract remains:
ordinary `latent(..., lv = ~ x)` models predictor-informed latent-score means;
source-specific `phylo_latent(..., lv = ~ x)` stays guarded/fail-loud; the
positive Phylo Model A evidence applies only to the internal
`B_eta_realized` target, not to public source-specific grammar.

## Files Changed

docs:

- `docs/design/73-predictor-informed-latent-scores.md`
- `docs/dev-log/decisions/2026-07-02-capability-baseline-review.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-capability-baseline-review.md`

## Tests Added

None. This was a docs-only capability truth-sync.

## Benchmark Numbers

N/A - no hot-path or likelihood code changed.

## R-Parity Verdict

Parity: N/A - change does not touch the parity surface.

## JET / Allocs / Aqua Verdicts

- JET: not run - docs-only change.
- Allocs: not run - docs-only change.
- Aqua: not run - docs-only change.

## Checks Run

```sh
git diff --check -- docs/design/73-predictor-informed-latent-scores.md docs/dev-log/decisions/2026-07-02-capability-baseline-review.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-02-capability-baseline-review.md
# passed, no output

rg -n 'future-only source-specific|future authorized|guarded/fail-loud|ordinary `latent\(\.\.\., lv = ~ x\)`|source-specific `phylo_latent\(\.\.\., lv = ~ x\)`' docs/design/73-predictor-informed-latent-scores.md docs/dev-log/decisions/2026-07-02-capability-baseline-review.md docs/dev-log/after-task/2026-07-02-capability-baseline-review.md
# found the tightened future-only wording and guarded/source-specific boundary

rg -n 'ready to expose|active compute|source-specific.*covered|non-Gaussian.*inherits|mixed-family.*CI.*support|Admit `lv` as a one-sided predictor formula on `latent\(\)`' docs/design/73-predictor-informed-latent-scores.md docs/dev-log/decisions/2026-07-02-capability-baseline-review.md
# no output

python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/version.txt
# r60
```

## Consistency Audit

Task-specific scans targeted stale source-specific `lv` support language,
active-compute wording, and the newly tightened future-only phrase. Dashboard
JSON validity was checked because Mission Control remains the local operating
board, even though no dashboard source changed.

## GitHub Issue Maintenance

No issue action needed. This is local handover/truth-lock documentation.

## What Did Not Go Smoothly

The gllvmTMB worktree is heavily dirty, including older capability synthesis
docs. To avoid mixing another agent's edits into this commit, the durable
review was recorded in the cleaner GLLVM.jl handover worktree and the older
gllvmTMB synthesis is only cited as a reviewed source.

## Team Learning

Rose/Hopper boundary: keep old capability ledgers useful as evidence, but make
the current operating truth explicit in a new review note when dirty worktrees
make direct ledger edits unsafe.

## Remaining Risks

- Bridge capability drift still needs a focused audit across R and Julia files.
- Mixed-family `X`, `X_lv`, masks, missing responses, and CIs remain blocked.
- Source-specific `lv` remains parked until Shinichi authorizes a new gated
  slice.

## Known Limitations

This task does not implement a new model, expose a formula argument, add
tests, or run compute. It only locks the current claim boundary and selects the
next bounded audit lane.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && rg -n 'source-specific|predictor_informed_lv|mixed.*CI|X_lv|ci_note|not routed' src/bridge.jl test/test_bridge_*.jl
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - docs-only claim-boundary sync is complete; the
remaining capability work is the bridge drift audit and any safe focused guard
test that falls out of it.
