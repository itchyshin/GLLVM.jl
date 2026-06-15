# parity_check.R — numerical-parity harness: R gllvm vs GLLVM.jl (via the bridge).
#
# `compare_gllvm(y, ...)` fits the SAME data with
#   (a) R gllvm::gllvm(...)        — if {gllvm} is installed, and
#   (b) gllvm_julia(...)           — the JuliaConnectoR bridge in gllvmtmb_julia.R,
# then prints a side-by-side table of logLik, intercepts beta, loadings (Procrustes-
# aligned, since loadings are identifiable only up to rotation/sign), and dispersion
# AFTER the gllvm-convention conversion (e.g. NB phi = 1/r), with max abs / relative
# differences. This is the validation the maintainer runs to confirm parity.
#
# REQUIREMENTS (NOT available in the authoring environment — run locally):
#   * R package {gllvm} (the gllvmTMB engine) installed, AND
#   * a Julia with GLLVM.jl available + {JuliaConnectoR} in R.
# This script was authored WITHOUT either runtime; treat numbers/tolerances as a
# starting point and verify in a live R + Julia session.
#
# Usage:
#   source("r/gllvmtmb_julia.R"); source("r/parity_check.R")
#   gllvm_jl_init()
#   set.seed(1); y <- matrix(rpois(150 * 8, 3), nrow = 150)  # n=150 sites x p=8 species
#   compare_gllvm(y, family = "poisson", num.lv = 2, method = "LA")

# Procrustes-align B (p x K) to A (p x K) via the orthogonal/sign rotation that best
# matches B to A (SVD of A'B). Returns the rotated B so loadings are comparable.
.procrustes <- function(A, B) {
  if (is.null(A) || is.null(B)) return(B)
  if (!all(dim(A) == dim(B))) return(B)
  s <- svd(t(A) %*% B)
  R <- s$v %*% t(s$u)              # rotation aligning B's column space to A's
  B %*% R
}

.maxdiff <- function(a, b) {
  if (is.null(a) || is.null(b) || length(a) != length(b)) return(c(abs = NA, rel = NA))
  a <- as.numeric(a); b <- as.numeric(b)
  d <- abs(a - b)
  rel <- d / pmax(abs(a), 1e-8)
  c(abs = max(d, na.rm = TRUE), rel = max(rel, na.rm = TRUE))
}

# Extract gllvm-side pieces in a normalized shape: list(logLik, beta, loadings, disp).
# gllvm stores beta0 (species intercepts) and theta (loadings, p x num.lv). Dispersion
# is in $params$phi (NB/beta/gamma/tweedie). gllvm y is n x p, loadings are p x K.
.gllvm_scaled_loadings <- function(fit, theta) {
  if (is.null(theta)) return(NULL)
  theta <- as.matrix(theta)
  sigma_lv <- tryCatch(as.numeric(fit$params$sigma.lv), error = function(e) NULL)
  if (is.null(sigma_lv) || length(sigma_lv) < ncol(theta)) return(theta)
  scales <- tail(sigma_lv, ncol(theta))
  if (!all(is.finite(scales))) return(theta)
  sweep(theta, 2L, scales, `*`)
}

.extract_gllvm <- function(fit) {
  ll  <- tryCatch(as.numeric(logLik(fit)), error = function(e) NA_real_)
  b0  <- tryCatch(as.numeric(fit$params$beta0), error = function(e) NA_real_)
  th  <- tryCatch(as.matrix(fit$params$theta), error = function(e) NULL)   # p x num.lv
  th  <- .gllvm_scaled_loadings(fit, th)
  phi <- tryCatch(as.numeric(fit$params$phi),  error = function(e) NA_real_)
  list(logLik = ll, beta = b0, loadings = th, disp = phi)
}

.extract_julia <- function(fit) {
  list(logLik = fit$logLik, beta = fit$coefficients,
       loadings = fit$loadings, disp = fit$dispersion$value)
}

