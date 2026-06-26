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
#   dispersion_group        :: Vector{Float64} — optional grouped-dispersion values
#   dispersion_group_id     :: Vector{Int}     — optional per-trait group id
#   dispersion_parameter    :: String          — optional engine parameter name
#   dispersion_engine_scale :: String          — optional engine variance rule
#   dispersion_public_scale :: String          — optional R/gllvmTMB public map
#   sigma_eps    :: Float64           — Gaussian residual SD (NaN otherwise)
#   Sigma        :: Matrix{Float64}   — p x p latent-scale trait covariance
#   correlation  :: Matrix{Float64}   — p x p latent-scale trait correlation
#   communality  :: Vector{Float64}   — per-trait communality c^2 (length p)
#   scores       :: Matrix{Float64}   — n x d latent scores (0x0 if unavailable)
#   loglik       :: Float64
#   aic, bic     :: Float64
#   df           :: Int               — free-parameter count for AIC
#   nobs         :: Int               — observed cells (p*n for complete data)
#   converged    :: Bool
#   iterations   :: Int
#   message      :: String
#   link         :: Vector{String}    — per-trait link name
#   note         :: String            — caveats for the R side
#
# Optional coefficient keys:
#   mean_coef    :: Vector{Float64}   — Gaussian-X full mean coefficient vector
#   mean_coef_status :: Vector{String} — "estimated"/"fixed" for mean_coef
#   beta_cov     :: Vector{Float64}   — non-Gaussian-X per-trait intercepts
#   gamma        :: Vector{Float64}   — non-Gaussian-X shared covariate slopes
#   gamma_status :: Vector{String}    — "estimated"/"fixed" for gamma
#
# Optional predictor-informed latent-score keys:
#   lv_effects        :: Matrix{Float64} — Gaussian-X_lv trait effects Λ*alpha_lv'
#   alpha_lv          :: Matrix{Float64} — raw q_lv x d latent-axis coefficients
#   scores_mean       :: Matrix{Float64} — n x d rotated score mean X_lv*alpha_lv
#   scores_innovation :: Matrix{Float64} — n x d rotated posterior innovation scores
#
# Optional CI keys (present ONLY when `options["ci_method"]` ∈ {"wald","profile",
# "bootstrap"}; absent for the default "none", so the no-CI contract above is
# byte-identical to before):
#   ci_method      :: String          — the method actually run
#   ci_level       :: Float64         — nominal coverage (default 0.95)
#   ci_param_names :: Vector{String}  — term names (engine-native ordering)
#   ci_estimate    :: Vector{Float64} — point estimates (raw scale for dispersions)
#   ci_lower       :: Vector{Float64} — lower CI bounds
#   ci_upper       :: Vector{Float64} — upper CI bounds
#   ci_note        :: String          — caveats (empty unless CIs were skipped)
#
# v1 scope: the one-part families main provides a fitter for (gaussian,
# poisson, binomial, negbinomial/nb2, nb1, beta, gamma, ordinal,
# ordinal_probit). For the Gaussian fit the
# latent-scale Sigma/correlation/communality use the package extractors; for the
# non-Gaussian fits they use the self-contained shared-block (Lambda*Lambda') form,
# pending the salvage of the link-residual table + non-Gaussian extractors (then the
# cross-family correlation gains its distribution-specific residual). A `family`
# VECTOR routes to the MIXED-family path (fit_mixed_gllvm): one shared latent block
# across distinct response families, with the cross-distribution latent-scale
# `correlation` as the headline. Lognormal is a documented follow-up; fixed-effect
# X is wired (Gaussian); predictor-informed latent-score X_lv is wired for the
# ordinary complete-response Gaussian bridge as a point-estimate-only C1 route.
# Confidence intervals (Wald / profile / bootstrap) route
# through `options["ci_method"]` for scalar-CI one-part families (Gaussian,
# Poisson, Binomial) and grouped-dispersion NB2/NB1/Beta/Gamma rows. NB2, NB1,
# and Beta default to per-trait grouped
# dispersion for R-twin parity. Gamma uses the same grouped engine with one
# shared group, matching current native gllvmTMB's scalar-CV Gamma oracle until
# a native per-trait Gamma expansion lands. Ordinal/ordinal_probit default to
# per-trait cutpoints; these cutpoint routes currently reject CI routing loudly
# until matching CI engines land. Mixed-family and REML paths skip-with-note
# since their fits have no native confint engine yet.
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

# Truthy coercion for bridge option flags coming from R/JuliaCall, where a logical
# may arrive as Bool `true`, integer `1`, or the string "true"/"TRUE".
_bridge_truthy(v::Bool) = v
_bridge_truthy(v::Real) = v != 0
_bridge_truthy(v::AbstractString) = lowercase(strip(v)) in ("true", "t", "1", "yes")
_bridge_truthy(::Nothing) = false
_bridge_truthy(v) = false

function _bridge_coef_fixed(options, q::Integer, label::AbstractString)
    raw = _bridge_get(options, "coef_fixed", nothing)
    raw === nothing && (raw = _bridge_get(options, "xcoef_fixed", nothing))
    raw === nothing && (raw = _bridge_get(options, "beta_fixed", nothing))
    raw === nothing && (raw = _bridge_get(options, "gamma_fixed", nothing))
    return _fixed_zero_mask(raw, q, label)
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
    key in ("ordinal_probit", "ordered_probit")                     && return "ordinal_probit"
    throw(ArgumentError(
        "bridge_fit: unsupported family \"$family\"; this engine build supports " *
        "gaussian, poisson, binomial, negbinomial (nbinom2), nb1, beta, gamma, ordinal, ordinal_probit"))
end

const _BRIDGE_ONEPART_FAMILIES = (
    "gaussian",
    "poisson",
    "binomial",
    "negbinomial",
    "nb1",
    "beta",
    "gamma",
    "ordinal",
    "ordinal_probit",
)

# One-part NON-Gaussian families `fit_gllvm_cov` fits with covariates X (it has a
# `_cov_*` kernel for each). Ordinal and NB1 are absent — no covariate kernel yet.
const _BRIDGE_X_FAMILIES = ("poisson", "binomial", "negbinomial", "beta", "gamma")

# Map a bridge family key to the `Distributions` marker `fit_gllvm_cov` dispatches
# on (the dispersion field is re-estimated, so the init values here are irrelevant).
function _bridge_cov_marker(key::AbstractString)
    key == "poisson"     && return Poisson()
    key == "binomial"    && return Binomial()
    key == "negbinomial" && return NegativeBinomial(10.0, 0.5)
    key == "beta"        && return Beta(10.0, 1.0)
    key == "gamma"       && return Gamma(2.0, 1.0)
    throw(ArgumentError(
        "bridge_fit: family key \"$key\" has no covariate (X) fitter; " *
        "X is supported for " * join(_BRIDGE_X_FAMILIES, ", ")))
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

