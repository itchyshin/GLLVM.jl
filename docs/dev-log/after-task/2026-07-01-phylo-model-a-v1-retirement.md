# After Task: Phylo Model A v1 retirement / parking

## Goal

Finish the current phylo Model A planning arc by recording the honest v1
decision after the population-target, narrowed-regime, and realized direct-slope
profile gates failed strict canaries.

## Implemented

Added a durable v1 retirement/parking decision note and refreshed Design 73,
the structural-dependency notes, the check log, and Mission Control so the
visible operating truth is clear: ordinary `latent(lv = ~ x)` remains supported
under its evidence, but public source-specific phylo `lv` is parked for v1.
Future work must begin with a newly predeclared ADEMP target/gate before
profile-LR, Totoro diagnostics, DRAC claim evidence, or R grammar exposure.

## Mathematical Contract

No likelihood contract changed. The interval policy is unchanged but narrowed:
`alpha_lv` is a conditional axis/access-effect display under the fitted loading
convention; old population `B_lv = Lambda * alpha_lv'` is rotation-stable but
blocked for public phylo Model A exposure; profile-LR is only a future
selected-entry canary for a new target.

## Files Changed

- `docs/dev-log/decisions/2026-07-01-phylo-model-a-v1-retirement.md`
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-redesign-fork.md`
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md`
- `docs/design/73-predictor-informed-latent-scores.md`
- `docs/dev-log/check-log.md`
- gllvmTMB dashboard: `docs/dev-log/dashboard/status.json`
- gllvmTMB dashboard: `docs/dev-log/dashboard/sweep.json`

## Tests Added

None. This was a planning/dashboard closeout; no `src/` behavior or public API
changed.

## Benchmark Numbers

N/A - no hot-path change.

## R-Parity Verdict

Parity: N/A - no Gaussian marginal likelihood, profile-out, init, fitter, or CI
machinery changed.

## JET / Allocs / Aqua Verdicts

- JET: not run - docs/dashboard-only change.
- Allocs: not run - no hot path changed.
- Aqua: not run - no package structure or dependency changed.

## Checks Run

```sh
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/sweep.json >/dev/null
git diff --check -- docs/dev-log/decisions/2026-07-01-phylo-model-a-v1-retirement.md docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-redesign-fork.md docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md docs/design/73-predictor-informed-latent-scores.md
git -C /Users/z3437171/Dropbox/Github\ Local/gllvmTMB diff --check -- docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json
julia --project=. test/test_phylo_xlv.jl
```

Focused package check: `phylo x X_lv (Model A)` passed `25/25` in `1m05.6s`.

Mission Control:

```sh
sh /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/version.txt
curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool | rg -n "23:30|v1 parking|retired/parked|96/100|blocked_no_active_compute|No active|no active|newly predeclared|PR #127"
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool | rg -n "23:30|v1 parking|retired/parked|96/100|profile-LR|no compute|PR #127"
```

Served version stayed `r60`, and served JSON shows the `2026-06-30 23:30 MDT`
v1 parking row, `96/100` direct-slope gate failure, `blocked_no_active_compute`,
and PR #127 closed/parked wording.

## Consistency Audit

Pattern:

```sh
rg -n "ready to scale|source-specific.*covered|phylo.*partial support|next step is v1 retirement|Choose v1 retirement|live choice is v1 retirement|production fan-out is running" docs/dev-log/decisions docs/design/73-predictor-informed-latent-scores.md docs/dev-log/check-log.md /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/sweep.json
```

Result: no live promotion wording found. Remaining hits are quoted command
lines, guard text that explicitly says not to use "partial support", and
no-active phrasing such as "no production fan-out is running".

## GitHub Issue Maintenance

No issue or PR action taken. PR #127 remains closed/parked; no push or PR reopen
was authorized.

## What Did Not Go Smoothly

The first realized direct-slope aggregate looked superficially reassuring
(`96/100`), but it failed the predeclared strict no-miss gate. That means it is
diagnostic evidence only, not a promotion route.

## Team Learning

For phylo Model A, the useful uncertainty stack is not "always run the trio".
Use Wald for conditional `alpha_lv` display, reserve profile-LR for new-target
canaries, and retire bootstrap for the failed current route.

## Remaining Risks

- A future realized/conditional target may still be scientifically useful, but
  it changes the claim and needs a new ADEMP note before compute.
- The NotebookLM trio/video material was not available in this workspace; this
  closeout relies on local repo evidence and served Mission Control state.
- The gllvmTMB Dropbox checkout is dirty from broader work; only
  `status.json` and `sweep.json` were intentionally edited in this slice.

## Known Limitations

This task did not implement new phylo Model A support, expose R grammar, reopen
PR #127, or launch compute. It parks public source-specific phylo `lv` for v1.

## Next Command

```sh
rg -n "retired/parked|v1 parking|blocked_no_active_compute" /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - v1 parking is recorded and preview-backed; future
non-v1 reopening still needs a newly predeclared ADEMP target/gate.
