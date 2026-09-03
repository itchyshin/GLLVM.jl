# Real-workflow acceptance lessons — from the DRM.jl ↔ drmTMB cross-engine validation

Source: Ayumi Mizuno's independent validation of DRM.jl through drmTMB's
`engine="julia"` bridge (Ayumi-495/LS_ecogeographical-rules#29 and the #28
validation report, 2026). The DRM twin is the same architecture as our bridge;
every failure class below is a standing risk for gllvmTMB `engine="julia"` and
becomes a required acceptance case for the M2 parity claim. Harness parity
(fixture fits agreeing to 1e-8) missed ALL of these — they only appear when a
real user runs real data through the documented workflow.

## The eight failure classes (each -> an acceptance case)

1. **Non-interactive session gate.** DRM's bridge aborted under `Rscript`
   because the CRAN-check safety gate classified ordinary batch sessions as the
   CRAN lane; the documented setup did not mention the opt-out variable.
   ACCEPTANCE: `ACC-BRIDGE-RSCRIPT` — a documented-setup-only `engine="julia"`
   fit must succeed via `Rscript` with no undocumented environment variable.
2. **Data-shape strictness the R engine does not have.** DRM.jl required a
   strictly binary phylogeny; real canonical trees carry ~200 polytomies, and
   the user had to build a `multi2di + epsilon` workaround tree.
   ACCEPTANCE: `ACC-DATA-POLYTOMY` — feed a genuinely multifurcating tree (and
   other real-data shapes: unbalanced, missing cells) through the bridge; the
   Julia side must either handle it or reject it with a documented, actionable
   error — never require an undocumented preprocessing ritual.
3. **String/serialization fragility.** Tip labels containing spaces broke the
   bridge. ACCEPTANCE: `ACC-DATA-LABELS` — species/site names with spaces,
   unicode, and R-syntactic-invalid identifiers round-trip correctly.
4. **Coefficient-name translation.** Transformed terms (e.g. `I(temp_z^2)`)
   returned bridge names needing manual matching. ACCEPTANCE:
   `ACC-NAME-TRANSLATION` — every coefficient in an R-formula fit maps to the
   R-side name exactly, including transformed and interaction terms.
5. **Optimizer/control asymmetry.** TMB's `robust` preset had no Julia
   equivalent through the bridge; formal comparisons carried an uncontrolled
   difference. ACCEPTANCE: `ACC-CONTROL-SYMMETRY` — every documented gllvmTMB
   control that affects the fit either maps through the bridge or is rejected
   loudly with the difference documented.
6. **Diagnostics not exposed.** Julia's gradient was not returned through the
   bridge, so convergence health could not be compared engine-to-engine. Our
   OWN latent-bare receipt already shows this gap: `public_r_bridge.
   gradient_max = null`. ACCEPTANCE: `ACC-BRIDGE-GRADIENT` — the bridge fit
   object exposes the Julia gradient max / convergence health on the same
   basis as the native fit.
7. **Computational-feasibility cliffs.** Whole-tree Profile CI through the
   bridge ran >2h without result while TMB completed; a claimed capability
   that is computationally impractical at production scale is not a paid
   capability. ACCEPTANCE: `ACC-SCALE-FEASIBILITY` — time-box bridge CI/
   post-fit paths at a realistic production scale and record measured times,
   not assumptions.
8. **Wrong claimed limits, in both directions.** A suspected 5,000-species
   limit turned out not to exist (sparse dispatch worked at N=10,970).
   Claimed limits must be measured: an overstated limit wrongly steers users
   away; an understated one breaks them. ACCEPTANCE: `ACC-CLAIMED-LIMITS` —
   every documented size/shape limit carries a measurement receipt.

## Standing rule this file encodes

A parity claim for `engine="julia"` requires, beyond the frozen-fixture
harness: at least one real-dataset workflow per qualified family/structure run
end-to-end exactly as a user would (Rscript, documented setup, real data
shapes, R-side extractor names), with failures classified into the eight
classes above. Fixture parity + these acceptance cases = true parity;
fixture parity alone is harness parity and must not be presented as more.

## Target real-data workflows (maintainer-supplied, 2026-09-01)

- Ayumi-495/avian_trait_scales
- Ayumi-495/urbanisation_map
- Ayumi-495/nest_morpho_gllvm
- Ayumi-495/BIRDBASE_pcm

Recon maps each repo's gllvm-class models (family, dependence structure, data
shape) onto the bridge coverage matrix; runnable-today cells become the first
`engine="julia"` real-data acceptance runs, blocked cells attach to their
named blocker (R adapter gate vs Julia gap vs data-shape class above).
