# Per-trait link-implicit residual variance σ²_d on the latent (link) scale.
#
# For non-Gaussian responses each trait carries an implicit observation-level
# residual on the latent (link) scale. Putting σ²_d on the diagonal of the
# per-trait Σ_latent = ΛΛᵀ + diag(σ²_d) is what makes the loadings ΛΛᵀ — which
# live on the LINK scale for non-Gaussian families — comparable across families
# on a common latent scale. Without it, binomial/ordinal diagonals are too small
# relative to a Gaussian latent of comparable variance and the implied cross-
# trait correlations are inflated.
#
# This is the GLLVM.jl twin of gllvmTMB's `link_residual_per_trait()`
# (gllvmTMB/R/extract-sigma.R) — the `link_residual = "auto"` convention. Each
# per-family formula below is confirmed against that R source.
#
# Per-family σ²_d (one entry per trait t; μ̂_t the per-trait mean fitted mean on
# the RESPONSE scale):
#   * Gaussian (identity)            : 0
#   * Binomial (logit)               : π²/3   (≈ 3.2899)
#   * Binomial (probit)              : 1
#   * Binomial (cloglog)             : π²/6   (≈ 1.6449)
#   * Poisson (log)                  : log(1 + 1/μ̂_t)         (lognormal-Poisson)
#   * NegativeBinomial (NB2, log)    : trigamma(r)            (r the Var=μ+μ²/r dispersion)
#   * Gamma (log)                    : trigamma(α)            (α the shape, Var=μ²/α)
#   * Beta (logit)                   : trigamma(μ̂_t φ) + trigamma((1−μ̂_t) φ)
#   * Ordinal (cumulative logit)     : π²/3
#
# References:
#   * Nakagawa & Schielzeth (2010) Biol. Rev. 85, 935–956 (the GLMM latent-scale
#     residual table; binomial-logit π²/3, NB/Gamma trigamma forms).
#   * Smithson & Verkuilen (2006) Psychol. Methods 11, 54–71 (the Beta-on-logit
#     delta-method residual trigamma(μφ) + trigamma((1−μ)φ)).
#   * McCullagh (1980) JRSS-B 42, 109–142 (the ordered cumulative-logit threshold
#     model: a standard logistic latent residual has variance π²/3).
#
# NOTE ON ORDINAL: gllvmTMB ships an ordinal_*probit* family (latent residual = 1
# by the standard-normal threshold construction). GLLVM.jl's `OrdinalFit` is the
# cumulative-*logit* model (`default_link(::Ordinal) == LogitLink()`), whose
# latent residual is standard-logistic with variance π²/3. Both are exact (no
# delta-method approximation); they differ only by the link's latent scale.

# ---------------------------------------------------------------------------
# Binomial link → constant σ²_d (μ̂-free). Confirmed: extract-sigma.R lines
# 156–162 (logit π²/3, probit 1, cloglog π²/6).
# ---------------------------------------------------------------------------
_binomial_link_residual(::LogitLink)   = π^2 / 3
_binomial_link_residual(::ProbitLink)  = 1.0
_binomial_link_residual(::CLogLogLink) = π^2 / 6
_binomial_link_residual(link::Link) = throw(ArgumentError(
    "Binomial link-residual is only defined for logit/probit/cloglog links; got $(typeof(link))."))

# Clamp a per-trait mean proportion away from {0, 1} before forming the Beta
# (a, b) = (μφ, (1−μ)φ) shape parameters. Mirrors the gllvmTMB Beta branch
# (extract-sigma.R line 230): a saturated fit with μ̂ → 0 or 1 would otherwise
# send one trigamma argument to ~0 and blow σ²_d up to ~1e24.
_clamp_mu_prop(μ) = clamp(μ, 1e-6, 1 - 1e-6)

