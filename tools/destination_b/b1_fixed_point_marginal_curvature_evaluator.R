#!/usr/bin/env Rscript

# PRE_RUN_ONLY evaluator. Do not run without fresh authorization recorded in
# the paired protocol. It reconstructs an already captured TMB input directly;
# it never calls a gllvmTMB fitter or an outer optimizer.

HARD_STOP_SECONDS <- 60
OUTER_OPTIMIZER_CALLS <- 0L
RESTART_CALLS <- 0L
DATA_CHANGES <- 0L
TOLERANCE_CHANGES <- 0L
ALLOWED_OUTPUT_FIELDS <- c("cov.fixed", "pdHess", "gradient.fixed")

FIXED_FORMULA <- "value ~ 0 + trait + latent(0 + trait | unit, d = 1, unique = FALSE) + indep(0 + trait | obs) + indep(0 + trait | cluster_id) + indep(0 + trait | cluster2_id)"
FIXED_DATA_MD5 <- "8d61143f2ce6102bb8460fb1575cc249"
FIXED_SOURCE_GIT_SHA <- "b4d5fee64def88bc768dda1f1f77c29b295edd86"
CANONICAL_CAPTURE_RDS <- "/private/tmp/destination-b-b1-integration-20260910/docs/dev-log/core070/destination-b-b1/b1-fixed-point-marginal-capture.rds"
FIXED_CAPTURE_RDS_SHA256 <- "UNRESOLVED_PENDING_CAPTURE_MATERIALIZATION"
FIXED_CAPTURE_DATA_SHA256 <- "UNRESOLVED_PENDING_CAPTURE_MATERIALIZATION"
FIXED_CAPTURE_DLL_SHA256 <- "3b6e7b63e072506d78ca5e468c1478758fa9aae333757b74c1f651cfab81da30"
FIXED_CAPTURE_MAP_SHA256 <- "UNRESOLVED_PENDING_CAPTURE_MATERIALIZATION"
CANONICAL_CAPTURE_DLL <- "/private/tmp/gllvmTMB-frozen-r070-b1-library-20260910/gllvmTMB/libs/gllvmTMB.so"
FIXED_TMB_VERSION <- "1.9.21"
FIXED_TMB_DESCRIPTION_SHA256 <- "937932be51fc4e954ac25430756885f68a135260e263c5403e768315de73e49b"
FIXED_TMB_DLL_SHA256 <- "8b387ebacb98a81c2d02b3aab701690ed4ed83b5fc46f6d0cd53d87577dd35d0"
FIXED_RAW_NAMES <- c("b_fix", "b_fix", "log_sigma_eps", "theta_rr_B", "theta_rr_B",
  "theta_diag_W", "theta_diag_W", "theta_diag_species", "theta_diag_species",
  "theta_diag_cluster2", "theta_diag_cluster2")
FIXED_RAW_VALUES <- c(0.62141307619579789, 0.083900519938897522, -1.7545929563229237,
  0.6648612242448747, -0.60905211277924087, -0.9144254396401722,
  -1.3939197924478266, -0.95732062289543995, -0.86810533006648949,
  -1.2894084122197988, -0.95668356821980305)

fail <- function(message) stop("B1 fixed-point marginal-curvature evaluator: ", message, call. = FALSE)

sha256_file <- function(path) {
  if (!file.exists(path)) fail(paste0("required provenance file is absent: ", path))
  output <- system2("/usr/bin/shasum", c("-a", "256", path), stdout = TRUE, stderr = TRUE)
  if (!identical(attr(output, "status"), NULL) || length(output) != 1L) fail("cannot SHA-256 provenance file")
  strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]]
}

sha256_object <- function(object) {
  temporary_rds <- tempfile("b1-capture-content-", fileext = ".rds")
  on.exit(unlink(temporary_rds), add = TRUE)
  saveRDS(object, temporary_rds, version = 2)
  sha256_file(temporary_rds)
}

is_unresolved_pin <- function(value) identical(value, "UNRESOLVED_PENDING_CAPTURE_MATERIALIZATION")

