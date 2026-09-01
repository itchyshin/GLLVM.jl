# Retained evidence runner for the masks-known-contract (9 required cases:
# 8 Gaussian fixed-point controls + 1 Poisson structural-only control), plus 2
# batch negative controls (absent/corrupt known_V must be rejected before the
# tape). It deliberately writes an incremental RDS after every stage so an
# interrupted or failing attempt remains inspectable. Usage:
# Rscript --vanilla tools/core070_masks_known.R <frozen-library> <fresh-outdir>
#
# This runner reuses, rather than reimplements, the already-verified dense
# fixed-point math in tools/core070_masks_known_points.R (run as a child
# process) and hands its retained TSV artifacts to the independent Julia
# reconstruction in tools/core070_masks_known.jl (also a child process, run
# directly -- there is no JuliaCall/LD_PRELOAD concern here because this
# feature has no native/formula/bridge fit surface to embed).

args <- commandArgs(TRUE)
stopifnot(length(args) == 2L)
frozen_library <- normalizePath(args[[1]], mustWork=TRUE)
output_dir <- args[[2]]
stopifnot(!dir.exists(output_dir))
dir.create(output_dir, recursive=TRUE)

sha256_file <- function(path) {
  command <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  argv <- if (identical(command, "sha256sum")) path else c("-a", "256", path)
  line <- system2(command, argv, stdout=TRUE, stderr=TRUE)
  stopifnot(is.null(attr(line, "status")), length(line) >= 1L)
  sub("[[:space:]].*$", "", line[[1L]])
}
error_text <- function(e) paste(conditionMessage(e), collapse=" ")

.libPaths(c(frozen_library, .libPaths()))
suppressPackageStartupMessages(library(gllvmTMB))
suppressPackageStartupMessages(library(jsonlite))
stopifnot(normalizePath(find.package("gllvmTMB")) ==
          normalizePath(file.path(frozen_library, "gllvmTMB")))

root <- normalizePath(".")
contract <- jsonlite::read_json(
  file.path(root, "docs/dev-log/core070/masks-known-contract.json"), simplifyVector=FALSE
)
required_case_ids <- vapply(contract$cases, function(x) x$fixture_id, character(1L))
stopifnot(length(required_case_ids) == 9L)

result <- list(
  scope="CORE070_MASKS_KNOWN_RETAINED_EVIDENCE",
  reference_commit=contract$reference_commit,
  process_receipt=list(
    r_version=R.version.string,
    gllvmTMB_version=as.character(utils::packageVersion("gllvmTMB")),
    gllvmTMB_path=find.package("gllvmTMB"), frozen_library=frozen_library
  ),
  admission=list(), byte_identical=list(), batch_negative_controls=list(),
  known_poisson_structural=NULL, points=NULL, julia=NULL, checks=list(), all_checks=FALSE
)
write_attempt <- function() saveRDS(result, file.path(output_dir, "attempt.rds"))
write_attempt()

# ---------------------------------------------------------------------------
# Stage 1: replay every fixture call (9 required + 2 batch negative controls)
# fresh against the frozen library, capturing admission outcome only (this
# mirrors masks-known-subset.json's PREPARED/REJECTED_BEFORE_TAPE columns).
# ---------------------------------------------------------------------------
source(file.path(root, "test/parity/fixtures/core070_masks_known.R"), local=(fixture_env <- new.env()))
get_case <- function(id) {
  hit <- Filter(function(x) identical(x$id, id), fixture_env$cases)
  stopifnot(length(hit) == 1L)
  hit[[1L]]
}
negative_control_ids <- c("KNOWN-MISSING", "KNOWN-DIM")
all_ids <- c(required_case_ids, negative_control_ids)

admit <- function(case) {
  value <- tryCatch(eval(case$call, envir=fixture_env), error=identity)
  if (inherits(value, "error")) {
    list(status="REJECTED_BEFORE_TAPE", error=error_text(value))
  } else {
    list(status="PREPARED", error="")
  }
}

admission <- list()
inputs <- list()
for (id in all_ids) {
  case <- get_case(id)
  outcome <- admit(case)
  admission[[id]] <- list(
    expected=case$expected, observed=outcome$status,
    matches_expected=identical(outcome$status, case$expected),
    error=outcome$error,
    error_contains_expected=if (!is.null(case$error_contains))
      grepl(case$error_contains, outcome$error, fixed=TRUE) else NA
  )
  if (identical(outcome$status, "PREPARED")) {
    inputs[[id]] <- eval(case$call, envir=fixture_env)
  }
}
result$admission <- admission
write_attempt()

# ---------------------------------------------------------------------------
# Stage 2: byte-identical alias/upper-triangle-inert checks.
# ---------------------------------------------------------------------------
plain <- function(x) {
  if (is.language(x)) return(paste(deparse(x), collapse=" "))
  if (is.list(x)) return(lapply(x, plain))
  if (is.object(x)) return(unclass(x))
  x
}
byte_identical <- function(a, b) identical(plain(inputs[[a]]$tmb_obj$env$data), plain(inputs[[b]]$tmb_obj$env$data))
result$byte_identical <- list(
  "KNOWN-ALIAS_equals_KNOWN-EXACT"=tryCatch(byte_identical("KNOWN-ALIAS", "KNOWN-EXACT"), error=function(e) FALSE),
  "MASK-B-UPPER_equals_MASK-B-PINS"=tryCatch(byte_identical("MASK-B-UPPER", "MASK-B-PINS"), error=function(e) FALSE)
)
write_attempt()

