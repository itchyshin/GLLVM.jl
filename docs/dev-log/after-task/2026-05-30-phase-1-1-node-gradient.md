# After-task — Phase 1.1: O(p) node-frame gradient (correctness core)

**Date:** 2026-05-30
**Phase:** 1.1 (O(p) node-frame phylogenetic gradient promotion)
**Branch:** `op-node-gradient` (stacked on `phase-0-team-scaffolding`)
**Commit:** `017e52c`
**Author:** Ada/Opus orchestrator; Karpinski scout + codegen (Sonnet).
**Models used:** Sonnet (scout + codegen), Opus (sign/convention judgment calls,
wiring, verification). No Haiku this slice — no purely-mechanical sub-task arose.

## Goal

Promote the bench "★ winner" node-frame analytic gradient into the GLLVM engine
as `src/node_gradient.jl`, wired and exported, passing the correctness gates of
the Engine Quality Battery (Workflow Q): FD, cross-check vs the existing analytic
gradient, and BLUP-vs-dense — all to the documented tolerances.

## Implemented

- **`src/node_gradient.jl`** (NEW, ~375 lines): 6 public functions (`node_grad`,
  `grad_node_perspecies`, `build_node_perspecies`, `node_blups`,
  `node_dσ_phy_only`, `NodePerSpecies`) + 3 internal helpers. Ported from the
  bench prototype with bench scaffolding stripped; module-context headers only.
- **`src/GLLVM.jl`**: wired `include("sparse_phy_grad.jl")` (previously orphaned;
  self-includes `takahashi_selinv.jl`) then `include("node_gradient.jl")` into
  the sparse phylo block; exported the 6 public functions.
- **`test/test_node_gradient.jl`** (NEW, 58 assertions): module-based (no
  self-include — avoids the AugmentedPhy type split with other phylo tests).
- **Decisions** (`docs/dev-log/decisions/2026-05-30-node-gradient-5.4e-2-convention.md`).

## Checks run (Workflow Q — partial)

| Q check | Status | Evidence |
|---------|--------|----------|
| FD ≤ 1e-6 | ✅ | `node_grad` vs ForwardDiff of dense +loglik; balanced + caterpillar, p ∈ {8,12} |
| Cross-check ≤ 1e-8 | ✅ | `node_grad ≡ sparse_phy_grad`; ≈1e-13 observed; p ∈ {8,16,32} |
| Per-species FD ≤ 1e-6 | ✅ | `grad_node_perspecies` vs central FD of +negll (after sign fix) |
| BLUP ≤ 1e-8 | ✅ | `node_blups` û vs dense `Λ̃⁻¹ rhs` + tip-BLUP consistency |
| Multi-shape | ✅ (partial) | balanced + caterpillar to p=32 in tests; benchmark to p=2000 |
| Benchmark vs baseline | ✅ (zero-dep) | node_grad vs sparse_phy_grad: ratio 1.7× (p=100) → 6.3× (500) → 35.7× (p=2000). node_grad ~10–20 ms at p≤2000; sparse_phy_grad 477 ms at p=2000. Confirms ~O(p) vs ~O(p²). |
| **R-parity ≤ 1e-6** | ⏳ pending | needs RCall scaffold (Phase 1.0) |
| **JET (type stability)** | ⏳ pending | needs JET test-dep (folds into Phase 1.3 whole-engine sweep) |
| **Allocs (zero-alloc loop)** | ⏳ pending | needs AllocCheck/BenchmarkTools test-dep (Phase 1.3) |
| **Aqua (project hygiene)** | ⏳ pending | needs Aqua test-dep (Phase 1.3) |

**Full suite:** `julia --project=. test/runtests.jl` → exit 0, **491 pass**
(1 pre-existing Broken in sparse-phy), node-frame 58/58. No regressions.

## Decisions (Opus judgment calls)

1. **5.4e-2 branch-increment discrepancy = convention, not bug.** Gradient
   (1e-13 vs engine) and node BLUPs (8e-16 vs dense) are machine-precision; the
   5.4e-2 is confined to a node-frame-vs-edge-frame BLUP comparison we do not
   ship. No test gate for it; caveat on `node_blups`. Full rationale in the
   decisions doc.
2. **`grad_node_perspecies` returns ∂negll/∂σ_phy** (optimiser convention),
   the OPPOSITE sign to `node_grad`'s ∂loglik. The ported docstring and the
   test's FD target both inherited a wrong sign from the prototype's comment;
   the ~2.0 relerr was a clean sign flip, confirmed by the negll math
   (`½(trace − dataq) = ∂negll`). Fixed docstring + test; documented the
   cross-function convention difference loudly (footgun prevention for the
   Phase 1.4 fitter, which consumes the ∂negll sign).

## What did not go smoothly (process learning)

- **The standalone test pass was a FALSE GREEN.** `test/test_node_gradient.jl`
  passed 58/58 run alone, then errored 22× in the full suite: an `AugmentedPhy`
  type-identity split. Other wired phylo tests self-include `sparse_phy.jl` into
  Main (the orphan-era idiom), so mixing `GLLVM.augmented_phy` with self-included
  functions created two distinct `AugmentedPhy` types. Fix: make the test
  module-based (no self-include) now that the src files are wired. **Lesson: the
  full suite is the only valid green for a newly-wired test; never trust a
  standalone run for an integration verdict.** (Logged for the after-task skill.)
- The scout's plan assumed `sparse_phy_grad.jl` was already in the module; it
  was orphaned. Pre-reading `src/GLLVM.jl` caught this before wiring.

## Known limitations / next actions

- **Phase 1.0 (RCall parity scaffold)** — enables the R-parity Q check. Needs a
  dependency-isolation decision so RCall does not break the default suite
  (likely a dedicated `test/parity/Project.toml` or a guarded `try using RCall`).
- **Phase 1.3 (perf hardening)** — set up JET/Allocs/Aqua/BenchmarkTools test
  deps and run the whole-engine sweep; this also closes the pending Q checks for
  this slice. Integrate Takahashi O(p) selected-inverse into `sparse_phy_grad`.
- `node_dσ_phy` is K_aug==1 only (phylo_unique); ArgumentError-guarded.
- CHOLMOD Float64-only: `node_grad` is evaluation-only for ForwardDiff (FD
  target uses a separate dense path). Documented in the source header.
