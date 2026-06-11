# Negative-binomial type 1 (NB1, LINEAR mean–variance) family pieces for the
# generic Laplace core (src/families/laplace.jl). y_t ∈ {0,1,2,…}; mean
# μ = exp(η) (log link), dispersion φ > 0; the per-observation law is
# NegativeBinomial with Var = μ(1 + φ) — variance grows LINEARLY in the mean
# (Hilbe 2011). This differs from NB2 (families/negbin.jl), whose variance is
# Var = μ + μ²/r (quadratic).
#
# Distributions.jl `NegativeBinomial(size r, prob p)` is the NB2 parameterisation
# with Var = μ + μ²/r. To realise NB1's Var = μ(1+φ) we map per observation:
#     μ²/r = μφ  ⇒  r = μ/φ            (size scales WITH the mean),
#     p     = r/(r+μ) = 1/(1+φ)        (success probability is μ-FREE).
# As φ → 0 the NB1 collapses to Poisson(μ). The dispersion φ is carried in the
# `NB1(φ)` marker below (a dedicated struct — NB1 has no Distributions marker,
# unlike NB2 which reuses `NegativeBinomial`).
#
# Score/weight wrt η (standard GLM Fisher scoring with the NB1 variance
# V(μ) = μ(1+φ) and log link me = dμ/dη = μ):
#   s = (y − μ)/V · me = (y − μ)/(1+φ)
#   W = me²/V          = μ/(1+φ)          (expected information ⇒ W ≥ 0)
#
# `_glm_logpdf` is written in CLOSED FORM via `loggamma` (not via a
# `NegativeBinomial(r, p)` object) so ForwardDiff Duals flow cleanly through both
# η (via μ, hence r = μ/φ) and log φ (via r and p) — this is what makes the
# generic implicit-gradient path in laplace.jl AD-clean for NB1.

"""
    NB1(φ)

Negative-binomial **type 1** family marker: linear mean–variance
`Var = μ(1 + φ)` with log link (`μ = exp η`), dispersion `φ > 0`. Used as the
family argument to the generic Laplace core (the NB1 twin of the
`NegativeBinomial(r, ·)` NB2 marker). Only the dispersion `φ` is stored.
"""
struct NB1{T<:Real}
    φ::T
end

default_link(::NB1) = LogLink()

_clamp_mu(::NB1, μ) = max(μ, 1e-12)
_glm_score(f::NB1, μ, n, me, y) = (y - μ) / (μ * (one(μ) + f.φ)) * me  # log link ⇒ (y−μ)/(1+φ)
_glm_weight(f::NB1, μ, n, me)   = me^2 / (μ * (one(μ) + f.φ))

# Closed-form NB1 conditional log-density. With r = μ/φ, p = 1/(1+φ):
#   ℓ = logΓ(y+r) − logΓ(r) − logΓ(y+1) + r·log p + y·log(1−p).
# log p = −log(1+φ); log(1−p) = log φ − log(1+φ).
function _glm_logpdf(f::NB1, μ, n, y)
    φ = f.φ
    r = μ / φ
    log1pφ = log1p(φ)
    return loggamma(y + r) - loggamma(r) - loggamma(y + one(y)) +
           r * (-log1pφ) + y * (log(φ) - log1pφ)
end

"""
    nb1_marginal_loglik_laplace(Y, Λ, β, φ; link=LogLink(), kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a negative-binomial
**type 1** (NB1) GLLVM with dispersion `φ` (`Var = μ(1+φ)`, log link) — a thin
wrapper over the family-generic `marginal_loglik_laplace` with the `NB1(φ)`
marker. `Y` is the p×n integer count matrix; `Λ` p×K; `β` length-p. As `φ → 0`
this tends to the Poisson marginal.
"""
nb1_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix, β::AbstractVector,
        φ::Real; link::Link = LogLink(), kwargs...) =
    marginal_loglik_laplace(NB1(φ), Y, ones(Int, size(Y)), Λ, β, link; kwargs...)

