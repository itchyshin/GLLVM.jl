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

# Binomial family pieces for the generic Laplace core (src/families/laplace.jl).
# y_t ~ Binomial(n_t, μ_t); E[y]=nμ, Var=nμ(1−μ). Score/weight wrt η below; with
# the logit link (me = μ(1−μ)) the weight reduces to the canonical nμ(1−μ).
_clamp_mu(::Binomial, μ) = clamp(μ, 1e-12, 1 - 1e-12)
_glm_score(::Binomial, μ, n, me, y) = (y - n * μ) / (μ * (one(μ) - μ)) * me
_glm_weight(::Binomial, μ, n, me)   = n * me^2 / (μ * (one(μ) - μ))
_glm_logpdf(::Binomial, μ, n, y)    = logpdf(Binomial(Int(n), μ), Int(y))

# Binomial-default convenience methods (back-compat: family ⇒ Binomial()), used
# by getLV(::BinomialFit) and the Binomial tests.
_laplace_mode(y::AbstractVector, n::AbstractVector, Λ::AbstractMatrix,
        β::AbstractVector, link::Link; kwargs...) =
    _laplace_mode(Binomial(), y, n, Λ, β, link; kwargs...)

laplace_loglik_site(y::AbstractVector, n::AbstractVector, Λ::AbstractMatrix,
        β::AbstractVector, link::Link; kwargs...) =
    laplace_loglik_site(Binomial(), y, n, Λ, β, link; kwargs...)

"""
    binomial_marginal_loglik_laplace(Y, N, Λ, β, link; kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites of a Binomial GLLVM — a thin
wrapper over the family-generic `marginal_loglik_laplace` with `Binomial()`.
`Y`, `N` are p×n response and trial-count matrices; `Λ` p×K; `β` length-p.
"""
binomial_marginal_loglik_laplace(Y::AbstractMatrix, N::AbstractMatrix,
        Λ::AbstractMatrix, β::AbstractVector, link::Link; kwargs...) =
    marginal_loglik_laplace(Binomial(), Y, N, Λ, β, link; kwargs...)

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
(`binomial_marginal_loglik_laplace`). `Y` is a p×n integer response
matrix (responses × sites); `N` the matching trial counts (default all-ones,
i.e. Bernoulli / binary). `K` is the latent dimension. Optimises the intercepts
`β` and loadings `Λ`.

The L-BFGS gradient uses an implicit dense-Laplace gradient: site modes are found
once by Fisher scoring, then the mode equation supplies `dz/dθ` without
differentiating through the Newton iterations. Warm start: empirical link-scale
intercepts + an SVD (PPCA-style) loadings init.
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
    family_fromθ = _ -> Binomial()
    value_grad(θ) = marginal_loglik_laplace_implicit_value_grad(
        family_fromθ, Y, Nm, θ, p, K, link; maxiter = newton_maxiter, tol = newton_tol)
    negll_fg!(F, G, θ) = _penalized_negloglik_fg!(F, G, value_grad, θ)
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    res = Optim.optimize(Optim.only_fg!(negll_fg!), θ0, ls,
                         Optim.Options(g_tol = g_tol, iterations = iterations))
    θ̂ = Optim.minimizer(res)
    β̂ = θ̂[1:p]
    Λ̂ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    return BinomialFit(β̂, Λ̂, link, -Optim.minimum(res),
                       Optim.converged(res), Optim.iterations(res))
end
