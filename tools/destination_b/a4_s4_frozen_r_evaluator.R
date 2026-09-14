#!/usr/bin/env Rscript
# Private A4/S4 frozen-R marginal-objective contract.  This file does not fit a
# model, write a receipt, alter gllvmTMB, or expose the public formula route.
#
# Usage (validation only; no objective is evaluated):
#   Rscript --vanilla tools/destination_b/a4_s4_frozen_r_evaluator.R \
#     --dry-run tree_height4_nonunit_ultrametric '-0.2,0.1,0.3,-1.1,0.7,-0.4,0.2'
#
# Live frozen-R objective evaluation is deliberately deferred to an integrated
# frozen-runner slice.  A serialized fit cannot establish the required
# same-process provenance binding, so this contract rejects live evaluation.

a4_s4_frozen_r_schema_version <- "destination-b-a4-s4-frozen-r-evaluator-1"
a4_s4_frozen_r_source_pin <- "b4d5fee64def88bc768dda1f1f77c29b295edd86"
a4_s4_frozen_r_dll_sha256 <- "91bfa6d90fbf3e4f42e1f4160583f2607f51a7839bb54a02a209da6e31a59beb"
a4_s4_frozen_r_fixture_file_sha256 <- "089f87d0dcf3c1014fc99646953d8696a0d5aa747287561dd815b5b8bf097549"

a4_s4_frozen_r_theta_names <- function() {
  c(rep("b_fix", 3L), "log_sigma_eps", rep("theta_rr_phy", 3L))
}

a4_s4_frozen_r_rows <- function() {
  species_id <- rep(seq_len(8L), each = 2L)
  list(
    tree = list(
      row_id = "tree_height4_nonunit_ultrametric", kind = "tree",
      reference_file_sha256 = "08c2c0f8dca3bb601e716da30d64dae2cd0ce3834766fa557dabb0444ddf4bd7",
      precision_source_sha256 = "ab01ee47206565eb1af7da391af313953b8a97c6bb11d9b6160655aaa0429170",
      data_sha256 = "a096e8a4f4408923ea0e906defef936f133b92b65202a9baac9fff0d197373c2",
      map = list(species_id_one_based = species_id,
        species_aug_id_zero_based = c(13L, 6L, 11L, 8L, 12L, 7L, 10L, 9L),
        observation_to_augmented_zero_based = c(13L, 13L, 6L, 6L, 11L, 11L, 8L, 8L,
          12L, 12L, 7L, 7L, 10L, 10L, 9L, 9L),
        n_augmented = 14L, n_species_observed = 8L, n_observations = 16L),
      precision = list(log_det_Q = 15.706819081565975, scale = 4,
        ridge = 0, ridge_applied_once = FALSE, ridge_operation = NULL)
    ),
    pedigree = list(
      row_id = "pedigree_12_nodes_8_observed_4_unobserved", kind = "pedigree",
      reference_file_sha256 = "55ebb6e89461dcb6693d2b70d8c845d6ec1c1c3447fbaf20c6c58caaf9f221d3",
      precision_source_sha256 = "c428e369e6fb554cc4b9bb03f250418d0d51474ba86e01d1be9c7c7301e615ee",
      data_sha256 = "025d9ca79375962ef4110c3ce62f84b30cdeea2939957e03f7235e2352e5142b",
      map = list(species_id_one_based = species_id,
        species_aug_id_zero_based = c(11L, 4L, 8L, 6L, 9L, 5L, 10L, 7L),
        observation_to_augmented_zero_based = c(11L, 11L, 4L, 4L, 8L, 8L, 6L, 6L,
          9L, 9L, 5L, 5L, 10L, 10L, 7L, 7L),
        n_augmented = 12L, n_species_observed = 8L, n_observations = 16L),
      precision = list(log_det_Q = 5.966390909555864, scale = 1,
        ridge = 0, ridge_applied_once = FALSE, ridge_operation = NULL)
    ),
    dense = list(
      row_id = "dense_vcv_ridged_once", kind = "dense",
      reference_file_sha256 = "5166bd887d8e85a962d551fd8670bc6f095d7b7cfff22d927b04cba34f3b981f",
      precision_source_sha256 = "5166bd887d8e85a962d551fd8670bc6f095d7b7cfff22d927b04cba34f3b981f",
      data_sha256 = "e33fcb6d2b391e70b1a8a19d8285c6d0205bdf80d97f35c65d82395d9eef3243",
      map = list(species_id_one_based = species_id,
        species_aug_id_zero_based = 0:7,
        observation_to_augmented_zero_based = rep(0:7, each = 2L),
        n_augmented = 8L, n_species_observed = 8L, n_observations = 16L),
      precision = list(log_det_Q = 7.861154398716261, scale = 1,
        ridge = 1e-8, ridge_applied_once = TRUE,
        ridge_operation = "A_ridged = A_original + 1e-8 * I; Q_canonical = solve(A_ridged)")
    )
  )
}

