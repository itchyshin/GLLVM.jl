runner <- file.path("tools", "destination_b", "run_a4_s4_frozen_r_raw.R")
if (!file.exists(runner)) {
  stop("the integrated frozen-R raw runner is missing", call. = FALSE)
}
source(runner)

expect_error <- function(expression, label) {
  failed <- FALSE
  tryCatch(force(expression), error = function(error) failed <<- TRUE)
  if (!failed) stop(sprintf("expected rejection for %s", label), call. = FALSE)
}

theta_csv <- "-0.2,0.1,0.3,-1.1,0.7,-0.4,0.2"
theta <- a4_s4_frozen_r_raw_parse_theta(theta_csv)
stopifnot(
  identical(unname(theta), c(-0.2, 0.1, 0.3, -1.1, 0.7, -0.4, 0.2)),
  identical(names(theta), a4_s4_frozen_r_theta_names())
)
expect_error(a4_s4_frozen_r_raw_parse_theta("-0.2,0.1"), "short theta CSV")
expect_error(a4_s4_frozen_r_raw_parse_theta("-0.2,0.1,0.3,NaN,0.7,-0.4,0.2"),
  "non-finite theta CSV")
expect_error(a4_s4_frozen_r_raw_parse_cli(c("a", "b", "c")), "wrong CLI arity")
build_receipt_sha <- strrep("a", 64L)
parsed <- a4_s4_frozen_r_raw_parse_cli(c("/tmp/library", ".", "/tmp/out.rds", theta_csv,
  build_receipt_sha))
stopifnot(identical(names(parsed), c("frozen_library", "core070", "output", "theta",
  "expected_build_receipt_sha256")),
          identical(parsed$expected_build_receipt_sha256, build_receipt_sha),
          identical(parsed$theta, theta))
expect_error(a4_s4_frozen_r_raw_parse_sha256("not-a-sha", "test digest"),
  "malformed expected build receipt digest")

occupied <- tempfile(fileext = ".rds")
stopifnot(file.create(occupied))
expect_error(a4_s4_frozen_r_raw_output_fence(occupied), "existing output")
vacant <- tempfile(fileext = ".rds")
a4_s4_frozen_r_raw_output_fence(vacant)
stopifnot(!file.exists(vacant))
lock <- a4_s4_frozen_r_raw_acquire_lock(vacant)
expect_error(a4_s4_frozen_r_raw_acquire_lock(vacant), "concurrent output lock")
a4_s4_frozen_r_raw_release_lock(lock)

regular_file <- tempfile("a4-s4-regular-file-")
writeBin(as.raw(c(1L, 2L)), regular_file)
stopifnot(identical(a4_s4_frozen_r_raw_regular_file(regular_file, "test regular file"),
  normalizePath(regular_file, mustWork = TRUE)))
symlink_file <- tempfile("a4-s4-dll-symlink-")
if (isTRUE(file.symlink(regular_file, symlink_file))) {
  expect_error(a4_s4_frozen_r_raw_regular_file(symlink_file, "test DLL symlink"),
    "symlinked DLL path")
}

# `a4_s4_preflight_payloads()` intentionally preserves JSON scalar arrays as
# lists.  The raw pedigree formula must decode those retained arrays before
# indexing parent labels, rather than silently relying on jsonlite defaults.
pedigree_payload <- a4_s4_preflight_payloads(file.path("docs", "dev-log", "core070"))[["pedigree"]]
pedigree_table <- a4_s4_frozen_r_raw_pedigree_table(pedigree_payload)
stopifnot(
  identical(names(pedigree_table), c("id", "sire", "dam")),
  identical(pedigree_table$id, paste0("i", seq_len(12L))),
  identical(pedigree_table$sire, c(NA_character_, NA_character_, NA_character_, NA_character_,
    "i1", "i1", "i2", "i2", "i5", "i7", "i9", "i9")),
  identical(pedigree_table$dam, c(NA_character_, NA_character_, NA_character_, NA_character_,
    "i3", "i3", "i4", "i4", "i6", "i8", "i10", "i6"))
)
malformed_pedigree_payload <- pedigree_payload
original_sire <- malformed_pedigree_payload$reference$precision$pedigree$sire_one_based_zero_unknown
malformed_pedigree_payload$reference$precision$pedigree$sire_one_based_zero_unknown <- c(
  list(c(original_sire[[1L]], original_sire[[2L]])), original_sire[-c(1L, 2L)]
)
expect_error(a4_s4_frozen_r_raw_pedigree_table(malformed_pedigree_payload),
  "nested pedigree parent-index array")
