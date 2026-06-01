# Fixed-effect covariates (Xβ) for the non-Gaussian Laplace families.
#
# The non-Gaussian Laplace path (src/families/laplace.jl) has no covariate term:
# its linear predictor is η_{ts} = β_t + (Λ z_s)_t. This file adds the
# environmental fixed-effect surface that gllvmTMB centres on — an additive
# offset o_{ts} = Σ_k X[t,s,k]·γ_k on the linear predictor:
#
#     η_{ts} = β_t + o_{ts} + (Λ z_s)_t
#
# mirroring the Gaussian engine's X::(p,n,q) / coefficient contract (src/likelihood.jl,
# src/fit.jl). Because the offset is constant in z, the per-observation score and
# Fisher weight wrt η are unchanged, so the existing family pieces
# (`_glm_score` / `_glm_weight` / `_glm_logpdf` / `_clamp_mu`) are reused verbatim.
#
# Design choice: a STANDALONE offset-aware per-site Laplace (`_laplace_site_off`)
# rather than editing the shared core, so families without covariates are byte-for-
# byte unaffected. The shared `_default_link`/links/packing helpers are reused.
#
# Coefficient convention: `γ` (length q) is SHARED across species; the 3-D `X`
# encodes species- and site-varying covariates exactly as the Gaussian path does
# (a per-species response is a block-expanded column of `X`). The first slice
# fits with covariates and recovers `γ`; post-fit predict/CI integration for the
# `GllvmCovFit` type is a documented follow-up.

# --- offset-aware per-site Laplace (mirrors families/laplace.jl, with η0 = β + offset) ---

