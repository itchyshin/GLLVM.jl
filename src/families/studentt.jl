# Student-t (heavy-tailed continuous) family pieces for the generic Laplace core
# (src/families/laplace.jl). y_t ∈ ℝ; location η (IDENTITY link, so μ = η), scale
# σ > 0, with FIXED degrees of freedom ν: the per-observation law is the
# location–scale t, (y − η)/σ ~ t_ν. The scale σ is the dispersion (carried on a
# log scale as the single scalar auxiliary). The conditional density is
#
#   p(y | η) = Γ((ν+1)/2) / (Γ(ν/2) √(νπ) σ) · (1 + (y−η)²/(ν σ²))^{−(ν+1)/2},
#
# i.e. a Gaussian-tailed model robustified against outliers; as ν → ∞ it tends to
# Normal(η, σ²). For v1 ν is FIXED (a fitter kwarg, default ν = 4); estimating ν
# jointly is a follow-up (it would need a SECOND auxiliary, breaking the scalar-aux
# implicit path used here). The marker `StudentTFamily(ν, σ)` stores both.
#
# Score/weight wrt η (identity link ⇒ dμ/dη = me = 1). The robust t-score is
#   r = y − η,   s_η = (ν+1) r / (ν σ² + r²)
# (the score down-weights large residuals — the bounded-influence property of the
# t; Lange, Little & Taylor 1989 JASA). The expected (Fisher) information wrt η is
#   I_η = (ν+1) / ((ν+3) σ²)
# (a constant, the standard location-t information; Lange et al. 1989 eq. for the
# scaled-t score variance). Using the EXPECTED information as the Fisher-scoring
# weight keeps W ≥ 0 (the OBSERVED Hessian of a t is non-monotone and can go
# negative for |r| large, which would break the SPD Newton step), so the generic
# mode-finder in laplace.jl stays well-conditioned:
#   _glm_score  = s_η · me = (ν+1) r / (ν σ² + r²)        (me = 1)
#   _glm_weight = I_η · me² = (ν+1) / ((ν+3) σ²)          (me = 1, ⇒ W ≥ 0)
#
# `_glm_logpdf` is written in CLOSED FORM via `loggamma` so ForwardDiff Duals flow
# cleanly through both η (via the residual r = y − η) and log σ (via σ in the aux),
# which is what makes the generic scalar-aux implicit-gradient path AD-clean.

"""
    StudentTFamily(ν, σ)

Student-t (heavy-tailed continuous) family marker: location–scale t with FIXED
degrees of freedom `ν > 0` and scale `σ > 0`, identity link (location `μ = η`),
so `(y − η)/σ ~ t_ν`. Used as the family argument to the generic Laplace core.
`σ` is the dispersion (estimated on a log scale via the scalar-auxiliary implicit
path); `ν` is held fixed (a fitter kwarg). As `ν → ∞` it tends to `Normal(η, σ²)`.
"""
struct StudentTFamily{T<:Real}
    ν::T
    σ::T
end
StudentTFamily(ν::Real, σ::Real) = (νσ = promote(float(ν), float(σ)); StudentTFamily(νσ[1], νσ[2]))

default_link(::StudentTFamily) = IdentityLink()

# Location is unconstrained ⇒ no μ clamp (identity link, μ = η ∈ ℝ).
_clamp_mu(::StudentTFamily, μ) = μ

# Robust t-score wrt η: (ν+1)(y−μ)/(ν σ² + (y−μ)²), times me (= 1 for identity).
function _glm_score(f::StudentTFamily, μ, n, me, y)
    r = y - μ
    return (f.ν + one(f.ν)) * r / (f.ν * f.σ^2 + r^2) * me
end

# Expected (Fisher) information wrt η: (ν+1)/((ν+3) σ²), times me² (= 1). W ≥ 0.
_glm_weight(f::StudentTFamily, μ, n, me) =
    (f.ν + one(f.ν)) / ((f.ν + 3 * one(f.ν)) * f.σ^2) * me^2

# Closed-form location–scale t log-density:
#   ℓ = logΓ((ν+1)/2) − logΓ(ν/2) − ½log(νπ) − log σ − (ν+1)/2 · log(1 + r²/(ν σ²)).
function _glm_logpdf(f::StudentTFamily, μ, n, y)
    ν = f.ν
    σ = f.σ
    r = y - μ
    half = (ν + one(ν)) / 2
    return loggamma(half) - loggamma(ν / 2) -
           0.5 * log(ν * convert(typeof(half), π)) - log(σ) -
           half * log1p(r^2 / (ν * σ^2))
