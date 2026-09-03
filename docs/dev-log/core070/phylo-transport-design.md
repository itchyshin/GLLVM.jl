# Phylo transport design: covariance-vs-precision conversion across the R↔Julia bridge

**Status: DESIGN FOR REVIEW — no code.** Maintainer decision round2-3 #7: phylo
transport is the next engine track; this doc resolves the C↔Q conversion risk
that kept `animal_*`/`phylo_*` deliberately deferred all programme. All R
citations are to the frozen 0.7.0 readback under
`.unlazy/core070-aghq/oracle-source/readback/R/`; Julia citations to `src/`.

---

## 1. Inventory: what each side actually consumes

### 1.1 R (gllvmTMB 0.7.0 frozen readback)

Three user input forms, all canonicalised by `fit-multi.R` into ONE internal
object — a **sparse augmented precision** `Ainv_phy_rr` plus
`log_det_A_phy_rr`, `n_aug_phy`, `species_aug_id`:

| Input | Keyword arg | Conversion R performs internally |
|---|---|---|
| `ape::phylo` tree | `phylo_*(…, tree=)` (in-keyword; outer `phylo_tree=` deprecated, `gllvmTMB.R:861-881`) | `.gllvm_phylo_tree_precision()` (`phylo-tree-precision.R:183-249`): builds sparse augmented A⁻¹ directly from topology (Hadfield–Nakagawa; 1/edge_length rules, L210-222). **No inversion ever.** |
| Sparse `Ainv` / sparse `vcv=` | `animal_*(…, Ainv=)`, or pedigree via `pedigree_to_Ainv_sparse()` (`animal-keyword.R:575-620` → Henderson/Quaas assembly `pedigree-precision.R:156-215`) | Used **directly** as precision (`fit-multi.R:3814-3841`). If it includes unphenotyped ancestors, the FULL precision is kept and tips mapped in — "subsetting a precision would condition on the dropped nodes, not marginalize them" (`fit-multi.R:3826-3829`). Validation: rownames coverage (`.resolve_sparse_phylo_precision`, `fit-multi.R:637-680`). |
| Dense `vcv=` C or dense `A` | `phylo_scalar(…, vcv=Cphy)`, `animal_*(…, A=)` | **The only C→Q inversion in R**: `Aphy + diag(1e-8)` jitter then dense `solve()` (`fit-multi.R:3843-3852`); dense `Ainv=` input is inverted back to A first (`.gllvmTMB_maybe_keep_sparse_ainv`, `animal-keyword.R:631-633`). Tip-only (`n_aug_phy = n_species`, identity aug map). |

Key R conventions:

- **Ultrametric gate + unit-height scaling.** `correlation = TRUE` (the fit
  path default, `fit-multi.R:3810`) requires ultrametricity within
  `sqrt(eps)·scale` (`phylo-tree-precision.R:140-146`) and multiplies the
  precision by `scale = height` (`phylo-tree-precision.R:223,227`), i.e. the
  correlation form of C (unit root-to-tip); σ²_phy absorbs the raw scale.
  `log_det_precision = n_aug·log(scale) − Σ log(edge_length)`
  (`phylo-tree-precision.R:240`).
- **Root excluded, tips last.** Augmented nodes are ordered internal-first,
  tips-last, root dropped (`phylo-tree-precision.R:203-204`), so
  `n_aug = 2p − 2` and the precision is full rank. Tips-last matches
  `MCMCglmm::inverseA` so the sparse-Cholesky trajectory is a drop-in
  (`phylo-tree-precision.R:197-202`).
- **No diag-normalization of A** on the pedigree path: A is Henderson raw
  (diag = 1 + F, `animal-keyword.R:489-496`); the tree path's height scaling
  is the only normalization.
- Harvest/agreement rules for per-term `tree=`/`vcv=` overrides:
  `fit-multi.R:3492-3549`; a supplied tree with no consuming term aborts
  (`fit-multi.R:3777-3793`).

### 1.2 GLLVM.jl native representations (all topology-consuming)

| Representation | Consumes | Convention |
|---|---|---|
| `AugmentedPhy` (`src/sparse_phy.jl:65-73`) | Newick string (`augmented_phy`, L222) or **edge list** `(parent, child, length)` (`make_phy`, L317-357) | `Q_topology` over `n_total = 2p − 1` nodes, **root INCLUDED**, raw branch lengths, PSD rank 2p−2; the root row is deleted at likelihood time (`Q_cond = Q_topology[keep, keep]`, `likelihood_sparse_phy.jl:198`). **No height scaling, no ultrametric gate.** |
| `FelsensteinContrasts` (`src/phylo_contrasts.jl:71,98,130`) | tree / Newick | contrasts transform of C; topology only |
| `EdgePhy` (`src/edge_incidence.jl:39,185`) | Newick | matrix-free Q = B·W·Bᵀ; per-branch rates on diag(W) |

