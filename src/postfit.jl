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

"""
    residuals(fit::GllvmFit, y; type=:dunnsmyth, X=nothing) -> p×n matrix

Conditional residuals at the predicted latent scores. For the Gaussian family the
Dunn–Smyth randomized quantile residual reduces (continuous CDF) to the
standardized residual `(y − μ) / σ_eps`, which also equals the `:pearson`
residual. `μ` is the conditional fitted mean (see [`predict`](@ref)).
"""
function residuals(fit::GllvmFit, y::AbstractMatrix;
                   type::Symbol = :dunnsmyth,
                   X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing)
    type in (:dunnsmyth, :pearson) ||
        throw(ArgumentError("type must be :dunnsmyth or :pearson; got :$type"))
    μ = predict(fit, y; type = :response, X = X)
    return (y .- μ) ./ fit.pars.σ_eps
end

"""
    residuals(fit::BinomialFit, Y; type=:dunnsmyth, N=nothing, rng=Random.default_rng())
        -> p×n matrix

Conditional residuals at the predicted latent mode. `:dunnsmyth` returns Dunn–
Smyth randomized quantile residuals — `Φ⁻¹(u)`, `u` uniform on `[F(y−1), F(y)]`
under `Binomial(N, μ)` — ≈ N(0,1) under a correct model (pass a fixed `rng` for
reproducibility). `:pearson` returns `(Y − Nμ) / √(Nμ(1−μ))`.
"""
function residuals(fit::BinomialFit, Y::AbstractMatrix{<:Integer};
                   type::Symbol = :dunnsmyth,
                   N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing,
                   rng::AbstractRNG = Random.default_rng())
    type in (:dunnsmyth, :pearson) ||
        throw(ArgumentError("type must be :dunnsmyth or :pearson; got :$type"))
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    μ = predict(fit, Y; type = :response, N = N)
    if type === :pearson
        return (Y .- Nm .* μ) ./ sqrt.(Nm .* μ .* (1 .- μ))
    end
    R = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        d = Binomial(Int(Nm[t, s]), μ[t, s])
        Flo = cdf(d, Y[t, s] - 1)
        Fhi = cdf(d, Y[t, s])
        u = Flo + (Fhi - Flo) * rand(rng)
        R[t, s] = quantile(Normal(), clamp(u, 1e-12, 1 - 1e-12))
    end
    return R
end

# ---------------------------------------------------------------------------
# Model-selection criteria + display.
# ---------------------------------------------------------------------------

_loglik(fit::GllvmFit)    = fit.logLik
_loglik(fit::BinomialFit) = fit.loglik

# Free-parameter count k (loadings counted modulo the K(K−1)/2 rotational df).
function _nparams(fit::GllvmFit)
    m = fit.model
    p = m.p
    q = fit.pars.β === nothing ? 0 : length(fit.pars.β)
    k = q + 1                                          # fixed effects + σ_eps
    k += p * m.K - div(m.K * (m.K - 1), 2)            # Λ_B
    m.K_W > 0        && (k += p * m.K_W - div(m.K_W * (m.K_W - 1), 2))
    m.has_diag       && (k += 2p)                      # σ²_B, σ²_W
    m.K_phy > 0      && (k += p * m.K_phy - div(m.K_phy * (m.K_phy - 1), 2))
    m.has_phy_unique && (k += p)                       # σ_phy
    return k
end

function _nparams(fit::BinomialFit)
    p, K = size(fit.Λ)
    return p + (p * K - div(K * (K - 1), 2))           # β intercepts + Λ
end

"""
    aic(fit) -> Float64

Akaike information criterion `2k − 2ℓ`: `k` the free-parameter count (loadings
counted modulo the `K(K−1)/2` rotational identifiability), `ℓ` the maximised
marginal log-likelihood.
"""
aic(fit) = 2 * _nparams(fit) - 2 * _loglik(fit)

"""
    bic(fit, n_sites) -> Float64

Bayesian information criterion `k·log(n_sites) − 2ℓ`. `n_sites` (the number of
independent sites/rows) is passed explicitly because the fit does not store the
data.
"""
bic(fit, n_sites::Integer) = _nparams(fit) * log(n_sites) - 2 * _loglik(fit)

