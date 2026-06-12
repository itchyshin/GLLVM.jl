# R -> Julia bridge entry point for GLLVM.jl, exposing the fitted one-part families
# to R via JuliaCall (the canonical transport across the drmTMB<->DRM.jl ecosystem).
#
# `bridge_fit` accepts plain matrices + family strings (the R side, gllvmTMB, owns
# formula parsing; GLLVM.jl owns the numerical fit) and returns a FLAT NamedTuple of
# JuliaCall-convertible primitives only (Float64 scalars/arrays, Ints, Strings,
# Bools) — no Julia struct ever crosses the language boundary.
#
# Contract keys:
#   family       :: String            — requested family
#   families     :: Vector{String}    — per-trait family (length p; repeated)
#   model        :: String            — short model tag ("poisson_rr", ...)
#   d            :: Int               — latent dimension K
#   n_traits     :: Int               — p (rows of y)
#   n_units      :: Int               — n (columns of y)
#   trait_names  :: Vector{String}    — length p
#   unit_names   :: Vector{String}    — length n
#   loadings     :: Matrix{Float64}   — p x d rotated loadings
#   alpha        :: Vector{Float64}   — per-trait intercept (link scale; NaN for Ordinal)
#   dispersion   :: Vector{Float64}   — per-trait nuisance (r/phi/alpha; NaN if none)
#   sigma_eps    :: Float64           — Gaussian residual SD (NaN otherwise)
#   Sigma        :: Matrix{Float64}   — p x p latent-scale trait covariance
#   correlation  :: Matrix{Float64}   — p x p latent-scale trait correlation
#   communality  :: Vector{Float64}   — per-trait communality c^2 (length p)
#   scores       :: Matrix{Float64}   — n x d latent scores (0x0 if unavailable)
#   loglik       :: Float64
#   aic, bic     :: Float64
#   df           :: Int               — free-parameter count for AIC
#   nobs         :: Int               — p*n
#   converged    :: Bool
#   iterations   :: Int
#   message      :: String
#   link         :: Vector{String}    — per-trait link name
#   note         :: String            — caveats for the R side
#
# v1 scope: the 8 one-part families main provides a fitter for (gaussian, poisson,
# binomial, negbinomial/nb2, nb1, beta, gamma, ordinal). For the Gaussian fit the
# latent-scale Sigma/correlation/communality use the package extractors; for the
# non-Gaussian fits they use the self-contained shared-block (Lambda*Lambda') form,
# pending the salvage of the link-residual table + non-Gaussian extractors (then the
# cross-family correlation gains its distribution-specific residual). Mixed-family,
# lognormal, fixed-effect X, and bootstrap CIs are documented follow-ups.
#
# ADDITIVE: this file + an include/export line in GLLVM.jl. It edits no fitter or
# extractor; it is included LAST so every dispatch target already exists.

# --- plain-data helpers ----------------------------------------------------

function _bridge_names(x, n::Integer, prefix::AbstractString)
    x === nothing && return ["$(prefix)$i" for i in 1:n]
    names = String.(collect(x))
    length(names) == n ||
        throw(ArgumentError("$(prefix)_names length ($(length(names))) must equal $n"))
    return names
end

function _bridge_get(options, key::AbstractString, default)
    options === nothing && return default
    if options isa AbstractDict
        for k in (key, Symbol(key))
            haskey(options, k) && return options[k]
        end
        return default
    end
    return default
end

function _bridge_family_key(family::AbstractString)
    key = lowercase(strip(family))
    key in ("gaussian", "normal")                                   && return "gaussian"
    key in ("poisson",)                                             && return "poisson"
    key in ("binomial", "bernoulli")                                && return "binomial"
    key in ("negbinomial", "negative_binomial", "nbinom2", "nb2", "negbin") && return "negbinomial"
    key in ("nb1", "nbinom1")                                       && return "nb1"
    key in ("beta",)                                                && return "beta"
    key in ("gamma",)                                               && return "gamma"
    key in ("ordinal", "ordered")                                   && return "ordinal"
    throw(ArgumentError(
        "bridge_fit: unsupported family \"$family\"; this engine build supports " *
        "gaussian, poisson, binomial, negbinomial (nbinom2), nb1, beta, gamma, ordinal"))
end

_bridge_rr_df(p::Integer, K::Integer) = p * K - div(K * (K - 1), 2)
_bridge_link_name(link::Link) = String(nameof(typeof(link)))

function _bridge_corr_from_sigma(Σ::AbstractMatrix)
    p = size(Σ, 1)
    R = Matrix{Float64}(undef, p, p)
    @inbounds for j in 1:p, i in 1:p
        denom = sqrt(Σ[i, i] * Σ[j, j])
        R[i, j] = denom > 0 ? Σ[i, j] / denom : (i == j ? 1.0 : 0.0)
    end
    return R
