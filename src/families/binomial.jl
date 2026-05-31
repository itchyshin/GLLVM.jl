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

# ---------------------------------------------------------------------------
# Fit driver (Binomial slice 4).
# ---------------------------------------------------------------------------

"""
    BinomialFit

Result of [`fit_binomial_gllvm`](@ref): intercepts `β` (length p), loadings `Λ`
(p×K), the `link`, the maximised Laplace `loglik`, the optimiser `converged`
flag, and `iterations`.
"""
struct BinomialFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::BinomialFit)
    p, K = size(f.Λ)
    print(io, "BinomialFit(p=", p, ", K=", K, ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_binomial_gllvm(Y; K, link=LogitLink(), N=nothing, …) -> BinomialFit

Fit a Binomial GLLVM by L-BFGS on the Laplace marginal log-likelihood
([`binomial_marginal_loglik_laplace`](@ref)). `Y` is a p×n integer response
matrix (responses × sites); `N` the matching trial counts (default all-ones,
i.e. Bernoulli / binary). `K` is the latent dimension. Optimises the intercepts
`β` and loadings `Λ`.

The L-BFGS gradient is finite-difference: the Laplace inner mode-finder is not
forward-AD-friendly, so this keeps the first driver simple and robust (an
envelope-theorem analytic gradient is the planned optimisation). Warm start:
empirical link-scale intercepts + an SVD (PPCA-style) loadings init.
"""
function fit_binomial_gllvm(Y::AbstractMatrix{<:Integer}; K::Integer,
        link::Link = LogitLink(),
        N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing,
        β_init = nothing, Λ_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    size(Nm) == (p, n) || throw(DimensionMismatch("N must be $(p)×$(n)"))
    rr = rr_theta_len(p, K)

    # warm start: empirical link-scale intercepts + SVD (PPCA-like) loadings
    Zemp = [linkfun(link, clamp((Y[t, i] + 0.5) / (Nm[t, i] + 1), 1e-4, 1 - 1e-4))
            for t in 1:p, i in 1:n]
    β0 = β_init === nothing ? vec(sum(Zemp; dims = 2)) ./ n : collect(float.(β_init))
    Λ0 = if Λ_init === nothing
        Zc = Zemp .- β0
        F = svd(Zc)
        kk = min(K, length(F.S))
        L = zeros(p, K)
        @inbounds for j in 1:kk
            L[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
        end
        L
    else
        collect(float.(Λ_init))
    end

    θ0 = vcat(β0, pack_lambda(Λ0))
    function negll(θ)
        β = θ[1:p]
        Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        v = -binomial_marginal_loglik_laplace(Y, Nm, Λ, β, link;
                                              maxiter = newton_maxiter, tol = newton_tol)
        return isfinite(v) ? v : 1e12
    end
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    res = Optim.optimize(negll, θ0, ls, Optim.Options(g_tol = g_tol, iterations = iterations);
                         autodiff = :finite)
    θ̂ = Optim.minimizer(res)
    β̂ = θ̂[1:p]
    Λ̂ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    return BinomialFit(β̂, Λ̂, link, -Optim.minimum(res),
                       Optim.converged(res), Optim.iterations(res))
end
