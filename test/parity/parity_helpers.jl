# parity_helpers.jl — shared RCall / gllvmTMB helpers for opt-in parity cells.
#
# Included by family test files under test/parity/. Never included by runtests.jl.
# Twin call shape: gllvmTMB (not CRAN gllvm), latent(..., unique = FALSE),
# extractors via stats::logLik / -opt$objective.
# Source: docs/dev-log/plans/scratch/2026-08-01-gaussian-rcall-shape.md

using RCall

# Prefer the lane twin install when present (gllvmTMB @ origin/main SHA recorded
# in LOOP / after-task). Override with ENV["GLLVM_PARITY_R_LIBS"].
const _PARITY_TWIN_RLIB =
    get(ENV, "GLLVM_PARITY_R_LIBS", "/tmp/R-gllvmtmb-x-parity-20260802")

function _parity_prepend_twin_lib!()
    twin = _PARITY_TWIN_RLIB
    isdir(joinpath(twin, "gllvmTMB")) || return nothing
    @rput twin
    R""".libPaths(c(twin, .libPaths())); invisible(TRUE)"""
    return nothing
end

function _parity_require_gllvmtmb!()
    _parity_prepend_twin_lib!()
    R"""
    if (!requireNamespace("gllvmTMB", quietly = TRUE)) {
        stop("R package 'gllvmTMB' is not installed. ",
             "Install from the twin checkout or GitHub (itchyshin/gllvmTMB).")
    }
    suppressPackageStartupMessages(library(gllvmTMB))
    invisible(TRUE)
    """
    return nothing
end

"""
    parity_site_design(x, p) -> Array{Float64,3}

Build `(p, n, 1)` design with shared site covariate: `X[t,s,1] = x[s]`.
"""
function parity_site_design(x::AbstractVector{<:Real}, p::Integer)
    n = length(x)
    X = zeros(Float64, p, n, 1)
    @inbounds for t in 1:p, s in 1:n
        X[t, s, 1] = Float64(x[s])
    end
    return X
end

