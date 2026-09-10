#!/usr/bin/env Rscript
# Private A4/S4 raw-R summary adapter.
#
# Usage:
#   Rscript --vanilla export_a4_s4_frozen_r_raw_summary.R <input-rds> <output-json>
#
# JSON contract (destination-b-a4-s4-fixed-coordinate-summary-1): each row
# carries `row_id`, `theta_r`, `r_nll`, `raw_artifact`, and `provenance` for
# the fixed-coordinate Julia evaluator.  `r_provenance` retains the complete
# source/build/DLL/runtime record.  `canonical_input` preserves the audited
# identity, maps, scale, and ridge data without inventing a new representation.
#
# This adapter is intentionally RDS-to-JSON only.  It does not source a
# runner, load gllvmTMB, fit a model, start Julia, calculate a delta, or make
# a pairing/admission decision.  Its only positive status is the narrow
# `raw summary exported unqualified` transport statement.

a4_s4_raw_summary_schema <- "destination-b-a4-s4-fixed-coordinate-summary-1"
a4_s4_raw_schema <- "destination-b-a4-s4-frozen-r-raw-4"
a4_s4_raw_theta_names <- c(
  "b1", "b2", "b3", "log_sigma", "lambda1", "lambda2", "lambda3"
)
a4_s4_raw_row_ids <- c(
  "tree_height4_nonunit_ultrametric",
  "pedigree_12_nodes_8_observed_4_unobserved",
  "dense_vcv_ridged_once"
)
a4_s4_raw_frozen_static <- list(
  package_version = "0.7.0",
  source_pin = "b4d5fee64def88bc768dda1f1f77c29b295edd86",
  archive_sha256 = "0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc",
  namespace_sha256 = "9094613610789faab69c43195d3cfdafb2c7dfef284e6646b10dababa4fa132c",
  source_tree_sha256 = "f83545faa6543dbb1f64d64bbf5a9498adcdf036cc3da5851f269912698b1cc7",
  source_provenance = "verified_installed_marker"
)

# Immutable A4/S4 input facts copied from the frozen evaluator contract.  They
# bind this adapter to the three declared records without importing its code.
a4_s4_raw_row_contracts <- function() {
  species_id <- rep(seq_len(8L), each = 2L)
  make_contract <- function(kind, reference_file_sha256, precision_source_sha256,
                            data_sha256, species_aug_id_zero_based,
                            observation_to_augmented_zero_based, n_augmented,
                            log_det_Q, scale, ridge, ridge_applied_once,
                            ridge_operation) {
    list(kind = kind,
      provenance = c(a4_s4_raw_frozen_static[c("package_version", "source_pin")],
        list(fixture_file_sha256 = "089f87d0dcf3c1014fc99646953d8696a0d5aa747287561dd815b5b8bf097549",
          reference_file_sha256 = reference_file_sha256,
          precision_source_sha256 = precision_source_sha256, data_sha256 = data_sha256)),
      map = list(species_id_one_based = species_id,
        species_aug_id_zero_based = species_aug_id_zero_based,
        observation_to_augmented_zero_based = observation_to_augmented_zero_based,
        n_augmented = as.integer(n_augmented), n_species_observed = 8L, n_observations = 16L),
      precision = list(log_det_Q = log_det_Q, scale = scale, ridge = ridge,
        ridge_applied_once = ridge_applied_once, ridge_operation = ridge_operation))
  }
  list(
    tree_height4_nonunit_ultrametric = make_contract("tree",
      "08c2c0f8dca3bb601e716da30d64dae2cd0ce3834766fa557dabb0444ddf4bd7",
      "ab01ee47206565eb1af7da391af313953b8a97c6bb11d9b6160655aaa0429170",
      "a096e8a4f4408923ea0e906defef936f133b92b65202a9baac9fff0d197373c2",
      c(13L, 6L, 11L, 8L, 12L, 7L, 10L, 9L),
      c(13L, 13L, 6L, 6L, 11L, 11L, 8L, 8L, 12L, 12L, 7L, 7L, 10L, 10L, 9L, 9L),
      14L, 15.706819081565975, 4, 0, FALSE, NULL),
    pedigree_12_nodes_8_observed_4_unobserved = make_contract("pedigree",
      "55ebb6e89461dcb6693d2b70d8c845d6ec1c1c3447fbaf20c6c58caaf9f221d3",
      "c428e369e6fb554cc4b9bb03f250418d0d51474ba86e01d1be9c7c7301e615ee",
      "025d9ca79375962ef4110c3ce62f84b30cdeea2939957e03f7235e2352e5142b",
      c(11L, 4L, 8L, 6L, 9L, 5L, 10L, 7L),
      c(11L, 11L, 4L, 4L, 8L, 8L, 6L, 6L, 9L, 9L, 5L, 5L, 10L, 10L, 7L, 7L),
      12L, 5.966390909555864, 1, 0, FALSE, NULL),
    dense_vcv_ridged_once = make_contract("dense",
      "5166bd887d8e85a962d551fd8670bc6f095d7b7cfff22d927b04cba34f3b981f",
      "5166bd887d8e85a962d551fd8670bc6f095d7b7cfff22d927b04cba34f3b981f",
      "e33fcb6d2b391e70b1a8a19d8285c6d0205bdf80d97f35c65d82395d9eef3243",
      0:7, rep(0:7, each = 2L), 8L, 7.861154398716261, 1, 1e-8, TRUE,
      "A_ridged = A_original + 1e-8 * I; Q_canonical = solve(A_ridged)")
  )
}

