#!/usr/bin/env Rscript
# Frozen-R receipt for one joint, replicated Gaussian B1 grouping fit.
# It only reads the supplied frozen source/build.

parse_args <- function(args) {
  out <- list()
  length(args) %% 2L == 0L || stop("Arguments must be --name PATH pairs.")
  for (i in seq.int(1L, length(args), by = 2L)) {
    key <- args[[i]]; value <- args[[i + 1L]]
    key %in% c("--source", "--library", "--output") || stop("Unknown argument: ", key)
    out[[substring(key, 3L)]] <- value
  }
  missing <- setdiff(c("source", "library", "output"), names(out))
  !length(missing) || stop("Missing: ", paste(missing, collapse = ", "))
  out
}
args <- parse_args(commandArgs(trailingOnly = TRUE))
source_dir <- normalizePath(args$source, mustWork = TRUE)
library_dir <- normalizePath(args$library, mustWork = TRUE)
output_path <- normalizePath(args$output, mustWork = FALSE)
dir.exists(dirname(output_path)) || stop("Output parent does not exist.")
expected_sha <- "b4d5fee64def88bc768dda1f1f77c29b295edd86"
expected_version <- "0.7.0"

sha256_file <- function(path) {
  result <- suppressWarnings(system2("shasum", c("-a", "256", path), stdout = TRUE, stderr = TRUE))
  is.null(attr(result, "status")) || attr(result, "status") == 0L || stop("SHA-256 failed.")
  strsplit(trimws(paste(result, collapse = "\n")), "[[:space:]]+")[[1L]][1L]
}
run_git <- function(...) {
  result <- suppressWarnings(system2("git", c("-C", source_dir, ...), stdout = TRUE, stderr = TRUE))
  is.null(attr(result, "status")) || attr(result, "status") == 0L || stop("git validation failed.")
  trimws(paste(result, collapse = "\n"))
}
identical(run_git("rev-parse", "HEAD"), expected_sha) || stop("Frozen source SHA mismatch.")
desc <- read.dcf(file.path(source_dir, "DESCRIPTION"))
identical(unname(desc[1L, "Version"]), expected_version) || stop("Frozen source Version mismatch.")
archive <- tempfile("gllvmTMB-frozen-r070-b1-joint-", fileext = ".tar")
archive_result <- system2("git", c("-C", source_dir, "archive", "--format=tar", paste0("--output=", archive), expected_sha), stdout = TRUE, stderr = TRUE)
is.null(attr(archive_result, "status")) || attr(archive_result, "status") == 0L || stop("Frozen archive failed.")
archive_sha256 <- sha256_file(archive); unlink(archive)

requireNamespace("jsonlite", quietly = TRUE) || stop("jsonlite is required.")
marker_path <- file.path(library_dir, "gllvmTMB-frozen-source-identity.json")
marker <- jsonlite::fromJSON(marker_path, simplifyVector = FALSE)
shared <- list.files(file.path(library_dir, "gllvmTMB", "libs"), pattern = "^gllvmTMB\\.(so|dylib)$", full.names = TRUE)
length(shared) == 1L || stop("Expected one installed shared library.")
shared <- normalizePath(shared[[1L]], mustWork = TRUE)
shared_sha256 <- sha256_file(shared)
identical(marker$source_sha, expected_sha) || stop("Frozen-library source SHA marker mismatch.")
identical(marker$source_version, expected_version) || stop("Frozen-library Version marker mismatch.")
identical(marker$source_archive_sha256, archive_sha256) || stop("Frozen-library archive marker mismatch.")
identical(marker$installed_shared_library_sha256, shared_sha256) || stop("Frozen-library shared-library marker mismatch.")

