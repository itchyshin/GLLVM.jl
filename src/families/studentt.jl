# Student-t (heavy-tailed continuous) family pieces for the generic Laplace core
# (src/families/laplace.jl). y_t ∈ ℝ; location η (IDENTITY link, so μ = η), scale
# σ > 0 and degrees of freedom ν > 1: the per-observation law is the
# location–scale t, (y − η)/σ ~ t_ν. A numeric `nu` fixes ν; `nu = nothing`
# estimates it. The scale σ is always estimated on a log scale, and
# `disp_group = :species` estimates one scale and (when ν is free) one ν per
# trait. This implementation lives in this file, not `grouped_dispersion.jl`.
# The conditional density is
#
#   p(y | η) = Γ((ν+1)/2) / (Γ(ν/2) √(νπ) σ) · (1 + (y−η)²/(ν σ²))^{−(ν+1)/2},
#
# i.e. a Gaussian-tailed model robustified against outliers; as ν → ∞ it tends to
# Normal(η, σ²). The marker `StudentTFamily(ν, σ)` carries a fixed numerical ν
# for an individual likelihood evaluation; the fitter supplies the estimated
# value when `nu = nothing`.
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
# `_glm_logpdf` uses a stable normalizer so ForwardDiff Duals flow
# cleanly through both η (via the residual r = y − η) and log σ (via σ in the aux),
# which is what makes the generic scalar-aux implicit-gradient path AD-clean.

"""
    StudentTFamily(ν = nothing, σ = 1.0)

Student-t (heavy-tailed continuous) family marker: location–scale t with
degrees of freedom `ν > 0` (or `nothing` before fitting) and scale `σ > 0`,
identity link (location `μ = η`),
so `(y − η)/σ ~ t_ν`. Used as the family argument to the generic Laplace core and
to [`fit_gllvm`](@ref):

```julia
fit_gllvm(Y; family = StudentTFamily(), K = 2)      # estimate ν (default)
fit_gllvm(Y; family = StudentTFamily(7.0), K = 2)   # fix a lighter tail
```

The two fields play **different** roles on the public route. `ν` is structural: it
defines the likelihood and a numeric value fixes it, while `ν = nothing` asks the
fitter to estimate it. `σ` is a **tag payload** —
the scale is always estimated, so `StudentTFamily(4.0, 1.0)` and
`StudentTFamily(4.0, 9.0)` give the same fit; pass `σ_init` to
[`fit_studentt_gllvm`](@ref) to seed it. Internally the Laplace kernels construct
their own per-iteration `StudentTFamily(ν, σ)` markers, which is what the `σ`
field is for. As `ν → ∞` the family tends to `Normal(η, σ²)`.
"""
struct StudentTFamily{N<:Union{Real,Nothing}, T<:Real}
    ν::N
    σ::T
end
StudentTFamily(ν::Real, σ::Real) = (νσ = promote(float(ν), float(σ)); StudentTFamily{typeof(νσ[1]), typeof(νσ[2])}(νσ[1], νσ[2]))
StudentTFamily(ν::Nothing, σ::Real) = StudentTFamily{Nothing, typeof(float(σ))}(nothing, float(σ))
StudentTFamily(ν::Real) = StudentTFamily(float(ν), 1.0)
StudentTFamily(::Nothing) = StudentTFamily(nothing, 1.0)
StudentTFamily() = StudentTFamily(nothing, 1.0)

const StudentT = StudentTFamily

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
# Limit the fixed-order series to Float64, including nested ForwardDiff Duals.
# BigFloat and BigFloat-backed Duals retain their caller-selected precision.
@inline _studentt_float64_backed(::Any) = false
@inline _studentt_float64_backed(::Float64) = true
@inline _studentt_float64_backed(x::ForwardDiff.Dual) = _studentt_float64_backed(ForwardDiff.value(x))

