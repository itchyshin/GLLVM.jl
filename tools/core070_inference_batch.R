# Retained R-side crosscheck for the "inference" manifest-area batch.
#
# This script does NOT re-run the R routing probe: that evidence is already
# retained and verified PASS at docs/dev-log/core070/inference-routing-subset.json
# (tools/core070_inference_routes.R against test/parity/fixtures/
# core070_inference_routes.tsv, all 98 CI-ROUTE-* rows, frozen source only --
# no installed package, no model fit, no numerical intervals). Re-deriving
# that evidence here would duplicate proven work; instead this script
# (a) re-hashes the pinned R artifacts to confirm they have not drifted since
# that run, (b) filters the retained per-row results down to exactly the 64
# source rows this batch's 19 inference case_ids reference (cross-referenced
# against docs/dev-log/core070/inference-batch-contract.json), and (c) copies
# the retained inputs it read into <destination> with SHA-recorded provenance,
# so this batch's own receipt does not depend on files outside <destination>
# ever staying put.
#
# Usage:
#   Rscript --vanilla tools/core070_inference_batch.R <repo-root> <destination>
#
# argv[1] <repo-root>   the GLLVM.jl checkout containing the pinned artifacts
#                        (docs/dev-log/core070/inference-batch-contract.json,
#                        docs/dev-log/core070/inference-routing-subset.json,
#                        and the retained .unlazy/core070-aghq/inference-routing/
#                        run it points at).
# argv[2] <destination> output directory; MUST NOT already exist.

args <- commandArgs(TRUE)
stopifnot(length(args) == 2L)
root <- normalizePath(args[[1]], mustWork = TRUE)
destination <- args[[2]]
stopifnot(!dir.exists(destination))
dir.create(destination, recursive = TRUE)

suppressPackageStartupMessages(library(jsonlite))

sha256_file <- function(path) {
  command <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  argv <- if (identical(command, "sha256sum")) path else c("-a", "256", path)
  line <- system2(command, argv, stdout = TRUE, stderr = TRUE)
  stopifnot(is.null(attr(line, "status")), length(line) >= 1L)
  sub("[[:space:]].*$", "", line[[1L]])
}

contract_path <- file.path(root, "docs/dev-log/core070/inference-batch-contract.json")
contract <- jsonlite::read_json(contract_path, simplifyVector = FALSE)
stopifnot(identical(contract$reference_commit, "b4d5fee64def88bc768dda1f1f77c29b295edd86"))

# --- re-hash the pinned R route-probe artifacts (fail loudly on drift) -----
pins <- contract$r_route_comparand$pins
for (rel in names(pins)) {
  path <- file.path(root, rel)
  stopifnot(file.exists(path))
  digest <- sha256_file(path)
  stopifnot(identical(digest, pins[[rel]]))
}

subset_evidence <- jsonlite::read_json(
  file.path(root, "docs/dev-log/core070/inference-routing-subset.json"),
  simplifyVector = FALSE
)
stopifnot(identical(subset_evidence$status, "FROZEN_SOURCE_ROUTING_SUBSET_NOT_INTERVAL_PARITY"))

results_rel <- subset_evidence$results
results_path <- file.path(root, results_rel)
stopifnot(file.exists(results_path))
# The subset evidence itself pins this file's hash under current_pins/artifacts;
# re-derive and check rather than trusting the path alone.
observed_hash <- sha256_file(results_path)
pinned_hash <- subset_evidence$artifacts[[results_rel]]
stopifnot(!is.null(pinned_hash), identical(observed_hash, pinned_hash))

r_results <- read.delim(results_path, sep = "\t", stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(all(r_results$pass == "TRUE"))

# --- filter down to this batch's 64 in-scope rows --------------------------
rows <- contract$rows
in_scope_ids <- vapply(rows, function(r) sub("^inference/", "", r$source_id), "")
stopifnot(length(in_scope_ids) == 64L, !anyDuplicated(in_scope_ids))

matched <- r_results[r_results$id %in% in_scope_ids, , drop = FALSE]
stopifnot(nrow(matched) == length(in_scope_ids))
matched <- matched[match(in_scope_ids, matched$id), , drop = FALSE]

bucket_by_id <- setNames(vapply(rows, function(r) r$bucket, ""), in_scope_ids)
case_id_by_id <- setNames(vapply(rows, function(r) r$case_id, ""), in_scope_ids)

crosscheck <- data.frame(
  source_id = matched$id,
  case_id = case_id_by_id[matched$id],
  bucket = bucket_by_id[matched$id],
  r_route_pass = matched$pass == "TRUE",
  r_route_actual = matched$actual,
  stringsAsFactors = FALSE
)
stopifnot(all(crosscheck$r_route_pass))

# --- copy retained inputs into <destination> with SHA-recorded provenance --
retained_dir <- file.path(destination, "retained-inputs")
dir.create(retained_dir, recursive = TRUE)
retained_files <- c(pins_names <- names(pins), results_rel)
provenance <- list()
for (rel in retained_files) {
  src <- file.path(root, rel)
  dst <- file.path(retained_dir, gsub("/", "__", rel))
  ok <- file.copy(src, dst, overwrite = FALSE)
  stopifnot(ok)
  provenance[[rel]] <- list(sha256 = sha256_file(dst), copied_from = rel)
}

crosscheck_path <- file.path(destination, "r-comparand-crosscheck.tsv")
write.table(crosscheck, crosscheck_path, sep = "\t", quote = TRUE, row.names = FALSE)

result <- list(
  status = "PASS",
  scope = "CORE070_INFERENCE_BATCH_R_CROSSCHECK",
  reference_commit = contract$reference_commit,
  contract_sha256 = sha256_file(contract_path),
  r_route_pins = pins,
  r_route_results_sha256 = observed_hash,
  in_scope_row_count = length(in_scope_ids),
  all_in_scope_rows_pass_r_routing = all(crosscheck$r_route_pass),
  retained_input_provenance = provenance,
  r_version = R.version.string
)
results_json_path <- file.path(destination, "inference-batch-r-crosscheck.json")
jsonlite::write_json(result, results_json_path, auto_unbox = TRUE, pretty = TRUE)

receipt <- list(
  status = "PASS",
  scope = "CORE070_INFERENCE_BATCH_R_CROSSCHECK",
  reference_commit = contract$reference_commit,
  contract_sha256 = sha256_file(contract_path),
  source_unchanged = TRUE,
  in_scope_row_count = length(in_scope_ids),
  crosscheck_sha256 = sha256_file(crosscheck_path),
  results_json_sha256 = sha256_file(results_json_path),
  r_version = R.version.string
)
receipt_path <- file.path(destination, "receipt.json")
jsonlite::write_json(receipt, receipt_path, auto_unbox = TRUE, pretty = TRUE)

cat("INFERENCE_BATCH_R_CROSSCHECK_RESULT", nrow(crosscheck), "rows;",
    sum(crosscheck$r_route_pass), "R-side PASS\n")
cat("CORE070_INFERENCE_BATCH_R_CROSSCHECK_PASS\n")
quit(status = 0L)
