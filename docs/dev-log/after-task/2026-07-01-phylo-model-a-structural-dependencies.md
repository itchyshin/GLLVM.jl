# After Task: Phylo Model A structural dependencies

## Goal

Record the method/estimand decision for phylo Model A after Shinichi clarified:
no bootstrap rescue, profile only if useful, and `alpha_lv` can remain the
ordinary Wald/default axis-effect side.

## Implemented

Added a structural-dependencies decision note and refreshed Design 73 plus the
local Mission Control board. Superseding update: the later K = 1 20-replicate
selected-entry gate also failed, so the current operating rule is stricter than
the original note: no bootstrap for the current phylo weak-cell route;
profile-LR only as a selected-entry truth-inclusion canary after a genuinely
different target/regime is named; `alpha_lv` Wald output is conditional
axis/access-effect output; source-specific phylo `lv` remains blocked until
structural redesign with fresh evidence or explicit v1 retirement.

## Mathematical Contract

No likelihood, fitter, or estimator changed. The contract remains:
`B_lv = Lambda * alpha_lv'` is the rotation-invariant trait/loading effect,
while `alpha_lv` is the axis/access-effect coefficient under the fitted loading
convention. The failed old-target canary used the one-df profile-LR
truth-inclusion check
`2 * (nll_constrained(B_lv = truth) - nll_mle) <= qchisq(level, 1)`.

## Files Changed

- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md`
- `docs/design/73-predictor-informed-latent-scores.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-phylo-model-a-structural-dependencies.md`
- gllvmTMB dashboard: `docs/dev-log/dashboard/status.json`
- gllvmTMB dashboard: `docs/dev-log/dashboard/sweep.json`

## Tests Added

None. This was a design/status guardrail update, not an implementation change.

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
git diff --check -- docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md docs/design/73-predictor-informed-latent-scores.md docs/dev-log/check-log.md
git -C /Users/z3437171/Dropbox/Github\ Local/gllvmTMB diff --check -- docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json
rg -n "bootstrap is not the next route|no bootstrap rescue|profile-LR is only a selected-entry|alpha Wald|structural-dependencies|partial support|source-specific.*covered|ready to scale" docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md docs/design/73-predictor-informed-latent-scores.md docs/dev-log/check-log.md /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/sweep.json
sh tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/version.txt
curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool | rg -n "updated|no bootstrap rescue|profile-LR is only|alpha Wald|profile_truth|active|queued|blocked|partial support"
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool | rg -n "updated|no bootstrap rescue|profile-LR is only|Alpha Wald|bootstrap is not the next route|active|queued|blocked"
julia --project=. test/test_phylo_xlv.jl
```

Results: JSON parsed; `git diff --check` passed; served `version.txt` stayed
`r60`; served Mission Control JSON showed `updated = 2026-06-30 21:41 MDT`,
`active = 0`, `queued = 0`, `blocked = 5`, and the no-bootstrap/profile-canary
method lock.

Focused phylo Model A tests passed after the documentation/status refresh:
`25/25` in `1m03.3s`.

## Consistency Audit

The `rg` scan above found expected current guard text and historical failed
canary/weak-cell evidence. It did not find live "ready to scale" or
source-specific phylo `lv` promotion wording.

## GitHub Issue Maintenance

No GitHub action was taken. PR #127 remains closed/parked as blocked evidence.

## What Did Not Go Smoothly

Browser automation against the in-app preview timed out during the read-only
page check. The preview source was still verified by the served JSON at
`http://127.0.0.1:8770/status.json` and `sweep.json`, and the browser tab
remains pointed at `http://127.0.0.1:8770/`.

## Team Learning

Fisher and Rose should name the estimand boundary before Grace spends compute;
otherwise the project can burn cores refining a target that is already blocked.

## Remaining Risks

- Phylo Model A is not solved; this slice prevents the wrong reruns.
- The first narrowed K = 1 population target did not pass the 20-replicate
  diagnostic gate.
- A realized/sampling-conditional target is possible but changes the scientific
  claim and needs explicit maintainer approval.
- Full package tests were not run because no code changed.

## Known Limitations

This does not expose R grammar, does not reopen PR #127, does not launch
Totoro/DRAC work, and does not validate a replacement target. It only records
the structural dependency and method policy for the next admissible step.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && sed -n '1,140p' docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md
```

## Rose Verdict

Rose verdict: SUPERSEDED WITH BLOCKER - the method/estimand lock is durable, and
the later K = 1 gate failure means phylo Model A remains blocked until
structural redesign with fresh evidence or explicit v1 retirement is chosen.
