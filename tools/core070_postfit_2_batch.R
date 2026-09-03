# Retained evidence runner for the postfit-2 batch (39 native/bridge/readback
# rows, all classified NEEDS_NEW_JULIA_SURFACE by
# docs/dev-log/core070/postfit-2-batch-contract.json -- see that contract for
# the full per-row triage). Unlike tools/core070_masks_known.R and
# tools/core070_data_batch.R, NO case in this batch has a Julia counterpart to
# compare against (that is the batch's own finding, cross-checked at runtime
# by tools/core070_postfit_2_batch.jl), and every r_call here needs an actual
# fitted gllvmTMB_multi object -- not a bare helper function -- so there is no
# cheap in-process replay available the way data.R/offset.R's free functions
# allowed. This runner therefore does NOT load the gllvmTMB package or fit any
# model; its only job is retained evidence that the 39 R functions the
# manifest cites genuinely exist, by name, in the pinned oracle source at the
# reference commit -- grounding the manifest's R-side claims rather than
# trusting them blindly.
#
# ARGV[1] is the R ORACLE SOURCE ROOT (a directory of .R files), NOT an
# installed/frozen library -- this script never library()s or evaluates any
# gllvmTMB code, so there is nothing to install or freeze. In this repo that
# root is .unlazy/core070-aghq/oracle-source/readback/R.
# ARGV[2] is a fresh output directory (must not already exist).
# Usage: Rscript --vanilla tools/core070_postfit_2_batch.R <r-oracle-source-root> <fresh-outdir>

args <- commandArgs(TRUE)
stopifnot(length(args) == 2L)
source_root <- normalizePath(args[[1]], mustWork = TRUE)
output_dir <- args[[2]]
stopifnot(!dir.exists(output_dir))
dir.create(output_dir, recursive = TRUE)

suppressPackageStartupMessages(library(jsonlite))

sha256_string <- function(text) {
  tmp <- tempfile()
  on.exit(unlink(tmp), add = TRUE)
  writeLines(text, tmp, useBytes = TRUE)
  sha256_file(tmp)
}
sha256_file <- function(path) {
  command <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  argv <- if (identical(command, "sha256sum")) path else c("-a", "256", path)
  line <- system2(command, argv, stdout = TRUE, stderr = TRUE)
  stopifnot(is.null(attr(line, "status")), length(line) >= 1L)
  sub("[[:space:]].*$", "", line[[1L]])
}

root <- normalizePath(".")
contract <- jsonlite::read_json(
  file.path(root, "docs/dev-log/core070/postfit-2-batch-contract.json"), simplifyVector = FALSE
)
rows <- contract$rows
stopifnot(length(rows) == 39L)

# ---------------------------------------------------------------------------
# Stage 0: source-pin freshness -- every pinned file's sha256 must match the
# contract's recorded value before anything else is trusted.
# ---------------------------------------------------------------------------
pin_names <- names(contract$source_pins)
pin_status <- lapply(pin_names, function(fname) {
  path <- file.path(source_root, fname)
  present <- file.exists(path)
  actual_sha <- if (present) sha256_file(path) else NA_character_
  expected_sha <- contract$source_pins[[fname]]
  list(file = fname, present = present, expected_sha256 = expected_sha,
       actual_sha256 = actual_sha, matches = isTRUE(present && identical(actual_sha, expected_sha)))
})
names(pin_status) <- pin_names
pins_ok <- all(vapply(pin_status, function(x) x$matches, logical(1L)))

result <- list(
  scope = "CORE070_POSTFIT_2_BATCH_RETAINED_EVIDENCE",
  reference_commit = contract$reference_commit,
  process_receipt = list(r_version = R.version.string, source_root = source_root),
  source_pins = pin_status, source_pins_ok = pins_ok,
  admission = list(), negative_controls = list(), rejected_mutations = list(),
  checks = list(), all_checks = FALSE
)
write_attempt <- function() saveRDS(result, file.path(output_dir, "attempt.rds"))
write_attempt()

