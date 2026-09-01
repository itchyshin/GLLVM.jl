# Retained evidence runner for the "namespace-1" manifest-area batch, Tier 0:
# existence / registration parity (48 EXECUTABLE_NOW + 6 NEEDS_NEW_JULIA_SURFACE
# cases; see docs/dev-log/core070/namespace-1-batch-contract.json for the full
# triage, including the 36 REUSED_OR_RECLASSIFY rows this batch deliberately
# does not fabricate checks for).
#
# This tier needs NO installed gllvmTMB package and NO frozen library: every
# check is a text scan of the PINNED readback R source tree (source_pins in
# the contract), confirming that each row's cited S3 method / export is both
# (a) registered in the readback NAMESPACE and (b) actually defined at the
# cited file. That is why this runner takes only a destination directory --
# unlike tools/core070_postfit_policy_batch.R, there is no <frozen-library>
# argv slot here (see the contract's runner.tier1_followup for the deferred
# numeric-fit tier that WOULD need one).
#
# argv (matches the contract's runner.outer_argv and this file's own
# --self-test, which never reaches disk under that path):
#   Rscript --vanilla tools/core070_namespace_1_batch.R <destination>
#
# <destination> must not already exist; it is created and holds r-facts.json,
# julia-facts.json, julia-stdout.log, julia-stderr.log, results.tsv,
# diagnostics.log, and receipt.json.

args <- commandArgs(TRUE)
self_test <- length(args) == 1L && identical(args[[1]], "--self-test")

sha256_file <- function(path) {
  command <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  argv <- if (identical(command, "sha256sum")) path else c("-a", "256", path)
  line <- system2(command, argv, stdout = TRUE, stderr = TRUE)
  stopifnot(is.null(attr(line, "status")), length(line) >= 1L)
  sub("[[:space:]].*$", "", line[[1L]])
}

suppressPackageStartupMessages(library(jsonlite))

root <- normalizePath(".")
contract_path <- file.path(root, "docs/dev-log/core070/namespace-1-batch-contract.json")
if (!file.exists(contract_path)) {
  stop("FATAL: contract not found at ", contract_path, " -- refusing to run with no state.")
}
contract <- jsonlite::read_json(contract_path, simplifyVector = FALSE)
contract_sha256 <- sha256_file(contract_path)

stopifnot(
  identical(contract$reference_commit, "b4d5fee64def88bc768dda1f1f77c29b295edd86"),
  identical(contract$status, "FROZEN_NAMESPACE_1_BATCH_CONTRACT"),
  length(contract$cases) == contract$expected_case_count,
  contract$expected_case_count == 48L,
  length(contract$needs_new_julia_surface) == contract$needs_new_julia_surface_count,
  contract$needs_new_julia_surface_count == 6L,
  length(contract$negative_controls) >= 2L
)

# --- validate pinned R source (NAMESPACE + every cited file) ---------------
source_root <- file.path(root, ".unlazy/core070-aghq/oracle-source/readback")
namespace_path <- file.path(root, contract$namespace_pin)
stopifnot(file.exists(namespace_path))
namespace_sha_actual <- sha256_file(namespace_path)
stopifnot(identical(namespace_sha_actual, contract$namespace_sha256))
namespace_lines <- readLines(namespace_path, warn = FALSE)

for (rel in names(contract$source_pins)) {
  path <- file.path(source_root, rel)
  stopifnot(file.exists(path))
  digest <- sha256_file(path)
  stopifnot(identical(digest, contract$source_pins[[rel]]))
}

# ---------------------------------------------------------------------------
# The one check this tier performs: for one row, is the NAMESPACE line
# present verbatim, and does the cited file contain a line matching the
# row's definition regex? Exposed as a function so --self-test can call it
# directly on deliberately mutated inputs (rejected-mutation checks).
# ---------------------------------------------------------------------------
check_row <- function(row, ns_lines, file_lines) {
  registered <- row$r_namespace_line %in% trimws(ns_lines)
  defined <- any(grepl(row$r_definition_pattern, file_lines, perl = TRUE))
  list(registered = registered, defined = defined)
}

# Cache file contents once per cited file.
file_cache <- new.env(parent = emptyenv())
get_file_lines <- function(rel) {
  if (!exists(rel, envir = file_cache, inherits = FALSE)) {
    assign(rel, readLines(file.path(source_root, rel), warn = FALSE), envir = file_cache)
  }
  get(rel, envir = file_cache, inherits = FALSE)
}

all_rows <- c(contract$cases, contract$needs_new_julia_surface)

run_all_checks <- function(ns_lines, cache_fn) {
  out <- list()
  for (row in all_rows) {
    fl <- cache_fn(row$r_file)
    out[[row$case_id]] <- check_row(row, ns_lines, fl)
  }
  out
}

r_results <- run_all_checks(namespace_lines, get_file_lines)

