# Tweedie (compound Poisson–Gamma, power 1 < p < 2) family pieces for the
# generic Laplace core (src/families/laplace.jl). Responses y ≥ 0: an exact
# point mass at 0 plus a positive continuous part — the standard model for
# biomass / abundance with true zeros. Mean μ = exp(η) (log link), dispersion
# φ > 0, power p ∈ (1, 2), variance function V(μ) = μ^p (Var = φ μ^p).
#
# Exponential-dispersion form (Dunn & Smyth 2005). The μ-dependent kernel of
# log f is  (1/φ)·[ y·μ^{1-p}/(1-p) − μ^{2-p}/(2-p) ]  (μ-free normaliser aside),
# so the Laplace score/weight wrt η need NO series:
#   score  s = (y − μ) μ^{1-p} / φ · (dμ/dη / μ)            (= (y−μ)μ^{1−p}/φ at log link)
#   weight W = (dμ/dη)² / (φ μ^p)                            (expected info = μ^{2−p}/φ)
# The normalising constant a(y, φ, p) is an infinite series (μ-free); it enters
# only the conditional log-density `_glm_logpdf`.

# A plain marker — NOT a Distributions type — carrying the dispersion φ and the
# power p. Used only by the dedicated Tweedie pieces below.
struct TweedieED
    φ::Float64
    p::Float64
end

_clamp_mu(::TweedieED, μ) = max(μ, 1e-12)

# Score/weight wrt η (log link ⇒ me = dμ/dη = μ). General me forms below.
_glm_score(f::TweedieED, μ, n, me, y) = me * (y - μ) / (f.φ * μ^f.p)
_glm_weight(f::TweedieED, μ, n, me)   = me^2 / (f.φ * μ^f.p)

# Numerically-safe log-sum-exp over a vector of log-weights.
@inline function _tweedie_logsumexp(logw::AbstractVector)
    m = maximum(logw)
    (isfinite(m) || return m)
    s = 0.0
    @inbounds for lw in logw
        s += exp(lw - m)
    end
    return m + log(s)
end

# log a(y, φ, p): the μ-free Dunn–Smyth normalising series (1 < p < 2, y > 0).
#   α = (2-p)/(1-p)  (α < 0 here)
#   logW_j = j·[ -α·log y + α·log(p-1) - (1-α)·log φ - log(2-p) ]
#            - logΓ(j+1) - logΓ(-jα)
#   log a  = -log y + logsumexp_j logW_j
# The summand peaks near j* ≈ y^{2-p} / (φ (2-p)); we sum a window around j*,
# expanding until the boundary terms fall ≳ 37 below the running max.
function _tweedie_logA(y::Float64, φ::Float64, p::Float64)
    α = (2.0 - p) / (1.0 - p)              # < 0 for 1 < p < 2
    # Per-j linear coefficient of the leading term.
    a = -α * log(y) + α * log(p - 1.0) - (1.0 - α) * log(φ) - log(2.0 - p)
    logW(j) = j * a - loggamma(j + 1.0) - loggamma(-j * α)

    jstar = max(1, round(Int, y^(2.0 - p) / (φ * (2.0 - p))))
    drop = 37.0
    cap = 5000
    W = 1
    local lo, hi, m, terms
    while true
        lo = max(1, jstar - W)
        hi = jstar + W
        terms = Float64[logW(float(j)) for j in lo:hi]
        m = maximum(terms)
        edge = max(terms[1], terms[end])
        if (m - edge) ≥ drop || W ≥ cap
            break
        end
        W *= 2
    end
    return -log(y) + _tweedie_logsumexp(terms)
end

"""
    tweedie_logpdf(y, μ, φ, p) -> Float64

Scalar Tweedie (compound Poisson–Gamma, power `1 < p < 2`) log-density in the
exponential-dispersion form (Dunn & Smyth 2005), with mean `μ`, dispersion `φ`
and `Var = φ μ^p`. Handles the exact point mass at `y = 0` and the positive
continuous part (the latter via the μ-free normalising series `log a(y,φ,p)`).
"""
function tweedie_logpdf(y::Real, μ::Real, φ::Real, p::Real)
    y = float(y); μ = float(μ); φ = float(φ); p = float(p)
    μ = max(μ, 1e-12)
    if y == 0.0
        # series term is 0, log a(0) = 0
        return -μ^(2.0 - p) / (φ * (2.0 - p))
    else
        kernel = (y * μ^(1.0 - p) / (1.0 - p) - μ^(2.0 - p) / (2.0 - p)) / φ
        return kernel + _tweedie_logA(y, φ, p)
    end
end