dense_payload <- a4_s4_preflight_payloads(file.path("docs", "dev-log", "core070"))[["dense"]]
dense_vcv <- a4_s4_frozen_r_raw_dense_vcv(dense_payload)
stopifnot(
  identical(dim(dense_vcv), c(8L, 8L)),
  identical(rownames(dense_vcv), paste0("sp", seq_len(8L))),
  identical(colnames(dense_vcv), paste0("sp", seq_len(8L))),
  isTRUE(all.equal(dense_vcv, t(dense_vcv), tolerance = 1e-12)),
  identical(sprintf("%.17g", as.numeric(dense_vcv[1L, c(1L, 2L, 8L)])),
    c("1", "0.92337763602796152", "0"))
)

# The marker verifier is independent of any installed gllvmTMB package.  It
# proves each source field plus both the NAMESPACE and complete installed-tree
# bindings instead of accepting a version string or an optional DESCRIPTION
# field.
marker_root <- tempfile("a4-s4-marker-")
marker_expected_values <- function(package) {
  list(reference_commit = strrep("a", 40L),
    archive_sha256 = strrep("b", 64L),
    namespace_sha256 = a4_s4_frozen_r_raw_sha256_file(file.path(package, "NAMESPACE"),
      "test namespace"),
    source_tree_sha256 = strrep("c", 64L),
    installed_tree_sha256 = a4_s4_frozen_r_raw_tree_sha256(package,
      exclude = a4_s4_frozen_r_raw_marker_name))
}
write_marker <- function(package, expected, overrides = list()) {
  values <- vapply(a4_s4_frozen_r_raw_marker_fields(), function(field) {
    expected[[field]]
  }, character(1L))
  if (length(overrides)) values[names(overrides)] <- unlist(overrides, use.names = FALSE)
  writeLines(sprintf('%s = "%s"', names(values), values),
    file.path(package, a4_s4_frozen_r_raw_marker_name))
}
reset_marker_fixture <- function() {
  unlink(marker_root, recursive = TRUE, force = TRUE)
  package <- file.path(marker_root, "gllvmTMB")
  dir.create(file.path(package, "R"), recursive = TRUE)
  writeLines("export(gllvmTMB)", file.path(package, "NAMESPACE"))
  writeLines("gllvmTMB <- function(...) NULL", file.path(package, "R", "gllvmTMB.R"))
  expected <- marker_expected_values(package)
  write_marker(package, expected)
  list(package = package, expected = expected)
}
marker_fixture <- reset_marker_fixture()
marker_package <- marker_fixture$package
marker_expected <- marker_fixture$expected
verified_marker <- a4_s4_frozen_r_raw_validate_marker(marker_package, marker_expected)
stopifnot(identical(verified_marker$source_provenance, "verified_installed_marker"),
          identical(verified_marker$source_pin, marker_expected$reference_commit))
write_marker(marker_package, marker_expected,
  overrides = list(reference_commit = strrep("0", 40L)))
expect_error(a4_s4_frozen_r_raw_validate_marker(marker_package, marker_expected),
  "tampered source commit")
marker_fixture <- reset_marker_fixture()
marker_package <- marker_fixture$package
marker_expected <- marker_fixture$expected
write_marker(marker_package, marker_expected,
  overrides = list(archive_sha256 = strrep("0", 64L)))