a4_s4_raw_summary_stop <- function(message) stop(message, call. = FALSE)

a4_s4_raw_summary_is_symlink <- function(path) {
  target <- Sys.readlink(path)
  length(target) == 1L && !is.na(target) && nzchar(target)
}

a4_s4_raw_summary_scalar_string <- function(value, label) {
  if (!is.character(value) || length(value) != 1L || is.na(value) || !nzchar(value)) {
    a4_s4_raw_summary_stop(sprintf("%s must be one nonempty string", label))
  }
  value
}

a4_s4_raw_summary_sha256 <- function(path, label) {
  path <- a4_s4_raw_summary_scalar_string(path, label)
  if (!file.exists(path) || !isTRUE(file_test("-f", path)) ||
      a4_s4_raw_summary_is_symlink(path)) {
    a4_s4_raw_summary_stop(sprintf("%s must be a regular non-symlink file", label))
  }
  digest <- unname(tools::sha256sum(path))[[1L]]
  if (!is.character(digest) || !grepl("^[0-9a-f]{64}$", digest)) {
    a4_s4_raw_summary_stop(sprintf("%s does not have a SHA-256 digest", label))
  }
  digest
}

a4_s4_raw_summary_finite_number <- function(value, label) {
  if (!is.numeric(value) || is.object(value) || length(value) != 1L ||
      is.na(value) || !is.finite(value)) {
    a4_s4_raw_summary_stop(sprintf("%s must be one finite number", label))
  }
  as.numeric(value)
}

a4_s4_raw_summary_false <- function(value, label) {
  if (!is.logical(value) || length(value) != 1L || is.na(value) || !identical(value, FALSE)) {
    a4_s4_raw_summary_stop(sprintf("%s must be FALSE", label))
  }
  invisible(NULL)
}

a4_s4_raw_summary_closed <- function(value, label) {
  if (!identical(value, "closed")) {
    a4_s4_raw_summary_stop(sprintf("%s must be closed", label))
  }
  invisible(NULL)
}

a4_s4_raw_summary_named_list <- function(value, fields, label) {
  if (!is.list(value) || !identical(names(value), fields)) {
    a4_s4_raw_summary_stop(sprintf("%s has an invalid field set", label))
  }
  value
}