function _laplace_mode_off(family, y::AbstractVector, n::AbstractVector,
        Λ::AbstractMatrix, η0::AbstractVector, link::Link;
        maxiter::Integer = 100, tol::Real = 1e-9)
    K = size(Λ, 2)
    z = zeros(K)
    for _ in 1:maxiter
        η  = _clamp_eta.(η0 .+ Λ * z)
        μ  = _clamp_mu.(Ref(family), linkinv.(Ref(link), η))
        me = mu_eta.(Ref(link), η)
        s  = _glm_score.(Ref(family), μ, n, me, y)
        W  = _glm_weight.(Ref(family), μ, n, me)
        A  = Symmetric(Λ' * (W .* Λ) + I)
        Δ  = _safe_solve(A, Λ' * s .- z)
        (Δ === nothing || !all(isfinite, Δ)) && break
        z  = z .+ Δ
        maximum(abs, Δ) < tol && break
    end
    return z
end

function _laplace_site_off(family, y::AbstractVector, n::AbstractVector,
        Λ::AbstractMatrix, η0::AbstractVector, link::Link;
        maxiter::Integer = 100, tol::Real = 1e-9)
    p = size(Λ, 1)
    z  = _laplace_mode_off(family, y, n, Λ, η0, link; maxiter = maxiter, tol = tol)
    η  = _clamp_eta.(η0 .+ Λ * z)
    μ  = _clamp_mu.(Ref(family), linkinv.(Ref(link), η))
    me = mu_eta.(Ref(link), η)
    W  = _glm_weight.(Ref(family), μ, n, me)
    A  = Symmetric(Λ' * (W .* Λ) + I)
    ℓ = 0.0
    @inbounds for t in 1:p
        ℓ += _glm_logpdf(family, μ[t], n[t], y[t])
    end
    return ℓ - 0.5 * dot(z, z) - 0.5 * logdet(A)
end

# Total Laplace log-marginal with an additive per-(t,s) offset matrix `O` (p×n):
# η0_s = β + O[:, s].
function _marginal_loglik_offset(family, Y::AbstractMatrix, N::AbstractMatrix,
        Λ::AbstractMatrix, β::AbstractVector, O::AbstractMatrix, link::Link; kwargs...)
    acc = 0.0
    @inbounds for s in axes(Y, 2)
        η0 = β .+ view(O, :, s)
        acc += _laplace_site_off(family, view(Y, :, s), view(N, :, s), Λ, η0, link; kwargs...)
    end
    return acc
end

# Offset matrix O[t,s] = Σ_k X[t,s,k]·γ_k from X::(p,n,q) and γ::length-q.
function _build_offset(X::AbstractArray{<:Real, 3}, γ::AbstractVector)
    p, n, q = size(X)
    length(γ) == q || throw(DimensionMismatch("γ has length $(length(γ)) but X has q = $q covariates"))
    return reshape(reshape(X, p * n, q) * γ, p, n)
end

# --- family-specific bits (isolated so the fitter stays generic) ---
_cov_default_link(::Poisson)          = LogLink()
_cov_default_link(::NegativeBinomial) = LogLink()
_cov_default_link(::Binomial)         = LogitLink()
_cov_default_link(::Beta)             = LogitLink()
_cov_default_link(::Gamma)            = LogLink()

_cov_has_disp(::Poisson)          = false
_cov_has_disp(::Binomial)         = false
_cov_has_disp(::NegativeBinomial) = true
_cov_has_disp(::Beta)             = true
_cov_has_disp(::Gamma)            = true

_cov_disp_init(::NegativeBinomial) = 10.0
_cov_disp_init(::Beta)             = 10.0
_cov_disp_init(::Gamma)            = 2.0
_cov_disp_init(f)                  = 1.0

# Rebuild the family marker carrying the current dispersion (only the relevant
# field is read by the marginal pieces).
_cov_family(::Poisson, d)          = Poisson()
_cov_family(::Binomial, d)         = Binomial()
_cov_family(::NegativeBinomial, d) = NegativeBinomial(d, 0.5)
_cov_family(::Beta, d)             = Beta(d, 1.0)
_cov_family(::Gamma, d)            = Gamma(d, 1.0)

# CI term name for the dispersion parameter (if any).
_cov_dispname(::NegativeBinomial) = "r"
_cov_dispname(::Beta)             = "phi"
_cov_dispname(::Gamma)            = "alpha"
_cov_dispname(f)                  = "disp"

# Draw one response from `family` (carrying its dispersion) at mean `μ`; `nt` is
# the Binomial trial count (ignored otherwise). Used by predict-side simulation
# and the bootstrap CI.
_cov_sample(::Poisson, μ, nt, rng)          = rand(rng, Poisson(max(μ, 1e-12)))
_cov_sample(f::NegativeBinomial, μ, nt, rng) = (m = max(μ, 1e-12); rand(rng, NegativeBinomial(f.r, f.r / (f.r + m))))
_cov_sample(::Binomial, μ, nt, rng)         = rand(rng, Binomial(nt, clamp(μ, 1e-12, 1 - 1e-12)))
function _cov_sample(f::Beta, μ, nt, rng)
    m = clamp(μ, 1e-6, 1 - 1e-6)
    return clamp(rand(rng, Beta(m * f.α, (1 - m) * f.α)), 1e-6, 1 - 1e-6)
end
_cov_sample(f::Gamma, μ, nt, rng)           = rand(rng, Gamma(f.α, max(μ, 1e-12) / f.α))

# Link-scale latent proxy for the warm start (per family).
function _cov_zemp(family, Y::AbstractMatrix, N::AbstractMatrix, link::Link)
    p, n = size(Y)
    if family isa Poisson || family isa NegativeBinomial
        return [linkfun(link, max(Y[t, i] + 0.5, 1e-4)) for t in 1:p, i in 1:n]
    elseif family isa Binomial
        return [linkfun(link, clamp((Y[t, i] + 0.5) / (N[t, i] + 1), 1e-4, 1 - 1e-4)) for t in 1:p, i in 1:n]
    elseif family isa Beta
        return [linkfun(link, clamp(float(Y[t, i]), 1e-6, 1 - 1e-6)) for t in 1:p, i in 1:n]
    else  # Gamma
        return [linkfun(link, max(float(Y[t, i]), 1e-6)) for t in 1:p, i in 1:n]
    end
end

"""
    GllvmCovFit

Result of [`fit_gllvm_cov`](@ref): a GLLVM fit with fixed-effect covariates. Fields:
`family` (the Distributions marker), per-species intercepts `β` (length p), shared
covariate coefficients `γ` (length q), loadings `Λ` (p×K), `dispersion` (`r`/`φ`/`α`,
or `NaN` when the family has none), `link`, the maximised Laplace `loglik`,
`converged`, and `iterations`.
"""
struct GllvmCovFit
    family::Distribution
    β::Vector{Float64}
    γ::Vector{Float64}
    Λ::Matrix{Float64}
    dispersion::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::GllvmCovFit)
    p, K = size(f.Λ); q = length(f.γ)
    print(io, "GllvmCovFit(", nameof(typeof(f.family)), ", p=", p, ", q=", q, ", K=", K)
    isnan(f.dispersion) || print(io, ", disp=", round(f.dispersion; sigdigits = 4))
    print(io, ", loglik=", round(f.loglik; sigdigits = 7), f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_gllvm_cov(Y; family, X, K, link=nothing, N=nothing, …) -> GllvmCovFit

Fit a non-Gaussian GLLVM **with fixed-effect covariates** by L-BFGS over
`[β; γ; vec(Λ); (log-dispersion)]` on the offset-augmented Laplace marginal, where
the linear predictor is `η_{ts} = β_t + Σ_k X[t,s,k]·γ_k + (Λ z_s)_t`.

`family` is a `Distributions` marker — `Poisson()`, `NegativeBinomial()`,
`Binomial()`, `Beta()`, or `Gamma()` — and dispatches the marginal (the dispersion,
where present, is jointly estimated). `X` is the `(p, n, q)` covariate array (same
contract as the Gaussian engine); `γ` (length q) are coefficients shared across
species (encode species-specific responses by block-expanding `X`). `Y` is `p × n`;
`N` supplies Binomial trial counts (default all-ones). Finite-difference gradient.

```julia
# Poisson abundance with one site covariate, shared coefficient:
X = reshape(repeat(temp', p), p, n, 1)            # X[t,s,1] = temp[s]
fit = fit_gllvm_cov(Y; family = Poisson(), X = X, K = 2)
fit.γ            # estimated environmental coefficient(s)
```
"""
function fit_gllvm_cov(Y::AbstractMatrix{<:Real}; family, X::AbstractArray{<:Real, 3},
        K::Integer, link::Union{Nothing, Link} = nothing,
        N::Union{Nothing, AbstractMatrix} = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    size(X, 1) == p && size(X, 2) == n ||
        throw(DimensionMismatch("X must be (p, n, q) = ($p, $n, q); got $(size(X))"))
    q = size(X, 3)
    rr = rr_theta_len(p, K)
    lk = link === nothing ? _cov_default_link(family) : link
    Nm = N === nothing ? fill(1, p, n) : N
    has_disp = _cov_has_disp(family)

    Zemp = _cov_zemp(family, Y, Nm, lk)
    β0 = vec(sum(Zemp; dims = 2)) ./ n
    Zc = Zemp .- β0
    F = svd(Zc); kk = min(K, length(F.S))
    Λ0 = zeros(p, K)
    @inbounds for j in 1:kk
        Λ0[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
    end

    θ0 = has_disp ? vcat(β0, zeros(q), pack_lambda(Λ0), log(_cov_disp_init(family))) :
                    vcat(β0, zeros(q), pack_lambda(Λ0))
    function negll(θ)
        β = θ[1:p]
        γ = θ[(p + 1):(p + q)]
        Λ = unpack_lambda(θ[(p + q + 1):(p + q + rr)], p, K)
        disp = has_disp ? exp(θ[p + q + rr + 1]) : NaN
        fam = _cov_family(family, disp)
        O = _build_offset(X, γ)
        v = try
            -_marginal_loglik_offset(fam, Y, Nm, Λ, β, O, lk;
                                     maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    res = Optim.optimize(negll, θ0, ls, Optim.Options(g_tol = g_tol, iterations = iterations);
                         autodiff = :finite)
    θ̂ = Optim.minimizer(res)
    β̂ = θ̂[1:p]
    γ̂ = θ̂[(p + 1):(p + q)]
    Λ̂ = unpack_lambda(θ̂[(p + q + 1):(p + q + rr)], p, K)
    disp̂ = has_disp ? exp(θ̂[p + q + rr + 1]) : NaN
    return GllvmCovFit(family, β̂, γ̂, Λ̂, disp̂, lk, -Optim.minimum(res),
                       Optim.converged(res), Optim.iterations(res))
end
