#!/usr/bin/env Rscript
# Source-attested, tree-only R own-optimum runner for the frozen A4/S4 cell.
#
# This is deliberately an R-only receipt producer.  It neither reads the
# fixed-coordinate raw RDS nor initializes Julia, any cross-runtime call, intervals, or a
# paired comparison.  The only future fit is a fresh gllvmTMB TMB-engine fit
# with native default data-derived initialization and no externally supplied coordinate.

a4_s4_tree_r_own_optimum_schema <- "destination-b-a4-s4-tree-r-own-optimum-1"
a4_s4_tree_r_own_optimum_pin <- "b4d5fee64def88bc768dda1f1f77c29b295edd86"
a4_s4_tree_r_own_optimum_archive_sha256 <- "0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc"
a4_s4_tree_r_own_optimum_namespace_sha256 <- "9094613610789faab69c43195d3cfdafb2c7dfef284e6646b10dababa4fa132c"
a4_s4_tree_r_own_optimum_source_tree_sha256 <- "f83545faa6543dbb1f64d64bbf5a9498adcdf036cc3da5851f269912698b1cc7"
a4_s4_tree_r_own_optimum_fixture_sha256 <- "089f87d0dcf3c1014fc99646953d8696a0d5aa747287561dd815b5b8bf097549"
a4_s4_tree_r_own_optimum_reference_sha256 <- "08c2c0f8dca3bb601e716da30d64dae2cd0ce3834766fa557dabb0444ddf4bd7"
a4_s4_tree_r_own_optimum_precision_sha256 <- "ab01ee47206565eb1af7da391af313953b8a97c6bb11d9b6160655aaa0429170"
a4_s4_tree_r_own_optimum_response_sha256 <- "a096e8a4f4408923ea0e906defef936f133b92b65202a9baac9fff0d197373c2"
a4_s4_tree_r_own_optimum_marker_name <- "CORE070_SOURCE_PIN.toml"
a4_s4_tree_r_own_optimum_dll_sha256 <- "5d8a9c43b725911452716d4462e655a974c06274925bdee0f1b0c9abec399fe1"
a4_s4_tree_r_own_optimum_installed_tree_sha256 <- "12c91ba3c8753bfccba2a1cda966a02e33a776892f52600377c9561a6ddd2b67"
a4_s4_tree_r_own_optimum_marker_sha256 <- "06d44520a7dbd35e52edb0b709f0cf7f9069ef45a45c52a144f260872a2b48a2"
a4_s4_tree_r_own_optimum_build_receipt_sha256 <- "ecb2bf37e4bc5ec4cbe60be777f9e46c4b7812387ee381e71077609872254b8a"
a4_s4_tree_r_own_optimum_install_log_sha256 <- "f384affeb31926be6514ee8301c014fcde7e265a074e35da17132615692ce429"

a4_s4_tree_r_own_optimum_stop <- function(message) stop(message, call. = FALSE)
a4_s4_tree_r_own_optimum_sha <- function(path, label) {
  if (!is.character(path) || length(path) != 1L || !file.exists(path) || dir.exists(path))
    a4_s4_tree_r_own_optimum_stop(sprintf("%s must be a readable file", label))
  value <- unname(tools::sha256sum(path))[[1L]]
  if (!is.character(value) || !grepl("^[0-9a-f]{64}$", value))
    a4_s4_tree_r_own_optimum_stop(sprintf("%s has no SHA-256 digest", label))
  value
}
a4_s4_tree_r_own_optimum_digest <- function(value, label) {
  if (!is.character(value) || length(value) != 1L || !grepl("^[0-9a-f]{64}$", value))
    a4_s4_tree_r_own_optimum_stop(sprintf("%s must be one lowercase SHA-256 digest", label))
  value
}
a4_s4_tree_r_own_optimum_exact_names <- function(x, expected, label) {
  if (!is.list(x) || !identical(names(x), expected))
    a4_s4_tree_r_own_optimum_stop(sprintf("%s has an unexpected field set", label))
  invisible(x)
}
a4_s4_tree_r_own_optimum_contract <- function() {
  list(
    row_id = "tree_height4_nonunit_ultrametric", package_version = "0.7.0",
    source_pin = a4_s4_tree_r_own_optimum_pin,
    hashes = list(fixture = a4_s4_tree_r_own_optimum_fixture_sha256,
      reference = a4_s4_tree_r_own_optimum_reference_sha256,
      precision = a4_s4_tree_r_own_optimum_precision_sha256,
      response = a4_s4_tree_r_own_optimum_response_sha256),
    map = list(species_id_one_based = rep(seq_len(8L), each = 2L),
      species_aug_id_zero_based = c(13L, 6L, 11L, 8L, 12L, 7L, 10L, 9L),
      observation_to_augmented_zero_based = c(13L, 13L, 6L, 6L, 11L, 11L, 8L, 8L,
        12L, 12L, 7L, 7L, 10L, 10L, 9L, 9L), n_augmented = 14L,
      n_species_observed = 8L, n_observations = 16L),
    precision = list(log_det_Q = 15.706819081565975, scale = 4,
      ridge = 0, ridge_applied_once = FALSE, ridge_operation = NULL)
  )
}