# --- confidence-interval routing -------------------------------------------
#
# Optionally route Wald / profile-likelihood / parametric-bootstrap CIs through
# the bridge by reusing the NATIVE CI engines on the fit object the bridge
# already produced — no CI math is re-implemented here. Controlled by the
# `ci_method` option (default "none", so existing callers are unchanged):
#
#   "none"      — no CIs (the default; the flat contract is byte-identical).
#   "wald"      — observed-information Wald intervals.
#   "profile"   — profile-likelihood (LRT inversion) intervals.
#   "bootstrap" — parametric bootstrap (fixed seed → reproducible).
#
# The returned CI fields are FLAT, JuliaCall-convertible arrays merged onto the
# base contract: ci_method::String, ci_level::Float64, ci_param_names,
# ci_estimate, ci_lower, ci_upper (Vector{Float64}), and ci_note::String.

const _BRIDGE_CI_METHODS = ("none", "wald", "profile", "bootstrap")

function _bridge_ci_method(options)
    raw = _bridge_get(options, "ci_method", "none")
    m = lowercase(strip(String(raw)))
    m in _BRIDGE_CI_METHODS || throw(ArgumentError(
        "bridge_fit: unsupported ci_method \"$raw\"; use one of " *
        join(_BRIDGE_CI_METHODS, ", ")))
    return m
end

_bridge_ci_level(options) = Float64(_bridge_get(options, "ci_level", 0.95))
_bridge_ci_nboot(options) = Int(_bridge_get(options, "ci_nboot", 200))
_bridge_ci_seed(options)  = Int(_bridge_get(options, "ci_seed", 0))

# Empty CI payload (the "none" default and the skip-with-note cases).
function _bridge_ci_payload(method::AbstractString, level::Real, note::AbstractString)
    return (
        ci_method      = String(method),
        ci_level       = Float64(level),
        ci_param_names = String[],
        ci_estimate    = Float64[],
        ci_lower       = Float64[],
        ci_upper       = Float64[],
        ci_note        = String(note),
    )
end

# Build the CI payload from a native CI NamedTuple (term/estimate/lower/upper).
function _bridge_ci_from_native(method::AbstractString, level::Real, ci;
                                note::AbstractString = "")
    return (
        ci_method      = String(method),
        ci_level       = Float64(level),
        ci_param_names = Vector{String}(ci.term),
        ci_estimate    = Vector{Float64}(ci.estimate),
        ci_lower       = Vector{Float64}(ci.lower),
        ci_upper       = Vector{Float64}(ci.upper),
        ci_note        = String(note),
    )
end

# Non-Gaussian one-part families (PoissonFit/BinomialFit/...): the
# unified confint(fit, Y; method, level, N, mask, n_boot, seed) covers all three
# methods, so route every method through it directly.
function _bridge_compute_ci_ng(fit, Ydata, N, method::AbstractString,
                               level::Real, nboot::Integer, seed::Integer;
                               mask = nothing)
    method == "none" && return _bridge_ci_payload("none", level, "")
    msym = method == "wald" ? :wald : (method == "profile" ? :profile : :bootstrap)
    ci = confint(fit, Ydata; method = msym, level = level, N = N,
                 mask = mask, n_boot = nboot, seed = seed)
    return _bridge_ci_from_native(method, level, ci)
end

function _bridge_compute_ci_cov(fit::GllvmCovFit, Ydata, N, X,
                                method::AbstractString, level::Real,
                                nboot::Integer, seed::Integer)
    method == "none" && return _bridge_ci_payload("none", level, "")
    msym = method == "wald" ? :wald : (method == "profile" ? :profile : :bootstrap)
    ci = confint(fit, Ydata; method = msym, level = level, N = N, X = X,
                 n_boot = nboot, seed = seed)
    return _bridge_ci_from_native(method, level, ci)
end

# Gaussian fit (GllvmFit): the three native engines have distinct signatures, so
# normalise each to a (term, estimate, lower, upper) table.
#   - wald      → confint(fit; y, level)
#   - profile   → loop profile_ci(fit, i; y, level) over the packed params,
#                 borrowing the Wald estimate vector for ci_estimate (raw scale,
#                 term-aligned by construction).
#   - bootstrap → bootstrap_ci(fit; y, n_boot, level, seed)
# A GllvmFit with an empty packed vector (e.g. the REML synthetic fit) has no
# observed-information / profile substrate — skip with a note rather than fake.
function _bridge_compute_ci_gaussian(fit::GllvmFit, ydata, method::AbstractString,
                                     level::Real, nboot::Integer, seed::Integer;
                                     X = nothing)
    method == "none" && return _bridge_ci_payload("none", level, "")
    if isempty(fit.pars.θ_packed)
        return _bridge_ci_payload(method, level,
            "CIs are not routed for this Gaussian fit (no packed parameter " *
            "vector, e.g. a REML fit); a documented follow-up.")
    end
    if method == "wald"
        ci = confint(fit; y = ydata, level = level, X = X)
        return _bridge_ci_from_native("wald", level, ci)
    elseif method == "bootstrap"
        ci = bootstrap_ci(fit; y = ydata, n_boot = nboot, level = level, seed = seed, X = X)
        return _bridge_ci_from_native("bootstrap", level, ci)
    else  # profile
        wald = confint(fit; y = ydata, level = level, X = X)  # term names + estimates
        lo = Float64[]; hi = Float64[]
        for i in 1:length(fit.pars.θ_packed)
            pc = profile_ci(fit, i; y = ydata, level = level, X = X)
            push!(lo, pc.lower); push!(hi, pc.upper)
        end
        return (
            ci_method      = "profile",
            ci_level       = Float64(level),
            ci_param_names = Vector{String}(wald.term),
            ci_estimate    = Vector{Float64}(wald.estimate),
            ci_lower       = lo,
            ci_upper       = hi,
            ci_note        = "",
        )
    end
end

# --- public entry point ----------------------------------------------------

