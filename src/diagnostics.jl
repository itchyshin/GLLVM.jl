# Fit diagnostics: randomized-quantile (Dunn–Smyth / DHARMa-style) residuals and
# a `check_fit` summary.
#
# Randomized quantile residuals (Dunn & Smyth 1996) standardise a fit to N(0,1)
# under correct specification, independently of the response family. For each
# observation we compute the probability integral transform (PIT) of y under the
# fitted family at the CONDITIONAL fit (latent modes from `getLV`):
#   * continuous families (Gaussian, Gamma, Beta): the exact PIT u = F(y);
#   * discrete families (Poisson, Binomial, NB, Ordinal): u ~ Uniform[F(y-1), F(y)]
#     (jittered, so a correct discrete model still yields uniform PITs);
# then map through the standard-normal quantile, r = Φ⁻¹(u). A well-specified fit
# gives r ≈ N(0,1) and u ≈ Uniform(0,1). The per-cell CDF parameterisations here
# mirror the per-family `residuals(...; type=:dunnsmyth)` methods in postfit.jl
# (single source of truth for each family's distribution/link); this file exposes
# the intermediate PIT `u` (needed for the discrete-randomisation and uniformity
# checks) and a uniform `quantile_residuals` front-end across all fit types.
#
# ADDITIVE: this file defines new functions only. It reuses getLV / predict
# (postfit.jl, mixed.jl) and the family CDFs from Distributions; it does not edit
# any src/families/*.jl fitter.

# ---------------------------------------------------------------------------
# Probability integral transform (PIT) per fit type. Returns a p×n matrix of
# u ∈ (0,1): exact F(y) for continuous families, randomised on [F(y-1), F(y)]
# for discrete families (pass a fixed `rng` to reproduce).
# ---------------------------------------------------------------------------

# Randomised discrete PIT for one cell from a Distributions discrete `d` and
# observed integer `y`: a draw from Uniform[F(y-1), F(y)].
@inline function _pit_discrete(d, y::Real, rng::AbstractRNG)
    Flo = cdf(d, y - 1)
    Fhi = cdf(d, y)
    return Flo + (Fhi - Flo) * rand(rng)
end

"""
    _pit(fit, Y; kwargs...) -> p×n matrix of PIT values u ∈ (0,1)

Probability integral transform of each observation under the fitted family at
the conditional fit (latent modes from [`getLV`](@ref)). Continuous families
return the exact `F(y)`; discrete families return a value drawn uniformly on
`[F(y-1), F(y)]` (randomised quantile, `rng`-controlled). Internal building block
for [`quantile_residuals`](@ref) and the uniformity check in [`check_fit`](@ref).
"""
function _pit end

# Gaussian: continuous, exact PIT under N(μ̂, σ_eps²) — equals Φ((y−μ̂)/σ_eps), so
# the resulting residual reduces to the standardized residual.
function _pit(fit::GllvmFit, y::AbstractMatrix;
              X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing, kwargs...)
    μ = predict(fit, y; type = :response, X = X)
    σ = fit.pars.σ_eps
    return cdf.(Normal(), (y .- μ) ./ σ)
end

# Poisson: discrete count, randomised PIT under Poisson(μ̂).
function _pit(fit::PoissonFit, Y::AbstractMatrix{<:Integer};
              rng::AbstractRNG = Random.default_rng(), kwargs...)
    p, n = size(Y)
    μ = predict(fit, Y; type = :response)
    U = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        U[t, s] = _pit_discrete(Poisson(μ[t, s]), Y[t, s], rng)
    end
    return U
end

# Binomial: discrete, randomised PIT under Binomial(N, μ̂).
function _pit(fit::BinomialFit, Y::AbstractMatrix{<:Integer};
              N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing,
              rng::AbstractRNG = Random.default_rng(), kwargs...)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    μ = predict(fit, Y; type = :response, N = N)
    U = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        U[t, s] = _pit_discrete(Binomial(Int(Nm[t, s]), μ[t, s]), Y[t, s], rng)
    end
    return U
end

# Negative binomial: discrete, randomised PIT under NB2 (r, r/(r+μ̂)).
function _pit(fit::NBFit, Y::AbstractMatrix{<:Integer};
              rng::AbstractRNG = Random.default_rng(), kwargs...)
    p, n = size(Y)
    r = fit.r
    μ = predict(fit, Y; type = :response)
    U = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        U[t, s] = _pit_discrete(NegativeBinomial(r, r / (r + μ[t, s])), Y[t, s], rng)
    end
    return U
