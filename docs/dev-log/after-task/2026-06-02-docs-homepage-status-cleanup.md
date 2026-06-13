# After Task: Documentation Homepage And Family Status Cleanup

## Goal

Audit and improve the GLLVM.jl documentation webpage after the homepage looked
messy, while comparing the page structure and status claims with the R twin's
gllvmTMB articles.

## Implemented

The homepage in `docs/src/index.md` now uses plain Documenter-compatible
Markdown instead of VitePress frontmatter. It opens with the scientific question,
states the current pilot boundary, gives a small Gaussian example, links to the
main articles, and explains the relationship to gllvmTMB without overclaiming.

The response-family, parity, roadmap, fit-workflow, README, and related article
links were brought into the same status vocabulary:

- one-part Laplace families are reached through `fit_gllvm(...; family=...)`;
- Delta-lognormal, Hurdle-Poisson, and Hurdle-NB use dedicated fitters;
- Delta-Gamma and zero-inflated families remain planned;
- non-Gaussian covariance-scale summaries and CIs remain limited unless a fit
  object documents support.

A second visual/prose audit then removed two homepage lookup tables, replacing
them with short lists; left-aligned the remaining technical tables; softened the
gllvmTMB comparison wording from "catch-up engine" to "Julia companion"; and
changed the zero-inflated parity row from in-progress to planned for this
branch.

A third gllvmTMB-style prose pass updated `quickstart.md`, `model.md`, and
README. Quickstart now starts with the same scientific question and an explicit
scope boundary; the model page uses `i` consistently for site/individual index;
README uses the same notation and no longer calls example data a fixture.

A final mobile pass compared the deployed phone views for GLLVM.jl and sister
site DRM.jl. The deployed GLLVM.jl page still rendered `layout: home`, `hero:`,
and `features:` as visible mobile text, while deployed DRM.jl opened with a
cleaner first screen. After maintainer review, the local GLLVM.jl homepage was
simplified further into a plain docs page: one identity sentence, install
immediately below it, then the first model. Status and gllvmTMB/benchmark detail
now sit lower on the page.

No `src/` code, exported symbol, likelihood parameterization, or public API
syntax changed.

## gllvmTMB Article Comparison

Ada asked Pat, Darwin, and Rose to compare the GLLVM.jl pages against the R
twin articles:

- `vignettes/gllvmTMB.Rmd` - reader-first opening and scope boundary.
- `vignettes/articles/morphometrics.Rmd` - applied example flow before
  implementation detail.
- `vignettes/articles/response-families.Rmd` - explicit supported vs planned
  family table.
- `vignettes/articles/covariance-correlation.Rmd` - extractor-oriented
  reference structure.
- `vignettes/articles/pitfalls.Rmd` - plain warnings about model and
  interpretation limits.

The useful pattern was not copied verbatim. It was ported as a Julia-first
landing flow: what question the package answers, what currently works, where
to start, and how the package relates to gllvmTMB.

## DRM.jl Mobile Comparison

The sister-site comparison used the deployed DRM.jl mobile page, not the dirty
local DRM.jl build. The local DRM.jl source branch still contains VitePress
home-page frontmatter that its local build rendered literally; the deployed
site was the cleaner reference.

The concrete mobile lessons carried back to GLLVM.jl were:

- keep the first screen plain and predictable;
- make install the first user action;
- put "Fit your first model" directly after install;
- move status, gllvmTMB comparison, and benchmark detail below the first
  workflow.

## Files Changed

- `README.md` - synchronized public status, installation, non-Gaussian support,
  and limitation wording.
- `docs/make.jl` - fixed the generated edit-link repository handle.
- `docs/src/index.md` - rebuilt the homepage as ordinary Documenter Markdown.
  The second pass also removed the homepage lookup tables that rendered as
  clutter on narrow pages. The final mobile pass reordered the page to match
  DRM.jl's deployed phone flow, then simplified it further to an install-first
  docs landing page.
- `docs/src/quickstart.md` - added the reader-first question and scope boundary.
- `docs/src/model.md` - added the Gaussian-engine scope boundary and fixed the
  overloaded site/species notation.
- `docs/src/response-families.md` - separated one-part unified support from
  dedicated two-part fitters and planned families.
