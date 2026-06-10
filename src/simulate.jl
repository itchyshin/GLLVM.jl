# Family-dispatched data-generating process (DGP) for GLLVM.jl.
#
# `simulate(...)` draws a p×n response matrix Y from a GLLVM at known parameters
# (params-in) or from a fitted model (from-fit). Per site s it draws a fresh
# latent vector z_s ~ N(0, I_K), forms η_{ts} = β_t + (Λ z_s)_t (+ Xβ if supplied),
# maps to μ via the family's inverse link, then draws y from the family. Each
# `_draw_y` method is the EXACT sampling inverse of that family's `_glm_logpdf`
# (families/*.jl), so simulate→fit round-trips recover the generating parameters
# (verified in test/test_simulate.jl).
#
# Ordinal is special: no intercept (η = (Λ z)_t only), the cutpoints τ live in
# the dispersion slot, and categories are drawn by inverse-CDF over the existing
# `_ord_prob(c, η, τ)` — it does NOT use the scalar `_draw_y` path.
#
# This file is ADDITIVE. It does NOT touch confint_bootstrap.jl's Gaussian
# `_bootstrap_simulate!` (a separate, GllvmFit-internal simulator) nor any
# src/families/*.jl fitter. It REUSES linkinv/default_link (families/links.jl),
# _clamp_eta/_positive_from_log (families/laplace.jl), _ord_prob (families/
# ordinal.jl), pack/unpack_lambda (packing.jl), and _fit_family/_fit_dispersion
# (link_residual.jl).

# ---------------------------------------------------------------------------
# Per-family scalar draw. Each method is the sampling inverse of the matching
# `_glm_logpdf(family, μ, n, y)` in src/families/*.jl.
#
# Signature: _draw_y(rng, family, μ, n_ts, dispersion_t) -> a single draw.
#   `μ`           is the response-scale mean for one (t, s) cell;
#   `n_ts`        the Binomial trial count for that cell (ignored otherwise);
#   `dispersion_t` the family's scalar nuisance (NB2 r, Gamma shape α, Beta
#                 precision φ); ignored by Poisson/Binomial.
# ---------------------------------------------------------------------------

# Poisson: _glm_logpdf(::Poisson, μ, n, y) = logpdf(Poisson(μ), y).
_draw_y(rng::AbstractRNG, ::Poisson, μ, n_ts, dispersion) =
    Float64(rand(rng, Poisson(μ)))

# Binomial: _glm_logpdf(::Binomial, μ, n, y) = logpdf(Binomial(Int(n), μ), y).
# `n_ts` is the number of trials (default 1 ⇒ Bernoulli).
_draw_y(rng::AbstractRNG, ::Binomial, μ, n_ts, dispersion) =
    Float64(rand(rng, Binomial(Int(n_ts), μ)))

# NegativeBinomial (NB2): _glm_logpdf uses NegativeBinomial(r, r/(r+μ)), r the
# dispersion (Var = μ + μ²/r).
function _draw_y(rng::AbstractRNG, ::NegativeBinomial, μ, n_ts, dispersion)
    r = dispersion
    return Float64(rand(rng, NegativeBinomial(r, r / (r + μ))))
end

# Gamma: _glm_logpdf is Gamma(shape α, scale μ/α), α the dispersion (Var = μ²/α).
function _draw_y(rng::AbstractRNG, ::Gamma, μ, n_ts, dispersion)
    α = dispersion
    return Float64(rand(rng, Gamma(α, μ / α)))
end

# Beta: _glm_logpdf is Beta(μφ, (1−μ)φ), φ the dispersion. Clamp the draw to
# (1e-6, 1−1e-6) so a generated 0/1 cannot violate `_clamp_mu(::Beta)` downstream.
function _draw_y(rng::AbstractRNG, ::Beta, μ, n_ts, dispersion)
    φ = dispersion
    y = rand(rng, Beta(μ * φ, (1 - μ) * φ))
    return clamp(y, 1e-6, 1 - 1e-6)
end