# ---------------------------------------------------------------------------
# Family-marker core: σ²_d from (family marker, link, μ̂_t, dispersion).
#
# `μ̂` is the per-trait mean fitted mean on the response scale; `dispersion` is
# the family's scalar nuisance (NB2 r, Gamma shape α, Beta precision φ) and is
# ignored by families that do not use one. Returns a scalar σ²_d for one trait.
# AD-clean: only arithmetic + trigamma/log1p, so ForwardDiff Duals flow through.
# ---------------------------------------------------------------------------

# Gaussian (identity): σ²_d = 0 — the Gaussian σ_eps² already models the
# response-scale residual directly, so there is no LINK-implicit residual to add.
# extract-sigma.R fid 0 (line 140). Present so a mixed/Gaussian trait reduces
# cleanly and the Gaussian-reduction convention check has a method to call.
_link_residual_one(::Normal, ::IdentityLink, μ̂::Real, dispersion) = 0.0

# Poisson-log: lognormal-Poisson approximation log(1 + 1/μ̂). extract-sigma.R 171.
function _link_residual_one(::Poisson, ::LogLink, μ̂::Real, dispersion)
    return (isfinite(μ̂) && μ̂ > 0) ? log1p(1 / μ̂) : 0.0
end

# Binomial: constant per link (μ̂ / dispersion unused).
_link_residual_one(::Binomial, link::Link, μ̂::Real, dispersion) =
    _binomial_link_residual(link)

# NB2-log: trigamma(r), r the Var = μ + μ²/r dispersion. extract-sigma.R 188–191.
_link_residual_one(::NegativeBinomial, ::LogLink, μ̂::Real, dispersion::Real) =
    trigamma(max(dispersion, 1e-12))

# NB1-log: delta-method/lognormal residual log(1 + (1+φ)/μ̂), φ the LINEAR-variance
# dispersion (Var = μ(1+φ)). extract-sigma.R 330–350 (gllvmTMB fid 15, nbinom1).
# NB1's Poisson–Gamma representation has shape μ/φ (μ-dependent), so the NB2
# trigamma(r) identity does NOT carry over; the delta method
# Var(log y) ≈ Var(y)/E(y)² = μ(1+φ)/μ² = (1+φ)/μ is used in stable log1p form.
# As φ → 0 this reduces to the Poisson branch log1p(1/μ̂).
# (Nakagawa & Schielzeth 2010 delta method; Hilbe 2011 NB1 variance.)
function _link_residual_one(::NB1, ::LogLink, μ̂::Real, dispersion::Real)
    return (isfinite(μ̂) && μ̂ > 0) ? log1p((1 + dispersion) / μ̂) : 0.0
end

# Lognormal-log: σ²_d = σ² (the log-scale residual variance). For a STANDALONE
# lognormal family the latent (log) scale residual is exactly σ², so this is the
# diagonal added to ΛΛᵀ to form the latent-scale Σ. (gllvmTMB's extract-sigma.R
# fid 3 reports 0 because there σ_eps is carried in a SEPARATE slot; here the
# standalone family folds it into σ²_d so a lognormal trait is comparable to
# other non-Gaussian traits on the latent scale.) `dispersion` IS σ.
_link_residual_one(::LogNormal, ::LogLink, μ̂::Real, dispersion::Real) =
    dispersion^2

# Gamma-log: trigamma(shape). extract-sigma.R 182–183 (nu_hat = 1/σ², the shape).
# GLLVM.jl carries the shape α directly (Var = μ²/α), so dispersion == α.
_link_residual_one(::Gamma, ::LogLink, μ̂::Real, dispersion::Real) =
    trigamma(max(dispersion, 1e-12))

# Beta-logit: trigamma(μ̂φ) + trigamma((1−μ̂)φ). extract-sigma.R 216–233.
function _link_residual_one(::Beta, ::LogitLink, μ̂::Real, dispersion::Real)
    μc = _clamp_mu_prop(μ̂)
    φ = dispersion
    a = max(μc * φ, 1e-12)
    b = max((1 - μc) * φ, 1e-12)
    return trigamma(a) + trigamma(b)
end

