# Structured dependence: phylogenetic, animal-model, and spatial

This page covers two Gaussian covariance models that are easy to confuse. Pick
the axis on which the covariance is defined before choosing a fitter.

| Covariance is among | Response layout and guide |
|---|---|
| Response rows | `Y`: entities × occasions; [row model](#row-structured-model) |
| Source groups | `Y`: traits × units; [source model](#fixed-source-groups) |

Use `fit_gaussian_gllvm` for the row model and `fit_gaussian_sources` for the
source-group model. In the latter, a projection maps source groups to the
observed units in the columns of `Y`.

The first model accepts any p × p positive-definite covariance through
`Σ_phy`; phylogenetic, animal-model, and spatial examples differ only in where
that row covariance comes from. The fixed-source model uses one or more known
source-node covariances projected onto observed units. Transposing `Y`, a
covariance matrix, or a similarly named argument does not make the models
equivalent.

## [The common model](@id row-structured-model)

Let `y` be a p × n matrix of continuous traits (or outcomes) measured on
`p` entities (species, individuals, sites) at `n` occasions (sites, visits).
The Gaussian GLLVM with a structured random effect is:

```
y[:, s] = Λ_B η_s + u + ε[:, s]
```

where:

- `Λ_B` (p × K) are the unit-tier loadings estimated freely,
- `η_s ~ N(0, I_K)` are independent site-level latent variables,
- `Λ_phy` (p × K_phy) and/or per-trait SDs `σ_phy` (length p) capture structured dependence,
- `u ~ MVN(0, B)` is drawn once and shared across all columns,
- `ε[t, s] ~ N(0, σ²_eps)` is the residual.

The marginal covariance of `vec(y)` is `I_n ⊗ A + J_n ⊗ B` where

- `A = Λ_B Λ_B' + σ²_eps I_p` (site covariance),
- `B = (Λ_phy_aug Λ_phy_aug') .* Σ_phy` (structured between-site block).

Two p × p Cholesky factorisations handle this regardless of `n`.

> **Dense path only.** The fast O(p) sparse path (`likelihood_sparse_phy.jl`,
> `sparse_phy.jl`) exploits tree structure and is not applicable here. The
> standard dense Gaussian path is used for all three cases below.

---

## 1. Phylogenetic (tree covariance)

Build `Σ_phy` from a phylogenetic tree using `PhyloNetworks`, `Phylo`, or any
package that returns a variance-covariance matrix on the tips.

```julia
using GLLVM, PhyloNetworks     # PhyloNetworks not in GLLVM.jl deps; install separately

tree    = readTopology("my_tree.tre")
Σ_phy   = vcv(tree)            # p × p tip covariance
y       = ...                  # p × n trait matrix

fit = fit_gaussian_gllvm(y;
    K              = 2,
    has_phy_unique = true,
    Σ_phy          = Σ_phy)
```

The tree-tip ordering must match the rows of `y`. This specifies a particular
row-structured Gaussian model; a tree covariance alone does not establish
equivalence to a multivariate phylogenetic model with separate grouping levels.

---

## 2. Animal model (pedigree / genomic relatedness)

The animal model (Henderson 1984) uses a relatedness or genomic relationship
matrix (GRM / NRM) as `Σ_phy`. Compute `A` from your pedigree or markers
using external tools (e.g. `kinship2`, `nadiv`, `rrBLUP`, PLINK `--make-grm`,
`AGHmatrix`), then pass it through `relatedness_cov` for validation.

```julia
using GLLVM

# A is a precomputed p × p relatedness / GRM matrix (from your pedigree tool)
A      = ...
Σ_rel  = relatedness_cov(A)           # symmetrize + small jitter for SPD

fit = fit_gaussian_gllvm(y;
    K              = 2,
    has_phy_unique = true,
    Σ_phy          = Σ_rel)
```

`relatedness_cov` does NOT parse pedigrees or compute GRMs from raw markers.
Supply a precomputed matrix.

### Retrieving the structured variance fraction

After fitting, the per-trait phylogenetic signal (fraction of variance explained
by the structured effect) is available via `phylo_signal`:

```julia
fraction = phylo_signal(fit)   # length-p vector for this fitted model
```

Interpreting this quantity as heritability requires a compatible genetic design
and variance decomposition; a relatedness matrix alone does not establish that.

---

## 3. Spatial dependence (coordinates)

Build `Σ_phy` from p × d location coordinates using `spatial_cov`. Three
kernel families are supported:

| Kernel        | Formula                                     | Notes                        |
|---------------|---------------------------------------------|------------------------------|
| `:exponential`| `sill * exp(-d / range)`                    | Matérn ν = 0.5               |
| `:gaussian`   | `sill * exp(-(d / range)²)`                 | Over-smooth, use with care   |
| `:matern`     | Matérn with smoothness ν (default ν = 1.5)  | ν = 0.5 → exponential (verified) |

```julia
using GLLVM

# coords is a p × 2 (or p × d) matrix of spatial coordinates
coords  = ...
Σ_sp    = spatial_cov(coords;
              kernel     = :matern,
              range      = 100.0,   # in coordinate units
              smoothness = 1.5,
              sill       = 1.0,
              nugget     = 1e-6)

fit = fit_gaussian_gllvm(y;
    K              = 2,
    has_phy_unique = true,
    Σ_phy          = Σ_sp)
```

A non-zero `nugget` is added to the diagonal and is required for
positive-definiteness when two locations are identical or very close.

---

## Function reference

See [`spatial_cov`](@ref) and [`relatedness_cov`](@ref) for the full signatures.

---

## Row-structured representations

| Use case                                           | `Σ_phy` source                             |
|----------------------------------------------------|---------------------------------------------|
| Species traits with shared evolutionary history    | Phylogenetic VCV from tree (`vcv`)          |
| Individual-level data with known pedigree          | NRM from pedigree tools (`kinship2`, `nadiv`) |
| Individual-level genomic data                      | GRM from marker tools (`rrBLUP`, PLINK)    |
| Spatially structured community or landscape data   | `spatial_cov(coords; ...)`                 |

In these row-structured models, pass the result as `Σ_phy` to `fit_gaussian_gllvm`.
The ordering and dimension must match the rows, not arbitrary observation groups. The
`has_phy_unique = true` flag activates per-trait structured SDs (`σ_phy`);
`K_phy` activates structured latent axes (`Λ_phy`). Both can be used together.

## [Fixed covariance among source groups](@id fixed-source-groups)

The retained evidence includes six paired public-R/native fixed-source Gaussian
fits and targeted unit checks. It does **not** establish broad parity,
calibration or recovery, nor does it cover formula or bridge interfaces. In a
retained `unique=true` case, near-zero curvature also means the current evidence
does not support a reliable uncertainty claim. The worked example below is a
deterministic analytic check, not a recovery simulation.

Here `Y` is traits × observed units. Each [`SourceCovariance`](@ref) supplies a
known SPD covariance `C` on source nodes and a units × nodes projection `P`.
Integer `groups` constructs a one-hot projection: each observed unit is assigned
to one source node. A source node may be unobserved, and sources can have
different numbers of nodes. The exact covariance is

```math
\operatorname{Cov}(\operatorname{vec}(Y)) =
\sigma_\varepsilon^2 I + \sum_r (P_r C_r P_r^\top) \otimes B_r.
```

The projection turns source-node covariance into unit covariance: `P` has one
row per observed unit and one column per source node, so `P*C*P'` is units ×
units. Its partner `B` is traits × traits. `mode=:latent` gives `B` a low-rank
loading structure (rank one by default); `:indep` gives each trait an
independent source variance; and `:dep` estimates a full lower-triangular
loading matrix. `unique=true` adds a trait-diagonal term only to a latent
source. `common=true` ties independent variances, or a latent source's unique
diagonal; it does not turn independent fields into one shared field. No jitter
or loading ridge is added, and trait intercepts are optimized jointly with the
covariance.

```@example fixed_sources
using GLLVM, LinearAlgebra
groups = repeat(1:4; inner=3)
group_means = [-1.5, -0.5, 0.5, 1.5]
within = [-0.2, 0.0, 0.2]
observations = [
    0.7 + group_means[g] + within[j]
    for g in 1:4 for j in 1:3
]
Y = reshape(observations, 1, :)
C = Matrix{Float64}(I, 4, 4)
source = SourceCovariance(C;
    groups, name=:group, mode=:indep)
fit = fit_gaussian_sources(Y;
    sources=[source], g_tol=1e-7)
@assert fit.converged && fit.gradient_norm <= 1e-7 # hide
@assert isapprox(coef(fit)[1], 0.7; atol=1e-6) # hide
@assert isapprox(fit.sigma_eps^2, 0.04; atol=1e-6) # hide
@assert isapprox(only(fit.trait_covariances)[1, 1], 1.25 - 0.04 / 3; atol=1e-6) # hide
estimates = (
    intercept=only(coef(fit)),
    residual_variance=fit.sigma_eps^2,
    group_variance=
        only(fit.trait_covariances)[1, 1],
)
for (name, value) in pairs(estimates)
    println(name, ": ", round(value; digits=4))
end
println("status: ", fit.stopping_reason)
```

For this balanced four-group construction, the displayed intercept is `0.7`,
the residual variance is `0.04`, and the group-level trait variance is
`1.25 - 0.04 / 3`. These are analytic values from the deterministic construction:
they show how the output is read, not that the estimator recovers parameters in
general data.

When residual noise is specified independently, pass its standard deviation
explicitly. It remains fixed; `start`, `parameters` and `dof` then omit that
coordinate. The default continues to estimate residual noise.

```@example fixed_sources
fixed_noise = fit_gaussian_sources(
    Y; sources=[source],
    sigma_eps_fixed=0.2,
    g_tol=1e-7,
)
@assert fixed_noise.residual_fixed && fixed_noise.sigma_eps == 0.2 # hide
@assert fixed_noise.converged && fixed_noise.gradient_norm <= 1e-7 # hide
@assert dof(fixed_noise) == 2 # hide
println(
    "fixed residual SD: ",
    fixed_noise.sigma_eps,
)
println(
    "free parameters: ",
    dof(fixed_noise),
)
```

This option can represent reference models with fixed residual variance. It
does not infer the noise from data or resolve variance identification by itself.
Gradients and Hessians cover free coordinates only.

[`GaussianSourcesFit`](@ref) retains normalized likelihood, source snapshots,
optimizer coordinates, stopping reason, fresh gradient norm and Hessian
diagnostics. A positive Hessian does not prove identification or recovery;
near-zero curvature for the retained unique-`Ψ` case is specifically why no
uncertainty interpretation should be attached to this result.

This layer requires complete finite Gaussian responses, at least two units and
variation in at least one trait when residual noise is estimated. With positive
fixed residual noise, constant responses are also admitted. It uses dense factorization over **all response
cells**: quadratic memory and cubic factorization cost. Keep initial examples
small. It does not parse trees, pedigrees or meshes; estimate source kernels;
fit slopes or loading masks; handle missing or non-Gaussian responses; provide
formula/bridge routes, new-unit prediction, or confidence intervals. For a
new analysis, first decide whether the covariance belongs to rows or source
groups, then start with a small fixed, complete Gaussian example and inspect
the convergence and gradient diagnostics before extending the model.

```@docs
SourceCovariance
GaussianSourcesFit
```