"""
    fit_gllvmtmb_parity_loglik(y, K; family) -> NamedTuple

Fit `gllvmTMB` on a Julia `p × n` response matrix with the twin-aligned
no-X formula:

```
value ~ 0 + trait + latent(0 + trait | site, d = K, unique = FALSE)
```

`family` ∈ `(:gaussian, :binomial, :poisson, :lognormal, :negbinomial, :beta,
:truncated_poisson)`. Returns `(logLik, objective, converged)`.

For `:negbinomial` / `:beta`, R defaults estimate per-trait dispersion; pair
with Julia grouped fitters (`disp_group=:species`), not shared-dispersion defaults.

`:lognormal` (twin fid 3) is the one no-X family where per-trait dispersion would
be WRONG: the twin ties a **shared scalar** `sigma_eps` across traits, so pair it
with `fit_lognormal_gllvm` (scalar `σ`), never a grouped fitter. Its reported
log-likelihood is on the **y scale** and must include the change-of-variables
Jacobian `−Σ log y` on both sides (Identity
`docs/dev-log/decisions/2026-08-15-lognormal-identity.md`).

`:truncated_nbinom2` (twin fid 11) carries **per-trait** dispersion
`log_phi_truncnb2` (`src/gllvmTMB.cpp:1187-1190`), so pair it with
`fit_truncated_nbinom2_gllvm_pertrait`, never the shared-scalar
`fit_truncated_nbinom2_gllvm`. Log link only; support `y ≥ 1`; η on the untruncated
mean. Its Laplace log-det must use `hessian = :observed` to match TMB — the NB2
curvature is y-dependent, unlike fid 10 (Identity
`docs/dev-log/decisions/2026-08-15-truncated-nbinom2-identity.md`).

`:truncated_poisson` (twin fid 10) has no dispersion. η is on the **untruncated**
mean `μ = exp(η)`; the twin's `linkinv` returns the truncated mean
`λ/(1−e^{−λ})` for GLM display only — never compare a mean-scale quantity, only
the log-likelihood (Identity
`docs/dev-log/decisions/2026-08-15-truncated-poisson-identity.md`).
"""
function fit_gllvmtmb_parity_loglik(y::AbstractMatrix, K::Integer; family::Symbol,
        N::Union{Nothing, AbstractMatrix{<:Real}} = nothing)
    family in (:gaussian, :binomial, :poisson, :lognormal, :gamma, :negbinomial,
               :nb1, :beta, :betabinomial, :truncated_poisson, :truncated_nbinom2) ||
        throw(ArgumentError("unsupported parity family: $family"))
    p, n = size(y)
    family === :betabinomial && N === nothing &&
        throw(ArgumentError("family = :betabinomial requires trial counts N (p×n)"))
    if N !== nothing
        size(N) == (p, n) ||
            throw(DimensionMismatch("N must be $(p)×$(n); got $(size(N))"))
    end
    fam = String(family)
    trials = N === nothing ? fill(1.0, p, n) : Float64.(N)
    _parity_require_gllvmtmb!()
    @rput y K p n fam trials

    R"""
    trait_names <- paste0("t", seq_len(p))
    df_long <- data.frame(
        site  = factor(rep(seq_len(n), each = p)),
        trait = factor(rep(trait_names, times = n), levels = trait_names),
        value = as.vector(y)   # column-major on p×n ⇒ site blocks
    )
    fam_obj <- switch(fam,
        gaussian          = stats::gaussian(),
        binomial          = stats::binomial(),
        poisson           = stats::poisson(),
        lognormal         = gllvmTMB::lognormal(),
        gamma             = stats::Gamma(link = "log"),
        negbinomial       = gllvmTMB::nbinom2(),
        nb1               = gllvmTMB::nbinom1(),
        beta              = gllvmTMB::Beta(),
        betabinomial      = gllvmTMB::betabinomial(),
        truncated_poisson = gllvmTMB::truncated_poisson(),
        truncated_nbinom2 = gllvmTMB::truncated_nbinom2(),
        stop(sprintf("unknown family: %s", fam))
    )
    # betabinomial/binomial rows: `weights` = per-row trial count (twin API B);
    # NULL for every other family (lme4-style per-observation multiplier).
    weights_vec <- if (identical(fam, "betabinomial")) as.vector(trials) else NULL
    fit_r <- gllvmTMB(
        value ~ 0 + trait + latent(0 + trait | site, d = K, unique = FALSE),
        data = df_long,
        unit = "site",
        trait = "trait",
        family = fam_obj,
        weights = weights_vec,
        control = gllvmTMBcontrol(n_init = 1L, se = FALSE)
    )
    .gllvm_parity_last <<- list(
        logL      = as.numeric(stats::logLik(fit_r)),
        objective = as.numeric(fit_r$opt$objective),
        converged = identical(as.integer(fit_r$opt$convergence), 0L)
    )
    invisible(NULL)
    """

    return (
        logLik = rcopy(Float64, R".gllvm_parity_last$logL"),
        objective = rcopy(Float64, R".gllvm_parity_last$objective"),
        converged = rcopy(Bool, R".gllvm_parity_last$converged"),
    )
end