a4_s4_tree_r_own_optimum_validate_request <- function(request) {
  expected <- c("schema_version", "row_id", "package_version", "source_pin",
    "build_receipt_sha256", "hashes", "map", "precision", "engine", "start_policy",
    "qualified", "public_formula_admission", "intervals", "paired_comparison")
  a4_s4_tree_r_own_optimum_exact_names(request, expected, "tree own-optimum request")
  contract <- a4_s4_tree_r_own_optimum_contract()
  if (!identical(request$schema_version, a4_s4_tree_r_own_optimum_schema) ||
      !identical(request$row_id, contract$row_id) ||
      !identical(request$package_version, contract$package_version) ||
      !identical(request$source_pin, contract$source_pin) ||
      !identical(request$hashes, contract$hashes) || !identical(request$map, contract$map) ||
      !identical(request$precision, contract$precision) || !identical(request$engine, "tmb") ||
      !identical(request$start_policy, "native_default_data_derived_no_external_coordinate") ||
      !identical(request$qualified, FALSE) ||
      !identical(request$public_formula_admission, "closed") ||
      !identical(request$intervals, "not_computed") ||
      !identical(request$paired_comparison, "not_computed"))
    a4_s4_tree_r_own_optimum_stop("request differs from the frozen tree-only own-optimum contract")
  if (!identical(a4_s4_tree_r_own_optimum_digest(request$build_receipt_sha256, "build receipt digest"),
      a4_s4_tree_r_own_optimum_build_receipt_sha256))
    a4_s4_tree_r_own_optimum_stop("request build receipt digest differs from retained source-attested alignment")
  request
}
a4_s4_tree_r_own_optimum_request <- function(build_receipt_sha256) {
  c <- a4_s4_tree_r_own_optimum_contract()
  a4_s4_tree_r_own_optimum_validate_request(list(schema_version = a4_s4_tree_r_own_optimum_schema,
    row_id = c$row_id, package_version = c$package_version, source_pin = c$source_pin,
    build_receipt_sha256 = a4_s4_tree_r_own_optimum_digest(build_receipt_sha256, "build receipt digest"),
    hashes = c$hashes, map = c$map, precision = c$precision, engine = "tmb",
    start_policy = "native_default_data_derived_no_external_coordinate", qualified = FALSE,
    public_formula_admission = "closed", intervals = "not_computed",
    paired_comparison = "not_computed"))
}

a4_s4_tree_r_own_optimum_output_exists <- function(path) {
  target <- Sys.readlink(path)
  isTRUE(file.exists(path)) || (length(target) == 1L && !is.na(target) && nzchar(target))
}
a4_s4_tree_r_own_optimum_output_fence <- function(path) {
  if (!is.character(path) || length(path) != 1L || !nzchar(path) ||
      a4_s4_tree_r_own_optimum_output_exists(path) || !dir.exists(dirname(path)))
    a4_s4_tree_r_own_optimum_stop("refusing to overwrite or misplace tree own-optimum receipt")
  normalizePath(path, mustWork = FALSE)
}
a4_s4_tree_r_own_optimum_publish <- function(receipt, output) {
  temporary <- tempfile(pattern = ".tree-r-own-optimum-", tmpdir = dirname(output))
  on.exit(if (file.exists(temporary)) unlink(temporary, force = TRUE), add = TRUE)
  saveRDS(receipt, temporary)
  if (a4_s4_tree_r_own_optimum_output_exists(output) || !isTRUE(file.link(temporary, output)))
    a4_s4_tree_r_own_optimum_stop("tree own-optimum receipt could not be published without overwrite")
  unlink(temporary, force = TRUE)
  invisible(output)
}

a4_s4_tree_r_own_optimum_is_symlink <- function(path) {
  target <- Sys.readlink(path)
  length(target) == 1L && !is.na(target) && nzchar(target)
}
a4_s4_tree_r_own_optimum_tree_sha <- function(root, exclude = character()) {
  root <- normalizePath(root, mustWork = TRUE)
  entries <- list.files(root, recursive = TRUE, all.files = TRUE, include.dirs = TRUE,
    full.names = TRUE, no.. = TRUE)
  if (!length(entries) || any(vapply(entries, a4_s4_tree_r_own_optimum_is_symlink, logical(1L))))
    a4_s4_tree_r_own_optimum_stop("installed frozen package tree is empty or contains a symlink")
  info <- file.info(entries)
  files <- entries[!is.na(info$isdir) & !as.logical(info$isdir)]
  relative <- substring(files, nchar(root) + 2L)
  keep <- !(relative %in% exclude)
  files <- files[keep]; relative <- relative[keep]
  if (!length(files) || anyDuplicated(relative))
    a4_s4_tree_r_own_optimum_stop("installed frozen package tree has no unique file manifest")
  hashes <- vapply(seq_along(files), function(i)
    a4_s4_tree_r_own_optimum_sha(files[[i]], relative[[i]]), character(1L))
  order <- order(relative, method = "radix")
  payload <- raw()
  for (i in order) {
    payload <- c(payload, charToRaw(relative[[i]]), as.raw(0L), charToRaw(hashes[[i]]), as.raw(10L))
  }
  # The terminal delimiter is deliberately removed: this matches the build oracle.
  digest::digest(payload[-length(payload)], algo = "sha256", serialize = FALSE)
}
a4_s4_tree_r_own_optimum_marker_fields <- function() c("reference_commit", "archive_sha256",
  "namespace_sha256", "source_tree_sha256", "installed_tree_sha256")