expect_error(a4_s4_frozen_r_raw_validate_marker(marker_package, marker_expected),
  "tampered source archive hash")
marker_fixture <- reset_marker_fixture()
marker_package <- marker_fixture$package
marker_expected <- marker_fixture$expected
write_marker(marker_package, marker_expected,
  overrides = list(source_tree_sha256 = strrep("0", 64L)))
expect_error(a4_s4_frozen_r_raw_validate_marker(marker_package, marker_expected),
  "tampered source tree hash")
marker_fixture <- reset_marker_fixture()
marker_package <- marker_fixture$package
marker_expected <- marker_fixture$expected
write_marker(marker_package, marker_expected,
  overrides = list(installed_tree_sha256 = strrep("0", 64L)))
expect_error(a4_s4_frozen_r_raw_validate_marker(marker_package, marker_expected),
  "tampered installed tree hash")
marker_fixture <- reset_marker_fixture()
marker_package <- marker_fixture$package
marker_expected <- marker_fixture$expected
writeLines("tampered", file.path(marker_package, "NAMESPACE"))
expect_error(a4_s4_frozen_r_raw_validate_marker(marker_package, marker_expected),
  "tampered installed namespace")
marker_fixture <- reset_marker_fixture()
marker_package <- marker_fixture$package
marker_expected <- marker_fixture$expected
writeLines("gllvmTMB <- function(...) 'tampered'", file.path(marker_package, "R", "gllvmTMB.R"))
expect_error(a4_s4_frozen_r_raw_validate_marker(marker_package, marker_expected),
  "tampered non-namespace installed file")
# Rewriting the mutable marker to the altered tree is still rejected because
# the verifier receives an independent expected installed-tree digest.
write_marker(marker_package, marker_expected,
  overrides = list(installed_tree_sha256 = a4_s4_frozen_r_raw_tree_sha256(marker_package,
    exclude = a4_s4_frozen_r_raw_marker_name)))
expect_error(a4_s4_frozen_r_raw_validate_marker(marker_package, marker_expected),
  "self-refreshed marker after installed-file tampering")
missing_marker_package <- tempfile("a4-s4-missing-marker-")
dir.create(missing_marker_package)
expect_error(a4_s4_frozen_r_raw_validate_marker(missing_marker_package, marker_expected),
  "missing installed source marker")

# A version-labelled but unmarked library is rejected before the package can
# load.  This is the exact boundary that prevents the locally available
# unmarked 0.7.0 build from becoming provenance evidence.
if ("gllvmTMB" %in% loadedNamespaces()) {
  stop("the frozen-R raw unit suite must start before gllvmTMB is loaded", call. = FALSE)
}
unmarked_library <- tempfile("a4-s4-unmarked-library-")
unmarked_package <- file.path(unmarked_library, "gllvmTMB")
dir.create(unmarked_package, recursive = TRUE)
writeLines(c("Package: gllvmTMB", "Version: 0.7.0"),
  file.path(unmarked_package, "DESCRIPTION"))
expect_error(a4_s4_frozen_r_raw_frozen_package(unmarked_library, build_receipt_sha),
  "unmarked installed 0.7.0 library")

