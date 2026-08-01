# parity_helpers.jl — shared RCall / gllvmTMB helpers for opt-in parity cells.
#
# Included by family test files under test/parity/. Never included by runtests.jl.
# Twin call shape: gllvmTMB (not CRAN gllvm), latent(..., unique = FALSE),
# extractors via stats::logLik / -opt$objective.
# Source: docs/dev-log/plans/scratch/2026-08-01-gaussian-rcall-shape.md

using RCall

function _parity_require_gllvmtmb!()
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
    fit_gllvmtmb_parity_loglik(y, K; family) -> NamedTuple

Fit `gllvmTMB` on a Julia `p × n` response matrix with the twin-aligned
no-X formula:

```
value ~ 0 + trait + latent(0 + trait | site, d = K, unique = FALSE)
```

`family` ∈ `(:gaussian, :binomial, :poisson)`. Returns
`(logLik, objective, converged)`.
"""
function fit_gllvmtmb_parity_loglik(y::AbstractMatrix, K::Integer; family::Symbol)
    family in (:gaussian, :binomial, :poisson) ||
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
        gaussian = stats::gaussian(),
        binomial = stats::binomial(),
        poisson  = stats::poisson(),
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
