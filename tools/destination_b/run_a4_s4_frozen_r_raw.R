#!/usr/bin/env Rscript
# Private, same-process frozen-R raw marginal-objective runner.
#
# Usage:
#   Rscript --vanilla run_a4_s4_frozen_r_raw.R \
#     <frozen-library> <core070-dir> <output-rds> <theta-csv> \
#     <expected-build-receipt-sha256>
#
# It is deliberately not a paired-evidence runner: it has no Julia call, no
# delta, no own-optimum comparison, no interval work, and no admission claim.
# The frozen public constructor necessarily optimizes while constructing its
# marginal object; that fact is retained explicitly as construction metadata.

a4_s4_frozen_r_raw_schema_version <- "destination-b-a4-s4-frozen-r-raw-4"
a4_s4_frozen_r_raw_archive_sha256 <- "0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc"
a4_s4_frozen_r_raw_namespace_sha256 <- "9094613610789faab69c43195d3cfdafb2c7dfef284e6646b10dababa4fa132c"
a4_s4_frozen_r_raw_source_tree_sha256 <- "f83545faa6543dbb1f64d64bbf5a9498adcdf036cc3da5851f269912698b1cc7"
a4_s4_frozen_r_raw_marker_name <- "CORE070_SOURCE_PIN.toml"

a4_s4_frozen_r_raw_stop <- function(message) stop(message, call. = FALSE)

a4_s4_frozen_r_raw_parse_theta <- function(value) {
  if (!is.character(value) || length(value) != 1L || !nzchar(value)) {
    a4_s4_frozen_r_raw_stop("theta-csv must be one nonempty comma-separated value")
  }
  pieces <- strsplit(value, ",", fixed = TRUE)[[1L]]
  theta <- suppressWarnings(as.numeric(pieces))
  names(theta) <- a4_s4_frozen_r_theta_names()
  a4_s4_frozen_r_validate_theta(theta)
  theta
}

a4_s4_frozen_r_raw_parse_sha256 <- function(value, label) {
  if (!is.character(value) || length(value) != 1L ||
      !grepl("^[0-9a-f]{64}$", value)) {
    a4_s4_frozen_r_raw_stop(sprintf("%s must be one lowercase SHA-256 digest", label))
  }
  value
}

a4_s4_frozen_r_raw_parse_cli <- function(args) {
  if (length(args) != 5L) {
    a4_s4_frozen_r_raw_stop(paste(
      "usage: Rscript --vanilla run_a4_s4_frozen_r_raw.R",
      "<frozen-library> <core070-dir> <output-rds> <theta-csv>",
      "<expected-build-receipt-sha256>"
    ))
  }
  list(frozen_library = args[[1L]], core070 = args[[2L]], output = args[[3L]],
    theta = a4_s4_frozen_r_raw_parse_theta(args[[4L]]),
    expected_build_receipt_sha256 = a4_s4_frozen_r_raw_parse_sha256(args[[5L]],
      "expected-build-receipt-sha256"))
}

a4_s4_frozen_r_raw_output_fence <- function(path) {
  if (!is.character(path) || length(path) != 1L || !nzchar(path)) {
    a4_s4_frozen_r_raw_stop("output-rds must be one nonempty path")
  }
  if (a4_s4_frozen_r_raw_output_exists(path)) {
    a4_s4_frozen_r_raw_stop("refusing to overwrite a frozen-R raw receipt")
  }
  parent <- dirname(path)
  if (!dir.exists(parent)) {
    a4_s4_frozen_r_raw_stop("output-rds parent directory does not exist")
  }
  invisible(normalizePath(path, mustWork = FALSE))
}

# `file.exists()` deliberately returns FALSE for a dangling symlink.  That is
# not an available receipt pathname: treating it as one would let a later
# writer redirect the result through an existing filesystem entry.
a4_s4_frozen_r_raw_output_exists <- function(path) {
  link_target <- Sys.readlink(path)
  isTRUE(file.exists(path)) ||
    (length(link_target) == 1L && !is.na(link_target) && nzchar(link_target))
}

a4_s4_frozen_r_raw_is_symlink <- function(path) {
  target <- Sys.readlink(path)
  length(target) == 1L && !is.na(target) && nzchar(target)
}

a4_s4_frozen_r_raw_regular_file <- function(path, label) {
  if (!is.character(path) || length(path) != 1L || !nzchar(path) ||
      !file.exists(path) || !isTRUE(file_test("-f", path)) ||
      a4_s4_frozen_r_raw_is_symlink(path)) {
    a4_s4_frozen_r_raw_stop(sprintf("%s must be a regular non-symlink file", label))
  }
  normalizePath(path, mustWork = TRUE)
}

a4_s4_frozen_r_raw_acquire_lock <- function(path) {
  lock <- paste0(path, ".lock")
  if (!dir.create(lock, showWarnings = FALSE)) {
    a4_s4_frozen_r_raw_stop("refusing to race another frozen-R raw receipt writer")
  }
  if (a4_s4_frozen_r_raw_output_exists(path)) {
    unlink(lock, recursive = TRUE, force = TRUE)
    a4_s4_frozen_r_raw_stop("refusing to overwrite a frozen-R raw receipt")
  }
  lock
}

a4_s4_frozen_r_raw_release_lock <- function(lock) {
  if (!is.null(lock) && dir.exists(lock)) unlink(lock, recursive = TRUE, force = TRUE)
  invisible(NULL)
}

# Publish through a hard link, not a replacement rename: POSIX link creation fails
# atomically if another writer creates `output` after the cooperative lock was
# acquired.  The temporary is deliberately in the output directory so the
# link remains on one filesystem.  A platform without this no-clobber
# primitive fails closed rather than falling back to a replace operation.
a4_s4_frozen_r_raw_publish <- function(receipt, output, unlink_file = unlink) {
  temporary <- tempfile(pattern = ".raw-frozen-r-", tmpdir = dirname(output))
  on.exit(if (file.exists(temporary)) unlink(temporary, force = TRUE), add = TRUE)
  saveRDS(receipt, temporary)
  if (a4_s4_frozen_r_raw_output_exists(output) ||
      !isTRUE(file.link(temporary, output)) ||
      !file.exists(output)) {
    a4_s4_frozen_r_raw_stop("frozen-R raw receipt could not be written without overwrite")
  }
  # Publication committed at `file.link()`.  Cleanup cannot turn a valid
  # immutable receipt into a failed run: the on-exit cleanup retries with the
  # base unlink if an injected or transient first cleanup attempt fails.
  unlink_file(temporary, force = TRUE)
  invisible(output)
}

