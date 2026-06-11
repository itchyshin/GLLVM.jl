# Post-fit predict/fitted + getLV for the newer one-part GLLVM fit types that
# postfit.jl does not yet cover: NB1Fit, LognormalFit, BetaBinomialFit,
# StudentTFit, TruncPoissonFit, TruncNBFit, ZIPFit, ZINBFit.
#
# This mirrors the PoissonFit / NBFit / BetaFit / GammaFit methods in postfit.jl
# exactly: for the seven LAPLACE families (NB1, BetaBinomial, StudentT, the two
# truncated and the two zero-inflated counts) the per-site conditional latent score
# is the Laplace mode `ẑₛ`, found by the SAME inner Fisher-scoring solver every
# other family uses (`_laplace_mode`, families/laplace.jl). The only per-type
# wrinkle is the family marker passed to that solver, taken from the already-defined
# `_fit_family(fit)` accessor (link_residual.jl) so each family's score/weight
# pieces dispatch correctly — exactly as the template's `getLV(::PoissonFit)` /
# `getLV(::NBFit)` pass `Poisson()` / `NegativeBinomial(fit.r, 0.5)` by hand.
#
# LognormalFit is the exception: the standalone Lognormal IS the Gaussian GLLVM on
# `log(Y)` (it defines no `_glm_*` Laplace pieces), so — like the Gaussian `getLV`
# in postfit.jl — its conditional score is the closed-form Gaussian factor-analysis
# posterior mean of the centred log-responses (residual covariance `σ²I`).
#
# `predict(...; type=:link)` returns the linear predictor `η = β + Λ ẑ`;
# `type=:response` applies the family's response-scale mean (see each docstring):
#   * NB1, StudentT, BetaBinomial : `linkinv(fit.link, η)` (log / identity / logit)
#   * Lognormal                   : `exp(η + σ²/2)` (the lognormal MEAN, not exp η)
#   * zero-truncated Poisson / NB : the truncated mean `μ/(1 − P₀)`
#   * zero-inflated Poisson / NB  : the marginal mean `(1 − π)·μ`
# `fitted` reuses the shared `fitted(fit, data; kwargs...)` generic in postfit.jl.
#
# ADDITIVE: this file defines new `getLV` / `predict` methods only (the generics
# and the `fitted` wrapper already exist in postfit.jl). It does NOT define
# residuals for these families: diagnostics.jl `quantile_residuals` (the shared
# per-family PIT hook `_pit`) has no method for any of these eight types, and the
# task brief is to skip residuals unless an existing clean per-family hook can be
# mirrored — there is none here, so residuals are intentionally omitted.

# Loadings accessors — each of these fit structs stores the p×K loadings in the
# `.Λ` field (exactly like PoissonFit/NBFit/…), so `_loadings(fit) = fit.Λ`. This
# is what the shared `getLoadings`/`rotation` (postfit.jl) and `check_fit`
# (diagnostics.jl) dispatch on, and what my `getLV`/`predict` rotations stay
# consistent with. (Mirrors the per-family `_loadings(fit::PoissonFit) = fit.Λ`
# lines in postfit.jl; additive new methods on the existing internal generic.)
_loadings(fit::NB1Fit)          = fit.Λ
_loadings(fit::LognormalFit)    = fit.Λ
_loadings(fit::BetaBinomialFit) = fit.Λ
_loadings(fit::StudentTFit)     = fit.Λ
_loadings(fit::TruncPoissonFit) = fit.Λ
_loadings(fit::TruncNBFit)      = fit.Λ
_loadings(fit::ZIPFit)          = fit.Λ
_loadings(fit::ZINBFit)         = fit.Λ

# ---------------------------------------------------------------------------
# NB1 post-fit (negative-binomial type 1; LINEAR variance Var = μ(1+φ); log link,
# mean μ = exp(η)). Parallel to NBFit, but the marker carries the dispersion φ.
# ---------------------------------------------------------------------------

