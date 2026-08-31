# Core070 Gaussian source bindings

Frozen R source: gllvmTMB commit `b4d5fee64def88bc768dda1f1f77c29b295edd86`.
The concrete helper is `tools/core070_gaussian_source_bindings.jl`. It maps six
captured *nonspatial* prepared R calls to the candidate
`GLLVM.SourceCovariance` / `GLLVM.fit_gaussian_sources` surface. Its fixture
data, source-node order, and starts are source-pinned. It performs no work on
`include`; constructors and sparse precision inversion happen only when
`core070_gaussian_source_binding(id)` is explicitly called.

```julia
using GLLVM, LinearAlgebra
include("tools/core070_gaussian_source_bindings.jl")
binding = core070_gaussian_source_binding("STRUCT-PHY-TREE-RR")
fit = GLLVM.fit_gaussian_sources(binding.Y;
    sources = binding.sources, start = binding.start)
```

The final two lines document the actual candidate call and are intentionally
not run by the helper or by this binding slice.

| Captured ID | R source form | Candidate source specification | Candidate start after trait means |
|---|---|---|---|
| `STRUCT-PHY-TREE-RR` | `phylo_latent(..., tree=tree, d=1)` | `:phylo_tree_rr`, `mode=:latent, rank=1`; `inv(Qtree)` over ordered nodes `(internal,a,b,c)`, with observations `(a,b,c)` mapped to Julia nodes `(2,3,4)` | raw loading `(0.5,0,0)`, residual `-0.39432656302578389` |
| `STRUCT-PHY-DENSE-RR` | `phylo_latent(..., vcv=C, d=1)` | `:phylo_dense_rr`, `mode=:latent, rank=1`; `C + 1e-8I` over the three ordered tips | raw loading `(0.5,0,0)`, residual `-0.39432656302578389` |
| `STRUCT-PHY-TREE-PROPTO` | deprecated `phylo_scalar(..., tree=tree)` | `:phylo_tree_propto`, `mode=:indep, common=true`; tip correlation `[[1,.5,0],[.5,1,0],[0,0,1]] + 1e-8I` | common logSD `0 = loglambda_phy / 2`, residual `-0.39432656302578389` |
| `STRUCT-ANI-PED-SPARSE` | `animal_latent(..., pedigree=ped, d=1, unique=FALSE)` | `:animal_pedigree_sparse`, `mode=:latent, rank=1`; `inv(Qped)` retains the two unobserved founders and maps observations to nodes `(3,4)` | raw loading `(0.5,0,0)`, residual `-0.39432656302578389` |
| `STRUCT-KER-SINGLE-PSI` | `kernel_latent(K=C, d=1, name="k1", unique=TRUE)` | `:kernel_single_psi`, `mode=:latent, rank=1, unique=true`; `C + 1e-8I` | raw loading `(0.5,0,0)`, unique logSDs `(0,0,0)`, residual `-0.39432656302578389` |
| `STRUCT-KER-MULTI` | named `kernel_latent(K=C,...) + kernel_latent(K=K2,...)` | `:kernel_k1` and `:kernel_k2`, both `mode=:latent, rank=1`; separate `C + 1e-8I` and `K2 + 1e-8I` | raw loadings `(0.5,0,0)` then `(0.5,0,0)`, residual `-0.39432656302578389` |

Every start begins with the retained trait means
`(0.57804248168973249, 0.34689924315484166, 0.29137546026000255)`. Each
captured `log_sigma_eps` has exactly one free coordinate. `SourceCovariance`
uses raw packed lower loadings for rank-one terms, matching the retained
`theta_rr_phy`/`theta_rr_kernel` coordinates; they are never transformed into
log diagonal loadings. The propto conversion is the only scale conversion:
the R parameter is a log variance while the candidate common independent term
uses a logSD.

## Checked preparation facts

The helper reconstructs `Y` from the retained long `y`, `trait_id`, and
`site_id` vectors. It requires 36 rows, 0-based traits `0:2`, 0-based sites
`0:11`, rejects duplicate cells, and rejects incomplete cells before returning
the resulting `3 × 12` matrix. At explicit helper call time it also asserts
each source projection has the required `12 × n_nodes` one-hot shape and that
the start-vector layout is 7, 7, 5, 7, 10, or 10 coordinates in the table's
case order. It preserves the R long-row source-node order:
four rows per tip for tree/dense/kernel cases and six rows per observed animal
for the pedigree case. The sparse tree and pedigree paths retain unobserved
ancestors; no dense jitter is added there. Dense and kernel covariances each
receive their retained single `1e-8I` regularization exactly once.

Source pins: `R/phylo-tree-precision.R:198` and `R/fit-multi.R:3794` for the
tree precision/projection; `R/pedigree-precision.R` and `R/fit-multi.R:3820`
for the pedigree precision/projection; `R/fit-multi.R` propto preparation and
`src/gllvmTMB.cpp` propto prior for the log-variance convention; and
`R/fit-multi.R:3620` plus `src/gllvmTMB.cpp` for named-kernel offsets. The
local retained evidence is `.unlazy/core070-aghq/structured-input-03/export.json`;
the interpretation and matrix contract are
`docs/dev-log/core070/structured-input-contract.md`.

## Boundaries that remain unpaid

This helper is source preparation only; it performs no optimization. The
parent candidate passed46source-model and71binding unit checks on2026-08-31
(gaussian-sources-numerical-tests.json). Those unit tests alone do not establish fitted parity. A later paired
public-R/native run passed all six retained fixtures; see
`gaussian-source-pair-evidence.json` for source pins, fit health and numerical
differences. The unique-variance case has nearly zero curvature; no interval
or calibration claim follows. Wider fitted native parity, formula support,
bridge support, parser obligations, inference, and all spatial cases remain
UNPAID. In particular, free-kappa spatial work and the retained 24-case
inventory are outside this six-case nonspatial binding and remain intact.

Requested helper implementation context: Terra/high. Runtime input checks and
source-model unit receipts are owned by the parent validation slice; paired
R-model fitting is a separate leaf (gaussian-source-pair-leaf.md).