a4_s4_frozen_r_raw_within <- function(path, root) {
  path <- normalizePath(path, mustWork = TRUE)
  root <- normalizePath(root, mustWork = TRUE)
  identical(path, root) || startsWith(path, paste0(root, .Platform$file.sep))
}

a4_s4_frozen_r_raw_sha256_file <- function(path, label) {
  if (!file.exists(path) || dir.exists(path)) {
    a4_s4_frozen_r_raw_stop(sprintf("%s is not a readable file", label))
  }
  value <- unname(tools::sha256sum(path))[[1L]]
  if (!is.character(value) || !grepl("^[0-9a-f]{64}$", value)) {
    a4_s4_frozen_r_raw_stop(sprintf("%s does not have a SHA-256 digest", label))
  }
  value
}

# This intentionally mirrors `tools/core070_build_oracle.py`: it hashes the
# sorted `relative-path NUL file-sha256` records, excludes only the marker, and
# rejects symlinks rather than following a different tree than the build did.
a4_s4_frozen_r_raw_tree_sha256 <- function(root, exclude = character()) {
  root <- normalizePath(root, mustWork = TRUE)
  entries <- list.files(root, recursive = TRUE, all.files = TRUE,
    include.dirs = TRUE, full.names = TRUE, no.. = TRUE)
  if (!length(entries)) {
    a4_s4_frozen_r_raw_stop("installed package tree is unexpectedly empty")
  }
  relative <- substring(entries, nchar(root) + 2L)
  if (any(nzchar(Sys.readlink(entries)))) {
    a4_s4_frozen_r_raw_stop("symlink is not admitted in the installed frozen-R tree")
  }
  info <- file.info(entries)
  is_dir <- !is.na(info$isdir) & as.logical(info$isdir)
  files <- entries[!is_dir]
  relative <- relative[!is_dir]
  keep <- !(relative %in% exclude)
  files <- files[keep]
  relative <- relative[keep]
  if (!length(files) || anyDuplicated(relative)) {
    a4_s4_frozen_r_raw_stop("installed package tree has no unique file manifest")
  }
  file_sha <- vapply(seq_along(files), function(i) {
    a4_s4_frozen_r_raw_sha256_file(files[[i]], relative[[i]])
  }, character(1L))
  order <- order(relative, method = "radix")
  records <- lapply(order, function(i) {
    c(charToRaw(relative[[i]]), as.raw(0L), charToRaw(file_sha[[i]]))
  })
  payload <- raw()
  for (i in seq_along(records)) {
    payload <- c(payload, records[[i]])
    if (i < length(records)) payload <- c(payload, as.raw(10L))
  }
  digest::digest(payload, algo = "sha256", serialize = FALSE)
}

a4_s4_frozen_r_raw_marker_fields <- function() {
  c("reference_commit", "archive_sha256", "namespace_sha256",
    "source_tree_sha256", "installed_tree_sha256")
}

a4_s4_frozen_r_raw_marker_values <- function(path) {
  if (!file.exists(path) || dir.exists(path)) {
    a4_s4_frozen_r_raw_stop("installed CORE070_SOURCE_PIN.toml is required")
  }
  lines <- readLines(path, warn = FALSE)
  fields <- a4_s4_frozen_r_raw_marker_fields()
  values <- vapply(fields, function(field) {
    pattern <- paste0("^", field, "[[:space:]]*=[[:space:]]*\\\"([0-9a-f]{40}|[0-9a-f]{64})\\\"[[:space:]]*$")
    matches <- grep(pattern, lines, value = TRUE)
    if (length(matches) != 1L) {
      a4_s4_frozen_r_raw_stop(sprintf("installed source marker has no unique %s field", field))
    }
    sub(pattern, "\\1", matches[[1L]])
  }, character(1L))
  names(values) <- fields
  values
}

a4_s4_frozen_r_raw_oracle_expected <- function() {
  list(reference_commit = a4_s4_frozen_r_source_pin,
    archive_sha256 = a4_s4_frozen_r_raw_archive_sha256,
    namespace_sha256 = a4_s4_frozen_r_raw_namespace_sha256,
    source_tree_sha256 = a4_s4_frozen_r_raw_source_tree_sha256)
}

a4_s4_frozen_r_raw_validate_marker <- function(package_path, expected) {
  package_path <- normalizePath(package_path, mustWork = TRUE)
  marker_path <- file.path(package_path, a4_s4_frozen_r_raw_marker_name)
  marker <- a4_s4_frozen_r_raw_marker_values(marker_path)
  required <- a4_s4_frozen_r_raw_marker_fields()
  if (!is.list(expected) || !identical(names(expected), required) ||
      !identical(unname(marker[required]), unname(vapply(required,
        function(field) expected[[field]], character(1L))))) {
    a4_s4_frozen_r_raw_stop("installed source marker differs from the frozen CORE-070 contract")
  }
  namespace_path <- file.path(package_path, "NAMESPACE")
  namespace_sha256 <- a4_s4_frozen_r_raw_sha256_file(namespace_path, "installed NAMESPACE")
  if (!identical(namespace_sha256, expected$namespace_sha256)) {
    a4_s4_frozen_r_raw_stop("installed gllvmTMB NAMESPACE differs from frozen source")
  }
  installed_tree_sha256 <- a4_s4_frozen_r_raw_tree_sha256(package_path,
    exclude = a4_s4_frozen_r_raw_marker_name)
  if (!identical(marker[["installed_tree_sha256"]], installed_tree_sha256)) {
    a4_s4_frozen_r_raw_stop("installed gllvmTMB tree differs from its source marker")
  }
  list(source_pin = marker[["reference_commit"]], archive_sha256 = marker[["archive_sha256"]],
    namespace_sha256 = namespace_sha256, source_tree_sha256 = marker[["source_tree_sha256"]],
    installed_tree_sha256 = installed_tree_sha256, marker_path = marker_path,
    marker_sha256 = a4_s4_frozen_r_raw_sha256_file(marker_path, "installed source marker"),
    source_provenance = "verified_installed_marker")
}