# Ordinal cumulative-logit: standard-logistic latent residual variance π²/3.
_link_residual_one(::Ordinal, ::LogitLink, μ̂::Real, dispersion) = π^2 / 3

# ---------------------------------------------------------------------------
# Per-trait mean fitted mean μ̂ (response scale), one entry per trait.
#
# Reuses the fit's own `predict(...; type = :response)` so this is exactly the
# fitted mean each family reports — matching gllvmTMB's `mean(invlink(eta))` per
# trait. Ordinal predict returns the modal CLASS, not a response-scale mean, so
# its μ̂ is unused by `_link_residual_one(::Ordinal, …)` (a `nothing` vector is
# returned to make that explicit).
# ---------------------------------------------------------------------------
function _trait_mean_fitted(fit::Union{PoissonFit, NBFit}, Y::AbstractMatrix)
    μ = predict(fit, Y; type = :response)            # p×n response-scale means
    return vec(Statistics.mean(μ; dims = 2))
end
function _trait_mean_fitted(fit::Union{BetaFit, GammaFit}, Y::AbstractMatrix)
    μ = predict(fit, Y; type = :response)
    return vec(Statistics.mean(μ; dims = 2))
end
function _trait_mean_fitted(fit::BinomialFit, Y::AbstractMatrix; N = nothing)
    μ = predict(fit, Y; type = :response, N = N)
    return vec(Statistics.mean(μ; dims = 2))
end

# Scalar dispersion accessor per fit type (the family nuisance parameter).
_fit_dispersion(::PoissonFit)  = nothing
_fit_dispersion(::BinomialFit) = nothing
_fit_dispersion(fit::NBFit)    = fit.r
_fit_dispersion(fit::NB1Fit)   = fit.φ
_fit_dispersion(fit::GammaFit) = fit.α
_fit_dispersion(fit::BetaFit)  = fit.φ
_fit_dispersion(fit::LognormalFit) = fit.σ
_fit_dispersion(::OrdinalFit)  = nothing

# Family marker per fit type (for dispatching `_link_residual_one`).
_fit_family(::PoissonFit)  = Poisson()
_fit_family(::BinomialFit) = Binomial()
_fit_family(fit::NBFit)    = NegativeBinomial(fit.r, 0.5)
_fit_family(fit::NB1Fit)   = NB1(fit.φ)
_fit_family(fit::GammaFit) = Gamma(fit.α, 1.0)
_fit_family(fit::BetaFit)  = Beta(fit.φ, 1.0)
_fit_family(fit::LognormalFit) = LogNormal()
_fit_family(::OrdinalFit)  = Ordinal()

# ---------------------------------------------------------------------------
# Public API.
# ---------------------------------------------------------------------------

"""
    link_residual(family, link, μ̂, dispersion) -> Float64

Per-trait link-implicit residual variance σ²_d on the latent (link) scale for a
single trait, given the response `family` marker, the `link`, the trait's mean
fitted mean `μ̂` (response scale), and the family's scalar `dispersion` (the NB2
dispersion `r`, the Gamma shape `α`, or the Beta precision `φ`; pass `nothing`
for families without one). This is the GLLVM.jl twin of gllvmTMB's
`link_residual_per_trait` (`link_residual = "auto"`).

Per-family forms (each confirmed against gllvmTMB/R/extract-sigma.R):

| family / link                     | σ²_d                                     |
|:----------------------------------|:-----------------------------------------|
| `Normal`, `IdentityLink`          | 0                                        |
| `Binomial`, `LogitLink`           | π²/3                                      |
| `Binomial`, `ProbitLink`          | 1                                        |
| `Binomial`, `CLogLogLink`         | π²/6                                      |
| `Poisson`, `LogLink`              | log(1 + 1/μ̂)                             |
| `NegativeBinomial`, `LogLink`     | trigamma(r)                              |
| `Gamma`, `LogLink`                | trigamma(α)                             |
| `Beta`, `LogitLink`               | trigamma(μ̂ φ) + trigamma((1−μ̂) φ)       |
| `Ordinal`, `LogitLink`            | π²/3                                      |

The Beta branch clamps μ̂ to `[1e-6, 1−1e-6]` before forming `(μ̂φ, (1−μ̂)φ)`
(mirrors the R source) to keep a saturated fit's σ²_d finite.
"""
link_residual(family, link::Link, μ̂::Real, dispersion) =
    _link_residual_one(family, link, μ̂, dispersion)