# The installed-tree marker is not a trust root by itself.  The raw runner
# requires a separately supplied SHA-256 for the oracle build receipt; that
# receipt pins the marker and installed-tree values before package loading.
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("jsonlite is required for oracle build-receipt unit tests", call. = FALSE)
}
oracle_root <- tempfile("a4-s4-oracle-")
oracle_library <- file.path(oracle_root, "library")
oracle_package <- file.path(oracle_library, "gllvmTMB")
oracle_source <- file.path(oracle_root, "source")
dir.create(file.path(oracle_package, "R"), recursive = TRUE)
dir.create(file.path(oracle_package, "libs"), recursive = TRUE)
dir.create(file.path(oracle_source, "R"), recursive = TRUE)
writeLines("export(gllvmTMB)", file.path(oracle_package, "NAMESPACE"))
writeLines("export(gllvmTMB)", file.path(oracle_source, "NAMESPACE"))
writeLines("gllvmTMB <- function(...) NULL", file.path(oracle_package, "R", "gllvmTMB.R"))
writeLines("gllvmTMB <- function(...) NULL", file.path(oracle_source, "R", "gllvmTMB.R"))
oracle_dll <- file.path(oracle_package, "libs", "gllvmTMB.so")
writeBin(as.raw(c(1L, 2L, 3L, 4L)), oracle_dll)
install_log <- file.path(oracle_root, "install.log")
writeLines("mock successful install", install_log)
oracle_expected <- list(reference_commit = strrep("d", 40L),
  archive_sha256 = strrep("e", 64L),
  namespace_sha256 = a4_s4_frozen_r_raw_sha256_file(file.path(oracle_source, "NAMESPACE"),
    "mock oracle source NAMESPACE"),
  source_tree_sha256 = strrep("f", 64L))
oracle_marker_expected <- c(oracle_expected,
  list(installed_tree_sha256 = a4_s4_frozen_r_raw_tree_sha256(oracle_package,
    exclude = a4_s4_frozen_r_raw_marker_name)))
write_marker(oracle_package, oracle_marker_expected)
oracle_receipt <- list(reference_commit = oracle_expected$reference_commit,
  archive_sha256 = oracle_expected$archive_sha256,
  source_tree_sha256 = oracle_expected$source_tree_sha256,
  installed_tree_sha256 = oracle_marker_expected$installed_tree_sha256,
  marker_sha256 = a4_s4_frozen_r_raw_sha256_file(
    file.path(oracle_package, a4_s4_frozen_r_raw_marker_name), "mock oracle marker"),
  log_sha256 = a4_s4_frozen_r_raw_sha256_file(install_log, "mock oracle install log"),
  exit_code = 0L, original_source_unchanged = TRUE)
oracle_receipt_path <- file.path(oracle_root, "build.json")
jsonlite::write_json(oracle_receipt, oracle_receipt_path, auto_unbox = TRUE)
oracle_receipt_sha <- a4_s4_frozen_r_raw_sha256_file(oracle_receipt_path,
  "mock oracle build receipt")
verified_oracle <- a4_s4_frozen_r_raw_validate_oracle_build(oracle_library,
  oracle_receipt_sha, expected = oracle_expected)
stopifnot(identical(verified_oracle$marker$installed_tree_sha256,
  oracle_marker_expected$installed_tree_sha256))
# A changed DLL, even with a self-refreshed marker, cannot satisfy the fixed
# external build-receipt digest.  This is the same installed-tree binding used
# for a fresh compiled oracle build.
writeBin(as.raw(c(9L, 8L, 7L, 6L)), oracle_dll)
refreshed_marker <- oracle_marker_expected
refreshed_marker$installed_tree_sha256 <- a4_s4_frozen_r_raw_tree_sha256(oracle_package,
  exclude = a4_s4_frozen_r_raw_marker_name)
write_marker(oracle_package, refreshed_marker)
expect_error(a4_s4_frozen_r_raw_validate_oracle_build(oracle_library, oracle_receipt_sha,
  expected = oracle_expected), "self-refreshed marker against attested build receipt")
jsonlite::write_json(c(oracle_receipt, list(exit_code = 1L)), oracle_receipt_path,
  auto_unbox = TRUE)
expect_error(a4_s4_frozen_r_raw_validate_oracle_build(oracle_library, oracle_receipt_sha,
  expected = oracle_expected), "mutated oracle build receipt against supplied digest")

