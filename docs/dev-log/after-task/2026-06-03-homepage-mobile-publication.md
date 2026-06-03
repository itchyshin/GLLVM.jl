# After Task: Homepage Mobile Publication

## Goal

Publish the homepage fix that removes rendered frontmatter from the mobile
GLLVM.jl landing page.

## Implemented

`docs/src/index.md` now uses ordinary Documenter Markdown instead of VitePress
home-page frontmatter. The page opens with one direct identity sentence, then
the install command, then the first Gaussian model example. `docs/make.jl` also
uses the repository handle form expected by DocumenterVitepress edit links.

No `src/` code, exported symbol, likelihood parameterization, or public API
syntax changed.

## Files Changed

- `docs/src/index.md` - removed rendered frontmatter and switched the top of
  the page to install-first docs flow.
- `docs/make.jl` - fixed the generated edit-link repository handle.
- `docs/dev-log/check-log.md` - recorded the publication checks.
- `docs/dev-log/after-task/2026-06-03-homepage-mobile-publication.md` -
  recorded this closure audit.

## Tests Added

None. This was a documentation publication hotfix.

## Benchmark Numbers

N/A - no algorithm or performance path changed.

## R-Parity Verdict

N/A - no likelihood, fitter, or parity surface changed.

## JET / Allocs / Aqua Verdicts

- JET: not run; docs-only hotfix.
- Allocs: not applicable.
- Aqua: not run; docs-only hotfix.

## Checks Run

```sh
julia --project=docs docs/make.jl
```

Result: exit code 0 before publication. Residual warnings remain: pre-existing
absolute local links in several article pages (`/quickstart`, `/api`, etc.),
missing logo/favicon assets, missing `docs/package.json`, and npm audit
reporting 4 moderate vulnerabilities.

Mobile rendered check at 390 x 664 px against the local build:

- no rendered `layout: home`, `hero:`, or `features:` text;
- no horizontal overflow;
- install appears before the first model;
- screenshot written to
  `/tmp/gllvm-mobile-audit/screens/gllvm_local_mobile_simplified.png`.

```sh
git diff --check
rg -n 'layout: home|hero:|features:|https://https://' docs/src docs/make.jl
rg -n 'Fast Generalised Linear Latent Variable Models|Install|Fit your first model|What works today' docs/build/.documenter/index.md docs/build/1/index.html
```

Result: whitespace clean; public source scan clean; rendered index confirms the
install-first page order.

## Remaining Risks

- Full `Pkg.test()` was not run because this did not touch package code.
- The live website updates only after the GitHub Documenter deployment
  workflow completes.
- Existing article-link, docs asset, and package warnings remain.

## Next Command

```sh
gh run list --limit 5
```

Use this to confirm the publish/deploy workflow state.

## Rose Verdict

Rose verdict: PASS WITH NOTES - homepage source bug fixed and mobile screenshot
verified; full package tests were not run for this docs-only hotfix and
pre-existing article-link warnings remain outside this narrow patch.