a4_s4_frozen_r_raw_validate_oracle_build <- function(frozen_library,
                                                       expected_build_receipt_sha256,
                                                       expected = a4_s4_frozen_r_raw_oracle_expected()) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    a4_s4_frozen_r_raw_stop("jsonlite is required to verify the frozen oracle build receipt")
  }
  frozen_library <- normalizePath(frozen_library, mustWork = TRUE)
  if (!identical(basename(frozen_library), "library")) {
    a4_s4_frozen_r_raw_stop("frozen-library must be the library directory of an oracle build")
  }
  expected_fields <- c("reference_commit", "archive_sha256", "namespace_sha256", "source_tree_sha256")
  receipt_fields <- c("reference_commit", "archive_sha256", "source_tree_sha256")
  if (!is.list(expected) || !identical(names(expected), expected_fields)) {
    a4_s4_frozen_r_raw_stop("frozen oracle expectation has an invalid field set")
  }
  expected_build_receipt_sha256 <- a4_s4_frozen_r_raw_parse_sha256(
    expected_build_receipt_sha256, "expected-build-receipt-sha256")
  build_root <- dirname(frozen_library)
  receipt_path <- file.path(build_root, "build.json")
  source_path <- file.path(build_root, "source")
  install_log_path <- file.path(build_root, "install.log")
  receipt_sha256 <- a4_s4_frozen_r_raw_sha256_file(receipt_path, "oracle build receipt")
  if (!identical(receipt_sha256, expected_build_receipt_sha256)) {
    a4_s4_frozen_r_raw_stop("oracle build receipt differs from the supplied attested digest")
  }
  receipt <- tryCatch(jsonlite::fromJSON(receipt_path, simplifyVector = FALSE),
    error = function(error) a4_s4_frozen_r_raw_stop("oracle build receipt is not readable JSON"))
  required <- c(receipt_fields, "installed_tree_sha256", "marker_sha256", "log_sha256",
    "exit_code", "original_source_unchanged")
  if (!is.list(receipt) || !all(required %in% names(receipt)) ||
      !identical(unname(vapply(receipt_fields, function(field) as.character(receipt[[field]]),
        character(1L))), unname(vapply(receipt_fields, function(field) expected[[field]],
        character(1L)))) ||
      !is.numeric(receipt$exit_code) || length(receipt$exit_code) != 1L ||
      !identical(as.numeric(receipt$exit_code), 0) ||
      !identical(receipt$original_source_unchanged, TRUE) ||
      any(!grepl("^[0-9a-f]{64}$", unname(vapply(c("installed_tree_sha256", "marker_sha256", "log_sha256"),
        function(field) as.character(receipt[[field]]), character(1L)))))) {
    a4_s4_frozen_r_raw_stop("oracle build receipt does not prove an unchanged successful frozen build")
  }
  # R CMD INSTALL may leave compiler by-products under the extracted source
  # tree.  The externally attested receipt's `original_source_unchanged`
  # field is therefore the source-tree assertion; re-hash only NAMESPACE here,
  # where a post-install extra cannot change the intended source byte.
  if (!dir.exists(source_path) ||
      !identical(a4_s4_frozen_r_raw_sha256_file(file.path(source_path, "NAMESPACE"),
        "oracle source NAMESPACE"), expected$namespace_sha256) ||
      !identical(a4_s4_frozen_r_raw_sha256_file(install_log_path, "oracle install log"),
        as.character(receipt$log_sha256))) {
    a4_s4_frozen_r_raw_stop("oracle build files differ from the frozen build receipt")
  }
  marker_expected <- c(expected,
    list(installed_tree_sha256 = as.character(receipt$installed_tree_sha256)))
  marker <- a4_s4_frozen_r_raw_validate_marker(file.path(frozen_library, "gllvmTMB"),
    marker_expected)
  if (!identical(marker$marker_sha256, as.character(receipt$marker_sha256))) {
    a4_s4_frozen_r_raw_stop("installed source marker differs from the externally attested oracle build")
  }
  list(oracle_build_root = build_root, oracle_build_receipt_path = receipt_path,
    oracle_build_receipt_sha256 = receipt_sha256, oracle_source_path = source_path,
    oracle_install_log_sha256 = as.character(receipt$log_sha256),
    marker = marker)
}

a4_s4_frozen_r_raw_frozen_package <- function(frozen_library,
                                                expected_build_receipt_sha256) {
  if ("gllvmTMB" %in% loadedNamespaces()) {
    a4_s4_frozen_r_raw_stop("gllvmTMB was already loaded; invoke this runner in a fresh R process")
  }
  frozen_library <- normalizePath(frozen_library, mustWork = TRUE)
  installed <- file.path(frozen_library, "gllvmTMB")
  description <- file.path(installed, "DESCRIPTION")
  if (!file.exists(description)) {
    a4_s4_frozen_r_raw_stop("frozen-library does not contain gllvmTMB/DESCRIPTION")
  }
  installed_version <- as.character(read.dcf(description, fields = "Version")[1L, "Version"])
  if (!identical(installed_version, "0.7.0")) {
    a4_s4_frozen_r_raw_stop("frozen-library DESCRIPTION is not gllvmTMB 0.7.0")
  }
  oracle_build <- a4_s4_frozen_r_raw_validate_oracle_build(frozen_library,
    expected_build_receipt_sha256)
  marker <- oracle_build$marker
  .libPaths(c(frozen_library, .libPaths()))
  library("gllvmTMB", lib.loc = frozen_library, character.only = TRUE)
  package_path <- normalizePath(find.package("gllvmTMB"), mustWork = TRUE)
  if (!a4_s4_frozen_r_raw_within(package_path, frozen_library) ||
      !identical(as.character(utils::packageVersion("gllvmTMB")), "0.7.0")) {
    a4_s4_frozen_r_raw_stop("loaded gllvmTMB is not frozen 0.7.0 under frozen-library")
  }
  dll <- getLoadedDLLs()[["gllvmTMB"]]
  if (is.null(dll) || is.null(dll[["path"]])) {
    a4_s4_frozen_r_raw_stop("frozen gllvmTMB DLL was not loaded")
  }
  expected_dll_path <- a4_s4_frozen_r_raw_regular_file(
    file.path(package_path, "libs", paste0("gllvmTMB", .Platform$dynlib.ext)),
    "installed frozen gllvmTMB DLL")
  dll_path <- a4_s4_frozen_r_raw_regular_file(dll[["path"]], "loaded gllvmTMB DLL")
  if (!identical(dll_path, expected_dll_path)) {
    a4_s4_frozen_r_raw_stop("loaded gllvmTMB DLL is not the exact frozen package DLL")
  }
  # The source contract binds compiled bytes through this build's marker and
  # externally attested installed-tree receipt.  A legacy retained fixture
  # has a different, build-specific DLL hash and is never a runtime gate here.
  dll_sha256 <- a4_s4_frozen_r_raw_sha256_file(dll_path, "loaded gllvmTMB DLL")
  list(package_version = "0.7.0", package_path = package_path, dll_path = dll_path,
    dll_sha256 = dll_sha256, source_pin = marker$source_pin,
    archive_sha256 = marker$archive_sha256, namespace_sha256 = marker$namespace_sha256,
    source_tree_sha256 = marker$source_tree_sha256,
    installed_tree_sha256 = marker$installed_tree_sha256,
    marker_path = marker$marker_path, marker_sha256 = marker$marker_sha256,
    oracle_build_root = oracle_build$oracle_build_root,
    oracle_build_receipt_path = oracle_build$oracle_build_receipt_path,
    oracle_build_receipt_sha256 = oracle_build$oracle_build_receipt_sha256,
    oracle_source_path = oracle_build$oracle_source_path,
    oracle_install_log_sha256 = oracle_build$oracle_install_log_sha256,
    runtime = a4_s4_frozen_r_raw_runtime_provenance(),
    source_provenance = marker$source_provenance)
}

