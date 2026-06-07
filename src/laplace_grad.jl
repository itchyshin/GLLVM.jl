# Analytic (exact) gradient of the Poisson Laplace marginal — a faster replacement
# for the finite-difference gradient used by the non-Gaussian fitters.
#
# The per-site Laplace marginal is  L_s = ℓ(ẑ) − ½ẑ'ẑ − ½ logdet A(ẑ),  with
# A = Λ'WΛ + I and ẑ the conditional mode solving g(z) = Λ's(z) − z = 0. A naive
# `ForwardDiff` through the marginal fails because the inner Newton mode-finder is
# not AD-friendly, and a hand-derived adjoint must carry the implicit dẑ/dθ through
# the log-det term (error-prone).
#
# Instead we use the implicit-function "one Newton step at the optimum" trick: find
# the mode concretely (non-differentiated), then form
#       z(θ) = ẑ + A(ẑ,θ)⁻¹ (Λ's(ẑ;θ) − ẑ),
# which equals ẑ at θ̂ (the bracket is ≈0) but whose θ-derivative is exactly the
# implicit dẑ/dθ. Evaluating L at this differentiable `z` and applying ForwardDiff
# yields the EXACT total gradient — including the log-det and implicit terms — at the
# cost of one Newton solve plus one AD pass, versus the ~2·nθ marginal evaluations a
# finite-difference gradient needs.
#
# This is the analytic-gradient lever from issue #65, Poisson first. It is a
# standalone, finite-difference-verified function — NOT yet wired into the fitter —
# so a regression cannot reach production fits. Generalising to the other families
# needs only an AD-friendly log-pmf/pdf per family (the score/weight are arithmetic).

# AD-friendly Poisson log-pmf (avoids Distributions' logpdf(::Poisson, ::Int) under a
# Dual mean). The lgamma(y+1) term is a constant in θ.
_pois_logpmf(μ, y) = y * log(μ) - μ - loggamma(y + 1.0)

# Shared optimiser wrapper: drive L-BFGS with an analytic gradient closure
# `analytic_grad(θ) -> Vector | nothing`, falling back to a central finite-difference
# gradient of `negll` for any θ where the analytic value is missing/non-finite. The
# fitters pass an `analytic_grad` that returns −∇(marginal) packing matched to θ.
function _optimize_with_analytic(negll, analytic_grad, θ0, ls, opts)
    function g!(G, θ)
        gg = analytic_grad(θ)
        if gg === nothing || !all(isfinite, gg)
            hh = 1e-6
            θp = copy(θ); θm = copy(θ)            # reused across indices (no per-i copy)
            @inbounds for i in eachindex(θ)
                θp[i] += hh; θm[i] -= hh
                G[i] = (negll(θp) - negll(θm)) / (2hh)
                θp[i] = θ[i]; θm[i] = θ[i]        # restore in place
            end
        else
            G .= gg
        end
        return G
    end
    return Optim.optimize(negll, g!, θ0, ls, opts)
end

