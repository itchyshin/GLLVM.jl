# After-task - Vitepress dead-link cleanup

## Goal

Remove the hard Vitepress dead-link blocker found while validating the
high-rate Poisson safeguard branch.

## Files Changed

- `docs/src/index.md`
- `docs/src/quickstart.md`
- `docs/src/comparison.md`
- `docs/src/gllvmtmb-parity.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-14-high-rate-poisson-safeguard.md`

## What Changed

The docs source mixed relative page links such as `benchmarks.md` with the
absolute Vitepress route style used elsewhere, such as `/benchmarks`. In the
local no-deploy build, DocumenterVitepress rendered the relative links as
extensionless relative routes (`./benchmarks`, `./model`, and similar), and
Vitepress failed the build with 13 dead links. The affected relative links were
normalised to the existing absolute route style.

## Checks Run

The direct docs command is still not a valid local gate on this checkout because
`docs/Project.toml` expects registered package `GLLVM`:

```sh
/Users/z3437171/.juliaup/bin/julia --project=docs docs/make.jl
```

Result: failed before build with `expected package GLLVM [2dc8e01c] to be
registered`.

The no-deploy docs validation was run from a temporary environment that
developed the local package and wrote build output under `/tmp`:

```sh
/Users/z3437171/.juliaup/bin/julia --startup-file=no -e 'using Pkg; Pkg.activate(; temp=true); Pkg.develop(PackageSpec(path=pwd())); Pkg.add(["Documenter", "DocumenterVitepress"]); using Documenter, DocumenterVitepress, GLLVM; makedocs(; sitename="GLLVM.jl", authors="Shinichi Nakagawa", modules=[GLLVM], source="docs/src", format=MarkdownVitepress(repo="github.com/itchyshin/GLLVM.jl", devbranch="main", devurl="dev"), build="/tmp/gllvm-docs-build", pages=[...], warnonly=true)'
```

Result: passed; Vitepress built the site successfully in `4.66s`.

## Remaining Warnings

The successful build still reports Documenter warnings for absolute local links
(`/quickstart`, `/api`, and similar), plus optional DocumenterVitepress warnings
for missing local Vitepress customisation files, logo/favicon assets, and
`docs/package.json`. These warnings pre-date this cleanup and should be handled
as a separate documentation-infrastructure slice.

## R-Parity Verdict

N/A - documentation link cleanup only.

## JET / Allocs / Aqua Verdict

N/A - documentation link cleanup only.

## Rose Verdict

PASS WITH NOTES. The hard Vitepress dead-link blocker is removed; remaining
docs warnings are real but belong to a separate docs-infrastructure cleanup.

## Next Command

```sh
rg -n "\\]\\(/(quickstart|model|benchmarks|comparison|working-with-a-fit|response-families|gllvmtmb-parity|roadmap|api|pitfalls|covariance-correlation|confidence-intervals|structured-dependence)" docs/src
```
