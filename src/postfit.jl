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
               rotate::Bool = true, mask = nothing)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    K = size(fit.Λ, 2)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        mi = mask === nothing ? nothing : view(mask, :, s)
        Z[:, s] = _laplace_mode(view(Y, :, s), view(Nm, :, s), fit.Λ, fit.β, fit.link;
                                mask = mi)
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
    q = if fit.pars.β === nothing
        0
    elseif haskey(fit.pars, :β_fixed)
        count(!, fit.pars.β_fixed)
    else
        length(fit.pars.β)
    end
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
               rotate::Bool = true, mask = nothing)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    K = size(fit.Λ, 2)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        mi = mask === nothing ? nothing : view(mask, :, s)
        Z[:, s] = _laplace_mode(Poisson(), view(Y, :, s), view(Nm, :, s), fit.Λ,
                                fit.β, fit.link; mask = mi)
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
               rotate::Bool = true, mask = nothing)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    K = size(fit.Λ, 2)
    fam = NegativeBinomial(fit.r, 0.5)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        mi = mask === nothing ? nothing : view(mask, :, s)
        Z[:, s] = _laplace_mode(fam, view(Y, :, s), view(Nm, :, s), fit.Λ,
                                fit.β, fit.link; mask = mi)
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

# ---------------------------------------------------------------------------
# NB1 (negative binomial type-1, linear variance Var = μ(1+φ)) post-fit methods —
# a mirror of NBFit with the mean-dependent size r = μ/φ, constant prob 1/(1+φ).
# ---------------------------------------------------------------------------

_loadings(fit::NB1Fit) = fit.Λ
_loglik(fit::NB1Fit)   = fit.loglik

function _nparams(fit::NB1Fit)
    p, K = size(fit.Λ)
    return p + (p * K - div(K * (K - 1), 2)) + 1       # β + Λ + dispersion φ
end

function getLV(fit::NB1Fit, Y::AbstractMatrix{<:Integer};
               N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing,
               rotate::Bool = true, mask = nothing)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    K = size(fit.Λ, 2)
    fam = NB1(fit.φ)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        mi = mask === nothing ? nothing : view(mask, :, s)
        Z[:, s] = _laplace_mode(fam, view(Y, :, s), view(Nm, :, s), fit.Λ,
                                fit.β, fit.link; mask = mi)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

