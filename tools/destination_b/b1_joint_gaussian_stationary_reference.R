#!/usr/bin/env Rscript
# Pre-registered frozen-R receipt for one stationary-candidate four-source Gaussian B1 fit.
# It reads the frozen source/build, uses the fixed design in the paired symbolic record,
# and publishes one no-clobber receipt. It never edits or rebuilds the R reference.

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
output_path <- normalizePath(args$output, mustWork = FALSE)
runner_arg <- commandArgs()[grepl("^--file=", commandArgs())]
length(runner_arg) == 1L || stop("Could not identify runner path.")
runner_path <- normalizePath(sub("^--file=", "", runner_arg), mustWork = TRUE)
source(file.path(dirname(runner_path), "b1_joint_gaussian_common.R"))

source_dir <- normalizePath(args$source, mustWork = TRUE)
library_dir <- normalizePath(args$library, mustWork = TRUE)
expected_sha <- "b4d5fee64def88bc768dda1f1f77c29b295edd86"
expected_version <- "0.7.0"
run_git <- function(...) {
  result <- suppressWarnings(system2("git", c("-C", source_dir, ...), stdout = TRUE, stderr = TRUE))
  is.null(attr(result, "status")) || attr(result, "status") == 0L || stop("git validation failed.")
  trimws(paste(result, collapse = "\n"))
}
identical(run_git("rev-parse", "HEAD"), expected_sha) || stop("Frozen source SHA mismatch.")
desc <- read.dcf(file.path(source_dir, "DESCRIPTION"))
identical(unname(desc[1L, "Version"]), expected_version) || stop("Frozen source Version mismatch.")
archive <- tempfile("gllvmTMB-frozen-r070-b1-joint-stationary-", fileext = ".tar")
on.exit(unlink(archive), add = TRUE)
archive_result <- system2("git", c("-C", source_dir, "archive", "--format=tar", paste0("--output=", archive), expected_sha), stdout = TRUE, stderr = TRUE)
is.null(attr(archive_result, "status")) || attr(archive_result, "status") == 0L || stop("Frozen archive failed.")
archive_sha256 <- b1_joint_sha256_file(archive)

requireNamespace("jsonlite", quietly = TRUE) || stop("jsonlite is required.")
marker_path <- file.path(library_dir, "gllvmTMB-frozen-source-identity.json")
marker <- jsonlite::fromJSON(marker_path, simplifyVector = FALSE)
shared <- list.files(file.path(library_dir, "gllvmTMB", "libs"), pattern = "^gllvmTMB\\.(so|dylib)$", full.names = TRUE)
length(shared) == 1L || stop("Expected one installed shared library.")
shared <- normalizePath(shared[[1L]], mustWork = TRUE)
shared_sha256 <- b1_joint_sha256_file(shared)
identical(marker$source_sha, expected_sha) || stop("Frozen-library source SHA marker mismatch.")
identical(marker$source_version, expected_version) || stop("Frozen-library Version marker mismatch.")
identical(marker$source_archive_sha256, archive_sha256) || stop("Frozen-library archive marker mismatch.")
identical(marker$installed_shared_library_sha256, shared_sha256) || stop("Frozen-library shared-library marker mismatch.")
.libPaths(c(library_dir, .libPaths()))
library("gllvmTMB", lib.loc = library_dir, character.only = TRUE)
loaded_path <- normalizePath(find.package("gllvmTMB"), mustWork = TRUE)
identical(loaded_path, normalizePath(file.path(library_dir, "gllvmTMB"), mustWork = TRUE)) || stop("Wrong loaded package.")
identical(as.character(packageVersion("gllvmTMB")), expected_version) || stop("Loaded Version mismatch.")

