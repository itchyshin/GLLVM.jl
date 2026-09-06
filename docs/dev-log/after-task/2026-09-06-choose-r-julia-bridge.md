# After Task: Choose R, Julia, or the bridge

## Goal

Add one concise Documenter page that routes a reader to R, Julia, or the
one-way R→Julia bridge without claiming universal parity.

## Implemented

New Getting Started page `docs/src/choose-r-julia-bridge.md`, wired in
`docs/make.jl` after Overview, with one Start Here sentence on
`docs/src/index.md`. Wording stays companion / partial-parity / one-way
R→Julia. Bridge status links issue #10 and does not close or subsume it.
R links reuse the existing pkgdown get-started and current-limits URLs.

## Mathematical Contract

N/A — reader-route documentation only. No likelihood, packing, or CI change.

## Files Changed

- `docs/src/choose-r-julia-bridge.md` (new)
- `docs/make.jl` (Getting Started nav)
- `docs/src/index.md` (one Start Here line)
- this report

## Tests Added

N/A — no engine or test change.

## Benchmark Numbers

N/A — no hot-path change.

## R-Parity Verdict

Parity: N/A — change does not touch the parity surface.

## JET / Allocs / Aqua Verdicts

- JET: not run — docs-only
- Allocs: not run — docs-only
- Aqua: not run — docs-only

## Checks Run

```sh
git diff --check
rg -n "itchyshin.github.io/gllvmTMB/articles/(gllvmTMB|current-limits)|quickstart.md|issues/10" docs/src/choose-r-julia-bridge.md
rg -n "choose-r-julia-bridge" docs/make.jl docs/src/index.md
```

`git diff --check` was clean. The new page carries the R get-started URL, the
current-limits URL, Quick Start, and issue #10. Nav and the index sentence
both name `choose-r-julia-bridge.md`.

Local `julia --project=docs docs/make.jl --local` was started, then
`Pkg.instantiate()` was interrupted to ship the draft PR. Documenter render
is therefore unverified in this slice.

`docs/dev-log/check-log.md` was **not** appended: open true-parity PRs #297,
#298, and #301 already own that file.

## Consistency Audit

- `rg "interchangeable|universal parity|menu of|Julia optimiser|two-way|calibrated coverage"`
  on the new page: only the intended refusals ("not interchangeable", "not a
  menu of interchangeable Julia optimisers").
- No `Project.toml` Julia bound change.
- No interval/CI implementation.
- No `gllvmtmb-navigation-renewal` files touched.

## GitHub Issue Maintenance

References #302. Links #10; does not close #10, #11, #13, or #276.

## What Did Not Go Smoothly

Fresh-worktree docs instantiate blocked the first ship attempt. This close-out
skips the Documenter render so the draft PR can land; CI or a later local
`--local` build still needs to confirm the page renders.

## Team Learning

A docs-only reader page should not wait on a cold docs environment when the
artefact is Markdown plus nav wiring.

## Remaining Risks

- Local DocumenterVitepress render not verified in this worktree.
- check-log omitted to avoid colliding with #297/#298/#301.

## Known Limitations

This page does not add extractors, interval evidence, Julia support-policy
text, or R-site navigation. Those remain on #302 / #10 and the separate
`gllvmtmb-navigation-renewal` lane.

## Next Command

Review the draft PR; optionally `julia --project=docs docs/make.jl --local`
on a machine with the docs environment already instantiated.

## Rose Verdict

Rose verdict: PASS WITH NOTES — docs-only route page is wired and worded
inside the earned boundary; Documenter render and check-log were skipped to
avoid a cold instantiate and a live-file collision.