"""
    getLV(fit::NB1Fit, Y; N=nothing, rotate=true) -> n×K matrix

Conditional latent-variable scores for an NB1 fit: the per-site Laplace mode `ẑₛ`
(computed at the fitted dispersion `φ`). `Y` is the p×n integer count matrix;
`rotate=true` applies the canonical [`rotation`](@ref). (`N` is accepted for
signature symmetry and ignored.)
"""
function getLV(fit::NB1Fit, Y::AbstractMatrix{<:Integer};
               N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing,
               rotate::Bool = true)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    K = size(fit.Λ, 2)
    fam = _fit_family(fit)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _laplace_mode(fam, view(Y, :, s), view(Nm, :, s), fit.Λ, fit.β, fit.link)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

"""
    predict(fit::NB1Fit, Y; type=:response, N=nothing) -> p×n matrix

In-sample fitted values at the Laplace mode: `type=:link` returns `η = β + Λ ẑ`;
`type=:response` the inverse-link fitted means `linkinv(link, η) = exp(η)`.
"""
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

# ---------------------------------------------------------------------------
# Lognormal post-fit (positive continuous; log(y) ~ Normal(η, σ²), log link). On
# the LOG scale the model is exactly the Gaussian GLLVM, so — like the Gaussian
# `getLV` in postfit.jl — the conditional latent score is the Gaussian factor-
# analysis posterior mean of the centred log-responses, NOT a generic Laplace mode
# (the standalone Lognormal family reuses the closed-form Gaussian machinery and
# defines no `_glm_*` Laplace pieces). The log-scale residual covariance is `σ²I`,
# so with R = log(Y) − β the posterior mean is
#   m_s = (I + Λᵀ(σ²I)⁻¹Λ)⁻¹ Λᵀ(σ²I)⁻¹ R_s .
# The RESPONSE-scale mean of a lognormal is exp(η + σ²/2) — NOT exp(η), the MEDIAN.
# ---------------------------------------------------------------------------

