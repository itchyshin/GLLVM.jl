# Generic Laplace-approximated marginal log-likelihood for non-Gaussian GLLVM
# families. The family-specific pieces — the Fisher-scoring score and weight, the
# μ clamp, and the conditional log-density — dispatch on the Distributions family
# type, so Binomial, Poisson, … share one mode-finder (no hardcoded family switch).
#
# Model (site s): y_{ts} ~ Family(μ_{ts}[, n_{ts}]),  μ = linkinv(link, η),
#     η = β_t + (Λ z_s)_t,  z_s ~ N(0, I_K).
# The marginal ∫ p(y_s|z) N(z;0,I) dz (non-conjugate) is computed by Laplace:
# find the conditional mode ẑ by Fisher scoring (expected Hessian ⇒ Λ'WΛ + I
# is always SPD), then  log p(y_s) ≈ ℓ(ẑ) − ½ẑ'ẑ − ½ logdet(Λ'WΛ + I).
#
# Each family provides, dispatched on its type:
#   _clamp_mu(family, μ)              domain-safe μ
#   _glm_score(family, μ, n, me, y)   ∂ℓ/∂η contribution (score)
#   _glm_weight(family, μ, n, me)     Fisher information wrt η (≥ 0)
#   _glm_logpdf(family, μ, n, y)      conditional log-density
# (see families/binomial.jl, families/poisson.jl).

# η clamp is family-agnostic; μ clamp dispatches on the family.
_clamp_eta(η) = clamp(η, -30.0, 30.0)
_positive_from_log(x) = exp(clamp(x, -30.0, 30.0))

# Robust linear solve: returns `nothing` if the factorization is singular or
# fails, so the inner Newton can stop gracefully. A = Λ'WΛ + I is SPD by
# construction but can be numerically singular when the Fisher weights blow up
# (huge μ at the η clamp — e.g. a Poisson rate driven to exp(30)).
_safe_solve(A, b) = try
    A \ b
catch
    nothing
end