assert_canonical_capture_file <- function(options) {
  if (any(vapply(c(FIXED_CAPTURE_RDS_SHA256, FIXED_CAPTURE_DATA_SHA256, FIXED_CAPTURE_MAP_SHA256),
      is_unresolved_pin, logical(1)))) fail("canonical capture content hashes are unresolved; fresh materialization authority is required")
  resolved_path <- normalizePath(options$capture, mustWork = TRUE)
  if (!identical(resolved_path, CANONICAL_CAPTURE_RDS)) fail("capture path is not the pinned canonical RDS")
  if (!identical(sha256_file(options$capture), FIXED_CAPTURE_RDS_SHA256)) fail("canonical capture RDS byte hash drift")
  invisible(resolved_path)
}

parse_args <- function(args) {
  if (length(args) != 4L || !identical(args[c(1L, 3L)], c("--capture", "--output"))) {
    fail("usage: b1_fixed_point_marginal_curvature_evaluator.R --capture FROZEN_CAPTURE.rds --output NEW_RECEIPT.json")
  }
  list(capture = args[[2L]], output = args[[4L]])
}

reserve_output <- function(path) {
  if (file.exists(path) || !file.create(path, showWarnings = FALSE)) {
    fail("output already exists or cannot be reserved; no clobber is permitted")
  }
  if (!identical(unname(file.info(path)$size), 0)) fail("reserved output is not empty")
  invisible(path)
}

with_hard_stop <- function(expr) {
  setTimeLimit(elapsed = HARD_STOP_SECONDS, transient = TRUE)
  on.exit(setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE), add = TRUE)
  force(expr)
}

assert_frozen_capture <- function(capture) {
  required <- c("data", "parameters", "DLL", "dll_path", "random", "map", "provenance", "raw_opt_par")
  if (!is.list(capture) || !all(required %in% names(capture))) fail("captured object schema drift")
  if (!identical(capture$provenance$formula, FIXED_FORMULA) ||
      !identical(capture$provenance$data_md5, FIXED_DATA_MD5) ||
      !identical(capture$provenance$source_git_sha, FIXED_SOURCE_GIT_SHA)) {
    fail("captured source, data, or formula drift")
  }
  if (!identical(sha256_object(capture$data), FIXED_CAPTURE_DATA_SHA256) ||
      !identical(sha256_object(capture$map), FIXED_CAPTURE_MAP_SHA256)) fail("captured data or map content hash drift")
  theta_star <- capture$raw_opt_par
  if (!identical(names(theta_star), FIXED_RAW_NAMES) ||
      !identical(as.numeric(theta_star), FIXED_RAW_VALUES)) fail("captured raw_opt_par drift")
  invisible(theta_star)
}

resolve_frozen_dll <- function(capture) {
  resolved_dll <- normalizePath(capture$dll_path, mustWork = TRUE)
  if (!identical(resolved_dll, CANONICAL_CAPTURE_DLL) ||
      !identical(sha256_file(resolved_dll), FIXED_CAPTURE_DLL_SHA256)) fail("captured DLL path or content hash drift")
  if (!(capture$DLL %in% names(getLoadedDLLs()))) dyn.load(resolved_dll)
  loaded_dll <- getLoadedDLLs()[[capture$DLL]]
  if (is.null(loaded_dll) || !identical(normalizePath(loaded_dll[["path"]], mustWork = TRUE), resolved_dll)) {
    fail("MakeADFun DLL is not the resolved frozen binary")
  }
  invisible(resolved_dll)
}

assert_tmb_provenance <- function() {
  tmb_root <- find.package("TMB", quiet = TRUE)
  if (length(tmb_root) != 1L || !nzchar(tmb_root) ||
      !identical(as.character(utils::packageVersion("TMB")), FIXED_TMB_VERSION)) {
    fail("installed TMB version drift")
  }
  description <- file.path(tmb_root, "DESCRIPTION")
  tmb_dll <- file.path(tmb_root, "libs", "TMB.so")
  if (!identical(sha256_file(description), FIXED_TMB_DESCRIPTION_SHA256) ||
      !identical(sha256_file(tmb_dll), FIXED_TMB_DLL_SHA256)) fail("installed TMB provenance hash drift")
  invisible(tmb_root)
}