r_facts <- lapply(all_rows, function(row) {
  res <- r_results[[row$case_id]]
  list(
    case_id = row$case_id,
    source_id = row$source_id,
    registered = res$registered,
    defined = res$defined,
    ok = isTRUE(res$registered) && isTRUE(res$defined)
  )
})
names(r_facts) <- vapply(all_rows, `[[`, "", "case_id")

# ---------------------------------------------------------------------------
# --self-test: exercise check_row() against the real pinned sources (no
# destination dir, no Julia child) AND against >=4 deliberately mutated
# inputs to prove each check actually discriminates rather than vacuously
# passing. FAILS LOUDLY (non-zero exit via stop()) on any mismatch.
# ---------------------------------------------------------------------------
if (self_test) {
  mismatches <- character(0)
  for (row in all_rows) {
    res <- r_results[[row$case_id]]
    if (!isTRUE(res$registered) || !isTRUE(res$defined)) {
      mismatches <- c(mismatches, sprintf(
        "case %s: expected registered=TRUE defined=TRUE, got registered=%s defined=%s",
        row$case_id, res$registered, res$defined))
    }
  }

  # --- rejected mutations (>=4): corrupt inputs the check must catch -------
  rejected <- character(0)
  probe_row <- all_rows[[1]]
  probe_lines <- get_file_lines(probe_row$r_file)

  # 1. NAMESPACE line missing entirely.
  ns_without <- namespace_lines[trimws(namespace_lines) != trimws(probe_row$r_namespace_line)]
  m1 <- check_row(probe_row, ns_without, probe_lines)
  if (isTRUE(m1$registered)) stop("REJECTED MUTATION 1 FAILED TO BE CAUGHT: NAMESPACE-line removal still read as registered")
  rejected <- c(rejected, "NAMESPACE line removed -> registered=FALSE (caught)")

  # 2. Definition line removed from the source file.
  lines_without_def <- probe_lines[!grepl(probe_row$r_definition_pattern, probe_lines, perl = TRUE)]
  m2 <- check_row(probe_row, namespace_lines, lines_without_def)
  if (isTRUE(m2$defined)) stop("REJECTED MUTATION 2 FAILED TO BE CAUGHT: definition removal still read as defined")
  rejected <- c(rejected, "definition line removed -> defined=FALSE (caught)")

  # 3. NAMESPACE line present but with a typo'd class name (must NOT match).
  garbled_ns_line <- sub(",", ",ZZZ_", probe_row$r_namespace_line, fixed = FALSE)
  ns_garbled <- c(namespace_lines, garbled_ns_line)
  ns_garbled <- ns_garbled[trimws(ns_garbled) != trimws(probe_row$r_namespace_line)]
  m3 <- check_row(probe_row, ns_garbled, probe_lines)
  if (isTRUE(m3$registered)) stop("REJECTED MUTATION 3 FAILED TO BE CAUGHT: garbled NAMESPACE line still read as registered")
  rejected <- c(rejected, "garbled NAMESPACE class name -> registered=FALSE (caught)")

  # 4. Definition present under a DIFFERENT (wrong) generic name (must NOT match).
  wrong_def <- gsub(probe_row$r_name, paste0("zzz_", probe_row$r_name), probe_lines, fixed = TRUE)
  m4 <- check_row(probe_row, namespace_lines, wrong_def)
  if (isTRUE(m4$defined)) stop("REJECTED MUTATION 4 FAILED TO BE CAUGHT: renamed-generic definition still read as defined")
  rejected <- c(rejected, "definition renamed to a different generic -> defined=FALSE (caught)")

  if (length(rejected) < 4L) stop("FATAL: fewer than 4 rejected mutations ran")

  # --- negative controls (>=2): rows whose Julia symbol is genuinely absent,
  #     confirmed via the paired Julia self-test's own contract read (this R
  #     process does not load Julia; it asserts the CONTRACT records these as
  #     expected_julia_symbol_exists == FALSE, which is what the Julia
  #     self-test independently verifies against the live GLLVM module).
  neg_case_ids <- vapply(contract$negative_controls, function(x) {
    if (is.null(x$case_id)) NA_character_ else x$case_id
  }, character(1))
  neg_case_ids <- neg_case_ids[!is.na(neg_case_ids)]
  if (length(neg_case_ids) < 2L) stop("FATAL: fewer than 2 case-anchored negative controls in contract")
  for (cid in neg_case_ids) {
    row <- Filter(function(r) identical(r$case_id, cid), contract$needs_new_julia_surface)[[1]]
    if (!identical(row$expected_julia_symbol_exists, FALSE)) {
      stop("NEGATIVE CONTROL ", cid, " FAILED TO BE CAUGHT: contract does not mark it as an expected absence")
    }
  }

  if (length(mismatches)) {
    for (m in mismatches) message("SELF_TEST_MISMATCH: ", m)
    stop("FATAL: R self-test found ", length(mismatches), " mismatch(es) on the real pinned sources -- see above.")
  }

  cat("CORE070_NAMESPACE_1_R_SELF_TEST_OK rows=", length(all_rows),
      " rejected_mutations=", length(rejected),
      " negative_controls=", length(neg_case_ids), "\n", sep = "")
  quit(status = 0L)
}