function predict(fit::NB1Fit, Y::AbstractMatrix{<:Integer};
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
    residuals(fit::NB1Fit, Y; type=:dunnsmyth, rng=Random.default_rng()) -> p×n matrix

Conditional residuals for an NB1 fit. `:dunnsmyth` returns Dunn–Smyth randomized
quantile residuals under `NegativeBinomial(μ/φ, 1/(1+φ))`; `:pearson` returns
`(Y − μ) / √(μ(1+φ))`.
"""
function residuals(fit::NB1Fit, Y::AbstractMatrix{<:Integer};
                   type::Symbol = :dunnsmyth,
                   rng::AbstractRNG = Random.default_rng())
    type in (:dunnsmyth, :pearson) ||
        throw(ArgumentError("type must be :dunnsmyth or :pearson; got :$type"))
    p, n = size(Y)
    φ = fit.φ
    μ = predict(fit, Y; type = :response)
    if type === :pearson
        return (Y .- μ) ./ sqrt.(μ .* (1 + φ))
    end
    R = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        d = NegativeBinomial(μ[t, s] / φ, 1 / (1 + φ))
        Flo = cdf(d, Y[t, s] - 1)
        Fhi = cdf(d, Y[t, s])
        u = Flo + (Fhi - Flo) * rand(rng)
        R[t, s] = quantile(Normal(), clamp(u, 1e-12, 1 - 1e-12))
    end
    return R
end

function Base.show(io::IO, ::MIME"text/plain", fit::NB1Fit)
    p, K = size(fit.Λ)
    println(io, "Negative-binomial type-1 (NB1) GLLVM fit")
    println(io, "  responses p = ", p, ", latent factors K = ", K,
            ", link = ", nameof(typeof(fit.link)), ", dispersion φ = ", round(fit.φ; sigdigits = 4))
    println(io, "  logLik = ", round(fit.loglik; sigdigits = 7),
            ", AIC = ", round(aic(fit); sigdigits = 7))
    print(io,   "  converged = ", fit.converged, " (", fit.iterations, " iterations)")
end

# ---------------------------------------------------------------------------
# GP-1 (generalized Poisson type-1, Var = μ(1+α μ)², signed dispersion α) post-fit
# methods — mirror the NB1 block; Dunn–Smyth uses the summed GP-1 CDF (_gp1_cdf).
# ---------------------------------------------------------------------------

_loadings(fit::GP1Fit) = fit.Λ
_loglik(fit::GP1Fit)   = fit.loglik

function _nparams(fit::GP1Fit)
    p, K = size(fit.Λ)
    return p + (p * K - div(K * (K - 1), 2)) + 1       # β + Λ + dispersion α
end

function getLV(fit::GP1Fit, Y::AbstractMatrix{<:Integer};
               N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing,
               rotate::Bool = true, mask = nothing)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    K = size(fit.Λ, 2)
    fam = GeneralizedPoisson1(fit.α)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        mi = mask === nothing ? nothing : view(mask, :, s)
        Z[:, s] = _laplace_mode(fam, view(Y, :, s), view(Nm, :, s), fit.Λ,
                                fit.β, fit.link; mask = mi)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

function predict(fit::GP1Fit, Y::AbstractMatrix{<:Integer};
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
    residuals(fit::GP1Fit, Y; type=:dunnsmyth, rng=Random.default_rng()) -> p×n matrix

Conditional residuals for a GP-1 fit. `:dunnsmyth` returns Dunn–Smyth randomized
quantile residuals under the fitted GP-1 pmf (CDF summed from the family log-pmf);
`:pearson` returns `(Y − μ) / √(μ(1+α μ)²)`.
"""
function residuals(fit::GP1Fit, Y::AbstractMatrix{<:Integer};
                   type::Symbol = :dunnsmyth,
                   rng::AbstractRNG = Random.default_rng())
    type in (:dunnsmyth, :pearson) ||
        throw(ArgumentError("type must be :dunnsmyth or :pearson; got :$type"))
    p, n = size(Y)
    fam = GeneralizedPoisson1(fit.α)
    μ = predict(fit, Y; type = :response)
    if type === :pearson
        return (Y .- μ) ./ sqrt.(μ .* (1 .+ fit.α .* μ) .^ 2)
    end
    R = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        Flo = _gp1_cdf(fam, μ[t, s], Y[t, s] - 1)
        Fhi = _gp1_cdf(fam, μ[t, s], Y[t, s])
        u = Flo + (Fhi - Flo) * rand(rng)
        R[t, s] = quantile(Normal(), clamp(u, 1e-12, 1 - 1e-12))
    end
    return R
end

function Base.show(io::IO, ::MIME"text/plain", fit::GP1Fit)
    p, K = size(fit.Λ)
    println(io, "Generalized-Poisson type-1 (GP-1) GLLVM fit")
    println(io, "  responses p = ", p, ", latent factors K = ", K,
            ", link = ", nameof(typeof(fit.link)), ", dispersion α = ", round(fit.α; sigdigits = 4))
    println(io, "  logLik = ", round(fit.loglik; sigdigits = 7),
            ", AIC = ", round(aic(fit); sigdigits = 7))
    print(io,   "  converged = ", fit.converged, " (", fit.iterations, " iterations)")
end

# ---------------------------------------------------------------------------
# Beta post-fit methods (proportions in (0,1); mean μ = logistic(η), precision
# φ — Var = μ(1−μ)/(1+φ) — via the logit link). Responses are continuous, so the
# Dunn–Smyth residual reduces to the (deterministic) PIT, as in the Gaussian case.
# ---------------------------------------------------------------------------

_loadings(fit::BetaFit) = fit.Λ
_loglik(fit::BetaFit)   = fit.loglik

function _nparams(fit::BetaFit)
    p, K = size(fit.Λ)
    return p + (p * K - div(K * (K - 1), 2)) + 1       # β + Λ + precision φ
end

"""
    getLV(fit::BetaFit, Y; rotate=true) -> n×K matrix

Conditional latent-variable scores for a Beta fit: the per-site Laplace mode `ẑₛ`
(computed at the fitted precision `φ`). `Y` is the p×n matrix of proportions in
(0,1); `rotate=true` applies the canonical [`rotation`](@ref).
"""
function getLV(fit::BetaFit, Y::AbstractMatrix{<:Real}; rotate::Bool = true, mask = nothing)
    p, n = size(Y)
    K = size(fit.Λ, 2)
    fam = Beta(fit.φ, 1.0)
    ones_p = ones(Int, p)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        mi = mask === nothing ? nothing : view(mask, :, s)
        Z[:, s] = _laplace_mode(fam, view(Y, :, s), ones_p, fit.Λ, fit.β, fit.link;
                                mask = mi)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

"""
    predict(fit::BetaFit, Y; type=:response) -> p×n matrix

In-sample fitted values at the Laplace mode: `type=:link` returns `η = β + Λ ẑ`;
`type=:response` the inverse-link fitted means `linkinv(link, η) = logistic(η)`
(proportions in (0,1)).
"""
function predict(fit::BetaFit, Y::AbstractMatrix{<:Real}; type::Symbol = :response)
    type in (:link, :response) ||
        throw(ArgumentError("type must be :link or :response; got :$type"))
    Z = getLV(fit, Y; rotate = false)
    η = fit.β .+ fit.Λ * Z'
    type === :link && return η
    return linkinv.(Ref(fit.link), η)
end

"""
    residuals(fit::BetaFit, Y; type=:dunnsmyth) -> p×n matrix

Conditional residuals for a Beta fit. The Beta CDF is continuous, so the
`:dunnsmyth` randomized quantile residual reduces to the deterministic PIT
`Φ⁻¹(F(y))` under `Beta(μφ, (1−μ)φ)` — ≈ N(0,1) under a correct model — exactly as
in the Gaussian case. `:pearson` returns `(Y − μ) / √(μ(1−μ)/(1+φ))`.
"""
function residuals(fit::BetaFit, Y::AbstractMatrix{<:Real}; type::Symbol = :dunnsmyth)
    type in (:dunnsmyth, :pearson) ||
        throw(ArgumentError("type must be :dunnsmyth or :pearson; got :$type"))
    p, n = size(Y)
    φ = fit.φ
    μ = predict(fit, Y; type = :response)
    if type === :pearson
        return (Y .- μ) ./ sqrt.(μ .* (1 .- μ) ./ (1 + φ))
    end
    R = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        d = Beta(μ[t, s] * φ, (1 - μ[t, s]) * φ)
        u = cdf(d, clamp(float(Y[t, s]), 1e-12, 1 - 1e-12))
        R[t, s] = quantile(Normal(), clamp(u, 1e-12, 1 - 1e-12))
    end
    return R
end

function Base.show(io::IO, ::MIME"text/plain", fit::BetaFit)
    p, K = size(fit.Λ)
    println(io, "Beta GLLVM fit")
    println(io, "  responses p = ", p, ", latent factors K = ", K,
            ", link = ", nameof(typeof(fit.link)), ", precision φ = ", round(fit.φ; sigdigits = 4))
    println(io, "  logLik = ", round(fit.loglik; sigdigits = 7),
            ", AIC = ", round(aic(fit); sigdigits = 7))
    print(io,   "  converged = ", fit.converged, " (", fit.iterations, " iterations)")
end

# ---------------------------------------------------------------------------
# Ordinal post-fit methods (ordered categories 1:C; cumulative logit, common
# ordered cutpoints τ; latent η = (Λz)_t, no intercept). The "fitted value" is
# the modal category; residuals are Dunn–Smyth randomized quantile (discrete CDF).
# ---------------------------------------------------------------------------

_loadings(fit::OrdinalFit) = fit.Λ
_loglik(fit::OrdinalFit)   = fit.loglik
_loadings(fit::OrdinalPerTraitFit) = fit.Λ
_loglik(fit::OrdinalPerTraitFit)   = fit.loglik

function _nparams(fit::OrdinalFit)
    p, K = size(fit.Λ)
    return (p * K - div(K * (K - 1), 2)) + (fit.C - 1)   # Λ + (C−1) cutpoints, no β
end
function _nparams(fit::OrdinalPerTraitFit)
    p, K = size(fit.Λ)
    return (p * K - div(K * (K - 1), 2)) + sum(fit.C .- 1)
end

"""
    getLV(fit::OrdinalFit, Y; rotate=true) -> n×K matrix

Conditional latent-variable scores for an ordinal fit: the per-site Laplace mode
`ẑₛ` (at the fitted cutpoints). `Y` is the p×n matrix of ordinal responses (`1:C`);
`rotate=true` applies the canonical [`rotation`](@ref).
"""
function getLV(fit::OrdinalFit, Y::AbstractMatrix{<:Integer}; rotate::Bool = true, mask = nothing)
    p, n = size(Y)
    K = size(fit.Λ, 2)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        mi = mask === nothing ? nothing : view(mask, :, s)
        Z[:, s] = _ordinal_laplace_mode(view(Y, :, s), fit.Λ, fit.τ, fit.link;
                                        mask = mi)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end
function getLV(fit::OrdinalPerTraitFit, Y::AbstractMatrix{<:Integer};
               rotate::Bool = true, mask = nothing)
    p, n = size(Y)
    K = size(fit.Λ, 2)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        mi = mask === nothing ? nothing : view(mask, :, s)
        Z[:, s] = _ordinal_laplace_mode_pertrait(view(Y, :, s), fit.Λ, fit.τ,
                                                 fit.C, fit.link; mask = mi)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

"""
    predict(fit::OrdinalFit, Y; type=:class) -> matrix or p×n×C array

In-sample predictions at the Laplace mode `ẑ` (η = Λẑ). `type=:link` returns the
linear predictor `η` (p×n); `type=:prob` the category probabilities (p×n×C array,
summing to 1 over the last axis); `type=:class` / `:response` the modal category
(p×n integer matrix).
"""
function predict(fit::OrdinalFit, Y::AbstractMatrix{<:Integer}; type::Symbol = :class)
    type in (:link, :prob, :class, :response) ||
        throw(ArgumentError("type must be :link, :prob, :class, or :response; got :$type"))
    p, n = size(Y); C = fit.C
    Z = getLV(fit, Y; rotate = false)
    η = fit.Λ * Z'                                   # p×n
    type === :link && return η
    if type === :prob
        P = Array{Float64, 3}(undef, p, n, C)
        @inbounds for s in 1:n, t in 1:p, c in 1:C
            P[t, s, c] = _ord_prob(c, η[t, s], fit.τ, fit.link)
        end
        return P
    end
    M = Matrix{Int}(undef, p, n)                     # modal category
    @inbounds for s in 1:n, t in 1:p
        best = 1; bestp = -1.0
        for c in 1:C
            pc = _ord_prob(c, η[t, s], fit.τ, fit.link)
            pc > bestp && (bestp = pc; best = c)
        end
        M[t, s] = best
    end
    return M
end
function predict(fit::OrdinalPerTraitFit, Y::AbstractMatrix{<:Integer};
                 type::Symbol = :class)
    type in (:link, :prob, :class, :response) ||
        throw(ArgumentError("type must be :link, :prob, :class, or :response; got :$type"))
    p, n = size(Y)
    Cmax = maximum(fit.C)
    Z = getLV(fit, Y; rotate = false)
    η = fit.Λ * Z'
    type === :link && return η
    if type === :prob
        P = zeros(Float64, p, n, Cmax)
        @inbounds for s in 1:n, t in 1:p
            τt = _trait_cutpoints(fit.τ, fit.C, t)
            for c in 1:fit.C[t]
                P[t, s, c] = _ord_prob(c, η[t, s], τt, fit.link)
            end
        end
        return P
    end
    M = Matrix{Int}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        τt = _trait_cutpoints(fit.τ, fit.C, t)
        best = 1
        bestp = -1.0
        for c in 1:fit.C[t]
            pc = _ord_prob(c, η[t, s], τt, fit.link)
            pc > bestp && (bestp = pc; best = c)
        end
        M[t, s] = best
    end
    return M
end

"""
    residuals(fit::OrdinalFit, Y; type=:dunnsmyth, rng=Random.default_rng()) -> p×n matrix

Dunn–Smyth randomized quantile residuals for an ordinal fit — `Φ⁻¹(u)`, `u` uniform
on `[P(Y≤c−1), P(Y≤c)]` under the fitted cumulative-logit model at the Laplace mode
— ≈ N(0,1) under a correct model (pass a fixed `rng` to reproduce). Only
`:dunnsmyth` is defined for ordered categories.
"""
function residuals(fit::OrdinalFit, Y::AbstractMatrix{<:Integer};
                   type::Symbol = :dunnsmyth, rng::AbstractRNG = Random.default_rng())
    type === :dunnsmyth ||
        throw(ArgumentError("ordinal residuals support type=:dunnsmyth only; got :$type"))
    p, n = size(Y); C = fit.C
    Z = getLV(fit, Y; rotate = false)
    η = fit.Λ * Z'
    R = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        c = Int(Y[t, s])
        Fhi = c >= C ? 1.0 : _ord_F(fit.τ[c] - η[t, s], fit.link)
        Flo = c <= 1 ? 0.0 : _ord_F(fit.τ[c - 1] - η[t, s], fit.link)
        u = Flo + (Fhi - Flo) * rand(rng)
        R[t, s] = quantile(Normal(), clamp(u, 1e-12, 1 - 1e-12))
    end
    return R
end
function residuals(fit::OrdinalPerTraitFit, Y::AbstractMatrix{<:Integer};
                   type::Symbol = :dunnsmyth, rng::AbstractRNG = Random.default_rng())
    type === :dunnsmyth ||
        throw(ArgumentError("ordinal residuals support type=:dunnsmyth only; got :$type"))
    p, n = size(Y)
    Z = getLV(fit, Y; rotate = false)
    η = fit.Λ * Z'
    R = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        τt = _trait_cutpoints(fit.τ, fit.C, t)
        c = Int(Y[t, s])
        Fhi = c >= fit.C[t] ? 1.0 : _ord_F(τt[c] - η[t, s], fit.link)
        Flo = c <= 1 ? 0.0 : _ord_F(τt[c - 1] - η[t, s], fit.link)
        u = Flo + (Fhi - Flo) * rand(rng)
        R[t, s] = quantile(Normal(), clamp(u, 1e-12, 1 - 1e-12))
    end
    return R
end

function Base.show(io::IO, ::MIME"text/plain", fit::OrdinalFit)
    p, K = size(fit.Λ)
    println(io, "Ordinal GLLVM fit (cumulative logit)")
    println(io, "  responses p = ", p, ", latent factors K = ", K, ", categories C = ", fit.C)
    println(io, "  logLik = ", round(fit.loglik; sigdigits = 7),
            ", AIC = ", round(aic(fit); sigdigits = 7))
    print(io,   "  converged = ", fit.converged, " (", fit.iterations, " iterations)")
end
function Base.show(io::IO, ::MIME"text/plain", fit::OrdinalPerTraitFit)
    p, K = size(fit.Λ)
    println(io, "Ordinal GLLVM fit (per-trait cutpoints)")
    println(io, "  responses p = ", p, ", latent factors K = ", K,
            ", categories C = ", fit.C)
    println(io, "  logLik = ", round(fit.loglik; sigdigits = 7),
            ", AIC = ", round(aic(fit); sigdigits = 7))
    print(io,   "  converged = ", fit.converged, " (", fit.iterations, " iterations)")
end

# ---------------------------------------------------------------------------
# Gamma post-fit methods (positive continuous; mean μ = exp(η), shape α —
# Var = μ²/α — via the log link). Responses are continuous, so the Dunn–Smyth
# residual reduces to the deterministic PIT, as in the Gaussian and Beta cases.
# ---------------------------------------------------------------------------

_loadings(fit::GammaFit) = fit.Λ
_loglik(fit::GammaFit)   = fit.loglik

function _nparams(fit::GammaFit)
    p, K = size(fit.Λ)
    return p + (p * K - div(K * (K - 1), 2)) + 1       # β + Λ + shape α
end

"""
    getLV(fit::GammaFit, Y; rotate=true) -> n×K matrix

Conditional latent-variable scores for a Gamma fit: the per-site Laplace mode `ẑₛ`
(computed at the fitted shape `α`). `Y` is the p×n matrix of positive reals;
`rotate=true` applies the canonical [`rotation`](@ref).
"""
function getLV(fit::GammaFit, Y::AbstractMatrix{<:Real}; rotate::Bool = true, mask = nothing)
    p, n = size(Y)
    K = size(fit.Λ, 2)
    fam = Gamma(fit.α, 1.0)
    ones_p = ones(Int, p)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        mi = mask === nothing ? nothing : view(mask, :, s)
        Z[:, s] = _laplace_mode(fam, view(Y, :, s), ones_p, fit.Λ, fit.β, fit.link;
                                mask = mi)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

"""
    predict(fit::GammaFit, Y; type=:response) -> p×n matrix

In-sample fitted values at the Laplace mode: `type=:link` returns `η = β + Λ ẑ`;
`type=:response` the inverse-link fitted means `linkinv(link, η) = exp(η)` (positive reals).
"""
function predict(fit::GammaFit, Y::AbstractMatrix{<:Real}; type::Symbol = :response)
    type in (:link, :response) ||
        throw(ArgumentError("type must be :link or :response; got :$type"))
    Z = getLV(fit, Y; rotate = false)
    η = fit.β .+ fit.Λ * Z'
    type === :link && return η
    return linkinv.(Ref(fit.link), η)
end

"""
    residuals(fit::GammaFit, Y; type=:dunnsmyth) -> p×n matrix

Conditional residuals for a Gamma fit. The Gamma CDF is continuous, so the
`:dunnsmyth` randomized quantile residual reduces to the deterministic PIT
`Φ⁻¹(F(y))` under `Gamma(α, μ/α)` — ≈ N(0,1) under a correct model — exactly as
in the Gaussian and Beta cases. `:pearson` returns `(Y − μ) / √(μ²/α)`.
"""
function residuals(fit::GammaFit, Y::AbstractMatrix{<:Real}; type::Symbol = :dunnsmyth)
    type in (:dunnsmyth, :pearson) ||
        throw(ArgumentError("type must be :dunnsmyth or :pearson; got :$type"))
    p, n = size(Y)
    α = fit.α
    μ = predict(fit, Y; type = :response)
    if type === :pearson
        return (Y .- μ) ./ sqrt.(μ .^ 2 ./ α)
    end
    R = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        d = Gamma(α, μ[t, s] / α)
        u = cdf(d, max(float(Y[t, s]), 1e-300))
        R[t, s] = quantile(Normal(), clamp(u, 1e-12, 1 - 1e-12))
    end
    return R
end

# --- Exponential post-fit (positive continuous, Var = μ², no dispersion) ---
_loadings(fit::ExponentialFit) = fit.Λ
_loglik(fit::ExponentialFit)   = fit.loglik
_nparams(fit::ExponentialFit)  = (p = size(fit.Λ, 1); K = size(fit.Λ, 2); p + (p * K - div(K * (K - 1), 2)))

function getLV(fit::ExponentialFit, Y::AbstractMatrix{<:Real}; rotate::Bool = true)
    p, n = size(Y); K = size(fit.Λ, 2)
    fam = Exponential(1.0); ones_p = ones(Int, p)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _laplace_mode(fam, view(Y, :, s), ones_p, fit.Λ, fit.β, fit.link)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

function predict(fit::ExponentialFit, Y::AbstractMatrix{<:Real}; type::Symbol = :response)
    type in (:link, :response) ||
        throw(ArgumentError("type must be :link or :response; got :$type"))
    Z = getLV(fit, Y; rotate = false)
    η = fit.β .+ fit.Λ * Z'
    type === :link && return η
    # clamp η before the (exp) inverse link, matching the inner mode solver
    # (_clamp_eta) and the other predict methods: an extreme conditional mode
    # must not over/underflow μ (Exponential(0) is invalid; Inf corrupts residuals).
    return linkinv.(Ref(fit.link), _clamp_eta.(η))
end

"""
    residuals(fit::ExponentialFit, Y; type=:dunnsmyth) -> p×n matrix

`:dunnsmyth` randomized-quantile (here deterministic PIT, the Exponential CDF being
continuous) `Φ⁻¹(F(y))` under `Exponential(μ)`; `:pearson` returns `(Y − μ)/μ`.
"""
function residuals(fit::ExponentialFit, Y::AbstractMatrix{<:Real}; type::Symbol = :dunnsmyth)
    type in (:dunnsmyth, :pearson) ||
        throw(ArgumentError("type must be :dunnsmyth or :pearson; got :$type"))
    p, n = size(Y)
    μ = predict(fit, Y; type = :response)
    type === :pearson && return (Y .- μ) ./ μ
    R = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        u = cdf(Exponential(μ[t, s]), max(float(Y[t, s]), 1e-300))
        R[t, s] = quantile(Normal(), clamp(u, 1e-12, 1 - 1e-12))
    end
    return R
end

function Base.show(io::IO, ::MIME"text/plain", fit::ExponentialFit)
    p, K = size(fit.Λ)
    println(io, "Exponential GLLVM fit")
    println(io, "  responses p = ", p, ", latent factors K = ", K,
            ", link = ", nameof(typeof(fit.link)))
    println(io, "  logLik = ", round(fit.loglik; sigdigits = 7),
            ", AIC = ", round(aic(fit); sigdigits = 7))
    print(io,   "  converged = ", fit.converged, " (", fit.iterations, " iterations)")
end

function Base.show(io::IO, ::MIME"text/plain", fit::GammaFit)
    p, K = size(fit.Λ)
    println(io, "Gamma GLLVM fit")
    println(io, "  responses p = ", p, ", latent factors K = ", K,
            ", link = ", nameof(typeof(fit.link)), ", shape α = ", round(fit.α; sigdigits = 4))
    println(io, "  logLik = ", round(fit.loglik; sigdigits = 7),
            ", AIC = ", round(aic(fit); sigdigits = 7))
    print(io,   "  converged = ", fit.converged, " (", fit.iterations, " iterations)")
end

# ---------------------------------------------------------------------------
# Delta-lognormal post-fit methods (two-part: occurrence Bernoulli × positive
# lognormal; shared latent z drives the positive part, Λ_z = 0).
# ---------------------------------------------------------------------------

_loadings(fit::DeltaLogNormalFit) = fit.Λc
_loglik(fit::DeltaLogNormalFit)   = fit.loglik

function _nparams(fit::DeltaLogNormalFit)
    p, K = size(fit.Λc)
    return 2p + (p * K - div(K * (K - 1), 2)) + 1   # βz + βc + Λc + σ
end

"""
    getLV(fit::DeltaLogNormalFit, Y; rotate=true) -> n×K matrix

Conditional latent scores for a Delta-lognormal fit: the per-site two-part Laplace
mode `ẑₛ` (occurrence intercept-only, so only the positive part loads on `z`).
"""
function getLV(fit::DeltaLogNormalFit, Y::AbstractMatrix{<:Real}; rotate::Bool = true)
    p, n = size(Y)
    K = size(fit.Λc, 2)
    fam = DeltaLogNormal(fit.σ)
    Λz = zeros(p, K)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _twopart_mode(fam, view(Y, :, s), Λz, fit.Λc, fit.βz, fit.βc)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λc) : Zt
