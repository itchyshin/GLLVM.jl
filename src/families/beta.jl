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
dimension. The default analytic Laplace gradient is used on the plain
no-mask/no-offset path, with an internal finite-difference fallback; masked or
offset fits use finite differences. Warm start = empirical logit-mean intercepts +
an SVD loadings init + a moderate `φ₀`.
"""
function fit_beta_gllvm(Y::AbstractMatrix; K::Integer,
        link::Link = LogitLink(), mask = nothing, offset = nothing,
        gradient::Symbol = :analytic,
        β_init = nothing, Λ_init = nothing, φ_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    rr = rr_theta_len(p, K)

    msk = _resolve_obs_mask(mask, Y)                  # NA handling
    Yc  = _sanitize_missing(Y, 0.5)                   # in-(0,1) placeholder

    Zemp = [linkfun(link, clamp(float(Yc[t, i]), 1e-6, 1 - 1e-6)) for t in 1:p, i in 1:n]
    offset === nothing || (Zemp .-= offset)           # offset (η = β + offset + Λz)
    _mask_warmstart!(Zemp, msk)
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
    logφ0 = φ_init === nothing ? log(10.0) : log(float(φ_init))

    θ0 = vcat(β0, pack_lambda(Λ0), logφ0)
    function negll(θ)
        β = θ[1:p]
        Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        φ = exp(θ[p + rr + 1])
        v = try
            -beta_marginal_loglik_laplace(Yc, Λ, β, φ; mask = msk, offset = offset,
                                          maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    opts = Optim.Options(g_tol = g_tol, iterations = iterations)
    res = if gradient === :analytic && offset === nothing
        ag = θ -> begin
            β = θ[1:p]; Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K); fv = exp(θ[p + rr + 1])
            try -beta_laplace_grad(Yc, Λ, β, fv; mask = msk) catch; nothing end
        end
        _optimize_with_analytic(negll, ag, θ0, ls, opts)
    else
        Optim.optimize(negll, θ0, ls, opts; autodiff = :finite)
    end
    θ̂ = Optim.minimizer(res)
    β̂ = θ̂[1:p]
    Λ̂ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    φ̂ = exp(θ̂[p + rr + 1])
    return BetaFit(β̂, Λ̂, φ̂, link, -Optim.minimum(res),
                   Optim.converged(res), Optim.iterations(res))
end
