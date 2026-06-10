# R -> Julia bridge entry point for GLLVM.jl, exposing ALL fitted families
# (Gaussian + non-Gaussian one-part + mixed) to R via JuliaCall.
#
# `bridge_fit` is the superset companion of the Gaussian-only `gllvm_bridge`
# primitive in the sibling phylo-bridge worktree. It deliberately accepts simple
# matrices, family strings, and a primitive `options` dictionary so the R side
# (gllvmTMB) owns formula parsing while GLLVM.jl owns the numerical fit. It
# returns a FLAT NamedTuple of JuliaCall-convertible primitives only — Float64
# scalars/arrays, Ints, Strings, Bools — so no Julia struct ever crosses the
# language boundary.
#
# Contract (mirrors `gllvm_bridge` keys, plus the additions the R side wants):
#   family        :: String                 — the requested family (or "mixed")
#   families      :: Vector{String}          — per-trait family (length p; the
#                                              single value repeated for one-part)
#   model         :: String                  — short model tag ("gaussian_rr", …)
#   d             :: Int                      — latent dimension K
#   n_traits      :: Int                      — p (rows of y)
#   n_units       :: Int                      — n (columns of y)
#   trait_names   :: Vector{String}          — preserved trait labels (length p)
#   unit_names    :: Vector{String}          — preserved unit labels (length n)
#   loadings      :: Matrix{Float64}         — p×d rotated loadings (Λ R)
#   alpha         :: Vector{Float64}         — per-trait intercept (length p;
#                                              link scale; NaN for Ordinal)
#   dispersion    :: Vector{Float64}         — per-trait nuisance (r/φ/α/σ where
#                                              the family carries one, else NaN)
#   sigma_eps     :: Float64                  — Gaussian residual SD (NaN otherwise)
#   Sigma         :: Matrix{Float64}         — p×p latent-scale trait covariance
#                                              (ΛΛᵀ + diag), rotation-invariant
#   correlation   :: Matrix{Float64}         — p×p latent-scale trait correlation
#   communality   :: Vector{Float64}         — per-trait communality c² (length p)
#   scores        :: Matrix{Float64}         — n×d conditional latent scores
#                                              (0×0 when unavailable)
#   loglik        :: Float64                  — marginal log-likelihood
#   aic, bic      :: Float64                  — information criteria
#   df            :: Int                      — free-parameter count used for AIC
#   nobs          :: Int                      — number of response cells (p·n)
#   converged     :: Bool                     — optimiser convergence flag
#   iterations    :: Int                      — optimiser iteration count
#   message       :: String                   — "converged" / "not converged"
#   link          :: Vector{String}          — per-trait link name (length p)
#   note          :: String                   — caveats for the R side
#
# Optional (opt-in via options["derived_ci"] = true; bootstrap is slow):
#   correlation_ci_lower, correlation_ci_upper :: Matrix{Float64} — percentile
#       bootstrap CI bounds for each off-diagonal `correlation[i, j]`
#       (diagonal = 1.0; NaN where a replicate target was not estimable)
#   correlation_ci_level   :: Float64         — the CI level used
#   correlation_ci_n_boot  :: Int             — bootstrap replicate count
#
# This file is ADDITIVE: it adds `src/bridge.jl` plus the include/export line in
# GLLVM.jl. It does NOT edit any fitter, extractor, or simulate file. It is
# included LAST so every dispatch target (fitters, extractors, simulate,
# bootstrap_ci_derived) already exists.

# ---------------------------------------------------------------------------
# Plain-data option / name helpers (self-contained; the sibling Gaussian-only
# `gllvm_bridge` primitive carries equivalents, but this worktree has no
# bridge.jl, so they are defined here).
# ---------------------------------------------------------------------------

# Default-or-validate a length-n label vector from an optional R-supplied one.
function _bridge_names(x, n::Integer, prefix::AbstractString)
    if x === nothing
        return ["$(prefix)$i" for i in 1:n]
    end
    names = String.(collect(x))
    length(names) == n ||
        throw(ArgumentError("$(prefix)_names length ($(length(names))) must equal $n"))
    return names
