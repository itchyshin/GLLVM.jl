# Negative-binomial (NB2) family pieces for the generic Laplace core
# (src/families/laplace.jl). y_t ~ NegBinomial(mean μ_t, dispersion r); μ = exp(η)
# (log link), Var = μ + μ²/r. As r → ∞ the NB collapses to Poisson. The dispersion
# `r` is carried in the family marker `NegativeBinomial(r, ·)` — only its `r` field
# is used; the success-probability is recomputed from μ as p = r/(r+μ).
#
# Score/weight wrt η (with V(μ) = μ + μ²/r the NB2 variance):
#   s = (y − μ)/V · dμ/dη,   W = (dμ/dη)²/V   (expected-information ⇒ W ≥ 0).
_clamp_mu(::NegativeBinomial, μ) = max(μ, 1e-12)
_glm_score(f::NegativeBinomial, μ, n, me, y) = (y - μ) / (μ + μ^2 / f.r) * me
_glm_weight(f::NegativeBinomial, μ, n, me)   = me^2 / (μ + μ^2 / f.r)
_glm_logpdf(f::NegativeBinomial, μ, n, y)    = logpdf(NegativeBinomial(f.r, f.r / (f.r + μ)), Int(y))

"""
    nb_marginal_loglik_laplace(Y, Λ, β, r; link=LogLink(), kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a negative-binomial
(NB2) GLLVM with dispersion `r` (`Var = μ + μ²/r`) — a thin wrapper over the
family-generic `marginal_loglik_laplace` with `NegativeBinomial(r, ·)`. `Y` is the
p×n integer count matrix; `Λ` p×K; `β` length-p. As `r → ∞` this tends to the
Poisson marginal.
"""
nb_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix, β::AbstractVector,
        r::Real; link::Link = LogLink(), kwargs...) =
    marginal_loglik_laplace(NegativeBinomial(float(r), 0.5), Y, ones(Int, size(Y)), Λ, β, link; kwargs...)

# ---------------------------------------------------------------------------
# Fit driver (NB family slice 2).
# ---------------------------------------------------------------------------

"""
    NBFit

Result of [`fit_nb_gllvm`](@ref): intercepts `β` (length p), loadings `Λ` (p×K),
the estimated dispersion `r` (Var = μ + μ²/r), the `link`, the maximised Laplace
`loglik`, the optimiser `converged` flag, and `iterations`.
"""
struct NBFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    r::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::NBFit)
    p, K = size(f.Λ)
    print(io, "NBFit(p=", p, ", K=", K, ", r=", round(f.r; sigdigits = 4),
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_nb_gllvm(Y; K, link=LogLink(), r_init=nothing, …) -> NBFit

Fit a negative-binomial (NB2) GLLVM by L-BFGS over `[β; vec(Λ); log r]` on the
Laplace marginal (`nb_marginal_loglik_laplace`), jointly estimating the dispersion
`r`. `Y` is a p×n integer count matrix; `K` the latent dimension. The L-BFGS
gradient uses a scalar-auxiliary implicit dense-Laplace gradient: observation
derivatives are taken only with respect to `(η, log r)`, then the packed
gradient is assembled analytically. Warm start = empirical log-mean intercepts
+ an SVD loadings init + a moderate `r₀`.
"""
function fit_nb_gllvm(Y::AbstractMatrix{<:Integer}; K::Integer,
        link::Link = LogLink(),
        β_init = nothing, Λ_init = nothing, r_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    rr = rr_theta_len(p, K)

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
    logr0 = r_init === nothing ? log(10.0) : log(float(r_init))

    θ0 = vcat(β0, pack_lambda(Λ0), logr0)
    family_from_aux = aux -> NegativeBinomial(_positive_from_log(aux[1]), 0.5)
    N = ones(Int, size(Y))
    value_grad(θ) = marginal_loglik_laplace_aux_value_grad(
        family_from_aux, Y, N, θ, p, K, link; maxiter = newton_maxiter, tol = newton_tol)
    negll_fg!(F, G, θ) = _penalized_negloglik_fg!(F, G, value_grad, θ)
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    res = Optim.optimize(Optim.only_fg!(negll_fg!), θ0, ls,
                         Optim.Options(g_tol = g_tol, iterations = iterations))
    θ̂ = Optim.minimizer(res)
    β̂ = θ̂[1:p]
    Λ̂ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    r̂ = _positive_from_log(θ̂[p + rr + 1])
    return NBFit(β̂, Λ̂, r̂, link, -Optim.minimum(res),
                 Optim.converged(res), Optim.iterations(res))
end
