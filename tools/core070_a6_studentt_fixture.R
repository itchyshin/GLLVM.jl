# A6 Student-t interior-nu paired fixture -- R stage (maintainer round2-3 #11).
#
# Fits the frozen gllvmTMB 0.7.0 `student()` family (families.R:367-381,
# `student(link = "identity")` -- estimates degrees of freedom unless `df` is
# supplied, matching GLLVM.jl's `StudentTFamily()` default) on the SAME
# response matrix the Julia stage generated at a moderate INTERIOR nu (the
# panel's finding-4 fixture pushed estimated nu to the flat Gaussian-limit
# boundary on pure-Gaussian data; this fixture is deliberately genuinely
# heavy-tailed so both engines are expected to land INTERIOR).
#
# House convention: argv 2, base-R only (no jsonlite dependency) -- a flat
# `key<TAB>[index<TAB>]value` table, sprintf("%.17g", .) for every numeric,
# mirroring tools/core070_student_warmstart_readback.R and
# tools/core070_aghq_frozen_reference.R. Never `library(gllvmTMB)` at parse
# time inside a `Filter`/`substitute` trick -- this script does a genuine
# live fit, not a frozen-helper extraction.
#
# argv[1]: path to the Y matrix (p rows x n columns, whitespace-delimited,
#          written by the Julia stage's generation pass -- `read.table`).
# argv[2]: output path for this script's TSV readback.
#
# K (latent dimension) is a FIXED design constant of this specific fixture
# (K = 1), not a runtime argument -- matching the argv-2 house convention,
# where only data/output paths are positional and fixture design constants
# are frozen in both sibling scripts and the contract JSON.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L)
data_path <- args[[1L]]
output_path <- args[[2L]]
stopifnot(file.exists(data_path))

K <- 1L

Y <- as.matrix(read.table(data_path, header = FALSE))
p <- nrow(Y); n <- ncol(Y)
stopifnot(p >= 2L, n >= 2L)

library(gllvmTMB)

trait_levels <- paste0("t", seq_len(p))
df <- data.frame(
  site  = factor(rep(seq_len(n), each = p)),
  trait = factor(rep(trait_levels, times = n), levels = trait_levels),
  value = as.vector(Y)
)

fit_warnings <- character()
fit <- withCallingHandlers(
  gllvmTMB(
    value ~ 0 + trait + latent(0 + trait | site, d = K, unique = FALSE),
    data = df, unit = "site", trait = "trait",
    family = student(link = "identity"),
    control = gllvmTMBcontrol(se = FALSE)
  ),
  warning = function(w) {
    fit_warnings <<- c(fit_warnings, conditionMessage(w))
    invokeRestart("muffleWarning")
  }
)

opt <- fit$opt
obj <- fit$tmb_obj
pars <- opt$par
gradient <- as.numeric(obj$gr(pars))
report <- obj$report(obj$env$last.par)
par_list <- obj$env$parList(x = pars, par = obj$env$last.par)

# Inline health check, mirroring test/parity/r_health.R's
# core070_tweedie_health() shape (optimizer code + finiteness + a
# scaled-gradient bound) but specialised to the student() family's own
# boundary: `log_df_student` running large positive is the ν -> infinity
# Gaussian-limit boundary this fixture is designed to sit AWAY from (finding
# 4, docs/dev-log/core070/parity-panel-2026-09-01.md).
nu_boundary_max <- 1e6
g_tol <- 1e-3
optimizer_ok <- isTRUE(as.integer(opt$convergence) == 0L)
finite_objective <- length(opt$objective) == 1L && is.finite(opt$objective)
finite_parameters <- is.numeric(pars) && length(pars) > 0L && all(is.finite(pars))
finite_gradient <- is.numeric(gradient) && length(gradient) == length(pars) && all(is.finite(gradient))
scaled_gradient <- if (finite_gradient && finite_objective) {
  max(abs(gradient)) / max(1, abs(opt$objective))
} else Inf
sigma_student <- as.numeric(report$sigma_student)
df_student <- as.numeric(report$df_student)
nu_at_boundary <- length(df_student) > 0L && any(is.finite(df_student) & df_student > nu_boundary_max)
healthy <- optimizer_ok && finite_objective && finite_parameters && finite_gradient &&
  scaled_gradient <= g_tol && !nu_at_boundary && all(is.finite(sigma_student)) && all(sigma_student > 0)

lines <- character(0)
push <- function(key, value) {
  lines[[length(lines) + 1L]] <<- paste(key, sprintf("%.17g", value), sep = "\t")
}
push_vec <- function(key, values) {
  for (i in seq_along(values)) {
    lines[[length(lines) + 1L]] <<- paste(key, i, sprintf("%.17g", values[[i]]), sep = "\t")
  }
}

push("p", p)
push("K", K)
push("n", n)
push("loglik", -opt$objective)   # opt$objective is the NEGATIVE log-likelihood
push("optimizer_convergence_code", opt$convergence)
push("healthy", as.integer(healthy))
push("nu_at_boundary", as.integer(nu_at_boundary))
push("scaled_gradient", scaled_gradient)
push_vec("beta", as.numeric(par_list$b_fix))
push_vec("sigma_student", sigma_student)
push_vec("df_student", df_student)
push_vec("loading", as.numeric(as.matrix(report$Lambda_B)))
lines[[length(lines) + 1L]] <- paste("n_warnings", length(fit_warnings), sep = "\t")

writeLines(lines, output_path)
cat("CORE070_A6_STUDENTT_R_FIT_PASS", output_path, "\n")