# Regex-defines-name checker: does `text` contain a genuine R top-level
# definition of `fn_name` (as a bare name, a backtick-quoted name -- needed
# for names containing dots like `logLik.gllvmTMB_multi`, or a
# quoted-string assignment target)?
defines_function <- function(text, fn_name) {
  esc <- gsub("([.\\\\^$|()\\[\\]{}*+?])", "\\\\\\1", fn_name, perl = TRUE)
  pattern <- paste0(
    "(?m)^(", esc, "|`", esc, "`|\"", esc, "\")\\s*(<-|=)\\s*function\\s*\\("
  )
  grepl(pattern, text, perl = TRUE)
}

# ---------------------------------------------------------------------------
# Stage 1: admit all 39 required rows -- confirm each row's R function name is
# genuinely defined in its pinned source file, fresh off disk.
# ---------------------------------------------------------------------------
admit_row <- function(row_key, row) {
  fname <- row$r_source_file
  fn_name <- row$r_function_name
  path <- file.path(source_root, fname)
  if (!file.exists(path)) {
    return(list(status = "REJECTED_BEFORE_TAPE", error = paste("source file not found:", path)))
  }
  text <- paste(readLines(path, warn = FALSE), collapse = "\n")
  if (defines_function(text, fn_name)) {
    list(status = "PREPARED", error = "")
  } else {
    list(status = "REJECTED_BEFORE_TAPE", error = paste("no definition of", fn_name, "found in", fname))
  }
}
for (row_key in names(rows)) {
  result$admission[[row_key]] <- admit_row(row_key, rows[[row_key]])
}
write_attempt()

# ---------------------------------------------------------------------------
# Stage 2: negative controls -- names that must NOT be found, proving the
# checker rejects rather than vacuously accepting everything.
# ---------------------------------------------------------------------------
negative_controls <- list(
  list(id = "NEG-NONEXISTENT-NAME", file = "methods-gllvmTMB.R", fn_name = "gllvm_totally_fabricated_symbol_xyz123"),
  list(id = "NEG-WRONG-FILE", file = "loading-profile.R", fn_name = "vcov.gllvmTMB_multi")
)
for (nc in negative_controls) {
  path <- file.path(source_root, nc$file)
  text <- if (file.exists(path)) paste(readLines(path, warn = FALSE), collapse = "\n") else ""
  found <- file.exists(path) && defines_function(text, nc$fn_name)
  result$negative_controls[[nc$id]] <- list(
    file = nc$file, fn_name = nc$fn_name, found = found,
    status = if (!found) "REJECTED_AS_EXPECTED" else "UNEXPECTEDLY_ADMITTED"
  )
}
write_attempt()

# ---------------------------------------------------------------------------
# Stage 3: rejected mutations -- corrupt a copy of a real source file four
# different ways and confirm the checker correctly stops admitting the
# targeted function on each corrupted copy (proves the checker inspects real
# content, not just file presence).
# ---------------------------------------------------------------------------
mutate_truncate_name <- function(text, fn_name) {
  # Chop the last 3 characters off the function name wherever it is defined,
  # so the exact-name regex can no longer match.
  short <- substr(fn_name, 1, nchar(fn_name) - 3)
  gsub(fn_name, short, text, fixed = TRUE)
}
mutate_delete_definition <- function(text, fn_name) {
  # Remove every line that starts the function's definition.
  lines <- strsplit(text, "\n", fixed = TRUE)[[1]]
  esc <- gsub("([.\\\\^$|()\\[\\]{}*+?])", "\\\\\\1", fn_name, perl = TRUE)
  pattern <- paste0("^(", esc, "|`", esc, "`)\\s*(<-|=)\\s*function\\s*\\(")
  paste(lines[!grepl(pattern, lines, perl = TRUE)], collapse = "\n")
}
mutate_wrong_operator <- function(text, fn_name) {
  # Replace the assignment arrow with a non-assignment token so it is no
  # longer a valid top-level definition the regex should match.
  esc <- gsub("([.\\\\^$|()\\[\\]{}*+?])", "\\\\\\1", fn_name, perl = TRUE)
  sub(paste0("(", esc, "|`", esc, "`)\\s*<-\\s*function\\s*\\("),
      paste0(fn_name, " ->> NOT_AN_ASSIGNMENT_function("), text, perl = TRUE)
}
mutate_comment_out <- function(text, fn_name) {
  # Prefix the definition line with `#`, turning it into a comment.
  esc <- gsub("([.\\\\^$|()\\[\\]{}*+?])", "\\\\\\1", fn_name, perl = TRUE)
  sub(paste0("(?m)^(", esc, "|`", esc, "`)(\\s*(<-|=)\\s*function\\s*\\()"),
      "# \\1\\2", text, perl = TRUE)
}