end

# Beta: continuous proportion, exact PIT under Beta(μ̂φ, (1−μ̂)φ).
function _pit(fit::BetaFit, Y::AbstractMatrix{<:Real}; kwargs...)
    p, n = size(Y)
    φ = fit.φ
    μ = predict(fit, Y; type = :response)
    U = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        U[t, s] = cdf(Beta(μ[t, s] * φ, (1 - μ[t, s]) * φ),
                      clamp(float(Y[t, s]), 1e-12, 1 - 1e-12))
    end
    return U
end

# Gamma: continuous positive, exact PIT under Gamma(α, μ̂/α).
function _pit(fit::GammaFit, Y::AbstractMatrix{<:Real}; kwargs...)
    p, n = size(Y)
    α = fit.α
    μ = predict(fit, Y; type = :response)
    U = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        U[t, s] = cdf(Gamma(α, μ[t, s] / α), max(float(Y[t, s]), 1e-300))
    end
    return U
end

# Ordinal: discrete ordered categories, randomised PIT under the fitted
# cumulative-logit at the Laplace mode (η = Λẑ). Mirrors residuals(::OrdinalFit).
function _pit(fit::OrdinalFit, Y::AbstractMatrix{<:Integer};
              rng::AbstractRNG = Random.default_rng(), kwargs...)
    p, n = size(Y); C = fit.C
    Z = getLV(fit, Y; rotate = false)
    η = fit.Λ * Z'
    U = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        c = Int(Y[t, s])
        Fhi = c >= C ? 1.0 : _ord_F(fit.τ[c] - η[t, s])
        Flo = c <= 1 ? 0.0 : _ord_F(fit.τ[c - 1] - η[t, s])
        U[t, s] = Flo + (Fhi - Flo) * rand(rng)
    end
    return U
end

# Mixed family: per-trait dispatch on families[t]/links[t]. Discrete traits are
# randomised; continuous traits use the exact PIT. One shared latent mode ẑ.
function _pit(fit::MixedFamilyFit, Y::AbstractMatrix;
              N::Union{Nothing, AbstractMatrix} = nothing,
              rng::AbstractRNG = Random.default_rng(), kwargs...)
    p, n = size(Y)
    Nm = N === nothing ? ones(Int, p, n) : N
    μ = predict(fit, Y; type = :response, N = N)
    U = Matrix{Float64}(undef, p, n)
    @inbounds for t in 1:p
        fam = fit.families[t]
        d = isfinite(fit.dispersion[t]) ? fit.dispersion[t] : NaN
        for s in 1:n
            U[t, s] = _pit_cell(fam, μ[t, s], Y[t, s], Int(Nm[t, s]), d, rng)
        end
    end
    return U
end

# Per-cell PIT for a mixed trait, dispatched on its family marker. Discrete
# families jitter; continuous families use the exact CDF. The dispersion `d` is
# the fit's scalar nuisance for that trait (NB r / Gamma α / Beta φ / Normal σ).
_pit_cell(::Poisson, μ, y, n, d, rng::AbstractRNG) =
    _pit_discrete(Poisson(μ), y, rng)
_pit_cell(::Binomial, μ, y, n, d, rng::AbstractRNG) =
    _pit_discrete(Binomial(n, μ), y, rng)
_pit_cell(::NegativeBinomial, μ, y, n, d, rng::AbstractRNG) =
    _pit_discrete(NegativeBinomial(d, d / (d + μ)), y, rng)
_pit_cell(::Normal, μ, y, n, d, rng::AbstractRNG) =
    cdf(Normal(μ, d), float(y))
_pit_cell(::Gamma, μ, y, n, d, rng::AbstractRNG) =
    cdf(Gamma(d, μ / d), max(float(y), 1e-300))
_pit_cell(::Beta, μ, y, n, d, rng::AbstractRNG) =
    cdf(Beta(μ * d, (1 - μ) * d), clamp(float(y), 1e-12, 1 - 1e-12))

# ---------------------------------------------------------------------------
# Randomized quantile residuals: r = Φ⁻¹(u), u the PIT above.
# ---------------------------------------------------------------------------