Fit entries take `AugmentedPhy` or Newick (`fit_phylo.jl:118,166-167`).
**Nothing in Julia consumes a dense C, a labeled sparse precision, or a
pedigree** — every path derives Q from topology. `src/bridge.jl` has zero
phylo payload slots today (confirmed: no phylo/tree mentions).

## 2. The conversion question, precisely

Where must a covariance C become a precision Q, or vice versa?

1. **Tree input (the common case): nowhere.** Both engines build Q directly
   from topology by the same 1/edge_length rules. No inversion exists on
   this path on either side. What differs is *convention*, not direction:
   (a) **scale** — R ships the correlation form (×height); Julia ships raw
   branch lengths ⇒ σ²_phy estimates differ by exactly `height` unless
   aligned — this is the feared **silent scale drift**, and it is silent
   because logLik at the *joint* optimum can still match while the variance
   estimand does not; (b) **root handling** — R drops the root at build time
   (n_aug = 2p−2), Julia at likelihood time (n_total = 2p−1) — the fitted
   model is identical (internal nodes marginalised) but log-det bookkeeping
   and node maps differ by one row; (c) **node ordering** — R internal-first
   tips-last, Julia leaves-first (`make_phy` convention, `sparse_phy.jl:352`).
2. **Pedigree / sparse Ainv input (animal): still nowhere.** Henderson/Quaas
   assembles the precision directly (`pedigree-precision.R:182-207`);
   inverting it to C would densify an O(1/n)-sparse matrix. The safe
   direction is *precision stays precision*; Julia needs a consumer for a
   labeled sparse Q it did not derive itself, not a converter.
3. **Dense `vcv=`/`A=` input: the only genuine C→Q.** R already does it
   (jitter 1e-8 + dense solve, `fit-multi.R:3846-3850`), O(p³) and
   conditioning-fragile for near-singular C (star phylogenies, duplicated
   tips, highly inbred pedigrees). This is what the deferral feared. It must
   not be duplicated: doing the same inversion independently on both sides
   with different jitter/ordering yields two *different* Q's from one C.

### Candidate resolutions

- **(a) Topology-first transport** — pass the tree (edge list + tip labels +
  scale), never any matrix; both sides build Q. Covers the tree path
  perfectly (`make_phy` already accepts exactly this shape) but **cannot
  cover** `animal_*(Ainv=)` or dense `vcv=` — there is no topology to pass.
- **(b) C→Q sparse via pedigree/tree structure** — re-derive Q on the Julia
  side from pedigree rules. Duplicates Henderson/Quaas + the validators in a
  second language; two implementations of one canonicalisation is the exact
  drift generator the programme's oracle discipline exists to avoid.
- **(c) Dense fallback with conditioning guards** — needed only where R
  itself already goes dense; adding a *second* dense inversion in Julia
  doubles the fragile step.

### Recommendation: **hybrid — "topology stays native, precision crosses the wire"**

R already canonicalises *all three* input forms into one bundle
(`Ainv_phy_rr`, `log_det_A_phy_rr`, `n_aug_phy`, `species_aug_id`,
`fit-multi.R:3796-3860`). Therefore:

1. **Bridge wire format = R's canonical precision bundle**: sparse triplets
   `(i, j, x)` of `Ainv_phy_rr`, node labels, `log_det_A_phy_rr`, the
   0-indexed `species_aug_id` map, and the `scale` (height) actually applied.
   **No inversion ever crosses or is introduced by the bridge**; the only
   C→Q that exists remains R's existing, receipted dense fallback, executed
   once, on one side. Scale drift is killed by shipping `scale` and
   `log_det` explicitly and asserting Julia's recomputed log-det against the
   shipped value (a free per-fit checksum).
2. **Julia gains a `PrecisionPhy` consumer** (new small struct: labeled
   sparse Q + log-det + tip map) feeding the same likelihood kernel as
   `AugmentedPhy` post-root-deletion. This is additive; the three native
   topology representations are untouched.
3. **Native Julia users keep topology-first** (`augmented_phy`/`make_phy`),
   gaining an opt-in `correlation = true` unit-height mode + ultrametric
   check to match R's estimand convention (§1.1).

Justification: option (a) alone strands the animal/Ainv rows that motivated
the track; (b) re-implements a validated oracle; the hybrid transports what
each object already *is* — trees as trees where both engines have builders,
precisions as precisions where only R has the builder — and makes the
dangerous direction (dense C→Q) happen exactly once, in the engine that
already owns it.

## 3. Parity-check design

**Quantities that pair** (matched Gaussian `phylo_latent` model first):