.libPaths(c(library_dir, .libPaths()))
library("gllvmTMB", lib.loc = library_dir, character.only = TRUE)
loaded_path <- normalizePath(find.package("gllvmTMB"), mustWork = TRUE)
identical(loaded_path, normalizePath(file.path(library_dir, "gllvmTMB"), mustWork = TRUE)) || stop("Wrong loaded package.")
identical(as.character(packageVersion("gllvmTMB")), expected_version) || stop("Loaded Version mismatch.")
as_value <- function(x) {
  if (is.null(x)) return(NULL)
  if (is.matrix(x)) { dimnames(x) <- NULL; return(x) }
  if (is.atomic(x)) return(unname(x))
  x
}
field <- function(x, name) if (is.list(x) && name %in% names(x)) as_value(x[[name]]) else NULL
runner_arg <- commandArgs()[grepl("^--file=", commandArgs())]
length(runner_arg) == 1L || stop("Could not identify runner path.")
runner_path <- normalizePath(sub("^--file=", "", runner_arg), mustWork = TRUE)

set.seed(20260913L)
n_trait <- 2L; n_unit <- 6L; n_obs_per_unit <- 2L; n_rep <- 3L
n_cluster <- 4L; n_cluster2 <- 3L
design <- do.call(rbind, lapply(seq_len(n_unit), function(unit_index) {
  local_obs <- rep(seq_len(n_obs_per_unit), each = n_rep)
  position <- seq_along(local_obs)
  data.frame(unit = paste0("unit_", unit_index),
    obs = paste0("unit_", unit_index, "_obs_", local_obs),
    cluster_id = paste0("cluster_", ((position - 1L) %% n_cluster) + 1L),
    cluster2_id = paste0("cluster2_", c(1L, 1L, 2L, 2L, 3L, 3L)[position]),
    replicate = ((position - 1L) %% n_rep) + 1L, stringsAsFactors = FALSE)
}))
trait_levels <- paste0("trait_", seq_len(n_trait))
rows <- design[rep(seq_len(nrow(design)), each = n_trait), , drop = FALSE]
rows$trait <- rep(trait_levels, times = nrow(rows) %/% n_trait)
lambda <- c(0.58, -0.37)
z_unit <- rnorm(n_unit)
sd_obs <- c(0.34, 0.24); sd_cluster <- c(0.29, 0.20); sd_cluster2 <- c(0.23, 0.16)
a_obs <- rbind(rnorm(n_unit * n_obs_per_unit, sd = sd_obs[1L]), rnorm(n_unit * n_obs_per_unit, sd = sd_obs[2L]))
q_cluster <- rbind(rnorm(n_cluster, sd = sd_cluster[1L]), rnorm(n_cluster, sd = sd_cluster[2L]))
r_cluster2 <- rbind(rnorm(n_cluster2, sd = sd_cluster2[1L]), rnorm(n_cluster2, sd = sd_cluster2[2L]))
trait_index <- match(rows$trait, trait_levels)
unit_index <- match(rows$unit, paste0("unit_", seq_len(n_unit)))
obs_index <- match(rows$obs, unique(design$obs))
cluster_index <- match(rows$cluster_id, paste0("cluster_", seq_len(n_cluster)))
cluster2_index <- match(rows$cluster2_id, paste0("cluster2_", seq_len(n_cluster2)))
rows$value <- c(-0.18, 0.24)[trait_index] + lambda[trait_index] * z_unit[unit_index] +
  a_obs[cbind(trait_index, obs_index)] + q_cluster[cbind(trait_index, cluster_index)] +
  r_cluster2[cbind(trait_index, cluster2_index)] + rnorm(nrow(rows), sd = 0.21)
data <- data.frame(value = rows$value, trait = factor(rows$trait, levels = trait_levels),
  unit = factor(rows$unit), obs = factor(rows$obs),
  cluster_id = factor(rows$cluster_id, levels = paste0("cluster_", seq_len(n_cluster))),
  cluster2_id = factor(rows$cluster2_id, levels = paste0("cluster2_", seq_len(n_cluster2))),
  replicate = rows$replicate)
data_csv <- tempfile("b1-joint-gaussian-data-", fileext = ".csv")
write.csv(data, data_csv, row.names = FALSE); data_md5 <- unname(tools::md5sum(data_csv)); unlink(data_csv)

