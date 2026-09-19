# spatial × dep — Arc 0 fail-loud admission (no mesh/SPDE transport yet).
#
# Twin estimand (Identity 2026-09-14; pin gllvmTMB spatial_dep roxygen b4d5fee6):
# full unstructured cross-trait covariance on the SPDE field (mesh required).
# Julia SPDE fitters exist separately; this slice only names the gap. No @formula sugar.

"""
    fit_spatial_dep_gllvm(Y; kwargs...)
    fit_spatial_dep_gllvm(Y, coords; kwargs...)

Standalone **spatial × dep** entry point (twin `spatial_dep(0 + trait | coords, mesh = mesh)`).

This route is not yet implemented. The twin estimand requires an fmesher-style
mesh and SPDE projected precision on **sites**; Julia does not yet provide that
transport.
Calls fail with `ArgumentError` — do not use dense [`spatial_cov`](@ref) on trait
coordinates as a stand-in for `spatial_dep`.

For spatial latent fields inside non-Gaussian GLLVMs, see [`fit_spde_latent_gllvm`](@ref).
For Gaussian SPDE fields, see [`fit_spde_gaussian`](@ref).

No `@formula` `spatial_dep()` syntax is available yet.
"""
function fit_spatial_dep_gllvm(Y::AbstractMatrix; kwargs...)
    p, n = size(Y)
    _spatial_dep_arc0_not_implemented(p, n, :matrix)
end

function fit_spatial_dep_gllvm(Y::AbstractMatrix, coords::AbstractMatrix; kwargs...)
    p, n = size(Y)
    size(coords, 1) == p ||
        throw(ArgumentError(
            "fit_spatial_dep_gllvm: coords must have one row per trait (p = $p); " *
            "got $(size(coords))"))
    _spatial_dep_arc0_not_implemented(p, n, :coords)
end

function _spatial_dep_arc0_not_implemented(p::Int, n::Int, _variant::Symbol)
    throw(ArgumentError(
        "fit_spatial_dep_gllvm: spatial × dep is not implemented yet " *
        "(p = $p traits, n = $n sites). The twin route needs " *
        "spatial_dep(0 + trait | coords, mesh = mesh) with an SPDE mesh and " *
        "projected site-level precision — not a dense trait-kernel Σ_phy shortcut."))
end
