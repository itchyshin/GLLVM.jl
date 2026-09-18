# kernel × latent — Gaussian matrix fitter (rank-d Λ on fixed dense K).
#
# Twin estimand (Identity 2026-09-14; pin gllvmTMB kernel_latent roxygen b4d5fee6):
# low-rank cross-trait loadings on a user-supplied between-unit matrix K,
# phylo-equivalent to phylo_latent(..., vcv = K, d = d) on the twin dense path
# (Design 65 C1). Reuses fit_gaussian_sources / SourceCovariance mode :latent.
# No @formula kernel_latent() sugar (formula recognizer exists separately).

"""
    fit_kernel_latent_gllvm(Y, K, groups, d; name = :kernel, unique = false, kwargs...)

Standalone **kernel × latent** Gaussian fit: rank-`d` trait loadings (`mode = :latent`,
`rank = d`) on a fixed dense between-unit covariance matrix `K`, with units projected
via one-based `groups` indices into the rows/columns of `K`.

Same estimand class as twin `kernel_latent(unit, K = K, d = d, name = "…")` /
`phylo_latent(0 + trait | unit, vcv = K, d = d)` on the dense supplied-kernel route.
When `d == p` this is the same estimand as kernel × dep (full-rank loadings on
`K`; twin `kernel_latent(..., d = T)`).

`unique = false` (default) is loadings-only on the kernel block. `unique = true`
(twin folded `kernel_latent(..., unique = TRUE)` with diag(psi)) is not yet
available and raises an error.

This is a **Gaussian matrix** fitter via [`fit_gaussian_sources`](@ref). It does
**not** estimate `K`, apply `rho` attenuation, or parse long-format grouping
columns. `@formula` `kernel_latent()` syntax is not currently available.

`Y` is traits × units (`size(Y, 1) == p`, `size(Y, 2) == length(groups)`). `K` must
be square PD; `groups[i]` maps unit `i` to a row of `K`. Require `1 ≤ d ≤ p`.

Engine knobs `K`, `num_lv`, `K_phy`, `Σ_phy`, and `sources` are fail-loud. Non-
default twin `rho` is not available.

```julia
p, n = 3, 12
Y = randn(p, n)
groups = repeat(1:4; inner = 3)
L = randn(4, 4); K = L * L' + 0.5I
fit = fit_kernel_latent_gllvm(Y, K, groups, 1; name = :known)
```
"""
function fit_kernel_latent_gllvm(Y::AbstractMatrix, K::AbstractMatrix, groups, d::Integer;
                                 name::Union{Symbol, AbstractString} = :kernel,
                                 unique::Bool = false,
                                 rho = 1,
                                 kwargs...)
    p, n = size(Y)
    m = size(K, 1)
    size(K, 1) == size(K, 2) ||
        throw(ArgumentError(
            "fit_kernel_latent_gllvm: K must be square; got $(size(K))"))
    length(groups) == n ||
        throw(ArgumentError(
            "fit_kernel_latent_gllvm: length(groups) must equal n = $n; got $(length(groups))"))
    ids = collect(groups)
    all(g -> g isa Integer && !(g isa Bool) && 1 <= g <= m, ids) ||
        throw(ArgumentError(
            "fit_kernel_latent_gllvm: groups must be one-based indices in 1:$m"))
    (1 <= d <= p) || throw(ArgumentError(
        "fit_kernel_latent_gllvm: d must satisfy 1 ≤ d ≤ p = $p; got d = $d"))
    sym_name = name isa Symbol ? name : Symbol(name)
    unique && throw(ArgumentError(
        "fit_kernel_latent_gllvm: unique = true (kernel × latent with diag(psi) " *
        "on the kernel tier) is not available; use unique = false."))
    if !(rho === 1 || rho == 1)
        throw(ArgumentError(
            "fit_kernel_latent_gllvm: rho attenuation is not available; omit rho or pass 1."))
    end
    for sym in (:K, :num_lv, :K_W, :has_diag, :K_phy, :has_phy_unique, :Σ_phy, :sources,
                :family, :common, :rank)
        if haskey(kwargs, sym)
            throw(ArgumentError(
                "fit_kernel_latent_gllvm: `$sym` is not a knob on kernel × latent."))
        end
    end
    source = if d == p
        SourceCovariance(K; groups = ids, name = sym_name, mode = :dep)
    else
        SourceCovariance(K; groups = ids, name = sym_name, mode = :latent, rank = d,
            unique = false)
    end
    return fit_gaussian_sources(Y; sources = [source], kwargs...)
end

function fit_kernel_latent_gllvm(Y::AbstractMatrix, K::AbstractMatrix, groups; kwargs...)
    throw(ArgumentError(
        "fit_kernel_latent_gllvm: pass latent rank `d` (1 ≤ d ≤ p) as the fourth argument."))
end

function fit_kernel_latent_gllvm(Y::AbstractMatrix, K::AbstractMatrix; kwargs...)
    throw(ArgumentError(
        "fit_kernel_latent_gllvm: pass unit-to-source `groups` and rank `d`; " *
        "kernel × latent does not infer grouping from Y alone."))
end