a4_s4_frozen_r_raw_runtime_package <- function(package) {
  path <- normalizePath(find.package(package), mustWork = TRUE)
  list(version = as.character(utils::packageVersion(package)), path = path,
    description_sha256 = a4_s4_frozen_r_raw_sha256_file(file.path(path, "DESCRIPTION"),
      sprintf("%s DESCRIPTION", package)))
}

a4_s4_frozen_r_raw_runtime_provenance <- function() {
  packages <- lapply(c("TMB", "Matrix", "ape"), a4_s4_frozen_r_raw_runtime_package)
  names(packages) <- c("TMB", "Matrix", "ape")
  list(r_version = R.version.string, packages = packages,
    runner_sha256 = a4_s4_frozen_r_raw_sha256_file(.a4_s4_raw_runner_path,
      "frozen-R raw runner"),
    json_matrix_helper_sha256 = a4_s4_frozen_r_raw_sha256_file(
      file.path(.a4_s4_raw_helper_dir, "a4_s4_json_matrix.R"), "JSON matrix helper"),
    frozen_evaluator_helper_sha256 = a4_s4_frozen_r_raw_sha256_file(
      file.path(.a4_s4_raw_helper_dir, "a4_s4_frozen_r_evaluator.R"),
      "frozen R evaluator helper"))
}

a4_s4_frozen_r_raw_request_provenance_fields <- function() {
  c("package_version", "source_pin", "fixture_file_sha256",
    "reference_file_sha256", "precision_source_sha256", "data_sha256")
}

# The shared frozen evaluator intentionally retains the historic reference
# DLL digest.  Raw receipts instead bind executable bytes at the top level to
# their own externally attested oracle build; keep only source/fixture facts
# in each declared-coordinate request.
a4_s4_frozen_r_raw_request <- function(row_id, r_packed_theta) {
  legacy <- a4_s4_frozen_r_request(row_id, r_packed_theta)
  fields <- a4_s4_frozen_r_raw_request_provenance_fields()
  provenance <- legacy$provenance[fields]
  if (!identical(names(provenance), fields) || "dll_sha256" %in% names(provenance)) {
    a4_s4_frozen_r_raw_stop("raw request did not separate build DLL provenance from frozen input facts")
  }
  list(row_id = legacy$row_id, provenance = provenance, map = legacy$map,
    precision = legacy$precision)
}

a4_s4_frozen_r_raw_validate_runtime <- function(runtime) {
  expected <- c("r_version", "packages", "runner_sha256", "json_matrix_helper_sha256",
    "frozen_evaluator_helper_sha256")
  if (!is.list(runtime) || !identical(names(runtime), expected) ||
      !is.character(runtime$r_version) || length(runtime$r_version) != 1L ||
      !is.list(runtime$packages) || !identical(names(runtime$packages), c("TMB", "Matrix", "ape")) ||
      any(!grepl("^[0-9a-f]{64}$", c(runtime$runner_sha256,
        runtime$json_matrix_helper_sha256, runtime$frozen_evaluator_helper_sha256))) ||
      !all(vapply(runtime$packages, function(package) {
        is.list(package) && identical(names(package), c("version", "path", "description_sha256")) &&
          is.character(package$version) && length(package$version) == 1L &&
          is.character(package$path) && length(package$path) == 1L &&
          is.character(package$description_sha256) && length(package$description_sha256) == 1L &&
          grepl("^[0-9a-f]{64}$", package$description_sha256)
      }, logical(1L)))) {
    a4_s4_frozen_r_raw_stop("raw receipt runtime provenance has an invalid field")
  }
  invisible(runtime)
}

a4_s4_frozen_r_raw_long_data <- function(payload, kind) {
  trait_names <- if (identical(kind, "dense")) payload$reference$fixture$trait_names else
    payload$reference$trait_names
  species_labels <- if (identical(kind, "dense")) payload$reference$fixture$tip_order else
    payload$reference$precision$observed_labels
  if (length(trait_names) != 3L || length(species_labels) != 8L) {
    a4_s4_frozen_r_raw_stop("retained row has unexpected trait/species labels")
  }
  data <- expand.grid(replicate = seq_len(2L), trait_id = seq_len(3L),
    species_id = seq_len(8L), KEEP.OUT.ATTRS = FALSE)
  observation <- (data$species_id - 1L) * 2L + data$replicate
  data$value <- payload$Y[cbind(data$trait_id, observation)]
  data$species <- factor(species_labels[data$species_id], levels = species_labels)
  data$trait <- factor(trait_names[data$trait_id], levels = trait_names)
  data
}

