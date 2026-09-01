# Retained evidence runner for the "postfit-policy" manifest-area batch (15
# EXECUTABLE_NOW cases + 2 negative controls; see
# docs/dev-log/core070/postfit-policy-batch-contract.json for the full case
# list, the 8 NEEDS_NEW_JULIA_SURFACE deferrals, and the 1 zero-case
# SPEC_DEFECT row). This script only validates pins, wires the environment,
# and invokes tools/core070_postfit_policy_batch.jl as a child process (the
# actual R<->Julia accessor comparisons live there, reusing the exact
# fixture-setup idiom already proven by tools/core070_gaussian_postfit.jl --
# not reimplemented here).
#
# argv (documented -- matches the contract's runner.outer_argv and the
# --self-test local smoke, which never reaches this file):
#   Rscript --vanilla tools/core070_postfit_policy_batch.R <frozen-library> <destination>
#
# <frozen-library> is an R library directory containing an installed
# gllvmTMB built from the pinned reference commit (b4d5fee...); this is the
# FROZEN, INSTALLED library, matching masks_known.R's arg 1 -- not a source
# tree. <destination> must not already exist; it is created and holds
# julia-results.json, julia-stdout.log, julia-stderr.log, results.tsv,
# diagnostics.log, and receipt.json.

args <- commandArgs(TRUE)
stopifnot(length(args) == 2L)
frozen_library <- normalizePath(args[[1]], mustWork = TRUE)
output_dir <- args[[2]]
stopifnot(!dir.exists(output_dir))
dir.create(output_dir, recursive = TRUE)

sha256_file <- function(path) {
  command <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  argv <- if (identical(command, "sha256sum")) path else c("-a", "256", path)
  line <- system2(command, argv, stdout = TRUE, stderr = TRUE)
  stopifnot(is.null(attr(line, "status")), length(line) >= 1L)
  sub("[[:space:]].*$", "", line[[1L]])
}

.libPaths(c(frozen_library, .libPaths()))
suppressPackageStartupMessages(library(gllvmTMB))
suppressPackageStartupMessages(library(jsonlite))
stopifnot(normalizePath(find.package("gllvmTMB")) ==
          normalizePath(file.path(frozen_library, "gllvmTMB")))

root <- normalizePath(".")
contract_path <- file.path(root, "docs/dev-log/core070/postfit-policy-batch-contract.json")
contract <- jsonlite::read_json(contract_path, simplifyVector = FALSE)
contract_sha256 <- sha256_file(contract_path)

stopifnot(identical(contract$reference_commit, "b4d5fee64def88bc768dda1f1f77c29b295edd86"),
          identical(contract$status, "FROZEN_POSTFIT_POLICY_BATCH_CONTRACT"),
          length(contract$cases) == contract$expected_case_count,
          contract$expected_case_count == 15L,
          length(contract$negative_controls) >= 2L)

# --- validate pinned R source ------------------------------------------
source_root <- file.path(root, ".unlazy/core070-aghq/oracle-source/readback")
for (rel in names(contract$source_pins)) {
  path <- file.path(source_root, rel)
  stopifnot(file.exists(path))
  digest <- sha256_file(path)
  stopifnot(identical(digest, contract$source_pins[[rel]]))
}

# --- invoke the Julia child ---------------------------------------------
julia_out <- file.path(output_dir, "julia-results.json")
julia_env <- c(
  GLLVM_PARITY_TESTS = "1",
  CORE070_PARITY_CASE_IDS = "NATIVE-01-GAUSSIAN",
  R_LIBS = frozen_library,
  GLLVM_PARITY_R_LIBS = frozen_library,
  GLLVM_PARITY_R_SOURCE_ROOT = source_root
)
julia_bin <- Sys.which("julia")
stopifnot(nzchar(julia_bin))
old_env <- Sys.getenv(names(julia_env), unset = NA, names = TRUE)
do.call(Sys.setenv, as.list(julia_env))
t0 <- Sys.time()
julia_status <- tryCatch(
  system2(julia_bin, c("--project=test/parity", "tools/core070_postfit_policy_batch.jl", julia_out),
          stdout = file.path(output_dir, "julia-stdout.log"),
          stderr = file.path(output_dir, "julia-stderr.log")),
  finally = {
    unset <- names(old_env)[is.na(old_env)]
    if (length(unset)) Sys.unsetenv(unset)
    set <- old_env[!is.na(old_env)]
    if (length(set)) do.call(Sys.setenv, as.list(set))
  }
)
elapsed <- as.numeric(Sys.time() - t0, units = "secs")