"""
    fit_gllvmtmb_parity_loglik_x(y, x_site, K; family, N=nothing) -> NamedTuple

Shared-site-X twin oracle. `x_site` is length-`n` (one value per site). R formula
uses a **shared** slope `+ x` (not `(0 + trait):x`):

```
value ~ 0 + trait + x + latent(0 + trait | site, d = K, unique = FALSE)
```

`family` ∈ `(:gaussian, :binomial, :poisson, :gamma, :negbinomial, :nb1, :beta,
:ordinal, :betabinomial)`.
Pair with Julia `fit_gaussian_gllvm(; X=)` / `fit_gllvm_cov` (shared γ) for
G/Bin/Pois; `fit_gamma_gllvm_grouped_cov` (per-trait shape α + shared γ) for
Gamma; `fit_nb_gllvm_grouped_cov` / `fit_nb1_gllvm_grouped_cov` /
`fit_beta_gllvm_grouped_cov` / `fit_beta_binomial_gllvm_grouped_cov` (per-trait
dispersion + shared γ) for NB2/NB1/Beta/BetaBinomial; or
`fit_ordinal_gllvm_pertrait_cov` (per-trait cutpoints τ₁=0 / K−2 + shared γ,
`ProbitLink`) for Ordinal — R defaults match twin API B under X (Gamma identity
`2026-08-03-gamma-x-dispersion-identity.md`; NB2/Beta
`2026-08-02-nb2-beta-x-dispersion-identity.md`; NB1
`2026-08-05-nb1-x-dispersion-identity.md`; Ordinal cutpoint identity
`2026-08-03-ordinal-x-cutpoint-identity.md`; BetaBinomial
`2026-08-05-betabinomial-x-dispersion-identity.md`). `:ordinal` uses
`gllvmTMB::ordinal_probit()`; `:nb1` uses `gllvmTMB::nbinom1()`; `:betabinomial`
uses `gllvmTMB::betabinomial()`.

`N` (`p×n` trial counts, required for `:betabinomial`) is threaded to R as the
`weights` argument to `gllvmTMB()` — gllvmTMB's beta-binomial/binomial rows
(fid 8/1) interpret a numeric `weights` vector of length `nrow(data)` as the
per-row trial count (`R/fit-multi.R:2031–2045`), the "API (B)" alternative to
`cbind(successes, failures)` on the LHS. Ignored for all other families.
"""
function fit_gllvmtmb_parity_loglik_x(
    y::AbstractMatrix,
    x_site::AbstractVector{<:Real},
    K::Integer;
    family::Symbol,
    N::Union{Nothing, AbstractMatrix{<:Real}} = nothing,
)
    family in (:gaussian, :binomial, :poisson, :gamma, :negbinomial, :nb1, :beta, :ordinal, :betabinomial) ||
        throw(ArgumentError("unsupported shared-X parity family: $family"))
    p, n = size(y)
    length(x_site) == n ||
        throw(DimensionMismatch("x_site length ($(length(x_site))) must equal n ($n)"))
    family === :betabinomial && N === nothing &&
        throw(ArgumentError("family = :betabinomial requires trial counts N (p×n)"))
    if N !== nothing
        size(N) == (p, n) ||
            throw(DimensionMismatch("N must be $(p)×$(n); got $(size(N))"))
    end
    fam = String(family)
    x = collect(Float64, x_site)
    trials = N === nothing ? fill(1.0, p, n) : Float64.(N)
    _parity_require_gllvmtmb!()
    @rput y K p n fam x trials

    R"""
    trait_names <- paste0("t", seq_len(p))
    df_long <- data.frame(
        site  = factor(rep(seq_len(n), each = p)),
        trait = factor(rep(trait_names, times = n), levels = trait_names),
        value = as.vector(y),   # column-major on p×n ⇒ site blocks
        x     = rep(as.numeric(x), each = p)
    )
    fam_obj <- switch(fam,
        gaussian     = stats::gaussian(),
        binomial     = stats::binomial(),
        poisson      = stats::poisson(),
        gamma        = stats::Gamma(link = "log"),
        negbinomial  = gllvmTMB::nbinom2(),
        nb1          = gllvmTMB::nbinom1(),
        beta         = gllvmTMB::Beta(),
        ordinal      = gllvmTMB::ordinal_probit(),
        betabinomial = gllvmTMB::betabinomial(),
        stop(sprintf("unknown family: %s", fam))
    )
    # betabinomial/binomial rows: `weights` = per-row trial count (API B);
    # NULL for every other family (lme4-style per-observation multiplier).
    weights_vec <- if (identical(fam, "betabinomial")) as.vector(trials) else NULL
    # Shared site slope: bare `x`, NOT `(0 + trait):x` (per-trait slopes).
    fit_r <- gllvmTMB(
        value ~ 0 + trait + x + latent(0 + trait | site, d = K, unique = FALSE),
        data = df_long,
        unit = "site",
        trait = "trait",
        family = fam_obj,
        weights = weights_vec,
        control = gllvmTMBcontrol(n_init = 1L, se = FALSE)
    )
    .gllvm_parity_last_x <<- list(
        logL      = as.numeric(stats::logLik(fit_r)),
        objective = as.numeric(fit_r$opt$objective),
        converged = identical(as.integer(fit_r$opt$convergence), 0L)
    )
    invisible(NULL)
    """

    return (
        logLik = rcopy(Float64, R".gllvm_parity_last_x$logL"),
        objective = rcopy(Float64, R".gllvm_parity_last_x$objective"),
        converged = rcopy(Bool, R".gllvm_parity_last_x$converged"),
    )
