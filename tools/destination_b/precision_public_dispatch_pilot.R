#!/usr/bin/env Rscript

# Exercise the authorised, closed Destination B candidate through the actual
# gllvmTMB() formula entry point. The package supplied as the first argument
# must be a disposable frozen-source overlay: this script never changes a
# user's installed gllvmTMB library and never opens public admission.
args <- commandArgs(trailingOnly = TRUE)
if (!length(args) %in% c(5L, 6L)) {
  stop(paste(
    "usage: precision_public_dispatch_pilot.R",
    "LIBRARY CORE070 PROJECT JULIA_BIN OUTPUT [tree|pedigree|dense]"
  ))
}
kind <- if (length(args) == 6L) args[[6L]] else "tree"
if (!kind %in% c("tree", "pedigree", "dense")) {
  stop("unsupported public-dispatch fixture")
}

library_path <- normalizePath(args[[1L]], mustWork = TRUE)
core070 <- normalizePath(args[[2L]], mustWork = TRUE)
project <- normalizePath(args[[3L]], mustWork = TRUE)
julia_bin <- normalizePath(args[[4L]], mustWork = TRUE)
output_path <- args[[5L]]
raw_path <- paste0(output_path, ".rds")
runner_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(runner_arg) != 1L) {
  stop("could not determine public-dispatch runner path")
}
runner_path <- normalizePath(sub("^--file=", "", runner_arg), mustWork = TRUE)
if (any(file.exists(c(output_path, raw_path)))) {
  stop("refusing to overwrite a public-dispatch attempt")
}
if (!identical(normalizePath(Sys.getenv("JULIA_PROJECT"), mustWork = TRUE), project)) {
  stop("JULIA_PROJECT must name the requested combined Julia environment")
}

.libPaths(c(library_path, .libPaths()))
suppressPackageStartupMessages(library(gllvmTMB))
if (!identical(as.character(utils::packageVersion("gllvmTMB")), "0.7.0")) {
  stop("public-dispatch pilot requires the frozen gllvmTMB 0.7.0 overlay")
}

reference_path <- file.path(core070, switch(
  kind,
  tree = "destination-b-tree/r-fit-attempt-01.json",
  pedigree = "destination-b-pedigree-fit/r-attempt-02.json",
  dense = "destination-b-s3b-pilot/r-attempt-02.json"
))
expected_path <- file.path(core070, switch(
  kind,
  tree = "destination-b-adapter/juliacall-tree-03.json",
  pedigree = "destination-b-adapter/juliacall-pedigree-02.json",
  dense = "destination-b-adapter/juliacall-dense-02.json"
))
if (!all(file.exists(c(reference_path, expected_path)))) {
  stop("reference or retained candidate receipt is missing for requested fixture")
}

sha256 <- function(path) unname(tools::sha256sum(path))
sha256_many <- function(paths) {
  hashes <- tools::sha256sum(unname(paths))
  stats::setNames(unname(hashes), names(paths))
}
dll_path <- getLoadedDLLs()[["gllvmTMB"]][["path"]]
package_path <- find.package("gllvmTMB")
installed_artifacts <- c(
  r_loader = file.path(package_path, "R", "gllvmTMB"),
  r_database = file.path(package_path, "R", "gllvmTMB.rdb"),
  r_index = file.path(package_path, "R", "gllvmTMB.rdx"),
  description = file.path(package_path, "DESCRIPTION")
)
if (!all(file.exists(installed_artifacts))) {
  stop("installed gllvmTMB package artifacts are incomplete")
}
receipt <- list(
  status = "error",
  qualified = FALSE,
  admission_status = "closed",
  scope = "Destination B phylogenetic precision public formula candidate",
  kind = kind,
  input_hashes = list(
    runner = sha256(runner_path),
    frozen_reference = sha256(reference_path),
    retained_candidate = sha256(expected_path),
    requested_julia_bin = sha256(julia_bin),
    loaded_dll = sha256(dll_path),
    installed_package = as.list(sha256_many(installed_artifacts))
  ),
  julia_project = project,
  julia_bin = julia_bin,
  gllvmTMB_version = as.character(utils::packageVersion("gllvmTMB"))
)