end

"""
    predict(fit::DeltaLogNormalFit, Y; type=:response) -> p×n matrix

In-sample predictions at the Laplace mode. `type=:link` is the positive-part linear
predictor `η^c = β^c + Λ_c ẑ`; `:occurrence` the presence probability `π = logistic(β^z)`;
`:positive` the conditional positive mean `exp(η^c + σ²/2)`; `:response` the
unconditional mean `π · exp(η^c + σ²/2)`.
"""
function predict(fit::DeltaLogNormalFit, Y::AbstractMatrix{<:Real}; type::Symbol = :response)
    type in (:response, :occurrence, :positive, :link) ||
        throw(ArgumentError("type must be :response, :occurrence, :positive, or :link; got :$type"))
    p, n = size(Y)
    Z = getLV(fit, Y; rotate = false)
    ηc = fit.βc .+ fit.Λc * Z'                       # p×n
    type === :link && return ηc
    π = inv.(1 .+ exp.(-fit.βz))                     # length p
    type === :occurrence && return repeat(π, 1, n)
    posmean = exp.(ηc .+ fit.σ^2 / 2)
    type === :positive && return posmean
    return π .* posmean
end

"""
    residuals(fit::DeltaLogNormalFit, Y; rng=Random.default_rng()) -> p×n matrix

Dunn–Smyth randomized quantile residuals for the two-part fit: `Φ⁻¹(u)` with
`u = (1−π) + π·G(y)` for `y>0` (`G` the lognormal CDF) and `u` uniform on `[0, 1−π]`
for `y=0` — ≈ N(0,1) under a correct model (pass a fixed `rng` to reproduce).
"""
function residuals(fit::DeltaLogNormalFit, Y::AbstractMatrix{<:Real};
                   rng::AbstractRNG = Random.default_rng())
    p, n = size(Y)
    Z = getLV(fit, Y; rotate = false)
    ηc = fit.βc .+ fit.Λc * Z'
    π = inv.(1 .+ exp.(-fit.βz))
    R = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        πt = π[t]
        if Y[t, s] > 0
            u = (1 - πt) + πt * cdf(LogNormal(ηc[t, s], fit.σ), Y[t, s])
        else
            u = (1 - πt) * rand(rng)
        end
        R[t, s] = quantile(Normal(), clamp(u, 1e-12, 1 - 1e-12))
    end
    return R
