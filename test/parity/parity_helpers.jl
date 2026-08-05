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

`family` ∈ `(:gaussian, :binomial, :poisson, :negbinomial, :beta)`. Returns
`(logLik, objective, converged)`.

For `:negbinomial` / `:beta`, R defaults estimate per-trait dispersion; pair
with Julia grouped fitters (`disp_group=:species`), not shared-dispersion defaults.
"""
function fit_gllvmtmb_parity_loglik(y::AbstractMatrix, K::Integer; family::Symbol)
    family in (:gaussian, :binomial, :poisson, :negbinomial, :beta) ||
        throw(ArgumentError("unsupported parity family: $family"))
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
        gaussian     = stats::gaussian(),
        binomial     = stats::binomial(),
        poisson      = stats::poisson(),
        negbinomial  = gllvmTMB::nbinom2(),
        beta         = gllvmTMB::Beta(),
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

Pair with Julia [`fit_gllvm_speciescov`](@ref) (`B` is `p×q`). Arc 0 starts
with `:poisson` only; other families may need separate dispersion identity.
"""
function fit_gllvmtmb_parity_loglik_species_x(
    y::AbstractMatrix,
    x_site::AbstractVector{<:Real},
    K::Integer;
    family::Symbol,
)
    family in (:poisson,) ||
        throw(ArgumentError("unsupported species-XB parity family (Arc 0): $family"))
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
        poisson = stats::poisson(),
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