_glm_logpdf(f::TweedieED, μ, n, y) = tweedie_logpdf(y, μ, f.φ, f.p)

"""
    tweedie_marginal_loglik_laplace(Y, Λ, β, φ, p; link=LogLink(), kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a Tweedie GLLVM with
dispersion `φ` and power `p ∈ (1,2)` — responses `Y ≥ 0` with a point mass at 0,
mean `μ = exp(η)` (log link), `Var = φ μ^p`. A thin wrapper over the
family-generic `marginal_loglik_laplace` with the `TweedieED(φ, p)` marker.
"""
tweedie_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix, β::AbstractVector,
        φ::Real, p::Real; link::Link = LogLink(), maxiter::Integer = 100,
        tol::Real = 1e-9) =
    marginal_loglik_laplace(TweedieED(float(φ), float(p)), Y, ones(Int, size(Y)),
                            Λ, β, link; maxiter = maxiter, tol = tol)

# ---------------------------------------------------------------------------
# Fit driver.
# ---------------------------------------------------------------------------

"""
    TweedieFit

Result of [`fit_tweedie_gllvm`](@ref): intercepts `β` (length p), loadings `Λ`
(p×K), the estimated dispersion `φ` and power `p ∈ (1,2)` (`Var = φ μ^p`), the
`link`, the maximised Laplace `loglik`, the optimiser `converged` flag, and
`iterations`.
"""
struct TweedieFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    φ::Float64
    p::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::TweedieFit)
    pp, K = size(f.Λ)
    print(io, "TweedieFit(p=", pp, ", K=", K,
          ", φ=", round(f.φ; sigdigits = 4),
          ", power=", round(f.p; sigdigits = 4),
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_tweedie_gllvm(Y; K, link=LogLink(), φ_init=1.0, p_init=1.5, …) -> TweedieFit

Fit a Tweedie GLLVM by L-BFGS over `[β; pack_lambda(Λ); log φ; ξ]` on the Laplace
marginal (`tweedie_marginal_loglik_laplace`), jointly estimating the dispersion
`φ` and power `p`. The power is mapped to `(1,2)` by `p = 1 + 1/(1+exp(-ξ))`
(so `ξ = 0 ⇒ p = 1.5`). `Y` is a p×n matrix of non-negative reals (a point mass
at 0 allowed); `K` the latent dimension. Finite-difference gradient; warm start =
log row-means of `max(Y, 1e-6)` as intercepts + SVD of row-centred log-Y as
loadings + `logφ₀ = log(φ_init)`, `ξ₀ = logit(p_init − 1)`.
"""
function fit_tweedie_gllvm(Y::AbstractMatrix{<:Real}; K::Integer,
        link::Link = LogLink(), φ_init::Real = 1.0, p_init::Real = 1.5,
        β_init = nothing, Λ_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p_sp, n = size(Y)
    rr = rr_theta_len(p_sp, K)

    Zemp = log.(max.(Y, 1e-6))
    β0 = β_init === nothing ? vec(sum(Zemp; dims = 2)) ./ n : collect(float.(β_init))
    Λ0 = if Λ_init === nothing
        Zc = Zemp .- β0
        F = svd(Zc)
        kk = min(K, length(F.S))
        L = zeros(p_sp, K)
        @inbounds for j in 1:kk
            L[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
        end
        L
    else
        collect(float.(Λ_init))
    end
    logφ0 = log(float(φ_init))
    ξ0 = log((float(p_init) - 1.0) / (2.0 - float(p_init)))   # logit(p_init - 1)

    θ0 = vcat(β0, pack_lambda(Λ0), logφ0, ξ0)
    function negll(θ)
        β = θ[1:p_sp]
        Λ = unpack_lambda(θ[(p_sp + 1):(p_sp + rr)], p_sp, K)
        φ = exp(θ[p_sp + rr + 1])
        ξ = θ[p_sp + rr + 2]
        pw = 1.0 + 1.0 / (1.0 + exp(-ξ))
        v = try
            -tweedie_marginal_loglik_laplace(Y, Λ, β, φ, pw;
                                             link = link,
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
    β̂ = θ̂[1:p_sp]
    Λ̂ = unpack_lambda(θ̂[(p_sp + 1):(p_sp + rr)], p_sp, K)
    φ̂ = exp(θ̂[p_sp + rr + 1])
    p̂ = 1.0 + 1.0 / (1.0 + exp(-θ̂[p_sp + rr + 2]))
    return TweedieFit(β̂, Λ̂, φ̂, p̂, link, -Optim.minimum(res),
                      Optim.converged(res), Optim.iterations(res))
end