a4_s4_raw_summary_validate_request <- function(request, label) {
  request <- a4_s4_raw_summary_named_list(request, c("provenance", "map", "precision"), label)
  provenance <- a4_s4_raw_summary_named_list(request$provenance,
    c("package_version", "source_pin", "fixture_file_sha256", "reference_file_sha256",
      "precision_source_sha256", "data_sha256"), paste0(label, "$provenance"))
  for (field in names(provenance)) {
    a4_s4_raw_summary_scalar_string(provenance[[field]], paste0(label, "$provenance$", field))
  }
  map <- a4_s4_raw_summary_named_list(request$map,
    c("species_id_one_based", "species_aug_id_zero_based",
      "observation_to_augmented_zero_based", "n_augmented",
      "n_species_observed", "n_observations"), paste0(label, "$map"))
  if (!is.numeric(map$species_id_one_based) || length(map$species_id_one_based) != 16L ||
      any(!is.finite(map$species_id_one_based)) ||
      !is.numeric(map$species_aug_id_zero_based) || length(map$species_aug_id_zero_based) != 8L ||
      any(!is.finite(map$species_aug_id_zero_based)) ||
      !is.numeric(map$observation_to_augmented_zero_based) ||
      length(map$observation_to_augmented_zero_based) != 16L ||
      any(!is.finite(map$observation_to_augmented_zero_based))) {
    a4_s4_raw_summary_stop(sprintf("%s has invalid canonical maps", label))
  }
  for (field in c("n_augmented", "n_species_observed", "n_observations")) {
    a4_s4_raw_summary_finite_number(map[[field]], paste0(label, "$map$", field))
  }
  precision <- a4_s4_raw_summary_named_list(request$precision,
    c("log_det_Q", "scale", "ridge", "ridge_applied_once", "ridge_operation"),
    paste0(label, "$precision"))
  for (field in c("log_det_Q", "scale", "ridge")) {
    a4_s4_raw_summary_finite_number(precision[[field]], paste0(label, "$precision$", field))
  }
  if (!is.logical(precision$ridge_applied_once) || length(precision$ridge_applied_once) != 1L ||
      is.na(precision$ridge_applied_once) ||
      !(is.null(precision$ridge_operation) || is.character(precision$ridge_operation))) {
    a4_s4_raw_summary_stop(sprintf("%s has invalid canonical ridge metadata", label))
  }
  request
}

