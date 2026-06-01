# Poisson family pieces for the generic Laplace core (src/families/laplace.jl).
# y_t ~ Poisson(μ_t), μ = linkinv(link, η) (log link ⇒ μ = exp η). E[y]=μ, Var=μ.
# Score/weight wrt η: with the log link (me = μ) these reduce to (y − μ) and μ.
# Poisson has no trial count, so `n` is ignored.
_clamp_mu(::Poisson, μ) = max(μ, 1e-12)
_glm_score(::Poisson, μ, n, me, y) = (y - μ) / μ * me
_glm_weight(::Poisson, μ, n, me)   = me^2 / μ
_glm_logpdf(::Poisson, μ, n, y)    = logpdf(Poisson(μ), Int(y))

"""
    poisson_marginal_loglik_laplace(Y, Λ, β, link=LogLink(); kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a Poisson GLLVM — a
thin wrapper over the family-generic `marginal_loglik_laplace` with `Poisson()`.
`Y` is the p×n integer count matrix; `Λ` p×K; `β` length-p. Poisson has no trial
counts, so a unit `N` is supplied internally.
"""
poisson_marginal_loglik_laplace(Y::AbstractMatrix,
        Λ::AbstractMatrix, β::AbstractVector, link::Link = LogLink(); kwargs...) =
    marginal_loglik_laplace(Poisson(), Y, ones(Int, size(Y)), Λ, β, link; kwargs...)

# ---------------------------------------------------------------------------
# Fit driver (Poisson slice 2).
# ---------------------------------------------------------------------------

"""
    PoissonFit

Result of [`fit_poisson_gllvm`](@ref): intercepts `β` (length p), loadings `Λ`
(p×K), the `link`, the maximised Laplace `loglik`, the optimiser `converged`
flag, and `iterations`.
"""
struct PoissonFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::PoissonFit)
    p, K = size(f.Λ)
    print(io, "PoissonFit(p=", p, ", K=", K, ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_poisson_gllvm(Y; K, link=LogLink(), …) -> PoissonFit

Fit a Poisson GLLVM by L-BFGS on the Laplace marginal log-likelihood
(`poisson_marginal_loglik_laplace`). `Y` is a p×n integer count matrix
(responses × sites); `K` the latent dimension. Optimises intercepts `β` and
loadings `Λ`. For the canonical log link, the L-BFGS gradient uses a hand-coded
implicit dense-Laplace gradient and a per-site latent-mode cache; warm start =
empirical log-mean intercepts + an SVD (PPCA-style) loadings init.
"""
function fit_poisson_gllvm(Y::AbstractMatrix{<:Integer}; K::Integer,
        link::Link = LogLink(),
        β_init = nothing, Λ_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    rr = rr_theta_len(p, K)

    # warm start: empirical log-scale intercepts + SVD (PPCA-like) loadings
    Zemp = [linkfun(link, max(Y[t, i] + 0.5, 1e-4)) for t in 1:p, i in 1:n]
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
    family_fromθ = _ -> Poisson()
    N = ones(Int, size(Y))
    Zcache = zeros(Float64, K, n)
    value_grad = if link isa LogLink
        θ -> marginal_loglik_laplace_canonical_value_grad!(
            Zcache,
            Poisson(), Y, N, θ, p, K, link; maxiter = newton_maxiter, tol = newton_tol)
    else
        θ -> marginal_loglik_laplace_implicit_value_grad(
            family_fromθ, Y, N, θ, p, K, link; maxiter = newton_maxiter, tol = newton_tol)
    end
    negll_fg!(F, G, θ) = _penalized_negloglik_fg!(F, G, value_grad, θ)
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    res = Optim.optimize(Optim.only_fg!(negll_fg!), θ0, ls,
                         Optim.Options(g_tol = g_tol, iterations = iterations))
    θ̂ = Optim.minimizer(res)
    β̂ = θ̂[1:p]
    Λ̂ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    return PoissonFit(β̂, Λ̂, link, -Optim.minimum(res),
                      Optim.converged(res), Optim.iterations(res))
end