end

"""
    studentt_marginal_loglik_laplace(Y, Λ, β, σ; ν=4.0, link=IdentityLink(), kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a Student-t GLLVM with
FIXED degrees of freedom `ν` and scale `σ` (`(y − η)/σ ~ t_ν`, identity link) — a
thin wrapper over the family-generic `marginal_loglik_laplace` with the
`StudentTFamily(ν, σ)` marker. `Y` is the p×n response matrix; `Λ` p×K; `β`
length-p. As `ν → ∞` this tends to the Gaussian marginal.
"""
studentt_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix, β::AbstractVector,
        σ::Real; ν::Real = 4.0, link::Link = IdentityLink(), kwargs...) =
    marginal_loglik_laplace(StudentTFamily(ν, σ), Y, ones(Int, size(Y)), Λ, β, link; kwargs...)

# ---------------------------------------------------------------------------
# Fit driver.
# ---------------------------------------------------------------------------

"""
    StudentTFit

Result of [`fit_studentt_gllvm`](@ref): intercepts `β` (length p), loadings `Λ`
(p×K), the FIXED degrees of freedom `ν`, the estimated scale `σ`
(`(y − η)/σ ~ t_ν`), the `link` (always `IdentityLink()`), the maximised Laplace
`loglik`, the optimiser `converged` flag, and `iterations`.
"""
struct StudentTFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    ν::Float64
    σ::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::StudentTFit)
    p, K = size(f.Λ)
    print(io, "StudentTFit(p=", p, ", K=", K, ", ν=", round(f.ν; sigdigits = 4),
          " (fixed), σ=", round(f.σ; sigdigits = 4),
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_studentt_gllvm(Y; K, nu=4.0, link=IdentityLink(), σ_init=nothing, …) -> StudentTFit

Fit a Student-t GLLVM by L-BFGS over `[β; vec(Λ); log σ]` on the Laplace marginal
(`studentt_marginal_loglik_laplace`), jointly estimating the scale `σ` while
holding the degrees of freedom `nu` FIXED (default `nu = 4.0`). `Y` is a p×n
response matrix; `K` the latent dimension. The L-BFGS gradient uses the generic
scalar-auxiliary implicit dense-Laplace gradient
(`marginal_loglik_laplace_aux_value_grad`): the per-site latent mode is found once
by Fisher scoring, then each observation is differentiated only with respect to
`(η, log σ)` via ForwardDiff through the closed-form `_glm_logpdf`, and the packed
implicit-gradient chain rule is applied. Warm start = empirical column-mean
intercepts + an SVD loadings init + a robust scale `σ₀` from the residual MAD.

Estimating `nu` jointly is a follow-up (it requires a second auxiliary, which the
scalar-aux path does not support); pass `nu` to change the fixed tail weight.
"""
function fit_studentt_gllvm(Y::AbstractMatrix{<:Union{Missing, Real}}; K::Integer,
        nu::Real = 4.0, link::Link = IdentityLink(),
        β_init = nothing, Λ_init = nothing, σ_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    nu > 0 || throw(ArgumentError("Student-t degrees of freedom nu must be > 0; got $nu"))
    rr = rr_theta_len(p, K)

    # NA-aware warm start (identity link): per-trait observed-cell mean intercepts;
    # missing cells mean-filled for the SVD init ONLY (FIML estimator, issue #27).
    Zemp = Matrix{Float64}(undef, p, n)
    β0r = Vector{Float64}(undef, p)
    @inbounds for t in 1:p
        acc = 0.0; cnt = 0
        for i in 1:n
            if !ismissing(Y[t, i])
                v = float(Y[t, i]); Zemp[t, i] = v; acc += v; cnt += 1
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
    # Robust σ₀ from the residual MAD (1.4826·MAD ≈ Gaussian SD; for a t the scale
    # σ < SD, but MAD is a stable, outlier-resistant starting point).
    σ0 = if σ_init === nothing
        R = Zemp .- β0
        s = 1.4826 * median(abs.(R .- median(R)))
        max(s, 1e-3)
    else
        float(σ_init)
    end
    logσ0 = log(σ0)
    ν0 = float(nu)

    θ0 = vcat(β0, pack_lambda(Λ0), logσ0)
    family_from_aux = aux -> StudentTFamily(ν0, _positive_from_log(aux[1]))
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
    σ̂ = _positive_from_log(θ̂[p + rr + 1])
    return StudentTFit(β̂, Λ̂, ν0, σ̂, link, -Optim.minimum(res),
                       Optim.converged(res), Optim.iterations(res))
end
