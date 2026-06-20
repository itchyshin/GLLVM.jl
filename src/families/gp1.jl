# Generalized-Poisson type-1 (GP-1, Famoye/Consul–Jain) family pieces for the
# generic Laplace core (src/families/laplace.jl). GLLVM.jl issue #104.
#
# Mean parameterization with a SIGNED scalar dispersion α (over- or under-dispersion):
#   y ~ GP1(μ, α),   μ = exp(η) (log link),   E[y] = μ,   Var = μ (1 + α μ)².
# α = 0 is the Poisson limit; α > 0 overdisperses (Var > μ), α < 0 underdisperses.
#
# pmf (Famoye 1993 mean-parameterized GP-1), with g = 1 + α μ and h = 1 + α y:
#   P(y) = (μ/g)^y · h^(y-1) / y! · exp(−μ h / g),    y = 0, 1, 2, …
# Domain: g = 1 + α μ > 0 and h = 1 + α y > 0.
#
# NOTE — pmf correction (issue #104 task spec). The task wrote the leading factor as
#   μ · g^(−y)   (i.e. a single power of μ),
# which does NOT normalize to 1 and does NOT reduce to Poisson at α → 0 (verified
# numerically: at α ≈ 0 the written form gives P(0) ≠ exp(−μ)). The correct Famoye
# GP-1 leading factor is (μ/g)^y = μ^y g^(−y). With (μ/g)^y the pmf:
#   • sums to 1 for α ≥ 0 (machine precision, verified numerically); for α < 0 the
#     Consul/Famoye GP has finite support y < 1/|α| and the truncated tail loses a
#     small mass when |α|μ is large (e.g. μ=8, α=−0.10 ⇒ sum≈0.983) — an intrinsic
#     property of the underdispersed GP, not an implementation error. Overdispersion
#     (α > 0) is the unconstrained, exactly-normalized regime,
#   • has E[y] = μ and Var = μ(1+α μ)² exactly (the task's stated variance; exact for
#     α ≥ 0 and for mild underdispersion), and
#   • reduces to Poisson(μ) as α → 0.
# This file implements the CORRECT (μ/g)^y form; the stated variance Var = μ(1+α μ)²
# from the task is reproduced exactly. (Numerical confirmation in test/test_gp1_laplace.jl.)
#
# log-pmf (the implemented form):
#   logL = y(log μ − log g) + (y−1) log h − lgamma(y+1) − μ h / g.
#
# Score / weight wrt η (log link ⇒ me = dμ/dη = μ):
#   dlogL/dμ = y/μ − y α/g − h/g²
#   s = me · dlogL/dμ = y − μ y α/g − μ h/g²        (E[s] = 0; α→0 ⇒ s = y − μ)
#   W = E[s²] = μ / g² = μ / (1+α μ)²               (EXACT Fisher info wrt η, ≥ 0 ⇒ SPD;
#                                                     α→0 ⇒ W = μ, matching Poisson)
# The Fisher weight is exact here (E[s²] = μ/g² verified numerically), so A = Λ'WΛ + I
# is SPD by construction, exactly as for Poisson.

# Marker — carries the SIGNED scalar dispersion α (Var = μ(1+α μ)²). Unlike NB's r,
# Beta's φ, Gamma's α (all positive, packed as log-param), GP-1's α may be negative and
# is therefore packed RAW (no log transform) in the fit path.
struct GeneralizedPoisson1{T}
    α::T
end

# Canonical link is log (registered here, not in links.jl, since the marker is our
# own struct — mirrors `Ordinal` in ordinal.jl).
default_link(::GeneralizedPoisson1) = LogLink()

# Domain-safe μ (shared with the Poisson idiom). The α-domain guard 1+αμ>0 is handled
# in the score/weight/log-pmf below (and the η-clamp keeps μ bounded).
_clamp_mu(::GeneralizedPoisson1, μ) = max(μ, 1e-12)

# Score wrt η (me = μ): s = y − μ y α/g − μ h/g². α→0 short-circuits to the Poisson
# score y − μ to avoid 0·(…)/g cancellation noise near the limit.
function _glm_score(f::GeneralizedPoisson1, μ, n, me, y)
    a = f.α
    abs(a) < 1e-10 && return (y - μ) / μ * me          # Poisson score (= y − μ for me = μ)
    g = 1 + a * μ
    h = 1 + a * y
    return me * (y / μ - y * a / g - h / g^2)
end

