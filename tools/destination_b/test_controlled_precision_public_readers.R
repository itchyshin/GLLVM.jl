#!/usr/bin/env Rscript
# No fits: re-open source-bound controlled candidate objects in a fresh R
# process and exercise only registered public readers.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) {
  stop(paste(
    "usage: test_controlled_precision_public_readers.R",
    "LIBRARY CONTROLLED_DIRECTORY OUTPUT"
  ))
}
library_path <- normalizePath(args[[1L]], mustWork = TRUE)
controlled_directory <- normalizePath(args[[2L]], mustWork = TRUE)
output_path <- args[[3L]]
if (file.exists(output_path)) stop("refusing to overwrite reader receipt")

.libPaths(c(library_path, .libPaths()))
suppressPackageStartupMessages(library(gllvmTMB))
package_path <- find.package("gllvmTMB")
if (!identical(normalizePath(package_path), normalizePath(file.path(library_path, "gllvmTMB")))) {
  stop("controlled reader check loaded an unexpected gllvmTMB package")
}
sha256 <- function(path) unname(tools::sha256sum(path))
installed_artifacts <- c(
  r_loader = file.path(package_path, "R", "gllvmTMB"),
  r_database = file.path(package_path, "R", "gllvmTMB.rdb"),
  r_index = file.path(package_path, "R", "gllvmTMB.rdx"),
  description = file.path(package_path, "DESCRIPTION"),
  dll = file.path(package_path, "libs", "gllvmTMB.so")
)
if (!all(file.exists(installed_artifacts))) stop("installed package artifacts are incomplete")

receipt <- list(
  status = "error",
  qualified = FALSE,
  admission_status = "closed",
  package_version = as.character(utils::packageVersion("gllvmTMB")),
  installed_package = as.list(stats::setNames(
    unname(tools::sha256sum(unname(installed_artifacts))), names(installed_artifacts)
  )),
  cases = list()
)

tryCatch({
  for (kind in c("tree", "pedigree", "dense")) {
    stem <- file.path(controlled_directory, paste0("controlled-dispatch-", kind, "-03.json"))
    paths <- c(receipt = stem, object = paste0(stem, ".rds"))
    if (!all(file.exists(paths))) stop("missing controlled receipt or saved object for ", kind)
    fit_receipt <- jsonlite::fromJSON(paths[["receipt"]])
    object <- readRDS(paths[["object"]])
    expected_names <- as.character(fit_receipt$public_methods$formula_coefficient_names)
    expected_targets <- as.character(fit_receipt$public_methods$displayed_beta_targets)
    actual_julia_bin <- as.character(fit_receipt$actual_julia_bin)
    actual_julia_sha256 <- as.character(fit_receipt$actual_julia_bin_sha256)
    requested_julia_sha256 <- as.character(fit_receipt$input_hashes$requested_julia_bin)
    ci <- stats::confint(object, method = "stored")
    selected <- stats::confint(object, parm = expected_targets[[1L]], method = "stored")
    fit_summary <- summary(object)
    mu <- stats::fitted(object, type = "link")
    response_residual <- stats::residuals(object, type = "response")
    pearson_residual <- stats::residuals(object, type = "pearson")
    simulation <- stats::simulate(object, nsim = 2L, seed = 73L)
    stopifnot(
      identical(fit_receipt$status, "pass"),
      identical(fit_receipt$admission_status, "closed"),
      identical(fit_receipt$ordinary_formula_gate, "rejected_before_julia_startup"),
      isTRUE(fit_receipt$candidate_opt_in),
      length(actual_julia_bin) == 1L,
      file.exists(actual_julia_bin),
      identical(actual_julia_sha256, requested_julia_sha256),
      identical(sha256(actual_julia_bin), actual_julia_sha256),
      inherits(object, "gllvmTMB_julia"),
      identical(object$model, "precision_multivariate_candidate"),
      identical(object$admission_status, "closed"),
      identical(names(stats::coef(object)$mean_coef), expected_names),
      identical(names(fit_summary$coefficients$mean_coef), expected_names),
      identical(rownames(ci)[seq_along(expected_targets)], expected_targets),
      identical(rownames(selected), expected_targets[[1L]]),
      is.matrix(mu),
      length(response_residual) == length(mu),
      length(pearson_residual) == length(mu),
      identical(dim(simulation), c(length(mu), 2L)),
      all(is.finite(simulation))
    )
    receipt$cases[[kind]] <- list(
      status = "pass",
      receipt_sha256 = sha256(paths[["receipt"]]),
      object_sha256 = sha256(paths[["object"]]),
      actual_julia_bin = actual_julia_bin,
      actual_julia_bin_sha256 = actual_julia_sha256,
      coefficient_names = expected_names,
      displayed_beta_targets = expected_targets,
      n_intervals = nrow(ci),
      fitted_shape = dim(mu),
      simulation_shape = dim(simulation)
    )
  }
  receipt$status <- "pass"
  jsonlite::write_json(receipt, output_path, pretty = TRUE, auto_unbox = TRUE, digits = 17)
  cat("CONTROLLED_PRECISION_PUBLIC_READERS_PASS\n")
}, error = function(error) {
  receipt$error <- conditionMessage(error)
  jsonlite::write_json(receipt, output_path, pretty = TRUE, auto_unbox = TRUE, digits = 17)
  stop(error)
})
