# Ordered-beta family (Kubinec 2023) for the GLLVM Laplace path.
#
# Responses y ∈ [0,1] with point masses at exactly 0 and 1 plus a continuous Beta
# interior — proportion / cover data. One latent linear predictor η drives all
# three regions via two ordered cutpoints c0 < c1 and a Beta precision φ:
#
#     P(y=0)     = 1 − σ(η − c0)            = σ(c0 − η)
#     P(0<y<1)   = σ(η − c0) − σ(η − c1)
#     P(y=1)     = σ(η − c1)
#     interior density: [σ(η−c0) − σ(η−c1)] · Beta(y; μφ, (1−μ)φ),  μ = σ(η),
#
# so
#     log p(y|η) = (y==0) ? log σ(c0−η)
#                : (y==1) ? log σ(η−c1)
#                : log(σ(η−c0) − σ(η−c1)) + logpdf(Beta(μφ,(1−μ)φ), y).
#
# The link here is identity-on-η (the family marker carries c0, c1, φ; μ = σ(η)
# is formed inside the pieces), so this file runs its OWN per-site Laplace,
# mirroring `_laplace_mode` / `laplace_loglik_site` from families/laplace.jl. The
# per-trait score s_t = ∂log p/∂η and weight W_t = −∂²log p/∂η² are obtained by
# ForwardDiff on the scalar map η → log p (lower risk than the messy three-branch
# closed form), with W_t clamped to ≥ 1e-8 for SPD.

"""
    OrderedBeta(c0, c1, φ)

Ordered-beta family marker (Kubinec 2023). `c0 < c1` are the ordered cutpoints
that carve the zero / interior / one regions out of the latent η, and `φ` is the
Beta precision of the (0,1) interior. Used only as a tag for the dedicated
ordered-beta Laplace path.
"""
struct OrderedBeta <: Distribution{Univariate, Continuous}
    c0::Float64
    c1::Float64
    φ::Float64
end

# logistic σ(x), numerically safe at large |x|.
_ob_logistic(x) = x ≥ 0 ? inv(one(x) + exp(-x)) : (e = exp(x); e / (one(x) + e))
# log σ(x) = −log(1 + e^{−x}), numerically safe.
_ob_logsigmoid(x) = -log1p(exp(-abs(x))) + (x < 0 ? x : zero(x))

const _OB_MU_LO = 1e-12
const _OB_MU_HI = 1 - 1e-12

"""
    ordered_beta_logp(y, η, c0, c1, φ) -> Float64

Scalar ordered-beta conditional log-density log p(y|η) for one trait. `y == 0`
and `y == 1` hit the point masses; `0 < y < 1` adds the interior Beta log-density
with `μ = σ(η)` clamped to (1e-12, 1−1e-12).
"""
function ordered_beta_logp(y, η, c0, c1, φ)
    if y == 0
        return _ob_logsigmoid(c0 - η)
    elseif y == 1
        return _ob_logsigmoid(η - c1)
    else
        # interior mass: log(σ(η−c0) − σ(η−c1)); since c0 < c1, σ(η−c0) > σ(η−c1).
        s0 = _ob_logistic(η - c0)
        s1 = _ob_logistic(η - c1)
        logmass = log(s0 - s1)
        μ = clamp(_ob_logistic(η), _OB_MU_LO, _OB_MU_HI)
        return logmass + logpdf(Beta(μ * φ, (one(μ) - μ) * φ), y)
    end
end

# Per-trait score s_t = ∂log p/∂η and weight W_t = −∂²log p/∂η², via ForwardDiff
# on the scalar map η → log p. W clamped to ≥ 1e-8 to keep Λ'WΛ + I SPD.
function _ob_score_weight(y, η, c0, c1, φ)
    f  = ηv -> ordered_beta_logp(y, ηv, c0, c1, φ)
    g  = ηv -> ForwardDiff.derivative(f, ηv)
    s  = g(η)
    W  = -ForwardDiff.derivative(g, η)
    return s, max(W, 1e-8)
end

