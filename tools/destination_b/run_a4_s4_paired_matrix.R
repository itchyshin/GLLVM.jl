#!/usr/bin/env Rscript
# Closed A4/S4 paired-evidence runner.  This never calls the public R formula
# admission path.  Its only Julia invocation is the private bridge contract.
#
# Usage:
#   Rscript run_a4_s4_paired_matrix.R CORE070 PROJECT JULIA_BIN OUTPUT_JSON
#
# The batch is expected to take 10--20 minutes in the already prepared local
# environment.  It refuses to overwrite either terminal JSON or raw RDS.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4L) {
  stop("usage: run_a4_s4_paired_matrix.R CORE070 PROJECT JULIA_BIN OUTPUT_JSON", call. = FALSE)
}
core070 <- normalizePath(args[[1L]], mustWork = TRUE)
project <- normalizePath(args[[2L]], mustWork = TRUE)
julia_bin <- normalizePath(args[[3L]], mustWork = TRUE)
output <- args[[4L]]
raw_output <- paste0(output, ".rds")
raw_rows <- paste0(raw_output, ".", c("tree", "pedigree", "dense"))
if (any(file.exists(c(output, raw_output, raw_rows)))) {
  stop("refusing to overwrite an A4/S4 terminal or raw receipt", call. = FALSE)
}
if (!requireNamespace("jsonlite", quietly = TRUE) ||
    !requireNamespace("digest", quietly = TRUE) ||
    !requireNamespace("JuliaCall", quietly = TRUE)) {
  stop("jsonlite, digest, and JuliaCall are required", call. = FALSE)
}
if (!identical(normalizePath(Sys.getenv("JULIA_PROJECT"), mustWork = TRUE), project)) {
  stop("JULIA_PROJECT must name the supplied combined Julia environment", call. = FALSE)
}

frozen_pin <- "b4d5fee64def88bc768dda1f1f77c29b295edd86"
frozen_dll <- "91bfa6d90fbf3e4f42e1f4160583f2607f51a7839bb54a02a209da6e31a59beb"
sha <- function(path) unname(tools::sha256sum(path))[[1L]]
git_output <- function(args) {
  output <- suppressWarnings(system2("git", args, stdout = TRUE, stderr = TRUE))
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) {
    stop(sprintf("git %s failed while recording execution provenance",
      paste(args, collapse = " ")), call. = FALSE)
  }
  output
}
project_toml <- file.path(project, "Project.toml")
manifest_toml <- file.path(project, "Manifest.toml")
if (!file.exists(project_toml)) {
  stop("the supplied Julia project has no Project.toml", call. = FALSE)
}
source_tree_commit <- trimws(git_output(c("-C", project, "rev-parse", "HEAD"))[[1L]])
source_tree_dirty <- length(git_output(c("-C", project, "status", "--porcelain"))) > 0L
row_path <- function(kind) file.path(core070, switch(kind,
  tree = "destination-b-tree/r-bfgs-attempt-01.json",
  pedigree = "destination-b-pedigree-fit/r-bfgs-attempt-01.json",
  dense = "destination-b-s3b-pilot/r-attempt-02.json"))
precision_source_path <- function(kind) file.path(core070, switch(kind,
  tree = "destination-b-tree/precision-reference.json",
  pedigree = "destination-b-pedigree/precision-reference.json",
  dense = "destination-b-s3b-pilot/r-attempt-02.json"))

fixtures_path <- file.path(core070, "destination-b-adapter/fixtures-01.json")
fixtures <- jsonlite::fromJSON(fixtures_path, simplifyVector = FALSE)
if (!all(c("tree", "pedigree", "dense") %in% names(fixtures$bundles))) {
  stop("the retained fixture bundle does not contain tree, pedigree, and dense rows", call. = FALSE)
}