a4_s4_frozen_r_raw_character_vector <- function(value, label, expected_length) {
  if (is.character(value)) {
    values <- value
  } else if (is.list(value) && all(vapply(value, function(item) {
    is.character(item) && length(item) == 1L
  }, logical(1L)))) {
    values <- unlist(value, use.names = FALSE)
  } else {
    a4_s4_frozen_r_raw_stop(sprintf("%s must be a character vector or scalar-list array", label))
  }
  if (length(values) != expected_length || anyNA(values) || any(!nzchar(values)) ||
      anyDuplicated(values)) {
    a4_s4_frozen_r_raw_stop(sprintf("%s must contain %d unique nonempty labels", label, expected_length))
  }
  as.character(values)
}

a4_s4_frozen_r_raw_integer_scalar_array <- function(value, label, lower, upper,
                                                      expected_length) {
  if (is.atomic(value) && is.numeric(value)) {
    values <- value
  } else if (is.list(value) && all(vapply(value, function(item) {
    is.atomic(item) && is.numeric(item) && length(item) == 1L
  }, logical(1L)))) {
    values <- unlist(value, recursive = FALSE, use.names = FALSE)
  } else {
    a4_s4_frozen_r_raw_stop(sprintf("%s must be a numeric vector or one-level scalar-list array", label))
  }
  if (length(values) != expected_length || any(!is.finite(values)) ||
      any(values != floor(values)) || any(values < lower) || any(values > upper)) {
    a4_s4_frozen_r_raw_stop(sprintf("%s must contain %d integer values in [%s, %s]", label,
      expected_length, lower, upper))
  }
  as.integer(values)
}

a4_s4_frozen_r_raw_pedigree_table <- function(payload) {
  pedigree <- payload$reference$precision$pedigree
  fields <- c("node_labels", "sire_one_based_zero_unknown", "dam_one_based_zero_unknown")
  if (!is.list(pedigree) || !identical(names(pedigree), fields)) {
    a4_s4_frozen_r_raw_stop("retained pedigree has an unexpected field set")
  }
  n_nodes <- a4_s4_positive_integer(payload$precision$n_aug, "retained pedigree n_aug")
  labels <- a4_s4_frozen_r_raw_character_vector(pedigree$node_labels,
    "retained pedigree node_labels", n_nodes)
  sire <- a4_s4_frozen_r_raw_integer_scalar_array(pedigree$sire_one_based_zero_unknown,
    "retained pedigree sire indices", 0L, n_nodes, n_nodes)
  dam <- a4_s4_frozen_r_raw_integer_scalar_array(pedigree$dam_one_based_zero_unknown,
    "retained pedigree dam indices", 0L, n_nodes, n_nodes)
  parent_labels <- function(index) {
    output <- rep(NA_character_, length(index))
    known <- index != 0L
    output[known] <- labels[index[known]]
    output
  }
  data.frame(id = labels, sire = parent_labels(sire), dam = parent_labels(dam),
    stringsAsFactors = FALSE)
}

a4_s4_frozen_r_raw_dense_vcv <- function(payload) {
  n_leaves <- a4_s4_positive_integer(payload$precision$n_leaves,
    "retained dense n_leaves")
  labels <- a4_s4_frozen_r_raw_character_vector(payload$reference$fixture$tip_order,
    "retained dense tip_order", n_leaves)
  A_original <- a4_s4_decode_json_matrix(payload$reference$source_covariance$A_original,
    "retained dense A_original")
  if (!identical(dim(A_original), c(n_leaves, n_leaves)) ||
      !isTRUE(all.equal(A_original, t(A_original), tolerance = 1e-12))) {
    a4_s4_frozen_r_raw_stop("retained dense A_original must be a symmetric n_leaves-by-n_leaves matrix")
  }
  dimnames(A_original) <- list(labels, labels)
  A_original
}

a4_s4_frozen_r_raw_formula <- function(payload, kind, data) {
  if (identical(kind, "tree")) {
    tree <- ape::read.tree(text = payload$reference$precision$newick)
    return(list(formula = value ~ 0 + trait + phylo_latent(species, d = 1,
      tree = tree, unique = FALSE), data = data))
  }
  if (identical(kind, "pedigree")) {
    ped <- a4_s4_frozen_r_raw_pedigree_table(payload)
    return(list(formula = value ~ 0 + trait + animal_latent(species, d = 1,
      pedigree = ped, unique = FALSE), data = data))
  }
  A_original <- a4_s4_frozen_r_raw_dense_vcv(payload)
  # Pass the retained original VCV.  gllvmTMB applies its one internal ridge;
  # passing A_ridged here would apply a second ridge and is forbidden.
  list(formula = value ~ 0 + trait + phylo_latent(species, d = 1,
    vcv = A_original, unique = FALSE), data = data)
}

a4_s4_frozen_r_raw_expected_Q <- function(payload, kind) {
  stored <- if (identical(kind, "dense")) payload$reference$precision$Q_canonical else
    payload$reference$precision$Q_canonical
  a4_s4_decode_json_matrix(stored, sprintf("%s retained canonical Q", kind))
}

a4_s4_frozen_r_raw_tmb_canonical_data <- function(data) {
  if (!is.list(data)) {
    a4_s4_frozen_r_raw_stop("checked TMB data are not a list")
  }
  # Mirror TMB::MakeADFun() 1.9.21 dataSanitize() exactly: a raw list is
  # recursively converted to doubles (and canonical sparse storage) before
  # the returned `obj$fn` closes over `obj$env$data`.  gllvmTMB retains the
  # pre-sanitisation list as `fit$tmb_data`, so direct identity is wrong.
  data_sanitize <- function(value) {
    if (is.list(value)) return(lapply(value, data_sanitize))
    if (methods::is(value, "sparseMatrix")) {
      return(methods::as(methods::as(value, "TsparseMatrix"), "generalMatrix"))
    }
    if (is.character(value)) return(value)
    if (is.factor(value)) value <- unclass(value) - 1L
    storage.mode(value) <- "double"
    value
  }
  check_passed <- attr(data, "check.passed")
  if (is.null(check_passed) || !isTRUE(check_passed)) data <- lapply(data, data_sanitize)
  attr(data, "check.passed") <- TRUE
  data
}

