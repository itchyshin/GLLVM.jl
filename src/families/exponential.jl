# Exponential (positive continuous, no dispersion) family for the generic Laplace
# core (src/families/laplace.jl). y_t > 0; mean μ = exp(η) (log link), so the
# per-observation law is Exponential(μ) — i.e. Gamma(shape 1, scale μ): E[y]=μ,
# Var = μ². It is the dispersion-free special case of the Gamma family (α ≡ 1),
# so its score/weight are the Gamma GLM pieces at α = 1:
#   s = (y − μ)/μ² · dμ/dη,   W = (dμ/dη)²/μ²   (expected information ⇒ W ≥ 0).
_clamp_mu(::Exponential, μ) = max(μ, 1e-12)
_glm_score(::Exponential, μ, n, me, y) = (y - μ) / μ^2 * me
_glm_weight(::Exponential, μ, n, me)   = me^2 / μ^2
_glm_logpdf(::Exponential, μ, n, y)    = logpdf(Exponential(μ), y)

"""
    exponential_marginal_loglik_laplace(Y, Λ, β; link=LogLink(), kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of an Exponential GLLVM —
responses `Y > 0`, mean `μ = exp(η)` (log link), per-observation `Exponential(μ)`
(`Var = μ²`). A thin wrapper over the family-generic `marginal_loglik_laplace`
with the `Exponential` marker (its scale field is unused — `μ` comes from `η`).
"""
exponential_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix, β::AbstractVector;
        link::Link = LogLink(), kwargs...) =
    marginal_loglik_laplace(Exponential(1.0), Y, ones(Int, size(Y)), Λ, β, link; kwargs...)

# ---------------------------------------------------------------------------
# Fit driver.
# ---------------------------------------------------------------------------

"""
    ExponentialFit

Result of [`fit_exponential_gllvm`](@ref): intercepts `β` (length p), loadings `Λ`
(p×K), the `link`, the maximised Laplace `loglik`, the optimiser `converged` flag,
and `iterations`. (No dispersion — the Exponential has `Var = μ²` fixed.)
"""
struct ExponentialFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::ExponentialFit)
    p, K = size(f.Λ)
    print(io, "ExponentialFit(p=", p, ", K=", K, ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_exponential_gllvm(Y; K, link=LogLink(), …) -> ExponentialFit

Fit an Exponential GLLVM by L-BFGS over `[β; vec(Λ)]` on the Laplace marginal
(`exponential_marginal_loglik_laplace`). `Y` is a p×n matrix of positive reals;
`K` the latent dimension. Finite-difference gradient; warm start = log row-means
as intercepts + SVD of row-centred log-Y as loadings.
"""
function fit_exponential_gllvm(Y::AbstractMatrix{<:Real}; K::Integer,
        link::Link = LogLink(),
        β_init = nothing, Λ_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    rr = rr_theta_len(p, K)

    Zemp = log.(max.(Y, 1e-6))
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
        v = try
            -exponential_marginal_loglik_laplace(Y, Λ, β; link = link,
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
    return ExponentialFit(β̂, Λ̂, link, -Optim.minimum(res),
                          Optim.converged(res), Optim.iterations(res))
end