end

# Rotated p x d loadings via the public extractor (works for every fit type).
_bridge_loadings(fit) = Matrix{Float64}(getLoadings(fit; rotate = true))

# Defensive latent-score extraction: getLV signatures vary per family; if a call
# does not apply, scores degrade to empty rather than failing the whole fit.
function _bridge_scores(f)
    try
        return Matrix{Float64}(f())
    catch
        return zeros(Float64, 0, 0)
    end
end

# --- public entry point ----------------------------------------------------

"""
    bridge_fit(; y, family, d=1, N=nothing, X=nothing,
               trait_names=nothing, unit_names=nothing, options=Dict())

Plain-data R->Julia bridge (JuliaCall transport). Fits a one-part GLLVM for the
requested `family` and returns a flat, JuliaCall-convertible NamedTuple (see the
file header for the key->type contract). `y` is a `p x n` response matrix
(traits x units); `d` is the latent dimension `K`; `N` (Binomial trials, `p x n`
or a scalar) is forwarded to the Binomial fitter.
"""
function bridge_fit(; y,
                    family,
                    d::Integer = 1,
                    N = nothing,
                    X = nothing,
                    trait_names = nothing,
                    unit_names = nothing,
                    options = Dict{String,Any}())
    K = Int(d)
    K >= 1 || throw(ArgumentError("d must be a positive integer"))
    family isa AbstractVector && throw(ArgumentError(
        "bridge_fit: mixed-family models (a vector of family strings) are not yet " *
        "supported on this engine build; fit one family at a time"))
    X === nothing || throw(ArgumentError(
        "bridge_fit: fixed-effect covariates X are not yet wired in this bridge " *
        "build; a documented follow-up"))
    return _bridge_fit_onepart(y, _bridge_family_key(String(family)), K, N,
                               trait_names, unit_names, options)
end

# --- one-part dispatch -----------------------------------------------------

function _bridge_fit_onepart(y, key::AbstractString, K::Integer, N,
                             trait_names, unit_names, options)
    Yf = Matrix{Float64}(y)
    p, n = size(Yf)
    traits = _bridge_names(trait_names, p, "trait")
    units = _bridge_names(unit_names, n, "unit")

    if key == "gaussian"
        alpha = vec(Statistics.mean(Yf; dims = 2))
        Yc = Yf .- alpha
        fit = fit_gaussian_gllvm(Yc; K = K)
        Sigma = Matrix{Float64}(sigma_y_site(fit))
        corr  = Matrix{Float64}(correlation(fit))
        comm  = Vector{Float64}(communality(fit))
        scores = _bridge_scores(() -> getLV(fit, Yc; rotate = true))
        df = p + _bridge_rr_df(p, K) + 1
        return _bridge_assemble(fit, "gaussian", "gaussian_rr", traits, units;
            alpha = alpha, dispersion = fill(NaN, p), sigma_eps = fit.pars.σ_eps,
            link = fill("IdentityLink", p), Sigma = Sigma, corr = corr, comm = comm,
            scores = scores, df = df, loglik = fit.logLik,
            converged = fit.converged, iterations = fit.n_iter, note = "")
    end

    # Non-Gaussian: fit, then build derived quantities from the shared block.
    note_ng = "non-Gaussian Sigma/correlation use the shared block Lambda*Lambda' " *
              "only (no link-residual term yet); communality is 1. Cross-family " *
              "correlation precision arrives with the link-residual salvage."
    if key == "poisson"
        Yi = round.(Int, Yf)
        fit = fit_poisson_gllvm(Yi; K = K)
        scores = _bridge_scores(() -> getLV(fit, Yi; rotate = true))
        return _bridge_assemble_ng(fit, "poisson", "poisson_rr", traits, units, p, K;
            alpha = fit.β, dispersion = fill(NaN, p), df = p + _bridge_rr_df(p, K),
            scores = scores, note = note_ng)
    elseif key == "binomial"
        Yi = round.(Int, Yf)
        Ni = N === nothing ? fill(1, p, n) :
             (N isa Number ? fill(round(Int, N), p, n) : round.(Int, Matrix(N)))
        fit = fit_binomial_gllvm(Yi; K = K, N = Ni)
        scores = _bridge_scores(() -> getLV(fit, Yi; N = Ni, rotate = true))
        return _bridge_assemble_ng(fit, "binomial", "binomial_rr", traits, units, p, K;
            alpha = fit.β, dispersion = fill(NaN, p), df = p + _bridge_rr_df(p, K),
            scores = scores, note = note_ng)
    elseif key == "negbinomial"
        Yi = round.(Int, Yf)
        fit = fit_nb_gllvm(Yi; K = K)
        scores = _bridge_scores(() -> getLV(fit, Yi; rotate = true))
        return _bridge_assemble_ng(fit, "negbinomial", "negbinomial_rr", traits, units, p, K;
            alpha = fit.β, dispersion = fill(fit.r, p), df = p + _bridge_rr_df(p, K) + 1,
            scores = scores, note = note_ng)
    elseif key == "nb1"
        Yi = round.(Int, Yf)
        fit = fit_nb1_gllvm(Yi; K = K)
        scores = _bridge_scores(() -> getLV(fit, Yi; rotate = true))
        return _bridge_assemble_ng(fit, "nb1", "nb1_rr", traits, units, p, K;
            alpha = fit.β, dispersion = fill(fit.φ, p), df = p + _bridge_rr_df(p, K) + 1,
            scores = scores, note = note_ng)
    elseif key == "beta"
        fit = fit_beta_gllvm(Yf; K = K)
        scores = _bridge_scores(() -> getLV(fit, Yf; rotate = true))
        return _bridge_assemble_ng(fit, "beta", "beta_rr", traits, units, p, K;
            alpha = fit.β, dispersion = fill(fit.φ, p), df = p + _bridge_rr_df(p, K) + 1,
            scores = scores, note = note_ng)
    elseif key == "gamma"
        fit = fit_gamma_gllvm(Yf; K = K)
        scores = _bridge_scores(() -> getLV(fit, Yf; rotate = true))
        return _bridge_assemble_ng(fit, "gamma", "gamma_rr", traits, units, p, K;
            alpha = fit.β, dispersion = fill(fit.α, p), df = p + _bridge_rr_df(p, K) + 1,
            scores = scores, note = note_ng)
    elseif key == "ordinal"
        Yi = round.(Int, Yf)
        fit = fit_ordinal_gllvm(Yi; K = K)
        scores = _bridge_scores(() -> getLV(fit, Yi; rotate = true))
        return _bridge_assemble_ng(fit, "ordinal", "ordinal_rr", traits, units, p, K;
            alpha = fill(NaN, p), dispersion = fill(NaN, p),
            df = (fit.C - 1) + _bridge_rr_df(p, K), scores = scores, note = note_ng)
    end
    throw(ArgumentError("bridge_fit: unhandled family key \"$key\""))  # unreachable