- `docs/src/gllvmtmb-parity.md` - updated the R-parity status table to match
  currently wired support.
- `docs/src/roadmap.md` - moved the roadmap language from Gaussian-only pilot
  wording to the current non-Gaussian catch-up state.
- `docs/src/working-with-a-fit.md` - clarified Gaussian, one-part
  non-Gaussian, and two-part fitter coverage.
- `docs/src/morphometrics.md`, `docs/src/pitfalls.md`,
  `docs/src/covariance-correlation.md` - fixed internal article links.
- `docs/dev-log/check-log.md` - recorded this audit and verification.

## Tests Added

None. This was a documentation/status cleanup with no implementation change.

## Benchmark Numbers

N/A. No algorithm, likelihood, or performance path changed.

## R-Parity Verdict

N/A for computation. The R twin was used as a documentation comparator, not as
a numerical parity target. The public GLLVM.jl parity table now keeps wired,
dedicated, planned, and missing support separate.

## JET / Allocs / Aqua Verdicts

- JET: not run in full quality mode for this docs-only slice.
- Allocs: not applicable.
- Aqua: not run in full quality mode for this docs-only slice.

The quick core suite was run and reported the expected direct-environment
quality placeholders; `Pkg.test()` remains the command for the full Aqua/JET
gate.

## Checks Run

```sh
gh run list --limit 3
```

Result: PR #59 `CI` was still in progress; PR #59 `Documenter` had failed; the
latest `pages-build-deployment` run had succeeded. The failed Documenter log
showed invalid local link warnings before an npm `ECONNRESET`.

```sh
julia --project=docs docs/make.jl
```

Result: exit code 0. Documenter and DocumenterVitepress completed. The invalid
local-link warnings were gone. Remaining local warnings were deployment
auto-detection skipped, missing logo/favicon assets, missing `docs/package.json`,
and npm audit reporting 4 moderate vulnerabilities.

The docs build was rerun after the second visual/table pass:

```sh
julia --project=docs docs/make.jl
```

Result: exit code 0. The build completed with the same residual local warnings
only.

The docs build was rerun after the quickstart/model prose pass:

```sh
julia --project=docs docs/make.jl
```

Result: exit code 0. The build completed with the same residual local warnings
only.

The docs build was rerun after the DRM.jl mobile pass, after removing a
redundant divider, and after the install-first simplification:

```sh
julia --project=docs docs/make.jl
```

Result: exit code 0 each time. The build completed with the same residual
local warnings only.

Browser DOM checks were run against `docs/build/1` served locally:

- `/`: title `GLLVM.jl`, `h1` `GLLVM.jl`, no visible `layout: home`,
  `hero:`, or `features:` frontmatter text; edit link points to
  `https://github.com/itchyshin/GLLVM.jl/edit/main/docs/src/index.md`.
- `/response-families.html`: title `Response families | GLLVM.jl`, `h1`
  `Response families`, and the one-part/two-part/planned family boundaries are
  visible.

Playwright mobile checks were run with a 390 x 664 px phone viewport:

- `https://itchyshin.github.io/GLLVM.jl/` redirected to `/dev/` and still
  rendered the old `layout: home`, `hero:`, and `features:` text on mobile.
- `https://itchyshin.github.io/DRM.jl/` redirected to `/stable/` and rendered a
  clean mobile opening: title, compact identity paragraph, and "Fit your first
  model".
- `http://127.0.0.1:8123/` for the rebuilt local GLLVM.jl page had no rendered
  frontmatter, no horizontal overflow, `Install` visible at y=304, install code
  at y=377, "Fit your first model" visible at y=614, and the status block moved
  to y=2692.
- Screenshots were written under `/tmp/gllvm-mobile-audit/screens/`, including
  `gllvm_deployed_mobile.png`, `drm_deployed_mobile.png`, and
  `gllvm_local_mobile_final.png`, and `gllvm_local_mobile_simplified.png`.

```sh
julia --project=. test/runtests.jl
```

Result: exit code 0. The emitted summaries had 0 fail and 0 error. The run
retained 1 existing sparse-phy precision broken placeholder and 2 expected
quality placeholders in the direct core environment because Aqua and JET are
run under `Pkg.test()`.

