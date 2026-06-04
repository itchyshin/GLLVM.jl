# GLLVM.jl — R interface (via JuliaConnectoR)

A thin **R front end** to the fast Julia engine, so R users (the gllvm/ecology
community) can drive GLLVM.jl without leaving R — the same idea as the DRM.jl bridge.

> **Status: scaffold, not yet verified.** `gllvmjl.R` was written without an R or
> Julia runtime available, so it has **not been executed**. Treat it as a starting
> point and verify each function in a real R + Julia environment. Once the DRM.jl R
> bridge is available to mirror, parts of this can be aligned to its conventions.

## How it works

[`JuliaConnectoR`](https://github.com/stefan-m-lenz/JuliaConnectoR) starts a Julia
process and calls GLLVM.jl functions directly. R matrices marshal to Julia arrays
automatically; results come back through the package's **array/table-returning
accessors** (`coef_table`, `getLV`, `getLoadings`, `ordiplot`, `predict`,
`residuals`, `aic`, `bic`), which convert cleanly to R `data.frame`s / matrices.
The fit object itself stays an opaque Julia reference that you pass back in.

## Setup (once)

```r
install.packages("JuliaConnectoR")
```
Install GLLVM.jl in Julia (>= 1.10):
```julia
using Pkg; Pkg.add(url = "https://github.com/itchyshin/GLLVM.jl")
```

## Usage

```r
source("gllvmjl.R")
gllvm_jl_init()

Y   <- matrix(rpois(6 * 120, 3), nrow = 6)         # p species x n sites
fit <- gllvm_fit(Y, family = "poisson", K = 2)     # method = "va" for variational

gllvm_coeftable(fit, Y)                            # tidy inference table
lv  <- gllvm_getLV(fit, Y)                         # site scores (n x K)
ord <- gllvm_ordiplot(fit, Y)                      # biplot data

# ordination biplot in base R:
plot(ord$sites[, 1], ord$sites[, 2],
     xlab = sprintf("LV1 (%.1f%%)", 100 * ord$axis_prop[1]),
     ylab = sprintf("LV2 (%.1f%%)", 100 * ord$axis_prop[2]))
text(ord$sites[, 1], ord$sites[, 2], ord$site_labels, pos = 3, cex = 0.6)
arrows(0, 0, ord$species[, 1], ord$species[, 2], col = "red", length = 0.08)
```

## Supported families / methods

`gllvm_fit(..., family=, method=)`:
- families: `poisson`, `nb`, `binomial`, `beta`, `gamma`, `ordinal`, `gaussian`
- `method = "laplace"` (default) or `"va"` (variational; Poisson/NB/Binomial/Beta/Gamma)

## Verification checklist (for the maintainer)

- [ ] `gllvm_jl_init()` imports the module; `gllvm_fit` returns a usable fit ref.
- [ ] `juliaGet` field access on the returned NamedTuples/structs works as written
      (adjust if `coef_table`/`ordiplot` fields need `$` vs `juliaGet`).
- [ ] integer vs double `storage.mode(Y)` matches each family's `fit_*` signature.
- [ ] `predict`'s `type` Symbol marshaling (`juliaCall("Symbol", type)`) is correct.
- [ ] cross-check a fit's estimates/loglik against the same model fit directly in Julia.
