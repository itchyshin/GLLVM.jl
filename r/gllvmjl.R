# gllvmjl.R — an R front end to GLLVM.jl via JuliaConnectoR.
#
# Goal: let R users drive the fast Julia engine (GLLVM.jl) without leaving R —
# the same idea as the DRM.jl R bridge. Data go R -> Julia as plain matrices;
# results come back through the package's array/table-returning accessors
# (coef_table, getLV, getLoadings, ordiplot, predict, residuals), which
# JuliaConnectoR converts cleanly to R objects.
#
# STATUS: scaffold. It was written without an R or Julia runtime available, so it
# has NOT been executed — verify in a real R + Julia environment before relying on
# it. Mirroring the proven DRM.jl bridge (once available) may simplify parts.
#
# Setup (once):
#   install.packages("JuliaConnectoR")
#   # Julia >= 1.10 with GLLVM.jl installed:  using Pkg; Pkg.add(url="https://github.com/itchyshin/GLLVM.jl")
#
# Usage:
#   source("gllvmjl.R"); gllvm_jl_init()
#   Y   <- matrix(rpois(6*120, 3), nrow = 6)          # p species x n sites
#   fit <- gllvm_fit(Y, family = "poisson", K = 2)
#   gllvm_coeftable(fit, Y)
#   ord <- gllvm_ordiplot(fit, Y)                      # $sites, $species, $axis_prop
#   plot(ord$sites[,1], ord$sites[,2])

library(JuliaConnectoR)

.gllvm_env <- new.env(parent = emptyenv())

#' Import GLLVM.jl into the session (call once).
gllvm_jl_init <- function() {
  .gllvm_env$GLLVM <- juliaImport("GLLVM")
  invisible(TRUE)
}

.gllvm <- function() {
  if (is.null(.gllvm_env$GLLVM)) gllvm_jl_init()
  .gllvm_env$GLLVM
}

# Map an R family string to the Julia fitter. method = "laplace" (default) or "va"
# (variational, where available). Returns an (opaque) Julia fit object.
.fitters <- list(
  poisson = list(laplace = "fit_poisson_gllvm",  va = "fit_poisson_gllvm_va"),
  nb      = list(laplace = "fit_nb_gllvm",        va = "fit_nb_gllvm_va"),
  binomial= list(laplace = "fit_binomial_gllvm",  va = "fit_binomial_gllvm_va"),
  beta    = list(laplace = "fit_beta_gllvm",      va = "fit_beta_gllvm_va"),
  gamma   = list(laplace = "fit_gamma_gllvm",     va = "fit_gamma_gllvm_va"),
  ordinal = list(laplace = "fit_ordinal_gllvm"),
  gaussian= list(laplace = "fit_gaussian_gllvm")
)

#' Fit a GLLVM in Julia.
#' @param Y p x n response matrix (species x sites).
#' @param family one of names(.fitters).
#' @param K number of latent variables.
#' @param method "laplace" (default) or "va" (variational).
#' @param N optional p x n trial counts (binomial).
gllvm_fit <- function(Y, family = "poisson", K = 2L, method = "laplace", N = NULL) {
  G <- .gllvm()
  family <- match.arg(family, names(.fitters))
  fn <- .fitters[[family]][[method]]
  if (is.null(fn)) stop(sprintf("method '%s' not available for family '%s'", method, family))
  fitter <- G[[fn]]
  Ym <- as.matrix(Y); storage.mode(Ym) <- if (family %in% c("beta","gamma","gaussian")) "double" else "integer"
  if (family == "binomial" && !is.null(N)) {
    fitter(Ym, N = as.matrix(N), K = as.integer(K))
  } else {
    fitter(Ym, K = as.integer(K))
  }
}

#' Tidy Wald coefficient table (data.frame): term, estimate, std.error, z, p, lower, upper.
gllvm_coeftable <- function(fit, Y) {
  G <- .gllvm(); ct <- G$coef_table(fit, as.matrix(Y))
  data.frame(
    term      = as.character(juliaGet(ct$term)),
    estimate  = as.numeric(juliaGet(ct$estimate)),
    std.error = as.numeric(juliaGet(ct$std_error)),
    z         = as.numeric(juliaGet(ct$z)),
    p.value   = as.numeric(juliaGet(ct$pvalue)),
    lower     = as.numeric(juliaGet(ct$lower)),
    upper     = as.numeric(juliaGet(ct$upper)),
    stringsAsFactors = FALSE
  )
}

#' Latent-variable (site) scores, n x K.
gllvm_getLV <- function(fit, Y) as.matrix(.gllvm()$getLV(fit, as.matrix(Y)))

#' Species loadings, p x K.
gllvm_getLoadings <- function(fit) as.matrix(.gllvm()$getLoadings(fit))

#' Ordination biplot data: list(sites, species, axis_prop, site_labels, species_labels).
gllvm_ordiplot <- function(fit, Y, biplot = TRUE, rotate = TRUE) {
  o <- .gllvm()$ordiplot(fit, as.matrix(Y), biplot = biplot, rotate = rotate)
  list(
    sites          = as.matrix(juliaGet(o$sites)),
    species        = as.matrix(juliaGet(o$species)),
    axis_prop      = as.numeric(juliaGet(o$axis_prop)),
    site_labels    = as.character(juliaGet(o$site_labels)),
    species_labels = as.character(juliaGet(o$species_labels))
  )
}

#' Predicted means (type = "response") or linear predictor (type = "link"), p x n.
gllvm_predict <- function(fit, Y, type = "response") {
  as.matrix(.gllvm()$predict(fit, as.matrix(Y), type = juliaCall("Symbol", type)))
}

#' Dunn-Smyth residuals, p x n.
gllvm_residuals <- function(fit, Y) as.matrix(.gllvm()$residuals(fit, as.matrix(Y)))

#' Information criteria.
gllvm_aic <- function(fit) as.numeric(.gllvm()$aic(fit))
gllvm_bic <- function(fit, n) as.numeric(.gllvm()$bic(fit, as.integer(n)))