formula_text <- "value ~ 0 + trait + latent(0 + trait | unit, d = 1, unique = FALSE) + indep(0 + trait | obs) + indep(0 + trait | cluster_id) + indep(0 + trait | cluster2_id)"
receipt <- list(receipt_kind = "frozen_R_to_Julia_joint_gaussian_optimizer_diagnostic",
  limitations = c("The frozen R reference point is not stationary enough for matched-parameter acceptance on this fixture.", "Direct-coordinate likelihood identity is not independently-refitted parameter parity.", "Not interval validation.", "Not recovery evidence.", "Not B1 qualification."),
  source = list(path = source_dir, git_sha = expected_sha, description_version = expected_version, archive_sha256 = archive_sha256),
  installed = list(library = library_dir, loaded_path = loaded_path, loaded_version = expected_version, marker_path = marker_path, shared_library = shared, shared_library_sha256 = shared_sha256),
  r_runner = list(path = "tools/destination_b/b1_joint_gaussian_reference.R", sha256 = sha256_file(runner_path), R_version = as.character(getRversion())),
  specification = list(formula = formula_text, family = "gaussian()", trait = "trait", unit = "unit", unit_obs = "obs", cluster = "cluster_id", cluster2 = "cluster2_id", REML = FALSE, control = list(n_init = 1L, se = FALSE), optimizer_attempts = list(default = "nlminb", nlminb_tight_same_start = list(eval_max = 10000L, iter_max = 10000L, rel_tol = 1e-12, x_tol = 1e-12, xf_tol = 1e-12), optim_bfgs_same_start = "BFGS", nlminb_multistart_5 = list(n_init = 5L, init_jitter = 0.3)), n_trait = n_trait, n_unit = n_unit, n_unit_obs_per_unit = n_obs_per_unit, n_replicate = n_rep, n_cluster = n_cluster, n_cluster2 = n_cluster2, n_observation = nrow(design), row_order = "unit, unit_obs, replicate, trait", seed = 20260913L, data_md5 = data_md5),
  response_long = list(value = as_value(data$value), trait = as.character(data$trait), unit = as.character(data$unit), obs = as.character(data$obs), cluster_id = as.character(data$cluster_id), cluster2_id = as.character(data$cluster2_id), replicate = data$replicate), mapping = NULL, fit = NULL, acceptance = list(matched_parameter = FALSE, source_gradient_threshold = 1e-6, reason = "Default, tight-control, BFGS, and documented five-start frozen-R attempts do not establish a stationary reference."), failure = list(present = FALSE))