"""
    bridge_fit(; y, family, d=1, N=nothing, X=nothing, X_lv=nothing,
               trait_names=nothing, unit_names=nothing, options=Dict())

Plain-data R->Julia bridge (JuliaCall transport). Fits a one-part GLLVM for the
requested `family` and returns a flat, JuliaCall-convertible NamedTuple (see the
file header for the key->type contract). `y` is a `p x n` response matrix
(traits x units); `d` is the latent dimension `K`; `N` (Binomial trials, `p x n`
or a scalar) is forwarded to the Binomial fitter.

Confidence intervals are routed through `options` (all optional):
  - `"ci_method"` ∈ {`"none"` (default), `"wald"`, `"profile"`, `"bootstrap"`}.
    When not `"none"`, the returned tuple gains the `ci_*` keys documented in the
    file header. These reuse the NATIVE confint / profile_ci / bootstrap_ci
    engines on the fit object the bridge already produced (no CI math is
    re-implemented), so bounds are identical to the equivalent native call.
  - `"ci_level"` — nominal coverage (default `0.95`).
  - `"ci_nboot"` — bootstrap replicates (default `200`).
  - `"ci_seed"`  — bootstrap RNG seed (default `0`; fixed → reproducible).
"""
function bridge_fit(; y,
                    family,
                    d::Integer = 1,
                    N = nothing,
                    X = nothing,
                    X_lv = nothing,
                    mask = nothing,
                    trait_names = nothing,
                    unit_names = nothing,
                    options = Dict{String,Any}())
    K = Int(d)
    K >= 0 || throw(ArgumentError("d must be a non-negative integer"))
    # Fixed-effect covariates X (a p×n×q array) are wired for the Gaussian family
    # and the one-part NON-Gaussian families that `fit_gllvm_cov` fits (poisson,
    # binomial, negbinomial, beta, gamma): fit_gaussian_gllvm / fit_gllvm_cov carry
    # the covariate mean structure η = β + Xγ (+ Λz) and return the coefficients.
    # Ordinal and NB1 (no covariate kernel) and the mixed-family path remain a
    # documented follow-up — reject loudly rather than silently dropping X.
    if X !== nothing
        if family isa AbstractVector
            throw(ArgumentError(
                "bridge_fit: fixed-effect covariates X are not yet wired for the " *
                "mixed-family path; a documented follow-up"))
        end
        key = _bridge_family_key(String(family))
        (key == "gaussian" || key in _BRIDGE_X_FAMILIES) || throw(ArgumentError(
            "bridge_fit: fixed-effect covariates X are wired for family ∈ {gaussian, " *
            join(_BRIDGE_X_FAMILIES, ", ") * "}; family=\"$(family)\" has no covariate " *
                "fitter (ordinal/nb1 are a documented follow-up)"))
    end
    # Predictor-informed latent-score covariates are narrower than ordinary
    # fixed-effect X in this bridge slice: complete Gaussian point estimates only.
    # The native Gaussian fitter can be widened later, but the bridge contract
    # should not silently imply non-Gaussian or mixed-family parity.
    if X_lv !== nothing
        if family isa AbstractVector
            throw(ArgumentError(
                "bridge_fit: predictor-informed latent-score covariates X_lv " *
                "are not yet wired for the mixed-family path; use family=\"gaussian\"."))
        end
        key = _bridge_family_key(String(family))
        key == "gaussian" || throw(ArgumentError(
            "bridge_fit: predictor-informed latent-score covariates X_lv are " *
            "currently wired only for family=\"gaussian\"; family=\"$(family)\" " *
            "is a separate validation gate."))
        X === nothing || throw(ArgumentError(
            "bridge_fit: simultaneous fixed-effect X and latent-score X_lv is " *
            "not admitted in the bridge yet; fit one mean route at a time."))
    end
    # Mixed-family: a vector of per-trait family strings ⇒ one shared latent block,
    # a TRUE cross-distribution VCV (the headline). A length-1 vector or an all-same
    # vector still routes here (the mixed fitter handles the degenerate one-family
    # case); the cross-family `correlation` is the contract's headline field.
    if family isa AbstractVector
        mask === nothing || throw(ArgumentError(
            "bridge_fit: missing-response masks are not yet wired for the " *
            "mixed-family path; use a one-part non-Gaussian family or engine='tmb'."))
        X_lv === nothing || throw(ArgumentError(
            "bridge_fit: X_lv is not wired for the mixed-family path."))
        return _bridge_fit_mixed(y, collect(String, String.(family)), K, N,
                                 trait_names, unit_names, options)
    end
    return _bridge_fit_onepart(y, _bridge_family_key(String(family)), K, N,
                               trait_names, unit_names, options;
                               X = X, X_lv = X_lv, mask = mask)
end

# --- one-part dispatch -----------------------------------------------------

const _BRIDGE_MASK_FAMILIES = (
    "poisson", "binomial", "negbinomial", "nb1", "beta", "gamma", "ordinal",
    "ordinal_probit",
)

const _BRIDGE_GROUPED_DISPERSION_FAMILIES = ("negbinomial", "nb1", "beta", "gamma")
const _BRIDGE_PERTRAIT_ORDINAL_FAMILIES = ("ordinal", "ordinal_probit")
const _BRIDGE_MASK_CI_FAMILIES = (
    "poisson", "binomial", "negbinomial", "nb1", "beta", "gamma",
)

function _bridge_ci_guard_pertrait_ordinal(key::AbstractString, ci_method::AbstractString)
    ci_method == "none" && return nothing
    throw(ArgumentError(
        "bridge_fit: confidence intervals for per-trait ordinal-cutpoint " *
        "$key fits are not routed yet; use ci_method=\"none\" or the shared-" *
        "cutpoint OrdinalFit directly as a Julia-side comparator."))
end

function _bridge_dispersion_payload(group_values::AbstractVector,
                                    group_id::AbstractVector{<:Integer},
                                    parameter::AbstractString,
                                    engine_scale::AbstractString,
                                    public_scale::AbstractString)
    g = collect(Float64, group_values)
    gid = collect(Int, group_id)
    return (
        dispersion_group = g,
        dispersion_group_id = gid,
        dispersion_parameter = String(parameter),
        dispersion_engine_scale = String(engine_scale),
        dispersion_public_scale = String(public_scale),
    )
end

_bridge_expand_dispersion(payload) =
    [payload.dispersion_group[g] for g in payload.dispersion_group_id]

_bridge_group_df(p::Integer, K::Integer, payload) =
    p + _bridge_rr_df(p, K) + length(payload.dispersion_group)