# Normal: identity link ⇒ μ = η; σ = dispersion. Return the Gaussian draw
# directly (NOT re-linkinv'd). Handled inline in _simulate_core for clarity, but
# a method is provided for the per-cell dispatch path used by mixed simulation.
_draw_y(rng::AbstractRNG, ::Normal, μ, n_ts, dispersion) =
    μ + dispersion * randn(rng)

# NB1 (linear variance, families/nb1.jl): Var = μ(1+φ), φ the dispersion. NB1's
# NB(size, prob) representation is size r = μ/φ, prob p = 1/(1+φ) (so
# Var = μ + μ²/r = μ(1+φ)). As φ → 0 the variance → μ (Poisson limit).
function _draw_y(rng::AbstractRNG, ::NB1, μ, n_ts, dispersion)
    φ = dispersion
    r = μ / φ
    p = 1 / (1 + φ)
    return Float64(rand(rng, NegativeBinomial(r, p)))
end

# Lognormal (families/lognormal.jl): log(y) ~ Normal(η, σ²), σ = dispersion. With
# the log link μ = exp(η), so the draw exp(η + σ·ε) = μ·exp(σ·ε), ε ~ N(0,1).
_draw_y(rng::AbstractRNG, ::LogNormal, μ, n_ts, dispersion) =
    μ * exp(dispersion * randn(rng))

# Beta-Binomial (families/betabinomial.jl): _glm_logpdf is the mean-parameterised
# BetaBinomial(N, μφ, (1−μ)φ), φ the dispersion. Drawn hierarchically as the exact
# sampling inverse: p ~ Beta(μφ, (1−μ)φ), then y ~ Binomial(N, p) (equivalent to
# Distributions' BetaBinomial(N, μφ, (1−μ)φ)). `n_ts` is the number of trials N.
function _draw_y(rng::AbstractRNG, ::BetaBinomial, μ, n_ts, dispersion)
    φ = dispersion
    p = rand(rng, Beta(μ * φ, (1 - μ) * φ))
    return Float64(rand(rng, Binomial(Int(n_ts), p)))
end

# Student-t (families/studentt.jl): identity link ⇒ location μ = η; scale σ =
# dispersion; degrees of freedom ν carried in the family marker. (y − μ)/σ ~ t_ν,
# so the draw is μ + σ · t, t ~ TDist(ν) — the exact sampling inverse of the
# location–scale t `_glm_logpdf`.
_draw_y(rng::AbstractRNG, f::StudentTFamily, μ, n_ts, dispersion) =
    μ + dispersion * rand(rng, TDist(f.ν))

# ---------------------------------------------------------------------------
# Core params-in DGP. Returns Y::Matrix{Float64} (p×n).
#
# `families`/`links` are length-p; `β` length-p; `Λ` p×K; `dispersion` length-p
# (entries unused by dispersion-free families may be NaN/anything). `N` is the
# p×n Binomial trial-count matrix. `Xβ` is an OPTIONAL p×n additive offset on the
# linear predictor (covariate hook — wired into η, but the public API does not
# build real covariates from `X` in this slice).
#
# Ordinal traits are detected by family marker and drawn via inverse-CDF using
# the cutpoints carried in `dispersion[t]` (a vector), with η = (Λ z)_t (no β).
# ---------------------------------------------------------------------------
function _simulate_core(rng::AbstractRNG, families::AbstractVector,
        links::AbstractVector, β::AbstractVector, Λ::AbstractMatrix,
        dispersion::AbstractVector, N::AbstractMatrix;
        Xβ::Union{Nothing, AbstractMatrix} = nothing)
    p, K = size(Λ)
    n = size(N, 2)
    z = randn(rng, K, n)                      # one latent vector per site
    Lz = Λ * z                                # p×n latent contribution
    Y = Matrix{Float64}(undef, p, n)
    @inbounds for t in 1:p
        fam = families[t]
        link = links[t]
        if fam isa Ordinal
            # No intercept; cutpoints τ in the dispersion slot.
            τ = dispersion[t]
            C = length(τ) + 1
            for s in 1:n
                η = Lz[t, s] + (Xβ === nothing ? 0.0 : Xβ[t, s])
                Y[t, s] = _draw_ordinal(rng, _clamp_eta(η), τ, C)
            end
        else
            for s in 1:n
                η = β[t] + Lz[t, s] + (Xβ === nothing ? 0.0 : Xβ[t, s])
                μ = linkinv(link, _clamp_eta(η))
                Y[t, s] = _draw_y(rng, fam, μ, N[t, s], dispersion[t])
            end
        end
    end
    return Y