# Differentiable per-site Poisson Laplace marginal (log link), via the implicit step.
# `β`, `Λ` may carry ForwardDiff duals; the mode is computed on their primal values.
function _poisson_site_diffable(y::AbstractVector, Λ::AbstractMatrix, β::AbstractVector)
    p = size(Λ, 1)
    # Concrete mode from the primal parameters (no dual leakage).
    Λv = ForwardDiff.value.(Λ); βv = ForwardDiff.value.(β)
    ẑ = _laplace_mode(Poisson(), y, ones(Int, p), Λv, βv, LogLink())

    # One differentiable Newton step from ẑ ⇒ z ≈ ẑ with the correct dz/dθ.
    η = _clamp_eta.(β .+ Λ * ẑ)
    μ = exp.(η)                       # log link
    s = y .- μ                        # Poisson/log score wrt η
    A = Λ' * (μ .* Λ) + I             # plain Matrix (AD-safe generic solve/logdet)
    z = ẑ .+ (A \ (Λ' * s .- ẑ))

    # Marginal evaluated at the differentiable mode.
    ηz = _clamp_eta.(β .+ Λ * z)
    μz = exp.(ηz)
    Az = Λ' * (μz .* Λ) + I
    ℓ = zero(eltype(z))
    @inbounds for t in 1:p
        ℓ += _pois_logpmf(μz[t], y[t])
    end
    return ℓ - 0.5 * dot(z, z) - 0.5 * logdet(Az)
end

"""
    poisson_laplace_grad(Y, Λ, β) -> Vector

Exact gradient of the total Poisson Laplace marginal log-likelihood
([`poisson_marginal_loglik_laplace`](@ref)) with respect to the packed parameter
vector `θ = [β; pack_lambda(Λ)]`, computed by ForwardDiff through the
implicit-function "one Newton step at the optimum" construction (see file header).

`Y` is the p×n count matrix, `Λ` p×K loadings, `β` length-p intercepts. The result
matches a finite-difference gradient of the marginal to ~AD precision, at a fraction
of the cost — the basis for replacing the finite-difference gradient in the fitter
(issue #65). Standalone for now; not yet used by `fit_poisson_gllvm`.
"""
function poisson_laplace_grad(Y::AbstractMatrix, Λ::AbstractMatrix, β::AbstractVector)
    p, K = size(Λ)
    rr = rr_theta_len(p, K)
    θ̂ = vcat(float.(β), pack_lambda(Λ))
    function marg(θ)
        b = θ[1:p]
        L = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        acc = zero(eltype(θ))
        @inbounds for s in axes(Y, 2)
            acc += _poisson_site_diffable(view(Y, :, s), L, b)
        end
        return acc
    end
    return ForwardDiff.gradient(marg, θ̂)
end

# --- Negative binomial (log link) — dispersion family: r enters θ as log r ---
# AD-friendly NB2 log-pmf kernel (mean μ, dispersion r); the loggamma(y+1) constant
# is dropped (zero gradient). r is a θ parameter (via log r), so the r-dependent
# loggamma(r+y) − loggamma(r) terms are kept and differentiated (loggamma' = digamma,
# which ForwardDiff supports).
_nb_logker(μ, r, y) = loggamma(r + y) - loggamma(r) +
                      r * log(r) - (r + y) * log(r + μ) + y * log(μ)

function _nb_site_diffable(y::AbstractVector, Λ::AbstractMatrix, β::AbstractVector, logr)
    p = size(Λ, 1)
    r = exp(logr)
    Λv = ForwardDiff.value.(Λ); βv = ForwardDiff.value.(β); rv = ForwardDiff.value(r)
    ẑ = _laplace_mode(NegativeBinomial(rv, 0.5), y, ones(Int, p), Λv, βv, LogLink())

    η = _clamp_eta.(β .+ Λ * ẑ); μ = exp.(η)
    s = (y .- μ) ./ (1 .+ μ ./ r)             # NB2/log score (= r(y−μ)/(r+μ))
    # NB is non-canonical: the implicit dẑ/dθ uses the OBSERVED Hessian weight
    # W_obs = −∂s/∂η = μr(r+y)/(r+μ)², not the Fisher weight. (For canonical links
    # the two coincide, which is why Poisson/Binomial work with the Fisher weight.)
    Wobs = μ .* r .* (r .+ y) ./ (r .+ μ) .^ 2
    Aobs = Λ' * (Wobs .* Λ) + I
    z = ẑ .+ (Aobs \ (Λ' * s .- ẑ))

    ηz = _clamp_eta.(β .+ Λ * z); μz = exp.(ηz)
    Wz = μz ./ (1 .+ μz ./ r)                 # Fisher weight — matches the marginal's logdet
    Az = Λ' * (Wz .* Λ) + I
    ℓ = zero(eltype(z))
    @inbounds for t in 1:p
        ℓ += _nb_logker(μz[t], r, y[t])
    end
    return ℓ - 0.5 * dot(z, z) - 0.5 * logdet(Az)
end

"""
    nb_laplace_grad(Y, Λ, β, r) -> Vector

Exact gradient of the total negative-binomial (NB2, log link) Laplace marginal wrt
`θ = [β; pack_lambda(Λ); log r]` — including the dispersion direction — via the same
ForwardDiff + implicit-step construction as [`poisson_laplace_grad`](@ref). This is the
dispersion-family generalisation (r carried in θ as `log r`). Standalone +
finite-difference-verified; not yet wired into `fit_nb_gllvm`.
"""
function nb_laplace_grad(Y::AbstractMatrix, Λ::AbstractMatrix, β::AbstractVector, r::Real)
    p, K = size(Λ)
    rr = rr_theta_len(p, K)
    θ̂ = vcat(float.(β), pack_lambda(Λ), log(float(r)))
    function marg(θ)
        b = θ[1:p]
        L = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        logr = θ[p + rr + 1]
        acc = zero(eltype(θ))
        @inbounds for s in axes(Y, 2)
            acc += _nb_site_diffable(view(Y, :, s), L, b, logr)
        end
        return acc
    end
    return ForwardDiff.gradient(marg, θ̂)
end

# --- Gamma (log link, shape α) — dispersion family, non-canonical ----------
# AD-friendly Gamma(shape α, mean μ) log-density kernel (Var = μ²/α). Score
# s = α(y−μ)/μ; Fisher weight = α (constant); observed weight −∂s/∂η = αy/μ.
_gamma_logker(μ, α, y) = (α - 1) * log(y) - y * α / μ - α * log(μ) + α * log(α) - loggamma(α)

function _gamma_site_diffable(y::AbstractVector, Λ::AbstractMatrix, β::AbstractVector, logα)
    p = size(Λ, 1)
    α = exp(logα)
    Λv = ForwardDiff.value.(Λ); βv = ForwardDiff.value.(β); αv = ForwardDiff.value(α)
    ẑ = _laplace_mode(Gamma(αv, 1.0), y, ones(Int, p), Λv, βv, LogLink())

    η = _clamp_eta.(β .+ Λ * ẑ); μ = exp.(η)
    s = α .* (y .- μ) ./ μ                    # Gamma/log score
    Wobs = α .* y ./ μ                        # observed weight −∂s/∂η (non-canonical)
    Aobs = Λ' * (Wobs .* Λ) + I
    z = ẑ .+ (Aobs \ (Λ' * s .- ẑ))

    ηz = _clamp_eta.(β .+ Λ * z); μz = exp.(ηz)
    Az = α .* (Λ' * Λ) + I                    # Fisher weight = α (constant) ⇒ logdet term
    ℓ = zero(eltype(z))
    @inbounds for t in 1:p
        ℓ += _gamma_logker(μz[t], α, y[t])
    end
    return ℓ - 0.5 * dot(z, z) - 0.5 * logdet(Az)
end

"""
    gamma_laplace_grad(Y, Λ, β, α) -> Vector

Exact gradient of the total Gamma (log link, shape `α`) Laplace marginal wrt
`θ = [β; pack_lambda(Λ); log α]`, via the ForwardDiff + implicit-step construction
(observed weight `αy/μ` in the implicit step, Fisher weight `α` in the log-det).
Standalone + finite-difference-verified; not yet wired into `fit_gamma_gllvm`.
"""
function gamma_laplace_grad(Y::AbstractMatrix, Λ::AbstractMatrix, β::AbstractVector, α::Real)
    p, K = size(Λ)
    rr = rr_theta_len(p, K)
    θ̂ = vcat(float.(β), pack_lambda(Λ), log(float(α)))
    function marg(θ)
        b = θ[1:p]
        L = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        logα = θ[p + rr + 1]
        acc = zero(eltype(θ))
        @inbounds for s in axes(Y, 2)
            acc += _gamma_site_diffable(view(Y, :, s), L, b, logα)
        end
        return acc
    end
    return ForwardDiff.gradient(marg, θ̂)
end

# --- Beta (logit link, precision φ) — non-canonical; observed weight via AD ---
# Beta's observed Hessian weight (−∂s/∂η) involves digamma/trigamma terms, so rather
# than hand-derive it we take it from a 1-D ForwardDiff derivative of the per-species
# score at the (concrete) mode — exact and low-risk. The implicit-step matrix is then
# concrete (correct, since the bracket is 0 at the mode); the log-det uses the Fisher
# weight (Dual) to match the marginal.
_beta_score_scalar(η, φ, y) = begin
    μ = 1 / (1 + exp(-η)); me = μ * (1 - μ)
    ystar = log(y) - log1p(-y)
    μstar = digamma(μ * φ) - digamma((1 - μ) * φ)
    return φ * (ystar - μstar) * me
end
_beta_logker(μ, φ, y) = (μ * φ - 1) * log(y) + ((1 - μ) * φ - 1) * log1p(-y) -
                        (loggamma(μ * φ) + loggamma((1 - μ) * φ) - loggamma(φ))

function _beta_site_diffable(y::AbstractVector, Λ::AbstractMatrix, β::AbstractVector, logφ)
    p = size(Λ, 1)
    φ = exp(logφ)
    Λv = ForwardDiff.value.(Λ); βv = ForwardDiff.value.(β); φv = ForwardDiff.value(φ)
    ẑ = _laplace_mode(Beta(φv, 1.0), y, ones(Int, p), Λv, βv, LogitLink())

    # Concrete observed-Hessian weights via AD-derivative of the scalar score.
    ηc = _clamp_eta.(βv .+ Λv * ẑ)
    Wobs = [-ForwardDiff.derivative(η_ -> _beta_score_scalar(η_, φv, y[t]), ηc[t]) for t in 1:p]
    Aobs = Λv' * (Wobs .* Λv) + I                 # concrete (correct since bracket≈0 at ẑ)

    # Differentiable score at ẑ.
    η = _clamp_eta.(β .+ Λ * ẑ); μ = 1 ./ (1 .+ exp.(-η))
    me = μ .* (1 .- μ)
    ystar = log.(y) .- log1p.(-y)
    μstar = digamma.(μ .* φ) .- digamma.((1 .- μ) .* φ)
    s = φ .* (ystar .- μstar) .* me
    z = ẑ .+ (Aobs \ (Λ' * s .- ẑ))

    ηz = _clamp_eta.(β .+ Λ * z); μz = 1 ./ (1 .+ exp.(-ηz))
    mez = μz .* (1 .- μz)
    νz = trigamma.(μz .* φ) .+ trigamma.((1 .- μz) .* φ)
    WFz = φ .^ 2 .* νz .* mez .^ 2                 # Fisher weight ⇒ logdet
    Az = Λ' * (WFz .* Λ) + I
    ℓ = zero(eltype(z))
    @inbounds for t in 1:p
        ℓ += _beta_logker(μz[t], φ, y[t])
    end
    return ℓ - 0.5 * dot(z, z) - 0.5 * logdet(Az)
end

"""
    beta_laplace_grad(Y, Λ, β, φ) -> Vector

Exact gradient of the total Beta (logit link, precision `φ`) Laplace marginal wrt
`θ = [β; pack_lambda(Λ); log φ]`, via the ForwardDiff + implicit-step construction,
with the observed-Hessian weight obtained from an AD-derivative of the score.
Standalone + finite-difference-verified; not yet wired into `fit_beta_gllvm`.
"""
function beta_laplace_grad(Y::AbstractMatrix, Λ::AbstractMatrix, β::AbstractVector, φ::Real)
    p, K = size(Λ)
    rr = rr_theta_len(p, K)
    θ̂ = vcat(float.(β), pack_lambda(Λ), log(float(φ)))
    function marg(θ)
        b = θ[1:p]
        L = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        logφ = θ[p + rr + 1]
        acc = zero(eltype(θ))
        @inbounds for s in axes(Y, 2)
            acc += _beta_site_diffable(view(Y, :, s), L, b, logφ)
        end
        return acc
    end
    return ForwardDiff.gradient(marg, θ̂)
end

# --- Binomial (logit link) — second no-dispersion family, same technique ---
# AD-friendly logit-Binomial log-pmf kernel (the binomial-coefficient term is a
# constant in θ ⇒ zero gradient, so it is dropped). μ = logistic(η).
_binom_logker(μ, n, y) = y * log(μ) + (n - y) * log(one(μ) - μ)

function _binomial_site_diffable(y::AbstractVector, nt::AbstractVector,
                                 Λ::AbstractMatrix, β::AbstractVector)
    p = size(Λ, 1)
    Λv = ForwardDiff.value.(Λ); βv = ForwardDiff.value.(β)
    ẑ = _laplace_mode(Binomial(), y, nt, Λv, βv, LogitLink())

    η = _clamp_eta.(β .+ Λ * ẑ)
    μ = 1 ./ (1 .+ exp.(-η))            # logistic
    s = y .- nt .* μ                    # logit-link score (y − nμ)
    W = nt .* μ .* (1 .- μ)             # logit-link weight (nμ(1−μ))
    A = Λ' * (W .* Λ) + I
    z = ẑ .+ (A \ (Λ' * s .- ẑ))

    ηz = _clamp_eta.(β .+ Λ * z)
    μz = 1 ./ (1 .+ exp.(-ηz))
    Wz = nt .* μz .* (1 .- μz)
    Az = Λ' * (Wz .* Λ) + I
    ℓ = zero(eltype(z))
    @inbounds for t in 1:p
        ℓ += _binom_logker(μz[t], nt[t], y[t])
    end
    return ℓ - 0.5 * dot(z, z) - 0.5 * logdet(Az)
end

"""
    binomial_laplace_grad(Y, N, Λ, β) -> Vector

Exact gradient of the total Binomial (logit-link) Laplace marginal wrt
`θ = [β; pack_lambda(Λ)]`, via the same ForwardDiff + implicit-step construction as
[`poisson_laplace_grad`](@ref). `N` is the p×n trial-count matrix. Standalone +
finite-difference-verified; not yet wired into `fit_binomial_gllvm`.
"""
function binomial_laplace_grad(Y::AbstractMatrix, N::AbstractMatrix,
                               Λ::AbstractMatrix, β::AbstractVector)
    p, K = size(Λ)
    rr = rr_theta_len(p, K)
    θ̂ = vcat(float.(β), pack_lambda(Λ))
    function marg(θ)
        b = θ[1:p]
        L = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        acc = zero(eltype(θ))
        @inbounds for s in axes(Y, 2)
            acc += _binomial_site_diffable(view(Y, :, s), view(N, :, s), L, b)
        end
        return acc
    end
    return ForwardDiff.gradient(marg, θ̂)
end