# This fixture is fixed before execution; do not alter it in response to fit output.
set.seed(20260914L)
n_trait <- 2L; n_unit <- 12L; n_obs_per_unit <- 3L; n_rep <- 5L
n_cluster <- 8L; n_cluster2 <- 7L
wide <- do.call(rbind, lapply(seq_len(n_unit), function(unit_index) {
  do.call(rbind, lapply(seq_len(n_obs_per_unit), function(obs_index) {
    replicate_index <- seq_len(n_rep)
    data.frame(
      unit = paste0("unit_", unit_index),
      obs = paste0("unit_", unit_index, "_obs_", obs_index),
      cluster_id = paste0("cluster_", ((unit_index + 2L * obs_index + 3L * replicate_index - 1L) %% n_cluster) + 1L),
      cluster2_id = paste0("cluster2_", ((2L * unit_index + obs_index + 4L * replicate_index - 1L) %% n_cluster2) + 1L),
      replicate = replicate_index,
      stringsAsFactors = FALSE
    )
  }))
}))
trait_levels <- paste0("trait_", seq_len(n_trait))
rows <- wide[rep(seq_len(nrow(wide)), each = n_trait), , drop = FALSE]
rows$trait <- rep(trait_levels, times = nrow(wide))
lambda <- c(0.72, -0.51)
z_unit <- rnorm(n_unit)
sd_obs <- c(0.36, 0.27); sd_cluster <- c(0.43, 0.32); sd_cluster2 <- c(0.38, 0.29)
a_obs <- rbind(rnorm(n_unit * n_obs_per_unit, sd = sd_obs[1L]), rnorm(n_unit * n_obs_per_unit, sd = sd_obs[2L]))
q_cluster <- rbind(rnorm(n_cluster, sd = sd_cluster[1L]), rnorm(n_cluster, sd = sd_cluster[2L]))
r_cluster2 <- rbind(rnorm(n_cluster2, sd = sd_cluster2[1L]), rnorm(n_cluster2, sd = sd_cluster2[2L]))
trait_index <- match(rows$trait, trait_levels)
unit_index <- match(rows$unit, paste0("unit_", seq_len(n_unit)))
obs_index <- match(rows$obs, unique(wide$obs))
cluster_index <- match(rows$cluster_id, paste0("cluster_", seq_len(n_cluster)))
cluster2_index <- match(rows$cluster2_id, paste0("cluster2_", seq_len(n_cluster2)))
rows$value <- c(-0.20, 0.27)[trait_index] + lambda[trait_index] * z_unit[unit_index] +
  a_obs[cbind(trait_index, obs_index)] + q_cluster[cbind(trait_index, cluster_index)] +
  r_cluster2[cbind(trait_index, cluster2_index)] + rnorm(nrow(rows), sd = 0.17)
data <- data.frame(value = rows$value, trait = factor(rows$trait, levels = trait_levels),
  unit = factor(rows$unit), obs = factor(rows$obs),
  cluster_id = factor(rows$cluster_id, levels = paste0("cluster_", seq_len(n_cluster))),
  cluster2_id = factor(rows$cluster2_id, levels = paste0("cluster2_", seq_len(n_cluster2))),
  replicate = rows$replicate)
data_csv <- tempfile("b1-joint-gaussian-stationary-data-", fileext = ".csv")
on.exit(unlink(data_csv), add = TRUE)
write.csv(data, data_csv, row.names = FALSE)
data_md5 <- unname(tools::md5sum(data_csv))
formula_text <- "value ~ 0 + trait + latent(0 + trait | unit, d = 1, unique = FALSE) + indep(0 + trait | obs) + indep(0 + trait | cluster_id) + indep(0 + trait | cluster2_id)"
fit_formula <- value ~ 0 + trait + latent(0 + trait | unit, d = 1, unique = FALSE) + indep(0 + trait | obs) + indep(0 + trait | cluster_id) + indep(0 + trait | cluster2_id)
control <- gllvmTMB::gllvmTMBcontrol(n_init = 1L, se = FALSE,
  optArgs = list(control = list(eval.max = 100000L, iter.max = 100000L,
    rel.tol = 1e-12, x.tol = 1e-12, xf.tol = 1e-12)))
started <- Sys.time()
fit <- tryCatch(gllvmTMB::gllvmTMB(fit_formula, data = data, family = gaussian(),
  trait = "trait", unit = "unit", unit_obs = "obs", cluster = "cluster_id", cluster2 = "cluster2_id",
  REML = FALSE, control = control), error = function(e) e)
fit_seconds <- as.numeric(difftime(Sys.time(), started, units = "secs"))