a4_s4_frozen_r_stop <- function(message) stop(message, call. = FALSE)

a4_s4_frozen_r_exact_names <- function(value, expected, label) {
  if (!is.list(value) || !identical(names(value), expected)) {
    a4_s4_frozen_r_stop(sprintf("%s has an unexpected field set", label))
  }
  invisible(value)
}

a4_s4_frozen_r_validate_hash <- function(value, expected, label) {
  if (!is.character(value) || length(value) != 1L ||
      !grepl("^[0-9a-f]{64}$", value) || !identical(value, expected)) {
    a4_s4_frozen_r_stop(sprintf("%s differs from the frozen A4/S4 contract", label))
  }
  invisible(value)
}

a4_s4_frozen_r_validate_theta <- function(theta) {
  expected_names <- a4_s4_frozen_r_theta_names()
  if (!is.numeric(theta) || length(theta) != length(expected_names) ||
      !identical(names(theta), expected_names) || any(!is.finite(theta))) {
    a4_s4_frozen_r_stop(
      "R packed theta must be finite and named [b_fix(3), log_sigma_eps, theta_rr_phy(3)]"
    )
  }
  as.numeric(theta)
}

a4_s4_frozen_r_row_for_id <- function(row_id) {
  rows <- a4_s4_frozen_r_rows()
  matches <- vapply(rows, function(row) identical(row$row_id, row_id), logical(1L))
  if (!is.character(row_id) || length(row_id) != 1L || sum(matches) != 1L) {
    a4_s4_frozen_r_stop("row_id is not one of the three frozen Gaussian A4/S4 rows")
  }
  rows[[which(matches)]]
}

a4_s4_frozen_r_request <- function(row_id, r_packed_theta) {
  row <- a4_s4_frozen_r_row_for_id(row_id)
  theta <- a4_s4_frozen_r_validate_theta(r_packed_theta)
  names(theta) <- a4_s4_frozen_r_theta_names()
  request <- list(
    schema_version = a4_s4_frozen_r_schema_version,
    row_id = row$row_id,
    family = "gaussian",
    r_packed_theta = theta,
    r_packed_theta_names = a4_s4_frozen_r_theta_names(),
    provenance = list(package_version = "0.7.0", source_pin = a4_s4_frozen_r_source_pin,
      dll_sha256 = a4_s4_frozen_r_dll_sha256,
      fixture_file_sha256 = a4_s4_frozen_r_fixture_file_sha256,
      reference_file_sha256 = row$reference_file_sha256,
      precision_source_sha256 = row$precision_source_sha256,
      data_sha256 = row$data_sha256),
    map = row$map,
    precision = row$precision,
    public_formula_admission = "closed",
    qualified = FALSE
  )
  a4_s4_frozen_r_validate_request(request)
}