"""
    bridge_capabilities()

Return the flat capability surface currently exposed by `bridge_fit`.

The result is a JuliaCall-friendly `NamedTuple` of vectors. It reports the
Julia bridge surface only; R-side admission gates may be narrower until
metadata, labels, parity rows, and confidence-interval status rows are
validated in `gllvmTMB`.

The `ci_no_x_*` columns report that a native route exists for complete one-part
no-covariate fits. The `ci_mask_*` columns are narrower: no-covariate one-part
response-mask fits whose masked likelihood can also drive Wald/profile/bootstrap
intervals. The `ci_x_*` columns are complete-response one-part fixed-effect-X
fits. `predictor_informed_lv` marks the point-estimate-only Gaussian X_lv bridge
route; it does not imply confidence intervals or non-Gaussian parity. None of
the CI groups imply mixed-family or R-bridge parity coverage. Use `status` and
`notes` for public claim wording.
"""
function bridge_capabilities()
    onepart = collect(_BRIDGE_ONEPART_FAMILIES)
    family = vcat(onepart, ["mixed-family vector"])
    x_families = Set(vcat(["gaussian"], collect(_BRIDGE_X_FAMILIES)))
    xlv_families = Set(["gaussian"])
    mask_families = Set(_BRIDGE_MASK_FAMILIES)
    mask_ci_families = Set(_BRIDGE_MASK_CI_FAMILIES)
    # Scalar-mean post-fit (residuals = y − μ, parametric simulate) excludes the
    # ordinal families (no scalar response mean). predict() IS wired for ordinal
    # via the cutpoints payload (type "prob"/"class"), so it uses every one-part
    # family.
    postfit_families = Set(filter(f -> !(f in ("ordinal", "ordinal_probit")), onepart))
    predict_families = Set(onepart)

    return (
        family = family,
        fit_no_x = vcat(fill(true, length(onepart)), [true]),
        fixed_effect_X = vcat([f in x_families for f in onepart], [false]),
        predictor_informed_lv = vcat([f in xlv_families for f in onepart], [false]),
        missing_response = vcat([f in mask_families for f in onepart], [false]),
        cbind_binomial = [f == "binomial" for f in family],
        ci_no_x_wald = vcat([!(f in _BRIDGE_PERTRAIT_ORDINAL_FAMILIES) for f in onepart], [false]),
        ci_no_x_profile = vcat([!(f in _BRIDGE_PERTRAIT_ORDINAL_FAMILIES) for f in onepart], [false]),
        ci_no_x_bootstrap = vcat([!(f in _BRIDGE_PERTRAIT_ORDINAL_FAMILIES) for f in onepart], [false]),
        ci_mask_wald = vcat([f in mask_ci_families for f in onepart], [false]),
        ci_mask_profile = vcat([f in mask_ci_families for f in onepart], [false]),
        ci_mask_bootstrap = vcat([f in mask_ci_families for f in onepart], [false]),
        ci_x_wald = vcat([f in x_families for f in onepart], [false]),
        ci_x_profile = vcat([f in x_families for f in onepart], [false]),
        ci_x_bootstrap = vcat([f in x_families for f in onepart], [false]),
        postfit_coef = vcat(fill(true, length(onepart)), [true]),
        postfit_fit_stats = vcat(fill(true, length(onepart)), [true]),
        postfit_summary = vcat(fill(true, length(onepart)), [true]),
        postfit_predict = vcat([f in predict_families for f in onepart], [true]),
        postfit_residuals = vcat([f in postfit_families for f in onepart], [true]),
        postfit_simulate = vcat([f in postfit_families for f in onepart], [true]),
        postfit_ordination = vcat(fill(true, length(onepart)), [true]),
        status = vcat(fill("partial", length(onepart)), ["partial"]),
        notes = vcat(
            [
                f in ("negbinomial", "beta") ?
                    "one-part reduced-rank bridge family; default no-X route uses per-trait grouped dispersion; no-X, masked no-X, and complete-response fixed-effect-X Wald/profile/bootstrap CI payloads are routed" :
                f == "nb1" ?
                    "one-part reduced-rank bridge family; default no-X route uses per-trait grouped dispersion; no-X and masked no-X Wald/profile/bootstrap CI payloads are routed; fixed-effect-X remains a follow-up" :
                f == "gamma" ?
                    "one-part reduced-rank bridge family; default no-X route uses shared Gamma grouped dispersion to match current native scalar-CV Gamma; no-X, masked no-X, and complete-response fixed-effect-X Wald/profile/bootstrap CI payloads are routed; per-trait Gamma is a native-expansion follow-up" :
                f in _BRIDGE_PERTRAIT_ORDINAL_FAMILIES ?
                    "one-part reduced-rank bridge family; default no-X route uses per-trait ordinal cutpoints; CI routing is a follow-up" :
                f in _BRIDGE_MASK_CI_FAMILIES ?
                    "one-part reduced-rank bridge family; no-X, masked no-X, and complete-response fixed-effect-X Wald/profile/bootstrap CI payloads are routed; route support is narrower than full R-user parity" :
                f == "gaussian" ?
                    "one-part reduced-rank bridge family; fixed-effect-X and point-estimate predictor-informed latent-score X_lv routes are wired; X_lv CIs and non-Gaussian X_lv remain follow-ups; route support is narrower than full R-user parity" :
                    "one-part reduced-rank bridge family; route support is narrower than full R-user parity"
                for f in onepart
            ],
            ["mixed-family vector route; no X, mask, or CI routing"],
        ),
    )
end

function _bridge_mask(mask, p::Integer, n::Integer)
    mask === nothing && return nothing
    M = Matrix{Bool}(mask)
    size(M) == (p, n) || throw(ArgumentError(
        "bridge_fit: mask must be p×n ($(p)×$(n)); got $(size(M))"))
    all(M) && return nothing
    any(M) || throw(ArgumentError(
        "bridge_fit: mask has no observed cells; at least one response must be observed"))
    return M
end