# --- read back and evaluate ----------------------------------------------
julia_report <- if (file.exists(julia_out)) {
  jsonlite::read_json(julia_out, simplifyVector = FALSE)
} else {
  NULL
}

contract_case_ids <- vapply(contract$cases, `[[`, "", "case_id")
contract_neg_ids <- vapply(contract$negative_controls, `[[`, "", "control_id")

results_ok <- !is.null(julia_report) &&
  identical(julia_status, 0L) &&
  identical(julia_report$status, "PASS") &&
  isTRUE(julia_report$all_positive_pass) &&
  isTRUE(julia_report$negative_controls_behaved_as_expected) &&
  isTRUE(julia_report$all_checks) &&
  identical(sort(names(julia_report$cases)), sort(contract_case_ids)) &&
  identical(sort(names(julia_report$negative_controls)), sort(contract_neg_ids)) &&
  all(vapply(julia_report$cases, function(x) isTRUE(x$pass), logical(1))) &&
  all(vapply(julia_report$negative_controls, function(x) isTRUE(x$behaved), logical(1)))

raw_lines <- if (!is.null(julia_report)) {
  vapply(contract_case_ids, function(id) {
    pass <- isTRUE(julia_report$cases[[id]]$pass)
    paste(id, if (pass) "PASS" else "FAIL", "positive", sep = "\t")
  }, character(1))
} else character(0)
neg_lines <- if (!is.null(julia_report)) {
  vapply(contract_neg_ids, function(id) {
    behaved <- isTRUE(julia_report$negative_controls[[id]]$behaved)
    paste(id, if (behaved) "PASS" else "FAIL", "negative_control", sep = "\t")
  }, character(1))
} else character(0)
raw_path <- file.path(output_dir, "results.tsv")
writeLines(c(raw_lines, neg_lines), raw_path)

diag_lines <- character(0)
if (!identical(julia_status, 0L)) diag_lines <- c(diag_lines, paste("julia_exit_code", julia_status))
if (is.null(julia_report)) diag_lines <- c(diag_lines, "julia-results.json was not written")
diag_path <- file.path(output_dir, "diagnostics.log")
writeLines(diag_lines, diag_path)

receipt <- list(
  status = if (isTRUE(results_ok)) "PASS" else "FAIL",
  scope = "CORE070_POSTFIT_POLICY_BATCH",
  reference_commit = contract$reference_commit,
  contract_sha256 = contract_sha256,
  source_pins = contract$source_pins,
  source_unchanged = TRUE,
  case_count = contract$expected_case_count,
  negative_control_count = length(contract$negative_controls),
  expected_case_ids = contract_case_ids,
  negative_control_case_ids = contract_neg_ids,
  julia_exit_code = julia_status,
  julia_elapsed_seconds = elapsed,
  julia_results_sha256 = if (file.exists(julia_out)) sha256_file(julia_out) else NA_character_,
  raw_sha256 = sha256_file(raw_path),
  diagnostics_sha256 = sha256_file(diag_path),
  r_version = R.version.string,
  gllvmTMB_version = as.character(utils::packageVersion("gllvmTMB")),
  frozen_library = frozen_library
)
receipt_path <- file.path(output_dir, "receipt.json")
jsonlite::write_json(receipt, receipt_path, auto_unbox = TRUE, pretty = TRUE, null = "null")

cat("CORE070_POSTFIT_POLICY_BATCH_", receipt$status, "\n", sep = "")
quit(status = if (isTRUE(results_ok)) 0L else 1L)