tryCatch({
  ref <- jsonlite::fromJSON(reference_path)
  expected <- jsonlite::fromJSON(expected_path)$result
  if (identical(kind, "dense")) {
    long <- ref$fixture$long_to_matrix
    y_reference <- ref$response$Y_traits_by_observations
    data <- data.frame(
      species = long$species,
      replicate = long$replicate,
      trait = long$trait,
      value = y_reference[cbind(
        long$trait_index_one_based,
        long$observation_index_one_based
      )]
    )
    data$species <- factor(data$species, levels = ref$fixture$tip_order)
    data$trait <- factor(data$trait, levels = ref$fixture$trait_names)
    C <- ref$source_covariance$A_original
    dimnames(C) <- list(ref$fixture$tip_order, ref$fixture$tip_order)
    formula <- value ~ 0 + trait + phylo_latent(
      species, d = 1, vcv = C, unique = FALSE
    )
  } else {
    data <- ref$original_long
    data$species <- factor(
      ref$precision$observed_labels[data$species_id],
      levels = ref$precision$observed_labels
    )
    data$trait <- factor(ref$trait_names[data$trait_id], levels = ref$trait_names)
    if (identical(kind, "tree")) {
      tree <- ape::read.tree(text = ref$precision$newick)
      formula <- value ~ 0 + trait + phylo_latent(
        species, d = 1, tree = tree, unique = FALSE
      )
    } else {
      pedigree <- ref$precision$pedigree
      parent <- function(index) {
        ifelse(index == 0L, NA_character_, pedigree$node_labels[pmax(index, 1L)])
      }
      ped <- data.frame(
        id = pedigree$node_labels,
        sire = parent(pedigree$sire_one_based_zero_unknown),
        dam = parent(pedigree$dam_one_based_zero_unknown)
      )
      formula <- value ~ 0 + trait + animal_latent(
        species, d = 1, pedigree = ped, unique = FALSE
      )
    }
  }
  expected_fitted <- expected$fitted_values
  expected_shape <- dim(expected_fitted)
  if (is.null(expected_shape)) {
    stop("retained candidate receipt did not decode fitted values as a matrix")
  }
  expected_long_rows <- nrow(data)

  # The ordinary public formula route must remain closed.  Exercise the exact
  # formula before enabling the controlled evidence-only candidate option, so
  # a metadata label cannot be mistaken for an admission gate.
  ordinary_gate_message <- tryCatch({
    gllvmTMB(
      formula,
      data = data,
      trait = "trait",
      unit = "species",
      family = gaussian(),
      engine = "julia",
      ci_method = "wald"
    )
    NA_character_
  }, error = function(error) conditionMessage(error))
  if (is.na(ordinary_gate_message) || !grepl(
    "GJL-GATE-PRECISION-ADMISSION", ordinary_gate_message, fixed = TRUE
  )) {
    stop("ordinary phylogenetic precision formula did not stop at its admission gate")
  }
  options(gllvmTMB.destination_b_precision_candidate = TRUE)
  options(gllvmTMB.julia_home = dirname(julia_bin))

  started <- proc.time()[["elapsed"]]
  fit <- gllvmTMB(
    formula,
    data = data,
    trait = "trait",
    unit = "species",
    family = gaussian(),
    engine = "julia",
    ci_method = "wald"
  )
  elapsed <- proc.time()[["elapsed"]] - started
  saveRDS(fit, raw_path)

  ci <- stats::confint(fit)
  coefficient_payload <- stats::coef(fit)
  fit_summary <- summary(fit)
  fitted_link <- stats::fitted(fit, type = "link")
  prediction <- stats::predict(fit, type = "response")
  response_residual <- stats::residuals(fit, type = "response")
  pearson_residual <- stats::residuals(fit, type = "pearson")
  simulated <- stats::simulate(fit, nsim = 1L, seed = 20260907L)
  actual_julia_bin <- normalizePath(
    JuliaCall::julia_eval("joinpath(Sys.BINDIR, Base.julia_exename())"),
    mustWork = TRUE
  )
  julia_version <- JuliaCall::julia_eval("string(VERSION)")
  actual_julia_sha256 <- sha256(actual_julia_bin)
  displayed_beta_targets <- sprintf("beta[%s]", fit$X_fix_names)
  selected_ci <- stats::confint(fit, parm = displayed_beta_targets[[1L]])

  stopifnot(
    inherits(fit, "gllvmTMB_julia"),
    identical(fit$model, "precision_multivariate_candidate"),
    identical(fit$admission_status, "closed"),
    isTRUE(fit$converged),
    is.list(fit$precision_formula),
    is.list(fit$precision_input),
    is.null(fit$bridge_input),
    identical(fit$precision_input$project, project),
    length(fit$ci_target_names) == 12L,
    all(fit$ci_statuses == "available"),
    nrow(ci) == 12L,
    identical(names(coefficient_payload$mean_coef), fit$X_fix_names),
    identical(names(fit_summary$coefficients$mean_coef), fit$X_fix_names),
    identical(rownames(ci)[seq_along(displayed_beta_targets)], displayed_beta_targets),
    identical(rownames(selected_ci), displayed_beta_targets[[1L]]),
    is.matrix(fitted_link),
    identical(dim(fitted_link), expected_shape),
    is.data.frame(prediction),
    length(response_residual) == expected_long_rows,
    length(pearson_residual) == expected_long_rows,
    is.matrix(simulated),
    identical(dim(simulated), c(expected_long_rows, 1L)),
    identical(actual_julia_bin, julia_bin),
    identical(actual_julia_sha256, receipt$input_hashes$requested_julia_bin)
  )
  loglik_error <- abs(fit$loglik - expected$loglik)
  fitted_error <- max(abs(fit$fitted_values - expected_fitted))
  stopifnot(loglik_error <= 1e-8, fitted_error <= 1e-5)

  receipt$status <- "pass"
  receipt$elapsed_seconds <- elapsed
  receipt$loglik <- fit$loglik
  receipt$loglik_absolute_error <- loglik_error
  receipt$conditional_fitted_max_abs_error <- fitted_error
  receipt$n_interval_targets <- length(fit$ci_target_names)
  receipt$ci_status <- fit$ci_status
  receipt$ordinary_formula_gate <- "rejected_before_julia_startup"
  receipt$ordinary_formula_gate_message <- ordinary_gate_message
  receipt$candidate_opt_in <- TRUE
  receipt$actual_julia_bin <- actual_julia_bin
  receipt$actual_julia_bin_sha256 <- actual_julia_sha256
  receipt$julia_version <- julia_version
  receipt$public_methods <- list(
    confint_rows = nrow(ci),
    formula_coefficient_names = fit$X_fix_names,
    displayed_beta_targets = displayed_beta_targets,
    fitted_shape = dim(fitted_link),
    predict_rows = nrow(prediction),
    response_residuals = length(response_residual),
    pearson_residuals = length(pearson_residual),
    simulation_shape = dim(simulated)
  )
  jsonlite::write_json(receipt, output_path, pretty = TRUE, auto_unbox = TRUE, digits = 17)
  cat("PRECISION_PUBLIC_DISPATCH_PASS\n")
}, error = function(error) {
  receipt$error <- conditionMessage(error)
  jsonlite::write_json(receipt, output_path, pretty = TRUE, auto_unbox = TRUE, digits = 17)
  stop(error)
})
