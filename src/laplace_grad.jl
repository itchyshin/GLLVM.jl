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