# Fisher weight wrt η: W = μ / g² (exact expected information). α→0 ⇒ W = μ.
function _glm_weight(f::GeneralizedPoisson1, μ, n, me)
    a = f.α
    abs(a) < 1e-10 && return me^2 / μ                  # Poisson weight (= μ for me = μ)
    g = 1 + a * μ
    return me^2 / (μ * g^2)                            # me²/Var, Var = μ g²
end

# Conditional log-pmf. α→0 delegates to Poisson's logpdf (exact, avoids cancellation).
function _glm_logpdf(f::GeneralizedPoisson1, μ, n, y)
    a = f.α
    abs(a) < 1e-10 && return logpdf(Poisson(μ), Int(y))
    g = 1 + a * μ
    h = 1 + a * y
    return y * (log(μ) - log(g)) + (y - 1) * log(h) - loggamma(y + 1.0) - μ * h / g
end

# Upper support: α<0 gives finite support y < 1/|α| (h = 1+αy > 0); α≥0 is unbounded.
_gp1_ymax(α) = α < 0 ? floor(Int, -1 / α - 1e-9) : typemax(Int)

# CDF F(y)=P(Y≤y) summed from the log-pmf (GP-1 has no Distributions object). Used by
# Dunn–Smyth residuals; caps at the α<0 truncation support.
function _gp1_cdf(f::GeneralizedPoisson1, μ, y::Integer)
    y < 0 && return 0.0
    yt = min(Int(y), _gp1_ymax(f.α))
    s = 0.0
    @inbounds for k in 0:yt
        s += exp(_glm_logpdf(f, μ, 1, k))
    end
    return min(s, 1.0)
end

# Inverse-CDF GP-1 sampler (parametric bootstrap for confint). For α≥0 the loop is
# capped well beyond the mean μ + 50·sd (sd = √μ·(1+αμ)) so it always terminates.
function _rand_gp1(rng::AbstractRNG, f::GeneralizedPoisson1, μ)
    a = f.α
    kmax = a < 0 ? _gp1_ymax(a) : ceil(Int, μ + 50 * sqrt(μ) * (1 + a * μ) + 100)
    u = rand(rng)
    c = 0.0
    @inbounds for k in 0:kmax
        c += exp(_glm_logpdf(f, μ, 1, k))
        c >= u && return k
    end
    return kmax
end

"""
    gp1_marginal_loglik_laplace(Y, Λ, β, α; link=LogLink(), kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a generalized-Poisson
type-1 (GP-1, Famoye) GLLVM with SIGNED dispersion `α` (`Var = μ(1+α μ)²`,
`μ = exp(η)`) — a thin wrapper over the family-generic `marginal_loglik_laplace`
with the `GeneralizedPoisson1(α)` marker. `Y` is the p×n integer count matrix; `Λ`
p×K; `β` length-p. As `α → 0` this tends to the Poisson marginal.
"""
gp1_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix, β::AbstractVector,
        α::Real; link::Link = LogLink(), kwargs...) =
    marginal_loglik_laplace(GeneralizedPoisson1(float(α)), Y, ones(Int, size(Y)), Λ, β, link; kwargs...)

# ---------------------------------------------------------------------------
# Fit driver (GP-1 family slice 2).
# ---------------------------------------------------------------------------