# Inner Laplace mode-finder (Fisher-scoring Newton). Returns the conditional mode
# ẑ (length K) for one site. Shared across families and by getLV (src/postfit.jl).
function _laplace_mode(family, y::AbstractVector, n::AbstractVector,
        Λ::AbstractMatrix, β::AbstractVector, link::Link;
        maxiter::Integer = 100, tol::Real = 1e-9)
    K = size(Λ, 2)
    z = zeros(K)
    for _ in 1:maxiter
        η  = _clamp_eta.(β .+ Λ * z)
        μ  = _clamp_mu.(Ref(family), linkinv.(Ref(link), η))
        me = mu_eta.(Ref(link), η)
        s  = _glm_score.(Ref(family), μ, n, me, y)
        W  = _glm_weight.(Ref(family), μ, n, me)
        A  = Symmetric(Λ' * (W .* Λ) + I)
        Δ  = _safe_solve(A, Λ' * s .- z)
        (Δ === nothing || !all(isfinite, Δ)) && break   # singular A ⇒ stop at current ẑ
        z  = z .+ Δ
        maximum(abs, Δ) < tol && break
    end
    return z
end

"""
    laplace_loglik_site(family, y, n, Λ, β, link; maxiter=100, tol=1e-9) -> Float64

Laplace-approximated log-marginal for one site of a non-Gaussian GLLVM. `family`
is a `Distributions` family marker (e.g. `Binomial()`, `Poisson()`); `y`, `n` are
the response and trial counts (length p; `n` is ignored by families without
trials); `Λ` p×K; `β` length-p; `link` a `Link`. Returns
`ℓ(ẑ) − ½ẑ'ẑ − ½logdet(Λ'WΛ + I)`.
"""
function laplace_loglik_site(family, y::AbstractVector, n::AbstractVector,
        Λ::AbstractMatrix, β::AbstractVector, link::Link;
        maxiter::Integer = 100, tol::Real = 1e-9)
    p = size(Λ, 1)
    z  = _laplace_mode(family, y, n, Λ, β, link; maxiter = maxiter, tol = tol)
    η  = _clamp_eta.(β .+ Λ * z)
    μ  = _clamp_mu.(Ref(family), linkinv.(Ref(link), η))
    me = mu_eta.(Ref(link), η)
    W  = _glm_weight.(Ref(family), μ, n, me)
    A  = Symmetric(Λ' * (W .* Λ) + I)
    ℓ = zero(eltype(A))
    @inbounds for t in 1:p
        ℓ += _glm_logpdf(family, μ[t], n[t], y[t])
    end
    return ℓ - 0.5 * dot(z, z) - 0.5 * logdet(A)
end

"""
    marginal_loglik_laplace(family, Y, N, Λ, β, link; kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a non-Gaussian GLLVM.
`Y`, `N` are p×n response and trial-count matrices.
"""
function marginal_loglik_laplace(family, Y::AbstractMatrix, N::AbstractMatrix,
        Λ::AbstractMatrix, β::AbstractVector, link::Link; kwargs...)
    acc = zero(promote_type(eltype(Λ), eltype(β)))
    @inbounds for i in axes(Y, 2)
        acc += laplace_loglik_site(family, view(Y, :, i), view(N, :, i), Λ, β, link; kwargs...)
    end
    return acc
end

# Value and mode-equation stack for one site at fixed `z` and packed `θ`.
# `family_fromθ` maps the packed parameter vector to the family marker, allowing
# dispersion families to keep log-dispersion in θ while differentiating wrt θ.
function _scalar_laplace_qF(family_fromθ, y::AbstractVector, n::AbstractVector,
        θ::AbstractVector, z::AbstractVector, p::Int, K::Int, link::Link)
    rr = rr_theta_len(p, K)
    β = θ[1:p]
    Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
    family = family_fromθ(θ)
    η  = _clamp_eta.(β .+ Λ * z)
    μ  = _clamp_mu.(Ref(family), linkinv.(Ref(link), η))
    me = mu_eta.(Ref(link), η)
    s  = _glm_score.(Ref(family), μ, n, me, y)
    W  = _glm_weight.(Ref(family), μ, n, me)
    A  = Symmetric(Λ' * (W .* Λ) + I)
    ℓ = zero(eltype(A))
    @inbounds for t in 1:p
        ℓ += _glm_logpdf(family, μ[t], n[t], y[t])
    end
    q = ℓ - 0.5 * dot(z, z) - 0.5 * logdet(A)
    F = Λ' * s .- z
    return vcat(q, F)
end

function _implicit_site_gradient(qF, x0::AbstractVector, K::Int)
    J = ForwardDiff.jacobian(qF, x0)
    qz = vec(J[1, 1:K])
    qθ = vec(J[1, (K + 1):end])
    Fz = J[2:end, 1:K]
    Fθ = J[2:end, (K + 1):end]
    adj = Fz' \ qz
    return qF(x0)[1], qθ - Fθ' * adj
end

function _scalar_laplace_site_implicit_value_grad(family_fromθ,
        y::AbstractVector, n::AbstractVector, θ::AbstractVector,
        p::Int, K::Int, link::Link; maxiter::Integer = 100, tol::Real = 1e-9)
    rr = rr_theta_len(p, K)
    β = θ[1:p]
    Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
    family = family_fromθ(θ)
    z = _laplace_mode(family, y, n, Λ, β, link; maxiter = maxiter, tol = tol)
    x0 = vcat(z, θ)
    qF = x -> _scalar_laplace_qF(family_fromθ, y, n, x[(K + 1):end],
                                 x[1:K], p, K, link)
    return _implicit_site_gradient(qF, x0, K)
end

"""
    marginal_loglik_laplace_implicit_value_grad(family_fromθ, Y, N, θ, p, K, link; kwargs...)

Return `(loglik, gradient)` for the packed scalar-family Laplace objective.
The site modes are found once with the Fisher-scoring solver, then the gradient
uses the implicit mode equation `F_z dz/dθ = -F_θ` instead of differentiating
through the Newton iterations.
"""
function marginal_loglik_laplace_implicit_value_grad(family_fromθ,
        Y::AbstractMatrix, N::AbstractMatrix, θ::AbstractVector,
        p::Int, K::Int, link::Link; kwargs...)
    value = zero(eltype(θ))
    grad = zeros(eltype(θ), length(θ))
    @inbounds for i in axes(Y, 2)
        v, g = _scalar_laplace_site_implicit_value_grad(
            family_fromθ, view(Y, :, i), view(N, :, i), θ, p, K, link; kwargs...)
        value += v
        grad .+= g
    end
    return value, grad
end

function _penalty_negloglik_fg!(F, G, θ)
    if G !== nothing
        any_nonzero = false
        @inbounds for i in eachindex(θ)
            gi = if isfinite(θ[i])
                2 * θ[i]
            elseif θ[i] < 0
                -one(eltype(G))
            else
                one(eltype(G))
            end
            G[i] = gi
            any_nonzero |= !iszero(gi)
        end
        !any_nonzero && !isempty(G) && (G[1] = one(eltype(G)))
    end
    if F !== nothing
        s = zero(eltype(θ))
        @inbounds for x in θ
            isfinite(x) && (s += abs2(x))
        end
        return oftype(first(θ), 1e12) + s
    end
    return nothing
end

function _penalized_negloglik_fg!(F, G, value_grad, θ)
    try
        value, grad = value_grad(θ)
        if !isfinite(value) || !all(isfinite, grad)
            return _penalty_negloglik_fg!(F, G, θ)
        end
        G !== nothing && (G .= .-grad)
        F !== nothing && return -value
        return nothing
    catch
        return _penalty_negloglik_fg!(F, G, θ)
    end
end
