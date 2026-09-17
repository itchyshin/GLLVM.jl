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

## Rose note

Narrow CI serialization only. It does not make any paste-gated PR mergeable by itself, and it does
not change any true-parity claim.
