# none × dep — Gaussian matrix fitter (K = p full-rank packed Λ).
#
# Twin estimand (Identity 2026-08-18; pin b8a1891a / e1922dbf L1721):
# standalone unstructured T×T Σ, PSD via Cholesky Σ = L Lᵀ, T(T+1)/2 free
# parameters. Same estimand as standalone latent(..., d = T).
#
# Reuses existing packing: rr_theta_len(p, p) = p(p+1)/2 and pack_lambda /
# unpack_lambda as L. This file does **not** add @formula dep() sugar
# (formula.jl v1 rejects FunctionTerm / `(… | g)`). Combo fail-loud waits
# for a later FunctionTerm slice. No phylo_dep / animal / spatial / kernel.

"""
    fit_dep_gllvm(Y; family = Normal(), kwargs...)

Standalone unstructured trait covariance (**none × dep**). Rank is forced
to `K = p`: full-rank packed-triangular ``Λ`` with
[`rr_theta_len`](@ref)`(p, p) = p(p + 1)/2` free parameters and Cholesky
``Σ = L Lᵀ``. Same estimand as [`fit_gaussian_gllvm`](@ref)`(Y; K = p)`
and twin `latent(0 + trait | g, d = T)`.

This is a **Gaussian matrix** fitter. `@formula` `dep()` sugar is not in
this slice (v1 rejects `FunctionTerm` and random-effect terms `(… | g)`).
`K` / `num_lv`, W-tier (`K_W`), `has_diag`, and phylogenetic kwargs
(`K_phy`, `has_phy_unique`, `Σ_phy`) are fail-loud — they are not knobs
on this path.

```julia
fit = fit_dep_gllvm(Y; family = Normal())
# equivalent latent(d = T) path:
fit2 = fit_gaussian_gllvm(Y; K = size(Y, 1))
```
"""
function fit_dep_gllvm(Y::AbstractMatrix; family = Normal(),
                      K = nothing, num_lv = nothing,
                      K_W::Integer = 0,
                      has_diag::Bool = false,
                      K_phy::Integer = 0,
                      has_phy_unique::Bool = false,
                      Σ_phy = nothing,
                      kwargs...)
    p = size(Y, 1)
    family isa Normal || throw(ArgumentError(
        "fit_dep_gllvm: this slice is a Gaussian wrapper only; got " *
        "$(nameof(typeof(family))). No formula dep() sugar."))
    K === nothing || throw(ArgumentError(
        "fit_dep_gllvm: K is not a knob; none × dep forces K = p = $p " *
        "(full-rank packed Λ). Do not pass K."))
    num_lv === nothing || throw(ArgumentError(
        "fit_dep_gllvm: num_lv is not a knob; none × dep forces K = p = $p. " *
        "Do not pass num_lv."))
    K_W == 0 || throw(ArgumentError(
        "fit_dep_gllvm: W-tier is out of scope for none × dep " *
        "(unstructured trait covariance; got K_W=$K_W)."))
    has_diag && throw(ArgumentError(
        "fit_dep_gllvm: has_diag is out of scope for none × dep " *
        "(got has_diag=true)."))
    (K_phy == 0 && !has_phy_unique && Σ_phy === nothing) || throw(ArgumentError(
        "fit_dep_gllvm: phylogenetic kwargs are out of scope " *
        "(phylo_dep is a later slice). Got K_phy=$K_phy, " *
        "has_phy_unique=$has_phy_unique, " *
        "Σ_phy=$(Σ_phy === nothing ? "nothing" : "set")."))
    return fit_gaussian_gllvm(Y; K = p, kwargs...)
end
