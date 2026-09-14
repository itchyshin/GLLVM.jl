# kernel × indep — Gaussian matrix fitter (per-trait variances on fixed dense K).
#
# Twin estimand (Identity 2026-09-14; pin gllvmTMB kernel_indep roxygen b4d5fee6):
# marginal-only dense-kernel trait variances on a user-supplied between-unit matrix K,
# phylo-equivalent to phylo_indep(..., vcv = K) on the twin dense path (Design 65 C1).
# Reuses fit_gaussian_sources / SourceCovariance mode :indep — not the J3 Σ_phy block.
# No @formula kernel_indep() sugar (formula recognizer exists separately).

"""
    fit_kernel_indep_gllvm(Y, K, groups; name = :kernel, common = false, kwargs...)

Standalone **kernel × indep** Gaussian fit: separate trait variances (`mode = :indep`)
on a fixed dense between-unit covariance matrix `K`, with units projected via
one-based `groups` indices into the rows/columns of `K`.

Same estimand class as twin `kernel_indep(unit, K = K, name = "…")` /
`phylo_indep(0 + trait | unit, vcv = K)` on the dense supplied-kernel route
(documentary keyword only on the R side). `common = true` ties trait variances
(twin `kernel_scalar()` / `kernel_indep(..., common = TRUE)` spelling).

This is a **Gaussian matrix** fitter via [`fit_gaussian_sources`](@ref). It does
**not** estimate `K`, apply `rho` attenuation, or parse long-format grouping
columns. `@formula` `kernel_indep()` sugar is not in this slice.

`Y` is traits × units (`size(Y, 2) == length(groups)`). `K` must be square PD;
`groups[i]` maps unit `i` to a row of `K` (integer in `1:size(K, 1)`).

Engine knobs `K`, `num_lv`, `K_phy`, `Σ_phy`, and `sources` are fail-loud. Non-
default twin `rho` is fail-loud in Arc 0.

```julia
p, n = 3, 12
Y = randn(p, n)
groups = repeat(1:4; inner = 3)
L = randn(4, 4); K = L * L' + 0.5I
fit = fit_kernel_indep_gllvm(Y, K, groups; name = :known)
```
"""
function fit_kernel_indep_gllvm(Y::AbstractMatrix, K::AbstractMatrix, groups;
                                name::Union{Symbol, AbstractString} = :kernel,
                                common::Bool = false,
                                rho = 1,
                                kwargs...)
    p, n = size(Y)
    m = size(K, 1)
    size(K, 1) == size(K, 2) ||
        throw(ArgumentError(
            "fit_kernel_indep_gllvm: K must be square; got $(size(K))"))
    length(groups) == n ||
        throw(ArgumentError(
            "fit_kernel_indep_gllvm: length(groups) must equal n = $n; got $(length(groups))"))
    ids = collect(groups)
    all(g -> g isa Integer && !(g isa Bool) && 1 <= g <= m, ids) ||
        throw(ArgumentError(
            "fit_kernel_indep_gllvm: groups must be one-based indices in 1:$m"))
    sym_name = name isa Symbol ? name : Symbol(name)
    if !(rho === 1 || rho == 1)
        throw(ArgumentError(
            "fit_kernel_indep_gllvm: rho attenuation is not in Arc 0; omit rho or pass 1."))
    end
    for sym in (:K, :num_lv, :K_W, :has_diag, :K_phy, :has_phy_unique, :Σ_phy, :sources, :family)
        if haskey(kwargs, sym)
            throw(ArgumentError(
                "fit_kernel_indep_gllvm: `$sym` is not a knob on kernel × indep."))
        end
    end
    source = SourceCovariance(K; groups = ids, name = sym_name, mode = :indep, common = common)
    return fit_gaussian_sources(Y; sources = [source], kwargs...)
end

function fit_kernel_indep_gllvm(Y::AbstractMatrix, K::AbstractMatrix; kwargs...)
    throw(ArgumentError(
        "fit_kernel_indep_gllvm: pass unit-to-source `groups` (length n = $(size(Y, 2))) " *
        "as the third argument; kernel × indep does not infer grouping from Y alone."))
end