receipt <- list(
  receipt_kind = "frozen_R_to_Julia_joint_gaussian_stationary_reference",
  limitations = c("One pre-registered Gaussian ML fixture only.", "Not interval validation.", "Not recovery evidence.", "Not B1 qualification."),
  source = list(path = source_dir, git_sha = expected_sha, description_version = expected_version, archive_sha256 = archive_sha256),
  installed = list(library = library_dir, loaded_path = loaded_path, loaded_version = expected_version,
    marker_path = marker_path, shared_library = shared, shared_library_sha256 = shared_sha256),
  r_runner = list(path = "tools/destination_b/b1_joint_gaussian_stationary_reference.R",
    sha256 = b1_joint_sha256_file(runner_path), fixture_attestation_module = "tools/destination_b/b1_joint_gaussian_common.R",
    fixture_attestation_module_sha256 = b1_joint_sha256_file(file.path(dirname(runner_path), "b1_joint_gaussian_common.R")), R_version = as.character(getRversion())),
  specification = list(formula = formula_text, family = "gaussian()", trait = "trait", unit = "unit",
    unit_obs = "obs", cluster = "cluster_id", cluster2 = "cluster2_id", REML = FALSE,
    n_trait = n_trait, n_unit = n_unit, n_unit_obs_per_unit = n_obs_per_unit, n_replicate = n_rep,
    n_cluster = n_cluster, n_cluster2 = n_cluster2, n_observation = nrow(wide),
    row_order = "unit, unit_obs, replicate, trait", seed = 20260914L, data_md5 = data_md5,
    true_scales = list(lambda = lambda, sd_obs = sd_obs, sd_cluster = sd_cluster,
      sd_cluster2 = sd_cluster2, sigma_eps = 0.17),
    control = list(n_init = 1L, se = FALSE, optimizer = "nlminb", eval_max = 100000L,
      iter_max = 100000L, rel_tol = 1e-12, x_tol = 1e-12, xf_tol = 1e-12)),
  response_long = list(value = b1_joint_as_value(data$value), trait = as.character(data$trait),
    unit = as.character(data$unit), obs = as.character(data$obs), cluster_id = as.character(data$cluster_id),
    cluster2_id = as.character(data$cluster2_id), replicate = data$replicate),
  mapping = NULL, fit = NULL,
  acceptance = list(matched_parameter = FALSE, source_gradient_threshold = 1e-6,
    reason = "Pending frozen-R fit."), failure = list(present = FALSE)
)
if (inherits(fit, "error")) {
  receipt$failure <- list(present = TRUE, class = class(fit), message = conditionMessage(fit), fit_seconds = fit_seconds)
  receipt$acceptance$reason <- "Frozen-R fit errored; no stationary reference was established."
} else {
  report <- b1_joint_field(fit, "report"); opt <- b1_joint_field(fit, "opt"); tmb_data <- b1_joint_field(fit, "tmb_data")
  opt_par <- opt$par; fitted <- fit$tmb_obj$env$parList(opt_par)
  required <- c("b_fix", "log_sigma_eps", "theta_rr_B", "theta_diag_W", "theta_diag_species", "theta_diag_cluster2")
  all(required %in% names(fitted)) || stop("Frozen R fit lacks a required joint coordinate.")
  Sigma <- function(level) gllvmTMB::extract_Sigma(fit, level = level, part = "total", link_residual = "none")$Sigma
  gradient <- b1_joint_as_value(fit$tmb_obj$gr(opt_par))
  gradient_max_abs <- max(abs(gradient))
  stationary <- identical(as.integer(opt$convergence), 0L) && gradient_max_abs <= 1e-6
  receipt$mapping <- list(trait_levels = b1_joint_as_value(levels(data$trait)), x_fix_names = b1_joint_field(fit, "X_fix_names"),
    trait_id = b1_joint_field(tmb_data, "trait_id"), unit_id = b1_joint_field(tmb_data, "site_id"),
    unit_obs_id = b1_joint_field(tmb_data, "site_species_id"), cluster_id = b1_joint_field(tmb_data, "species_id"),
    cluster2_id = b1_joint_field(tmb_data, "cluster2_id"))
  receipt$fit <- list(fit_seconds = fit_seconds, logLik = as.numeric(logLik(fit)),
    convergence = b1_joint_as_value(opt$convergence), optimizer_message = b1_joint_as_value(opt$message),
    gradient = gradient, gradient_max_abs = gradient_max_abs,
    raw_opt_par = list(names = unname(names(opt_par)), values = unname(as.numeric(opt_par))),
    report_fields = unname(names(report)), b_fix = b1_joint_as_value(fitted$b_fix),
    log_sigma_eps = b1_joint_as_value(fitted$log_sigma_eps), theta_rr_B = b1_joint_as_value(fitted$theta_rr_B),
    theta_diag_W = b1_joint_as_value(fitted$theta_diag_W), theta_diag_species = b1_joint_as_value(fitted$theta_diag_species),
    theta_diag_cluster2 = b1_joint_as_value(fitted$theta_diag_cluster2),
    Sigma_unit = b1_joint_as_value(Sigma("unit")), Sigma_unit_obs = b1_joint_as_value(Sigma("unit_obs")),
    Sigma_cluster = b1_joint_as_value(Sigma("cluster")), Sigma_cluster2 = b1_joint_as_value(Sigma("cluster2")),
    sigma_eps = b1_joint_field(report, "sigma_eps"))
  receipt$acceptance$matched_parameter <- stationary
  receipt$acceptance$reason <- if (stationary) "Source convergence and the pre-registered 1e-6 gradient gate passed." else "Frozen-R fit did not meet the pre-registered source convergence and gradient gate."
}
b1_joint_publish_json_new(receipt, output_path)
message("Frozen-R joint B1 stationary-candidate receipt written: ", output_path)