end

"""
    fit_gllvmtmb_parity_loglik_species_x(y, x_site, K; family) -> NamedTuple

Species-specific site-X twin oracle. R formula uses **per-trait** slopes
`(0 + trait):x` (not bare `+ x`):

```
value ~ 0 + trait + (0 + trait):x + latent(0 + trait | site, d = K, unique = FALSE)
```

Pair with Julia [`fit_gllvm_speciescov`](@ref) (`B` is `p×q`). Supported
families: `:poisson` (Arc 0 / #190) and `:binomial` (Bernoulli N=1; capacity
programme S1). Other families may need a separate dispersion identity.
`:binomial` matches the shared-X helper: `stats::binomial()` with no `weights`
(N=1). Do not narrate as a full species-B cohort.
"""
function fit_gllvmtmb_parity_loglik_species_x(
    y::AbstractMatrix,
    x_site::AbstractVector{<:Real},
    K::Integer;
    family::Symbol,
)
    family in (:poisson, :binomial) ||
        throw(ArgumentError("unsupported species-XB parity family: $family"))
    p, n = size(y)
    length(x_site) == n ||
        throw(DimensionMismatch("x_site length ($(length(x_site))) must equal n ($n)"))
    fam = String(family)
    x = collect(Float64, x_site)
    _parity_require_gllvmtmb!()
    @rput y K p n fam x

    R"""
    trait_names <- paste0("t", seq_len(p))
    df_long <- data.frame(
        site  = factor(rep(seq_len(n), each = p)),
        trait = factor(rep(trait_names, times = n), levels = trait_names),
        value = as.vector(y),
        x     = rep(as.numeric(x), each = p)
    )
    fam_obj <- switch(fam,
        poisson  = stats::poisson(),
        binomial = stats::binomial(),
        stop(sprintf("unknown family: %s", fam))
    )
    # Per-trait slopes: (0 + trait):x — NOT bare shared `x`.
    fit_r <- gllvmTMB(
        value ~ 0 + trait + (0 + trait):x + latent(0 + trait | site, d = K, unique = FALSE),
        data = df_long,
        unit = "site",
        trait = "trait",
        family = fam_obj,
        control = gllvmTMBcontrol(n_init = 1L, se = FALSE)
    )
    .gllvm_parity_last_species_x <<- list(
        logL      = as.numeric(stats::logLik(fit_r)),
        objective = as.numeric(fit_r$opt$objective),
        converged = identical(as.integer(fit_r$opt$convergence), 0L)
    )
    invisible(NULL)
    """

    return (
        logLik = rcopy(Float64, R".gllvm_parity_last_species_x$logL"),
        objective = rcopy(Float64, R".gllvm_parity_last_species_x$objective"),
        converged = rcopy(Bool, R".gllvm_parity_last_species_x$converged"),
    )
end

function print_parity_loglik(label::AbstractString; jl_logL, r_logL, r_obj)
    println()
    println("── ", label, " ──")
    println("  Julia logLik          = ", jl_logL)
    println("  gllvmTMB logLik       = ", r_logL)
    println("  gllvmTMB -objective   = ", -r_obj)
    println("  Δ logLik (jl − r)     = ", jl_logL - r_logL)
    println()
    return nothing
end