mock_runtime_package <- function(name) {
  list(version = "test-1.0.0", path = file.path("/private/runtime", name),
    description_sha256 = strrep("2", 64L))
}
mock_runtime <- list(r_version = "R version test", packages = list(
  TMB = mock_runtime_package("TMB"), Matrix = mock_runtime_package("Matrix"),
  ape = mock_runtime_package("ape")), runner_sha256 = strrep("3", 64L),
  json_matrix_helper_sha256 = strrep("4", 64L),
  frozen_evaluator_helper_sha256 = strrep("5", 64L))
frozen <- list(package_version = "0.7.0", package_path = "/private/frozen/library/gllvmTMB",
  dll_path = "/private/frozen/library/gllvmTMB/libs/gllvmTMB.so",
  dll_sha256 = "5d8a9c43b725911452716d4462e655a974c06274925bdee0f1b0c9abec399fe1",
  source_pin = a4_s4_frozen_r_source_pin,
  archive_sha256 = a4_s4_frozen_r_raw_archive_sha256,
  namespace_sha256 = a4_s4_frozen_r_raw_namespace_sha256,
  source_tree_sha256 = a4_s4_frozen_r_raw_source_tree_sha256,
  installed_tree_sha256 = strrep("d", 64L),
  marker_path = "/private/frozen/library/gllvmTMB/CORE070_SOURCE_PIN.toml",
  marker_sha256 = strrep("e", 64L), oracle_build_root = "/private/frozen",
  oracle_build_receipt_path = "/private/frozen/build.json",
  oracle_build_receipt_sha256 = strrep("f", 64L),
  oracle_source_path = "/private/frozen/source",
  oracle_install_log_sha256 = strrep("1", 64L),
  runtime = mock_runtime,
  source_provenance = "verified_installed_marker")

