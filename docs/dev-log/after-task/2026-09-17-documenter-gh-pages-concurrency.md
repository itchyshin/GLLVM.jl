# Documenter gh-pages concurrency

Date: 2026-09-17
Branch: `ci/documenter-gh-pages-concurrency-20260917`
Base: `origin/main` @ `1c492486f`

## Scope

Fix the Documenter deploy race that made concurrent PR docs jobs fail while pushing to `gh-pages`.

Not changed: paste-gated harness PRs #399, #409, #410, #411; `Project.toml`; R `gllvmTMB` engine code; paste-packet tip churn.

## Finding

Failed Documenter runs `35148351157` and `35148337444` both built PR previews, then failed at:

```text
! [rejected] HEAD -> gh-pages (fetch first)
error: failed to push some refs to 'https://github.com/itchyshin/GLLVM.jl.git'
```

`docs/make.jl` calls `DocumenterVitepress.deploydocs(..., branch = "gh-pages", push_preview = true)`.
The workflow ran on every PR with no concurrency guard, so independent jobs could fetch the same
`gh-pages` tip and then race to push different preview commits.

## Change

Added a workflow-level `documenter-gh-pages` concurrency group to `.github/workflows/Documenter.yml`
with `cancel-in-progress: false`. This queues all Documenter deploys that write the shared branch
instead of cancelling main evidence or letting PR previews race.

## Checks

- Lane preflight run before editing; initial `.github/` lease conflict waited out, then a narrow
  lease was granted for `.github/workflows/Documenter.yml`, `docs/dev-log/check-log.md`, and
  `docs/dev-log/after-task`.
- `gh run list --workflow Documenter.yml --limit 80` used to locate failed deploy runs.
- `gh run view 35148351157 --log` and `gh run view 35148337444 --log` confirmed the
  non-fast-forward `gh-pages` push failure.
- Local docs rebuild not run: this is workflow scheduling only, not docs source or Documenter content.
- PR #424 CI: Documenter passed and `documenter/deploy` reported the preview URL. CI was rerun once
  for failed jobs; both Julia shard-1 jobs still failed in Aqua `Persistent tasks` with
  `Unable to locate ChainRulesCore` under dependencies of `LogExpFunctions` / `SpecialFunctions`.
  The merge gate refused: `NOT MERGED: #424 has 3 check(s) that settled non-green`.

## Follow-up: Aqua 0.8.17 resolver drift

The shard-1 failures were not caused by the Documenter concurrency change. The PR diff was limited to
`.github/workflows/Documenter.yml` plus this dev-log note and `check-log.md`, while the failing Julia
jobs errored inside `test/test_quality.jl` when `Aqua.test_all(GLLVM; ambiguities = false)` reached
the `Persistent tasks` subcheck.

Main CI run `35097722925` was green with `SpecialFunctions v2.9.0`, `LogExpFunctions v0.3.29`, and
`Aqua v0.8.16`. PR run `35266715435` resolved the same package versions for
`SpecialFunctions` / `LogExpFunctions` but floated Aqua to `v0.8.17`; both Julia 1.10 and Julia 1
shard-1 jobs then errored with `Unable to locate ChainRulesCore`.

Local probe with a floating resolver and `Aqua v0.8.17` reproduced the class of failure: adding the
first missing weak dependency moved the error from `ChainRulesCore` to `ChangesOfVariables`, then to
`DensityInterface`. A manifest scan found 58 absent weak dependencies, so adding weakdeps one by one
would turn a hygiene-tool bug into broad test-environment bloat.

Fix: pin the test-only Aqua dependency to exact `0.8.16` in `test/Project.toml`. This does not change
the package runtime dependency set, `Project.toml`, the package version, likelihood code, or any
gllvmTMB reference code, and it keeps the Aqua persistent-task subcheck enabled.

## Rose note

Narrow CI serialization only. It does not make any paste-gated PR mergeable by itself, and it does
not change any true-parity claim.