end

function Base.show(io::IO, ::MIME"text/plain", fit::DeltaLogNormalFit)
    p, K = size(fit.Λc)
    println(io, "Delta-lognormal GLLVM fit (two-part)")
    println(io, "  responses p = ", p, ", latent factors K = ", K,
            ", log-SD σ = ", round(fit.σ; sigdigits = 4))
    println(io, "  logLik = ", round(fit.loglik; sigdigits = 7),
            ", AIC = ", round(aic(fit); sigdigits = 7))
    print(io,   "  converged = ", fit.converged, " (", fit.iterations, " iterations)")
end

# ---------------------------------------------------------------------------
# Hurdle-Poisson post-fit (occurrence Bernoulli × zero-truncated Poisson count).
# ---------------------------------------------------------------------------

_loadings(fit::HurdlePoissonFit) = fit.Λc
_loglik(fit::HurdlePoissonFit)   = fit.loglik

function _nparams(fit::HurdlePoissonFit)
    p, K = size(fit.Λc)
    return 2p + (p * K - div(K * (K - 1), 2))   # βz + βc + Λc (no dispersion)
end

function getLV(fit::HurdlePoissonFit, Y::AbstractMatrix{<:Real}; rotate::Bool = true)
    p, n = size(Y)
    K = size(fit.Λc, 2)
    Λz = zeros(p, K)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _twopart_mode(HurdlePoisson(), view(Y, :, s), Λz, fit.Λc, fit.βz, fit.βc)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λc) : Zt