# Clamp PITs off the open-interval boundary so Φ⁻¹ stays finite, then transform.
_normal_quantile_of_pit(U::AbstractMatrix) =
    quantile.(Normal(), clamp.(U, 1e-12, 1 - 1e-12))

"""
    quantile_residuals(fit, Y; rng=Random.default_rng(), kwargs...) -> p×n matrix

Randomized-quantile (Dunn–Smyth / DHARMa-style) residuals for a fitted GLLVM.
For each observation the probability integral transform `u` of `y` is computed
under the fitted family at the conditional fit (latent modes from
[`getLV`](@ref)) — the exact CDF `F(y)` for continuous families (Gaussian, Gamma,
Beta) and a value drawn uniformly on `[F(y-1), F(y)]` for discrete families
(Poisson, Binomial, NegativeBinomial, Ordinal, and per-trait in a mixed fit) —
then mapped through the standard-normal quantile, `r = Φ⁻¹(u)`. Under correct
specification `r ≈ N(0,1)`.

Pass a fixed `rng` for reproducible randomisation of the discrete families. Extra
keyword arguments are forwarded to the fit's [`getLV`](@ref)/[`predict`](@ref):
`N` (trial/exposure counts) for Binomial and mixed fits, `X` (fixed-effect
design) for the Gaussian fit.

Dispatches across all fit types: `GllvmFit`, `PoissonFit`, `BinomialFit`,
`NBFit`, `BetaFit`, `GammaFit`, `OrdinalFit`, and `MixedFamilyFit`. (Two-part
fits — `DeltaLogNormalFit`, hurdle — keep their bespoke
[`residuals`](@ref)`(...; type=:dunnsmyth)` mixed-CDF path and are intentionally
not wired here.)
"""
quantile_residuals(fit, Y; kwargs...) = _normal_quantile_of_pit(_pit(fit, Y; kwargs...))

# ---------------------------------------------------------------------------
# check_fit: a compact, family-agnostic post-fit summary.
# ---------------------------------------------------------------------------

"""
    FitCheck

Result of [`check_fit`](@ref). Fields:
- `family::Symbol` — the fit type (e.g. `:Poisson`, `:Mixed`).
- `converged::Bool` — the optimiser's convergence flag.
- `n_obs::Int`, `p::Int`, `K::Int` — observation count, responses, latent factors.
- `heywood::Bool` — Heywood / near-degenerate-loading flag: `true` when a loading
  column has collapsed (its largest singular value is a vanishing fraction of the
  leading one), a classic factor-analytic identifiability symptom.
- `low_resid_var::Bool` — near-zero residual-variance flag: `true` when the
  quantile residuals have an SD far below the ≈1 expected under a correct fit
  (over-fit / saturated cells; another identifiability symptom).
- `resid_mean::Float64`, `resid_sd::Float64` — mean and SD of the quantile
  residuals (≈0 and ≈1 under correct specification).
- `resid_min::Float64`, `resid_max::Float64` — residual range.
- `pit_ks::Float64` — Kolmogorov–Smirnov distance of the PITs from Uniform(0,1)
  (0 = perfectly uniform); a uniformity check independent of the normal transform.
- `note::String` — the loading-rotation reminder (loadings are identified only up
  to a `K×K` rotation; see [`rotation`](@ref)).
"""
struct FitCheck
    family::Symbol
    converged::Bool
    n_obs::Int
    p::Int
    K::Int
    heywood::Bool
    low_resid_var::Bool
    resid_mean::Float64
    resid_sd::Float64
    resid_min::Float64
    resid_max::Float64
    pit_ks::Float64
    note::String
end

# Convergence flag accessor (field name differs across fit structs).
_check_converged(fit::GllvmFit) = fit.converged
_check_converged(fit) = fit.converged   # all family fit structs carry `converged`

# Loadings via the existing _loadings accessor (postfit.jl) for every fit type.
_check_loadings(fit) = _loadings(fit)

# Family tag for display.
_check_family(::GllvmFit)        = :Gaussian
_check_family(::PoissonFit)      = :Poisson
_check_family(::BinomialFit)     = :Binomial
_check_family(::NBFit)           = :NegativeBinomial
_check_family(::BetaFit)         = :Beta
_check_family(::GammaFit)        = :Gamma
_check_family(::OrdinalFit)      = :Ordinal
_check_family(::MixedFamilyFit)  = :Mixed

