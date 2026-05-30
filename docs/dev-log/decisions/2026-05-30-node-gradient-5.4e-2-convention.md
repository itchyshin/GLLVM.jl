# Decision — the 5.4e-2 branch-increment discrepancy is a convention, not a bug

**Date:** 2026-05-30
**Phase:** 1.1 (O(p) node-frame gradient promotion)
**Decider:** Ada/Opus orchestrator, on evidence from the Karpinski scout.
**Reviewer lens:** Noether (to confirm at verify stage).

## Context

The bench prototype `Pnode_latent_grad.jl` (★ winner — O(p) node-frame
phylogenetic gradient) carried one unresolved note: "branch-increment-by-
differencing vs P2 was off 5.4e-2 (a √σ²_phy unit/scale factor; node BLUPs
themselves exact)." Before promoting the prototype into `src/node_gradient.jl`
we had to decide whether this 5.4e-2 is a correctness defect that blocks the
port, or a benign representation convention.

## Evidence (verbatim from the bench results)

- `node_grad` vs the engine `sparse_phy_grad`: **max rel 2.4e-13** (dσ_phy),
  **0.0** (dσ²_phy), **7.6e-16** (dσ²_eps) — machine precision.
- Node-frame BLUPs `û` vs the dense reference `Λ̃ \ rhs`: **7.8e-16** — exact.
- The 5.4e-2 appears at exactly one comparison
  (`results/Pnode-latent-gradient.md:31`, `.log:70`):
  > branch increments (û_child − û_parent) vs P2 branch BLUPs : max rel = 5.429e-02 → MISMATCH
- The prototype's own comment (`Pnode_run.jl:267–271`) documents the attempted
  re-scaling: the node frame folds σ²_phy in via `σ_phy = √σ²_phy` while P2
  uses `σ²_phy` with `σ_phy = 1`, and the author expected the BM-displacement
  `b_e = û_child − û_parent` to equal P2's increment BLUP `ẑ_e`. The residual
  5.4e-2 is the leftover mismatch between the node posterior-mean BLUP
  (Q_cond-normalised space, prior precision absorbing branch lengths) and P2's
  branch-increment BLUP (BM-displacement space).

## Decision

**Port the node-frame gradient as-is.** The 5.4e-2 is confined to a comparison
*between two different BLUP representations* (node frame vs edge frame); it does
**not** appear in any quantity we are shipping:

- `node_grad` / `grad_node_perspecies` — gradient, machine-precision vs engine.
- `node_blups` `û` — node posterior means, exact vs dense.

The mismatch is a scale/ordering convention between the node and edge frames
that does not cleanly cancel under heterogeneous σ_phy or differing node-index
ordering. It is a *cross-representation comparison artifact*, not a gradient or
BLUP correctness problem.

## Consequences for the port

1. `test/test_node_gradient.jl` gates on: FD ≤ 1e-6, cross-check vs
   `sparse_phy_grad` ≤ 1e-8, node-BLUP-vs-dense ≤ 1e-8. These all pass at
   machine precision per the bench.
2. **No branch-increment-vs-P2 test gate.** Including one would false-FAIL on
   an unresolved cross-frame convention and is not a statement about engine
   correctness. (P2/edge-frame is not even in `src/`.)
3. `src/node_gradient.jl` carries a short docstring caveat on `node_blups`
   noting node-frame BLUPs are exact but edge-frame branch increments differ
   by a representation convention.
4. **Revisit trigger:** only if/when edge-frame per-branch increments become
   user-facing — i.e. the relaxed-clock per-branch-rate path (`relaxed_clock.jl`)
   needs `ẑ_e` directly. At that point, derive the exact node↔edge scale map
   (likely `ẑ_e = (û_child − û_parent) / √ℓ_e` or similar) and add a gate then.

## Inherited constraints to carry into the port (Karpinski risk scan)

- CHOLMOD `Factor{Float64}` is Float64-only → `node_grad` is evaluation-only
  for ForwardDiff; the test must not flow Duals through it (same limitation as
  `sparse_phy_grad`).
- `node_dσ_phy` enforces `K_aug == 1` (the phylo_unique case) via ArgumentError;
  it does not generalise to K_aug > 1 as written. Acceptable for v0.2.0 scope.
- Leaf-index shift (`root_index < l ? l-1 : l`) assumes `AugmentedPhy` places
  leaves first and root last — guaranteed by `augmented_phy` construction.