end

"""
    predict(fit::HurdlePoissonFit, Y; type=:response) -> p×n matrix

`:link` = count log-mean predictor `η^c`; `:occurrence` = `π = logistic(β^z)`;
`:positive` = the zero-truncated count mean `μ/(1−e^{−μ})`; `:response` =
unconditional mean `π · μ/(1−e^{−μ})`.
"""
function predict(fit::HurdlePoissonFit, Y::AbstractMatrix{<:Real}; type::Symbol = :response)
    type in (:response, :occurrence, :positive, :link) ||
        throw(ArgumentError("type must be :response, :occurrence, :positive, or :link; got :$type"))
    p, n = size(Y)
    Z = getLV(fit, Y; rotate = false)
    ηc = fit.βc .+ fit.Λc * Z'
    type === :link && return ηc
    π = inv.(1 .+ exp.(-fit.βz))
    type === :occurrence && return repeat(π, 1, n)
    μ = exp.(ηc)
    μtr = μ ./ (1 .- exp.(-μ))
    type === :positive && return μtr
    return π .* μtr
end

"""
    residuals(fit::HurdlePoissonFit, Y; rng=Random.default_rng()) -> p×n matrix

Dunn–Smyth randomized quantile residuals for the discrete two-part fit: `Φ⁻¹(u)`
with `u` uniform on `[F(y−1), F(y)]` under the hurdle CDF
`F(k) = (1−π) + π·F_trunc(k)` (`F_trunc` the zero-truncated Poisson CDF).
"""
function residuals(fit::HurdlePoissonFit, Y::AbstractMatrix{<:Real};
                   rng::AbstractRNG = Random.default_rng())
    p, n = size(Y)
    Z = getLV(fit, Y; rotate = false)
    ηc = fit.βc .+ fit.Λc * Z'
    π = inv.(1 .+ exp.(-fit.βz))
    R = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        πt = π[t]; y = Int(Y[t, s])
        if y == 0
            lo = 0.0; hi = 1 - πt
        else
            μ = exp(ηc[t, s]); p0 = exp(-μ)
            Flo = y == 1 ? 0.0 : (cdf(Poisson(μ), y - 1) - p0) / (1 - p0)
            Fhi = (cdf(Poisson(μ), y) - p0) / (1 - p0)
            lo = (1 - πt) + πt * Flo
            hi = (1 - πt) + πt * Fhi
        end
        u = lo + (hi - lo) * rand(rng)
        R[t, s] = quantile(Normal(), clamp(u, 1e-12, 1 - 1e-12))
    end
    return R
end

function Base.show(io::IO, ::MIME"text/plain", fit::HurdlePoissonFit)
    p, K = size(fit.Λc)
    println(io, "Hurdle-Poisson GLLVM fit (two-part)")
    println(io, "  responses p = ", p, ", latent factors K = ", K)
    println(io, "  logLik = ", round(fit.loglik; sigdigits = 7),
            ", AIC = ", round(aic(fit); sigdigits = 7))
    print(io,   "  converged = ", fit.converged, " (", fit.iterations, " iterations)")
end

# ---------------------------------------------------------------------------
# Hurdle-NB post-fit (occurrence Bernoulli × zero-truncated NB2 count).
# ---------------------------------------------------------------------------

_loadings(fit::HurdleNBFit) = fit.Λc
_loglik(fit::HurdleNBFit)   = fit.loglik

function _nparams(fit::HurdleNBFit)
    p, K = size(fit.Λc)
    return 2p + (p * K - div(K * (K - 1), 2)) + 1   # βz + βc + Λc + r
end

function getLV(fit::HurdleNBFit, Y::AbstractMatrix{<:Real}; rotate::Bool = true)
    p, n = size(Y); K = size(fit.Λc, 2)
    Λz = zeros(p, K)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _twopart_mode(HurdleNB(fit.r), view(Y, :, s), Λz, fit.Λc, fit.βz, fit.βc)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λc) : Zt
end

"""
    predict(fit::HurdleNBFit, Y; type=:response) -> p×n matrix

`:link` = `η^c`; `:occurrence` = `π`; `:positive` = zero-truncated NB mean
`μ/(1−p₀)` (`p₀=(r/(r+μ))^r`); `:response` = `π · μ/(1−p₀)`.
"""
function predict(fit::HurdleNBFit, Y::AbstractMatrix{<:Real}; type::Symbol = :response)
    type in (:response, :occurrence, :positive, :link) ||
        throw(ArgumentError("type must be :response, :occurrence, :positive, or :link; got :$type"))
    p, n = size(Y)
    Z = getLV(fit, Y; rotate = false)
    ηc = fit.βc .+ fit.Λc * Z'
    type === :link && return ηc
    π = inv.(1 .+ exp.(-fit.βz))
    type === :occurrence && return repeat(π, 1, n)
    μ = exp.(ηc); r = fit.r
    μtr = μ ./ (1 .- (r ./ (r .+ μ)) .^ r)
    type === :positive && return μtr
    return π .* μtr
end

"""
    residuals(fit::HurdleNBFit, Y; rng=Random.default_rng()) -> p×n matrix

Dunn–Smyth randomized quantile residuals for the discrete two-part fit, using the
hurdle CDF `F(k) = (1−π) + π·F_trunc(k)` (`F_trunc` the zero-truncated NB2 CDF).
"""
function residuals(fit::HurdleNBFit, Y::AbstractMatrix{<:Real};
                   rng::AbstractRNG = Random.default_rng())
    p, n = size(Y); r = fit.r
    Z = getLV(fit, Y; rotate = false)
    ηc = fit.βc .+ fit.Λc * Z'
    π = inv.(1 .+ exp.(-fit.βz))
    R = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        πt = π[t]; y = Int(Y[t, s])
        if y == 0
            lo = 0.0; hi = 1 - πt
        else
            μ = exp(ηc[t, s]); p0 = (r / (r + μ))^r
            nb = NegativeBinomial(r, r / (r + μ))
            Flo = y == 1 ? 0.0 : (cdf(nb, y - 1) - p0) / (1 - p0)
            Fhi = (cdf(nb, y) - p0) / (1 - p0)
            lo = (1 - πt) + πt * Flo
            hi = (1 - πt) + πt * Fhi
        end
        u = lo + (hi - lo) * rand(rng)
        R[t, s] = quantile(Normal(), clamp(u, 1e-12, 1 - 1e-12))
    end
    return R
end

function Base.show(io::IO, ::MIME"text/plain", fit::HurdleNBFit)
    p, K = size(fit.Λc)
    println(io, "Hurdle-NB GLLVM fit (two-part)")
    println(io, "  responses p = ", p, ", latent factors K = ", K,
            ", dispersion r = ", round(fit.r; sigdigits = 4))
    println(io, "  logLik = ", round(fit.loglik; sigdigits = 7),
            ", AIC = ", round(aic(fit); sigdigits = 7))
    print(io,   "  converged = ", fit.converged, " (", fit.iterations, " iterations)")
end

# ---------------------------------------------------------------------------
# Delta-Gamma post-fit (occurrence Bernoulli × positive Gamma, log-link mean).
# ---------------------------------------------------------------------------