result <- list(
  schema_version = "destination-b-a4-s4-paired-matrix-1",
  status = "error",
  provenance = list(frozen_source_pin = frozen_pin, frozen_dll_sha256 = frozen_dll,
    julia_source_sha256 = sha(file.path(project, "src", "bridge_precision_multivariate.jl"))),
  execution_provenance = list(attestation_status = "runner_recorded_unverified",
    julia_executable_sha256 = sha(julia_bin), project_toml_sha256 = sha(project_toml),
    manifest_toml_sha256 = if (file.exists(manifest_toml)) sha(manifest_toml) else "unavailable",
    source_tree_commit = source_tree_commit, source_tree_dirty = source_tree_dirty),
  route = list(entrypoint = "GLLVM.bridge_fit", phylo_model = "multivariate",
    private_candidate_only = TRUE, public_formula_admission = "closed"),
  qualification = list(qualified = FALSE, r_public_admission = "closed",
    note = "candidate evidence only; no admission is qualified"),
  rows = list(), warnings = list()
)

fixture_descriptor <- function(kind) switch(kind,
  tree = list(kind = "tree", height = 4L, unit_ultrametric = FALSE),
  pedigree = list(kind = "pedigree", n_nodes = 12L, n_observed = 8L,
    n_unobserved_ancestors = 4L),
  dense = list(kind = "dense", ridge_operation = "A + 1e-8 I; solve once"))
raw_interval_target <- function(fit, kind) {
  if (identical(kind, "dense")) {
    return(list(target_names = character(), method = "not_run", status = "unavailable",
      gate = "not_assessed"))
  }
  status <- as.character(fit$ci_status)
  names <- as.character(fit$ci_target_names)
  methods <- as.character(fit$ci_target_methods)
  if (identical(status, "available") && length(names) == 12L &&
      length(methods) == 12L && all(methods == "transformed_wald")) {
    return(list(target_names = names, method = "transformed_wald", status = status,
      gate = "not_assessed"))
  }
  list(target_names = names, method = "bridge_reported", status = status,
    gate = "not_assessed")
}

# The only permitted bridge call.  In particular, there is no gllvmTMB(), no
# formula object, and no public-admission option in this runner.
bridge_one <- function(Y, precision, species_id, ci_method) {
  do.call(JuliaCall::julia_call, list("GLLVM.bridge_fit", y = Y,
    family = "gaussian", d = 1L, phylo = precision,
    options = list(phylo_model = "multivariate", mode = "barelowrank",
      residual_mode = "shared", species_id = as.integer(species_id),
      ci_method = ci_method, g_tol = 1e-5, iterations = 400L)))
}