end

# Read `key` from a primitive options container (Dict, NamedTuple, or struct),
# accepting both String and Symbol keys; return `default` when absent.
function _bridge_get(options, key::AbstractString, default)
    options === nothing && return default
    if options isa AbstractDict
        for k in (key, Symbol(key))
            haskey(options, k) && return options[k]
        end
        return default
    end
    if options isa NamedTuple
        skey = Symbol(key)
        haskey(options, skey) && return getfield(options, skey)
        return default
    end
    if hasproperty(options, Symbol(key))
        return getproperty(options, Symbol(key))
    end
    return default
end

# ---------------------------------------------------------------------------
# Family-string -> (marker, fitter dispatch) resolution.
# ---------------------------------------------------------------------------

# Canonicalise an R-side family string to a lowercase key, accepting the common
# aliases the R side uses (gllvmTMB / glmmTMB naming).
function _bridge_family_key(family::AbstractString)
    key = lowercase(strip(family))
    if key in ("gaussian", "normal")
        return "gaussian"
    elseif key in ("poisson",)
        return "poisson"
    elseif key in ("binomial", "bernoulli")
        return "binomial"
    elseif key in ("negbinomial", "negative_binomial", "negativebinomial",
                   "nbinom2", "nb2", "negbin")
        return "negbinomial"
    elseif key in ("nb1", "nbinom1")
        return "nb1"
    elseif key in ("beta",)
        return "beta"
    elseif key in ("gamma",)
        return "gamma"
    elseif key in ("ordinal", "ordered")
        return "ordinal"
    elseif key in ("lognormal", "log_normal")
        return "lognormal"
    end
    throw(ArgumentError(
        "bridge_fit: unsupported family \"$family\"; supported one-part families " *
        "are gaussian, poisson, binomial, negbinomial (nbinom2), nb1, beta, " *
        "gamma, ordinal, lognormal (or pass a vector of family strings for a " *
        "mixed model)"))
end

# Per-key Distributions marker used to build the mixed per-trait family vector
# and to look up the canonical link / family label.
_bridge_family_marker(key::AbstractString) =
    key == "gaussian"    ? Normal() :
    key == "poisson"     ? Poisson() :
    key == "binomial"    ? Binomial() :
    key == "negbinomial" ? NegativeBinomial(10.0, 0.5) :
    key == "nb1"         ? NB1(1.0) :
    key == "beta"        ? Beta(10.0, 1.0) :
    key == "gamma"       ? Gamma(2.0, 1.0) :
    key == "ordinal"     ? Ordinal() :
    key == "lognormal"   ? LogNormal() :
    throw(ArgumentError("bridge_fit: no marker for family key \"$key\""))

# ---------------------------------------------------------------------------
# Flat-primitive helpers.
# ---------------------------------------------------------------------------

# Free-parameter count k for AIC/BIC, uniform across every fit type the bridge
# returns (including NB1Fit / LognormalFit / MixedFamilyFit, which carry no
# `_nparams` method). Loadings are counted modulo the K(K−1)/2 rotational df, to
# match the package's own `_nparams` convention.
_bridge_rr_df(p::Integer, K::Integer) = p * K - div(K * (K - 1), 2)

function _bridge_nparams(fit::GllvmFit)
    m = fit.model
    q = fit.pars.β === nothing ? 0 : length(fit.pars.β)
    k = q + 1                                   # fixed effects + σ_eps
    k += _bridge_rr_df(m.p, m.K)
    m.K_W > 0        && (k += _bridge_rr_df(m.p, m.K_W))
    m.has_diag       && (k += 2 * m.p)
    m.K_phy > 0      && (k += _bridge_rr_df(m.p, m.K_phy))
    m.has_phy_unique && (k += m.p)
    return k
