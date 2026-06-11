# Generalized Poisson (GP-1, Consul–Jain / Famoye mean-parameterised) family pieces
# for the generic Laplace core (src/families/laplace.jl). y_t ∈ {0,1,2,…}; mean
# μ = exp(η) (log link), dispersion α; the per-observation law handles BOTH
# over-dispersion (α > 0) and under-dispersion (α < 0) — the modelling advantage
# over NB2/NB1, which can only over-disperse. As α → 0 every piece reduces EXACTLY
# to the plain Poisson(μ).
#
# Mean-parameterised pmf (Famoye 1993, Comm. Stat. Theory Methods 22(5), 1335–1354;
# the "GP-1" of Zamani & Ismail 2012, Comm. Stat. Theory Methods 41(11), 2056–2073;
# Consul & Jain 1973, Technometrics 15, 791–799 for the original GP), with D = 1+αμ:
#
#   P(Y=y) = (μ/D)^y · (1+αy)^{y-1} / y! · exp(−μ(1+αy)/D),   y = 0,1,2,…
#
#   E[Y]   = μ,        Var(Y) = μ(1+αμ)² = μ D².
#
# Domain: D = 1+αμ > 0 and 1+αy > 0 for every observed y (the standard GP support
# constraints; Consul & Famoye 1992). α > 0 ⇒ Var > μ (over-dispersion); −1/μ <
# α < 0 ⇒ Var < μ (under-dispersion); α = 0 ⇒ Poisson. The dispersion is carried on
# an UNCONSTRAINED IDENTITY scale (NOT log: α may be negative), with the denominators
# guarded away from 0 by `_gp_D` so the score/weight/logpdf stay finite at the
# domain boundary. The `GenPoisson(α)` marker is a dedicated struct (GP has no
# Distributions marker, like NB1).
#
# Closed-form conditional log-density (μ-clamped upstream; D guarded):
#   ℓ = y·log μ − y·log D + (y−1)·log(1+αy) − logΓ(y+1) − μ(1+αy)/D.
#
# Score wrt η (log link, me = dμ/dη = μ). With D = 1+αμ:
#   ∂ℓ/∂μ = y/μ − yα/D − (1+αy)/D²  =  (y − μ)/(μ D²)   [algebraic identity, see derivation]
#   s = ∂ℓ/∂η = ∂ℓ/∂μ · me = (y − μ)/D².
# (Derivation: over the common denominator μD², the numerator is
#  yD² − yαμD − μ(1+αy); since D² − αμD = D(D−αμ) = D, this is yD − μ − αμy =
#  y(1+αμ) − μ − αμy = y − μ. So ∂ℓ/∂μ = (y−μ)/(μD²) = (y−μ)/Var(Y).)
#
# Weight wrt η = the EXPECTED (Fisher) information I(η) = E[s²] (a positive working
# weight, so Λ'WΛ + I stays SPD — the expected-information convention used by
# Poisson/NB/ZIP in this codebase). Since s = (y−μ)/D² and E[(y−μ)²] = Var = μD²:
#   W = E[s²] = Var/D⁴ = μD²/D⁴ = μ/D².
# At α → 0 (D → 1) s → (y−μ) and W → μ, the plain-Poisson pieces (test oracles).
#
# `_glm_logpdf`/`_glm_score`/`_glm_weight` are CLOSED FORM (via `loggamma`/`log`/`exp`,
# no Distributions object), so ForwardDiff Duals flow cleanly through both η (via μ)
# and the dispersion α — this keeps the GENERIC implicit dense-Laplace gradient path
# in laplace.jl AD-clean for GP (the NB1/ZIP pattern: a single scalar auxiliary via
# `marginal_loglik_laplace_implicit_value_grad`, no hand-coded kernel).

"""
    GenPoisson(α)

Generalized Poisson (GP-1, Famoye mean-parameterised) family marker: counts
`y ∈ {0,1,2,…}` with mean `μ = exp η` (log link) and variance `Var = μ(1+αμ)²`.
The dispersion `α` allows BOTH over-dispersion (`α > 0`) and under-dispersion
(`−1/μ < α < 0`); `α = 0` reduces EXACTLY to the `Poisson()` family. Used as the
family argument to the generic Laplace core. Only the dispersion `α` is stored.
"""
struct GenPoisson{T<:Real}
    α::T
end

default_link(::GenPoisson) = LogLink()

_clamp_mu(::GenPoisson, μ) = max(μ, 1e-12)

# Guarded D = 1 + αμ (kept ≥ 1e-10 so the over/under-dispersed denominators D²/D⁴
# stay finite at the domain boundary 1+αμ → 0; differentiable a.e., matching the
# `_clamp_mu`/`_clamp_eta` clamping convention used elsewhere).
@inline _gp_D(α, μ) = max(one(α) + α * μ, 1e-10)
# Guarded 1 + αy for the (y−1)·log(1+αy) and μ(1+αy)/D terms in the log-pmf.
@inline _gp_1pay(α, y) = max(one(α) + α * y, 1e-10)