function _bridge_fit_onepart(y, key::AbstractString, K::Integer, N,
                             trait_names, unit_names, options;
                             X = nothing, X_lv = nothing, mask = nothing)
    Yf = Matrix{Float64}(y)
    p, n = size(Yf)
    traits = _bridge_names(trait_names, p, "trait")
    units = _bridge_names(unit_names, n, "unit")
    M = _bridge_mask(mask, p, n)

    # CI routing options (validated up-front so a bad ci_method errors before the
    # — potentially expensive — fit runs). ci_method="none" ⇒ ci stays nothing ⇒
    # the assembled contract is byte-identical to the no-CI path.
    ci_method = _bridge_ci_method(options)
    ci_level  = _bridge_ci_level(options)
    ci_nboot  = _bridge_ci_nboot(options)
    ci_seed   = _bridge_ci_seed(options)

    if M !== nothing
        key in _BRIDGE_MASK_FAMILIES || throw(ArgumentError(
            "bridge_fit: missing-response masks are wired for " *
            join(_BRIDGE_MASK_FAMILIES, ", ") *
            "; family=\"$key\" is not yet supported"))
        X === nothing || throw(ArgumentError(
            "bridge_fit: missing-response masks with fixed-effect covariates X " *
            "are not wired yet; use a complete response table or engine='tmb'."))
    end

    if X_lv !== nothing
        key == "gaussian" || throw(ArgumentError(
            "bridge_fit: X_lv is currently wired only for family=\"gaussian\"."))
        X === nothing || throw(ArgumentError(
            "bridge_fit: simultaneous fixed-effect X and latent-score X_lv is " *
            "not admitted in the bridge yet; fit one mean route at a time."))
        M === nothing || throw(ArgumentError(
            "bridge_fit: missing-response masks with X_lv are not wired yet; " *
            "use a complete response table or engine='tmb'."))
        K > 0 || throw(ArgumentError(
            "bridge_fit: X_lv requires a positive latent dimension d."))
        ci_method == "none" || throw(ArgumentError(
            "bridge_fit: confidence intervals for X_lv fits are not admitted " *
            "yet; use ci_method=\"none\" and lv_effects point estimates."))
    end

    # X (a p×n×q covariate array) routes to the covariate fitters: the Gaussian
    # branch below handles key=="gaussian"; every other one-part family with a
    # covariate kernel (_BRIDGE_X_FAMILIES) routes to fit_gllvm_cov. Defend the
    # invariant here too so a future DIRECT caller can't slip X past a family with
    # no covariate fitter (ordinal/nb1) and have it silently dropped.
    if X !== nothing && key != "gaussian"
        key in _BRIDGE_X_FAMILIES ||
            throw(ArgumentError("bridge_fit: X is not wired for family=\"$key\"; " *
                "supported families with covariates are gaussian, " *
                join(_BRIDGE_X_FAMILIES, ", ")))
        return _bridge_fit_onepart_cov(Yf, key, K, N, traits, units, X,
                                       ci_method, ci_level, ci_nboot, ci_seed,
                                       options)
    end

    if key == "gaussian"
        if X_lv !== nothing
            Xlv = Matrix{Float64}(X_lv)
            size(Xlv, 1) == n || throw(ArgumentError(
                "bridge_fit: X_lv must be n×q_lv ($(n)×q_lv); got $(size(Xlv))"))
            size(Xlv, 2) > 0 || throw(ArgumentError(
                "bridge_fit: X_lv must have at least one predictor column"))

            # Preserve the no-X Gaussian bridge convention: trait means live in
            # alpha, while the latent-score predictor fit sees centred responses.
            alpha = vec(Statistics.mean(Yf; dims = 2))
            Yc = Yf .- alpha
            fit = fit_gaussian_gllvm(Yc; K = K, X_lv = Xlv)
            Sigma = Matrix{Float64}(sigma_y_site(fit))
            corr  = Matrix{Float64}(correlation(fit))
            comm  = Vector{Float64}(communality(fit))
            scores_total = Matrix{Float64}(
                getLV(fit, Yc; X_lv = Xlv, component = :total, rotate = true))
            scores_mean = Matrix{Float64}(
                getLV(fit, Yc; X_lv = Xlv, component = :mean, rotate = true))
            scores_innovation = Matrix{Float64}(
                getLV(fit, Yc; X_lv = Xlv, component = :innovation, rotate = true))
            df = p + _nparams(fit)
            base = _bridge_assemble(fit, "gaussian", "gaussian_xlv_rr", traits, units;
                alpha = alpha, dispersion = fill(NaN, p), sigma_eps = fit.pars.σ_eps,
                link = fill("IdentityLink", p), Sigma = Sigma, corr = corr, comm = comm,
                scores = scores_total, df = df, loglik = fit.logLik,
                converged = fit.converged, iterations = fit.n_iter,
                note = "predictor-informed latent-score fit (Gaussian C1): alpha " *
                       "are pre-fit trait means, scores are total latent scores, " *
                       "scores_mean = X_lv*alpha_lv, scores_innovation are the " *
                       "posterior zero-mean score deviations, and lv_effects = " *
                       "Lambda*alpha_lv' is the rotation-stable trait-effect matrix. " *
                       "Confidence intervals and non-Gaussian X_lv routes remain " *
                       "separate validation gates.",
                ci = nothing)
            return merge(base, (lv_effects = Matrix{Float64}(extract_lv_effects(fit)),
                                alpha_lv = Matrix{Float64}(fit.pars.alpha_lv),
                                scores_mean = scores_mean,
                                scores_innovation = scores_innovation))
        end
        if X !== nothing
            # Fixed-effect covariate path. The caller's X (p×n×q) already carries the
            # FULL mean structure — per-trait intercept dummies AND covariates — so we
            # do NOT pre-centre Y; fit_gaussian_gllvm estimates β jointly with Λ̂/σ̂.
            # `alpha` is the per-trait fitted mean (mean over sites of Xₜₛ·β̂), the
            # natural per-trait intercept summary when the mean is covariate-driven.
            Xarr = Array{Float64,3}(X)
            size(Xarr, 1) == p && size(Xarr, 2) == n || throw(ArgumentError(
                "bridge_fit: X must be p×n×q ($(p)×$(n)×q); got $(size(Xarr))"))
            q = size(Xarr, 3)
            coef_fixed = _bridge_coef_fixed(options, q, "coef_fixed")
            fit = fit_gaussian_gllvm(Yf; K = K, X = Xarr, β_fixed = coef_fixed)
            β = collect(Float64, fit.pars.β)
            alpha = zeros(Float64, p)
            @inbounds for t in 1:p
                acc = 0.0
                for s in 1:n, k in 1:q
                    acc += Xarr[t, s, k] * β[k]
                end
                alpha[t] = acc / n
            end
            Sigma = Matrix{Float64}(sigma_y_site(fit))
            corr  = Matrix{Float64}(correlation(fit))
            comm  = Vector{Float64}(communality(fit))
            scores = _bridge_scores(() -> getLV(fit, Yf; X = Xarr, rotate = true))
            df = count(!, coef_fixed) + _bridge_rr_df(p, K) + 1
            ci = ci_method == "none" ? nothing :
                 _bridge_compute_ci_gaussian(fit, Yf, ci_method, ci_level, ci_nboot,
                                             ci_seed; X = Xarr)
            base = _bridge_assemble(fit, "gaussian", "gaussian_x_rr", traits, units;
                alpha = alpha, dispersion = fill(NaN, p), sigma_eps = fit.pars.σ_eps,
                link = fill("IdentityLink", p), Sigma = Sigma, corr = corr, comm = comm,
                scores = scores, df = df, loglik = fit.logLik,
                converged = fit.converged, iterations = fit.n_iter,
                note = "fixed-effect covariate fit: X carries the full mean structure " *
                       "(per-trait intercepts + covariates); alpha is the per-trait " *
                       "fitted mean. coef_fixed entries, if any, are fixed at zero.", ci = ci)
            return merge(base, (mean_coef = β,
                                mean_coef_status = _fixed_status(coef_fixed)))
        end
        reml = _bridge_truthy(_bridge_get(options, "reml", false))
        if reml
            # Restricted ML: per-trait intercepts enter as the GLS fixed effects X
            # (q = p, Xₜₛₜ = 1), so the trait means are REML-adjusted rather than
            # pre-centred. The fitted Λ̂/σ̂ are wrapped in a GllvmFit so the SAME
            # Gaussian extractors build the flat contract; the GLS β̂ is the alpha.
            Xrt = zeros(Float64, p, n, p)
            @inbounds for t in 1:p, s in 1:n
                Xrt[t, s, t] = 1.0
            end
            rfit = fit_gaussian_reml(Yf, Xrt; K = K)
            alpha = collect(Float64, rfit.β)
            fit = GllvmFit(GllvmModel(p, K),
                (σ_eps = rfit.σ_eps, Λ = rfit.Λ, β = nothing,
                 Λ_W = nothing, σ²_B = nothing, σ²_W = nothing,
                 Λ_phy = nothing, σ_phy = nothing, θ_packed = Float64[]),
                rfit.reml_loglik, rfit.iterations, rfit.converged, nothing, NaN)
            Yc = Yf .- alpha
            Sigma = Matrix{Float64}(sigma_y_site(fit))
            corr  = Matrix{Float64}(correlation(fit))
            comm  = Vector{Float64}(communality(fit))
            scores = _bridge_scores(() -> getLV(fit, Yc; rotate = true))
            df = p + _bridge_rr_df(p, K) + 1
            # REML's synthetic GllvmFit carries no packed vector ⇒ no observed-
            # information / profile substrate; _bridge_compute_ci_gaussian returns a
            # skip-with-note payload rather than fabricating bounds.
            ci = ci_method == "none" ? nothing :
                 _bridge_compute_ci_gaussian(fit, Yc, ci_method, ci_level, ci_nboot, ci_seed)
            return _bridge_assemble(fit, "gaussian", "gaussian_reml_rr", traits, units;
                alpha = alpha, dispersion = fill(NaN, p), sigma_eps = rfit.σ_eps,
                link = fill("IdentityLink", p), Sigma = Sigma, corr = corr, comm = comm,
                scores = scores, df = df, loglik = rfit.reml_loglik,
                converged = rfit.converged, iterations = rfit.iterations,
                note = "REML fit (restricted ML): loglik is the REML criterion, " *
                       "not directly comparable to ML loglik; alpha are GLS trait means.",
                ci = ci)
        end
        alpha = vec(Statistics.mean(Yf; dims = 2))
        Yc = Yf .- alpha
        fit = fit_gaussian_gllvm(Yc; K = K)
        Sigma = Matrix{Float64}(sigma_y_site(fit))
        corr  = Matrix{Float64}(correlation(fit))
        comm  = Vector{Float64}(communality(fit))
        scores = _bridge_scores(() -> getLV(fit, Yc; rotate = true))
        df = p + _bridge_rr_df(p, K) + 1
        ci = ci_method == "none" ? nothing :
             _bridge_compute_ci_gaussian(fit, Yc, ci_method, ci_level, ci_nboot, ci_seed)
        return _bridge_assemble(fit, "gaussian", "gaussian_rr", traits, units;
            alpha = alpha, dispersion = fill(NaN, p), sigma_eps = fit.pars.σ_eps,
            link = fill("IdentityLink", p), Sigma = Sigma, corr = corr, comm = comm,
            scores = scores, df = df, loglik = fit.logLik,
            converged = fit.converged, iterations = fit.n_iter, note = "", ci = ci)
    end

    # Non-Gaussian: fit, then build the latent-scale derived quantities. The six
    # families with link-residual extractors on main (poisson/binomial/negbinomial/
    # beta/gamma/ordinal) get the real cross-family Sigma/correlation/communality;
    # NB1 (no extractor yet) falls back to the shared block via _bridge_assemble_ng.
    # Non-Gaussian CI: the unified confint(fit, Y; method, …) covers wald/profile/
    # bootstrap for all six families below (the bridge fit objects are exactly the
    # _CIFit types it dispatches on). Pass Float64 data so the parity oracle (which
    # uses Float64.(Y)) matches to machine precision; nb1 routes too (its FamilyFit
    # is in _CIFit even though its latent-scale extractor is not yet present).
    if key == "poisson"
        Yi = round.(Int, Yf)
        fit = fit_poisson_gllvm(Yi; K = K, mask = M)
        scores = _bridge_scores(() -> getLV(fit, Yi; rotate = true, mask = M))
        ci = ci_method == "none" ? nothing :
             _bridge_compute_ci_ng(fit, Float64.(Yi), nothing, ci_method, ci_level, ci_nboot, ci_seed; mask = M)
        return _bridge_assemble_ng(fit, "poisson", "poisson_rr", traits, units, p, K, Yi, nothing;
            alpha = fit.β, dispersion = fill(NaN, p), df = p + _bridge_rr_df(p, K),
            scores = scores, ci = ci, mask = M)
    elseif key == "binomial"
        Yi = round.(Int, Yf)
        Ni = N === nothing ? fill(1, p, n) :
             (N isa Number ? fill(round(Int, N), p, n) : round.(Int, Matrix(N)))
        fit = fit_binomial_gllvm(Yi; K = K, N = Ni, mask = M)
        scores = _bridge_scores(() -> getLV(fit, Yi; N = Ni, rotate = true, mask = M))
        ci = ci_method == "none" ? nothing :
             _bridge_compute_ci_ng(fit, Float64.(Yi), Ni, ci_method, ci_level, ci_nboot, ci_seed; mask = M)
        return _bridge_assemble_ng(fit, "binomial", "binomial_rr", traits, units, p, K, Yi, Ni;
            alpha = fit.β, dispersion = fill(NaN, p), df = p + _bridge_rr_df(p, K),
            scores = scores, ci = ci, mask = M)
    elseif key == "negbinomial"
        Yi = round.(Int, Yf)
        fit = fit_nb_gllvm_grouped(Yi; K = K, group = collect(1:p), mask = M)
        disp = _bridge_dispersion_payload(fit.r_group, fit.group, "r",
            "Var = mu + mu^2 / r",
            "gllvm phi = 1 / r; gllvmTMB sigma = 1 / sqrt(r)")
        scores = _bridge_scores(() -> getLV(fit, Yi; rotate = true, mask = M))
        ci = ci_method == "none" ? nothing :
             _bridge_compute_ci_ng(fit, Float64.(Yi), nothing, ci_method, ci_level, ci_nboot, ci_seed; mask = M)
        base = _bridge_assemble_ng(fit, "negbinomial", "negbinomial_rr", traits, units, p, K, Yi, nothing;
            alpha = fit.β, dispersion = _bridge_expand_dispersion(disp), df = _bridge_group_df(p, K, disp),
            scores = scores, ci = ci, mask = M)
        return merge(base, disp)
    elseif key == "nb1"
        Yi = round.(Int, Yf)
        fit = fit_nb1_gllvm_grouped(Yi; K = K, group = collect(1:p), mask = M)
        disp = _bridge_dispersion_payload(fit.φ, fit.group, "phi",
            "Var = mu * (1 + phi)",
            "identity on the NB1 overdispersion scale")
        scores = _bridge_scores(() -> getLV(fit, Yi; rotate = true, mask = M))
        ci = ci_method == "none" ? nothing :
             _bridge_compute_ci_ng(fit, Float64.(Yi), nothing, ci_method, ci_level, ci_nboot, ci_seed; mask = M)
        base = _bridge_assemble_ng(fit, "nb1", "nb1_rr", traits, units, p, K, Yi, nothing;
            alpha = fit.β, dispersion = _bridge_expand_dispersion(disp), df = _bridge_group_df(p, K, disp),
            scores = scores, ci = ci, mask = M)
        return merge(base, disp)
    elseif key == "beta"
        fit = fit_beta_gllvm_grouped(Yf; K = K, group = collect(1:p), mask = M)
        disp = _bridge_dispersion_payload(fit.φ, fit.group, "phi",
            "Var = mu * (1 - mu) / (1 + phi)",
            "gllvmTMB sigma = 1 / sqrt(phi)")
        scores = _bridge_scores(() -> getLV(fit, Yf; rotate = true, mask = M))
        ci = ci_method == "none" ? nothing :
             _bridge_compute_ci_ng(fit, Yf, nothing, ci_method, ci_level, ci_nboot, ci_seed; mask = M)
        base = _bridge_assemble_ng(fit, "beta", "beta_rr", traits, units, p, K, Yf, nothing;
            alpha = fit.β, dispersion = _bridge_expand_dispersion(disp), df = _bridge_group_df(p, K, disp),
            scores = scores, ci = ci, mask = M)
        return merge(base, disp)
    elseif key == "gamma"
        # Native gllvmTMB ordinary Gamma currently has one scalar sigma_eps/CV for
        # all Gamma traits. Use a single grouped-Gamma shape here for R-oracle
        # parity; the per-trait grouped Gamma engine remains available for a later
        # native per-trait Gamma expansion.
        fit = fit_gamma_gllvm_grouped(Yf; K = K, group = fill(1, p), mask = M)
        disp = _bridge_dispersion_payload(fit.α, fit.group, "alpha",
            "Var = mu^2 / alpha",
            "gllvmTMB sigma = 1 / sqrt(alpha)")
        scores = _bridge_scores(() -> getLV(fit, Yf; rotate = true, mask = M))
        ci = ci_method == "none" ? nothing :
             _bridge_compute_ci_ng(fit, Yf, nothing, ci_method, ci_level, ci_nboot, ci_seed; mask = M)
        base = _bridge_assemble_ng(fit, "gamma", "gamma_rr", traits, units, p, K, Yf, nothing;
            alpha = fit.β, dispersion = _bridge_expand_dispersion(disp), df = _bridge_group_df(p, K, disp),
            scores = scores, ci = ci, mask = M)
        return merge(base, disp)
    elseif key in ("ordinal", "ordinal_probit")
        Yi = round.(Int, Yf)
        link = key == "ordinal_probit" ? ProbitLink() : LogitLink()
        _bridge_ci_guard_pertrait_ordinal(key, ci_method)
        fit = fit_ordinal_gllvm_pertrait(Yi; K = K, link = link, mask = M)
        scores = _bridge_scores(() -> getLV(fit, Yi; rotate = true, mask = M))
        family_out = key == "ordinal_probit" ? "ordinal_probit" : "ordinal"
        model_out = key == "ordinal_probit" ? "ordinal_probit_rr" : "ordinal_rr"
        base = _bridge_assemble_ng(fit, family_out, model_out, traits, units, p, K, Yi, nothing;
            alpha = fill(NaN, p), dispersion = fill(NaN, p),
            df = _bridge_rr_df(p, K) + sum(fit.C .- 1), scores = scores, ci = nothing, mask = M)
        # Ordinal-only FLAT extras (ASCII keys, primitive arrays): per-trait
        # ordered cutpoints (NaN-padded after each trait's final threshold) and
        # per-trait category counts. This is the native gllvmTMB parity shape.
        return merge(base, (cutpoints = Matrix{Float64}(fit.τ),
                            n_categories = Vector{Int}(fit.C),
                            cutpoint_mode = "per_trait",
                            cutpoint_link = _bridge_link_name(fit.link)))
    end
    throw(ArgumentError("bridge_fit: unhandled family key \"$key\""))  # unreachable