```sh
git diff --check
```

Result: clean.

```sh
rg -n "\]\(/[^)]+\)|layout: home|hero:|features:|https://https://" docs/src docs/make.jl
```

Result: no matches.

```sh
rg -n "text-align:right" docs/build/1/index.html docs/build/1/response-families.html docs/build/1/gllvmtmb-parity.html docs/build/1/roadmap.html docs/build/.documenter/index.md docs/build/.documenter/response-families.md docs/build/.documenter/gllvmtmb-parity.md docs/build/.documenter/roadmap.md
```

Result: no matches on the touched rendered pages after the table-alignment
pass.

```sh
rg -n "Zero-inflated \(ZIP / ZINB\)" docs/src/gllvmtmb-parity.md docs/build/.documenter/gllvmtmb-parity.md
```

Result: both source and rendered markdown show zero-inflated support as planned
and not wired in this branch.

```sh
rg -n 'species `s`|site `s`|η_B\[s\]|ε\[:, s\]|fixture|R-side fixture|catch-up engine|Fast Gaussian|Gaussian Generalised|https://https://|layout: home|hero:|features:' README.md docs/src docs/make.jl
```

Result: no matches.

```sh
rg -n 'The first question|Scope|For site or individual `i`|y_i|Response families|Simulate data|Julia companion' docs/build/.documenter/quickstart.md docs/build/.documenter/model.md docs/build/.documenter/index.md
```

Result: rendered markdown contains the new question/scope/model-index wording.

```sh
rg -n "Gaussian family only|Gaussian only|10-100|Reverse-mode AD|Pkg.add\(\"GLLVM\"\)|not yet implemented|planned next|TODO|FIXME" README.md docs/src CLAUDE.md
```

Result: only the intentional negative installation sentence in `docs/src/index.md`
matched `Pkg.add("GLLVM")`.

```sh
gh pr list --limit 5 --json number,title,headRefName,isDraft,state,url
```

Result: PR #60 and PR #59 remain separate draft lanes; no GitHub issue or PR
was modified.

## Consistency Audit

The source audit removed the immediate page mess, fixed generated edit links,
and aligned README/docs language with currently wired non-Gaussian support. It
also avoided introducing a new gllvmTMB numerical parity claim. The mobile pass
confirmed that the local rebuilt first viewport is now a plain docs landing
page rather than a half-rendered landing page.

## GitHub Issue Maintenance

No issue action was taken. This was local documentation cleanup on the current
draft branch.

## What Did Not Go Smoothly

Browser screenshots timed out during the first visual QA pass because the audit
was not yet using a dedicated mobile viewport. A temporary Playwright install
under `/tmp/gllvm-mobile-audit` solved that without adding a repository
dependency. The upstream PR #59 Documenter failure also included npm
`ECONNRESET`, so this source cleanup fixes the stale link/frontmatter causes
but does not prove that future npm fetches cannot fail.

## Team Learning

Pat/Darwin: GLLVM.jl needs the same reader-first structure as gllvmTMB, but the
Julia site should start with installation and the currently wired API rather
than a long R-style vignette or hero-style marketing copy.

Rose: the old homepage and README were a claim-drift trap because the page
still read as Gaussian-only in some places while newer docs advertised
non-Gaussian families. Public status pages now need the one-part, dedicated
two-part, planned, and missing buckets kept separate.

## Remaining Risks

- Full `Pkg.test()` was not run for this docs-only slice.
- Local docs build still warns about missing logo/favicon assets, missing
  `docs/package.json`, and npm audit vulnerabilities.
- The deployed GLLVM.jl site still shows the old mobile frontmatter until this
  branch is published.
- The failed upstream Documenter run for PR #59 had a network failure component
  in addition to source warnings.

## Next Command

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Run this before pushing or claiming the full quality battery.

## Rose Verdict

Rose verdict: PASS WITH NOTES - the webpage source mess, homepage clutter,
broken internal links, bad edit link, right-aligned lookup tables, overloaded
model notation, internal fixture wording, and visible public status drift are
fixed and locally rendered; the mobile top is now install-first and screenshot
checked; full `Pkg.test()`, deployed-site publication, and residual docs
asset/npm warnings remain explicit notes.
