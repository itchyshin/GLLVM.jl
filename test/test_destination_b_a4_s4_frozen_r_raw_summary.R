exporter <- file.path("tools", "destination_b", "export_a4_s4_frozen_r_raw_summary.R")
if (!file.exists(exporter)) stop("raw summary exporter is missing", call. = FALSE)
source(exporter)

expect_error <- function(expression, label) {
  failed <- FALSE
  tryCatch(force(expression), error = function(error) failed <<- TRUE)
  if (!failed) stop(sprintf("expected rejection for %s", label), call. = FALSE)
}

make_raw4_fixture <- function() {
  contracts <- a4_s4_raw_row_contracts()
  make_row <- function(id) {
    contract <- contracts[[id]]
    list(
      row_id = id, kind = contract$kind, marginal_nll = 10 + contract$precision$scale,
      repeated_marginal_nll = 10 + contract$precision$scale,
      source_response_sha256 = contract$provenance$data_sha256,
      precision_scale = contract$precision$scale,
      frozen_request = list(provenance = contract$provenance, map = contract$map,
        precision = contract$precision),
      dense_original_vcv_only = identical(contract$kind, "dense"),
      construction = list(route = "gllvmTMB(..., engine = 'tmb')", fit_performed = TRUE,
        optimization_performed = TRUE, optimizer_policy = "n_init=1; optimizer=nlminb",
        sdreport_requested = FALSE, optimizer_result_retained = FALSE,
        optimizer_result_compared = FALSE),
      repeat_identical = TRUE, qualified = FALSE, public_formula_admission = "closed"
    )
  }
  list(
    schema_version = "destination-b-a4-s4-frozen-r-raw-4",
    status = "raw_r_declared_coordinate_evaluations_unqualified",
    frozen = list(package_version = a4_s4_raw_frozen_static$package_version,
      package_path = "/frozen/library/gllvmTMB",
      dll_path = "/frozen/library/gllvmTMB/libs/gllvmTMB.so", dll_sha256 = "dll",
      source_pin = a4_s4_raw_frozen_static$source_pin,
      archive_sha256 = a4_s4_raw_frozen_static$archive_sha256,
      namespace_sha256 = a4_s4_raw_frozen_static$namespace_sha256,
      source_tree_sha256 = a4_s4_raw_frozen_static$source_tree_sha256,
      installed_tree_sha256 = "installed-tree",
      marker_path = "/frozen/library/gllvmTMB/CORE070_SOURCE_PIN.toml",
      marker_sha256 = "marker", oracle_build_root = "/frozen",
      oracle_build_receipt_path = "/frozen/build.json", oracle_build_receipt_sha256 = "build",
      oracle_source_path = "/frozen/source",
      oracle_install_log_sha256 = "install-log", runtime = list(r_version = "test"),
      source_provenance = a4_s4_raw_frozen_static$source_provenance),
    r_packed_theta = c(0.4, -0.2, 0.3, -1.2, 0.9, -0.6, 0.2),
    r_packed_theta_names = c("b_fix", "b_fix", "b_fix", "log_sigma_eps",
      "theta_rr_phy", "theta_rr_phy", "theta_rr_phy"),
    rows = list(
      make_row("tree_height4_nonunit_ultrametric"),
      make_row("pedigree_12_nodes_8_observed_4_unobserved"),
      make_row("dense_vcv_ridged_once")
    ),
    qualified = FALSE, public_formula_admission = "closed",
    claim_boundary = list(sdreport = "disabled_at_construction")
  )
}

fixture <- make_raw4_fixture()
input <- tempfile(fileext = ".rds")
output <- tempfile(fileext = ".json")
saveRDS(fixture, input)
summary <- a4_s4_raw_summary_export(input, output)
stopifnot(file.exists(output),
  identical(summary$schema_version, "destination-b-a4-s4-fixed-coordinate-summary-1"),
  identical(summary$status, "raw summary exported unqualified"),
  identical(summary$qualified, FALSE),
  identical(summary$public_formula_admission, "closed"),
  identical(summary$claim_boundary, "raw summary exported unqualified"),
  identical(summary$source$input_rds_sha256, unname(tools::sha256sum(input))[[1L]]),
  identical(summary$r_provenance, fixture$frozen),
  length(summary$rows) == 3L,
  identical(vapply(summary$rows, `[[`, character(1L), "row_id"), a4_s4_raw_row_ids),
  identical(vapply(summary$rows, `[[`, numeric(1L), "r_nll"),
    c(14, 11, 11)),
  identical(summary$rows[[1L]]$theta_r$names, fixture$r_packed_theta_names),
  identical(summary$rows[[1L]]$theta_r$values, unname(fixture$r_packed_theta)),
  identical(summary$rows[[1L]]$raw_artifact$sha256,
    unname(tools::sha256sum(input))[[1L]]),
  identical(summary$rows[[1L]]$raw_artifact$attestation_status,
    fixture$frozen$source_provenance),
  identical(summary$source$summary_adapter_status,
    "runner_recorded_unverified"),
  identical(summary$rows[[1L]]$provenance$source_pin, fixture$frozen$source_pin),
  identical(summary$rows[[1L]]$canonical_input, fixture$rows[[1L]]$frozen_request),
  identical(summary$rows[[3L]]$canonical_input$precision$ridge, 1e-8),
  identical(summary$rows[[3L]]$canonical_input$precision$ridge_applied_once, TRUE)
)
parsed <- jsonlite::read_json(output, simplifyVector = FALSE)
stopifnot(identical(parsed$schema_version, summary$schema_version),
  identical(parsed$qualified, FALSE),
  identical(parsed$public_formula_admission, "closed"))