# Score wrt η: s = (y − μ)/D², D = 1+αμ (log link, me = μ). α → 0 ⇒ (y − μ).
_glm_score(f::GenPoisson, μ, n, me, y) = (y - μ) / _gp_D(f.α, μ)^2

# Weight wrt η = Fisher info E[s²] = μ/D² ≥ 0. α → 0 ⇒ μ.
_glm_weight(f::GenPoisson, μ, n, me) = μ / _gp_D(f.α, μ)^2

# Closed-form GP-1 log pmf, AD-clean via `loggamma`:
#   ℓ = y·log μ − y·log D + (y−1)·log(1+αy) − logΓ(y+1) − μ(1+αy)/D.
# α → 0 (D → 1, 1+αy → 1) ⇒ y·log μ − μ − logΓ(y+1) = Poisson logpdf.
function _glm_logpdf(f::GenPoisson, μ, n, y)
    α = f.α
    D = _gp_D(α, μ)
    onepay = _gp_1pay(α, y)
    return y * log(μ) - y * log(D) + (y - one(y)) * log(onepay) -
           loggamma(y + one(y)) - μ * onepay / D
end

"""
    genpoisson_marginal_loglik_laplace(Y, Λ, β, α; link=LogLink(), kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a Generalized Poisson
(GP-1, Famoye mean-parameterised) GLLVM with dispersion `α` (`Var = μ(1+αμ)²`, log
link) — a thin wrapper over the family-generic `marginal_loglik_laplace` with the
`GenPoisson(α)` marker. `Y` is the p×n integer count matrix; `Λ` p×K; `β` length-p.
As `α → 0` this tends to the Poisson marginal. GP has no trial counts, so a unit `N`
is supplied internally.
"""
genpoisson_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix, β::AbstractVector,
        α::Real; link::Link = LogLink(), kwargs...) =
    marginal_loglik_laplace(GenPoisson(float(α)), Y, ones(Int, size(Y)), Λ, β, link; kwargs...)

# ---------------------------------------------------------------------------
# Fit driver.
# ---------------------------------------------------------------------------

"""
    GenPoissonFit

Result of [`fit_genpoisson_gllvm`](@ref): intercepts `β` (length p), loadings `Λ`
(p×K), the estimated dispersion `α` (`Var = μ(1+αμ)²`; `α > 0` over-, `α < 0`
under-dispersion), the `link`, the maximised Laplace `loglik`, the optimiser
`converged` flag, and `iterations`.
"""
struct GenPoissonFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    α::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::GenPoissonFit)
    p, K = size(f.Λ)
    print(io, "GenPoissonFit(p=", p, ", K=", K, ", α=", round(f.α; sigdigits = 4),
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_genpoisson_gllvm(Y; K, link=LogLink(), α_init=nothing, …) -> GenPoissonFit

Fit a Generalized Poisson (GP-1, `Var = μ(1+αμ)²`) GLLVM by L-BFGS over
`[β; vec(Λ); α]` on the Laplace marginal (`genpoisson_marginal_loglik_laplace`),
jointly estimating the dispersion `α`. `Y` is a p×n integer count matrix; `K` the
latent dimension. The dispersion `α` is estimated on an UNCONSTRAINED IDENTITY
scale (NOT log: `α` may be negative for under-dispersion). The L-BFGS gradient uses
the generic implicit dense-Laplace gradient
(`marginal_loglik_laplace_implicit_value_grad`): the per-site latent mode is found
once by Fisher scoring, then the gradient is taken with the implicit-function rule,
with per-observation `(η, α)` derivatives supplied by ForwardDiff through the
closed-form `_glm_logpdf`. Warm start = empirical log-mean intercepts + an SVD
loadings init + a mild over-dispersion `α₀`.
"""
function fit_genpoisson_gllvm(Y::AbstractMatrix{<:Integer}; K::Integer,
        link::Link = LogLink(),
        β_init = nothing, Λ_init = nothing, α_init = nothing,
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
    # mild over-dispersion warm start (raw α; identity scale, so negative α is reachable).
    α0 = α_init === nothing ? 0.1 : float(α_init)

    θ0 = vcat(β0, pack_lambda(Λ0), α0)
    family_fromθ = θ -> GenPoisson(θ[end])
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
    α̂ = θ̂[p + rr + 1]
    return GenPoissonFit(β̂, Λ̂, α̂, link, -Optim.minimum(res),
                         Optim.converged(res), Optim.iterations(res))
end