a4_s4_frozen_r_raw_assert_marginal_binding <- function(obj, tmb, request) {
  if (is.null(obj) || !is.function(obj$fn) || !is.environment(obj$env) ||
      !is.list(obj$env$data) || !is.list(obj$env$parameters)) {
    a4_s4_frozen_r_raw_stop("fit$tmb_obj has no auditable marginal TMB environment")
  }
  canonical_tmb <- a4_s4_frozen_r_raw_tmb_canonical_data(tmb)
  if (!identical(environment(obj$fn), obj$env) || !identical(obj$env$data, canonical_tmb)) {
    a4_s4_frozen_r_raw_stop("marginal TMB object is not bound to the checked TMB inputs")
  }
  if (!identical(as.character(obj$env$DLL), "gllvmTMB")) {
    a4_s4_frozen_r_raw_stop("marginal TMB object is not bound to the frozen gllvmTMB DLL")
  }
  # MakeADFun turns the requested `random = "g_phy"` block into numeric
  # positions in `env$random`.  Reconstruct those positions from the complete
  # parameter list: this rejects both a joint `random = NULL` object and a
  # marginal object that integrated a different block.
  parameter_blocks <- rep(names(obj$env$parameters), lengths(obj$env$parameters))
  expected_random <- which(parameter_blocks == "g_phy")
  actual_random <- obj$env$random
  if (is.null(actual_random) || is.null(obj$env$parameters$g_phy) ||
      length(obj$env$parameters$g_phy) != request$map$n_augmented ||
      !identical(as.integer(actual_random), as.integer(expected_random))) {
    a4_s4_frozen_r_raw_stop("TMB random-effect integration is not the required g_phy marginal structure")
  }
  invisible(obj)
}

a4_s4_frozen_r_raw_assert_fit <- function(fit, payload, request, kind, data) {
  obj <- fit$tmb_obj
  expected_names <- a4_s4_frozen_r_theta_names()
  if (!identical(names(obj$par), expected_names) || !identical(names(fit$opt$par), expected_names)) {
    a4_s4_frozen_r_raw_stop("marginal object active coordinates differ from frozen theta contract")
  }
  tmb <- fit$tmb_data
  required <- c("Ainv_phy_rr", "log_det_A_phy_rr", "n_aug_phy", "species_id",
    "species_aug_id", "trait_id", "y", "X_fix")
  if (!all(required %in% names(tmb))) {
    a4_s4_frozen_r_raw_stop("marginal fit lacks a required frozen TMB input")
  }
  a4_s4_frozen_r_raw_assert_marginal_binding(obj, tmb, request)
  Q <- as.matrix(tmb$Ainv_phy_rr)
  expected_Q <- a4_s4_frozen_r_raw_expected_Q(payload, kind)
  if (!identical(dim(Q), dim(expected_Q)) || max(abs(Q - expected_Q)) > 1e-12 ||
      !identical(as.integer(tmb$n_aug_phy), request$map$n_augmented) ||
      !isTRUE(all.equal(-as.numeric(tmb$log_det_A_phy_rr), request$precision$log_det_Q,
        tolerance = 1e-12))) {
    a4_s4_frozen_r_raw_stop("TMB Q, log determinant, or augmented size differs from frozen row")
  }
  sid <- as.integer(tmb$species_id)
  aug <- as.integer(tmb$species_aug_id)
  tid <- as.integer(tmb$trait_id)
  y <- as.numeric(tmb$y)
  if (length(sid) != nrow(data) || length(aug) != nrow(data) || length(tid) != nrow(data) ||
      length(y) != nrow(data) || any(sid < 0L) || any(sid >= 8L) ||
      !identical(aug, as.integer(request$map$species_aug_id_zero_based[sid + 1L])) ||
      any(tid < 0L) || any(tid >= 3L)) {
    a4_s4_frozen_r_raw_stop("TMB species, augmented-node, or trait map differs from frozen row")
  }
  candidates <- vapply(seq_along(y), function(i) {
    candidate <- which(data$species_id - 1L == sid[[i]] & data$trait_id - 1L == tid[[i]] &
      abs(data$value - y[[i]]) <= 16 * .Machine$double.eps * max(1, abs(y[[i]])))
    if (length(candidate) == 1L) as.integer(candidate[[1L]]) else NA_integer_
  }, integer(1L))
  if (anyNA(candidates) || !identical(sort(as.integer(candidates)), seq_len(nrow(data)))) {
    a4_s4_frozen_r_raw_stop("TMB response rows do not identify the retained response exactly once")
  }
  expected_X <- stats::model.matrix(~ 0 + trait, data = data)[as.integer(candidates), , drop = FALSE]
  X <- as.matrix(tmb$X_fix)
  if (!identical(dim(X), dim(expected_X)) || any(X != expected_X) ||
      !identical(as.numeric(request$precision$scale), as.numeric(payload$precision$scale))) {
    a4_s4_frozen_r_raw_stop("TMB fixed design or retained precision scale differs from frozen row")
  }
  if (identical(kind, "dense") &&
      !identical(payload$reference$source_covariance$ridge_operation, a4_s4_dense_ridge_operation)) {
    a4_s4_frozen_r_raw_stop("dense row does not retain the one-ridge source covariance contract")
  }
  obj
}

a4_s4_frozen_r_raw_assert_no_sdreport <- function(fit) {
  if (!is.null(fit$sd_report)) {
    a4_s4_frozen_r_raw_stop("raw evaluator must construct the fit without a retained sdreport")
  }
  invisible(fit)
}