tryCatch({
  JuliaCall::julia_setup(JULIA_HOME = dirname(julia_bin), installJulia = FALSE,
    install = FALSE, rebuild = FALSE, verbose = FALSE)
  JuliaCall::julia_command(sprintf(
    "import Pkg; Pkg.activate(%s); using GLLVM", encodeString(project, quote = '"')))

  for (kind in c("tree", "pedigree", "dense")) {
    reference_path <- row_path(kind)
    reference <- jsonlite::fromJSON(reference_path, simplifyVector = FALSE)
    bundle <- fixtures$bundles[[kind]]
    precision <- bundle$precision
    Y <- if (identical(kind, "dense")) reference$response$Y_traits_by_observations else
      reference$Y_traits_by_observations
    source_pin <- if (identical(kind, "dense")) reference$provenance$frozen_source_pin else reference$source_pin
    dll_hash <- if (identical(kind, "dense")) reference$provenance$dll_sha256 else reference$dll_sha256
    data_hash <- if (identical(kind, "dense")) reference$response$data_sha256 else reference$data_sha256
    if (!identical(source_pin, frozen_pin) || !identical(dll_hash, frozen_dll)) {
      stop(sprintf("%s does not name the frozen R source/DLL", kind), call. = FALSE)
    }
    species_id <- as.integer(bundle$species_id)
    if (length(species_id) != ncol(Y) || any(!species_id %in% seq_len(precision$n_leaves))) {
      stop(sprintf("%s fixture has no valid observation-level species_id map", kind), call. = FALSE)
    }
    ci_request <- if (identical(kind, "dense")) "none" else "wald"
    ridge_evidence <- if (identical(kind, "dense")) {
      operation <- reference$source_covariance$ridge_operation
      expected_operation <- "A_ridged = A_original + 1e-8 * I; Q_canonical = solve(A_ridged)"
      if (!identical(operation, expected_operation)) {
        stop("dense retained source does not document the canonical one-ridge operation", call. = FALSE)
      }
      list(source_covariance_reference_sha256 = sha(reference_path),
        source_covariance_operation = operation)
    } else NULL
    started <- proc.time()[["elapsed"]]
    fit <- bridge_one(Y, precision, species_id, ci_request)
    elapsed <- proc.time()[["elapsed"]] - started
    raw_rds_path <- paste0(raw_output, ".", kind)
    saveRDS(fit, raw_rds_path)

    # The terminal record preserves runner-reported return metadata. Its RDS
    # SHA and CI payload are not independently authenticated evidence, and
    # neither this runner nor its verifier opens R admission.
    result$rows[[length(result$rows) + 1L]] <- list(
      row_id = switch(kind, tree = "tree_height4_nonunit_ultrametric",
        pedigree = "pedigree_12_nodes_8_observed_4_unobserved",
        dense = "dense_vcv_ridged_once"),
      fixture = fixture_descriptor(kind), evidence_status = "candidate_input_only",
      data_sha256 = data_hash,
      reference = list(source_pin = source_pin, dll_sha256 = dll_hash,
        julia_source_sha256 = result$provenance$julia_source_sha256,
        data_sha256 = data_hash, reference_file_sha256 = sha(reference_path)),
      precision = list(precision_payload_sha256 = sha(fixtures_path),
        precision_source_sha256 = sha(precision_source_path(kind)),
        log_det_Q = precision$log_det, scale = precision$scale,
        ridge = if (identical(kind, "dense")) 1e-8 else 0,
        ridge_applied_once = identical(kind, "dense")),
      ridge_evidence = ridge_evidence,
      map = list(observed_species_to_augmented_zero_based = precision$species_aug_id,
        species_id_one_based = species_id,
        observation_to_augmented_zero_based = precision$species_aug_id[species_id],
        n_augmented = precision$n_aug, n_species_observed = precision$n_leaves,
        n_observations = length(species_id)),
      bridge_result = list(status = "returned", admission_status = fit$admission_status,
        ci_status = fit$ci_status, ci_target_names = as.character(fit$ci_target_names),
        ci_target_methods = as.character(fit$ci_target_methods),
        ci_statuses = as.character(fit$ci_statuses),
        ci_payload_attestation_status = "runner_recorded_unverified"),
      raw_rds_sha256 = sha(raw_rds_path),
      raw_artifact = list(attestation_status = "runner_recorded_unverified"),
      ci_request = ci_request, elapsed_seconds = elapsed,
      interval_target = raw_interval_target(fit, kind),
      qualification = list(qualified = FALSE, r_public_admission = "closed")
    )
  }
  # This JSON is a raw transport record, deliberately not a verified paired
  # matrix: the independent R own-optimum diagnostics must be supplied by a
  # subsequent evidence writer rather than inferred or fabricated here.
  result$schema_version <- "destination-b-a4-s4-private-bridge-raw-1"
  result$status <- "raw_bridge_returns_recorded_unqualified"
  jsonlite::write_json(result, output, auto_unbox = TRUE, pretty = TRUE,
    digits = 17L, null = "null", na = "null")
  cat("A4_S4_PRIVATE_BRIDGE_RETURNS_RECORDED_UNQUALIFIED\n")
}, error = function(error) {
  result$error <- conditionMessage(error)
  jsonlite::write_json(result, output, auto_unbox = TRUE, pretty = TRUE,
    digits = 17L, null = "null", na = "null")
  stop(error)
})
