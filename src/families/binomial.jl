# Per-site Laplace marginal log-likelihood for the Binomial GLLVM.
#
# Model (site s, p binary/binomial responses):
#     y_{ts} ~ Binomial(n_{ts}, μ_{ts}),  μ_{ts} = linkinv(link, η_{ts}),
#     η_{ts} = β_t + (Λ z_s)_t,           z_s ~ N(0, I_K).
#
# The marginal  ∫ p(y_s | z) N(z; 0, I) dz  is non-conjugate, so it is computed
# by a Laplace approximation: find the conditional mode ẑ_s by Fisher scoring,
# then
#     log p(y_s) ≈ ℓ(ẑ_s) − ½ ẑ_s'ẑ_s − ½ logdet(Λ' W Λ + I_K),
# where ℓ is the binomial log-likelihood and W are the Fisher working weights at
# the mode. This is the smallest correctness unit of the Binomial family (#7);
# the fit driver and gradient build on it. See the design note in the after-task
# log. Inner mode-finder uses the Fisher information (expected Hessian), so
# Λ' W Λ + I_K is always SPD.

# Numerical-safety clamps for separated data (η → ±∞, μ → 0/1).
_clamp_eta(η) = clamp(η, -30.0, 30.0)
_clamp_mu(μ)  = clamp(μ, 1e-12, 1 - 1e-12)

"""
    laplace_loglik_site(y, n, Λ, β, link; maxiter=100, tol=1e-9) -> Float64

Laplace-approximated log-marginal for one site. `y`, `n` are the response counts
and trial counts (length p); `Λ` is p×K loadings; `β` length-p intercepts;
`link` a [`Link`](@ref). Returns `ℓ(ẑ) − ½ẑ'ẑ − ½logdet(Λ'WΛ + I)`.
"""
function laplace_loglik_site(y::AbstractVector, n::AbstractVector,
        Λ::AbstractMatrix, β::AbstractVector, link::Link;
        maxiter::Integer = 100, tol::Real = 1e-9)
    p, K = size(Λ)
    z = zeros(K)
    for _ in 1:maxiter
        η = _clamp_eta.(β .+ Λ * z)
        μ = _clamp_mu.(linkinv.(Ref(link), η))
        me = mu_eta.(Ref(link), η)
        v  = μ .* (1 .- μ)
        s  = (y .- n .* μ) ./ v .* me        # working-residual contribution
        W  = n .* me .^ 2 ./ v               # Fisher working weights (≥ 0)
        A  = Symmetric(Λ' * (W .* Λ) + I)
        Δ  = A \ (Λ' * s .- z)
        z  = z .+ Δ
        maximum(abs, Δ) < tol && break
    end
    η = _clamp_eta.(β .+ Λ * z)
    μ = _clamp_mu.(linkinv.(Ref(link), η))
    me = mu_eta.(Ref(link), η)
    v  = μ .* (1 .- μ)
    W  = n .* me .^ 2 ./ v
    A  = Symmetric(Λ' * (W .* Λ) + I)
    ℓ = 0.0
    @inbounds for t in 1:p
        ℓ += logpdf(Binomial(Int(n[t]), μ[t]), Int(y[t]))   # incl. binomial coefficient
    end
    return ℓ - 0.5 * dot(z, z) - 0.5 * logdet(A)
end

"""
    binomial_marginal_loglik_laplace(Y, N, Λ, β, link; kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites of a Binomial GLLVM. `Y`, `N` are
p×n response and trial-count matrices; `Λ` p×K; `β` length-p; `link` a `Link`.
"""
function binomial_marginal_loglik_laplace(Y::AbstractMatrix, N::AbstractMatrix,
        Λ::AbstractMatrix, β::AbstractVector, link::Link; kwargs...)
    acc = 0.0
    @inbounds for i in axes(Y, 2)
        acc += laplace_loglik_site(view(Y, :, i), view(N, :, i), Λ, β, link; kwargs...)
    end
    return acc
end