# Strictly validate the current raw-4 contract before any JSON is built.
a4_s4_raw_summary_validate <- function(receipt) {
  receipt <- a4_s4_raw_summary_named_list(receipt,
    c("schema_version", "status", "frozen", "r_packed_theta", "r_packed_theta_names",
      "rows", "qualified", "public_formula_admission", "claim_boundary"), "raw receipt")
  if (!identical(receipt$schema_version, a4_s4_raw_schema)) {
    a4_s4_raw_summary_stop("raw receipt schema is not destination-b-a4-s4-frozen-r-raw-4")
  }
  a4_s4_raw_summary_false(receipt$qualified, "raw receipt qualified")
  a4_s4_raw_summary_closed(receipt$public_formula_admission,
    "raw receipt public_formula_admission")
  frozen_fields <- c("package_version", "package_path", "dll_path", "dll_sha256",
    "source_pin", "archive_sha256", "namespace_sha256", "source_tree_sha256",
    "installed_tree_sha256", "marker_path", "marker_sha256", "oracle_build_root",
    "oracle_build_receipt_path", "oracle_build_receipt_sha256", "oracle_source_path",
    "oracle_install_log_sha256",
    "runtime", "source_provenance")
  if (!is.list(receipt$frozen) || !identical(names(receipt$frozen), frozen_fields)) {
    a4_s4_raw_summary_stop("raw receipt frozen source/build/DLL provenance is incomplete")
  }
  for (field in setdiff(frozen_fields, "runtime")) {
    a4_s4_raw_summary_scalar_string(receipt$frozen[[field]], paste0("raw receipt frozen$", field))
  }
  if (!is.list(receipt$frozen$runtime) || is.null(names(receipt$frozen$runtime))) {
    a4_s4_raw_summary_stop("raw receipt frozen runtime provenance is missing")
  }
  if (!identical(receipt$frozen[names(a4_s4_raw_frozen_static)], a4_s4_raw_frozen_static)) {
    a4_s4_raw_summary_stop("raw receipt frozen provenance differs from the attested CORE-070 contract")
  }
  if (!identical(receipt$status, "raw_r_declared_coordinate_evaluations_unqualified") ||
      !is.list(receipt$claim_boundary) ||
      !identical(receipt$claim_boundary$sdreport, "disabled_at_construction")) {
    a4_s4_raw_summary_stop("raw receipt status or sdreport claim boundary is not the point-only contract")
  }
  if (!is.numeric(receipt$r_packed_theta) || length(receipt$r_packed_theta) != 7L ||
      any(!is.finite(receipt$r_packed_theta)) ||
      !is.character(receipt$r_packed_theta_names) ||
      length(receipt$r_packed_theta_names) != 7L) {
    a4_s4_raw_summary_stop("raw receipt packed theta is not a finite seven-coordinate vector")
  }
  if (!identical(receipt$r_packed_theta_names,
    c("b_fix", "b_fix", "b_fix", "log_sigma_eps", "theta_rr_phy", "theta_rr_phy", "theta_rr_phy"))) {
    a4_s4_raw_summary_stop("raw receipt packed theta names are not in the frozen R order")
  }
  if (!is.list(receipt$rows) || length(receipt$rows) != 3L) {
    a4_s4_raw_summary_stop("raw receipt must contain exactly three rows")
  }
  row_ids <- vapply(receipt$rows, function(row) {
    if (!is.list(row) || is.null(row$row_id)) "" else as.character(row$row_id)
  }, character(1L))
  if (!identical(row_ids, a4_s4_raw_row_ids)) {
    a4_s4_raw_summary_stop("raw receipt does not contain the required tree, pedigree, and dense rows in order")
  }
  contracts <- a4_s4_raw_row_contracts()
  for (i in seq_along(receipt$rows)) {
    row <- a4_s4_raw_summary_named_list(receipt$rows[[i]],
      c("row_id", "kind", "marginal_nll", "repeated_marginal_nll", "source_response_sha256",
        "precision_scale", "frozen_request", "dense_original_vcv_only", "construction",
        "repeat_identical", "qualified", "public_formula_admission"),
      sprintf("raw row %d", i))
    a4_s4_raw_summary_scalar_string(row$row_id, sprintf("raw row %d id", i))
    a4_s4_raw_summary_scalar_string(row$kind, sprintf("raw row %d kind", i))
    contract <- contracts[[row$row_id]]
    a4_s4_raw_summary_finite_number(row$marginal_nll, sprintf("raw row %d marginal NLL", i))
    a4_s4_raw_summary_finite_number(row$repeated_marginal_nll,
      sprintf("raw row %d repeated marginal NLL", i))
    if (!identical(row$kind, contract$kind) ||
        !identical(row$source_response_sha256, contract$provenance$data_sha256) ||
        !identical(as.numeric(row$precision_scale), as.numeric(contract$precision$scale))) {
      a4_s4_raw_summary_stop(sprintf("raw row %d differs from its frozen identity contract", i))
    }
    if (!is.logical(row$dense_original_vcv_only) || length(row$dense_original_vcv_only) != 1L ||
        is.na(row$dense_original_vcv_only) || !is.logical(row$repeat_identical) ||
        length(row$repeat_identical) != 1L || is.na(row$repeat_identical)) {
      a4_s4_raw_summary_stop(sprintf("raw row %d has invalid logical metadata", i))
    }
    a4_s4_raw_summary_false(row$qualified, sprintf("raw row %d qualified", i))
    a4_s4_raw_summary_closed(row$public_formula_admission,
      sprintf("raw row %d public_formula_admission", i))
    construction <- a4_s4_raw_summary_named_list(row$construction,
      c("route", "fit_performed", "optimization_performed", "optimizer_policy",
        "sdreport_requested", "optimizer_result_retained", "optimizer_result_compared"),
      sprintf("raw row %d construction", i))
    a4_s4_raw_summary_false(construction$sdreport_requested,
      sprintf("raw row %d construction sdreport_requested", i))
    a4_s4_raw_summary_validate_request(row$frozen_request, sprintf("raw row %d frozen_request", i))
    if (!identical(row$frozen_request$provenance, contract$provenance) ||
        !identical(row$frozen_request$map, contract$map) ||
        !identical(row$frozen_request$precision, contract$precision)) {
      a4_s4_raw_summary_stop(sprintf("raw row %d map or precision differs from the frozen A4/S4 contract", i))
    }
  }
  receipt
}