a4_s4_frozen_r_raw_validate_frozen <- function(frozen) {
  expected <- c("package_version", "package_path", "dll_path", "dll_sha256", "source_pin",
    "archive_sha256", "namespace_sha256", "source_tree_sha256", "installed_tree_sha256",
    "marker_path", "marker_sha256", "oracle_build_root", "oracle_build_receipt_path",
    "oracle_build_receipt_sha256", "oracle_source_path", "oracle_install_log_sha256",
    "runtime", "source_provenance")
  if (!is.list(frozen) || !identical(names(frozen), expected) ||
      !identical(frozen$package_version, "0.7.0") ||
      !identical(frozen$source_pin, a4_s4_frozen_r_source_pin) ||
      !identical(frozen$archive_sha256, a4_s4_frozen_r_raw_archive_sha256) ||
      !identical(frozen$namespace_sha256, a4_s4_frozen_r_raw_namespace_sha256) ||
      !identical(frozen$source_tree_sha256, a4_s4_frozen_r_raw_source_tree_sha256) ||
      !identical(frozen$source_provenance, "verified_installed_marker")) {
    a4_s4_frozen_r_raw_stop("raw receipt frozen provenance is not the verified CORE-070 oracle")
  }
  hashes <- c(frozen$dll_sha256, frozen$installed_tree_sha256, frozen$marker_sha256,
    frozen$oracle_build_receipt_sha256, frozen$oracle_install_log_sha256)
  if (any(!grepl("^[0-9a-f]{64}$", hashes)) ||
      !is.character(frozen$package_path) || !is.character(frozen$dll_path) ||
      !is.character(frozen$marker_path) || !is.character(frozen$oracle_build_root) ||
      !is.character(frozen$oracle_build_receipt_path) || !is.character(frozen$oracle_source_path) ||
      !identical(basename(frozen$marker_path), a4_s4_frozen_r_raw_marker_name) ||
      !identical(dirname(frozen$marker_path), frozen$package_path) ||
      !identical(frozen$dll_path,
        file.path(frozen$package_path, "libs", paste0("gllvmTMB", .Platform$dynlib.ext))) ||
      !identical(frozen$package_path,
        file.path(frozen$oracle_build_root, "library", "gllvmTMB")) ||
      !identical(frozen$oracle_build_receipt_path,
        file.path(frozen$oracle_build_root, "build.json")) ||
      !identical(frozen$oracle_source_path, file.path(frozen$oracle_build_root, "source"))) {
    a4_s4_frozen_r_raw_stop("raw receipt frozen provenance has an invalid field")
  }
  a4_s4_frozen_r_raw_validate_runtime(frozen$runtime)
  invisible(frozen)
}

a4_s4_frozen_r_raw_assert_frozen_unchanged <- function(frozen) {
  a4_s4_frozen_r_raw_validate_frozen(frozen)
  oracle_build <- a4_s4_frozen_r_raw_validate_oracle_build(
    file.path(frozen$oracle_build_root, "library"),
    frozen$oracle_build_receipt_sha256)
  marker <- oracle_build$marker
  if (!identical(marker$source_pin, frozen$source_pin) ||
      !identical(marker$archive_sha256, frozen$archive_sha256) ||
      !identical(marker$namespace_sha256, frozen$namespace_sha256) ||
      !identical(marker$source_tree_sha256, frozen$source_tree_sha256) ||
      !identical(marker$installed_tree_sha256, frozen$installed_tree_sha256) ||
      !identical(marker$marker_sha256, frozen$marker_sha256) ||
      !identical(oracle_build$oracle_build_receipt_path, frozen$oracle_build_receipt_path) ||
      !identical(oracle_build$oracle_source_path, frozen$oracle_source_path) ||
      !identical(oracle_build$oracle_install_log_sha256, frozen$oracle_install_log_sha256) ||
      !identical(a4_s4_frozen_r_raw_sha256_file(frozen$dll_path, "frozen gllvmTMB DLL"),
        frozen$dll_sha256) ||
      !identical(a4_s4_frozen_r_raw_runtime_provenance(), frozen$runtime)) {
    a4_s4_frozen_r_raw_stop("frozen R runtime changed during raw objective evaluation")
  }
  invisible(frozen)
}

a4_s4_frozen_r_raw_validate_input_row <- function(row) {
  expected <- c("row_id", "kind", "marginal_nll", "repeated_marginal_nll",
    "source_response_sha256", "precision_scale", "frozen_request",
    "dense_original_vcv_only", "construction")
  if (!is.list(row) || !identical(names(row), expected)) {
    a4_s4_frozen_r_raw_stop("raw receipt row has an unexpected field set")
  }
  expected_row <- a4_s4_frozen_r_row_for_id(row$row_id)
  request <- a4_s4_frozen_r_raw_request(row$row_id,
    setNames(c(rep(0, 3L), 0, rep(0, 3L)), a4_s4_frozen_r_theta_names()))
  if (!identical(row$kind, expected_row$kind) || !is.numeric(row$marginal_nll) ||
      length(row$marginal_nll) != 1L || !is.finite(row$marginal_nll) ||
      !identical(row$marginal_nll, row$repeated_marginal_nll) ||
      !identical(row$source_response_sha256, expected_row$data_sha256) ||
      !identical(as.numeric(row$precision_scale), as.numeric(expected_row$precision$scale)) ||
      !identical(names(row$frozen_request), c("provenance", "map", "precision")) ||
      !identical(row$frozen_request$provenance, request$provenance) ||
      !identical(row$frozen_request$map, request$map) ||
      !identical(row$frozen_request$precision, request$precision) ||
      !identical(row$dense_original_vcv_only, identical(row$kind, "dense"))) {
    a4_s4_frozen_r_raw_stop("raw receipt row differs from its frozen A4/S4 contract")
  }
  construction_fields <- c("route", "fit_performed", "optimization_performed",
    "optimizer_policy", "sdreport_requested", "optimizer_result_retained", "optimizer_result_compared")
  if (!is.list(row$construction) || !identical(names(row$construction), construction_fields) ||
      !identical(row$construction$route, "gllvmTMB(..., engine = 'tmb')") ||
      !identical(row$construction$fit_performed, TRUE) ||
      !identical(row$construction$optimization_performed, TRUE) ||
      !identical(row$construction$optimizer_policy, "n_init=1; optimizer=nlminb") ||
      !identical(row$construction$sdreport_requested, FALSE) ||
      !identical(row$construction$optimizer_result_retained, FALSE) ||
      !identical(row$construction$optimizer_result_compared, FALSE)) {
    a4_s4_frozen_r_raw_stop("raw receipt construction metadata is not honest or complete")
  }
  list(row_id = row$row_id, kind = row$kind, marginal_nll = row$marginal_nll,
    repeated_marginal_nll = row$repeated_marginal_nll,
    source_response_sha256 = row$source_response_sha256,
    precision_scale = row$precision_scale, frozen_request = row$frozen_request,
    dense_original_vcv_only = row$dense_original_vcv_only, construction = row$construction,
    repeat_identical = TRUE, qualified = FALSE, public_formula_admission = "closed")
}