# Rich REPL display (the idiomatic "summary").
function Base.show(io::IO, ::MIME"text/plain", fit::GllvmFit)
    println(io, "Gaussian GLLVM fit")
    println(io, "  responses p = ", fit.model.p, ", latent factors K = ", fit.model.K)
    println(io, "  logLik = ", round(fit.logLik; sigdigits = 7),
            ", AIC = ", round(aic(fit); sigdigits = 7))
    print(io,   "  converged = ", fit.converged, " (", fit.n_iter, " iterations)")
end

function Base.show(io::IO, ::MIME"text/plain", fit::BinomialFit)
    p, K = size(fit.Λ)
    println(io, "Binomial GLLVM fit")
    println(io, "  responses p = ", p, ", latent factors K = ", K,
            ", link = ", nameof(typeof(fit.link)))
    println(io, "  logLik = ", round(fit.loglik; sigdigits = 7),
            ", AIC = ", round(aic(fit); sigdigits = 7))
    print(io,   "  converged = ", fit.converged, " (", fit.iterations, " iterations)")
end

Base.show(io::IO, fit::GllvmFit) =
    print(io, "GllvmFit(p=", fit.model.p, ", K=", fit.model.K,
          ", logLik=", round(fit.logLik; sigdigits = 6),
          fit.converged ? "" : ", NOT CONVERGED", ")")

# ---------------------------------------------------------------------------
# Poisson post-fit methods (parallel to Binomial; counts via the log link).
# ---------------------------------------------------------------------------

_loadings(fit::PoissonFit) = fit.Λ
_loglik(fit::PoissonFit)   = fit.loglik

function _nparams(fit::PoissonFit)
    p, K = size(fit.Λ)
    return p + (p * K - div(K * (K - 1), 2))           # β intercepts + Λ
end

"""
    getLV(fit::PoissonFit, Y; N=nothing, rotate=true) -> n×K matrix

Conditional latent-variable scores for a Poisson fit: the per-site Laplace mode
`ẑₛ`. `Y` is the p×n integer count matrix; `rotate=true` applies the canonical
[`rotation`](@ref). (`N` is accepted for signature symmetry and ignored.)
"""
function getLV(fit::PoissonFit, Y::AbstractMatrix{<:Integer};
               N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing,
               rotate::Bool = true)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    K = size(fit.Λ, 2)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _laplace_mode(Poisson(), view(Y, :, s), view(Nm, :, s), fit.Λ, fit.β, fit.link)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

"""
    predict(fit::PoissonFit, Y; type=:response, N=nothing) -> p×n matrix

In-sample fitted values at the Laplace mode: `type=:link` returns `η = β + Λ ẑ`;
`type=:response` the inverse-link fitted rates `linkinv(link, η) = exp(η)`.
"""
function predict(fit::PoissonFit, Y::AbstractMatrix{<:Integer};
                 type::Symbol = :response,
                 N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing)
    type in (:link, :response) ||
        throw(ArgumentError("type must be :link or :response; got :$type"))
    Z = getLV(fit, Y; N = N, rotate = false)
    η = fit.β .+ fit.Λ * Z'
    type === :link && return η
    return linkinv.(Ref(fit.link), η)
end

"""
    residuals(fit::PoissonFit, Y; type=:dunnsmyth, rng=Random.default_rng()) -> p×n matrix

Conditional residuals for a Poisson fit. `:dunnsmyth` returns Dunn–Smyth
randomized quantile residuals — `Φ⁻¹(u)`, `u` uniform on `[F(y−1), F(y)]` under
`Poisson(μ)` — ≈ N(0,1) under a correct model (pass a fixed `rng` to reproduce).
`:pearson` returns `(Y − μ) / √μ`.
"""
function residuals(fit::PoissonFit, Y::AbstractMatrix{<:Integer};
                   type::Symbol = :dunnsmyth,
                   rng::AbstractRNG = Random.default_rng())
    type in (:dunnsmyth, :pearson) ||
        throw(ArgumentError("type must be :dunnsmyth or :pearson; got :$type"))
    p, n = size(Y)
    μ = predict(fit, Y; type = :response)
    if type === :pearson
        return (Y .- μ) ./ sqrt.(μ)
    end
    R = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        d = Poisson(μ[t, s])
        Flo = cdf(d, Y[t, s] - 1)
        Fhi = cdf(d, Y[t, s])
        u = Flo + (Fhi - Flo) * rand(rng)
        R[t, s] = quantile(Normal(), clamp(u, 1e-12, 1 - 1e-12))
    end
    return R
end