a4_s4_raw_summary_build <- function(receipt, input_path, input_sha256) {
  receipt <- a4_s4_raw_summary_validate(receipt)
  rows <- lapply(receipt$rows, function(row) {
    list(
      row_id = row$row_id,
      kind = row$kind,
      theta_r = list(names = receipt$r_packed_theta_names,
        values = as.numeric(receipt$r_packed_theta)),
      r_nll = as.numeric(row$marginal_nll),
      raw_r_repeated_marginal_nll = as.numeric(row$repeated_marginal_nll),
      raw_artifact = list(path = input_path, sha256 = input_sha256,
        # This describes the source-attested R artifact, not this adapter.
        attestation_status = receipt$frozen$source_provenance),
      provenance = list(source = "source-attested frozen R raw receipt",
        source_pin = receipt$frozen$source_pin),
      source_response_sha256 = row$source_response_sha256,
      precision_scale = as.numeric(row$precision_scale),
      dense_original_vcv_only = row$dense_original_vcv_only,
      construction = row$construction,
      canonical_input = row$frozen_request,
      qualified = FALSE,
      public_formula_admission = "closed"
    )
  })
  list(
    schema_version = a4_s4_raw_summary_schema,
    status = "raw summary exported unqualified",
    source = list(
      raw_r_schema_version = receipt$schema_version,
      input_rds_path = input_path,
      input_rds_sha256 = input_sha256,
      summary_adapter_status = "runner_recorded_unverified",
      claim_boundary = "R-only raw source summarized; no pairing result was computed"
    ),
    r_provenance = receipt$frozen,
    coordinate_labels = a4_s4_raw_theta_names,
    rows = rows,
    qualified = FALSE,
    public_formula_admission = "closed",
    claim_boundary = "raw summary exported unqualified"
  )
}

a4_s4_raw_summary_output_fence <- function(path) {
  path <- a4_s4_raw_summary_scalar_string(path, "output-json")
  if (file.exists(path) || a4_s4_raw_summary_is_symlink(path)) {
    a4_s4_raw_summary_stop("refusing to overwrite output JSON")
  }
  if (!dir.exists(dirname(path))) {
    a4_s4_raw_summary_stop("output-json parent directory does not exist")
  }
  normalizePath(path, mustWork = FALSE)
}

a4_s4_raw_summary_export <- function(input_rds, output_json) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    a4_s4_raw_summary_stop("jsonlite is required to export the JSON summary")
  }
  input_sha256 <- a4_s4_raw_summary_sha256(input_rds, "input-rds")
  a4_s4_raw_summary_output_fence(output_json)
  receipt <- tryCatch(readRDS(input_rds), error = function(error) {
    a4_s4_raw_summary_stop("input-rds cannot be read as an RDS receipt")
  })
  input_path <- normalizePath(input_rds, mustWork = TRUE)
  summary <- a4_s4_raw_summary_build(receipt, input_path, input_sha256)
  lock <- paste0(output_json, ".lock")
  if (!dir.create(lock, showWarnings = FALSE)) {
    a4_s4_raw_summary_stop("refusing to race another raw summary writer")
  }
  on.exit(if (dir.exists(lock)) unlink(lock, recursive = TRUE, force = TRUE), add = TRUE)
  a4_s4_raw_summary_output_fence(output_json)
  temporary <- tempfile(pattern = ".a4-s4-raw-summary-", tmpdir = dirname(output_json))
  on.exit(if (file.exists(temporary)) unlink(temporary, force = TRUE), add = TRUE)
  jsonlite::write_json(summary, temporary, auto_unbox = TRUE, pretty = TRUE,
    digits = 17, null = "null")
  if (file.exists(output_json) || !isTRUE(file.link(temporary, output_json)) ||
      !file.exists(output_json)) {
    a4_s4_raw_summary_stop("raw summary JSON could not be written without overwrite")
  }
  invisible(summary)
}

a4_s4_raw_summary_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  if (length(args) != 2L) {
    a4_s4_raw_summary_stop(paste(
      "usage: Rscript --vanilla export_a4_s4_frozen_r_raw_summary.R",
      "<input-rds> <output-json>"
    ))
  }
  a4_s4_raw_summary_export(args[[1L]], args[[2L]])
  cat("A4_S4_FROZEN_R_RAW_SUMMARY_OK\n")
  invisible(NULL)
}

if (sys.nframe() == 0L && !interactive()) a4_s4_raw_summary_main()