# The command-line adapter accepts exactly the documented input/output pair.
cli_output <- tempfile(fileext = ".json")
cli <- system2(file.path(R.home("bin"), "Rscript"),
  c("--vanilla", exporter, input, cli_output), stdout = TRUE, stderr = TRUE)
stopifnot(identical(unname(attr(cli, "status")), NULL),
  identical(cli, "A4_S4_FROZEN_R_RAW_SUMMARY_OK"),
  file.exists(cli_output),
  identical(jsonlite::read_json(cli_output, simplifyVector = FALSE)$qualified, FALSE))

expect_error(a4_s4_raw_summary_export(input, output), "existing output JSON")

malformed <- fixture
malformed$schema_version <- "wrong"
expect_error(a4_s4_raw_summary_validate(malformed), "wrong raw schema")
malformed <- fixture
malformed$frozen$source_pin <- strrep("0", 40L)
expect_error(a4_s4_raw_summary_validate(malformed), "forged frozen source pin")
malformed <- fixture
malformed$frozen$source_provenance <- "runner_recorded_unverified"
expect_error(a4_s4_raw_summary_validate(malformed), "forged frozen source provenance")
malformed <- fixture
malformed$status <- "paired_result"
expect_error(a4_s4_raw_summary_validate(malformed), "forged raw status")
malformed <- fixture
malformed$claim_boundary$sdreport <- "computed"
expect_error(a4_s4_raw_summary_validate(malformed), "sdreport claim boundary")
malformed <- fixture
malformed$qualified <- TRUE
expect_error(a4_s4_raw_summary_validate(malformed), "qualified raw receipt")
malformed <- fixture
malformed$public_formula_admission <- "open"
expect_error(a4_s4_raw_summary_validate(malformed), "open public admission")
malformed <- fixture
malformed$rows[[1L]]$construction$sdreport_requested <- TRUE
expect_error(a4_s4_raw_summary_validate(malformed), "sdreport requested")
malformed <- fixture
malformed$rows <- malformed$rows[-3L]
expect_error(a4_s4_raw_summary_validate(malformed), "missing dense row")
malformed <- fixture
malformed$rows[[3L]]$frozen_request$precision$ridge_operation <- 1
expect_error(a4_s4_raw_summary_validate(malformed), "malformed ridge operation")
malformed <- fixture
malformed$rows[[1L]]$source_response_sha256 <- strrep("0", 64L)
expect_error(a4_s4_raw_summary_validate(malformed), "forged response hash")
malformed <- fixture
malformed$rows[[2L]]$frozen_request$map$n_augmented <- 8L
expect_error(a4_s4_raw_summary_validate(malformed), "forged augmented map")
malformed <- fixture
malformed$rows[[3L]]$frozen_request$precision$log_det_Q <- 1
expect_error(a4_s4_raw_summary_validate(malformed), "forged precision determinant")

# Read-only compatibility check for the current attested raw-02 artifact.
real_raw <- file.path("docs", "dev-log", "core070", "destination-b-a4-s4", "raw-frozen-r-02.rds")
if (file.exists(real_raw)) {
  real_receipt <- readRDS(real_raw)
  invisible(a4_s4_raw_summary_validate(real_receipt))
}

# This adapter must stay an inert RDS exporter: no package loading, fitting,
# bridge invocation, or Julia launch path may enter the implementation.
exporter_text <- paste(readLines(exporter, warn = FALSE), collapse = "\n")
stopifnot(!grepl("library\\s*\\(|requireNamespace\\(\\\"gllvmTMB|bridge_fit|julia_setup|JuliaCall|gllvmTMB\\s*::", exporter_text),
  !grepl("\\bfit\\s*\\(", exporter_text))

cat("A4_S4_FROZEN_R_RAW_SUMMARY_OK\n")