end

# Non-Gaussian assembler: shared-block (Lambda*Lambda') derived quantities.
function _bridge_assemble_ng(fit, family, model, traits, units, p, K;
                             alpha, dispersion, df, scores, note)
    Λ = _bridge_loadings(fit)
    Sigma = Λ * Λ'
    Sigma = (Sigma + Sigma') ./ 2
    corr = _bridge_corr_from_sigma(Sigma)
    comm = ones(Float64, p)
    return _bridge_assemble(fit, family, model, traits, units;
        alpha = alpha, dispersion = dispersion, sigma_eps = NaN,
        link = fill(_bridge_link_name(fit.link), p), Sigma = Sigma, corr = corr,
        comm = comm, scores = scores, df = df, loglik = fit.loglik,
        converged = fit.converged, iterations = fit.iterations, note = note,
        loadings = Λ)
end

# Shared flat-NamedTuple builder.
function _bridge_assemble(fit, family::AbstractString, model::AbstractString,
                          traits, units;
                          alpha, dispersion, sigma_eps, link, Sigma, corr, comm,
                          scores, df, loglik, converged, iterations, note,
                          loadings = nothing)
    p = length(traits)
    n = length(units)
    L = loadings === nothing ? _bridge_loadings(fit) : loadings
    K = size(L, 2)
    ll = Float64(loglik)
    nobs = p * n
    return (
        family       = family,
        families     = fill(family, p),
        model        = model,
        d            = K,
        n_traits     = p,
        n_units      = n,
        trait_names  = traits,
        unit_names   = units,
        loadings     = Matrix{Float64}(L),
        alpha        = Vector{Float64}(alpha),
        dispersion   = Vector{Float64}(dispersion),
        sigma_eps    = Float64(sigma_eps),
        Sigma        = Matrix{Float64}(Sigma),
        correlation  = Matrix{Float64}(corr),
        communality  = Vector{Float64}(comm),
        scores       = Matrix{Float64}(scores),
        loglik       = ll,
        aic          = 2 * df - 2 * ll,
        bic          = df * log(n) - 2 * ll,
        df           = df,
        nobs         = nobs,
        converged    = converged,
        iterations   = iterations,
        message      = converged ? "converged" : "not converged",
        link         = Vector{String}(link),
        note         = note,
    )
end