make_row <- function(row_id, nll) {
  request <- a4_s4_frozen_r_raw_request(row_id, theta)
  kind <- a4_s4_frozen_r_row_for_id(row_id)$kind
  list(row_id = row_id, kind = kind, marginal_nll = nll, repeated_marginal_nll = nll,
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

rows <- list(
  make_row("tree_height4_nonunit_ultrametric", 1.25),
  make_row("pedigree_12_nodes_8_observed_4_unobserved", 2.5),
  make_row("dense_vcv_ridged_once", 3.75)
)

receipt <- a4_s4_frozen_r_raw_receipt(
  frozen = frozen, theta = theta, rows = rows
)
stopifnot(
  identical(receipt$schema_version, "destination-b-a4-s4-frozen-r-raw-4"),
  identical(receipt$status, "raw_r_declared_coordinate_evaluations_unqualified"),
  identical(receipt$qualified, FALSE),
  identical(receipt$public_formula_admission, "closed"),
  identical(receipt$claim_boundary$paired_delta, "not_computed"),
  identical(receipt$claim_boundary$construction_optimizer, "performed_not_retained_or_compared"),
  identical(receipt$claim_boundary$sdreport, "disabled_at_construction"),
  identical(receipt$claim_boundary$own_optimum_comparison, "not_computed"),
  identical(receipt$claim_boundary$ci, "not_computed"),
  identical(receipt$claim_boundary$admission, "closed"),
  identical(receipt$claim_boundary$binary_provenance,
    "loaded DLL bytes are bound to externally attested oracle build receipt and installed tree"),
  length(receipt$rows) == 3L,
  all(vapply(receipt$rows, `[[`, logical(1L), "repeat_identical")),
  all(vapply(receipt$rows, function(row) row$construction$optimization_performed,
    logical(1L))),
  all(vapply(receipt$rows, function(row) identical(row$construction$sdreport_requested, FALSE),
    logical(1L)))
)
bad_repeat <- rows
bad_repeat[[1L]]$repeated_marginal_nll <- 1.0000000001
expect_error(a4_s4_frozen_r_raw_receipt(frozen, theta, bad_repeat),
  "non-identical repeated objective")
bad_claim <- rows
bad_claim[[1L]]$qualified <- TRUE
expect_error(a4_s4_frozen_r_raw_receipt(frozen, theta, bad_claim),
  "duplicate row claim field")
bad_frozen <- frozen
bad_frozen$source_provenance <- "not_available"
expect_error(a4_s4_frozen_r_raw_receipt(bad_frozen, theta, rows),
  "unverified frozen source provenance")
bad_runtime <- frozen
bad_runtime$runtime$packages$TMB$description_sha256 <- "not-a-digest"
expect_error(a4_s4_frozen_r_raw_receipt(bad_runtime, theta, rows),
  "malformed retained runtime provenance")
bad_marker_path <- frozen
bad_marker_path$marker_path <- "/private/other/CORE070_SOURCE_PIN.toml"
expect_error(a4_s4_frozen_r_raw_receipt(bad_marker_path, theta, rows),
  "marker outside declared package")
bad_dll_path <- frozen
bad_dll_path$dll_path <- "/private/other/libs/gllvmTMB.so"
expect_error(a4_s4_frozen_r_raw_receipt(bad_dll_path, theta, rows),
  "DLL outside declared package")
bad_dll_subpath <- frozen
bad_dll_subpath$dll_path <- "/private/frozen/library/gllvmTMB/other/gllvmTMB.so"
expect_error(a4_s4_frozen_r_raw_receipt(bad_dll_subpath, theta, rows),
  "DLL outside exact package libs path")
bad_dll_sha256 <- frozen
bad_dll_sha256$dll_sha256 <- "not-a-digest"
expect_error(a4_s4_frozen_r_raw_receipt(bad_dll_sha256, theta, rows),
  "malformed build-specific DLL hash")
bad_construction <- rows
bad_construction[[1L]]$construction$optimization_performed <- FALSE
expect_error(a4_s4_frozen_r_raw_receipt(frozen, theta, bad_construction),
  "dishonest construction optimisation flag")

# The end-of-run guard hashes the exact DLL path again.  Stub only its already
# unit-tested marker/runtime dependencies so this check can prove that a DLL
# byte mutation after initial acceptance cannot leave a receipt as successful.
mutation_root <- tempfile("a4-s4-postload-dll-")
mutation_build_root <- file.path(mutation_root, "oracle")
mutation_package <- file.path(mutation_build_root, "library", "gllvmTMB")
mutation_dll <- file.path(mutation_package, "libs", paste0("gllvmTMB", .Platform$dynlib.ext))
dir.create(dirname(mutation_dll), recursive = TRUE)
writeBin(as.raw(c(1L, 3L, 5L, 7L)), mutation_dll)
mutation_frozen <- frozen
mutation_frozen$package_path <- mutation_package
mutation_frozen$dll_path <- mutation_dll
mutation_frozen$dll_sha256 <- a4_s4_frozen_r_raw_sha256_file(mutation_dll,
  "post-load test DLL")
mutation_frozen$marker_path <- file.path(mutation_package, a4_s4_frozen_r_raw_marker_name)
mutation_frozen$oracle_build_root <- mutation_build_root
mutation_frozen$oracle_build_receipt_path <- file.path(mutation_build_root, "build.json")
mutation_frozen$oracle_source_path <- file.path(mutation_build_root, "source")
original_validate_oracle_build <- a4_s4_frozen_r_raw_validate_oracle_build
original_runtime_provenance <- a4_s4_frozen_r_raw_runtime_provenance
tryCatch({
  assign("a4_s4_frozen_r_raw_validate_oracle_build", function(...) {
    list(marker = list(source_pin = mutation_frozen$source_pin,
      archive_sha256 = mutation_frozen$archive_sha256,
      namespace_sha256 = mutation_frozen$namespace_sha256,
      source_tree_sha256 = mutation_frozen$source_tree_sha256,
      installed_tree_sha256 = mutation_frozen$installed_tree_sha256,
      marker_sha256 = mutation_frozen$marker_sha256),
      oracle_build_receipt_path = mutation_frozen$oracle_build_receipt_path,
      oracle_source_path = mutation_frozen$oracle_source_path,
      oracle_install_log_sha256 = mutation_frozen$oracle_install_log_sha256)
  }, envir = .GlobalEnv)
  assign("a4_s4_frozen_r_raw_runtime_provenance", function() mutation_frozen$runtime,
    envir = .GlobalEnv)
  a4_s4_frozen_r_raw_assert_frozen_unchanged(mutation_frozen)
  writeBin(as.raw(c(2L, 4L, 6L, 8L)), mutation_dll)
  expect_error(a4_s4_frozen_r_raw_assert_frozen_unchanged(mutation_frozen),
    "post-load DLL mutation")
}, finally = {
  assign("a4_s4_frozen_r_raw_validate_oracle_build", original_validate_oracle_build,
    envir = .GlobalEnv)
  assign("a4_s4_frozen_r_raw_runtime_provenance", original_runtime_provenance,
    envir = .GlobalEnv)
})

raw_request <- a4_s4_frozen_r_raw_request("tree_height4_nonunit_ultrametric", theta)
stopifnot(
  identical(names(raw_request), c("row_id", "provenance", "map", "precision")),
  identical(names(raw_request$provenance), a4_s4_frozen_r_raw_request_provenance_fields()),
  !("dll_sha256" %in% names(raw_request$provenance)),
  !identical(frozen$dll_sha256, a4_s4_frozen_r_dll_sha256)
)
bound_request <- raw_request
bound_data <- list(Ainv_phy_rr = diag(2L), log_det_A_phy_rr = 0, n_aug_phy = 14L,
  species_id = c(0L, 1L), species_aug_id = c(13L, 6L), trait_id = c(0L, 1L),
  y = c(1, 2), X_fix = diag(2L), uninspected_test_field = "retained")
canonical_bound_data <- a4_s4_frozen_r_raw_tmb_canonical_data(bound_data)
stopifnot(is.double(canonical_bound_data$species_id),
  identical(attr(canonical_bound_data, "check.passed"), TRUE))
bound_env <- new.env(parent = baseenv())
bound_env$data <- bound_data
bound_env$parameters <- list(g_phy = rep(0, 14L))
bound_env$DLL <- "gllvmTMB"
bound_env$random <- seq_len(14L)
bound_object <- list(fn = evalq(function(theta) 0, envir = bound_env), env = bound_env)
expect_error(a4_s4_frozen_r_raw_assert_marginal_binding(bound_object, bound_data, bound_request),
  "unsanitized objective data")
bound_env$data <- canonical_bound_data
a4_s4_frozen_r_raw_assert_marginal_binding(bound_object, bound_data, bound_request)
bound_env$data$uninspected_test_field <- "tampered"
expect_error(a4_s4_frozen_r_raw_assert_marginal_binding(bound_object, bound_data, bound_request),
  "objective full data not bound to checked TMB inputs")
bound_env$data <- canonical_bound_data
unbound_object <- list(fn = function(theta) 0, env = bound_env)
expect_error(a4_s4_frozen_r_raw_assert_marginal_binding(unbound_object, bound_data, bound_request),
  "objective closure not bound to checked TMB environment")
bound_env$random <- seq_len(13L)
expect_error(a4_s4_frozen_r_raw_assert_marginal_binding(bound_object, bound_data, bound_request),
  "wrong integrated random-effect coordinates")
bound_env$random <- seq_len(14L)

a4_s4_frozen_r_raw_assert_no_sdreport(list(sd_report = NULL))
expect_error(a4_s4_frozen_r_raw_assert_no_sdreport(list(sd_report = list(fixed = 1))),
  "retained sdreport")

publish_directory <- tempfile("a4-s4-raw-publish-")
dir.create(publish_directory)
published <- file.path(publish_directory, "receipt.rds")
publish_payload <- list(immutable = TRUE)
a4_s4_frozen_r_raw_publish(publish_payload, published)
stopifnot(file.exists(published), identical(readRDS(published), publish_payload))
expect_error(a4_s4_frozen_r_raw_publish(list(immutable = FALSE), published),
  "non-clobber receipt publication")
cleanup_failure_published <- file.path(publish_directory, "cleanup-failure.rds")
cleanup_result <- a4_s4_frozen_r_raw_publish(publish_payload, cleanup_failure_published,
  unlink_file = function(...) 1L)
stopifnot(identical(cleanup_result, cleanup_failure_published),
  file.exists(cleanup_failure_published),
  identical(readRDS(cleanup_failure_published), publish_payload))

source_text <- paste(readLines(runner, warn = FALSE), collapse = "\n")
stopifnot(
  grepl("<frozen-library> <core070-dir> <output-rds> <theta-csv>", source_text, fixed = TRUE),
  grepl("obj$fn(theta)", source_text, fixed = TRUE),
  grepl("CORE070_SOURCE_PIN.toml", source_text, fixed = TRUE),
  grepl("a4_s4_frozen_r_raw_acquire_lock", source_text, fixed = TRUE),
  grepl("a4_s4_frozen_r_raw_publish", source_text, fixed = TRUE),
  grepl("optimization_performed = TRUE", source_text, fixed = TRUE),
  grepl("se = FALSE", source_text, fixed = TRUE),
  grepl("sdreport_requested = FALSE", source_text, fixed = TRUE),
  grepl('paired_delta = "not_computed"', source_text, fixed = TRUE),
  !grepl("a4_s4_frozen_r_dll_sha256", source_text, fixed = TRUE),
  !grepl("JuliaCall", source_text, fixed = TRUE),
  !grepl("readRDS", source_text, fixed = TRUE),
  !grepl("file.rename", source_text, fixed = TRUE),
  !grepl("obj$gr", source_text, fixed = TRUE),
  !grepl("optimHess", source_text, fixed = TRUE),
  !grepl("standard_errors", source_text, fixed = TRUE),
  !grepl("confint", source_text, fixed = TRUE)
)

# Live integration is opt-in.  The default Tier 1 unit suite never loads the
# frozen package or creates a raw receipt.
if (identical(Sys.getenv("GLLVM_RUN_A4_S4_FROZEN_R_RAW"), "1")) {
  integration_args <- strsplit(Sys.getenv("GLLVM_A4_S4_FROZEN_R_RAW_ARGS"), "\\|", fixed = FALSE)[[1L]]
  if (length(integration_args) != 5L || any(!nzchar(integration_args))) {
    stop(paste("GLLVM_A4_S4_FROZEN_R_RAW_ARGS must be",
      "frozen-library|core070|output-rds|theta-csv|expected-build-receipt-sha256"),
      call. = FALSE)
  }
  status <- system2("Rscript", c("--vanilla", runner, integration_args))
  if (!identical(status, 0L)) stop("opt-in frozen-R raw integration failed", call. = FALSE)
  if (!file.exists(integration_args[[3L]]) || dir.exists(paste0(integration_args[[3L]], ".lock"))) {
    stop("opt-in frozen-R raw integration did not leave one immutable receipt", call. = FALSE)
  }
  live_receipt <- readRDS(integration_args[[3L]])
  stopifnot(
    identical(live_receipt$schema_version, "destination-b-a4-s4-frozen-r-raw-4"),
    identical(live_receipt$qualified, FALSE),
    identical(live_receipt$public_formula_admission, "closed"),
    identical(live_receipt$frozen$source_provenance, "verified_installed_marker"),
    all(vapply(live_receipt$rows, function(row) row$construction$optimization_performed,
      logical(1L)))
  )
}

cat("A4_S4_FROZEN_R_RAW_UNIT_OK\n")