# Kolmogorov–Smirnov distance of a sample from Uniform(0,1): the max gap between
# the empirical CDF and the 45° line. A simple uniformity statistic (no p-value).
function _uniform_ks(u::AbstractVector{<:Real})
    m = length(u)
    m == 0 && return NaN
    su = sort(u)
    d = 0.0
    @inbounds for i in 1:m
        dplus = i / m - su[i]
        dminus = su[i] - (i - 1) / m
        d = max(d, dplus, dminus)
    end
    return d
end

"""
    check_fit(fit, Y; rng=Random.default_rng(), heywood_tol=1e-3,
              low_resid_sd=0.5, kwargs...) -> FitCheck

Compact post-fit diagnostic summary for a fitted GLLVM. Reports the optimiser
convergence flag; a Heywood / near-degenerate-loading identifiability flag (a
loading singular value collapsed to a `heywood_tol` fraction of the leading one);
a near-zero residual-variance flag (quantile-residual SD below `low_resid_sd`,
well under the ≈1 expected under a correct fit); basic [`quantile_residuals`](@ref)
summaries (mean, SD, range); a Kolmogorov–Smirnov uniformity distance of the PITs
from Uniform(0,1); and the loading-rotation reminder.

`rng` (and any `N`/`X` keyword) is forwarded to [`quantile_residuals`](@ref); pass
a fixed `rng` for reproducible discrete-family randomisation. Returns a
[`FitCheck`](@ref) with a readable `show`.
"""
function check_fit(fit, Y; rng::AbstractRNG = Random.default_rng(),
                   heywood_tol::Real = 1e-3, low_resid_sd::Real = 0.5, kwargs...)
    Λ = _check_loadings(fit)
    p, K = size(Λ)
    n = size(Y, 2)

    # Heywood / degenerate-loading flag: a collapsed loading singular value.
    s = svdvals(Λ)
    smax = isempty(s) ? 0.0 : maximum(s)
    smin = isempty(s) ? 0.0 : minimum(s)
    heywood = smax > 0 ? (smin / smax < heywood_tol) : true

    # Residual summaries + PIT uniformity (one shared randomisation draw).
    U = _pit(fit, Y; rng = rng, kwargs...)
    R = _normal_quantile_of_pit(U)
    rv = vec(R)
    rmean = Statistics.mean(rv)
    rsd = Statistics.std(rv)
    rmin, rmax = extrema(rv)
    ks = _uniform_ks(vec(U))
    low_resid_var = isfinite(rsd) && rsd < low_resid_sd

    note = "Loadings are identified only up to a $(K)×$(K) rotation; " *
           "compare ΛΛᵀ (rotation-invariant) or use rotation(fit)/getLoadings(fit)."

    return FitCheck(_check_family(fit), _check_converged(fit), n, p, K,
                    heywood, low_resid_var, rmean, rsd, rmin, rmax, ks, note)
end

function Base.show(io::IO, ::MIME"text/plain", c::FitCheck)
    println(io, "GLLVM fit check (", c.family, ")")
    println(io, "  converged       : ", c.converged)
    println(io, "  dims            : n = ", c.n_obs, ", p = ", c.p, ", K = ", c.K)
    println(io, "  Heywood flag    : ", c.heywood,
            c.heywood ? "  (near-degenerate loading — check identifiability)" : "")
    println(io, "  low resid var   : ", c.low_resid_var,
            c.low_resid_var ? "  (residual SD ≪ 1 — possible over-fit)" : "")
    println(io, "  quantile resid  : mean = ", round(c.resid_mean; sigdigits = 3),
            ", sd = ", round(c.resid_sd; sigdigits = 3),
            ", range = [", round(c.resid_min; sigdigits = 3), ", ",
            round(c.resid_max; sigdigits = 3), "]")
    println(io, "  PIT uniformity  : KS = ", round(c.pit_ks; sigdigits = 3),
            " (0 = uniform)")
    print(io,   "  note            : ", c.note)
end

function Base.show(io::IO, c::FitCheck)
    print(io, "FitCheck(", c.family, ", converged=", c.converged,
          ", resid_sd=", round(c.resid_sd; sigdigits = 3),
          ", pit_ks=", round(c.pit_ks; sigdigits = 3),
          c.heywood ? ", HEYWOOD" : "",
          c.low_resid_var ? ", LOW_RESID_VAR" : "", ")")
end