"""
    getLV(fit::LognormalFit, Y; rotate=true) -> n×K matrix

Conditional latent-variable scores for a Lognormal fit: the Gaussian posterior
mean on the log scale, `mₛ = (I + Λᵀ Ψ⁻¹ Λ)⁻¹ Λᵀ Ψ⁻¹ (log(yₛ) − β)` with residual
covariance `Ψ = σ² I` (the standalone Lognormal is exactly the Gaussian GLLVM on
`log(Y)`). `Y` is the p×n matrix of strictly positive responses; `rotate=true`
applies the canonical [`rotation`](@ref).
"""
function getLV(fit::LognormalFit, Y::AbstractMatrix{<:Real}; rotate::Bool = true)
    all(>(0), Y) || throw(ArgumentError("Lognormal responses must be strictly positive"))
    Λ = fit.Λ
    K = size(Λ, 2)
    R = log.(Y) .- fit.β                              # p×n centred log-responses
    Ψi = inv(fit.σ^2)                                 # Ψ⁻¹ = σ⁻² I (scalar)
    ΨiΛ = Ψi .* Λ
    M = Symmetric(I + Λ' * ΨiΛ)
    Z = M \ (ΨiΛ' * R)                                # K×n posterior means
    Zt = permutedims(Z)                              # n×K
    return rotate ? Zt * _svd_rotation(Λ) : Zt
end

"""
    predict(fit::LognormalFit, Y; type=:response) -> p×n matrix

In-sample fitted values at the conditional latent score (see [`getLV`](@ref)):
`type=:link` returns the log-scale linear predictor `η = β + Λ ẑ`; `type=:response`
the lognormal MEAN `exp(η + σ²/2)` (strictly positive). Note the response is the
mean, not `exp(η)` (the lognormal median).
"""
function predict(fit::LognormalFit, Y::AbstractMatrix{<:Real}; type::Symbol = :response)
    type in (:link, :response) ||
        throw(ArgumentError("type must be :link or :response; got :$type"))
    Z = getLV(fit, Y; rotate = false)
    η = fit.β .+ fit.Λ * Z'
    type === :link && return η
    return exp.(η .+ fit.σ^2 / 2)                     # lognormal mean E[y] = exp(η + σ²/2)
end

# ---------------------------------------------------------------------------
# Beta-Binomial post-fit (overdispersed binomial; logit link, mean probability
# μ = logistic(η), dispersion φ). Parallel to BinomialFit: the trial counts `N`
# enter the per-site Laplace mode, and `:response` returns the fitted PROBABILITY
# (in (0,1)), exactly as the Binomial predict does.
# ---------------------------------------------------------------------------

"""
    getLV(fit::BetaBinomialFit, Y; N=nothing, rotate=true) -> n×K matrix

Conditional latent-variable scores for a Beta-Binomial fit: the per-site Laplace
mode `ẑₛ` (computed at the fitted dispersion `φ`). `Y` is the p×n integer response
matrix; `N` the trial counts (default all-ones, i.e. Bernoulli, where the
Beta-Binomial is unidentified from Binomial). `rotate=true` applies the canonical
[`rotation`](@ref).
"""
function getLV(fit::BetaBinomialFit, Y::AbstractMatrix{<:Integer};
               N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing,
               rotate::Bool = true)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    K = size(fit.Λ, 2)
    fam = _fit_family(fit)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _laplace_mode(fam, view(Y, :, s), view(Nm, :, s), fit.Λ, fit.β, fit.link)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

"""
    predict(fit::BetaBinomialFit, Y; type=:response, N=nothing) -> p×n matrix

In-sample fitted values at the Laplace mode: `type=:link` returns `η = β + Λ ẑ`;
`type=:response` the inverse-link fitted probabilities `linkinv(link, η) =
logistic(η)` (in (0,1)). As with the Binomial predict, this is the per-trial
mean probability `μ`; the expected count is `N·μ`. `N` is the trial counts used
for the per-site mode solve (default all-ones).
"""
function predict(fit::BetaBinomialFit, Y::AbstractMatrix{<:Integer};
                 type::Symbol = :response,
                 N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing)
    type in (:link, :response) ||
        throw(ArgumentError("type must be :link or :response; got :$type"))
    Z = getLV(fit, Y; N = N, rotate = false)
    η = fit.β .+ fit.Λ * Z'
    type === :link && return η
    return linkinv.(Ref(fit.link), η)
end

# ---------------------------------------------------------------------------
# Student-t post-fit (heavy-tailed continuous; IDENTITY link, location μ = η). As
# in the Gaussian case the identity link makes `:link` and `:response` coincide.
# Responses are unconstrained reals.
# ---------------------------------------------------------------------------

"""
    getLV(fit::StudentTFit, Y; rotate=true) -> n×K matrix

Conditional latent-variable scores for a Student-t fit: the per-site Laplace mode
`ẑₛ` (computed at the fitted scale `σ` and fixed degrees of freedom `ν`). `Y` is
the p×n response matrix; `rotate=true` applies the canonical [`rotation`](@ref).
"""
function getLV(fit::StudentTFit, Y::AbstractMatrix{<:Real}; rotate::Bool = true)
    p, n = size(Y)
    K = size(fit.Λ, 2)
    fam = _fit_family(fit)
    ones_p = ones(Int, p)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _laplace_mode(fam, view(Y, :, s), ones_p, fit.Λ, fit.β, fit.link)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

"""
    predict(fit::StudentTFit, Y; type=:response) -> p×n matrix

In-sample fitted values at the Laplace mode: `type=:link` returns the linear
predictor `η = β + Λ ẑ`; `type=:response` the inverse-link fitted location
`linkinv(link, η) = η` (identity link, so both types coincide, as in the Gaussian
family).
"""
function predict(fit::StudentTFit, Y::AbstractMatrix{<:Real}; type::Symbol = :response)
    type in (:link, :response) ||
        throw(ArgumentError("type must be :link or :response; got :$type"))
    Z = getLV(fit, Y; rotate = false)
    η = fit.β .+ fit.Λ * Z'
    type === :link && return η
    return linkinv.(Ref(fit.link), η)                # identity link ⇒ μ = η
end

# ---------------------------------------------------------------------------
# Zero-truncated Poisson post-fit (positive counts y ≥ 1; log link, untruncated
# rate μ = exp(η)). The RESPONSE-scale mean is the TRUNCATED mean
# μ_tr = μ/(1 − e^{−μ}) ≥ 1, not the untruncated rate exp(η).
# ---------------------------------------------------------------------------

"""
    getLV(fit::TruncPoissonFit, Y; N=nothing, rotate=true) -> n×K matrix

Conditional latent-variable scores for a zero-truncated Poisson fit: the per-site
Laplace mode `ẑₛ`. `Y` is the p×n integer count matrix (entries `≥ 1`);
`rotate=true` applies the canonical [`rotation`](@ref). (`N` is accepted for
signature symmetry and ignored.)
"""
function getLV(fit::TruncPoissonFit, Y::AbstractMatrix{<:Integer};
               N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing,
               rotate::Bool = true)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    K = size(fit.Λ, 2)
    fam = _fit_family(fit)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _laplace_mode(fam, view(Y, :, s), view(Nm, :, s), fit.Λ, fit.β, fit.link)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

"""
    predict(fit::TruncPoissonFit, Y; type=:response, N=nothing) -> p×n matrix

In-sample fitted values at the Laplace mode: `type=:link` returns `η = β + Λ ẑ`;
`type=:response` the zero-truncated Poisson MEAN `μ_tr = μ/(1 − e^{−μ})` with
`μ = exp(η)` (`≥ 1`) — the response-scale mean of the positive-count law, not the
untruncated rate `exp(η)`.
"""
function predict(fit::TruncPoissonFit, Y::AbstractMatrix{<:Integer};
                 type::Symbol = :response,
                 N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing)
    type in (:link, :response) ||
        throw(ArgumentError("type must be :link or :response; got :$type"))
    Z = getLV(fit, Y; N = N, rotate = false)
    η = fit.β .+ fit.Λ * Z'
    type === :link && return η
    μ = exp.(η)
    return μ ./ (.-expm1.(.-μ))                       # μ_tr = μ/(1 − e^{−μ}) (stable form)
end

# ---------------------------------------------------------------------------
# Zero-truncated NB2 post-fit (positive counts y ≥ 1; log link, untruncated rate
# μ = exp(η), dispersion r). The RESPONSE-scale mean is the TRUNCATED mean
# μ_tr = μ/(1 − P₀), P₀ = (r/(r+μ))^r, not the untruncated rate exp(η).
# ---------------------------------------------------------------------------

"""
    getLV(fit::TruncNBFit, Y; N=nothing, rotate=true) -> n×K matrix

Conditional latent-variable scores for a zero-truncated NB2 fit: the per-site
Laplace mode `ẑₛ` (computed at the fitted dispersion `r`). `Y` is the p×n integer
count matrix (entries `≥ 1`); `rotate=true` applies the canonical
[`rotation`](@ref). (`N` is accepted for signature symmetry and ignored.)
"""
function getLV(fit::TruncNBFit, Y::AbstractMatrix{<:Integer};
               N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing,
               rotate::Bool = true)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    K = size(fit.Λ, 2)
    fam = _fit_family(fit)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _laplace_mode(fam, view(Y, :, s), view(Nm, :, s), fit.Λ, fit.β, fit.link)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

"""
    predict(fit::TruncNBFit, Y; type=:response, N=nothing) -> p×n matrix

In-sample fitted values at the Laplace mode: `type=:link` returns `η = β + Λ ẑ`;
`type=:response` the zero-truncated NB2 MEAN `μ_tr = μ/(1 − P₀)` with `μ = exp(η)`
and `P₀ = (r/(r+μ))^r` (`≥ 1`) — the response-scale mean of the positive-count
law, not the untruncated rate `exp(η)`.
"""
function predict(fit::TruncNBFit, Y::AbstractMatrix{<:Integer};
                 type::Symbol = :response,
                 N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing)
    type in (:link, :response) ||
        throw(ArgumentError("type must be :link or :response; got :$type"))
    Z = getLV(fit, Y; N = N, rotate = false)
    η = fit.β .+ fit.Λ * Z'
    type === :link && return η
    r = fit.r
    μ = exp.(η)
    P0 = (r ./ (r .+ μ)) .^ r
    return μ ./ (1 .- P0)                            # μ_tr = μ/(1 − P₀)
end

# ---------------------------------------------------------------------------
# Zero-inflated Poisson post-fit (counts y ≥ 0; log link, count rate μ = exp(η),
# zero-inflation π). The RESPONSE-scale (marginal) mean is (1 − π)·μ.
# ---------------------------------------------------------------------------

"""
    getLV(fit::ZIPFit, Y; N=nothing, rotate=true) -> n×K matrix

Conditional latent-variable scores for a zero-inflated Poisson fit: the per-site
Laplace mode `ẑₛ` (computed at the fitted zero-inflation `π`). `Y` is the p×n
integer count matrix; `rotate=true` applies the canonical [`rotation`](@ref).
(`N` is accepted for signature symmetry and ignored.)
"""
function getLV(fit::ZIPFit, Y::AbstractMatrix{<:Integer};
               N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing,
               rotate::Bool = true)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    K = size(fit.Λ, 2)
    fam = _fit_family(fit)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _laplace_mode(fam, view(Y, :, s), view(Nm, :, s), fit.Λ, fit.β, fit.link)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

"""
    predict(fit::ZIPFit, Y; type=:response, N=nothing) -> p×n matrix

In-sample fitted values at the Laplace mode: `type=:link` returns the COUNT linear
predictor `η = β + Λ ẑ`; `type=:response` the marginal mean `(1 − π)·exp(η)` (the
mixture `π·δ₀ + (1 − π)·Poisson(μ)` has mean `(1 − π)μ`), not the bare count rate
`exp(η)`.
"""
function predict(fit::ZIPFit, Y::AbstractMatrix{<:Integer};
                 type::Symbol = :response,
                 N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing)
    type in (:link, :response) ||
        throw(ArgumentError("type must be :link or :response; got :$type"))
    Z = getLV(fit, Y; N = N, rotate = false)
    η = fit.β .+ fit.Λ * Z'
    type === :link && return η
    return (1 - fit.π) .* exp.(η)                    # marginal mean (1 − π)·μ
end

# ---------------------------------------------------------------------------
# Zero-inflated NB2 post-fit (counts y ≥ 0; log link, count rate μ = exp(η),
# dispersion r, zero-inflation π). The RESPONSE-scale (marginal) mean is (1 − π)·μ.
# ---------------------------------------------------------------------------

"""
    getLV(fit::ZINBFit, Y; N=nothing, rotate=true) -> n×K matrix

Conditional latent-variable scores for a zero-inflated NB2 fit: the per-site
Laplace mode `ẑₛ` (computed at the fitted dispersion `r` and zero-inflation `π`).
`Y` is the p×n integer count matrix; `rotate=true` applies the canonical
[`rotation`](@ref). (`N` is accepted for signature symmetry and ignored.)
"""
function getLV(fit::ZINBFit, Y::AbstractMatrix{<:Integer};
               N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing,
               rotate::Bool = true)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    K = size(fit.Λ, 2)
    fam = _fit_family(fit)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _laplace_mode(fam, view(Y, :, s), view(Nm, :, s), fit.Λ, fit.β, fit.link)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

"""
    predict(fit::ZINBFit, Y; type=:response, N=nothing) -> p×n matrix

In-sample fitted values at the Laplace mode: `type=:link` returns the COUNT linear
predictor `η = β + Λ ẑ`; `type=:response` the marginal mean `(1 − π)·exp(η)` (the
mixture `π·δ₀ + (1 − π)·NB2(μ, r)` has mean `(1 − π)μ`), not the bare count rate
`exp(η)`.
"""
function predict(fit::ZINBFit, Y::AbstractMatrix{<:Integer};
                 type::Symbol = :response,
                 N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing)
    type in (:link, :response) ||
        throw(ArgumentError("type must be :link or :response; got :$type"))
    Z = getLV(fit, Y; N = N, rotate = false)
    η = fit.β .+ fit.Λ * Z'
    type === :link && return η
    return (1 - fit.π) .* exp.(η)                    # marginal mean (1 − π)·μ
end