mutation_targets <- list(
  list(id = "MUT-TRUNCATE-NAME", file = "vcov-coef.R", fn_name = "vcov.gllvmTMB_multi", mutate = mutate_truncate_name),
  list(id = "MUT-DELETE-DEFINITION", file = "standard-errors.R", fn_name = "standard_errors", mutate = mutate_delete_definition),
  list(id = "MUT-WRONG-OPERATOR", file = "rotate-loadings.R", fn_name = "rotate_loadings", mutate = mutate_wrong_operator),
  list(id = "MUT-COMMENT-OUT", file = "profile-targets.R", fn_name = "profile_targets", mutate = mutate_comment_out)
)
for (mt in mutation_targets) {
  path <- file.path(source_root, mt$file)
  stopifnot(file.exists(path))
  original <- paste(readLines(path, warn = FALSE), collapse = "\n")
  stopifnot(defines_function(original, mt$fn_name))  # sanity: real positive before mutating
  mutated <- mt$mutate(original, mt$fn_name)
  still_found <- defines_function(mutated, mt$fn_name)
  result$rejected_mutations[[mt$id]] <- list(
    file = mt$file, fn_name = mt$fn_name,
    positive_control_found_before_mutation = TRUE,
    found_after_mutation = still_found,
    status = if (!still_found) "CORRECTLY_REJECTED" else "MUTATION_NOT_DETECTED"
  )
}
write_attempt()

# ---------------------------------------------------------------------------
# Final checks
# ---------------------------------------------------------------------------
admitted_ok <- all(vapply(result$admission, function(x) identical(x$status, "PREPARED"), logical(1L)))
negatives_ok <- all(vapply(result$negative_controls, function(x) identical(x$status, "REJECTED_AS_EXPECTED"), logical(1L)))
mutations_ok <- all(vapply(result$rejected_mutations, function(x) identical(x$status, "CORRECTLY_REJECTED"), logical(1L)))

result$checks <- list(
  source_pins_ok = pins_ok,
  all_39_rows_admitted = admitted_ok,
  negative_controls_all_rejected = negatives_ok,
  mutations_all_rejected = mutations_ok
)
result$all_checks <- pins_ok && admitted_ok && negatives_ok && mutations_ok
write_attempt()

writeLines(jsonlite::toJSON(result, auto_unbox = TRUE, null = "null", force = TRUE),
           file.path(output_dir, "result.json"))

cat(sprintf(
  "CORE070_POSTFIT_2_BATCH_R %s pins=%s admitted=%d/39 negctl=%d/2 mut=%d/4\n",
  if (result$all_checks) "PASS" else "FAIL",
  pins_ok, sum(vapply(result$admission, function(x) identical(x$status, "PREPARED"), logical(1L))),
  sum(vapply(result$negative_controls, function(x) identical(x$status, "REJECTED_AS_EXPECTED"), logical(1L))),
  sum(vapply(result$rejected_mutations, function(x) identical(x$status, "CORRECTLY_REJECTED"), logical(1L)))
))
quit(status = if (result$all_checks) 0L else 1L)