fit_formula <- value ~ 0 + trait + latent(0 + trait | unit, d = 1, unique = FALSE) + indep(0 + trait | obs) + indep(0 + trait | cluster_id) + indep(0 + trait | cluster2_id)
fit_seed <- .Random.seed
run_fit <- function(control, seed_state) {
  assign(".Random.seed", seed_state, envir = .GlobalEnv)
  started <- Sys.time()
  fit <- tryCatch(gllvmTMB::gllvmTMB(fit_formula, data = data, family = gaussian(), trait = "trait", unit = "unit", unit_obs = "obs", cluster = "cluster_id", cluster2 = "cluster2_id", REML = FALSE, control = control), error = function(e) e)
  list(fit = fit, fit_seconds = as.numeric(difftime(Sys.time(), started, units = "secs")))
}
fit_record <- function(fit, fit_seconds) {
  report <- field(fit, "report"); opt <- field(fit, "opt"); tmb_data <- field(fit, "tmb_data")
  opt_par <- opt$par; fitted <- fit$tmb_obj$env$parList(opt_par)
  required <- c("b_fix", "log_sigma_eps", "theta_rr_B", "theta_diag_W", "theta_diag_species", "theta_diag_cluster2")
  all(required %in% names(fitted)) || stop("Frozen R fit lacks a required joint coordinate.")
  Sigma <- function(level) gllvmTMB::extract_Sigma(fit, level = level, part = "total", link_residual = "none")$Sigma
  list(fit_seconds = fit_seconds, logLik = as.numeric(logLik(fit)), convergence = as_value(opt$convergence), optimizer_message = as_value(opt$message), gradient = as_value(fit$tmb_obj$gr(opt_par)), gradient_max_abs = max(abs(fit$tmb_obj$gr(opt_par))), raw_opt_par = list(names = unname(names(opt_par)), values = unname(as.numeric(opt_par))), report_fields = unname(names(report)), b_fix = as_value(fitted$b_fix), log_sigma_eps = as_value(fitted$log_sigma_eps), theta_rr_B = as_value(fitted$theta_rr_B), theta_diag_W = as_value(fitted$theta_diag_W), theta_diag_species = as_value(fitted$theta_diag_species), theta_diag_cluster2 = as_value(fitted$theta_diag_cluster2), Sigma_unit = as_value(Sigma("unit")), Sigma_unit_obs = as_value(Sigma("unit_obs")), Sigma_cluster = as_value(Sigma("cluster")), Sigma_cluster2 = as_value(Sigma("cluster2")), sigma_eps = field(report, "sigma_eps"), mapping = list(trait_levels = as_value(levels(data$trait)), x_fix_names = field(fit, "X_fix_names"), trait_id = field(tmb_data, "trait_id"), unit_id = field(tmb_data, "site_id"), unit_obs_id = field(tmb_data, "site_species_id"), cluster_id = field(tmb_data, "species_id"), cluster2_id = field(tmb_data, "cluster2_id")))
}
default_control <- gllvmTMB::gllvmTMBcontrol(n_init = 1L, se = FALSE)
default_attempt <- run_fit(default_control, fit_seed)
fit <- default_attempt$fit
fit_seconds <- default_attempt$fit_seconds
if (inherits(fit, "error")) {
  receipt$failure <- list(present = TRUE, class = class(fit), message = conditionMessage(fit), fit_seconds = fit_seconds)
} else {
  default_record <- fit_record(fit, fit_seconds)
  receipt$mapping <- default_record$mapping
  default_record$mapping <- NULL
  tight_control <- gllvmTMB::gllvmTMBcontrol(n_init = 1L, se = FALSE,
    optArgs = list(control = list(eval.max = 10000L, iter.max = 10000L,
      rel.tol = 1e-12, x.tol = 1e-12, xf.tol = 1e-12)))
  tight_attempt <- run_fit(tight_control, fit_seed)
  bfgs_control <- gllvmTMB::gllvmTMBcontrol(n_init = 1L, se = FALSE,
    optimizer = "optim", optArgs = list(method = "BFGS"))
  bfgs_attempt <- run_fit(bfgs_control, fit_seed)
  multistart_control <- gllvmTMB::gllvmTMBcontrol(n_init = 5L, se = FALSE)
  multistart_attempt <- run_fit(multistart_control, fit_seed)
  tight_record <- if (inherits(tight_attempt$fit, "error")) {
    list(failure = TRUE, class = class(tight_attempt$fit), message = conditionMessage(tight_attempt$fit), fit_seconds = tight_attempt$fit_seconds)
  } else {
    record <- fit_record(tight_attempt$fit, tight_attempt$fit_seconds); record$mapping <- NULL; record
  }
  if (inherits(bfgs_attempt$fit, "error")) {
    receipt$fit <- c(default_record, list(nlminb_tight_same_start = tight_record, optim_bfgs_same_start = list(failure = TRUE, class = class(bfgs_attempt$fit), message = conditionMessage(bfgs_attempt$fit), fit_seconds = bfgs_attempt$fit_seconds)))
  } else {
    bfgs_record <- fit_record(bfgs_attempt$fit, bfgs_attempt$fit_seconds)
    bfgs_record$mapping <- NULL
    receipt$fit <- c(default_record, list(nlminb_tight_same_start = tight_record, optim_bfgs_same_start = bfgs_record))
  }
  if (inherits(multistart_attempt$fit, "error")) {
    receipt$fit$nlminb_multistart_5 <- list(failure = TRUE, class = class(multistart_attempt$fit), message = conditionMessage(multistart_attempt$fit), fit_seconds = multistart_attempt$fit_seconds)
  } else {
    multistart_record <- fit_record(multistart_attempt$fit, multistart_attempt$fit_seconds)
    multistart_record$mapping <- NULL
    receipt$fit$nlminb_multistart_5 <- multistart_record
  }
}
writeLines(jsonlite::toJSON(receipt, auto_unbox = TRUE, pretty = TRUE, digits = 16, na = "null"), output_path)
if (isTRUE(receipt$failure$present)) quit(status = 1L)
message("Frozen-R joint B1 optimizer-diagnostic receipt written: ", output_path)
