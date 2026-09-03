# Remaining structured-source preparation cases

Noether source review, requested Terra/high via fresh read-only tiered CLI,
2026-08-31. Original result and dispatch receipt retained at
`.unlazy/core070-aghq/structured-source-review/`. These are source-grounded
next cases, not executed results or an exhaustive frozen manifest. Read actual
source at b4d5fee64def88bc768dda1f1f77c29b295edd86 before assigning native work.

| Proposed case | Public reference term | Distinct preparation to verify |
|---|---|---|
| PHY_TREE_RR | phylo_latent(species,d=1,tree=tree) | augmented sparse tree precision, tip mapping |
| PHY_DENSE_RR | phylo_latent(species,d=1,vcv=C) | dense tip-only matrix plus1e-8I |
| PHY_TREE_PROPTO | phylo_scalar(species,tree=tree) | tree marginalized to tip covariance, propto engine |
| ANI_PED_SPARSE | animal_latent(animal,d=1,pedigree=ped,unique=FALSE) | full sparse pedigree precision, observed subset |
| KER_SINGLE_PSI | kernel_latent(species,K=K1,d=1,name="k1",unique=TRUE) | single kernel with folded diagonal companion |
| KER_MULTI | two kernel_latent terms with distinct names | separate tier ranks/offsets, g_kernel arrays |
| SPA_INDEP | spatial_indep(0+trait\|coords,mesh=mesh) | per-trait omega_spde/log_tau_spde |
| SPA_LATENT | spatial_latent(0+trait\|coords,d=1,mesh=mesh,unique=FALSE) | shared fields, per-trait block mapped off |
| SPA_LATENT_PSI | same with unique=TRUE | shared plus per-trait spatial fields |
| SPA_DEP | spatial_dep(0+trait\|coords,mesh=mesh) | full-rank latent path, dependent-specific exclusions |
| SPA_COMMON_MAP | spatial_indep(...,common=TRUE,mesh=mesh) | tied tau map; separate from new native branch |

Suggested deterministic tree: ape::read.tree(text="((a:1,b:1):1,c:2);").
Public fitting requires ultrametric positive branches and correlation scaling;
internal correlation=FALSE is not automatically a public fitting obligation.
Source: R/phylo-tree-precision.R:71 and R/fit-multi.R:3794.

Suggested pedigree: a,b founders; c,d offspring of a,b; observe c,d only.
Capture full sparse precision and observed-to-full map. Every named parent
must exist; duplicate IDs and cycles reject. Sparse Ainv is an adapter to this
branch; dense Ainv becomes a dense covariance path. Do not infer all adapters
are tested from one pedigree success. Source: R/brms-sugar.R:2563 and
R/fit-multi.R:3820. Dense matrices and tree precision have different jitter
paths, so exact source equivalence must be measured rather than asserted.

Multiple named kernels require top-level cluster grouping, one latent term per
tier, rank<=p, finite symmetric PSD matrices. Dependent multi-kernel and explicit
Psi combinations reject. Auto-Psi from unique=TRUE is pruned for multiple names
in the frozen source; capture warnings and actual maps explicitly before
classifying the route. Similar kernels can confound component separation.
Source: R/fit-multi.R:1121 and3620. This source review alone is not a claim
that the requested unique-variance model is preserved.

Suggested spatial qualification: four square sites repeated over two traits;
make_mesh on the exact final long data with x/y coordinates, cutoff=.25.
Mesh construction/runtime prerequisites must first be qualified on Totoro;
do not use an arbitrary tiny mesh for numerical evidence. Formula coords is a
placeholder; FEM matrices and row-aligned projection come from the wrapper.
Raw mesh input and mismatched projection row count reject. Source:
R/mesh.R:318, R/fit-multi.R:4010, src/gllvmTMB.cpp:2182.

Next leaf must freeze exact calls, inputs, negative controls and expected maps
before execution. These admitted reference models belong in the approved Core
contract, subject to actual fitting admission; lack of current Julia evidence
does not justify excluding them. Numerical identification, native interfaces,
family/mode crossings and inference remain separately required.
