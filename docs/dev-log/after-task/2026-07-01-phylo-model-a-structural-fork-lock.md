# After Task: Phylo Model A structural fork lock

## Goal

Close the failed phylo Model A interval dependency chain and make the remaining
choice explicit before any more compute.

## Implemented

Added a structural-redesign fork note: source-specific phylo `lv` now has only
two admissible futures, v1 retirement or a genuinely changed realized/sampling-
conditional target with fresh ADEMP evidence. Refreshed Design 73, the check
log, and Mission Control so profile-LR is described only as a selected-entry
canary for a changed target, not as a continuation of the failed population-
`B_lv` route. No package API, likelihood code, R grammar, PR state, or compute
launcher was changed.

## Mathematical Contract

`alpha_lv` remains a conditional axis/access-effect coefficient under the
fitted loading convention; Wald output is acceptable for that display only.
`B_lv = Lambda * alpha_lv'` remains the rotation-invariant population
trait/loading product, but the old population-`B_lv` interval route is blocked
for v1 exposure. A future realized/sampling-conditional target must define and
store its own replicate-specific truth before `profile_truth` diagnostics run.

## Files Changed

- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-redesign-fork.md`
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md`
- `docs/design/73-predictor-informed-latent-scores.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-phylo-model-a-structural-fork-lock.md`
- gllvmTMB dashboard: `docs/dev-log/dashboard/status.json`
- gllvmTMB dashboard: `docs/dev-log/dashboard/sweep.json`

## Tests Added

None. This was a documentation/status guardrail update.

## Benchmark Numbers

N/A - no hot-path code changed.

## R-Parity Verdict

Parity: N/A - no R bridge, likelihood, fitter, init, or CI machinery changed.

## JET / Allocs / Aqua Verdicts

- JET: not run - no Julia source changed in this slice.
- Allocs: not run - no hot path changed.
- Aqua: not run - no package metadata, exports, or dependencies changed.

## Checks Run

```sh
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/sweep.json >/dev/null
git diff --check -- docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-redesign-fork.md docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md docs/design/73-predictor-informed-latent-scores.md docs/dev-log/check-log.md
git -C /Users/z3437171/Dropbox/Github\ Local/gllvmTMB diff --check -- docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json
sh tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool | rg -n "updated|Structural fork lock|realized/sampling-conditional|K=1 profile gate|no bootstrap|active|queued|blocked"
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool | rg -n "updated|Structural fork lock|realized/sampling-conditional|K=1 profile gate|no bootstrap|active|queued|blocked"
julia --project=. test/test_phylo_xlv.jl
```

Results: dashboard JSON parsed; `git diff --check` passed before the after-task
file was added; Mission Control restarted and served `updated = 2026-06-30
22:37 MDT`, `active = 0`, `queued = 0`, `blocked = 5`, and the new
`Structural fork lock` row. Focused phylo Model A tests passed: `25/25` in
`1m07.3s`.

Browser check: the in-app browser tab remained on `http://127.0.0.1:8770/`,
but browser automation timed out on reload twice. The served JSON backing the
preview was verified by `curl`; the tab should show the refreshed board on
manual refresh.

## Consistency Audit

Ran:

```sh
rg -n "partial support|ready to scale|source-specific.*covered|source-specific.*unblock|bootstrap rescue|profile endpoint repeats|production fan-out" docs/dev-log/decisions docs/design/73-predictor-informed-latent-scores.md /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/sweep.json
```

Results: hits are negative guardrails, historical command strings, or current
blocked wording. No live text claims source-specific phylo `lv` is ready,
covered, or partially supported.

## GitHub Issue Maintenance

No GitHub action was taken. PR #127 remains closed/parked as blocked evidence.

## What Did Not Go Smoothly

Browser automation could not complete a read-only reload check even after the
dashboard server and served JSON were healthy. No package state depends on that
browser path.

## Team Learning

Fisher should keep profile-LR as a canary for a newly named target only. Curie
must define the ADEMP truth before Grace spends compute. Rose should continue
blocking "partial support" language for source-specific phylo `lv`.

## Remaining Risks

- Phylo Model A is not solved; the old population-`B_lv` route is closed as
  negative evidence.
- Shinichi still needs to choose v1 retirement or explicitly authorize a
  changed realized/sampling-conditional target.
- The NotebookLM trio/video material was not available in this workspace; this
  decision uses the local weak-cell evidence and the likelihood-framework
  interval distinction already recorded in Design 73.

## Known Limitations

This does not expose R grammar, reopen PR #127, launch Totoro/DRAC work, change
likelihood code, or validate a replacement target.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && sed -n '1,180p' docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-redesign-fork.md
```

## Rose Verdict

Rose verdict: BLOCKED WITH CLEAN FORK - no public source-specific phylo `lv`
support follows from current evidence; the only honest next step is v1
retirement or a maintainer-approved changed target with fresh ADEMP evidence.