_loadings(fit::DeltaGammaFit) = fit.Λc
_loglik(fit::DeltaGammaFit)   = fit.loglik

function _nparams(fit::DeltaGammaFit)
    p, K = size(fit.Λc)
    return 2p + (p * K - div(K * (K - 1), 2)) + 1   # βz + βc + Λc + α
end

"""
    getLV(fit::DeltaGammaFit, Y; rotate=true) -> n×K matrix

Conditional latent scores for a Delta-Gamma fit: the per-site two-part Laplace mode
`ẑₛ` (occurrence intercept-only, so only the positive part loads on `z`).
"""
function getLV(fit::DeltaGammaFit, Y::AbstractMatrix{<:Real}; rotate::Bool = true)
    p, n = size(Y); K = size(fit.Λc, 2)
    fam = DeltaGamma(fit.α)
    Λz = zeros(p, K)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _twopart_mode(fam, view(Y, :, s), Λz, fit.Λc, fit.βz, fit.βc)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λc) : Zt
end

"""
    predict(fit::DeltaGammaFit, Y; type=:response) -> p×n matrix

`:link` = positive-part log-mean predictor `η^c`; `:occurrence` = presence
probability `π = logistic(β^z)`; `:positive` = conditional positive mean `μ = exp(η^c)`
(the Gamma mean); `:response` = unconditional mean `π · μ`.
"""
function predict(fit::DeltaGammaFit, Y::AbstractMatrix{<:Real}; type::Symbol = :response)
    type in (:response, :occurrence, :positive, :link) ||
        throw(ArgumentError("type must be :response, :occurrence, :positive, or :link; got :$type"))
    p, n = size(Y)
    Z = getLV(fit, Y; rotate = false)
    ηc = fit.βc .+ fit.Λc * Z'                       # p×n
    type === :link && return ηc
    π = inv.(1 .+ exp.(-fit.βz))                     # length p
    type === :occurrence && return repeat(π, 1, n)
    μ = exp.(ηc)
    type === :positive && return μ
    return π .* μ
end

"""
    residuals(fit::DeltaGammaFit, Y; rng=Random.default_rng()) -> p×n matrix

Dunn–Smyth randomized quantile residuals for the two-part fit: `Φ⁻¹(u)` with
`u = (1−π) + π·G(y)` for `y>0` (`G` the Gamma CDF) and `u` uniform on `[0, 1−π]`
for `y=0` — ≈ N(0,1) under a correct model (pass a fixed `rng` to reproduce).
"""
function residuals(fit::DeltaGammaFit, Y::AbstractMatrix{<:Real};
                   rng::AbstractRNG = Random.default_rng())
    p, n = size(Y); α = fit.α
    Z = getLV(fit, Y; rotate = false)
    ηc = fit.βc .+ fit.Λc * Z'
    π = inv.(1 .+ exp.(-fit.βz))
    R = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        πt = π[t]
        if Y[t, s] > 0
            μ = exp(ηc[t, s])
            u = (1 - πt) + πt * cdf(Gamma(α, μ / α), Y[t, s])
        else
            u = (1 - πt) * rand(rng)
        end
        R[t, s] = quantile(Normal(), clamp(u, 1e-12, 1 - 1e-12))
    end
    return R
end

function Base.show(io::IO, ::MIME"text/plain", fit::DeltaGammaFit)
    p, K = size(fit.Λc)
    println(io, "Delta-Gamma GLLVM fit (two-part)")
    println(io, "  responses p = ", p, ", latent factors K = ", K,
            ", shape α = ", round(fit.α; sigdigits = 4))
    println(io, "  logLik = ", round(fit.loglik; sigdigits = 7),
            ", AIC = ", round(aic(fit); sigdigits = 7))
    print(io,   "  converged = ", fit.converged, " (", fit.iterations, " iterations)")
end

# ---------------------------------------------------------------------------
# Zero-inflated post-fit (ZIP / ZINB: structural zero × Poisson / NB2 count).
# Unconditional mean is (1−π)·μ (structural zeros contribute 0).
# ---------------------------------------------------------------------------

_loadings(fit::ZIPFit) = fit.Λc
_loglik(fit::ZIPFit)   = fit.loglik
_loadings(fit::ZINBFit) = fit.Λc
_loglik(fit::ZINBFit)   = fit.loglik

function _nparams(fit::ZIPFit)
    p, K = size(fit.Λc)
    return 2p + (p * K - div(K * (K - 1), 2))        # βz + βc + Λc
end
function _nparams(fit::ZINBFit)
    p, K = size(fit.Λc)
    return 2p + (p * K - div(K * (K - 1), 2)) + 1     # βz + βc + Λc + r
end

function getLV(fit::ZIPFit, Y::AbstractMatrix{<:Real}; rotate::Bool = true)
    p, n = size(Y); K = size(fit.Λc, 2)
    Λz = zeros(p, K)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _twopart_mode(ZIPoisson(), view(Y, :, s), Λz, fit.Λc, fit.βz, fit.βc)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λc) : Zt
end

function getLV(fit::ZINBFit, Y::AbstractMatrix{<:Real}; rotate::Bool = true)
    p, n = size(Y); K = size(fit.Λc, 2)
    Λz = zeros(p, K)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _twopart_mode(ZINB(fit.r), view(Y, :, s), Λz, fit.Λc, fit.βz, fit.βc)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λc) : Zt
end

"""
    predict(fit::ZIPFit, Y; type=:response) -> p×n matrix

`:link` = count log-mean predictor `η^c`; `:zeroinfl` = structural-zero
probability `π = logistic(β^z)`; `:mean` = the count mean `μ = exp(η^c)`;
`:response` = unconditional mean `(1−π)·μ`.
"""
function predict(fit::ZIPFit, Y::AbstractMatrix{<:Real}; type::Symbol = :response)
    type in (:response, :zeroinfl, :mean, :link) ||
        throw(ArgumentError("type must be :response, :zeroinfl, :mean, or :link; got :$type"))
    p, n = size(Y)
    Z = getLV(fit, Y; rotate = false)
    ηc = fit.βc .+ fit.Λc * Z'
    type === :link && return ηc
    π = inv.(1 .+ exp.(-fit.βz))
    type === :zeroinfl && return repeat(π, 1, n)
    μ = exp.(ηc)
    type === :mean && return μ
    return (1 .- π) .* μ
end

"""
    predict(fit::ZINBFit, Y; type=:response) -> p×n matrix

As [`predict(::ZIPFit, …)`](@ref); `:mean` is the NB2 count mean `μ`, `:response`
the unconditional mean `(1−π)·μ`.
"""
function predict(fit::ZINBFit, Y::AbstractMatrix{<:Real}; type::Symbol = :response)
    type in (:response, :zeroinfl, :mean, :link) ||
        throw(ArgumentError("type must be :response, :zeroinfl, :mean, or :link; got :$type"))
    p, n = size(Y)
    Z = getLV(fit, Y; rotate = false)
    ηc = fit.βc .+ fit.Λc * Z'
    type === :link && return ηc
    π = inv.(1 .+ exp.(-fit.βz))
    type === :zeroinfl && return repeat(π, 1, n)
    μ = exp.(ηc)
    type === :mean && return μ
    return (1 .- π) .* μ
end

# Dunn–Smyth residuals for the zero-inflated CDF F(k) = π + (1−π)·F_count(k).
function _zi_residuals(π::AbstractVector, ηc::AbstractMatrix, Y::AbstractMatrix,
                       countdist, rng::AbstractRNG)
    p, n = size(Y)
    R = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        πt = π[t]; y = Int(Y[t, s])
        d = countdist(exp(ηc[t, s]))
        if y == 0
            lo = 0.0
            hi = πt + (1 - πt) * cdf(d, 0)
        else
            lo = πt + (1 - πt) * cdf(d, y - 1)
            hi = πt + (1 - πt) * cdf(d, y)
        end
        u = lo + (hi - lo) * rand(rng)
        R[t, s] = quantile(Normal(), clamp(u, 1e-12, 1 - 1e-12))
    end
    return R