"""
    link_residual(fit, Y; N=nothing) -> Vector{Float64}

Per-trait link-implicit residual variance σ²_d (length `p`) for a fitted
non-Gaussian GLLVM (`PoissonFit`, `BinomialFit`, `NBFit`, `BetaFit`, `GammaFit`,
or `OrdinalFit`). `Y` is the response matrix the fit was computed on (the fits do
not store the data); `N` (Binomial only) the trial counts.

Each entry uses the fit's own link, scalar dispersion, and per-trait mean fitted
mean `μ̂_t = mean_s predict(fit, Y; type = :response)[t, s]` (response scale).
Returns the vector added to `diag(ΛΛᵀ)` to form the latent-scale
`Σ_latent = ΛΛᵀ + diag(σ²_d)` (see [`sigma_y_site`](@ref)). Rotation-invariant
and family-agnostic on the latent scale (matches gllvmTMB `link_residual="auto"`).
"""
function link_residual(fit::Union{PoissonFit, NBFit, BetaFit, GammaFit}, Y::AbstractMatrix)
    link = fit.link
    fam  = _fit_family(fit)
    disp = _fit_dispersion(fit)
    μ̂    = _trait_mean_fitted(fit, Y)
    return [Float64(_link_residual_one(fam, link, μ̂[t], disp)) for t in eachindex(μ̂)]
end

function link_residual(fit::BinomialFit, Y::AbstractMatrix;
                       N::Union{Nothing, AbstractMatrix} = nothing)
    link = fit.link
    p = size(fit.Λ, 1)
    # Binomial σ²_d is μ̂-free, so we don't need the fitted mean; one value per trait.
    v = _binomial_link_residual(link)
    return fill(Float64(v), p)
end

function link_residual(fit::OrdinalFit, Y::AbstractMatrix)
    p = size(fit.Λ, 1)
    # Cumulative-logit threshold residual: π²/3, μ̂-free (no species intercept,
    # latent η has zero mean by construction).
    return fill(π^2 / 3, p)
end

# NB1: σ²_d = log1p((1+φ)/μ̂_t) is μ̂-dependent. NB1Fit has no postfit `predict`
# method, so the per-trait conditional fitted mean is computed inline from the
# fit's own parameters: per site find the Laplace mode ẑ_s under the NB1 family,
# form η = β + Λẑ, μ = exp(η), and average across sites (matches gllvmTMB's
# per-trait mean(exp(eta)) and the Poisson/NB conditional-mode convention).
function link_residual(fit::NB1Fit, Y::AbstractMatrix)
    p, n = size(Y)
    fam = _fit_family(fit)
    Nm = ones(Int, p, n)
    μacc = zeros(Float64, p)
    @inbounds for s in 1:n
        ẑ = _laplace_mode(fam, view(Y, :, s), view(Nm, :, s), fit.Λ, fit.β, fit.link)
        η = fit.β .+ fit.Λ * ẑ
        for t in 1:p
            μacc[t] += linkinv(fit.link, _clamp_eta(η[t]))
        end
    end
    μ̂ = μacc ./ n
    φ = fit.φ
    return [Float64(_link_residual_one(fam, fit.link, μ̂[t], φ)) for t in 1:p]
end

# Lognormal: σ²_d = σ² is μ̂-free (the log-scale residual variance), so no per-site
# mode solve is needed. extract-sigma.R fid 3 vs the standalone-family choice is
# documented at `_link_residual_one(::LogNormal, …)` above.
function link_residual(fit::LognormalFit, Y::AbstractMatrix)
    p = size(fit.Λ, 1)
    return fill(Float64(fit.σ^2), p)
end