"""Tiny LT loadings fixture used across parity DGPs."""
function parity_loadings_p5k2()
    return [
        0.8   0.0
        0.5   0.6
        0.3  -0.4
       -0.2   0.5
        0.1   0.3
    ]
end

"""
    fit_gllvmtmb_parity_loglik_multinomial(y, ncat) -> NamedTuple

Twin oracle for **multinomial (twin fid 16)**. Deliberately NOT part of
[`fit_gllvmtmb_parity_loglik`](@ref): every other cell reshapes a numeric `p×n`
matrix and fits `value ~ 0 + trait + latent(0 + trait | site, d = K, unique = FALSE)`.
Multinomial differs on both counts —

* the response is a **single categorical (factor) column** on the formula LHS, not a
  numeric cell value; the twin expands it internally into `K−1` one-hot pseudo-trait
  rows (`R/gllvmTMB.R` `expand_multinomial_response()`), and
* there is **no `latent(...)` term**, because GLLVM.jl's v1 multinomial is
  fixed-effects softmax only (no LV — `fit_multinomial_gllvm` throws on `K`/`num_lv`).
  The twin supports a no-covstruct multinomial fit, so the FE-only shape is a genuine
  same-model comparison rather than a concession.

`y` is a length-`n` integer vector of category codes `1..ncat` (`ncat ≥ 3`; a
2-category response is binomial and the twin rejects it). Returns
`(logLik, objective, converged)`.

Two footguns are handled here rather than left to callers:

1. **Explicit factor levels.** `factor(y)` sorts levels as *strings*, so with
   `ncat ≥ 10` the baseline would silently permute ("10" sorts before "2"). Levels are
   pinned to `as.character(1:ncat)`.
2. **No `baseline=` argument.** The twin's default reference is the first level, which
   under those pinned levels is category 1 — exactly Julia's `η₁ ≡ 0`. Passing
   `baseline` would risk disagreeing with the Julia convention.
"""
function fit_gllvmtmb_parity_loglik_multinomial(y::AbstractVector{<:Integer},
        ncat::Integer)
    ncat >= 3 || throw(ArgumentError(
        "multinomial parity needs ncat ≥ 3 (a 2-category response is binomial)"))
    all(v -> 1 <= v <= ncat, y) ||
        throw(ArgumentError("y must hold category codes in 1..$ncat"))
    n = length(y)
    yv = collect(Int, y)
    _parity_require_gllvmtmb!()
    @rput yv ncat n

    R"""
    lev <- as.character(seq_len(ncat))
    df_long <- data.frame(
        unit  = factor(seq_len(n)),
        trait = factor(rep("t1", n)),
        value = factor(as.character(yv), levels = lev)
    )
    # No latent(...) term: GLLVM.jl v1 multinomial is fixed-effects softmax only.
    fit_r <- gllvmTMB(
        value ~ 0 + trait,
        data = df_long,
        unit = "unit",
        trait = "trait",
        family = multinomial(),
        control = gllvmTMBcontrol(n_init = 1L, se = FALSE)
    )
    .gllvm_parity_multinom <<- list(
        logL      = as.numeric(stats::logLik(fit_r)),
        objective = as.numeric(fit_r$opt$objective),
        converged = identical(as.integer(fit_r$opt$convergence), 0L)
    )
    invisible(NULL)
    """

    return (
        logLik = rcopy(Float64, R".gllvm_parity_multinom$logL"),
        objective = rcopy(Float64, R".gllvm_parity_multinom$objective"),
        converged = rcopy(Bool, R".gllvm_parity_multinom$converged"),
    )
end