end

# Ordinal category draw by inverse-CDF over `_ord_prob(c, η, τ)` (cumulative-logit
# probabilities at η with cutpoints τ; C = length(τ)+1 categories coded 1:C).
function _draw_ordinal(rng::AbstractRNG, η, τ::AbstractVector, C::Integer)
    u = rand(rng)
    acc = 0.0
    @inbounds for c in 1:(C - 1)
        acc += _ord_prob(c, η, τ)
        u ≤ acc && return Float64(c)
    end
    return Float64(C)
end

# ---------------------------------------------------------------------------
# Argument validation / normalisation helpers.
# ---------------------------------------------------------------------------

# Build the RNG: an explicit `seed` (Integer) yields a fresh MersenneTwister;
# otherwise the supplied `rng` is used as-is.
_simulate_rng(rng::AbstractRNG, seed::Nothing) = rng
_simulate_rng(::AbstractRNG, seed::Integer) = MersenneTwister(seed)

# Normalise the trial-count argument N (Binomial) into a p×n integer matrix.
# `nothing` ⇒ all-ones (Bernoulli); a scalar ⇒ filled; a matrix ⇒ size-checked.
function _simulate_trials(N, p::Integer, n::Integer)
    if N === nothing
        return ones(Int, p, n)
    elseif N isa Integer
        return fill(Int(N), p, n)
    elseif N isa AbstractMatrix
        size(N) == (p, n) || throw(DimensionMismatch(
            "N must be $(p)×$(n); got $(size(N))"))
        return Int.(N)
    else
        throw(ArgumentError("N must be nothing, an Integer, or a $(p)×$(n) matrix"))
    end
end

# Normalise the dispersion argument for the GENERAL (non-ordinal) params-in path
# into a length-p vector. `nothing` ⇒ all-NaN (no dispersion-carrying family).
# A scalar ⇒ filled; a vector ⇒ length-checked. NaN/`nothing`-as-NaN entries are
# allowed where a family carries no dispersion.
function _simulate_dispersion(dispersion, p::Integer)
    if dispersion === nothing
        return fill(NaN, p)
    elseif dispersion isa Real
        return fill(Float64(dispersion), p)
    elseif dispersion isa AbstractVector
        length(dispersion) == p || throw(DimensionMismatch(
            "dispersion must have length p = $p; got $(length(dispersion))"))
        return [d === nothing ? NaN : Float64(d) for d in dispersion]
    else
        throw(ArgumentError("dispersion must be nothing, a Real, or a length-$p vector"))
    end
end

# Validate the shared (families, links, β, Λ) shapes for the params-in path.
function _simulate_validate(families::AbstractVector, links::AbstractVector,
        β::AbstractVector, Λ::AbstractMatrix)
    p = length(families)
    length(links) == p || throw(DimensionMismatch(
        "links must have length p = $p; got $(length(links))"))
    length(β) == p || throw(DimensionMismatch(
        "β must have length p = $p; got $(length(β))"))
    size(Λ, 1) == p || throw(DimensionMismatch(
        "Λ must have $p rows (one per response); got size(Λ) = $(size(Λ))"))
    return p
end

# ---------------------------------------------------------------------------
# Public API: params-in.
# ---------------------------------------------------------------------------