| Pair | Tolerance class (campaign precedent, `delta-matched-contract.md:17`) |
|---|---|
| logLik at matched fixed parameters (transport check, pre-optimisation) | rtol 1e-6; objective re-evaluation 1e-8 |
| log-det checksum: Julia-recomputed vs shipped `log_det_A_phy_rr` | abs 1e-8 (same matrix, same arithmetic class) |
| logLik at each engine's own optimum | rtol 1e-6 |
| σ²_phy / Λ_phy point estimates (scale-aligned) | rtol 1e-4 (optimizer class) |
| H² phylogenetic signal — estimand now fixed to R's convention (denominator includes σ²_phy; `src/confint_derived.jl:292-330` ↔ `profile-derived.R:145-156`; commit 75e325e7) | abs 1e-4 |

**Proven-fixture sketch**: one seeded 8-tip ultrametric balanced tree
(explicit Newick literal in the fixture, height ≠ 1 so scale drift cannot
hide) + the 12-individual pedigree from `animal-keyword.R:63-67` examples
(2 founder pairs, so F > 0 exercises the Mendelian-variance branch of
`pedigree-precision.R:187-195`). StableRNGs seed; fixture emits both the R
bundle (via the frozen readback functions) and the raw inputs.

**Cross-check within Julia** (Workflow Q check 2): `PrecisionPhy` logLik ==
`AugmentedPhy` logLik ≤ 1e-8 when the precision bundle was built from the
same tree with `correlation = false`, after aligning root/ordering.

## 4. Implementation slices (in order, red-first)

1. **S1 — Julia `PrecisionPhy` consumer.** Red test: build R-convention
   precision (root-dropped, tips-last, height-scaled) for the 8-tip fixture
   by hand; assert `gaussian_marginal_loglik` through the new consumer equals
   the `AugmentedPhy` path ≤ 1e-8 after scale alignment. No bridge yet.
2. **S2 — scale-convention alignment on the native tree path.** Add
   `correlation::Bool` (+ ultrametric check mirroring
   `phylo-tree-precision.R:140-146`) to `augmented_phy`/`make_phy`. Red test:
   unit-height rescale changes σ²_phy by exactly `height`, logLik invariant.
3. **S3 — bridge payload + R gate lift.** Extend the `bridge_fit` descriptor
   with the precision bundle of §2; on the R side add a `phylo_rr` arm beside
   the `rr` handling and lift `GJL-GATE-STRUCTURED-TERMS`
   (`julia-bridge.R` ~L3578-3589) for phylo/animal/kernel kinds only. Red
   test: the six receipted refusal cases become fits. **Converts 3 of the 13
   R-ADAPTER-BLOCKED cells** (`bridge-coverage-matrix.md:56-58`; case ids
   `FIT-MODE-ANIMAL-{INDEP,COMMON,DEP}` + `FIT-MODE-KERNEL-{INDEP,COMMON,DEP}`
   from `covariance-required-case-plan.json` — kernel rides the same
   `phylo_rr` rewrite, `brms-sugar.R:3293`).
4. **S4 — paired parity leaf.** §3 table against the proven fixture, signed
   evidence JSON per campaign format. Gaussian first; then the receipted
   bridge families (Poisson/Beta/NB2) × phylo via the existing
   `phylo_*_xlv.jl` kernels.
5. **S5 (later) — `phylo_slope`, mi-phylo covariate model, and the
   ORD-DEP-style upstream defect** stay out of scope (the latter is a 0.7.1
   R-lane item, `bridge-coverage-matrix.md:80`).

## 5. Open questions — genuinely the maintainer's

1. **Estimand convention for native Julia fits**: should `correlation = true`
   (R's unit-height σ²_phy) become the Julia *default* in S2, a breaking
   change for existing native users, or opt-in with the bridge always
   setting it? (Parity forces it on bridge fits either way.)
2. **Dense `vcv=` admission**: admit R's dense-solve path over the bridge in
   S3 (it produces the same bundle), or gate it behind a condition-number
   guard first? R today jitters silently at 1e-8 (`fit-multi.R:3847`).
3. **Kernel scope**: kernel_* shares the `phylo_rr` rewrite but carries
   `.cross_kernel_rho` extras (`fit-multi.R:3527-3549`) — bundle into S3 or
   split to its own slice?
4. **Non-ultrametric trees** (`correlation = FALSE` in R exists but the fit
   path hard-codes TRUE): support now or defer with a named gate?

**Recommendation recap**: hybrid transport — trees pass as topology (edge
list into `make_phy`), everything else passes as R's already-canonical
sparse precision bundle with explicit `scale` and `log_det` checksums;
Julia adds a `PrecisionPhy` consumer and a unit-height mode; no new
inversion anywhere.