a4_s4_frozen_r_validate_request <- function(request) {
  a4_s4_frozen_r_exact_names(request, c("schema_version", "row_id", "family",
    "r_packed_theta", "r_packed_theta_names", "provenance", "map", "precision",
    "public_formula_admission", "qualified"), "frozen evaluator request")
  if (!identical(request$schema_version, a4_s4_frozen_r_schema_version) ||
      !identical(request$family, "gaussian") ||
      !identical(request$public_formula_admission, "closed") ||
      !identical(request$qualified, FALSE)) {
    a4_s4_frozen_r_stop("request is outside the closed, unqualified Gaussian evaluator scope")
  }
  row <- a4_s4_frozen_r_row_for_id(request$row_id)
  a4_s4_frozen_r_validate_theta(request$r_packed_theta)
  if (!identical(request$r_packed_theta_names, a4_s4_frozen_r_theta_names())) {
    a4_s4_frozen_r_stop("R packed theta coordinate names differ from the frozen contract")
  }
  a4_s4_frozen_r_exact_names(request$provenance, c("package_version", "source_pin",
    "dll_sha256", "fixture_file_sha256", "reference_file_sha256",
    "precision_source_sha256", "data_sha256"), "request provenance")
  if (!identical(request$provenance$package_version, "0.7.0") ||
      !identical(request$provenance$source_pin, a4_s4_frozen_r_source_pin)) {
    a4_s4_frozen_r_stop("request does not bind frozen gllvmTMB 0.7.0 source")
  }
  a4_s4_frozen_r_validate_hash(request$provenance$dll_sha256,
    a4_s4_frozen_r_dll_sha256, "DLL hash")
  a4_s4_frozen_r_validate_hash(request$provenance$fixture_file_sha256,
    a4_s4_frozen_r_fixture_file_sha256, "fixture hash")
  a4_s4_frozen_r_validate_hash(request$provenance$reference_file_sha256,
    row$reference_file_sha256, "reference hash")
  a4_s4_frozen_r_validate_hash(request$provenance$precision_source_sha256,
    row$precision_source_sha256, "precision-source hash")
  a4_s4_frozen_r_validate_hash(request$provenance$data_sha256,
    row$data_sha256, "data hash")
  if (!identical(request$map, row$map) || !identical(request$precision, row$precision)) {
    a4_s4_frozen_r_stop("request map, scale, or ridge facts differ from the frozen row")
  }
  request
}

a4_s4_frozen_r_evaluate <- function(request, dry_run = TRUE) {
  request <- a4_s4_frozen_r_validate_request(request)
  if (!identical(dry_run, TRUE)) {
    a4_s4_frozen_r_stop(
      "live frozen-R objective evaluation is deferred to the integrated frozen-runner slice"
    )
  }
  list(status = "dry_run_validated_not_evaluated", evaluated = FALSE,
    row_id = request$row_id, r_packed_theta = request$r_packed_theta,
    public_formula_admission = "closed", qualified = FALSE)
}

a4_s4_frozen_r_parse_theta <- function(value) {
  pieces <- strsplit(value, ",", fixed = TRUE)[[1L]]
  theta <- suppressWarnings(as.numeric(pieces))
  names(theta) <- a4_s4_frozen_r_theta_names()
  a4_s4_frozen_r_validate_theta(theta)
  theta
}

a4_s4_frozen_r_cli <- function(args) {
  usage <- paste(
    "usage:",
    "  Rscript --vanilla tools/destination_b/a4_s4_frozen_r_evaluator.R --dry-run ROW_ID THETA_CSV",
    sep = "\n")
  if (length(args) >= 1L && identical(args[[1L]], "--evaluate")) {
    a4_s4_frozen_r_stop(
      "live frozen-R objective evaluation is unsupported here; use the integrated frozen-runner slice"
    )
  }
  if (length(args) != 3L || !identical(args[[1L]], "--dry-run")) {
    a4_s4_frozen_r_stop(usage)
  }
  request <- a4_s4_frozen_r_request(args[[2L]], a4_s4_frozen_r_parse_theta(args[[3L]]))
  print(a4_s4_frozen_r_evaluate(request, dry_run = TRUE))
  invisible(NULL)
}

if (sys.nframe() == 0L) a4_s4_frozen_r_cli(commandArgs(trailingOnly = TRUE))