"""
    simulate(families, links, β, Λ, n; dispersion=nothing, N=nothing,
             rng=Random.default_rng(), seed=nothing, X=nothing) -> Matrix{Float64}

Simulate a `p × n` GLLVM response matrix `Y` from known parameters. Per site
`s`, a latent vector `z_s ~ N(0, I_K)` is drawn, the linear predictor is
`η_{ts} = β_t + (Λ z_s)_t`, the mean is `μ_{ts} = linkinv(links[t], η_{ts})`,
and `y_{ts}` is drawn from `families[t]` at `μ_{ts}` (the exact sampling inverse
of that family's likelihood).

Arguments:
- `families::AbstractVector` — length-`p` `Distributions` family markers
  (`Normal()`, `Poisson()`, `Binomial()`, `NegativeBinomial()`, `Gamma()`,
  `Beta()`; `Ordinal()` via the dedicated overload below).
- `links::AbstractVector` — length-`p` `Link`s.
- `β::AbstractVector` — length-`p` intercepts (on each trait's link scale; for
  `Normal`/identity this is the mean).
- `Λ::AbstractMatrix` — `p × K` loadings.
- `n::Integer` — number of sites (columns of `Y`).

Keyword arguments:
- `dispersion` — `nothing` (no dispersion-carrying family), a scalar (applied to
  every trait), or a length-`p` vector. Entry meanings: `Normal` σ, `NegativeBinomial`
  r, `Gamma` shape α, `Beta` precision φ. Use `NaN`/`nothing` where a trait has none.
- `N` — Binomial trial counts: `nothing` (all-ones ⇒ Bernoulli), a scalar, or a
  `p × n` matrix.
- `rng` — an `AbstractRNG` (default `Random.default_rng()`).
- `seed` — if given (an `Integer`), a fresh `MersenneTwister(seed)` is used (so
  the same `seed` reproduces the same `Y`), overriding `rng`.
- `X` — reserved covariate hook (not wired in this release; must be `nothing`).

Returns `Y::Matrix{Float64}` of size `p × n`.
"""
function simulate(families::AbstractVector, links::AbstractVector,
        β::AbstractVector, Λ::AbstractMatrix, n::Integer;
        dispersion = nothing, N = nothing,
        rng::AbstractRNG = Random.default_rng(), seed = nothing, X = nothing)
    X === nothing || throw(ArgumentError(
        "simulate: the covariate `X` hook is not wired in this release; pass X = nothing"))
    n ≥ 1 || throw(ArgumentError("n must be ≥ 1; got $n"))
    p = _simulate_validate(families, links, β, Λ)
    rng = _simulate_rng(rng, seed)
    Nm = _simulate_trials(N, p, n)
    disp = _simulate_dispersion(dispersion, p)
    return _simulate_core(rng, families, links, β, Λ, disp, Nm)
end

"""
    simulate(family, β, Λ, n; link=default_link(family), dispersion=nothing,
             N=nothing, rng=Random.default_rng(), seed=nothing, X=nothing)

Single-family convenience overload: every trait shares `family` and `link`. `β`
is the length-`p` intercept vector and `Λ` the `p × K` loadings (so `p` is read
from `length(β)`). See the vector overload for the keyword semantics.
"""
function simulate(family, β::AbstractVector, Λ::AbstractMatrix, n::Integer;
        link::Link = default_link(family), dispersion = nothing, N = nothing,
        rng::AbstractRNG = Random.default_rng(), seed = nothing, X = nothing)
    p = length(β)
    families = [family for _ in 1:p]
    links = [link for _ in 1:p]
    return simulate(families, links, β, Λ, n;
                    dispersion = dispersion, N = N, rng = rng, seed = seed, X = X)
end