"""
    fit_gllvmtmb_parity_delta(y, K; family) -> NamedTuple

Twin oracle for the **delta (hurdle) families**, `:delta_lognormal` (fid 12) /
`:delta_gamma` (fid 13). Unlike [`fit_gllvmtmb_parity_loglik`](@ref), the twin's
`delta_lognormal()` / `delta_gamma()` share ONE linear predictor across occurrence
and the positive part (`gllvmTMB.cpp:2816-2844`), matching Julia's
`predictor = :shared` mode on `fit_delta_lognormal_gllvm` /
`fit_delta_gamma_gllvm` (Identity
`docs/dev-log/decisions/2026-08-28-delta-shared-predictor-identity.md`).

**Dispersion parameterisation is PER-TRAIT on the twin side** (`log_sigma_lognormal_delta`
/ `log_phi_gamma_delta`, `n_traits`-length TMB parameter vectors — no shared/pinned
mode is exposed through the family constructor or `gllvmTMB()`; see
`R/dispersion-trait-map.R`), while Julia's `fit_delta_lognormal_gllvm` /
`fit_delta_gamma_gllvm` estimate a single SHARED scalar `σ` / `α` across all traits.
This is a genuine, irreducible parameterisation mismatch (not a bug): the twin has
`p−1` more free parameters than Julia here, so its maximised log-likelihood is
generically ≥ Julia's even under a shared-dispersion DGP. Report the per-trait
dispersion vector `r_disp_vec` alongside the Δ so a caller can see whether the twin's
per-trait estimates are close to each other (consistent with a genuinely shared DGP)
or spread apart.

`family` ∈ `(:delta_lognormal, :delta_gamma)`. `y` is `p×n` with `0` for absences.
Returns `(logLik, objective, converged, b_fix, disp_vec)`: `b_fix` is the twin's
trait-intercept vector (length `p`, ONE per trait since the shared predictor has
no separate occurrence/positive intercepts); `disp_vec` is the reported per-trait
`sigma_lognormal_delta` / `phi_gamma_delta` vector (length `p`; for `:delta_gamma`
this is the **CV**, `phi = 1/sqrt(shape)`, NOT the shape — map before comparing to
Julia's `α` = shape via `α ≈ 1/phi^2`).
"""
function fit_gllvmtmb_parity_delta(y::AbstractMatrix, K::Integer; family::Symbol)
    family in (:delta_lognormal, :delta_gamma) ||
        throw(ArgumentError("unsupported delta parity family: $family"))
    p, n = size(y)
    fam = String(family)
    _parity_require_gllvmtmb!()
    @rput y K p n fam

    R"""
    trait_names <- paste0("t", seq_len(p))
    df_long <- data.frame(
        site  = factor(rep(seq_len(n), each = p)),
        trait = factor(rep(trait_names, times = n), levels = trait_names),
        value = as.vector(y)   # column-major on p×n ⇒ site blocks
    )
    fam_obj <- switch(fam,
        delta_lognormal = gllvmTMB::delta_lognormal(),
        delta_gamma     = gllvmTMB::delta_gamma(),
        stop(sprintf("unknown family: %s", fam))
    )
    fit_r <- gllvmTMB(
        value ~ 0 + trait + latent(0 + trait | site, d = K, unique = FALSE),
        data = df_long,
        unit = "site",
        trait = "trait",
        family = fam_obj,
        control = gllvmTMBcontrol(n_init = 1L, se = FALSE)
    )
    pl <- fit_r$tmb_obj$env$parList(fit_r$opt$par)
    disp_vec <- if (identical(fam, "delta_lognormal")) {
        as.numeric(fit_r$report$sigma_lognormal_delta)
    } else {
        as.numeric(fit_r$report$phi_gamma_delta)
    }
    .gllvm_parity_delta <<- list(
        logL      = as.numeric(stats::logLik(fit_r)),
        objective = as.numeric(fit_r$opt$objective),
        converged = identical(as.integer(fit_r$opt$convergence), 0L),
        b_fix     = as.numeric(pl$b_fix),
        disp_vec  = disp_vec
    )
    invisible(NULL)
    """

    return (
        logLik = rcopy(Float64, R".gllvm_parity_delta$logL"),
        objective = rcopy(Float64, R".gllvm_parity_delta$objective"),
        converged = rcopy(Bool, R".gllvm_parity_delta$converged"),
        b_fix = rcopy(Vector{Float64}, R".gllvm_parity_delta$b_fix"),
        disp_vec = rcopy(Vector{Float64}, R".gllvm_parity_delta$disp_vec"),
    )