end

"""
    residuals(fit::ZIPFit, Y; rng=Random.default_rng()) -> p×n matrix

Dunn–Smyth randomized quantile residuals under the zero-inflated CDF
`F(k) = π + (1−π)·F_Poisson(k)`.
"""
function residuals(fit::ZIPFit, Y::AbstractMatrix{<:Real};
                   rng::AbstractRNG = Random.default_rng())
    Z = getLV(fit, Y; rotate = false)
    ηc = fit.βc .+ fit.Λc * Z'
    π = inv.(1 .+ exp.(-fit.βz))
    return _zi_residuals(π, ηc, Y, μ -> Poisson(μ), rng)
end

"""
    residuals(fit::ZINBFit, Y; rng=Random.default_rng()) -> p×n matrix

Dunn–Smyth randomized quantile residuals under `F(k) = π + (1−π)·F_NB2(k)`.
"""
function residuals(fit::ZINBFit, Y::AbstractMatrix{<:Real};
                   rng::AbstractRNG = Random.default_rng())
    Z = getLV(fit, Y; rotate = false)
    ηc = fit.βc .+ fit.Λc * Z'
    π = inv.(1 .+ exp.(-fit.βz)); r = fit.r
    return _zi_residuals(π, ηc, Y, μ -> NegativeBinomial(r, r / (r + μ)), rng)
end

function Base.show(io::IO, ::MIME"text/plain", fit::ZIPFit)
    p, K = size(fit.Λc)
    println(io, "Zero-inflated Poisson GLLVM fit (two-part)")
    println(io, "  responses p = ", p, ", latent factors K = ", K)
    println(io, "  logLik = ", round(fit.loglik; sigdigits = 7),
            ", AIC = ", round(aic(fit); sigdigits = 7))
    print(io,   "  converged = ", fit.converged, " (", fit.iterations, " iterations)")
end

function Base.show(io::IO, ::MIME"text/plain", fit::ZINBFit)
    p, K = size(fit.Λc)
    println(io, "Zero-inflated NB GLLVM fit (two-part)")
    println(io, "  responses p = ", p, ", latent factors K = ", K,
            ", dispersion r = ", round(fit.r; sigdigits = 4))
    println(io, "  logLik = ", round(fit.loglik; sigdigits = 7),
            ", AIC = ", round(aic(fit); sigdigits = 7))
    print(io,   "  converged = ", fit.converged, " (", fit.iterations, " iterations)")
end

# ---------------------------------------------------------------------------
# Zero-inflated binomial post-fit (ZIB: structural zero × Binomial(N, μ) count,
# μ = logistic(η^c), N trials fixed — no dispersion). Mirrors ZINB, swapping the
# NB2 count for Binomial(N, μ). Unconditional mean is (1−π)·N·μ.
# ---------------------------------------------------------------------------

_loadings(fit::ZIBFit) = fit.Λc
_loglik(fit::ZIBFit)   = fit.loglik

function _nparams(fit::ZIBFit)
    p, K = size(fit.Λc)
    return 2p + (p * K - div(K * (K - 1), 2))        # βz + βc + Λc (N fixed, no dispersion)
end

function getLV(fit::ZIBFit, Y::AbstractMatrix{<:Real}; rotate::Bool = true)
    p, n = size(Y); K = size(fit.Λc, 2)
    Λz = zeros(p, K)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _twopart_mode(ZIB(fit.N), view(Y, :, s), Λz, fit.Λc, fit.βz, fit.βc)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λc) : Zt
end

"""
    predict(fit::ZIBFit, Y; type=:response) -> p×n matrix

`:link` = count success-logit predictor `η^c`; `:zeroinfl` = structural-zero
probability `π = logistic(β^z)`; `:mean` = the binomial mean `N·μ`
(`μ = logistic(η^c)`); `:response` = unconditional mean `(1−π)·N·μ`.
"""
function predict(fit::ZIBFit, Y::AbstractMatrix{<:Real}; type::Symbol = :response)
    type in (:response, :zeroinfl, :mean, :link) ||
        throw(ArgumentError("type must be :response, :zeroinfl, :mean, or :link; got :$type"))
    p, n = size(Y)
    Z = getLV(fit, Y; rotate = false)
    ηc = fit.βc .+ fit.Λc * Z'
    type === :link && return ηc
    π = inv.(1 .+ exp.(-fit.βz))
    type === :zeroinfl && return repeat(π, 1, n)
    μ = inv.(1 .+ exp.(-ηc))                          # logit link for the count part
    type === :mean && return fit.N .* μ
    return (1 .- π) .* (fit.N .* μ)
end

"""
    residuals(fit::ZIBFit, Y; rng=Random.default_rng()) -> p×n matrix

Dunn–Smyth randomized quantile residuals under the zero-inflated CDF
`F(k) = π + (1−π)·F_Binomial(N,μ)(k)`.
"""
function residuals(fit::ZIBFit, Y::AbstractMatrix{<:Real};
                   rng::AbstractRNG = Random.default_rng())
    p, n = size(Y)
    Z = getLV(fit, Y; rotate = false)
    ηc = fit.βc .+ fit.Λc * Z'
    π = inv.(1 .+ exp.(-fit.βz))
    R = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        πt = π[t]; y = Int(Y[t, s])
        μ = inv(1 + exp(-ηc[t, s]))
        d = Binomial(fit.N, μ)
        if y == 0
            lo = 0.0
            hi = πt + (1 - πt) * cdf(d, 0)
        else
            lo = πt + (1 - πt) * cdf(d, y - 1)
            hi = πt + (1 - πt) * cdf(d, y)
        end
        u = lo + (hi - lo) * rand(rng)
        R[t, s] = quantile(Normal(), clamp(u, 1e-12, 1 - 1e-12))
    end
    return R
end

function Base.show(io::IO, ::MIME"text/plain", fit::ZIBFit)
    p, K = size(fit.Λc)
    println(io, "Zero-inflated binomial GLLVM fit (two-part)")
    println(io, "  responses p = ", p, ", latent factors K = ", K, ", trials N = ", fit.N)
    println(io, "  logLik = ", round(fit.loglik; sigdigits = 7),
            ", AIC = ", round(aic(fit); sigdigits = 7))
    print(io,   "  converged = ", fit.converged, " (", fit.iterations, " iterations)")
end

# ---------------------------------------------------------------------------
# Tweedie post-fit (compound Poisson–Gamma, power 1 < p < 2; mean μ = exp(η),
# dispersion φ, Var = φ μ^p; point mass at 0 plus a positive continuous part).
# Scalar-μ family, mirroring Gamma; the Tweedie CDF is mixed (atom at 0 + density
# for y>0), so the Dunn–Smyth residual randomises the jump at 0 and is the
# deterministic PIT on the positive part.
# ---------------------------------------------------------------------------

_loadings(fit::TweedieFit) = fit.Λ
_loglik(fit::TweedieFit)   = fit.loglik

function _nparams(fit::TweedieFit)
    p, K = size(fit.Λ)
    return p + (p * K - div(K * (K - 1), 2)) + 2       # β + Λ + dispersion φ + power p
end

"""
    getLV(fit::TweedieFit, Y; rotate=true) -> n×K matrix

Conditional latent-variable scores for a Tweedie fit: the per-site Laplace mode
`ẑₛ` (computed at the fitted dispersion `φ` and power `p`). `Y` is the p×n matrix
of non-negative reals; `rotate=true` applies the canonical [`rotation`](@ref).
"""
function getLV(fit::TweedieFit, Y::AbstractMatrix{<:Real}; rotate::Bool = true)
    p, n = size(Y)
    K = size(fit.Λ, 2)
    fam = TweedieED(fit.φ, fit.p)
    ones_p = ones(Int, p)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _laplace_mode(fam, view(Y, :, s), ones_p, fit.Λ, fit.β, fit.link)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