a4_s4_tree_r_own_optimum_marker <- function(package_path, expected) {
  marker_path <- file.path(package_path, a4_s4_tree_r_own_optimum_marker_name)
  lines <- readLines(marker_path, warn = FALSE)
  fields <- a4_s4_tree_r_own_optimum_marker_fields()
  values <- vapply(fields, function(field) {
    pattern <- paste0("^", field, "[[:space:]]*=[[:space:]]*\\\"([0-9a-f]{40}|[0-9a-f]{64})\\\"[[:space:]]*$")
    hit <- grep(pattern, lines, value = TRUE)
    if (length(hit) != 1L) a4_s4_tree_r_own_optimum_stop("source marker has an invalid field")
    sub(pattern, "\\1", hit[[1L]])
  }, character(1L))
  names(values) <- fields
  expected_values <- c(reference_commit = a4_s4_tree_r_own_optimum_pin,
    archive_sha256 = a4_s4_tree_r_own_optimum_archive_sha256,
    namespace_sha256 = a4_s4_tree_r_own_optimum_namespace_sha256,
    source_tree_sha256 = a4_s4_tree_r_own_optimum_source_tree_sha256,
    installed_tree_sha256 = expected$installed_tree_sha256)
  if (!identical(values, expected_values) || !identical(
      a4_s4_tree_r_own_optimum_sha(file.path(package_path, "NAMESPACE"), "installed NAMESPACE"),
      a4_s4_tree_r_own_optimum_namespace_sha256) || !identical(
      a4_s4_tree_r_own_optimum_tree_sha(package_path, a4_s4_tree_r_own_optimum_marker_name),
      expected$installed_tree_sha256))
    a4_s4_tree_r_own_optimum_stop("installed marker, namespace, or tree differs from frozen source")
  list(path = marker_path, sha256 = a4_s4_tree_r_own_optimum_sha(marker_path, "installed marker"),
    installed_tree_sha256 = expected$installed_tree_sha256)
}
a4_s4_tree_r_own_optimum_runtime <- function() {
  package_record <- function(package) list(version = as.character(utils::packageVersion(package)),
    path = normalizePath(find.package(package), mustWork = TRUE),
    description_sha256 = a4_s4_tree_r_own_optimum_sha(file.path(find.package(package), "DESCRIPTION"),
      sprintf("%s DESCRIPTION", package)))
  packages <- lapply(c("TMB", "Matrix", "ape"), package_record)
  names(packages) <- c("TMB", "Matrix", "ape")
  list(r_version = R.version.string, packages = packages)
}
a4_s4_tree_r_own_optimum_validate_oracle_build <- function(frozen_library, expected_build_sha256) {
  if (!requireNamespace("jsonlite", quietly = TRUE) || !requireNamespace("digest", quietly = TRUE))
    a4_s4_tree_r_own_optimum_stop("jsonlite and digest are required for build provenance")
  frozen_library <- normalizePath(frozen_library, mustWork = TRUE)
  if (!identical(basename(frozen_library), "library"))
    a4_s4_tree_r_own_optimum_stop("frozen library must be an oracle build library directory")
  build_root <- dirname(frozen_library); receipt_path <- file.path(build_root, "build.json")
  source_path <- file.path(build_root, "source"); install_log <- file.path(build_root, "install.log")
  expected_build_sha256 <- a4_s4_tree_r_own_optimum_digest(expected_build_sha256, "build receipt digest")
  if (!identical(expected_build_sha256, a4_s4_tree_r_own_optimum_build_receipt_sha256))
    a4_s4_tree_r_own_optimum_stop("build receipt digest is not the retained source-attested alignment value")
  if (!identical(a4_s4_tree_r_own_optimum_sha(receipt_path, "build receipt"), expected_build_sha256))
    a4_s4_tree_r_own_optimum_stop("build receipt differs from supplied attestation")
  receipt <- tryCatch(jsonlite::fromJSON(receipt_path, simplifyVector = FALSE),
    error = function(e) a4_s4_tree_r_own_optimum_stop("build receipt is not readable JSON"))
  required <- c("reference_commit", "archive_sha256", "source_tree_sha256", "installed_tree_sha256",
    "marker_sha256", "log_sha256", "exit_code", "original_source_unchanged")
  hashes <- c("installed_tree_sha256", "marker_sha256", "log_sha256")
  if (!is.list(receipt) || !all(required %in% names(receipt)) ||
      !identical(as.character(receipt$reference_commit), a4_s4_tree_r_own_optimum_pin) ||
      !identical(as.character(receipt$archive_sha256), a4_s4_tree_r_own_optimum_archive_sha256) ||
      !identical(as.character(receipt$source_tree_sha256), a4_s4_tree_r_own_optimum_source_tree_sha256) ||
      !identical(as.character(receipt$installed_tree_sha256), a4_s4_tree_r_own_optimum_installed_tree_sha256) ||
      !identical(as.character(receipt$marker_sha256), a4_s4_tree_r_own_optimum_marker_sha256) ||
      !identical(as.character(receipt$log_sha256), a4_s4_tree_r_own_optimum_install_log_sha256) ||
      !all(grepl("^[0-9a-f]{64}$", vapply(hashes, function(x) as.character(receipt[[x]]), character(1L)))) ||
      !identical(as.integer(receipt$exit_code), 0L) || !identical(receipt$original_source_unchanged, TRUE) ||
      !identical(a4_s4_tree_r_own_optimum_sha(file.path(source_path, "NAMESPACE"), "source NAMESPACE"),
        a4_s4_tree_r_own_optimum_namespace_sha256) ||
      !identical(a4_s4_tree_r_own_optimum_sha(install_log, "install log"), as.character(receipt$log_sha256)))
    a4_s4_tree_r_own_optimum_stop("build receipt, source, or install log is not the attested frozen build")
  marker <- a4_s4_tree_r_own_optimum_marker(file.path(frozen_library, "gllvmTMB"),
    list(installed_tree_sha256 = as.character(receipt$installed_tree_sha256)))
  if (!identical(marker$sha256, as.character(receipt$marker_sha256)))
    a4_s4_tree_r_own_optimum_stop("installed marker differs from the attested build receipt")
  list(oracle_build_root = build_root, oracle_build_receipt_path = receipt_path,
    oracle_build_receipt_sha256 = expected_build_sha256, oracle_source_path = source_path,
    oracle_install_log_sha256 = as.character(receipt$log_sha256), marker = marker)
}