a4_s4_frozen_r_raw_receipt <- function(frozen, theta, rows) {
  a4_s4_frozen_r_raw_validate_frozen(frozen)
  a4_s4_frozen_r_validate_theta(theta)
  expected <- unname(vapply(a4_s4_frozen_r_rows(), `[[`, character(1L), "row_id"))
  ids <- unname(vapply(rows, `[[`, character(1L), "row_id"))
  if (!identical(ids, expected)) a4_s4_frozen_r_raw_stop("raw receipt must retain the three frozen rows in order")
  rows <- lapply(rows, a4_s4_frozen_r_raw_validate_input_row)
  list(schema_version = a4_s4_frozen_r_raw_schema_version,
    status = "raw_r_declared_coordinate_evaluations_unqualified", frozen = frozen,
    r_packed_theta = unname(theta), r_packed_theta_names = a4_s4_frozen_r_theta_names(),
    rows = rows, qualified = FALSE, public_formula_admission = "closed",
    claim_boundary = list(r_declared_coordinate_evaluation = "recorded",
      paired_delta = "not_computed",
      construction_optimizer = "performed_not_retained_or_compared",
      sdreport = "disabled_at_construction",
      own_optimum_comparison = "not_computed", ci = "not_computed", admission = "closed",
      binary_provenance = "loaded DLL bytes are bound to externally attested oracle build receipt and installed tree",
      note = "R-only declared-coordinate evaluations after construction-time optimization; no paired or public claim"))
}

a4_s4_frozen_r_raw_run <- function(frozen_library, core070, output, theta,
                                    expected_build_receipt_sha256) {
  output <- a4_s4_frozen_r_raw_output_fence(output)
  lock <- a4_s4_frozen_r_raw_acquire_lock(output)
  on.exit(a4_s4_frozen_r_raw_release_lock(lock), add = TRUE)
  if (!requireNamespace("jsonlite", quietly = TRUE) || !requireNamespace("digest", quietly = TRUE) ||
      !requireNamespace("ape", quietly = TRUE) || !requireNamespace("TMB", quietly = TRUE) ||
      !requireNamespace("Matrix", quietly = TRUE)) {
    a4_s4_frozen_r_raw_stop("jsonlite, digest, ape, TMB, and Matrix are required before frozen-R evaluation")
  }
  core070 <- normalizePath(core070, mustWork = TRUE)
  payloads <- a4_s4_preflight_payloads(core070)
  frozen <- a4_s4_frozen_r_raw_frozen_package(frozen_library,
    expected_build_receipt_sha256)
  rows <- list()
  for (kind in c("tree", "pedigree", "dense")) {
    request <- a4_s4_frozen_r_raw_request(a4_s4_frozen_r_rows()[[kind]]$row_id, theta)
    payload <- payloads[[kind]]
    data <- a4_s4_frozen_r_raw_long_data(payload, kind)
    model <- a4_s4_frozen_r_raw_formula(payload, kind, data)
    # The public frozen R constructor has no no-fit route.  Its optimisation is
    # therefore recorded below but its values are neither retained nor used as
    # an own-optimum comparison or as evidence by this raw evaluator.  This
    # point-only runner explicitly disables construction-time sdreport work.
    fit <- gllvmTMB(
      model$formula, data = model$data, trait = "trait", unit = "species", cluster = "species",
      family = gaussian(), REML = FALSE, engine = "tmb",
      control = gllvmTMBcontrol(n_init = 1L, optimizer = "nlminb",
        se = FALSE, optArgs = list(control = list(iter.max = 80L, eval.max = 120L, rel.tol = 1e-12)))
    )
    a4_s4_frozen_r_raw_assert_no_sdreport(fit)
    obj <- a4_s4_frozen_r_raw_assert_fit(fit, payload, request, kind, data)
    # After structural checks, objective access is exactly two evaluations at
    # the supplied frozen coordinate vector.  It calls no post-construction
    # gradient, Hessian, sdreport, CI, or fit-comparison route.
    marginal_nll <- obj$fn(theta)
    repeated_marginal_nll <- obj$fn(theta)
    rows[[length(rows) + 1L]] <- list(row_id = request$row_id,
      kind = kind, marginal_nll = marginal_nll, repeated_marginal_nll = repeated_marginal_nll,
      source_response_sha256 = request$provenance$data_sha256,
      precision_scale = request$precision$scale,
      frozen_request = list(provenance = request$provenance, map = request$map,
        precision = request$precision),
      dense_original_vcv_only = identical(kind, "dense"),
      construction = list(route = "gllvmTMB(..., engine = 'tmb')", fit_performed = TRUE,
        optimization_performed = TRUE, optimizer_policy = "n_init=1; optimizer=nlminb",
        sdreport_requested = FALSE,
        optimizer_result_retained = FALSE, optimizer_result_compared = FALSE))
  }
  # Re-check package/source/runtime bytes after the three evaluations.  This
  # narrows the interval in which a concurrent local mutation could turn a
  # start-validated environment into a different recorded result.
  a4_s4_frozen_r_raw_assert_frozen_unchanged(frozen)
  receipt <- a4_s4_frozen_r_raw_receipt(frozen, theta, rows)
  a4_s4_frozen_r_raw_publish(receipt, output)
  receipt
}

a4_s4_frozen_r_raw_cli <- function(args) {
  parsed <- a4_s4_frozen_r_raw_parse_cli(args)
  a4_s4_frozen_r_raw_run(parsed$frozen_library, parsed$core070, parsed$output, parsed$theta,
    parsed$expected_build_receipt_sha256)
  cat("A4_S4_FROZEN_R_RAW_RECORDED_UNQUALIFIED\n")
  invisible(NULL)
}

.a4_s4_raw_helper_dir <- file.path("tools", "destination_b")
.a4_s4_raw_runner_path <- normalizePath(file.path(.a4_s4_raw_helper_dir,
  "run_a4_s4_frozen_r_raw.R"), mustWork = TRUE)
source(file.path(.a4_s4_raw_helper_dir, "a4_s4_json_matrix.R"))
source(file.path(.a4_s4_raw_helper_dir, "a4_s4_frozen_r_evaluator.R"))

if (sys.nframe() == 0L) a4_s4_frozen_r_raw_cli(commandArgs(trailingOnly = TRUE))