#' Compare an R gllvm fit and a GLLVM.jl bridge fit on the same data.
#'
#' @param y       n x p response matrix (gllvm orientation: sites x species).
#' @param family  gllvm family string (passed to BOTH engines).
#' @param num.lv  number of latent variables.
#' @param method  "LA" or "VA" — passed to the bridge; for the R side, gllvm's
#'                `method` is set to match ("LA"/"VA"). Pin them so finite-sample
#'                LA vs VA differences don't masquerade as bridge errors.
#' @param disp.formula  NULL (per-species, gllvm default) or ~1 (shared) — passed to BOTH.
#' @param row.eff "none"/"fixed"/"random" — passed to BOTH.
#' @param ...     extra args forwarded to gllvm_julia (e.g. link, N, g_tol).
#' @return (invisibly) a list with both fits and the per-quantity diffs.
compare_gllvm <- function(y, family = "negative.binomial", num.lv = 2L,
                          method = c("LA", "VA"), disp.formula = NULL,
                          row.eff = "none", ...) {
  method <- toupper(match.arg(method))

  # ---- (a) R gllvm (optional) ----
  have_gllvm <- requireNamespace("gllvm", quietly = TRUE)
  r_fit <- NULL; r <- NULL
  if (have_gllvm) {
    r_args <- list(y = y, num.lv = as.integer(num.lv), family = family,
                   method = method, row.eff = row.eff)
    if (!is.null(disp.formula)) r_args$disp.formula <- disp.formula
    r_fit <- tryCatch(do.call(gllvm::gllvm, r_args),
                      error = function(e) { message("R gllvm fit failed: ", conditionMessage(e)); NULL })
    if (!is.null(r_fit)) r <- .extract_gllvm(r_fit)
  } else {
    message("Package {gllvm} not installed — running the Julia side only; ",
            "install.packages('gllvm') for a true side-by-side parity check.")
  }

  # ---- (b) GLLVM.jl via the bridge ----
  if (!exists("gllvm_julia", mode = "function"))
    stop("gllvm_julia() not found — source('r/gllvmtmb_julia.R') first.")
  j_fit <- gllvm_julia(y, family = family, num.lv = num.lv, method = method,
                       disp.formula = disp.formula, row.eff = row.eff, ...)
  j <- .extract_julia(j_fit)

  # ---- side-by-side report ----
  cat("\n=== GLLVM parity: R gllvm vs GLLVM.jl ===\n")
  cat(sprintf("family=%s  num.lv=%d  method=%s  row.eff=%s  disp=%s\n\n",
              family, as.integer(num.lv), method, row.eff,
              if (is.null(disp.formula)) "per-species(NULL)" else deparse(disp.formula)))

  diffs <- list()
  if (!is.null(r)) {
    cat(sprintf("logLik:   R = %.6f   Julia = %.6f   |diff| = %.3e\n",
                r$logLik, j$logLik, abs(r$logLik - j$logLik)))
    diffs$logLik <- abs(r$logLik - j$logLik)

    db <- .maxdiff(r$beta, j$beta)
    cat(sprintf("beta:     max|diff| = %.3e   max rel = %.3e   (length %d)\n",
                db["abs"], db["rel"], length(j$beta)))
    diffs$beta <- db

    # loadings: Procrustes-align the Julia loadings to the R loadings first.
    Jload <- .procrustes(r$loadings, j$loadings)
    dl <- .maxdiff(r$loadings, Jload)
    cat(sprintf("loadings: max|diff| = %.3e   max rel = %.3e   (Procrustes-aligned, %s)\n",
                dl["abs"], dl["rel"],
                if (!is.null(j$loadings)) paste(dim(j$loadings), collapse = "x") else "NA"))
    diffs$loadings <- dl

    if (!all(is.na(r$disp)) && !all(is.na(j$disp))) {
      dd <- .maxdiff(r$disp, j$disp)
      cat(sprintf("dispersion (%s, gllvm convention): max|diff| = %.3e   max rel = %.3e\n",
                  j_fit$dispersion$name, dd["abs"], dd["rel"]))
      diffs$disp <- dd
    } else {
      cat("dispersion: (none for this family, or not comparable)\n")
    }
  } else {
    cat(sprintf("Julia-only: logLik = %.6f\n", j$logLik))
    cat(sprintf("Julia beta (length %d), loadings (%s)\n", length(j$beta),
                if (!is.null(j$loadings)) paste(dim(j$loadings), collapse = "x") else "NA"))
    if (!is.na(j_fit$dispersion$name))
      cat(sprintf("Julia dispersion (%s, gllvm convention) = %s\n",
                  j_fit$dispersion$name, paste(format(j$disp, digits = 4), collapse = ", ")))
  }
  cat("\nNOTE: loadings agree only up to rotation/sign — they are Procrustes-aligned\n",
      "before differencing. LA vs VA differ in finite samples; pin `method` to match.\n", sep = "")

  invisible(list(r_fit = r_fit, julia_fit = j_fit, diffs = diffs))
}
