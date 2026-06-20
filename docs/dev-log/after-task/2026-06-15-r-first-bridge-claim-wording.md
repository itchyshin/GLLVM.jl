# After Task: R-First Bridge Claim Wording Cleanup

## Goal

Align the Julia integration checkout with the maintainer's R-first priority:
`gllvmTMB` is the user surface and evidence gate, while `GLLVM.jl` supplies
targeted engine routes that are promoted row by row.

## Files Changed

- `README.md`
- `CLAUDE.md`
- `CHANGELOG.md`
- `docs/src/changelog.md`
- `docs/src/gllvmtmb-parity.md`
- `src/bridge.jl`
- `test/test_bridge_capabilities.jl`
- `docs/dev-log/check-log.md`

## Implementation

- Removed blanket "full GLM", "gllvmTMB parity and beyond", "surpassed", and
  "full Wald/profile/bootstrap" wording from visible status surfaces touched by
  this slice.
- Clarified that CI columns in `GLLVM.bridge_capabilities()` describe native
  no-X route availability, not complete R bridge parity.
- Changed current bridge rows from `status = "supported"` to `status = "partial"`.
- Added test coverage for the partial-status vocabulary and explanatory notes.

## Verification

```sh
rg -n "full GLM|gllvmTMB parity|parity and beyond|surpassed|full Wald|status = \"supported\"|must be supported" README.md CLAUDE.md CHANGELOG.md src/bridge.jl test/test_bridge_capabilities.jl docs/src -S
```

Only the intended caveat remains in `docs/src/gllvmtmb-parity.md`.

```sh
~/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: `20/20 pass`.

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" /usr/local/bin/Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'
```

Result in `/Users/z3437171/Dropbox/Github Local/gllvmTMB`: `FAIL 0 | WARN 0 |
SKIP 0 | PASS 552` in `68.0s`.

```sh
tmp=$(mktemp -d); JULIA_PROJECT="$tmp" ~/.juliaup/bin/julia --startup-file=no -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.add(["Documenter", "DocumenterVitepress"]); include("docs/make.jl")'
```

Result: exit code 0. Known residual warnings remain: absolute local links,
optional Vitepress assets, npm audit warnings, and chunk-size warnings.

```sh
git diff --check
```

Result: clean.

## R-Parity Verdict

The live `gllvmTMB` Julia bridge test passes against this integration checkout.
No new parity row is claimed; this slice narrows claim vocabulary so `gllvmTMB`
can remain the public admission gate.

## Rose Verdict

PASS WITH NOTES. The overclaiming language is removed from the touched public
surfaces and the bridge metadata now uses partial status. Broader stale-claim
audits still belong in the issue-led matrix, especially before tagging.

## Remaining Risks

- Direct `julia --project=docs docs/make.jl` remains blocked until the docs
  environment handles unregistered local `GLLVM`; the temporary developed-env
  build is the local workaround.
- This does not add a new R bridge feature; the next R-first feature slice should
  be selected from the `gllvmTMB` issue ledger.

## Next Command

```sh
git status --short --branch
```