"""
    simulate(::Ordinal, τ, Λ, n; link=LogitLink(), rng=Random.default_rng(),
             seed=nothing, X=nothing) -> Matrix{Float64}

Ordinal (proportional-odds cumulative-logit) DGP. There is NO intercept — the
shared ordered cutpoints `τ` (length `C−1`) carry the category levels — so the
linear predictor is `η_{ts} = (Λ z_s)_t` and each `y_{ts} ∈ {1,…,C}` is drawn by
inverse-CDF over `P(y = c | η) = _ord_prob(c, η, τ)`. `Λ` is `p × K`; `p` is read
from `size(Λ, 1)`. Returns an integer-valued `Float64` `p × n` matrix.
"""
function simulate(::Ordinal, τ::AbstractVector, Λ::AbstractMatrix, n::Integer;
        link::Link = LogitLink(), rng::AbstractRNG = Random.default_rng(),
        seed = nothing, X = nothing)
    X === nothing || throw(ArgumentError(
        "simulate: the covariate `X` hook is not wired in this release; pass X = nothing"))
    n ≥ 1 || throw(ArgumentError("n must be ≥ 1; got $n"))
    length(τ) ≥ 1 || throw(ArgumentError(
        "ordinal cutpoints τ must have length ≥ 1 (C = length(τ)+1 ≥ 2 categories)"))
    issorted(τ) || throw(ArgumentError("ordinal cutpoints τ must be sorted ascending"))
    p = size(Λ, 1)
    rng = _simulate_rng(rng, seed)
    families = [Ordinal() for _ in 1:p]
    links = [link for _ in 1:p]
    β = zeros(p)                              # unused by the ordinal branch
    disp = [τ for _ in 1:p]                   # cutpoints in the dispersion slot
    N = ones(Int, p, n)
    return _simulate_core(rng, families, links, β, Λ, disp, N)
end

# ---------------------------------------------------------------------------
# Public API: from a fitted model. The fit structs do not record `n`, so it is a
# required positional argument. Each overload reads the fit's parameters and
# dispatches to the params-in core.
# ---------------------------------------------------------------------------

"""
    simulate(fit::MixedFamilyFit, n; N=nothing, rng=Random.default_rng(), seed=nothing)

Simulate `n` fresh sites from a fitted mixed-family GLLVM, using the fit's
per-trait families/links/intercepts, shared loadings `Λ`, and per-trait
dispersions (`NaN` entries for dispersion-free traits map to the unused slot).
"""
function simulate(fit::MixedFamilyFit, n::Integer;
        N = nothing, rng::AbstractRNG = Random.default_rng(), seed = nothing)
    n ≥ 1 || throw(ArgumentError("n must be ≥ 1; got $n"))
    p = size(fit.Λ, 1)
    rng = _simulate_rng(rng, seed)
    Nm = _simulate_trials(N, p, n)
    # dispersion[t] is NaN where the trait carries none; those families ignore it.
    return _simulate_core(rng, fit.families, fit.links, fit.β, fit.Λ, fit.dispersion, Nm)
end

"""
    simulate(fit::Union{PoissonFit,BinomialFit,NBFit,NB1Fit,GammaFit,BetaFit,BetaBinomialFit,LognormalFit,StudentTFit}, n;
             N=nothing, rng=Random.default_rng(), seed=nothing)

Simulate `n` fresh sites from a fitted single-family GLLVM. The family marker,
scalar dispersion, and link are taken from the fit (`_fit_family`,
`_fit_dispersion`, `fit.link`); intercepts and loadings from `fit.β` / `fit.Λ`.
"""
function simulate(fit::Union{PoissonFit, BinomialFit, NBFit, NB1Fit, GammaFit, BetaFit, BetaBinomialFit, LognormalFit, StudentTFit},
        n::Integer; N = nothing,
        rng::AbstractRNG = Random.default_rng(), seed = nothing)
    n ≥ 1 || throw(ArgumentError("n must be ≥ 1; got $n"))
    p = size(fit.Λ, 1)
    rng = _simulate_rng(rng, seed)
    Nm = _simulate_trials(N, p, n)
    fam = _fit_family(fit)
    d = _fit_dispersion(fit)
    disp = fill(d === nothing ? NaN : Float64(d), p)
    families = [fam for _ in 1:p]
    links = [fit.link for _ in 1:p]
    return _simulate_core(rng, families, links, fit.β, fit.Λ, disp, Nm)
end

"""
    simulate(fit::OrdinalFit, n; rng=Random.default_rng(), seed=nothing)

Simulate `n` fresh sites from a fitted ordinal (cumulative-logit) GLLVM, using
the fit's loadings `Λ` and ordered cutpoints `τ`.
"""
function simulate(fit::OrdinalFit, n::Integer;
        rng::AbstractRNG = Random.default_rng(), seed = nothing)
    return simulate(Ordinal(), fit.τ, fit.Λ, n;
                    link = fit.link, rng = rng, seed = seed)
end