# ---------------------------------------------------------------------------
# Fit driver.
# ---------------------------------------------------------------------------

"""
    NB1Fit

Result of [`fit_nb1_gllvm`](@ref): intercepts `β` (length p), loadings `Λ` (p×K),
the estimated dispersion `φ` (linear variance `Var = μ(1+φ)`), the `link`, the
maximised Laplace `loglik`, the optimiser `converged` flag, and `iterations`.
"""
struct NB1Fit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    φ::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::NB1Fit)
    p, K = size(f.Λ)
    print(io, "NB1Fit(p=", p, ", K=", K, ", φ=", round(f.φ; sigdigits = 4),
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_nb1_gllvm(Y; K, link=LogLink(), φ_init=nothing, …) -> NB1Fit

Fit a negative-binomial **type 1** (NB1, `Var = μ(1+φ)`) GLLVM by L-BFGS over
`[β; vec(Λ); log φ]` on the Laplace marginal (`nb1_marginal_loglik_laplace`),
jointly estimating the dispersion `φ`. `Y` is a p×n integer count matrix; `K` the
latent dimension. The L-BFGS gradient uses the generic implicit dense-Laplace
gradient (`marginal_loglik_laplace_implicit_value_grad`): the per-site latent
mode is found once by Fisher scoring, then the gradient is taken with the
implicit-function rule, with per-observation `(η, log φ)` derivatives supplied by
ForwardDiff through the closed-form `_glm_logpdf`. Warm start = empirical log-mean
intercepts + an SVD loadings init + a moderate `φ₀`.
"""
function fit_nb1_gllvm(Y::AbstractMatrix{<:Union{Missing, Integer}}; K::Integer,
        link::Link = LogLink(),
        β_init = nothing, Λ_init = nothing, φ_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    rr = rr_theta_len(p, K)

    # NA-aware warm start: per-trait observed-cell log-mean intercepts; missing cells
    # mean-filled for the SVD init ONLY (FIML estimator, issue #27). Byte-equivalent on dense Y.
    Zemp = Matrix{Float64}(undef, p, n)
    β0r = Vector{Float64}(undef, p)
    @inbounds for t in 1:p
        acc = 0.0; cnt = 0
        for i in 1:n
            if !ismissing(Y[t, i])
                v = linkfun(link, max(Y[t, i] + 0.5, 1e-4)); Zemp[t, i] = v; acc += v; cnt += 1
            end
        end
        m = cnt == 0 ? linkfun(link, 0.5) : acc / cnt
        β0r[t] = m
        for i in 1:n
            ismissing(Y[t, i]) && (Zemp[t, i] = m)
        end
    end
    β0 = β_init === nothing ? β0r : collect(float.(β_init))
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
    logφ0 = φ_init === nothing ? log(1.0) : log(float(φ_init))

    θ0 = vcat(β0, pack_lambda(Λ0), logφ0)
    family_fromθ = θ -> NB1(_positive_from_log(θ[end]))
    N = ones(Int, size(Y))
    value_grad(θ) = marginal_loglik_laplace_implicit_value_grad(
        family_fromθ, Y, N, θ, p, K, link; maxiter = newton_maxiter, tol = newton_tol)
    negll_fg!(F, G, θ) = _penalized_negloglik_fg!(F, G, value_grad, θ)
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    res = Optim.optimize(Optim.only_fg!(negll_fg!), θ0, ls,
                         Optim.Options(g_tol = g_tol, iterations = iterations))
    θ̂ = Optim.minimizer(res)
    β̂ = θ̂[1:p]
    Λ̂ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    φ̂ = _positive_from_log(θ̂[p + rr + 1])
    return NB1Fit(β̂, Λ̂, φ̂, link, -Optim.minimum(res),
                  Optim.converged(res), Optim.iterations(res))
end
