# Gamma (positive continuous) family pieces for the generic Laplace core
# (src/families/laplace.jl). y_t > 0; mean μ = exp(η) (log link), shape α;
# the per-observation law is Gamma(shape α, scale μ/α), so E[y] = μ and
# Var = μ²/α. The shape `α` is carried in the family marker `Gamma(α, ·)` —
# only its `α` field is read.
#
# Score/weight wrt η (Gamma GLM, variance function V(μ) = μ²/α):
#   s = α (y − μ) / μ² · dμ/dη
#   W = α (dμ/dη)² / μ²          (expected information ⇒ W ≥ 0)
_clamp_mu(::Gamma, μ) = max(μ, 1e-12)
_glm_score(f::Gamma, μ, n, me, y) = f.α * (y - μ) / μ^2 * me
_glm_weight(f::Gamma, μ, n, me)   = f.α * me^2 / μ^2
_glm_logpdf(f::Gamma, μ, n, y)    = logpdf(Gamma(f.α, μ / f.α), y)

"""
    gamma_marginal_loglik_laplace(Y, Λ, β, α; link=LogLink(), kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a Gamma GLLVM with
shape `α` — responses `Y > 0`, mean `μ = exp(η)` (log link), per-observation
`Gamma(α, μ/α)` (`Var = μ²/α`). A thin wrapper over the family-generic
`marginal_loglik_laplace` with the `Gamma(α, ·)` marker.
"""
gamma_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix, β::AbstractVector,
        α::Real; link::Link = LogLink(), kwargs...) =
    marginal_loglik_laplace(Gamma(float(α), 1.0), Y, ones(Int, size(Y)), Λ, β, link; kwargs...)

# ---------------------------------------------------------------------------
# Fit driver (Gamma family slice 2).
# ---------------------------------------------------------------------------

"""
    GammaFit

Result of [`fit_gamma_gllvm`](@ref): intercepts `β` (length p), loadings `Λ` (p×K),
the estimated shape `α` (Var = μ²/α), the `link`, the maximised Laplace
`loglik`, the optimiser `converged` flag, and `iterations`.
"""
struct GammaFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    α::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::GammaFit)
    p, K = size(f.Λ)
    print(io, "GammaFit(p=", p, ", K=", K, ", α=", round(f.α; sigdigits = 4),
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_gamma_gllvm(Y; K, link=LogLink(), α_init=nothing, …) -> GammaFit

Fit a Gamma GLLVM by L-BFGS over `[β; vec(Λ); log α]` on the Laplace marginal
(`gamma_marginal_loglik_laplace`), jointly estimating the shape `α`
(`Var = μ²/α`). `Y` is a p×n matrix of positive reals; `K` the latent
dimension. Finite-difference gradient; warm start = log row-means as intercepts +
SVD of row-centred log-Y as loadings + `logα₀ = log(2.0)`.
"""
function fit_gamma_gllvm(Y::AbstractMatrix; K::Integer,
        link::Link = LogLink(), mask = nothing,
        β_init = nothing, Λ_init = nothing, α_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    rr = rr_theta_len(p, K)

    msk = _resolve_obs_mask(mask, Y)                  # NA handling
    Yc  = _sanitize_missing(Y, 1.0)                   # positive placeholder

    Zemp = log.(max.(Yc, 1e-6))
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
    logα0 = α_init === nothing ? log(2.0) : log(float(α_init))

    θ0 = vcat(β0, pack_lambda(Λ0), logα0)
    function negll(θ)
        β = θ[1:p]
        Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        α = exp(θ[p + rr + 1])
        v = try
            -gamma_marginal_loglik_laplace(Yc, Λ, β, α; mask = msk,
                                           maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    res = Optim.optimize(negll, θ0, ls, Optim.Options(g_tol = g_tol, iterations = iterations);
                         autodiff = :finite)
    θ̂ = Optim.minimizer(res)
    β̂ = θ̂[1:p]
    Λ̂ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    α̂ = exp(θ̂[p + rr + 1])
    return GammaFit(β̂, Λ̂, α̂, link, -Optim.minimum(res),
                   Optim.converged(res), Optim.iterations(res))
end