end
_bridge_nparams(fit::PoissonFit)   = (p = size(fit.Λ, 1); p + _bridge_rr_df(p, size(fit.Λ, 2)))
_bridge_nparams(fit::BinomialFit)  = (p = size(fit.Λ, 1); p + _bridge_rr_df(p, size(fit.Λ, 2)))
_bridge_nparams(fit::NBFit)        = (p = size(fit.Λ, 1); p + _bridge_rr_df(p, size(fit.Λ, 2)) + 1)
_bridge_nparams(fit::NB1Fit)       = (p = size(fit.Λ, 1); p + _bridge_rr_df(p, size(fit.Λ, 2)) + 1)
_bridge_nparams(fit::BetaFit)      = (p = size(fit.Λ, 1); p + _bridge_rr_df(p, size(fit.Λ, 2)) + 1)
_bridge_nparams(fit::GammaFit)     = (p = size(fit.Λ, 1); p + _bridge_rr_df(p, size(fit.Λ, 2)) + 1)
_bridge_nparams(fit::LognormalFit) = (p = size(fit.Λ, 1); p + _bridge_rr_df(p, size(fit.Λ, 2)) + 1)
_bridge_nparams(fit::OrdinalFit)   = (p = size(fit.Λ, 1); (fit.C - 1) + _bridge_rr_df(p, size(fit.Λ, 2)))
function _bridge_nparams(fit::MixedFamilyFit)
    p, K = size(fit.Λ)
    return p + _bridge_rr_df(p, K) + fit.n_disp   # β + Λ + per-trait dispersions
end

# Maximised marginal log-likelihood, uniform across fit types.
_bridge_loglik(fit::GllvmFit) = fit.logLik
_bridge_loglik(fit) = fit.loglik

# Rotated p×d loadings (canonical SVD rotation), read straight from the struct so
# NB1Fit / LognormalFit (no `_loadings` method) are covered too.
_bridge_loadings_raw(fit::GllvmFit) = fit.pars.Λ
_bridge_loadings_raw(fit) = fit.Λ
function _bridge_loadings(fit)
    Λ = Matrix{Float64}(_bridge_loadings_raw(fit))
    return size(Λ, 2) == 0 ? Λ : Λ * _svd_rotation(Λ)
end

# Per-trait link name (length p) on the link scale.
_bridge_link_name(link::Link) = String(nameof(typeof(link)))

# ---------------------------------------------------------------------------
# Public entry point.
# ---------------------------------------------------------------------------

