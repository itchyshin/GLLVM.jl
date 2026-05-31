# Post-fit ordination extraction for fitted GLLVMs.
#
# Loadings come from the fit; the canonical rotation is the right-singular-
# vector matrix V of Λ (SVD), sign-fixed so each rotated loading column's
# largest-magnitude entry is non-negative and columns are ordered by
# decreasing singular value. Rotating loadings (Λ → Λ V) and scores
# (Z → Z V) by the same V leaves Λ Zᵀ — hence Σ_y — unchanged.

# Loadings accessor — dispatches over the two fitted types.
_loadings(fit::GllvmFit)    = fit.pars.Λ
_loadings(fit::BinomialFit) = fit.Λ

# Canonical sign-fixed right-singular-vector rotation of Λ (p×K) -> K×K.
function _svd_rotation(Λ::AbstractMatrix)
    F = svd(Λ)                      # Λ = U S Vᵀ ; columns of V order by S↓
    V = Matrix(F.V)                 # K×K
    ΛV = Λ * V
    @inbounds for k in 1:size(V, 2)
        idx = argmax(abs.(@view ΛV[:, k]))
        if ΛV[idx, k] < 0
            @views V[:, k] .= .-V[:, k]
        end
    end
    return V
end

"""
    rotation(fit) -> K×K orthogonal matrix

Canonical rotation `R` of the latent space (sign-fixed SVD of the loadings):
`getLoadings(fit; rotate=true) == getLoadings(fit; rotate=false) * R` and
`getLV(fit, y; rotate=true) == getLV(fit, y; rotate=false) * R`. `R'R == I`.
"""
rotation(fit) = _svd_rotation(_loadings(fit))

"""
    getLoadings(fit; rotate=true) -> p×K matrix

Species loadings. `rotate=true` (default) returns them in the canonical
ordination orientation (`Λ R`, columns ordered by decreasing variance, signs
fixed); `rotate=false` returns the raw fitted `Λ`. Rotation leaves `Λ Λᵀ` (and
`Σ_y`) unchanged.
"""
function getLoadings(fit; rotate::Bool = true)
    Λ = _loadings(fit)
    return rotate ? Λ * _svd_rotation(Λ) : copy(Λ)
end

# Fitted mean μ (p×n): X·β when fixed effects are present, else zeros.
function _fitted_mean(fit::GllvmFit, y::AbstractMatrix,
                      X::Union{Nothing, AbstractArray{<:Real, 3}})
    p, n = size(y)
    β = fit.pars.β
    if X === nothing || β === nothing || length(β) == 0
        return zeros(Float64, p, n)
    end
    μ = zeros(Float64, p, n)
    q = size(X, 3)
    @inbounds for s in 1:n, t in 1:p, k in 1:q
        μ[t, s] += X[t, s, k] * β[k]
    end
    return μ
end

"""
    getLV(fit::GllvmFit, y; X=nothing, rotate=true) -> n×K matrix

Conditional latent-variable scores (site ordination): the Gaussian posterior
mean `mₛ = (I + Λᵀ Ψ⁻¹ Λ)⁻¹ Λᵀ Ψ⁻¹ (yₛ − μₛ)`, with residual covariance
`Ψ = Σ_y − ΛΛᵀ` and `μ` the fitted mean (`X·β`, or 0 when there are no fixed
effects). `y` (and `X`, when the fit used fixed effects) must match what was
passed to `fit_gaussian_gllvm` — the fit does not store the data. `rotate=true`
applies the canonical [`rotation`](@ref).
"""
function getLV(fit::GllvmFit, y::AbstractMatrix;
               X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing,
               rotate::Bool = true)
    Λ = fit.pars.Λ
    K = size(Λ, 2)
    Σ = sigma_y_site(fit)
    Ψ = Σ - Λ * Λ'
    R = y .- _fitted_mean(fit, y, X)
    ΨiΛ = Ψ \ Λ
    M = Symmetric(I + Λ' * ΨiΛ)
    Z = M \ (ΨiΛ' * R)                  # K×n
    Zt = permutedims(Z)                 # n×K
    return rotate ? Zt * _svd_rotation(Λ) : Zt
end

"""
    getLV(fit::BinomialFit, Y; N=nothing, rotate=true) -> n×K matrix

Conditional latent-variable scores: the per-site Laplace mode `ẑₛ` (the inner
Fisher-scoring solve of the marginal). `Y` is the p×n integer response matrix;
`N` the trial counts (default all-ones, i.e. Bernoulli). `rotate=true` applies
the canonical [`rotation`](@ref).
"""
function getLV(fit::BinomialFit, Y::AbstractMatrix{<:Integer};
               N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing,
               rotate::Bool = true)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    K = size(fit.Λ, 2)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _laplace_mode(view(Y, :, s), view(Nm, :, s), fit.Λ, fit.β, fit.link)
    end
    Zt = permutedims(Z)                 # n×K
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

"""
    predict(fit::GllvmFit, y; type=:response, X=nothing) -> p×n matrix

In-sample fitted values at the conditional latent scores `ẑ` (see [`getLV`](@ref)):
`type=:link` returns the linear predictor `η = μ + Λ ẑ` (`μ` the fixed-effect
mean, `0` without `X`); `type=:response` applies the inverse link (identity for
the Gaussian family, so both types coincide). No `newdata` — `y` (and `X`) must
match the fit.
"""
function predict(fit::GllvmFit, y::AbstractMatrix;
                 type::Symbol = :response,
                 X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing)
    type in (:link, :response) ||
        throw(ArgumentError("type must be :link or :response; got :$type"))
    Z = getLV(fit, y; X = X, rotate = false)         # n×K
    η = _fitted_mean(fit, y, X) .+ fit.pars.Λ * Z'   # p×n
    return η                                          # identity link
end

"""
    predict(fit::BinomialFit, Y; type=:response, N=nothing) -> p×n matrix

In-sample fitted values at the Laplace conditional mode `ẑ` (see [`getLV`](@ref)):
`type=:link` returns `η = β + Λ ẑ`; `type=:response` returns the inverse-link
fitted probabilities `linkinv(link, η)`.
"""
function predict(fit::BinomialFit, Y::AbstractMatrix{<:Integer};
                 type::Symbol = :response,
                 N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing)
    type in (:link, :response) ||
        throw(ArgumentError("type must be :link or :response; got :$type"))
    Z = getLV(fit, Y; N = N, rotate = false)         # n×K
    η = fit.β .+ fit.Λ * Z'                           # p×n
    type === :link && return η
    return linkinv.(Ref(fit.link), η)
end

"""
    fitted(fit, data; kwargs...) -> p×n matrix

Response-scale in-sample fitted values — `predict(fit, data; type=:response, kwargs...)`.
"""
fitted(fit, data; kwargs...) = predict(fit, data; type = :response, kwargs...)