"""
    GP1Fit

Result of [`fit_gp1_gllvm`](@ref): intercepts `β` (length p), loadings `Λ` (p×K),
the estimated SIGNED dispersion `α` (Var = μ(1+α μ)²), the `link`, the maximised
Laplace `loglik`, the optimiser `converged` flag, and `iterations`.
"""
struct GP1Fit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    α::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::GP1Fit)
    p, K = size(f.Λ)
    print(io, "GP1Fit(p=", p, ", K=", K, ", α=", round(f.α; sigdigits = 4),
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_gp1_gllvm(Y; K, link=LogLink(), α_init=nothing, …) -> GP1Fit

Fit a generalized-Poisson type-1 (GP-1) GLLVM, jointly estimating the SIGNED dispersion
`α` (`Var = μ(1+α μ)²`) with the intercepts `β` and loadings `Λ`. `Y` is a p×n integer
count matrix (may contain `missing`); `K` the latent dimension.

Fitting strategy — **profile over α**. The family dispersion `α` and the latent-factor
variance are *substitutes* for overdispersion, and a single joint L-BFGS over `[β;Λ;α]`
collapses (it drives `Λ→0` and `α` to the bound — a much worse optimum) because a
finite-difference gradient through the Laplace inner solve cannot resolve that trade-off.
Instead we profile `α`: for each value on a warm-start-chained grid we fit `(β,Λ)` at
fixed `α` (a well-conditioned, Poisson-like problem), then Brent-refine `α` on the profile
and re-fit `(β,Λ)` at the optimum. The Laplace marginal is `gp1_marginal_loglik_laplace`;
warm start = empirical log-mean intercepts + an SVD (PPCA-style) loadings init. The inner
solves use finite-difference gradients; an analytic-gradient joint fit is a documented
follow-up (issue #104).

`α_bound` caps `|α|` (default 2.0 ⇒ extreme overdispersion `Var = μ(1+2μ)²`); raise it if a
fit saturates near the cap. `α_init`, if given, is added to the profile grid as a seed.

Missing data: pass a `mask` (p×n Bool, `false` = unobserved) or `missing` entries in `Y`;
masked cells are dropped from the marginal and the warm start.
"""
function fit_gp1_gllvm(Y::AbstractMatrix; K::Integer,
        link::Link = LogLink(), mask = nothing, offset = nothing,
        β_init = nothing, Λ_init = nothing, α_init = nothing,
        α_bound::Real = 2.0,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    rr = rr_theta_len(p, K)

    # NA handling: observation mask + sanitized counts (see fit_poisson_gllvm).
    msk = _resolve_obs_mask(mask, Y)
    Yc = Integer.(_sanitize_missing(Y, 0))

    Zemp = [linkfun(link, max(Yc[t, i] + 0.5, 1e-4)) for t in 1:p, i in 1:n]
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

    N1 = ones(Int, size(Yc))                           # unit trials, hoisted out of the closure
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    opts = Optim.Options(g_tol = g_tol, iterations = iterations)

    # Inner solve: optimize (β,Λ) at FIXED α, warm-started from (βs,Λs). The forbidden
    # region 1+αμ≤0 is caught by the marginal's own guard and surfaces here as 1e12.
    function fit_bL(α, βs, Λs)
        θ0 = vcat(βs, pack_lambda(Λs))
        function negll(θ)
            β = θ[1:p]
            Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
            v = try
                -marginal_loglik_laplace(GeneralizedPoisson1(α), Yc, N1, Λ, β, link;
                                         mask = msk, offset = offset,
                                         maxiter = newton_maxiter, tol = newton_tol)
            catch
                return 1e12
            end
            return isfinite(v) ? v : 1e12
        end
        res = Optim.optimize(negll, θ0, ls, opts; autodiff = :finite)
        θ̂ = Optim.minimizer(res)
        (β = θ̂[1:p], Λ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K),
         nll = Optim.minimum(res), converged = Optim.converged(res),
         iters = Optim.iterations(res))
    end

    # Profile grid over α (kept strictly inside ±α_bound), seeded with α_init if given.
    base = [-0.1, -0.05, 0.0, 0.05, 0.1, 0.2, 0.3, 0.5, 0.75, 1.0, 1.5]
    cap = 0.99 * α_bound
    grid = sort!(unique!(vcat(filter(a -> abs(a) < cap, base),
                              α_init === nothing ? Float64[] : [clamp(float(α_init), -cap, cap)])))

    βc, Λc = copy(β0), copy(Λ0)
    best = nothing
    for α in grid
        r = fit_bL(α, βc, Λc)
        r.nll < 1e11 && (βc, Λc = r.β, r.Λ)            # chain only from feasible fits
        if best === nothing || r.nll < best.nll
            best = (α = α, β = r.β, Λ = r.Λ, nll = r.nll,
                    converged = r.converged, iters = r.iters)
        end
    end

    # Brent-refine α on the profile in the bracket around the best grid point, then
    # re-fit (β,Λ) at the refined α from the best warm start. Never accept a worse point.
    fit_star = best
    i = findfirst(==(best.α), grid)
    lo = i == 1 ? grid[1] : grid[i - 1]
    hi = i == length(grid) ? grid[end] : grid[i + 1]
    if hi > lo
        rb = Optim.optimize(α -> fit_bL(α, best.β, best.Λ).nll, lo, hi, Optim.Brent();
                            abs_tol = 1e-3)
        rstar = fit_bL(Optim.minimizer(rb), best.β, best.Λ)
        rstar.nll < best.nll && (fit_star = (α = Optim.minimizer(rb), β = rstar.β,
            Λ = rstar.Λ, nll = rstar.nll, converged = rstar.converged, iters = rstar.iters))
    end

    return GP1Fit(fit_star.β, fit_star.Λ, fit_star.α, link, -fit_star.nll,
                  fit_star.converged, fit_star.iters)
end