# ---------------------------------------------------------------------------
# Stage 3: batch negative controls -- both must reject with the fixture's
# expected diagnostic substring (absent known_V; wrong-dimension known_V).
# ---------------------------------------------------------------------------
result$batch_negative_controls <- setNames(
  lapply(negative_control_ids, function(id) admission[[id]]),
  negative_control_ids
)
write_attempt()

# ---------------------------------------------------------------------------
# Stage 4: KNOWN-POISSON structural-only check (no nll/gradient claim).
# ---------------------------------------------------------------------------
kp <- inputs[["KNOWN-POISSON"]]
result$known_poisson_structural <- if (is.null(kp)) {
  list(status="SPEC-DEFECT", reason="KNOWN-POISSON did not reach PREPARED")
} else {
  d <- kp$tmb_obj$env$data
  list(
    status="PREPARED",
    all_family_id_poisson=isTRUE(all(as.integer(d$family_id_vec) == 2L)),
    use_equalto_flag_set=isTRUE(as.integer(d$use_equalto) == 1L),
    random_effect_is_e_eq=identical(kp$random, "e_eq"),
    nll_gradient_claim="none (matches masks-known-contract.md evidence_kind=structural_only)"
  )
}
write_attempt()

# ---------------------------------------------------------------------------
# Stage 5: run the existing dense fixed-point R child (reused, not
# reimplemented), then the independent Julia reconstruction child, on the
# same fresh inputs directory.
# ---------------------------------------------------------------------------
points_inputs_dir <- file.path(output_dir, "points-inputs")
dir.create(points_inputs_dir)
saveRDS(fixture_env$fixtures, file.path(points_inputs_dir, "fixtures.rds"))
for (id in required_case_ids) {
  if (!is.null(inputs[[id]])) {
    saveRDS(inputs[[id]], file.path(points_inputs_dir, paste0(id, "-input.rds")))
  }
}
points_out_dir <- file.path(output_dir, "points-out")
points_status <- system2("Rscript", c("--vanilla", "tools/core070_masks_known_points.R",
                                       frozen_library, points_inputs_dir, points_out_dir),
                          stdout=file.path(output_dir, "points-stdout.log"),
                          stderr=file.path(output_dir, "points-stderr.log"))
result$points <- list(
  exit_code=points_status,
  out_dir=points_out_dir,
  points_tsv_sha256=if (file.exists(file.path(points_out_dir, "points.tsv")))
    sha256_file(file.path(points_out_dir, "points.tsv")) else NA_character_
)
write_attempt()

julia_output <- file.path(output_dir, "julia-results.json")
julia_status <- if (identical(points_status, 0L)) {
  system2("julia", c("tools/core070_masks_known.jl", points_out_dir, julia_output),
          stdout=file.path(output_dir, "julia-stdout.log"),
          stderr=file.path(output_dir, "julia-stderr.log"))
} else {
  NA_integer_
}
result$julia <- list(
  exit_code=julia_status,
  results=if (isTRUE(julia_status == 0L) && file.exists(julia_output))
    jsonlite::read_json(julia_output, simplifyVector=FALSE) else NULL
)
write_attempt()

# ---------------------------------------------------------------------------
# Final verdict.
# ---------------------------------------------------------------------------
required_admission_ok <- all(vapply(required_case_ids, function(id) isTRUE(admission[[id]]$matches_expected), logical(1L)))
negative_controls_ok <- all(vapply(negative_control_ids, function(id) {
  isTRUE(admission[[id]]$matches_expected) && isTRUE(admission[[id]]$error_contains_expected)
}, logical(1L)))
result$checks <- list(
  required_admission=required_admission_ok,
  batch_negative_controls=negative_controls_ok,
  byte_identical_alias=isTRUE(result$byte_identical[["KNOWN-ALIAS_equals_KNOWN-EXACT"]]),
  byte_identical_upper=isTRUE(result$byte_identical[["MASK-B-UPPER_equals_MASK-B-PINS"]]),
  known_poisson_structural=isTRUE(result$known_poisson_structural$status == "PREPARED") &&
    isTRUE(result$known_poisson_structural$all_family_id_poisson) &&
    isTRUE(result$known_poisson_structural$use_equalto_flag_set) &&
    isTRUE(result$known_poisson_structural$random_effect_is_e_eq),
  dense_points_batch=identical(result$points$exit_code, 0L),
  julia_reconstruction=identical(result$julia$exit_code, 0L) &&
    isTRUE(result$julia$results$all_gaussian_points_pass)
)
result$all_checks <- all(unlist(result$checks))

saveRDS(result, file.path(output_dir, "masks-known-results.rds"))
jsonlite::write_json(plain(result), file.path(output_dir, "masks-known-results.json"),
                      auto_unbox=TRUE, pretty=TRUE, digits=NA, null="null")
cat("CORE070_MASKS_KNOWN_RESULTS_SHA256", sha256_file(file.path(output_dir, "masks-known-results.json")), "\n")
if (!isTRUE(result$all_checks)) quit(status=1L)
