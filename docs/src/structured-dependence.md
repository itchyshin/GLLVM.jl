# Structured dependence: phylogenetic, animal-model, and spatial

The Gaussian GLLVM marginal likelihood accepts any p × p positive-definite
covariance matrix via the `Σ_phy` keyword. The three use cases below are
mathematically the same structure (the `J3` likelihood path in `likelihood.jl`);
only the origin of `Σ_phy` differs.

## The common model

Let `y` be a p × n matrix of continuous traits (or outcomes) measured on
`p` entities (species, individuals, sites) at `n` occasions (sites, visits).
The Gaussian GLLVM with a structured random effect is:

```
y[t, s] = (Λ_B η_s)[t] + (Λ_phy aug) φ)[t] + ε[t, s]
```

where:

- `Λ_B` (p × K) are the unit-tier loadings estimated freely,
- `η_s ~ N(0, I_K)` are independent site-level latent variables,
- `Λ_phy` (p × K_phy) and/or per-trait SDs `σ_phy` (length p) capture structured dependence,
- `φ ~ MVN(0, Σ_phy)` once (shared across all sites),
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

`vcv` returns a VCV matrix on the identity scale; the result is the
Hadfield & Nakagawa (2010) phylogenetic mixed model.

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

### Retrieving the heritability-analogue

After fitting, the per-trait phylogenetic signal (fraction of variance explained
by the structured effect) is available via `phylo_signal`:

```julia
h2 = phylo_signal(fit)   # length-p vector; same formula as H² in phylo context
```

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

## When to use each representation

| Use case                                           | `Σ_phy` source                             |
|----------------------------------------------------|---------------------------------------------|
| Species traits with shared evolutionary history    | Phylogenetic VCV from tree (`vcv`)          |
| Individual-level data with known pedigree          | NRM from pedigree tools (`kinship2`, `nadiv`) |
| Individual-level genomic data                      | GRM from marker tools (`rrBLUP`, PLINK)    |
| Spatially structured community or landscape data   | `spatial_cov(coords; ...)`                 |

In all cases, pass the result as `Σ_phy` to `fit_gaussian_gllvm`. The
`has_phy_unique = true` flag activates per-trait structured SDs (`σ_phy`);
`K_phy` activates structured latent axes (`Λ_phy`). Both can be used together.