# Verify the source/build state before loading the DLL, then bind the actual loaded bytes.
a4_s4_tree_r_own_optimum_frozen_package <- function(frozen_library, expected_build_sha256) {
  if ("gllvmTMB" %in% loadedNamespaces()) a4_s4_tree_r_own_optimum_stop("gllvmTMB must not already be loaded")
  oracle <- a4_s4_tree_r_own_optimum_validate_oracle_build(frozen_library, expected_build_sha256)
  package_path <- file.path(normalizePath(frozen_library, mustWork = TRUE), "gllvmTMB")
  if (!identical(as.character(read.dcf(file.path(package_path, "DESCRIPTION"), fields = "Version")[1L, "Version"]), "0.7.0"))
    a4_s4_tree_r_own_optimum_stop("frozen library is not gllvmTMB 0.7.0")
  .libPaths(c(frozen_library, .libPaths())); library("gllvmTMB", lib.loc = frozen_library, character.only = TRUE)
  expected_dll <- file.path(package_path, "libs", paste0("gllvmTMB", .Platform$dynlib.ext))
  loaded_dll <- getLoadedDLLs()[["gllvmTMB"]][["path"]]
  if (is.null(loaded_dll) || !identical(normalizePath(loaded_dll, mustWork = TRUE), normalizePath(expected_dll, mustWork = TRUE)))
    a4_s4_tree_r_own_optimum_stop("loaded DLL is not the attested frozen package DLL")
  dll_sha <- a4_s4_tree_r_own_optimum_sha(expected_dll, "loaded gllvmTMB DLL")
  if (!identical(dll_sha, a4_s4_tree_r_own_optimum_dll_sha256))
    a4_s4_tree_r_own_optimum_stop("loaded DLL differs from retained source-attested alignment bytes")
  list(package_version = "0.7.0", package_path = package_path, dll_path = expected_dll,
    dll_sha256 = dll_sha,
    source_pin = a4_s4_tree_r_own_optimum_pin, archive_sha256 = a4_s4_tree_r_own_optimum_archive_sha256,
    namespace_sha256 = a4_s4_tree_r_own_optimum_namespace_sha256,
    source_tree_sha256 = a4_s4_tree_r_own_optimum_source_tree_sha256,
    installed_tree_sha256 = oracle$marker$installed_tree_sha256, marker_path = oracle$marker$path,
    marker_sha256 = oracle$marker$sha256, oracle_build_root = oracle$oracle_build_root,
    oracle_build_receipt_path = oracle$oracle_build_receipt_path,
    oracle_build_receipt_sha256 = oracle$oracle_build_receipt_sha256,
    oracle_source_path = oracle$oracle_source_path, oracle_install_log_sha256 = oracle$oracle_install_log_sha256,
    runtime = a4_s4_tree_r_own_optimum_runtime(), source_provenance = "verified_installed_marker")
}
a4_s4_tree_r_own_optimum_assert_frozen_unchanged <- function(frozen) {
  oracle <- a4_s4_tree_r_own_optimum_validate_oracle_build(
    file.path(frozen$oracle_build_root, "library"), frozen$oracle_build_receipt_sha256)
  if (!identical(oracle$marker$installed_tree_sha256, frozen$installed_tree_sha256) ||
      !identical(oracle$marker$sha256, frozen$marker_sha256) ||
      !identical(a4_s4_tree_r_own_optimum_sha(frozen$dll_path, "loaded gllvmTMB DLL"), frozen$dll_sha256) ||
      !identical(a4_s4_tree_r_own_optimum_runtime(), frozen$runtime))
    a4_s4_tree_r_own_optimum_stop("frozen R package, DLL, or runtime changed during own optimum fit")
  invisible(frozen)
}

a4_s4_tree_r_own_optimum_decode_matrix <- function(x, label) {
  rows <- lapply(x, function(row) as.numeric(unlist(row, recursive = TRUE, use.names = FALSE)))
  if (!is.list(x) || !length(rows) || any(lengths(rows) != length(rows[[1L]])) ||
      any(!is.finite(unlist(rows, use.names = FALSE))))
    a4_s4_tree_r_own_optimum_stop(sprintf("%s must be a finite rectangular matrix", label))
  matrix(unlist(rows, use.names = FALSE), nrow = length(rows), byrow = TRUE)
}
a4_s4_tree_r_own_optimum_response_hash <- function(Y) {
  if (!requireNamespace("digest", quietly = TRUE))
    a4_s4_tree_r_own_optimum_stop("digest is required for response provenance")
  digest::digest(writeBin(as.double(c(Y)), raw(), size = 8L, endian = "little"),
    algo = "sha256", serialize = FALSE)
}
a4_s4_tree_r_own_optimum_inputs <- function(core070, request) {
  a4_s4_tree_r_own_optimum_validate_request(request)
  if (!requireNamespace("jsonlite", quietly = TRUE))
    a4_s4_tree_r_own_optimum_stop("jsonlite is required for tree fixture decoding")
  core070 <- normalizePath(core070, mustWork = TRUE)
  fixture_path <- file.path(core070, "destination-b-adapter", "fixtures-01.json")
  reference_path <- file.path(core070, "destination-b-tree", "r-bfgs-attempt-01.json")
  precision_path <- file.path(core070, "destination-b-tree", "precision-reference.json")
  if (!identical(a4_s4_tree_r_own_optimum_sha(fixture_path, "tree fixture"), request$hashes$fixture) ||
      !identical(a4_s4_tree_r_own_optimum_sha(reference_path, "tree reference"), request$hashes$reference) ||
      !identical(a4_s4_tree_r_own_optimum_sha(precision_path, "tree precision reference"), request$hashes$precision))
    a4_s4_tree_r_own_optimum_stop("tree fixture/reference/precision bytes differ from the frozen contract")
  fixture <- jsonlite::fromJSON(fixture_path, simplifyVector = FALSE)$bundles$tree
  reference <- jsonlite::fromJSON(reference_path, simplifyVector = FALSE)
  precision <- jsonlite::fromJSON(precision_path, simplifyVector = FALSE)
  Y <- a4_s4_tree_r_own_optimum_decode_matrix(reference$Y_traits_by_observations, "tree response")
  if (!identical(dim(Y), c(3L, 16L)) ||
      !identical(a4_s4_tree_r_own_optimum_response_hash(Y), request$hashes$response) ||
      !identical(as.character(reference$source_pin), request$source_pin) ||
      !identical(as.character(reference$package_version), request$package_version) ||
      !identical(as.character(reference$data_sha256), request$hashes$response) ||
      !identical(as.character(precision$source_pin), request$source_pin) ||
      !identical(as.integer(unlist(fixture$species_id)), request$map$species_id_one_based) ||
      !identical(as.integer(unlist(fixture$precision$species_aug_id)), request$map$species_aug_id_zero_based) ||
      !identical(as.integer(unlist(fixture$precision$n_aug)), request$map$n_augmented) ||
      !isTRUE(all.equal(as.numeric(unlist(fixture$precision$scale)), request$precision$scale, tolerance = 0)) ||
      !isTRUE(all.equal(as.numeric(unlist(fixture$precision$log_det)), request$precision$log_det_Q, tolerance = 1e-14)) ||
      !identical(precision$ridge_applied, FALSE))
    a4_s4_tree_r_own_optimum_stop("tree response, map, scale, log determinant, or no-ridge fact differs")
  list(Y = Y, tree = ape::read.tree(text = precision$newick),
    expected_Q = a4_s4_tree_r_own_optimum_decode_matrix(precision$Q_canonical, "canonical tree Q"),
    trait_names = as.character(reference$trait_names),
    species_labels = as.character(precision$observed_labels))
}