end

# --- one-part NON-Gaussian covariate dispatch (fit_gllvm_cov) ---------------
#
# Route the one-part non-Gaussian families that carry a covariate kernel
# (_BRIDGE_X_FAMILIES) through `fit_gllvm_cov`, whose linear predictor is
# η_{ts} = β_t + Σ_k X[t,s,k]·γ_k + (Λ z_s)_t. The flat contract MIRRORS the
# Gaussian-X return (loadings, alpha, dispersion, Sigma/correlation/communality,
# scores, df, …) and ADDS two coefficient arrays the R side reads to fill the
# covariate coefficient table:
#
#   beta_cov :: Vector{Float64}  — per-trait intercepts β (length p)
#   gamma    :: Vector{Float64}  — shared covariate coefficients γ (length q)
#
# `alpha` mirrors β (the per-trait intercept on the link scale) so the existing
# intercept field stays meaningful. Σ_y/correlation/communality use the shared
# block ΛΛᵀ (GllvmCovFit has no link-residual extractor yet — same honest fallback
# as NB1 in _bridge_assemble_ng). CI routing uses native
# confint(fit, Y; X=…, N=…) and returns the same flat bridge CI payload contract
# as no-X fits.
function _bridge_fit_onepart_cov(Yf::AbstractMatrix{Float64}, key::AbstractString,
                                 K::Integer, N, traits, units, X,
                                 ci_method::AbstractString, ci_level::Real,
                                 ci_nboot::Integer, ci_seed::Integer, options)
    p, n = size(Yf)
    Xarr = Array{Float64,3}(X)
    size(Xarr, 1) == p && size(Xarr, 2) == n || throw(ArgumentError(
        "bridge_fit: X must be p×n×q ($(p)×$(n)×q); got $(size(Xarr))"))
    q = size(Xarr, 3)
    marker = _bridge_cov_marker(key)
    coef_fixed = _bridge_coef_fixed(options, q, "coef_fixed")

    # Per-family response coercion + Binomial trial counts (mirror the no-X path):
    # the count families round to integer-valued Float64; continuous pass through.
    is_count = key in ("poisson", "binomial", "negbinomial")
    Ydata = is_count ? Float64.(round.(Int, Yf)) : Yf
    Nm = key == "binomial" ?
         (N === nothing ? fill(1, p, n) :
          (N isa Number ? fill(round(Int, N), p, n) : round.(Int, Matrix(N)))) :
         nothing

    fit = Nm === nothing ?
          fit_gllvm_cov(Ydata; family = marker, X = Xarr, K = K, γ_fixed = coef_fixed) :
          fit_gllvm_cov(Ydata; family = marker, X = Xarr, K = K, N = Nm,
                        γ_fixed = coef_fixed)

    β   = collect(Float64, fit.β)
    γ   = collect(Float64, fit.γ)
    L   = Matrix{Float64}(getLoadings(fit; rotate = true))
    disp = fill(Float64(fit.dispersion), p)   # NaN where the family has none

    scores = _bridge_scores(() -> getLV(fit, Ydata, Xarr; rotate = true,
                                        N = (Nm === nothing ? nothing : Nm)))
    ci = ci_method == "none" ? nothing :
         _bridge_compute_ci_cov(fit, Ydata, Nm, Xarr, ci_method, ci_level,
                                ci_nboot, ci_seed)

    # Shared-block latent-scale derived quantities (no link-residual extractor for
    # GllvmCovFit yet): Σ = ΛΛᵀ, correlation from Σ, communality = 1.
    Λr = L
    Σ  = Λr * Λr'; Σ = (Σ + Σ') ./ 2
    corr = _bridge_corr_from_sigma(Σ)
    comm = ones(Float64, p)

    df = p + count(!, coef_fixed) + _bridge_rr_df(p, K) + (isnan(fit.dispersion) ? 0 : 1)
    base = _bridge_assemble(fit, key, "$(key)_x_rr", traits, units;
        alpha = β, dispersion = disp, sigma_eps = NaN,
        link = fill(_bridge_link_name(fit.link), p), Sigma = Σ, corr = corr,
        comm = comm, scores = scores, df = df, loglik = fit.loglik,
        converged = fit.converged, iterations = fit.iterations,
        loadings = L, note =
            "fixed-effect covariate fit (non-Gaussian): eta = beta + X*gamma + " *
            "Lambda*z. beta_cov = per-trait intercepts, gamma = shared covariate " *
            "coefficients. coef_fixed entries, if any, are fixed at zero. " *
            "Sigma/correlation use the shared block Lambda*Lambda' " *
            "(communality 1).",
        ci = ci)
    return merge(base, (beta_cov = β, gamma = γ, gamma_status = _fixed_status(coef_fixed)))