# ---------------------------------------------------------------------------
# Normal (non-self-test) invocation: write r-facts.json, invoke the Julia
# child, cross-check, write receipt.
# ---------------------------------------------------------------------------
stopifnot(length(args) == 1L)
output_dir <- args[[1]]
stopifnot(!dir.exists(output_dir))
dir.create(output_dir, recursive = TRUE)

r_facts_path <- file.path(output_dir, "r-facts.json")
jsonlite::write_json(
  list(schema = "core070-namespace-1-r-facts/v1", status = "OK", facts = r_facts),
  r_facts_path, auto_unbox = TRUE, pretty = TRUE, null = "null"
)

julia_out <- file.path(output_dir, "julia-facts.json")
julia_bin <- Sys.which("julia")
stopifnot(nzchar(julia_bin))
t0 <- Sys.time()
julia_status <- system2(julia_bin, c("--project=.", "tools/core070_namespace_1_batch.jl", julia_out),
                         stdout = file.path(output_dir, "julia-stdout.log"),
                         stderr = file.path(output_dir, "julia-stderr.log"))
elapsed <- as.numeric(Sys.time() - t0, units = "secs")

julia_report <- if (file.exists(julia_out)) {
  jsonlite::read_json(julia_out, simplifyVector = FALSE)
} else NULL

exec_ids <- vapply(contract$cases, `[[`, "", "case_id")
needs_ids <- vapply(contract$needs_new_julia_surface, `[[`, "", "case_id")

julia_ok <- function(row) {
  if (is.null(julia_report)) return(FALSE)
  f <- julia_report$facts[[row$julia_symbol]]
  !is.null(f) && identical(f$exists, row$expected_julia_symbol_exists)
}

exec_pass <- vapply(contract$cases, function(row) {
  r_ok <- isTRUE(r_facts[[row$case_id]]$ok)
  r_ok && julia_ok(row)
}, logical(1))
names(exec_pass) <- exec_ids

needs_pass <- vapply(contract$needs_new_julia_surface, function(row) {
  r_ok <- isTRUE(r_facts[[row$case_id]]$ok)  # R side is still expected to be registered+defined
  r_ok && julia_ok(row)                       # and the Julia absence/partial fact must match expectation
}, logical(1))
names(needs_pass) <- needs_ids

results_ok <- !is.null(julia_report) &&
  identical(julia_status, 0L) &&
  identical(julia_report$status, "OK") &&
  all(exec_pass) &&
  all(needs_pass)

raw_lines <- c(
  vapply(exec_ids, function(id) paste(id, if (isTRUE(exec_pass[[id]])) "PASS" else "FAIL", "executable_now", sep = "\t"), character(1)),
  vapply(needs_ids, function(id) paste(id, if (isTRUE(needs_pass[[id]])) "PASS" else "FAIL", "needs_new_julia_surface", sep = "\t"), character(1))
)
raw_path <- file.path(output_dir, "results.tsv")
writeLines(raw_lines, raw_path)

diag_lines <- character(0)
if (!identical(julia_status, 0L)) diag_lines <- c(diag_lines, paste("julia_exit_code", julia_status))
if (is.null(julia_report)) diag_lines <- c(diag_lines, "julia-facts.json was not written")
diag_path <- file.path(output_dir, "diagnostics.log")
writeLines(diag_lines, diag_path)

receipt <- list(
  status = if (isTRUE(results_ok)) "PASS" else "FAIL",
  scope = "CORE070_NAMESPACE_1_BATCH_TIER0",
  reference_commit = contract$reference_commit,
  contract_sha256 = contract_sha256,
  namespace_sha256 = namespace_sha_actual,
  source_pins = contract$source_pins,
  source_unchanged = TRUE,
  executable_now_count = length(exec_ids),
  needs_new_julia_surface_count = length(needs_ids),
  reused_or_reclassify_count = contract$reused_or_reclassify_count,
  julia_exit_code = julia_status,
  julia_elapsed_seconds = elapsed,
  julia_facts_sha256 = if (file.exists(julia_out)) sha256_file(julia_out) else NA_character_,
  r_facts_sha256 = sha256_file(r_facts_path),
  raw_sha256 = sha256_file(raw_path),
  diagnostics_sha256 = sha256_file(diag_path),
  r_version = R.version.string
)
receipt_path <- file.path(output_dir, "receipt.json")
jsonlite::write_json(receipt, receipt_path, auto_unbox = TRUE, pretty = TRUE, null = "null")

cat("CORE070_NAMESPACE_1_BATCH_", receipt$status, "\n", sep = "")
quit(status = if (isTRUE(results_ok)) 0L else 1L)
