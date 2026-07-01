# After Task: Phylo Model A council and mission-control refresh

## Goal

Refresh the local Mission Control board and GLLVM.jl planning log so the
phylogenetic LV arc has an explicit council gate before any new compute or
source-specific R grammar exposure.

Superseded note, 2026-07-01: the later seed-matched `profile_truth` canary for
task 8 entry 71 missed truth, so the current operating policy is no bootstrap
rescue and profile-LR only as a selected-entry truth-inclusion canary after a
new/narrowed target is named. See
`docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md`.

## Implemented

Updated the local gllvmTMB Mission Control source JSON and synced the served
widget. The board now states that GLLVM.jl phylo Model A remains blocked, that
same-route Wald, t-Wald, percentile bootstrap, and `bootstrap_basic` reruns are
retired for the p = 80, K = 2, lambda = 0.5 weak cell, and that any interval
claim must pass a predeclared council gate before grammar exposure. At the time,
the next candidate was a Gaussian direct/native profile-LR canary for
rotation-invariant `B_lv`; that candidate was later run as a truth-inclusion
canary and failed for the task-8 entry-71 row. Added the matching GLLVM.jl
check-log entry and later superseding structural lock.

## Mathematical Contract

Planning/dashboard-only. The statistical contract is unchanged: `alpha_lv` is
the access/axis-effect coefficient for the predictor-informed latent score mean,
while `B_lv = Lambda * alpha_lv'` is the rotation-invariant induced
trait/loading effect and remains the only current interval target.

## Files Changed

- gllvmTMB dashboard: `docs/dev-log/dashboard/status.json`
- gllvmTMB dashboard: `docs/dev-log/dashboard/sweep.json`
- GLLVM.jl docs: `docs/dev-log/check-log.md`
- GLLVM.jl docs: `docs/dev-log/after-task/2026-06-30-phylo-model-a-council-mission-control-refresh.md`

## Tests Added

None. This was a local dashboard and planning-log refresh, not source
implementation.

## Benchmark Numbers

N/A - no hot-path code changed.

## R-Parity Verdict

Parity: N/A - no likelihood, fitter, bridge, init, or CI machinery changed.

## JET / Allocs / Aqua Verdicts

- JET: not run - no Julia source changed.
- Allocs: not run - no hot path changed.
- Aqua: not run - no package metadata, exports, or deps changed.

## Checks Run

```sh
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
git diff --check -- docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json
git diff --check -- docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-30-phylo-model-a-council-mission-control-refresh.md docs/dev-log/decisions/2026-06-30-phylo-model-a-redesign-plan.md
gh pr view 127 --repo itchyshin/GLLVM.jl --json number,state,title,headRefName,headRefOid,isDraft,mergeStateStatus,url,updatedAt
sh tools/start-mission-control.sh --background
curl -s -o /dev/null -w '8770 %{http_code}\n' http://127.0.0.1:8770/
curl -s http://127.0.0.1:8770/version.txt
python3 - <<'PY'
import json, urllib.request
with urllib.request.urlopen('http://127.0.0.1:8770/status.json', timeout=5) as r:
    data=json.load(r)
print(data["updated"])
print(data["metrics"])
PY
```

Results: dashboard JSON parsed successfully; `git diff --check` passed for the
touched dashboard and GLLVM.jl docs files; PR #127 remained `CLOSED`, draft, and
unstable on old head `b87a522`; Mission Control served HTTP `200`; `version.txt`
remained `r60`; served status updated to `2026-06-30 17:33 MDT`; source and
served `status.json` / `sweep.json` matched byte-for-byte. Browser preview at
`http://127.0.0.1:8770/` visibly showed profile-LR canary, retired reruns,
`591/720 = 0.821`, and `0 active`.

Later Mission Control refresh on 2026-06-30 21:41 MDT superseded the profile-LR
next-step wording: served JSON now states no bootstrap rescue, profile-LR only
after target lock, `alpha_lv` Wald as conditional axis/access-effect output,
`active = 0`, `queued = 0`, and `blocked = 5`.

## Consistency Audit

Patterns run:

```sh
rg -n "partial support|ready to scale|production sweep|source-specific.*covered|phylo_latent\\(.*lv.*covered|lv.*source-specific.*covered|profile-LR|canary|bootstrap_basic|Wald|t-Wald|percentile" docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json docs/dev-log/check-log.md docs/dev-log/decisions/2026-06-30-phylo-model-a-redesign-plan.md docs/design/73-predictor-informed-latent-scores.md
rg -n "PR #581 is not on main|review/merge PR #581|once merged|branch install route|source-specific phylo lv partial support|ready to scale|production sweep|source-specific.*covered" docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json
```

The first scan returned expected current and historical mentions of the weak
cell, canary, and retired interval routes. The second scan found one stale
`once merged` phrase in the dashboard; it was corrected to say PR #581 is on
main. Remaining `partial support` hits are explicit guard text saying not to use
that wording for source-specific phylo `lv`.

## GitHub Issue Maintenance

Confirmed GLLVM.jl PR #127 is closed/parked. No issue or PR comment was made
because this slice changed only local Mission Control and planning logs.

## What Did Not Go Smoothly

The gllvmTMB checkout was already heavily dirty with unrelated work. I touched
only `docs/dev-log/dashboard/status.json` and `docs/dev-log/dashboard/sweep.json`
there. One ad hoc served-status parse command failed because a heredoc consumed
stdin from `curl`; the corrected `urllib.request` check passed.

## Team Learning

Rose should be part of every dashboard refresh, because local operating boards
can silently keep stale merge or support wording after the code state changes.

## Remaining Risks

- The old profile-LR `B_lv` canary has now failed for the adversarial task-8
  entry-71 truth-inclusion check.
- Phylo Model A source-specific `lv` remains blocked until structural redesign,
  narrower-regime ADEMP evidence, or explicit v1 retirement/sign-off.
- The gllvmTMB dashboard source worktree has substantial unrelated dirt, so any
  later commit must stage files by explicit path only.

## Known Limitations

This task did not validate profile-LR intervals, did not run production
coverage, did not launch Totoro/DRAC jobs, did not reopen PR #127, and did not
change R grammar guards.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && sed -n '1,140p' docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - Mission Control and the GLLVM.jl log state the
blocked/council boundary; later evidence supersedes the profile-LR-next wording
and keeps phylo Model A blocked under the structural-dependency lock.