"""
    bridge_fit(; y, family, d, N=nothing, X=nothing,
               trait_names=nothing, unit_names=nothing, options=Dict())

Plain-data R→Julia bridge that fits a GLLVM for ANY supported family and returns
a flat, JuliaCall-convertible NamedTuple (see the file header for the full key →
type contract).

`y` is a `p×n` response matrix (traits × units). `family` is either a single
family string (`"gaussian"`, `"poisson"`, `"binomial"`, `"negbinomial"` /
`"nbinom2"`, `"nb1"`, `"beta"`, `"gamma"`, `"ordinal"`, `"lognormal"`) routed to
the matching one-part fitter, or a length-`p` vector of family strings routed to
`fit_mixed_gllvm` (one response family per trait, sharing one latent block).

`d` is the latent dimension `K`. `N` (Binomial trial counts, `p×n`) is forwarded
to the Binomial / mixed fitters. `X` (Gaussian fixed-effect covariates, a
`p×n×q` array) is forwarded to the Gaussian fitter only; non-Gaussian `X` is not
yet supported and raises a clear error. `options` is a primitive dictionary;
recognised keys are `iterations`, `x_tol`, `f_tol`, `g_tol` (Gaussian), and the
opt-in `derived_ci` bootstrap-CI block (see below).

Set `options["derived_ci"] = true` to attach a parametric-bootstrap percentile CI
for every off-diagonal `correlation[i, j]` (the headline cross-family quantity).
This is opt-in because the bootstrap refits the model `n_boot` times. Tune with
`options["derived_ci_n_boot"]` (default 200), `options["derived_ci_level"]`
(default 0.95), and `options["derived_ci_seed"]` (default 0). Bootstrap CIs are
available for the one-part non-Gaussian families and the mixed model; for the
Gaussian, NB1, and Lognormal fits the CI block is skipped with a note.
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

    if family isa AbstractVector
        return _bridge_fit_mixed(y, collect(String, family), K, N, X,
                                 trait_names, unit_names, options)
    else
        return _bridge_fit_onepart(y, _bridge_family_key(String(family)), K, N, X,
                                   trait_names, unit_names, options)
    end
end

# ---------------------------------------------------------------------------
# One-part (single-family) path.
# ---------------------------------------------------------------------------

function _bridge_fit_onepart(y, key::AbstractString, K::Integer, N, X,
                             trait_names, unit_names, options)
    Yf = Matrix{Float64}(y)
    p, n = size(Yf)
    traits = _bridge_names(trait_names, p, "trait")
    units = _bridge_names(unit_names, n, "unit")

    if X !== nothing && key != "gaussian"
        throw(ArgumentError(
            "bridge_fit: fixed-effect covariates X are only supported for the " *
            "Gaussian family (got family=\"$key\"); non-Gaussian X is deferred"))
    end

    # Dispatch to the matching fitter. `alpha`/`dispersion`/`scores` are built
    # per family from the fit struct.
    if key == "gaussian"
        return _bridge_gaussian(Yf, K, X, traits, units, options)
    elseif key == "poisson"
        Yi = round.(Int, Yf)
        fit = fit_poisson_gllvm(Yi; K = K)
        return _bridge_return(fit, Yi, key, "poisson_rr", traits, units;
                              alpha = fit.β, dispersion = fill(NaN, p),
                              link = fill(_bridge_link_name(fit.link), p),
                              options = options)
    elseif key == "binomial"
        Yi = round.(Int, Yf)
        Ni = N === nothing ? fill(1, p, n) : round.(Int, Matrix(N))
        fit = fit_binomial_gllvm(Yi; K = K, N = Ni)
        return _bridge_return(fit, Yi, key, "binomial_rr", traits, units;
                              alpha = fit.β, dispersion = fill(NaN, p),
                              link = fill(_bridge_link_name(fit.link), p), N = Ni,
                              options = options)
    elseif key == "negbinomial"
        Yi = round.(Int, Yf)
        fit = fit_nb_gllvm(Yi; K = K)
        return _bridge_return(fit, Yi, key, "negbinomial_rr", traits, units;
                              alpha = fit.β, dispersion = fill(fit.r, p),
                              link = fill(_bridge_link_name(fit.link), p),
                              options = options)
    elseif key == "nb1"
        Yi = round.(Int, Yf)
        fit = fit_nb1_gllvm(Yi; K = K)
        return _bridge_return(fit, Yi, key, "nb1_rr", traits, units;
                              alpha = fit.β, dispersion = fill(fit.φ, p),
                              link = fill(_bridge_link_name(fit.link), p),
                              options = options)
    elseif key == "beta"
        fit = fit_beta_gllvm(Yf; K = K)
        return _bridge_return(fit, Yf, key, "beta_rr", traits, units;
                              alpha = fit.β, dispersion = fill(fit.φ, p),
                              link = fill(_bridge_link_name(fit.link), p),
                              options = options)
    elseif key == "gamma"
        fit = fit_gamma_gllvm(Yf; K = K)
        return _bridge_return(fit, Yf, key, "gamma_rr", traits, units;
                              alpha = fit.β, dispersion = fill(fit.α, p),
                              link = fill(_bridge_link_name(fit.link), p),
                              options = options)
    elseif key == "ordinal"
        Yi = round.(Int, Yf)
        fit = fit_ordinal_gllvm(Yi; K = K)
        # No species intercept (common cutpoints carry the levels); alpha = NaN.
        return _bridge_return(fit, Yi, key, "ordinal_rr", traits, units;
                              alpha = fill(NaN, p), dispersion = fill(NaN, p),
                              link = fill(_bridge_link_name(fit.link), p),
                              options = options)
    elseif key == "lognormal"
        fit = fit_lognormal_gllvm(Yf; K = K)
        return _bridge_return(fit, Yf, key, "lognormal_rr", traits, units;
                              alpha = fit.β, dispersion = fill(fit.σ, p),
                              link = fill(_bridge_link_name(fit.link), p),
                              options = options)
    end
    throw(ArgumentError("bridge_fit: unhandled family key \"$key\""))  # unreachable
end

# Gaussian path: mirror gllvm_bridge's trait-centering intercept convention,
# return the closed-form Gaussian fit with optional fixed effects X.
function _bridge_gaussian(Yf::AbstractMatrix, K::Integer, X,
                          traits, units, options)
    p, n = size(Yf)
    iterations = Int(_bridge_get(options, "iterations", 500))
    x_tol = Float64(_bridge_get(options, "x_tol", 1e-8))
    f_tol = Float64(_bridge_get(options, "f_tol", 1e-10))
    g_tol = Float64(_bridge_get(options, "g_tol", 1e-6))

    if X === nothing
        # Row-center: alpha = per-trait mean; fit on the centred matrix.
        alpha = vec(Statistics.mean(Yf; dims = 2))
        Yc = Yf .- alpha
        fit = fit_gaussian_gllvm(Yc; K = K, iterations = iterations,
                                 x_tol = x_tol, f_tol = f_tol, g_tol = g_tol)
        scores = getLV(fit, Yc; rotate = true)
        return _bridge_return(fit, nothing, "gaussian", "gaussian_rr", traits, units;
                              alpha = alpha, dispersion = fill(NaN, p),
                              sigma_eps = fit.pars.σ_eps,
                              scores = scores,
                              link = fill("IdentityLink", p),
                              options = options)
    else
        Xa = Array{Float64,3}(X)
        size(Xa, 1) == p && size(Xa, 2) == n ||
            throw(ArgumentError("X must be p×n×q with p=$p, n=$n; got $(size(Xa))"))
        fit = fit_gaussian_gllvm(Yf; K = K, X = Xa, iterations = iterations,
                                 x_tol = x_tol, f_tol = f_tol, g_tol = g_tol)
        scores = getLV(fit, Yf; X = Xa, rotate = true)
        # With fixed effects the intercept lives in β; report the q coefficients
        # in `alpha` would be length-mismatched, so report the per-trait fitted
        # mean instead and keep β in `dispersion`-free metadata via note.
        β = fit.pars.β === nothing ? Float64[] : Vector{Float64}(fit.pars.β)
        alpha = vec(Statistics.mean(_fitted_mean(fit, Yf, Xa); dims = 2))
        return _bridge_return(fit, nothing, "gaussian", "gaussian_rr_fixef", traits, units;
                              alpha = alpha, dispersion = fill(NaN, p),
                              sigma_eps = fit.pars.σ_eps,
                              scores = scores,
                              link = fill("IdentityLink", p),
                              options = options,
                              note = "Gaussian fit with fixed effects: `alpha` is " *
                                     "the per-trait fitted mean of X·β (q=$(length(β)) " *
                                     "coefficients), not a single trait intercept.")
    end
end

# ---------------------------------------------------------------------------
# Mixed-family path.
# ---------------------------------------------------------------------------

function _bridge_fit_mixed(y, family_strs::AbstractVector{<:AbstractString},
                           K::Integer, N, X, trait_names, unit_names, options)
    Yf = Matrix{Float64}(y)
    p, n = size(Yf)
    length(family_strs) == p || throw(DimensionMismatch(
        "bridge_fit: mixed family vector has length $(length(family_strs)); " *
        "expected p = $p (one family string per trait/row)"))
    X === nothing || throw(ArgumentError(
        "bridge_fit: fixed-effect covariates X are not supported for mixed " *
        "models yet"))
    traits = _bridge_names(trait_names, p, "trait")
    units = _bridge_names(unit_names, n, "unit")

    keys = [_bridge_family_key(String(f)) for f in family_strs]
    any(==("ordinal"), keys) && throw(ArgumentError(
        "bridge_fit: Ordinal is not supported as a mixed-model trait (vector μ / " *
        "own mode-finder); it is a documented future lane"))
    any(==("nb1"), keys) && throw(ArgumentError(
        "bridge_fit: NB1 is not supported as a mixed-model trait; use negbinomial " *
        "(NB2) or fit NB1 as a single-family model"))
    any(==("lognormal"), keys) && throw(ArgumentError(
        "bridge_fit: Lognormal is not supported as a mixed-model trait; fit it as " *
        "a single-family model (or use gaussian on log-responses)"))
    fam_markers = [_bridge_family_marker(k) for k in keys]

    Ni = N === nothing ? ones(Int, p, n) : round.(Int, Matrix(N))
    fit = fit_mixed_gllvm(Yf; families = fam_markers, K = K, N = Ni)

    p_, K_ = size(fit.Λ)
    loadings = _bridge_loadings(fit)
    Sigma = sigma_y_site(fit, Yf; N = Ni)
    corr = correlation(fit, Yf; N = Ni)
    comm = communality(fit, Yf; N = Ni)
    scores = getLV(fit, Yf; N = Ni, rotate = true)
    ll = fit.loglik
    df = _bridge_nparams(fit)
    nobs = p * n
    families_out = [_bridge_canonical_family_name(keys[t]) for t in 1:p]
    links_out = [_bridge_link_name(fit.links[t]) for t in 1:p]

    base = (
        family       = "mixed",
        families     = families_out,
        model        = "mixed_rr",
        d            = K_,
        n_traits     = p_,
        n_units      = n,
        trait_names  = traits,
        unit_names   = units,
        loadings     = loadings,
        alpha        = Vector{Float64}(fit.β),
        dispersion   = Vector{Float64}(fit.dispersion),  # NaN where none
        sigma_eps    = NaN,
        Sigma        = Matrix{Float64}(Sigma),
        correlation  = Matrix{Float64}(corr),
        communality  = Vector{Float64}(comm),
        scores       = Matrix{Float64}(scores),
        loglik       = Float64(ll),
        aic          = 2 * df - 2 * ll,
        bic          = df * log(n) - 2 * ll,
        df           = df,
        nobs         = nobs,
        converged    = fit.converged,
        iterations   = fit.iterations,
        message      = fit.converged ? "converged" : "not converged",
        link         = links_out,
        note         = "mixed-family GLLVM: one shared latent block, per-trait " *
                       "response family; `correlation` is the cross-family " *
                       "latent-scale trait correlation.",
    )
    return _bridge_maybe_attach_ci(base, fit, Yf, corr, Ni, options)
end

_bridge_canonical_family_name(key::AbstractString) =
    key == "negbinomial" ? "negbinomial" : key

# ---------------------------------------------------------------------------
# Shared return assembler for the one-part fits.
# ---------------------------------------------------------------------------

# Build the flat NamedTuple for a one-part fit. `Ydata` is the response matrix
# the latent-scale extractors need (Int for discrete families, Float64 for
# continuous); `nothing` for the Gaussian path (its extractors take no Y).
function _bridge_return(fit, Ydata, family::AbstractString, model::AbstractString,
                        traits, units;
                        alpha::AbstractVector,
                        dispersion::AbstractVector,
                        link::AbstractVector,
                        sigma_eps::Real = NaN,
                        scores = nothing,
                        N = nothing,
                        note::AbstractString = "",
                        options = nothing)
    p = size(_bridge_loadings_raw(fit), 1)
    n = length(units)
    K = size(_bridge_loadings_raw(fit), 2)
    loadings = _bridge_loadings(fit)
    ll = _bridge_loglik(fit)
    df = _bridge_nparams(fit)
    nobs = p * n
    iters = fit isa GllvmFit ? fit.n_iter : fit.iterations

    Sigma, corr, comm, sc, used_note = _bridge_derived(fit, Ydata, N, scores, note)

    base = (
        family       = family,
        families     = fill(family, p),
        model        = model,
        d            = K,
        n_traits     = p,
        n_units      = n,
        trait_names  = traits,
        unit_names   = units,
        loadings     = loadings,
        alpha        = Vector{Float64}(alpha),
        dispersion   = Vector{Float64}(dispersion),
        sigma_eps    = Float64(sigma_eps),
        Sigma        = Sigma,
        correlation  = corr,
        communality  = comm,
        scores       = sc,
        loglik       = Float64(ll),
        aic          = 2 * df - 2 * ll,
        bic          = df * log(n) - 2 * ll,
        df           = df,
        nobs         = nobs,
        converged    = fit.converged,
        iterations   = iters,
        message      = fit.converged ? "converged" : "not converged",
        link         = Vector{String}(link),
        note         = used_note,
    )
    # Ydata is the matrix the bootstrap refit/extractor need (Int for discrete
    # families, Float64 for continuous; `nothing` for Gaussian — the no-op CI
    # default fires there). N threads Binomial trial counts.
    return _bridge_maybe_attach_ci(base, fit, Ydata, corr, N, options)
end

# Latent-scale derived quantities (Sigma / correlation / communality / scores)
# for a one-part fit. Gaussian uses the no-Y extractors; the non-Gaussian
# families that have extractors use the Y-form; NB1 / Lognormal have none, so we
# fall back to the bare ΛΛᵀ-with-no-residual correlation and a note.
function _bridge_derived(fit::GllvmFit, ::Any, ::Any, scores, note)
    Sigma = Matrix{Float64}(sigma_y_site(fit))
    corr = Matrix{Float64}(correlation(fit))
    comm = Vector{Float64}(communality(fit))
    sc = scores === nothing ? zeros(Float64, 0, 0) : Matrix{Float64}(scores)
    return Sigma, corr, comm, sc, note
end

function _bridge_derived(fit::Union{PoissonFit, NBFit, BetaFit, GammaFit},
                         Ydata::AbstractMatrix, ::Any, scores, note)
    Sigma = Matrix{Float64}(sigma_y_site(fit, Ydata))
    corr = Matrix{Float64}(correlation(fit, Ydata))
    comm = Vector{Float64}(communality(fit, Ydata))
    sc = Matrix{Float64}(getLV(fit, Ydata; rotate = true))
    return Sigma, corr, comm, sc, note
end

function _bridge_derived(fit::BinomialFit, Ydata::AbstractMatrix, N, scores, note)
    Sigma = Matrix{Float64}(sigma_y_site(fit, Ydata; N = N))
    corr = Matrix{Float64}(correlation(fit, Ydata; N = N))
    comm = Vector{Float64}(communality(fit, Ydata; N = N))
    sc = Matrix{Float64}(getLV(fit, Ydata; N = N, rotate = true))
    return Sigma, corr, comm, sc, note
end

function _bridge_derived(fit::OrdinalFit, Ydata::AbstractMatrix, ::Any, scores, note)
    Sigma = Matrix{Float64}(sigma_y_site(fit, Ydata))
    corr = Matrix{Float64}(correlation(fit, Ydata))
    comm = Vector{Float64}(communality(fit, Ydata))
    sc = Matrix{Float64}(getLV(fit, Ydata; rotate = true))
    return Sigma, corr, comm, sc, note
end

# NB1 / Lognormal: no latent-scale link-residual extractor is defined. Report the
# pure shared covariance Σ = ΛΛᵀ (plus σ² on the diagonal for Lognormal, on the
# log scale) and the correlation it induces, flagged in the note.
function _bridge_derived(fit::NB1Fit, Ydata::AbstractMatrix, ::Any, scores, note)
    Λ = Matrix{Float64}(fit.Λ)
    Sigma = Λ * Λ'
    Sigma = (Sigma + Sigma') ./ 2
    corr = _bridge_corr_from_sigma(Sigma)
    comm = ones(Float64, size(Λ, 1))             # no residual term ⇒ c² = 1
    sc = zeros(Float64, 0, 0)                     # no getLV(::NB1Fit) method
    n = note == "" ? "" : note * " "
    n *= "NB1 has no latent-scale link-residual extractor; `Sigma`/`correlation` " *
         "use the shared block ΛΛᵀ only (no overdispersion residual added), " *
         "`communality` is 1, and `scores` is empty."
    return Sigma, corr, comm, sc, n
end

function _bridge_derived(fit::LognormalFit, Ydata::AbstractMatrix, ::Any, scores, note)
    Λ = Matrix{Float64}(fit.Λ)
    p = size(Λ, 1)
    Sigma = Λ * Λ' + (fit.σ^2) .* Matrix{Float64}(I, p, p)   # log-scale covariance
    Sigma = (Sigma + Sigma') ./ 2
    corr = _bridge_corr_from_sigma(Sigma)
    ΛΛt = Λ * Λ'
    comm = [ΛΛt[t, t] / Sigma[t, t] for t in 1:p]
    sc = zeros(Float64, 0, 0)                     # no getLV(::LognormalFit) method
    n = note == "" ? "" : note * " "
    n *= "Lognormal `Sigma`/`correlation`/`communality` are on the LOG scale " *
         "(ΛΛᵀ + σ²I); `scores` is empty (no getLV(::LognormalFit) method)."
    return Sigma, corr, comm, sc, n
end

function _bridge_corr_from_sigma(Σ::AbstractMatrix)
    p = size(Σ, 1)
    R = Matrix{Float64}(undef, p, p)
    @inbounds for j in 1:p, i in 1:p
        denom = sqrt(Σ[i, i] * Σ[j, j])
        R[i, j] = denom > 0 ? Σ[i, j] / denom : (i == j ? 1.0 : 0.0)
    end
    return R
end

# ---------------------------------------------------------------------------
# Optional bootstrap CI for the cross-family correlation (opt-in).
# ---------------------------------------------------------------------------

# Attach correlation-CI keys when options["derived_ci"] == true and the fit type
# supports the family-dispatched bootstrap (one-part non-Gaussian + mixed). Other
# fits get the keys with a skip note rather than a hard failure, so the contract
# stays uniform.
const _BridgeBootCIFit =
    Union{PoissonFit, NBFit, BetaFit, GammaFit, BinomialFit, OrdinalFit, MixedFamilyFit}

function _bridge_maybe_attach_ci(base::NamedTuple, fit, Ydata, corr, N, options)
    Bool(_bridge_get(options, "derived_ci", false)) || return base
    return _bridge_attach_ci(base, fit, Ydata, corr, N, options)
end

# Default no-op for fit types without a family-dispatched bootstrap.
function _bridge_attach_ci(base::NamedTuple, fit, Ydata, corr, N, options)
    note = base.note == "" ? "" : base.note * " "
    note *= "derived_ci requested but bootstrap CIs are not available for this " *
            "fit type (Gaussian/NB1/Lognormal); correlation CI skipped."
    return merge(base, (note = note,))
end

function _bridge_attach_ci(base::NamedTuple, fit::_BridgeBootCIFit,
                           Ydata::AbstractMatrix, corr::AbstractMatrix, N, options)
    n_boot = Int(_bridge_get(options, "derived_ci_n_boot", 200))
    level = Float64(_bridge_get(options, "derived_ci_level", 0.95))
    seed = Int(_bridge_get(options, "derived_ci_seed", 0))
    p = size(corr, 1)
    lower = Matrix{Float64}(undef, p, p)
    upper = Matrix{Float64}(undef, p, p)
    @inbounds for i in 1:p
        lower[i, i] = 1.0
        upper[i, i] = 1.0
    end
    @inbounds for j in 1:p, i in 1:p
        i < j || continue
        ci = correlation_boot_ci(fit, i, j; Y = Ydata, n_boot = n_boot,
                                 level = level, seed = seed, N = N)
        lower[i, j] = ci.lower; lower[j, i] = ci.lower
        upper[i, j] = ci.upper; upper[j, i] = ci.upper
    end
    note = base.note == "" ? "" : base.note * " "
    note *= "correlation_ci_* are parametric-bootstrap percentile CIs " *
            "($(n_boot) replicates, level $(level)) for each off-diagonal " *
            "correlation entry."
    return merge(base, (
        correlation_ci_lower  = lower,
        correlation_ci_upper  = upper,
        correlation_ci_level  = level,
        correlation_ci_n_boot = n_boot,
        note                  = note,
    ))
end