# Inner Laplace mode-finder for one site (Newton on the negative second
# derivative). Mirrors `_laplace_mode` from families/laplace.jl.
function _ordered_beta_mode(y::AbstractVector, Λ::AbstractMatrix, β::AbstractVector,
        c0::Real, c1::Real, φ::Real; maxiter::Integer = 100, tol::Real = 1e-9)
    p, K = size(Λ)
    z = zeros(K)
    for _ in 1:maxiter
        η = β .+ Λ * z
        s = Vector{Float64}(undef, p)
        W = Vector{Float64}(undef, p)
        @inbounds for t in 1:p
            st, Wt = _ob_score_weight(y[t], η[t], c0, c1, φ)
            s[t] = st
            W[t] = Wt
        end
        A = Symmetric(Λ' * (W .* Λ) + I)
        Δ = _safe_solve(A, Λ' * s .- z)
        (Δ === nothing || !all(isfinite, Δ)) && break
        z = z .+ Δ
        maximum(abs, Δ) < tol && break
    end
    return z
end

# Per-site Laplace log-marginal:
#   log p(y_s) ≈ ℓ(ẑ) − ½ẑ'ẑ − ½logdet(Λ'WΛ + I).
function _ordered_beta_loglik_site(y::AbstractVector, Λ::AbstractMatrix,
        β::AbstractVector, c0::Real, c1::Real, φ::Real;
        maxiter::Integer = 100, tol::Real = 1e-9)
    p, K = size(Λ)
    z = _ordered_beta_mode(y, Λ, β, c0, c1, φ; maxiter = maxiter, tol = tol)
    η = β .+ Λ * z
    ℓ = 0.0
    W = Vector{Float64}(undef, p)
    @inbounds for t in 1:p
        ℓ += ordered_beta_logp(y[t], η[t], c0, c1, φ)
        _, Wt = _ob_score_weight(y[t], η[t], c0, c1, φ)
        W[t] = Wt
    end
    A = Symmetric(Λ' * (W .* Λ) + I)
    return ℓ - 0.5 * dot(z, z) - 0.5 * logdet(A)
end

"""
    ordered_beta_marginal_loglik_laplace(Y, Λ, β, c0, c1, φ; maxiter=100, tol=1e-9) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of an ordered-beta GLLVM.
`Y` is a p×n matrix of responses in `[0,1]` (with exact 0s and 1s allowed); `Λ`
p×K loadings; `β` length-p intercepts; `c0 < c1` the ordered cutpoints; `φ` the
Beta precision. Runs its own per-site Laplace (identity-on-η link). At `Λ = 0`
this reduces exactly to the sum of the independent ordered-beta `logp`.
"""
function ordered_beta_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix,
        β::AbstractVector, c0::Real, c1::Real, φ::Real;
        maxiter::Integer = 100, tol::Real = 1e-9)
    acc = 0.0
    @inbounds for i in axes(Y, 2)
        acc += _ordered_beta_loglik_site(view(Y, :, i), Λ, β, c0, c1, φ;
                                         maxiter = maxiter, tol = tol)
    end
    return acc
end

# ---------------------------------------------------------------------------
# Fit driver.
# ---------------------------------------------------------------------------

"""
    OrderedBetaFit

Result of [`fit_ordered_beta_gllvm`](@ref): intercepts `β` (length p), loadings
`Λ` (p×K), the ordered cutpoints `c0 < c1`, the Beta precision `φ`, the maximised
Laplace `loglik`, the optimiser `converged` flag, and `iterations`.
"""
struct OrderedBetaFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    c0::Float64
    c1::Float64
    φ::Float64
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::OrderedBetaFit)
    p, K = size(f.Λ)
    print(io, "OrderedBetaFit(p=", p, ", K=", K,
          ", c0=", round(f.c0; sigdigits = 4),
          ", c1=", round(f.c1; sigdigits = 4),
          ", φ=", round(f.φ; sigdigits = 4),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_ordered_beta_gllvm(Y; K, c0_init=-1.0, c1_init=1.0, φ_init=nothing, …) -> OrderedBetaFit

Fit an ordered-beta GLLVM by L-BFGS on the Laplace marginal
(`ordered_beta_marginal_loglik_laplace`), jointly estimating the cutpoints
`c0 < c1` (parameterised `c1 = c0 + exp(Δ)` to keep the order) and the Beta
precision `φ`. `Y` is a p×n matrix of responses in `[0,1]`; `K` the latent
dimension. The optimiser θ = `[β(p); pack_lambda(Λ)(rr); c0; Δ; log φ]`. Finite-
difference gradient; warm start = empirical logit-mean intercepts (interior
values only) + an SVD loadings init + a moderate `φ₀`, mirroring `fit_beta_gllvm`.
"""
function fit_ordered_beta_gllvm(Y::AbstractMatrix{<:Real}; K::Integer,
        c0_init::Real = -1.0, c1_init::Real = 1.0,
        β_init = nothing, Λ_init = nothing, φ_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    rr = rr_theta_len(p, K)

    # warm start: empirical logit-mean over interior values (fall back to clamp).
    Zemp = [log(clamp(float(Y[t, i]), 1e-3, 1 - 1e-3) /
                (1 - clamp(float(Y[t, i]), 1e-3, 1 - 1e-3))) for t in 1:p, i in 1:n]
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
    c0_0  = float(c0_init)
    Δ0    = log(max(float(c1_init) - c0_0, 1e-3))      # c1 = c0 + exp(Δ)

    θ0 = vcat(β0, pack_lambda(Λ0), c0_0, Δ0, logφ0)
    function negll(θ)
        β  = θ[1:p]
        Λ  = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        c0 = θ[p + rr + 1]
        c1 = c0 + exp(θ[p + rr + 2])
        φ  = exp(θ[p + rr + 3])
        v = try
            -ordered_beta_marginal_loglik_laplace(Y, Λ, β, c0, c1, φ;
                                                  maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    res = Optim.optimize(negll, θ0, ls, Optim.Options(g_tol = g_tol, iterations = iterations);
                         autodiff = :finite)
    θ̂  = Optim.minimizer(res)
    β̂  = θ̂[1:p]
    Λ̂  = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    c0̂ = θ̂[p + rr + 1]
    c1̂ = c0̂ + exp(θ̂[p + rr + 2])
    φ̂  = exp(θ̂[p + rr + 3])
    return OrderedBetaFit(β̂, Λ̂, c0̂, c1̂, φ̂, -Optim.minimum(res),
                          Optim.converged(res), Optim.iterations(res))
end