end

"""
    fit_gllvmtmb_parity_student(y, K; df_fixed) -> NamedTuple

Twin oracle for the Student-t family (`gllvmTMB::student()`, fid 9,
identity link). `df_fixed` is passed straight to `student(df = df_fixed)`
so BOTH sides hold degrees of freedom fixed at the same value — the twin's
own default is to ESTIMATE df per trait (`student(df = NULL)`), which is
not the same model as Julia's `fit_studentt_gllvm` (fixed scalar `nu`); see
`docs/dev-log/decisions/2026-08-28-studentt-parameterisation.md`. Fixing
`df` on the twin isolates the ONE remaining structural difference: the
twin's `log_sigma_student` is a PER-TRAIT `n_traits`-length TMB parameter
(`gllvmTMB.cpp:1184`; no shared/pinned mode is exposed through the family
constructor or `dispersion_trait_map()`), while Julia's `fit_studentt_gllvm`
estimates a single SHARED scalar `σ`. This mirrors
[`fit_gllvmtmb_parity_delta`](@ref) exactly, for the same reason.

Returns `(logLik, objective, converged, b_fix, sigma_vec, df_vec)`: `b_fix`
is the twin's trait-intercept vector (length `p`); `sigma_vec` /`df_vec` are
the reported per-trait `sigma_student` / `df_student` vectors (length `p`).
Per the parameterisation note, `df_vec` should equal `df_fixed` on every
trait (fixed, not estimated) — assert that in the caller before trusting a
logLik Δ as dispersion-only.
"""
function fit_gllvmtmb_parity_student(y::AbstractMatrix, K::Integer; df_fixed::Union{Nothing, Real} = nothing)
    df_fixed !== nothing && (df_fixed > 1 || throw(ArgumentError("student(): df_fixed must be > 1; got $df_fixed")))
    p, n = size(y)
    _parity_require_gllvmtmb!()
    dfv = df_fixed === nothing ? nothing : Float64(df_fixed)
    @rput y K p n dfv

    R"""
    trait_names <- paste0("t", seq_len(p))
    df_long <- data.frame(
        site  = factor(rep(seq_len(n), each = p)),
        trait = factor(rep(trait_names, times = n), levels = trait_names),
        value = as.vector(y)   # column-major on p×n ⇒ site blocks
    )
    fam_obj <- if (is.null(dfv)) {
        gllvmTMB::student(link = "identity")
    } else {
        gllvmTMB::student(link = "identity", df = dfv)
    }
    fit_r <- gllvmTMB(
        value ~ 0 + trait + latent(0 + trait | site, d = K, unique = FALSE),
        data = df_long,
        unit = "site",
        trait = "trait",
        family = fam_obj,
        control = gllvmTMBcontrol(n_init = 1L, se = FALSE)
    )
    pl <- fit_r$tmb_obj$env$parList(fit_r$opt$par)
    .gllvm_parity_student <<- list(
        logL      = as.numeric(stats::logLik(fit_r)),
        objective = as.numeric(fit_r$opt$objective),
        converged = identical(as.integer(fit_r$opt$convergence), 0L),
        b_fix     = as.numeric(pl$b_fix),
        sigma_vec = as.numeric(fit_r$report$sigma_student),
        df_vec    = as.numeric(fit_r$report$df_student)
    )
    invisible(NULL)
    """

    return (
        logLik = rcopy(Float64, R".gllvm_parity_student$logL"),
        objective = rcopy(Float64, R".gllvm_parity_student$objective"),
        converged = rcopy(Bool, R".gllvm_parity_student$converged"),
        b_fix = rcopy(Vector{Float64}, R".gllvm_parity_student$b_fix"),
        sigma_vec = rcopy(Vector{Float64}, R".gllvm_parity_student$sigma_vec"),
        df_vec = rcopy(Vector{Float64}, R".gllvm_parity_student$df_vec"),
    )
end
