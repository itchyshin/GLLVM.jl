# Beta (proportions in (0,1)) family pieces for the generic Laplace core
# (src/families/laplace.jl). y_t ∈ (0,1); mean μ = linkinv(link, η) (logit link),
# precision φ; the per-observation law is Beta(μφ, (1−μ)φ), Var = μ(1−μ)/(1+φ).
# The precision φ is carried in the family marker `Beta(φ, ·)` — only its `α`
# field is read as φ.
#
# Score/weight wrt η (Ferrari & Cribari-Neto 2004 beta regression):
#   y*  = logit(y),   μ* = ψ(μφ) − ψ((1−μ)φ)
#   s   = φ (y* − μ*) · dμ/dη
#   W   = φ² [ψ′(μφ) + ψ′((1−μ)φ)] · (dμ/dη)²        (expected information ⇒ W ≥ 0)
# with ψ = digamma, ψ′ = trigamma.
_clamp_mu(::Beta, μ) = clamp(μ, 1e-6, 1 - 1e-6)

function _glm_score(f::Beta, μ, n, me, y)
    φ = f.α
    ystar = log(y) - log1p(-y)                      # logit(y)
    μstar = digamma(μ * φ) - digamma((1 - μ) * φ)
    return φ * (ystar - μstar) * me
end

function _glm_weight(f::Beta, μ, n, me)
    φ = f.α
    ν = trigamma(μ * φ) + trigamma((1 - μ) * φ)
    return φ^2 * ν * me^2
end

_glm_logpdf(f::Beta, μ, n, y) = logpdf(Beta(μ * f.α, (1 - μ) * f.α), y)

"""
    beta_marginal_loglik_laplace(Y, Λ, β, φ; link=LogitLink(), kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a Beta GLLVM with
precision `φ` — responses `Y ∈ (0,1)`, mean `μ = logistic(η)`, per-observation
`Beta(μφ, (1−μ)φ)` (`Var = μ(1−μ)/(1+φ)`). A thin wrapper over the family-generic
`marginal_loglik_laplace` with the `Beta(φ, ·)` marker.
"""
beta_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix, β::AbstractVector,
        φ::Real; link::Link = LogitLink(), kwargs...) =
    marginal_loglik_laplace(Beta(float(φ), 1.0), Y, ones(Int, size(Y)), Λ, β, link; kwargs...)

# ---------------------------------------------------------------------------
# Fit driver (Beta family slice 2).
# ---------------------------------------------------------------------------

"""
    BetaFit

Result of [`fit_beta_gllvm`](@ref): intercepts `β` (length p), loadings `Λ` (p×K),
the estimated precision `φ` (Var = μ(1−μ)/(1+φ)), the `link`, the maximised Laplace
`loglik`, the optimiser `converged` flag, and `iterations`.
"""
struct BetaFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    φ::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::BetaFit)
    p, K = size(f.Λ)
    print(io, "BetaFit(p=", p, ", K=", K, ", φ=", round(f.φ; sigdigits = 4),
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_beta_gllvm(Y; K, link=LogitLink(), φ_init=nothing, …) -> BetaFit

Fit a Beta GLLVM by L-BFGS over `[β; vec(Λ); log φ]` on the Laplace marginal
(`beta_marginal_loglik_laplace`), jointly estimating the precision `φ`
(`Var = μ(1−μ)/(1+φ)`). `Y` is a p×n matrix of proportions in (0,1); `K` the latent
dimension. The L-BFGS gradient uses a scalar-auxiliary implicit dense-Laplace
gradient: observation derivatives are taken only with respect to `(η, log φ)`,
then the packed gradient is assembled analytically. Warm start = empirical
logit-mean intercepts + an SVD loadings init + a moderate `φ₀`.
"""
function fit_beta_gllvm(Y::AbstractMatrix{<:Union{Missing, Real}}; K::Integer,
        link::Link = LogitLink(),
        β_init = nothing, Λ_init = nothing, φ_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    rr = rr_theta_len(p, K)

    # NA-aware warm start: per-trait observed-cell logit intercepts; missing cells
    # mean-filled for the SVD init ONLY (FIML estimator, issue #27). Byte-equivalent
    # on a dense Y.
    Zemp = Matrix{Float64}(undef, p, n)
    β0r = Vector{Float64}(undef, p)
    @inbounds for t in 1:p
        acc = 0.0; cnt = 0
        for i in 1:n
            if !ismissing(Y[t, i])
                v = linkfun(link, clamp(float(Y[t, i]), 1e-6, 1 - 1e-6))
                Zemp[t, i] = v; acc += v; cnt += 1
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
    logφ0 = φ_init === nothing ? log(10.0) : log(float(φ_init))

    θ0 = vcat(β0, pack_lambda(Λ0), logφ0)
    family_from_aux = aux -> Beta(_positive_from_log(aux[1]), 1.0)
    N = ones(Int, size(Y))
    value_grad(θ) = marginal_loglik_laplace_aux_value_grad(
        family_from_aux, Y, N, θ, p, K, link; maxiter = newton_maxiter, tol = newton_tol)
    Zcache = zeros(Float64, K, n)
    cached_value_grad(θ) = marginal_loglik_laplace_aux_value_grad!(
        Zcache, family_from_aux, Y, N, θ, p, K, link;
        maxiter = newton_maxiter, tol = newton_tol)
    negll_fg!(F, G, θ) = _penalized_negloglik_fg!(F, G, value_grad, θ)
    cached_negll_fg!(F, G, θ) = _penalized_negloglik_fg!(F, G, cached_value_grad, θ)
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    cached_res = Optim.optimize(Optim.only_fg!(cached_negll_fg!), θ0, ls,
                                Optim.Options(g_tol = g_tol, iterations = iterations))
    res, total_iterations = if Optim.converged(cached_res)
        cached_res, Optim.iterations(cached_res)
    else
        polish_res = Optim.optimize(Optim.only_fg!(negll_fg!), Optim.minimizer(cached_res), ls,
                                    Optim.Options(g_tol = g_tol, iterations = iterations))
        if Optim.converged(polish_res) || Optim.minimum(polish_res) <= Optim.minimum(cached_res)
            polish_res, Optim.iterations(cached_res) + Optim.iterations(polish_res)
        else
            cached_res, Optim.iterations(cached_res)
        end
    end
    θ̂ = Optim.minimizer(res)
    β̂ = θ̂[1:p]
    Λ̂ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    φ̂ = _positive_from_log(θ̂[p + rr + 1])
    return BetaFit(β̂, Λ̂, φ̂, link, -Optim.minimum(res),
                   Optim.converged(res), total_iterations)
end