reconstruct_frozen_object <- function(capture) {
  # Direct TMB reconstruction only: no fitter, restart, or outer optimization.
  TMB::MakeADFun(data = capture$data, parameters = capture$parameters, DLL = capture$DLL,
    random = capture$random, map = capture$map, silent = TRUE)
}

assert_output_schema <- function(receipt) {
  allowed_top <- c("status", "stage", "provenance", "data", "formula", "raw_opt_par", "sdreport", "outputs", "failure")
  if (!is.list(receipt) || !all(names(receipt) %in% allowed_top)) fail("receipt has unregistered top-level fields")
  if (!identical(receipt$sdreport$getJointPrecision, FALSE) ||
      !identical(receipt$sdreport$getReportCovariance, FALSE) ||
      !identical(receipt$sdreport$skip.delta.method, TRUE)) fail("sdreport switch drift")
  if (identical(receipt$status, "OK")) {
    if (!identical(names(receipt$outputs), ALLOWED_OUTPUT_FIELDS)) fail("success receipt output schema drift")
  } else if (identical(receipt$status, "FAILED")) {
    output_names <- names(receipt$outputs)
    if (length(receipt$outputs) != 0L || !is.null(output_names)) fail("failure receipt must have exactly empty outputs")
    if (!is.list(receipt$failure) || !identical(names(receipt$failure), c("class", "message"))) {
      fail("failure receipt metadata schema drift")
    }
  } else {
    fail("receipt status must be OK or FAILED")
  }
  invisible(receipt)
}

write_once_json <- function(path, receipt) {
  if (!file.exists(path) || !identical(unname(file.info(path)$size), 0)) fail("write-once output reservation lost")
  assert_output_schema(receipt)
  if (!requireNamespace("jsonlite", quietly = TRUE)) fail("jsonlite is required to write the immutable receipt")
  jsonlite::write_json(receipt, path = path, auto_unbox = TRUE, digits = NA, pretty = TRUE)
  invisible(path)
}

run_audit <- function(capture) {
  theta_star <- assert_frozen_capture(capture)
  resolve_frozen_dll(capture)
  assert_tmb_provenance()
  obj <- reconstruct_frozen_object(capture)
  if (!identical(names(obj$par), FIXED_RAW_NAMES) || !identical(length(obj$par), length(FIXED_RAW_NAMES))) {
    fail("reconstructed fixed coordinate names or length drift")
  }
  objective_value <- obj$fn(theta_star)
  marginal <- TMB::sdreport(obj, par.fixed = theta_star, getJointPrecision = FALSE, getReportCovariance = FALSE,
    skip.delta.method = TRUE)
  list(objective_value = objective_value, outputs = list(
    "cov.fixed" = marginal$cov.fixed,
    "pdHess" = marginal$pdHess,
    "gradient.fixed" = marginal$gradient.fixed))
}

main <- function() {
  options <- parse_args(commandArgs(trailingOnly = TRUE))
  reserve_output(options$output)
  base_receipt <- list(
    stage = "fixed_point_marginal_curvature",
    provenance = list(source_git_sha = FIXED_SOURCE_GIT_SHA),
    data = list(md5 = FIXED_DATA_MD5), formula = FIXED_FORMULA,
    raw_opt_par = list(names = FIXED_RAW_NAMES, values = FIXED_RAW_VALUES),
    sdreport = list(getJointPrecision = FALSE, getReportCovariance = FALSE, "skip.delta.method" = TRUE))
  receipt <- tryCatch(with_hard_stop({
    assert_canonical_capture_file(options)
    capture <- readRDS(options$capture)
    audit <- run_audit(capture)
    c(list(status = "OK"), base_receipt, list(outputs = audit$outputs, failure = NULL))
  }), error = function(error) {
    c(list(status = "FAILED"), base_receipt,
      list(outputs = list(), failure = list(class = class(error)[[1L]], message = conditionMessage(error))))
  })
  write_once_json(options$output, receipt)
}

main()