end

# --- mixed-family dispatch (the cross-distribution VCV headline) -----------

# Map a bridge family string to the `Distributions` marker `fit_mixed_gllvm`
# dispatches on. v1 supports the SIX families the mixed fitter supports
# (gaussian/poisson/binomial/negbinomial/gamma/beta); ordinal and nb1 (no mixed
# kernels yet) are documented follow-ups, rejected here with a clear message.
function _bridge_mixed_family_marker(family::AbstractString)
    key = _bridge_family_key(family)
    key == "gaussian"    && return Normal()
    key == "poisson"     && return Poisson()
    key == "binomial"    && return Binomial()
    key == "negbinomial" && return NegativeBinomial(10.0, 0.5)
    key == "gamma"       && return Gamma(2.0, 1.0)
    key == "beta"        && return Beta(10.0, 1.0)
    throw(ArgumentError(
        "bridge_fit (mixed): family \"$family\" is not yet supported per-trait in a " *
        "mixed-family fit; v1 supports gaussian, poisson, binomial, negbinomial, " *
        "gamma, beta. Ordinal and nb1 are documented follow-ups."))
end

# Mixed-family bridge: per-trait families share one latent block Λ; the flat
# contract's `correlation` is the TRUE cross-distribution latent-scale correlation.
# Per-trait response coercion: count families (poisson/binomial/negbinomial) round
# to integer-valued Float64 (the family logpdf takes Int(y)); continuous families
# (gaussian/gamma/beta) pass through as Float64.
function _bridge_fit_mixed(y, family_strs::AbstractVector, K::Integer, N,
                           trait_names, unit_names, options)
    Yf = Matrix{Float64}(y)
    p, n = size(Yf)
    length(family_strs) == p || throw(ArgumentError(
        "bridge_fit (mixed): family vector length $(length(family_strs)) must equal " *
        "the number of traits (rows of y) = $p"))
    traits = _bridge_names(trait_names, p, "trait")
    units = _bridge_names(unit_names, n, "unit")

    # Validate the CI option up-front (a bad ci_method must error loudly even on
    # the mixed path). The mixed fit is a MixedFamilyFit, which the native confint
    # engines do not dispatch on, so any actual CI request is skipped-with-note
    # rather than faked — a documented follow-up.
    ci_method = _bridge_ci_method(options)
    ci_level  = _bridge_ci_level(options)

    keys_norm = [_bridge_family_key(f) for f in family_strs]
    families = [_bridge_mixed_family_marker(f) for f in family_strs]
    links = Link[default_link(fam) for fam in families]

    # Per-trait response matrix: round count rows to integers (in Float64), leave
    # continuous rows untouched. The mixed marginal reads each row by its family.
    Ymix = copy(Yf)
    is_count = (k -> k in ("poisson", "binomial", "negbinomial"))
    @inbounds for t in 1:p
        if is_count(keys_norm[t])
            for s in 1:n
                Ymix[t, s] = float(round(Int, Yf[t, s]))
            end
        end
    end

    # Binomial trial counts (p×n; defaults to 1). Only the Binomial rows read N.
    Nm = N === nothing ? fill(1, p, n) :
         (N isa Number ? fill(round(Int, N), p, n) : round.(Int, Matrix(N)))

    fit = fit_mixed_gllvm(Ymix; families = families, links = links, K = K, N = Nm)

    Sigma = Matrix{Float64}(sigma_y_site(fit, Ymix; N = Nm))
    corr  = Matrix{Float64}(correlation(fit, Ymix; N = Nm))
    comm  = Vector{Float64}(communality(fit, Ymix; N = Nm))
    scores = _bridge_scores(() -> getLV(fit, Ymix; N = Nm, rotate = true))

    # alpha is the per-trait link-scale intercept; dispersion is per-trait (NaN
    # where the family carries none — already the MixedFamilyFit convention).
    alpha = collect(Float64, fit.β)
    dispersion = collect(Float64, fit.dispersion)
    link_names = [_bridge_link_name(links[t]) for t in 1:p]

    # Free-parameter count: p intercepts + reduced-rank loadings + n_disp dispersions.
    df = p + _bridge_rr_df(p, K) + fit.n_disp
    fams_tag = join(keys_norm, "+")

    ci = ci_method == "none" ? nothing :
         _bridge_ci_payload(ci_method, ci_level,
             "CIs are not routed for the mixed-family path yet (the cross-family " *
             "MixedFamilyFit has no native confint engine); a documented follow-up.")

    return _bridge_assemble(fit, fams_tag, "mixed_rr", traits, units;
        alpha = alpha, dispersion = dispersion, sigma_eps = NaN,
        link = link_names, Sigma = Sigma, corr = corr, comm = comm,
        scores = scores, df = df, loglik = fit.loglik,
        converged = fit.converged, iterations = fit.iterations,
        loadings = Matrix{Float64}(fit.Λ * _svd_rotation(fit.Λ)),  # canonical SVD-rotated p×K loadings
        families = keys_norm,
        note = "mixed-family GLLVM: one shared latent block across distinct response " *
               "families; `correlation` is the cross-distribution latent-scale " *
               "correlation. `families` is the per-trait family vector.", ci = ci)
