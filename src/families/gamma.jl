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
_glm_logpdf(f::Gamma, μ, n, y) =
    f.α * (log(f.α) - log(μ)) - loggamma(f.α) +
    (f.α - one(f.α)) * log(y) - f.α * y / μ

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

Fit a Gamma GLLVM by L-BFGS over `[β; vec(Λ); log α]` on the Laplace marginal,
jointly estimating the shape `α` (`Var = μ²/α`). `Y` is a p×n matrix of
positive reals; `K` the latent dimension. The L-BFGS gradient uses the
scalar-auxiliary implicit-gradient path: the site mode is held by the envelope
equation, while the Gamma log-link observation derivatives are closed form.
Warm start = log row-means as intercepts + SVD of row-centred log-Y as loadings
and `logα₀ = log(2.0)`.
"""
function fit_gamma_gllvm(Y::AbstractMatrix{<:Union{Missing, Real}}; K::Integer,
        link::Link = LogLink(),
        β_init = nothing, Λ_init = nothing, α_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    rr = rr_theta_len(p, K)

    # NA-aware warm start: per-trait observed-cell log-mean intercepts; missing cells
    # mean-filled for the SVD init ONLY (FIML estimator, issue #27). Byte-equivalent
    # on a dense Y.
    Zemp = Matrix{Float64}(undef, p, n)
    β0r = Vector{Float64}(undef, p)
    @inbounds for t in 1:p
        acc = 0.0; cnt = 0
        for i in 1:n
            if !ismissing(Y[t, i])
                v = log(max(float(Y[t, i]), 1e-6)); Zemp[t, i] = v; acc += v; cnt += 1
            end
        end
        m = cnt == 0 ? 0.0 : acc / cnt
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
    logα0 = α_init === nothing ? log(2.0) : log(float(α_init))

    θ0 = vcat(β0, pack_lambda(Λ0), logα0)
    family_from_aux = aux -> Gamma(_positive_from_log(aux[1]), 1.0)
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
    α̂ = _positive_from_log(θ̂[p + rr + 1])
    return GammaFit(β̂, Λ̂, α̂, link, -Optim.minimum(res),
                   Optim.converged(res), Optim.iterations(res))
end