function _studentt_log_normalizer(ν)
    if _studentt_float64_backed(ν) && ν >= 64
        # DLMF 5.11.8, subtracting h=1/2 and h=0 at z=ν/2.
        # First omitted term is 691/(88ν^11), about 1.1e-19 at ν=64.
        # Direct differentiation of this expression avoids digamma cancellation.
        u = inv(ν)
        u2 = u*u
        o = one(ν)
        correction = u * (-o/4 + u2*(o/24 + u2*(-o/20 + u2*(17o/112 - u2*31o/36))))
        return -log(2*oftype(ν, π))/2 + correction
    end
    half = (ν + one(ν))/2
    return loggamma(half) - loggamma(ν/2) - log(ν*oftype(half, π))/2
end

function _glm_logpdf(f::StudentTFamily, μ, n, y)
    ν = f.ν
    σ = f.σ
    r = y - μ
    half = (ν + one(ν)) / 2
    return _studentt_log_normalizer(ν) - log(σ) -
           half * log1p(r^2 / (ν * σ^2))
end

"""
    studentt_marginal_loglik_laplace(Y, Λ, β, σ; ν=4.0, link=IdentityLink(), kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a Student-t GLLVM with
degrees of freedom `ν` and scale `σ` (`(y − η)/σ ~ t_ν`, identity link) — a
thin wrapper over the family-generic `marginal_loglik_laplace` or grouped site
evaluator. `Y` is the p×n response matrix; `Λ` p×K; `β` length-p. `σ` and `ν`
may each be a scalar `Real` or a length-p `AbstractVector`. As `ν → ∞` this tends
to the Gaussian marginal.
"""
studentt_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix, β::AbstractVector,
        σ::Real; ν::Real = 4.0, link::Link = IdentityLink(), kwargs...) =
    marginal_loglik_laplace(StudentTFamily(ν, σ), Y, ones(Int, size(Y)), Λ, β, link; kwargs...)

function studentt_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix, β::AbstractVector,
        σ::Union{Real, AbstractVector}; ν::Union{Real, AbstractVector} = 4.0, link::Link = IdentityLink(),
        mask = nothing, offset = nothing, kwargs...)
    p = size(Λ, 1)
    if σ isa AbstractVector
        length(σ) == p || throw(ArgumentError("length(σ)=$(length(σ)) must equal p=$p"))
    end
    if ν isa AbstractVector
        length(ν) == p || throw(ArgumentError("length(ν)=$(length(ν)) must equal p=$p"))
    end
    fams = if σ isa AbstractVector && ν isa AbstractVector
        [StudentTFamily(ν[t], σ[t]) for t in 1:p]
    elseif σ isa AbstractVector
        [StudentTFamily(ν, σ[t]) for t in 1:p]
    elseif ν isa AbstractVector
        [StudentTFamily(ν[t], σ) for t in 1:p]
    else
        [StudentTFamily(ν, σ) for t in 1:p]
    end
    N = ones(Int, size(Y))
    acc = 0.0
    @inbounds for i in axes(Y, 2)
        mi = mask   === nothing ? nothing : view(mask, :, i)
        oi = offset === nothing ? nothing : view(offset, :, i)
        acc += _studentt_grouped_loglik_site(fams, view(Y, :, i), view(N, :, i), Λ, β, link;
                                             mask = mi, offset = oi, kwargs...)
    end
    return acc
end

# ---------------------------------------------------------------------------
# Per-trait dispersion substrate (2026-08-28, gllvmTMB.cpp:1184 `log_sigma_student`,
# length n_traits — measured baseline Δ logLik = +1.070 at df fixed = ν on both
# sides, docs/dev-log/decisions/2026-08-28-studentt-parameterisation.md). Mirrors
# the established `grouped_dispersion.jl` pattern (Gamma/Beta/NB2/NB1): the
# family-generic single-marker core in `families/laplace.jl` broadcasts ONE
# family via `Ref(family)`, so per-species dispersion needs its own site kernel
# that broadcasts a length-p VECTOR of `StudentTFamily` markers instead — reusing
# the exact same `_glm_score`/`_glm_weight`/`_glm_logpdf`/`_clamp_mu`/
# `_glm_obs_weight` pieces already defined above. The shared-σ path
# (`studentt_marginal_loglik_laplace(..., σ::Real; ...)` above) is left
# byte-for-byte untouched, which is what keeps `disp_group = :shared` (the
# default) bit-identical to the pre-existing fitter.
function _studentt_grouped_laplace_weight(hessian::Symbol, f::StudentTFamily, μ, me, y, link::Link, η)
    hessian === :fisher && return _glm_weight(f, μ, 1, me)
    hessian === :observed || throw(ArgumentError(
        "hessian must be :fisher or :observed; got :$hessian"))
    link isa IdentityLink || throw(ArgumentError(
        "hessian=:observed is currently supported only for Student-t with IdentityLink()"))
    return _glm_obs_weight(f, μ, 1, me, y, link, η)