end

# Non-Gaussian assembler: REAL latent-scale derived quantities via the salvaged
# link-residual extractors (sigma_y_site/correlation/communality, ΛΛᵀ + diag(d_t)).
# Falls back to the shared block ΛΛᵀ ONLY when a family has no extractor on this
# engine (narrow MethodError catch — e.g. NB1); other errors propagate.
function _bridge_assemble_ng(fit, family, model, traits, units, p, K, Ydata, N;
                             alpha, dispersion, df, scores, ci = nothing, mask = nothing)
    Sigma, corr, comm, note = try
        S  = N === nothing ? sigma_y_site(fit, Ydata; mask = mask)  : sigma_y_site(fit, Ydata; N = N, mask = mask)
        C  = N === nothing ? correlation(fit, Ydata; mask = mask)   : correlation(fit, Ydata; N = N, mask = mask)
        cm = N === nothing ? communality(fit, Ydata; mask = mask)   : communality(fit, Ydata; N = N, mask = mask)
        (Matrix{Float64}(S), Matrix{Float64}(C), Vector{Float64}(cm), "")
    catch e
        e isa MethodError || rethrow()
        Λ = _bridge_loadings(fit)
        Σ = Λ * Λ'; Σ = (Σ + Σ') ./ 2
        (Σ, _bridge_corr_from_sigma(Σ), ones(Float64, p),
         "$(family) has no link-residual extractor on this engine yet; " *
         "Sigma/correlation use the shared block Lambda*Lambda' only (communality 1).")
    end
    return _bridge_assemble(fit, family, model, traits, units;
        alpha = alpha, dispersion = dispersion, sigma_eps = NaN,
        link = fill(_bridge_link_name(fit.link), p), Sigma = Sigma, corr = corr,
        comm = comm, scores = scores, df = df, loglik = fit.loglik,
        converged = fit.converged, iterations = fit.iterations, note = note, ci = ci,
        nobs = mask === nothing ? nothing : count(mask))
end

# Shared flat-NamedTuple builder. `ci` (when non-nothing) is a flat CI payload
# NamedTuple (from _bridge_compute_ci_*) MERGED onto the base contract; passing
# `ci = nothing` (the ci_method="none" default) returns the base tuple unchanged,
# so the existing contract is byte-identical for callers that request no CIs.
function _bridge_assemble(fit, family::AbstractString, model::AbstractString,
                          traits, units;
                          alpha, dispersion, sigma_eps, link, Sigma, corr, comm,
                          scores, df, loglik, converged, iterations, note,
                          loadings = nothing, families = nothing, ci = nothing,
                          nobs = nothing)
    p = length(traits)
    n = length(units)
    L = loadings === nothing ? _bridge_loadings(fit) : loadings
    K = size(L, 2)
    ll = Float64(loglik)
    nobs_val = nobs === nothing ? p * n : Int(nobs)
    family_vec = families === nothing ? fill(family, p) : Vector{String}(families)
    length(family_vec) == p || throw(ArgumentError(
        "bridge_fit: per-trait families length $(length(family_vec)) must equal " *
        "the number of traits $p"))
    base = (
        family       = family,
        families     = family_vec,
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
        nobs         = nobs_val,
        converged    = converged,
        iterations   = iterations,
        message      = converged ? "converged" : "not converged",
        link         = Vector{String}(link),
        note         = note,
    )
    return ci === nothing ? base : merge(base, ci)
end