function Base.show(io::IO, ::MIME"text/plain", fit::PoissonFit)
    p, K = size(fit.Λ)
    println(io, "Poisson GLLVM fit")
    println(io, "  responses p = ", p, ", latent factors K = ", K,
            ", link = ", nameof(typeof(fit.link)))
    println(io, "  logLik = ", round(fit.loglik; sigdigits = 7),
            ", AIC = ", round(aic(fit); sigdigits = 7))
    print(io,   "  converged = ", fit.converged, " (", fit.iterations, " iterations)")
end

# ---------------------------------------------------------------------------
# Negative-binomial post-fit methods (parallel to Poisson; counts with
# dispersion r — Var = μ + μ²/r — via the log link).
# ---------------------------------------------------------------------------

_loadings(fit::NBFit) = fit.Λ
_loglik(fit::NBFit)   = fit.loglik

function _nparams(fit::NBFit)
    p, K = size(fit.Λ)
    return p + (p * K - div(K * (K - 1), 2)) + 1       # β + Λ + dispersion r
end

"""
    getLV(fit::NBFit, Y; N=nothing, rotate=true) -> n×K matrix

Conditional latent-variable scores for a negative-binomial fit: the per-site
Laplace mode `ẑₛ` (computed at the fitted dispersion `r`). `rotate=true` applies
the canonical [`rotation`](@ref).
"""
function getLV(fit::NBFit, Y::AbstractMatrix{<:Integer};
               N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing,
               rotate::Bool = true)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    K = size(fit.Λ, 2)
    fam = NegativeBinomial(fit.r, 0.5)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _laplace_mode(fam, view(Y, :, s), view(Nm, :, s), fit.Λ, fit.β, fit.link)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

"""
    predict(fit::NBFit, Y; type=:response, N=nothing) -> p×n matrix

In-sample fitted values at the Laplace mode: `type=:link` returns `η = β + Λ ẑ`;
`type=:response` the inverse-link fitted means `linkinv(link, η) = exp(η)`.
"""
function predict(fit::NBFit, Y::AbstractMatrix{<:Integer};
                 type::Symbol = :response,
                 N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing)
    type in (:link, :response) ||
        throw(ArgumentError("type must be :link or :response; got :$type"))
    Z = getLV(fit, Y; N = N, rotate = false)
    η = fit.β .+ fit.Λ * Z'
    type === :link && return η
    return linkinv.(Ref(fit.link), η)
end

"""
    residuals(fit::NBFit, Y; type=:dunnsmyth, rng=Random.default_rng()) -> p×n matrix

Conditional residuals for a negative-binomial fit. `:dunnsmyth` returns Dunn–Smyth
randomized quantile residuals — `Φ⁻¹(u)`, `u` uniform on `[F(y−1), F(y)]` under
`NegativeBinomial(r, r/(r+μ))` — ≈ N(0,1) under a correct model (pass a fixed
`rng` to reproduce). `:pearson` returns `(Y − μ) / √(μ + μ²/r)`.
"""
function residuals(fit::NBFit, Y::AbstractMatrix{<:Integer};
                   type::Symbol = :dunnsmyth,
                   rng::AbstractRNG = Random.default_rng())
    type in (:dunnsmyth, :pearson) ||
        throw(ArgumentError("type must be :dunnsmyth or :pearson; got :$type"))
    p, n = size(Y)
    r = fit.r
    μ = predict(fit, Y; type = :response)
    if type === :pearson
        return (Y .- μ) ./ sqrt.(μ .+ μ .^ 2 ./ r)
    end
    R = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        d = NegativeBinomial(r, r / (r + μ[t, s]))
        Flo = cdf(d, Y[t, s] - 1)
        Fhi = cdf(d, Y[t, s])
        u = Flo + (Fhi - Flo) * rand(rng)
        R[t, s] = quantile(Normal(), clamp(u, 1e-12, 1 - 1e-12))
    end
    return R
end

function Base.show(io::IO, ::MIME"text/plain", fit::NBFit)
    p, K = size(fit.Λ)
    println(io, "Negative-binomial GLLVM fit")
    println(io, "  responses p = ", p, ", latent factors K = ", K,
            ", link = ", nameof(typeof(fit.link)), ", dispersion r = ", round(fit.r; sigdigits = 4))
    println(io, "  logLik = ", round(fit.loglik; sigdigits = 7),
            ", AIC = ", round(aic(fit); sigdigits = 7))
    print(io,   "  converged = ", fit.converged, " (", fit.iterations, " iterations)")
end