end

# Per-site Laplace log-marginal with per-species Student-t markers `fams` (each
# entry shares ν, differs only in σ). PD guard mirrors the generic single-family
# core (`families/laplace.jl`'s `laplace_loglik_site`): the observed Student-t
# curvature is genuinely negative for |r| > σ√ν (documented above at
# `_glm_obs_weight`), so `A` is not SPD by construction here the way it is for
# Gamma/log — the guard is load-bearing, not defensive.
function _studentt_grouped_loglik_site(fams::AbstractVector{<:StudentTFamily}, y::AbstractVector, n::AbstractVector,
        Λ::AbstractMatrix, β::AbstractVector, link::Link;
        mask = nothing, offset = nothing, hessian::Symbol = :observed,
        maxiter::Integer = 100, tol::Real = 1e-9)
    p, K = size(Λ)
    off = offset === nothing ? false : offset
    z = zeros(K)
    local A
    for _ in 1:maxiter
        η  = _clamp_eta.(β .+ off .+ Λ * z)
        μ  = _clamp_mu.(fams, linkinv.(Ref(link), η))
        me = mu_eta.(Ref(link), η)
        s  = _glm_score.(fams, μ, n, me, y)
        # Mode search is ALWAYS Fisher-scored (role separation, 2026-08-25
        # convention shared with Gamma/Beta/NB2 grouped kernels): expected
        # information is >= 0, so `Λ'WΛ + I` is SPD by construction and every
        # Newton step is a descent step, independent of the caller's `hessian`.
        W  = _glm_weight.(fams, μ, n, me)
        if mask !== nothing
            s = ifelse.(mask, s, 0.0)
            W = ifelse.(mask, W, 0.0)
        end
        A  = Symmetric(Λ' * (W .* Λ) + I)
        Δ  = _safe_solve(A, Λ' * s .- z)
        (Δ === nothing || !all(isfinite, Δ)) && break
        z  = z .+ Δ
        maximum(abs, Δ) < tol && break
    end
    η  = _clamp_eta.(β .+ off .+ Λ * z)
    μ  = _clamp_mu.(fams, linkinv.(Ref(link), η))
    me = mu_eta.(Ref(link), η)
    W  = _studentt_grouped_laplace_weight.(Ref(hessian), fams, μ, me, y, Ref(link), η)
    if mask !== nothing
        W = ifelse.(mask, W, 0.0)
    end
    A  = Symmetric(Λ' * (W .* Λ) + I)
    ℓ = 0.0
    @inbounds for t in 1:p
        (mask === nothing || mask[t]) || continue
        ℓ += _glm_logpdf(fams[t], μ[t], n[t], y[t])
    end
    if any(w -> w < zero(w), W)
        F = cholesky(A; check = false)
        issuccess(F) || return oftype(ℓ, -Inf)
    end
    return ℓ - 0.5 * dot(z, z) - 0.5 * logdet(A)
end

# ---------------------------------------------------------------------------
# Fit driver.
# ---------------------------------------------------------------------------

"""
    StudentTFit

Result of [`fit_studentt_gllvm`](@ref): intercepts `β` (length p), loadings `Λ`
(p×K), degrees of freedom `ν` (`Float64` or length-p `Vector{Float64}`), whether
`ν` was estimated (`estimated_nu`), and estimated scale `σ`
(`(y − η)/σ ~ t_ν`; a `Float64` under `disp_group == :shared`, or a length-p `Vector{Float64}`
under `disp_group == :species`), the `link` (always `IdentityLink()`), the
maximised Laplace `loglik`, the optimiser `converged` flag, `iterations`, the
`hessian` curvature selector, and `disp_group` (`:shared` default or
`:species`).
"""
struct StudentTFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    ν::Union{Float64, Vector{Float64}}
    σ::Union{Float64, Vector{Float64}}
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
    hessian::Symbol   # the Laplace log-det curvature this fit's objective used
    disp_group::Symbol
    estimated_nu::Bool
end

# Positional compatibility constructors (2026-08-28): every pre-existing
# construction site builds a default-curvature, shared-dispersion fit; the
# `hessian` field records the objective identity so `confint`/bootstrap can
# rebuild THE SAME objective instead of guessing (the audit's
# confint-consistency class); `disp_group` mirrors the delta fitters'
# precedent (`DeltaLogNormalFit`).
StudentTFit(β, Λ, ν, σ, link, loglik, converged, iterations) =
    StudentTFit(β, Λ, ν, σ, link, loglik, converged, iterations,
               _default_hessian(StudentTFamily(4.0, 1.0), link), :shared, false)
StudentTFit(β, Λ, ν, σ, link, loglik, converged, iterations, hessian::Symbol) =
    StudentTFit(β, Λ, ν, σ, link, loglik, converged, iterations, hessian, :shared, false)
StudentTFit(β, Λ, ν, σ, link, loglik, converged, iterations, hessian::Symbol,
            disp_group::Symbol) =
    StudentTFit(β, Λ, ν, σ, link, loglik, converged, iterations, hessian,
                disp_group, false)

function Base.show(io::IO, f::StudentTFit)
    p, K = size(f.Λ)
    σstr = f.σ isa Real ? string(round(f.σ; sigdigits = 4)) : "per-trait"
    νstr = f.ν isa Real ? string(round(f.ν; sigdigits = 4)) : "per-trait"
    print(io, "StudentTFit(p=", p, ", K=", K, ", ν=", νstr,
          f.estimated_nu ? " (estimated)" : " (fixed)",
          ", σ=", σstr,
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

# Student-t/identity Laplace log-det defaults to the OBSERVED conditional
# curvature (decision A, 2026-08-27 — campaign: estimator preference 100% in
# every regime; reported-loglik cost accepted). With r = y − μ (identity link,
# me = 1): −∂²ℓ/∂η² = (ν+1)(νσ² − r²)/(νσ² + r²)². GENUINELY NEGATIVE for
# |r| > σ√ν — the assembly-level PD guard in `marginal_loglik_laplace` handles
# that (measured, load-bearing; never clamp here). No analytic-gradient
# coupling: this fitter is finite-difference only.
function _glm_obs_weight(f::StudentTFamily, μ, n, me, y, link::IdentityLink, η)
    r = y - μ
    νσ² = f.ν * f.σ^2
    return (f.ν + 1) * (νσ² - r^2) / (νσ² + r^2)^2
end
_default_hessian(::StudentTFamily, ::IdentityLink) = :observed

"""
    fit_studentt_gllvm(Y; K, nu=nothing, link=IdentityLink(), σ_init=nothing, nu_init=nothing, …) -> StudentTFit

Fit a Student-t GLLVM by L-BFGS over `[β; vec(Λ); log σ; log(ν-1)]` on the Laplace
marginal (`studentt_marginal_loglik_laplace`). When `nu === nothing` (default),
the degrees of freedom `ν` are estimated jointly per-trait (`ν_j = 1 + exp(θ_{ν,j}) > 1`),
matching `gllvmTMB`. When `nu` is passed as a number (e.g. `nu = 4.0`), `nu` is held FIXED.
`Y` is a p×n response matrix; `K` the latent dimension.

Initial values: `σ₀ = 1.0`, `ν₀ = 3.0` (`log(ν₀ - 1) = log(2.0)`), matching gllvmTMB.
`hessian` selects the Laplace log-det curvature (`:observed` default / `:fisher`).
`disp_group` selects `:species` (per-trait dispersion) or `:shared`.
"""
function fit_studentt_gllvm(Y::AbstractMatrix{<:Real}; K::Integer,
        nu::Union{Nothing, Real, AbstractVector{<:Real}} = nothing,
        link::Link = IdentityLink(),
        hessian::Symbol = _default_hessian(StudentTFamily(4.0, 1.0), link),
        disp_group::Symbol = :shared,
        β_init = nothing, Λ_init = nothing, σ_init = nothing, nu_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    if nu !== nothing
        if nu isa Real
            nu > 0 || throw(ArgumentError("Student-t degrees of freedom nu must be > 0; got $nu"))
        else
            length(nu) == p || throw(ArgumentError("length(nu)=$(length(nu)) must equal p=$p"))
            all(>(0), nu) || throw(ArgumentError("All Student-t degrees of freedom nu must be > 0"))
        end
    end
    hessian in (:fisher, :observed) || throw(ArgumentError(
        "fit_studentt_gllvm: hessian must be :fisher or :observed; got :$hessian"))
    disp_group in (:shared, :species) || throw(ArgumentError(
        "fit_studentt_gllvm: disp_group must be :shared or :species; got :$disp_group"))
    rr = rr_theta_len(p, K)

    Zemp = float.(Y)                                   # identity link ⇒ Z = Y
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
    # Initial values: σ_0 = 1.0, ν_0 = 3.0 (matching gllvmTMB).
    σ0 = σ_init === nothing ? 1.0 : float(σ_init)
    σ0vec = σ_init === nothing ? fill(1.0, p) : (σ_init isa AbstractVector ? float.(σ_init) : fill(float(σ_init), p))
    ndisp = disp_group === :shared ? 1 : p
    logσ0 = disp_group === :shared ? [log(σ0)] : log.(σ0vec)

    log_nu_minus_1_0 = if nu === nothing
        if nu_init === nothing
            fill(log(2.0), ndisp)
        else
            if disp_group === :shared
                [log(float(nu_init) - 1.0)]
            else
                nu_init isa AbstractVector ? log.(float.(nu_init) .- 1.0) : fill(log(float(nu_init) - 1.0), p)
            end
        end
    else
        Float64[]
    end
    ν_fixed = nu === nothing ? nothing : (nu isa Real ? float(nu) : float.(nu))

    θ0 = if nu === nothing
        vcat(β0, pack_lambda(Λ0), logσ0, log_nu_minus_1_0)
    else
        vcat(β0, pack_lambda(Λ0), logσ0)
    end

    function negll(θ)
        β = θ[1:p]
        Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        σ = disp_group === :shared ? exp(θ[p + rr + 1]) : exp.(θ[(p + rr + 1):(p + rr + ndisp)])
        ν = if nu === nothing
            disp_group === :shared ? (1.0 + exp(θ[p + rr + ndisp + 1])) : (1.0 .+ exp.(θ[(p + rr + ndisp + 1):(p + rr + 2 * ndisp)]))
        else
            ν_fixed
        end
        v = try
            -studentt_marginal_loglik_laplace(Y, Λ, β, σ; ν = ν, link = link,
                                              hessian = hessian,
                                              maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    opts = Optim.Options(g_tol = g_tol, iterations = iterations)
    res = Optim.optimize(negll, θ0, ls, opts; autodiff = :finite)
    θ̂ = Optim.minimizer(res)
    β̂ = θ̂[1:p]
    Λ̂ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    σ̂ = disp_group === :shared ? exp(θ̂[p + rr + 1]) : exp.(θ̂[(p + rr + 1):(p + rr + ndisp)])
    ν̂ = if nu === nothing
        disp_group === :shared ? (1.0 + exp(θ̂[p + rr + ndisp + 1])) : (1.0 .+ exp.(θ̂[(p + rr + ndisp + 1):(p + rr + 2 * ndisp)]))
    else
        ν_fixed
    end
    return StudentTFit(β̂, Λ̂, ν̂, σ̂, link, _fit_verdict(res)..., hessian,
                       disp_group, nu === nothing)
end
