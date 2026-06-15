# Full-Finish Roadmap: GLLVM.jl + gllvmTMB

Date: 2026-06-14

## Mission

Finish the R-Julia twin: `GLLVM.jl` as the Julia engine and `gllvmTMB` as the
R user surface. The target is not "engine exists somewhere." The target is that
R users can fit, inspect, infer, visualize, and trust the supported models
through `engine = "julia"`.

Live local board: `http://127.0.0.1:8770/`

## Operating Rule

A capability is done only when engine support, R bridge support, point
estimates, objective/logLik, CI or CI-status, docs/articles, visual evidence,
tests, issue ledger, and Rose audit agree.

## Phase Order

1. **Rehydrate, merge gates, and current truth.**
   Record current branches, heads, dirty state, PRs, issues, and CI. Hold #95
   until maintainer approval; audit #94 before closure; rebuild the gllvmTMB
   bridge branch from current main.
2. **Mission-control dashboard.**
   Keep `http://127.0.0.1:8770/` live. Data source is `.claude/preview/status.json`,
   `.claude/preview/sweep.json`, and `.claude/preview/version.txt`. The board
   must warn on dirty/detached state and stale build data.
3. **Issue-led claim governance.**
   Every roadmap row gets an owning issue, claim boundary, tests, dashboard
   status, and after-task path. Broad stale issues close only after successors
   exist.
4. **Capability and bridge matrix.**
   Use `covered`, `partial`, `experimental`, `planned`, and `unsupported`.
   No "full capability" claim may bypass the matrix.
5. **Core robustness before breadth.**
   #96 mode-finder safeguards and #92 phylo-signal CI scale/export/test are
   fixed locally on this branch and await issue/PR reconciliation. #91
   high-rate Poisson divergence and the Gamma analytic-gradient recheck remain
   open.
6. **R-Julia bridge contract and gate drift.**
   `GLLVM.bridge_fit` now exists on the active GLLVM surface for the minimal
   no-covariate one-part route. Next enforce live `gllvmTMB` roundtrips, flat
   ASCII-safe payloads, no fragile Unicode field access, deliberate rejection
   tests, `confint.gllvmTMB_julia()`, and post-fit methods.
7. **Missing values and incomplete data.**
   Mask data terms only, preserve latent and structural priors, support or
   deliberately reject response/predictor/mixed missingness, and make
   missingness visible.
8. **Mixed and cross-family models.**
   Implement per-response family dispatch. Homogeneous vectors must equal
   single-family fits exactly before mixed-family support is promoted.
9. **Random slopes.**
   Add family-by-family and structure-by-structure support; do not make blanket
   random-slope claims.
10. **Structural dependencies.**
    Phylo, animal/relmat, spatial/SPDE, kernel, and coevolution each need
    engine, bridge, CI, article, visual, and simulation status.
11. **Speedups with robust inference.**
    Exact implicit gradients, Takahashi selected inverse, observed-information
    methods, profile endpoint acceleration, bootstrap/profile batching, and AD
    allocation cleanup. No speed claim without point estimates and CI/status.
12. **Articles and visual aids.**
    Each major user-facing capability gets a concrete article and at least one
    figure or diagnostic table.
13. **Cross-team visits.**
    DRM/drmTMB supplies bridge-drift, interval-status, profile-boundary, and
    missing-response lessons. HSquared/hsquared supplies validation-status,
    capability-matrix, and AI-REML boundary discipline.
14. **ADEMP, parity, and comparator gates.**
    StableRNG recovery tests, explicit ADEMP blocks, R-Julia parity, comparator
    mapping, and coverage gates before calibration claims.
15. **Big simulation and power program.**
    Runs only after small parity/recovery gates are stable. Reports must include
    usable-CI denominators.
16. **Release.**
    `Pkg.test()`, docs build, optional R parity, `devtools::test()`, live bridge
    tests, `rcmdcheck --as-cran`, pkgdown, issue cleanup, changelog/news,
    dashboard freeze, and final Rose audit.

## First Concrete Work Order

1. Update the dashboard at `http://127.0.0.1:8770/` to JSON-backed mission
   control.
2. Create the master capability/bridge matrix.
3. Write/update issues for each phase and slice.
4. Settle GLLVM #95 and audit #94.
5. Repair the `gllvmTMB` bridge branch from current `origin/main`.
6. Fix GLLVM #91. GLLVM #96 and #92 are locally fixed and need issue/PR
   reconciliation.
7. Bring `bridge_fit` into the active GLLVM branch and prove primitive payload
   parity. First narrow no-X route passed 175/175 on 2026-06-14; X,
   missingness, mixed families, and live R roundtrip remain follow-up slices.
8. Implement bridge gate-vs-engine guard for `gllvmTMB#488`.
9. Start missing-response mask bridge.
10. Start speed+CI benchmark protocol.
11. Begin article and visual inventory.

## Current Slice

The current slice implemented items 1 and 2 locally, then added the first
minimal `bridge_fit` route for no-covariate one-part families. It deliberately
does not merge PRs, mutate GitHub issues, push branches, tag releases, or claim
the full R bridge is complete.