a4_s4_tree_r_own_optimum_long_data <- function(inputs) {
  data <- expand.grid(replicate = seq_len(2L), trait_id = seq_len(3L), species_id = seq_len(8L),
    KEEP.OUT.ATTRS = FALSE)
  observation <- (data$species_id - 1L) * 2L + data$replicate
  data$value <- inputs$Y[cbind(data$trait_id, observation)]
  data$trait <- factor(inputs$trait_names[data$trait_id], levels = inputs$trait_names)
  data$species <- factor(inputs$species_labels[data$species_id], levels = inputs$species_labels)
  data
}
a4_s4_tree_r_own_optimum_theta_names <- function() {
  c(rep("b_fix", 3L), "log_sigma_eps", rep("theta_rr_phy", 3L))
}
a4_s4_tree_r_own_optimum_tmb_canonical_data <- function(data) {
  if (!is.list(data)) a4_s4_tree_r_own_optimum_stop("checked TMB data are not a list")
  sanitize <- function(value) {
    if (is.list(value)) return(lapply(value, sanitize))
    if (methods::is(value, "sparseMatrix")) return(methods::as(methods::as(value, "TsparseMatrix"), "generalMatrix"))
    if (is.character(value)) return(value)
    if (is.factor(value)) value <- unclass(value) - 1L
    storage.mode(value) <- "double"; value
  }
  if (!isTRUE(attr(data, "check.passed"))) data <- lapply(data, sanitize)
  attr(data, "check.passed") <- TRUE
  data
}
a4_s4_tree_r_own_optimum_assert_marginal_binding <- function(obj, tmb, request) {
  if (is.null(obj) || !is.function(obj$fn) || !is.environment(obj$env) ||
      !is.list(obj$env$data) || !is.list(obj$env$parameters) ||
      !identical(environment(obj$fn), obj$env) ||
      !identical(obj$env$data, a4_s4_tree_r_own_optimum_tmb_canonical_data(tmb)) ||
      !identical(as.character(obj$env$DLL), "gllvmTMB"))
    a4_s4_tree_r_own_optimum_stop("fit TMB marginal objective is not bound to checked frozen inputs")
  blocks <- rep(names(obj$env$parameters), lengths(obj$env$parameters))
  expected_random <- which(blocks == "g_phy")
  if (is.null(obj$env$parameters$g_phy) || length(obj$env$parameters$g_phy) != request$map$n_augmented ||
      is.null(obj$env$random) || !identical(as.integer(obj$env$random), as.integer(expected_random)))
    a4_s4_tree_r_own_optimum_stop("TMB fit did not integrate the required g_phy random block")
  invisible(obj)
}
a4_s4_tree_r_own_optimum_assert_fit_binding <- function(fit, inputs, request, data) {
  obj <- fit$tmb_obj; tmb <- fit$tmb_data
  required <- c("Ainv_phy_rr", "log_det_A_phy_rr", "n_aug_phy", "species_id", "species_aug_id",
    "trait_id", "y", "X_fix")
  if (is.null(obj) || !is.list(tmb) || !all(required %in% names(tmb)) ||
      !identical(names(obj$par), a4_s4_tree_r_own_optimum_theta_names()) ||
      !identical(names(fit$opt$par), a4_s4_tree_r_own_optimum_theta_names()))
    a4_s4_tree_r_own_optimum_stop("fit has no exact seven-coordinate marginal TMB contract")
  a4_s4_tree_r_own_optimum_assert_marginal_binding(obj, tmb, request)
  Q <- as.matrix(tmb$Ainv_phy_rr)
  if (!identical(dim(Q), dim(inputs$expected_Q)) || max(abs(Q - inputs$expected_Q)) > 1e-12 ||
      !identical(as.integer(tmb$n_aug_phy), request$map$n_augmented) ||
      !isTRUE(all.equal(-as.numeric(tmb$log_det_A_phy_rr), request$precision$log_det_Q, tolerance = 1e-12)))
    a4_s4_tree_r_own_optimum_stop("TMB canonical Q, log determinant, or augmented size differs")
  sid <- as.integer(tmb$species_id); aug <- as.integer(tmb$species_aug_id)
  tid <- as.integer(tmb$trait_id); y <- as.numeric(tmb$y)
  if (length(sid) != nrow(data) || length(aug) != nrow(data) || length(tid) != nrow(data) ||
      length(y) != nrow(data) || any(sid < 0L | sid >= 8L) || any(tid < 0L | tid >= 3L) ||
      !identical(aug, as.integer(request$map$species_aug_id_zero_based[sid + 1L])))
    a4_s4_tree_r_own_optimum_stop("TMB species, augmented-node, or trait map differs")
  candidates <- vapply(seq_along(y), function(i) {
    hit <- which(data$species_id - 1L == sid[[i]] & data$trait_id - 1L == tid[[i]] &
      abs(data$value - y[[i]]) <= 16 * .Machine$double.eps * max(1, abs(y[[i]])))
    if (length(hit) == 1L) as.integer(hit) else NA_integer_
  }, integer(1L))
  expected_X <- stats::model.matrix(~ 0 + trait, data = data)[candidates, , drop = FALSE]
  if (anyNA(candidates) || !identical(sort(candidates), seq_len(nrow(data))) ||
      !identical(dim(as.matrix(tmb$X_fix)), dim(expected_X)) || any(as.matrix(tmb$X_fix) != expected_X))
    a4_s4_tree_r_own_optimum_stop("TMB response rows or fixed design differs from frozen data")
  invisible(obj)
}
a4_s4_tree_r_own_optimum_assert_no_sdreport <- function(fit) {
  if (!is.null(fit$sd_report))
    a4_s4_tree_r_own_optimum_stop("own-optimum fit must be constructed with se = FALSE")
  invisible(fit)
}
a4_s4_tree_r_own_optimum_diagnostics <- function(fit) {
  obj <- fit$tmb_obj
  theta <- fit$opt$par
  expected_names <- a4_s4_tree_r_own_optimum_theta_names()
  if (is.null(obj) || !is.function(obj$fn) || !is.function(obj$gr) || !is.numeric(theta) ||
      !identical(names(theta), expected_names) || length(theta) != 7L ||
      !identical(as.integer(fit$opt$convergence), 0L))
    a4_s4_tree_r_own_optimum_stop("own fit has no auditable marginal objective and gradient")
  gradient <- obj$gr(theta)
  hessian <- optimHess(theta, obj$fn, obj$gr)
  eigenvalues <- eigen((hessian + t(hessian)) / 2, symmetric = TRUE, only.values = TRUE)$values
  direct_objective <- as.numeric(obj$fn(theta))
  reported_objective <- as.numeric(fit$opt$objective)
  l2_norm <- sqrt(sum(gradient^2)); infinity_norm <- max(abs(gradient))
  if (length(reported_objective) != 1L || length(direct_objective) != 1L ||
      any(!is.finite(c(theta, gradient, hessian, eigenvalues, direct_objective, reported_objective))) ||
      !isTRUE(all.equal(reported_objective, direct_objective, tolerance = 1e-10)) ||
      infinity_norm > 1e-5 || min(eigenvalues) <= 0)
    a4_s4_tree_r_own_optimum_stop("own-optimum diagnostics are non-finite")
  list(reported_objective = reported_objective, direct_objective = direct_objective, optimizer = list(
    convergence = fit$opt$convergence, message = fit$opt$message,
    iterations = fit$opt$iterations, par = theta),
    gradient = list(values = as.numeric(gradient), l2_norm = l2_norm, infinity_norm = infinity_norm),
    curvature = list(hessian = unname(hessian), min_eigenvalue = min(eigenvalues),
      max_eigenvalue = max(eigenvalues), positive_definite = min(eigenvalues) > 0))
}
a4_s4_tree_r_own_optimum_validate_record <- function(record, request) {
  a4_s4_tree_r_own_optimum_validate_request(request)
  expected <- c("schema_version", "status", "request", "frozen", "fit", "qualified",
    "public_formula_admission", "intervals", "paired_comparison")
  a4_s4_tree_r_own_optimum_exact_names(record, expected, "tree own-optimum receipt")
  fit_names <- c("reported_objective", "direct_objective", "optimizer", "gradient", "curvature")
  frozen_names <- c("package_version", "package_path", "dll_path", "dll_sha256", "source_pin",
    "archive_sha256", "namespace_sha256", "source_tree_sha256", "installed_tree_sha256",
    "marker_path", "marker_sha256", "oracle_build_root", "oracle_build_receipt_path",
    "oracle_build_receipt_sha256", "oracle_source_path", "oracle_install_log_sha256",
    "runtime", "source_provenance")
  if (!identical(record$schema_version, a4_s4_tree_r_own_optimum_schema) ||
      !identical(record$status, "r_tree_own_optimum_recorded_unqualified") ||
      !identical(record$request, request) || !identical(record$qualified, FALSE) ||
      !identical(record$public_formula_admission, "closed") ||
      !identical(record$intervals, "not_computed") ||
      !identical(record$paired_comparison, "not_computed") || !is.list(record$frozen) ||
      !identical(names(record$frozen), frozen_names) ||
      !identical(record$frozen$package_version, request$package_version) ||
      !identical(record$frozen$source_pin, request$source_pin) ||
      !identical(record$frozen$archive_sha256, a4_s4_tree_r_own_optimum_archive_sha256) ||
      !identical(record$frozen$namespace_sha256, a4_s4_tree_r_own_optimum_namespace_sha256) ||
      !identical(record$frozen$source_tree_sha256, a4_s4_tree_r_own_optimum_source_tree_sha256) ||
      !identical(record$frozen$dll_sha256, a4_s4_tree_r_own_optimum_dll_sha256) ||
      !identical(record$frozen$installed_tree_sha256, a4_s4_tree_r_own_optimum_installed_tree_sha256) ||
      !identical(record$frozen$marker_sha256, a4_s4_tree_r_own_optimum_marker_sha256) ||
      !identical(record$frozen$oracle_build_receipt_sha256, request$build_receipt_sha256) ||
      !identical(record$frozen$oracle_install_log_sha256, a4_s4_tree_r_own_optimum_install_log_sha256) ||
      !identical(record$frozen$source_provenance, "verified_installed_marker") ||
      !all(grepl("^[0-9a-f]{64}$", c(record$frozen$dll_sha256, record$frozen$installed_tree_sha256,
        record$frozen$marker_sha256, record$frozen$oracle_build_receipt_sha256,
        record$frozen$oracle_install_log_sha256))) ||
      !identical(dirname(record$frozen$marker_path), record$frozen$package_path) ||
      !identical(record$frozen$dll_path, file.path(record$frozen$package_path, "libs",
        paste0("gllvmTMB", .Platform$dynlib.ext))) ||
      !identical(record$frozen$package_path, file.path(record$frozen$oracle_build_root, "library", "gllvmTMB")) ||
      !identical(record$frozen$oracle_build_receipt_path, file.path(record$frozen$oracle_build_root, "build.json")) ||
      !identical(record$frozen$oracle_source_path, file.path(record$frozen$oracle_build_root, "source")) ||
      !is.list(record$frozen$runtime) || !identical(names(record$frozen$runtime), c("r_version", "packages")) ||
      !is.character(record$frozen$runtime$r_version) || length(record$frozen$runtime$r_version) != 1L ||
      !is.list(record$frozen$runtime$packages) ||
      !identical(names(record$frozen$runtime$packages), c("TMB", "Matrix", "ape")) ||
      !all(vapply(record$frozen$runtime$packages, function(x) is.list(x) &&
        identical(names(x), c("version", "path", "description_sha256")) &&
        is.character(x$version) && length(x$version) == 1L && is.character(x$path) && length(x$path) == 1L &&
        is.character(x$description_sha256) && length(x$description_sha256) == 1L &&
        grepl("^[0-9a-f]{64}$", x$description_sha256), logical(1L))) ||
      !is.list(record$fit) ||
      !identical(names(record$fit), fit_names) || !is.finite(record$fit$reported_objective) ||
      !is.finite(record$fit$direct_objective) ||
      !isTRUE(all.equal(record$fit$reported_objective, record$fit$direct_objective, tolerance = 1e-10)) ||
      !is.list(record$fit$optimizer) || !identical(as.integer(record$fit$optimizer$convergence), 0L) ||
      !is.numeric(record$fit$optimizer$par) || length(record$fit$optimizer$par) != 7L ||
      !identical(names(record$fit$optimizer$par), a4_s4_tree_r_own_optimum_theta_names()) ||
      !is.numeric(record$fit$gradient$values) || length(record$fit$gradient$values) != 7L ||
      !all(is.finite(record$fit$gradient$values)) ||
      !is.finite(record$fit$gradient$l2_norm) || !is.finite(record$fit$gradient$infinity_norm) ||
      record$fit$gradient$infinity_norm > 1e-5 ||
      !is.matrix(record$fit$curvature$hessian) || !identical(dim(record$fit$curvature$hessian), c(7L, 7L)) ||
      any(!is.finite(record$fit$curvature$hessian)) ||
      !is.finite(record$fit$curvature$min_eigenvalue) || !is.finite(record$fit$curvature$max_eigenvalue) ||
      !is.logical(record$fit$curvature$positive_definite) || length(record$fit$curvature$positive_definite) != 1L ||
      !isTRUE(record$fit$curvature$positive_definite) || record$fit$curvature$min_eigenvalue <= 0)
    a4_s4_tree_r_own_optimum_stop("tree own-optimum receipt is incomplete, non-finite, or outside scope")
  record
}
a4_s4_tree_r_own_optimum_probe_diagnostics <- function(fit, elapsed_seconds) {
  obj <- fit$tmb_obj; theta <- fit$opt$par; gradient <- obj$gr(theta)
  reported <- as.numeric(fit$opt$objective); direct <- as.numeric(obj$fn(theta))
  if (!is.numeric(theta) || !identical(names(theta), a4_s4_tree_r_own_optimum_theta_names()) ||
      any(!is.finite(c(theta, gradient, reported, direct))) || !is.finite(elapsed_seconds))
    a4_s4_tree_r_own_optimum_stop("five-iteration probe has no finite own-fit diagnostics")
  list(status = if (identical(as.integer(fit$opt$convergence), 0L)) "converged_within_probe_budget" else "nonconverged_probe",
    elapsed_seconds = elapsed_seconds, reported_objective = reported, direct_objective = direct,
    optimizer_convergence = as.integer(fit$opt$convergence), optimizer_par = theta,
    gradient = list(values = as.numeric(gradient), l2_norm = sqrt(sum(gradient^2)),
      infinity_norm = max(abs(gradient))))
}
a4_s4_tree_r_own_optimum_validate_probe_record <- function(record, request) {
  a4_s4_tree_r_own_optimum_validate_request(request)
  expected <- c("schema_version", "status", "request", "frozen", "probe", "qualified",
    "public_formula_admission", "intervals", "paired_comparison", "finality")
  a4_s4_tree_r_own_optimum_exact_names(record, expected, "five-iteration probe receipt")
  if (!identical(record$schema_version, a4_s4_tree_r_own_optimum_schema) ||
      !identical(record$status, "r_tree_five_iteration_probe_unqualified") || !identical(record$request, request) ||
      !identical(record$qualified, FALSE) || !identical(record$public_formula_admission, "closed") ||
      !identical(record$intervals, "not_computed") || !identical(record$paired_comparison, "not_computed") ||
      !identical(record$finality, "non_final_probe") || !is.list(record$frozen) ||
      !identical(record$frozen$source_pin, a4_s4_tree_r_own_optimum_pin) ||
      !identical(record$frozen$dll_sha256, a4_s4_tree_r_own_optimum_dll_sha256) ||
      !identical(record$frozen$installed_tree_sha256, a4_s4_tree_r_own_optimum_installed_tree_sha256) ||
      !identical(record$frozen$marker_sha256, a4_s4_tree_r_own_optimum_marker_sha256) ||
      !identical(record$frozen$oracle_build_receipt_sha256, request$build_receipt_sha256) ||
      !identical(record$frozen$oracle_install_log_sha256, a4_s4_tree_r_own_optimum_install_log_sha256) ||
      !identical(record$frozen$source_provenance, "verified_installed_marker") || !is.list(record$probe) ||
      !identical(names(record$probe), c("status", "elapsed_seconds", "reported_objective", "direct_objective",
        "optimizer_convergence", "optimizer_par", "gradient")) || !is.finite(record$probe$elapsed_seconds) ||
      !is.finite(record$probe$reported_objective) || !is.finite(record$probe$direct_objective) ||
      !is.numeric(record$probe$optimizer_convergence) || length(record$probe$optimizer_convergence) != 1L ||
      !is.numeric(record$probe$optimizer_par) || length(record$probe$optimizer_par) != 7L ||
      !identical(names(record$probe$optimizer_par), a4_s4_tree_r_own_optimum_theta_names()) ||
      !is.numeric(record$probe$gradient$values) || length(record$probe$gradient$values) != 7L ||
      any(!is.finite(record$probe$gradient$values)) || !is.finite(record$probe$gradient$l2_norm) ||
      !is.finite(record$probe$gradient$infinity_norm))
    a4_s4_tree_r_own_optimum_stop("five-iteration probe receipt is incomplete or exceeds its non-final scope")
  record
}
a4_s4_tree_r_own_optimum_fit <- function(inputs, data, control) {
  gllvmTMB::gllvmTMB(value ~ 0 + trait + phylo_latent(species, d = 1, tree = inputs$tree,
    unique = FALSE), data = data, trait = "trait", unit = "species", cluster = "species",
    family = gaussian(), REML = FALSE, engine = "tmb", control = control)
}
a4_s4_tree_r_own_optimum_run <- function(frozen_library, core070, output, expected_build_sha256) {
  output <- a4_s4_tree_r_own_optimum_output_fence(output)
  request <- a4_s4_tree_r_own_optimum_request(expected_build_sha256)
  if (!requireNamespace("ape", quietly = TRUE)) a4_s4_tree_r_own_optimum_stop("ape is required")
  frozen <- a4_s4_tree_r_own_optimum_frozen_package(frozen_library, expected_build_sha256)
  inputs <- a4_s4_tree_r_own_optimum_inputs(core070, request)
  data <- a4_s4_tree_r_own_optimum_long_data(inputs)
  # Native data-derived initialization is used; no external or cross-engine coordinate is admitted.
  fit <- a4_s4_tree_r_own_optimum_fit(inputs, data,
    control = gllvmTMBcontrol(n_init = 1L, optimizer = "nlminb", se = FALSE,
      optArgs = list(control = list(iter.max = 80L, eval.max = 120L, rel.tol = 1e-12))))
  a4_s4_tree_r_own_optimum_assert_no_sdreport(fit)
  a4_s4_tree_r_own_optimum_assert_fit_binding(fit, inputs, request, data)
  record <- list(schema_version = a4_s4_tree_r_own_optimum_schema,
    status = "r_tree_own_optimum_recorded_unqualified", request = request, frozen = frozen,
    fit = a4_s4_tree_r_own_optimum_diagnostics(fit), qualified = FALSE,
    public_formula_admission = "closed", intervals = "not_computed",
    paired_comparison = "not_computed")
  a4_s4_tree_r_own_optimum_validate_record(record, request)
  a4_s4_tree_r_own_optimum_assert_frozen_unchanged(frozen)
  a4_s4_tree_r_own_optimum_publish(record, output)
}
a4_s4_tree_r_own_optimum_probe_run <- function(frozen_library, core070, output, expected_build_sha256) {
  output <- a4_s4_tree_r_own_optimum_output_fence(output)
  request <- a4_s4_tree_r_own_optimum_request(expected_build_sha256)
  if (!requireNamespace("ape", quietly = TRUE)) a4_s4_tree_r_own_optimum_stop("ape is required")
  frozen <- a4_s4_tree_r_own_optimum_frozen_package(frozen_library, expected_build_sha256)
  inputs <- a4_s4_tree_r_own_optimum_inputs(core070, request); data <- a4_s4_tree_r_own_optimum_long_data(inputs)
  started <- proc.time()[["elapsed"]]
  fit <- a4_s4_tree_r_own_optimum_fit(inputs, data,
    control = gllvmTMBcontrol(n_init = 1L, optimizer = "nlminb", se = FALSE,
      optArgs = list(control = list(iter.max = 5L, eval.max = 10L, rel.tol = 1e-12))))
  elapsed <- proc.time()[["elapsed"]] - started
  a4_s4_tree_r_own_optimum_assert_no_sdreport(fit)
  a4_s4_tree_r_own_optimum_assert_fit_binding(fit, inputs, request, data)
  record <- list(schema_version = a4_s4_tree_r_own_optimum_schema,
    status = "r_tree_five_iteration_probe_unqualified", request = request, frozen = frozen,
    probe = a4_s4_tree_r_own_optimum_probe_diagnostics(fit, elapsed), qualified = FALSE,
    public_formula_admission = "closed", intervals = "not_computed", paired_comparison = "not_computed",
    finality = "non_final_probe")
  a4_s4_tree_r_own_optimum_validate_probe_record(record, request)
  a4_s4_tree_r_own_optimum_assert_frozen_unchanged(frozen)
  a4_s4_tree_r_own_optimum_publish(record, output)
}
a4_s4_tree_r_own_optimum_cli <- function(args) {
  if (length(args) == 5L && identical(args[[1L]], "--probe"))
    return(a4_s4_tree_r_own_optimum_probe_run(args[[2L]], args[[3L]], args[[4L]], args[[5L]]))
  if (length(args) != 4L) a4_s4_tree_r_own_optimum_stop(paste(
    "usage: Rscript --vanilla run_a4_s4_tree_r_own_optimum.R",
    "<frozen-library> <core070-dir> <output-rds> <expected-build-receipt-sha256>"))
  a4_s4_tree_r_own_optimum_run(args[[1L]], args[[2L]], args[[3L]], args[[4L]])
}
if (sys.nframe() == 0L) a4_s4_tree_r_own_optimum_cli(commandArgs(trailingOnly = TRUE))