"""
    predict(fit::TweedieFit, Y; type=:response) -> p×n matrix

In-sample fitted values at the Laplace mode: `type=:link` returns `η = β + Λ ẑ`;
`type=:response` the inverse-link fitted means `linkinv(link, η) = exp(η)`
(non-negative reals).
"""
function predict(fit::TweedieFit, Y::AbstractMatrix{<:Real}; type::Symbol = :response)
    type in (:link, :response) ||
        throw(ArgumentError("type must be :link or :response; got :$type"))
    Z = getLV(fit, Y; rotate = false)
    η = fit.β .+ fit.Λ * Z'
    type === :link && return η
    return linkinv.(Ref(fit.link), _clamp_eta.(η))
end

"""
    residuals(fit::TweedieFit, Y; type=:dunnsmyth, rng=Random.default_rng()) -> p×n matrix

Conditional residuals for a Tweedie fit. The Tweedie CDF has an atom at `0` plus a
continuous positive part, so the `:dunnsmyth` randomized quantile residual draws
`u` uniform on `[0, F(0)]` at `y=0` and is the deterministic PIT `Φ⁻¹(F(y))` for
`y>0` — ≈ N(0,1) under a correct model (pass a fixed `rng` to reproduce). `:pearson`
returns `(Y − μ) / √(φ μ^p)`.
"""
function residuals(fit::TweedieFit, Y::AbstractMatrix{<:Real};
                   type::Symbol = :dunnsmyth, rng::AbstractRNG = Random.default_rng())
    type in (:dunnsmyth, :pearson) ||
        throw(ArgumentError("type must be :dunnsmyth or :pearson; got :$type"))
    p, n = size(Y)
    φ = fit.φ; pw = fit.p
    μ = predict(fit, Y; type = :response)
    if type === :pearson
        return (Y .- μ) ./ sqrt.(φ .* μ .^ pw)
    end
    R = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        if Y[t, s] <= 0
            F0 = exp(tweedie_logpdf(0.0, μ[t, s], φ, pw))   # P(Y = 0) (the atom)
            u = F0 * rand(rng)
        else
            u = tweedie_cdf(float(Y[t, s]), μ[t, s], φ, pw) # atom + positive-part CDF
        end
        R[t, s] = quantile(Normal(), clamp(u, 1e-12, 1 - 1e-12))
    end
    return R
end

function Base.show(io::IO, ::MIME"text/plain", fit::TweedieFit)
    p, K = size(fit.Λ)
    println(io, "Tweedie GLLVM fit")
    println(io, "  responses p = ", p, ", latent factors K = ", K,
            ", link = ", nameof(typeof(fit.link)),
            ", φ = ", round(fit.φ; sigdigits = 4), ", power = ", round(fit.p; sigdigits = 4))
    println(io, "  logLik = ", round(fit.loglik; sigdigits = 7),
            ", AIC = ", round(aic(fit); sigdigits = 7))
    print(io,   "  converged = ", fit.converged, " (", fit.iterations, " iterations)")
end

# ---------------------------------------------------------------------------
# Covariate-fit post-fit (GllvmCovFit: η = β + Xγ + Λẑ). Needs the (p,n,q) design
# `X` (and Binomial trial counts `N`) to rebuild the linear predictor.
# ---------------------------------------------------------------------------

_loadings(fit::GllvmCovFit) = fit.Λ
_loglik(fit::GllvmCovFit)   = fit.loglik

function _nparams(fit::GllvmCovFit)
    p, K = size(fit.Λ); q = count(!, fit.γ_fixed)
    return p + q + (p * K - div(K * (K - 1), 2)) + (isnan(fit.dispersion) ? 0 : 1)
end

"""
    getLV(fit::GllvmCovFit, Y, X; rotate=true, N=nothing) -> n×K matrix

Conditional latent scores for a covariate fit: the per-site offset-aware Laplace
mode `ẑₛ` at `η = β + Xγ + Λz`.
"""
function getLV(fit::GllvmCovFit, Y::AbstractMatrix{<:Real}, X::AbstractArray{<:Real, 3};
               rotate::Bool = true, N::Union{Nothing, AbstractMatrix} = nothing)
    p, n = size(Y); K = size(fit.Λ, 2)
    Nm = N === nothing ? fill(1, p, n) : N
    fam = _cov_family(fit.family, fit.dispersion)
    O = _build_offset(X, fit.γ)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        η0 = fit.β .+ view(O, :, s)
        Z[:, s] = _laplace_mode_off(fam, view(Y, :, s), view(Nm, :, s), fit.Λ, η0, fit.link)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

"""
    predict(fit::GllvmCovFit, Y, X; type=:response, N=nothing) -> p×n matrix

`:link` = the linear predictor `η = β + Xγ + Λẑ`; `:response` (= `:mean`) = the
mean `μ = linkinv(link, η)` (a probability for Binomial, a positive mean for the
count/positive families).
"""
function predict(fit::GllvmCovFit, Y::AbstractMatrix{<:Real}, X::AbstractArray{<:Real, 3};
                 type::Symbol = :response, N::Union{Nothing, AbstractMatrix} = nothing)
    type in (:response, :mean, :link) ||
        throw(ArgumentError("type must be :response, :mean, or :link; got :$type"))
    Z = getLV(fit, Y, X; rotate = false, N = N)
    O = _build_offset(X, fit.γ)
    η = fit.β .+ O .+ fit.Λ * Z'
    type === :link && return η
    return linkinv.(Ref(fit.link), _clamp_eta.(η))
end

"""
    fitted(fit::GllvmCovFit, Y, X; N=nothing) -> p×n matrix of fitted means.
"""
fitted(fit::GllvmCovFit, Y::AbstractMatrix{<:Real}, X::AbstractArray{<:Real, 3};
       N::Union{Nothing, AbstractMatrix} = nothing) =
    predict(fit, Y, X; type = :response, N = N)

"""
    predict(fit::GllvmCovFit, X; type=:response) -> p×n matrix

Population-level (new-site) prediction at a covariate design `X` (`(p, n, q)`) with
the latent at its prior mean `z = 0` — the latent is not estimable at unseen sites.
`:link` returns the fixed-effect linear predictor `η = β + Xγ`; `:response`
(= `:mean`) the mean `μ = linkinv(link, η)`. (For in-sample *conditional*
predictions at the fitted sites, use the three-argument `predict(fit, Y, X)`.)
"""
function predict(fit::GllvmCovFit, X::AbstractArray{<:Real, 3}; type::Symbol = :response)
    type in (:response, :mean, :link) ||
        throw(ArgumentError("type must be :response, :mean, or :link; got :$type"))
    O = _build_offset(X, fit.γ)
    η = fit.β .+ O
    type === :link && return η
    return linkinv.(Ref(fit.link), _clamp_eta.(η))
end

function Base.show(io::IO, ::MIME"text/plain", fit::GllvmCovFit)
    p, K = size(fit.Λ); q = length(fit.γ)
    println(io, "GLLVM fit with covariates (", nameof(typeof(fit.family)), ", Laplace)")
    println(io, "  responses p = ", p, ", covariates q = ", q, ", latent factors K = ", K,
            isnan(fit.dispersion) ? "" : ", dispersion = $(round(fit.dispersion; sigdigits = 4))")
    println(io, "  logLik = ", round(fit.loglik; sigdigits = 7),
            ", AIC = ", round(aic(fit); sigdigits = 7))
    print(io,   "  converged = ", fit.converged, " (", fit.iterations, " iterations)")
end
