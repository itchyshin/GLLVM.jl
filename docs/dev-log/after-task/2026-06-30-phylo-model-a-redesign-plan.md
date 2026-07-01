# After Task: Phylo Model A redesign plan

## Goal

Draft a compact, evidence-grounded redesign plan for the blocked phylo Model A
`X_lv` interval route before any new large compute.

Superseded note, 2026-07-01: this report records the first redesign plan. A
later local `profile_truth` canary for task 8 entry 71 missed truth, so the
current operating policy is the structural-dependency lock in
`docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md`.

## Implemented

Added a decision-plan note that starts from the p = 80, K = 2, lambda = 0.5
`B_lv` weak-cell evidence, names what worked and what failed, separates
`alpha_lv` from `B_lv`, and originally recommended profile-LR calibrated
Gaussian Model A `B_lv` as the next candidate target. That recommendation is now
retired by the later negative `profile_truth` canary. Updated the check log for
the planning slice. No source, API, tests, likelihood code, R bridge code, or
cluster compute changed in this planning-only step.

## Mathematical Contract

Planning-only. The proposed estimand separation preserves the existing contract:
`alpha_lv` is the access/axis-effect coefficient for the latent score mean, while
`B_lv = Lambda * alpha_lv'` is the rotation-invariant induced trait/loading
effect and the only admissible current interval target.

## Files Changed

- `docs/dev-log/decisions/2026-06-30-phylo-model-a-redesign-plan.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-30-phylo-model-a-redesign-plan.md`

## Tests Added

None. This is a docs/design planning slice, not an implementation slice.

## Benchmark Numbers

N/A - no hot-path code changed.

## R-Parity Verdict

Parity: N/A - no Gaussian marginal likelihood, fitter, init path, bridge, or CI
implementation changed.

## JET / Allocs / Aqua Verdicts

- JET: not run - no Julia code changed.
- Allocs: not run - no hot path changed.
- Aqua: not run - no package metadata or exports changed.

## Checks Run

```sh
sed -n '1,260p' /Users/z3437171/shinichi-brain/AGENTS.md
sed -n '1,240p' /Users/z3437171/shinichi-brain/memory/00-INDEX.md
sed -n '1,320p' AGENTS.md
sed -n '1,320p' docs/dev-log/handover/2026-06-30-codex-handover.md
sed -n '1,320p' docs/design/73-predictor-informed-latent-scores.md
sed -n '1,260p' docs/dev-log/after-task/2026-06-30-phylo-xlv-weak-cell-mechanism-diagnosis.md
sed -n '1,260p' docs/dev-log/after-task/2026-06-30-phylo-xlv-bootstrap-basic-aggregate.md
git status --short --branch
git rev-parse --short HEAD
gh run list --limit 3
gh pr view 127 --repo itchyshin/GLLVM.jl --json number,state,title,headRefName,headRefOid,isDraft,mergeStateStatus,statusCheckRollup,url,updatedAt
gh pr list --repo itchyshin/GLLVM.jl --state open --json number,title,headRefName,updatedAt,url,mergeStateStatus,isDraft
git log --all --oneline --since="6 hours ago" -- AGENTS.md CLAUDE.md README.md ROADMAP.md CHANGELOG.md docs/design docs/src docs/dev-log/check-log.md docs/dev-log/after-task bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh bench/phylo_xlv_drac_summarise.jl
```

Pre-edit result: checkout clean at `e794575`; PR #127 `CLOSED`; no open
GLLVM.jl PRs; recent same-file history showed only the handoff and weak-cell
diagnostic commits.

```sh
git diff --check
rg -n "source-specific.*lv|phylo_latent\\(.*lv|bootstrap_basic|p = 80|p=80|alpha_lv|B_lv|axis_effect|trait_effect" docs/dev-log/decisions/2026-06-30-phylo-model-a-redesign-plan.md docs/design/73-predictor-informed-latent-scores.md AGENTS.md docs/src/model.md src/postfit.jl docs/dev-log/check-log.md
rg -n "ready to scale|production sweep|coverage.*ready|source-specific.*covered" README.md docs/src docs/design AGENTS.md docs/dev-log/check-log.md
julia --project=. -e 'using GLLVM; println("GLLVM load ok")'
```

Final results: `git diff --check` passed. The targeted estimand/source-specific
scan returned expected current or historical mentions in AGENTS, Design 73, the
new plan, the check log, `docs/src/model.md`, and `src/postfit.jl`; no new public
support claim was found. The production-claim scan returned only historical
check-log entries and Design 73's "do not launch or advertise" gate. The
lightweight Julia load check printed `GLLVM load ok`.

## Consistency Audit

The plan keeps the existing public boundary: source-specific phylo `lv` remains
unadvertised and R grammar remains fail-loud until a redesigned target passes.
The exact stale-wording scans are listed under Checks Run.

## GitHub Issue Maintenance

Confirmed PR #127 is already closed/parked as blocked evidence. No issue or PR
comment was made in this planning slice.

## What Did Not Go Smoothly

The old branch contains useful point-plumbing and diagnostics, but the interval
evidence is strong enough that the branch should be treated as retired evidence,
not as a nearly-ready PR.

## Team Learning

Fisher should lead the next interval-target decision, with Rose guarding the
claim boundary and Boole/Hopper kept out of R grammar exposure until evidence
supports it.

## Remaining Risks

- Profile-LR has now failed the selected task-8 entry-71 truth-inclusion canary
  for the old population-`B_lv` target.
- Axis-effect `alpha_lv` remains rotation dependent and has no admissible SE/CI
  target yet.
- Source-specific phylo `lv` remains blocked until a redesigned target passes a
  predeclared evidence gate.

## Known Limitations

This task did not validate profile-LR calibration, did not run production
coverage, did not reopen PR #127, and did not change the R bridge guard.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && sed -n '1,140p' docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - the original planning deliverable is preserved
as audit history, but its profile-LR-next recommendation is superseded and phylo
Model A remains blocked until structural redesign, narrower-regime ADEMP
evidence, or explicit v1 retirement.
