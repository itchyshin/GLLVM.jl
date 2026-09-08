helper <- file.path("tools", "destination_b", "a4_s4_json_matrix.R")
source(helper)

expect_error <- function(expression, label) {
  failed <- FALSE
  tryCatch(force(expression), error = function(error) failed <<- TRUE)
  if (!failed) stop(sprintf("expected decoder failure for %s", label), call. = FALSE)
}

reference_paths <- c(
  tree = file.path("docs", "dev-log", "core070", "destination-b-tree", "r-bfgs-attempt-01.json"),
  pedigree = file.path("docs", "dev-log", "core070", "destination-b-pedigree-fit", "r-bfgs-attempt-01.json"),
  dense = file.path("docs", "dev-log", "core070", "destination-b-s3b-pilot", "r-attempt-02.json")
)
expected_first <- c(
  tree = -0.578147955781614,
  pedigree = -0.468356678610928,
  dense = -0.204875288969302
)

for (kind in names(reference_paths)) {
  reference <- jsonlite::fromJSON(reference_paths[[kind]], simplifyVector = FALSE)
  payload <- if (identical(kind, "dense")) reference$response$Y_traits_by_observations else
    reference$Y_traits_by_observations
  Y <- a4_s4_decode_json_matrix(payload, sprintf("%s retained response", kind))
  stopifnot(is.matrix(Y), is.numeric(Y), identical(dim(Y), c(3L, 16L)),
    all(is.finite(Y)), isTRUE(all.equal(Y[1L, 1L], expected_first[[kind]], tolerance = 1e-14)))
}

core070 <- file.path("docs", "dev-log", "core070")
preflight <- a4_s4_preflight_payloads(core070)
stopifnot(identical(sort(names(preflight)), c("dense", "pedigree", "tree")))
for (kind in names(preflight)) {
  stopifnot(is.matrix(preflight[[kind]]$Y), is.numeric(preflight[[kind]]$Y),
    identical(dim(preflight[[kind]]$Y), c(3L, 16L)),
    length(preflight[[kind]]$species_id) == 16L)
}

bad_fixture <- jsonlite::fromJSON(file.path(core070, "destination-b-adapter", "fixtures-01.json"),
  simplifyVector = FALSE)
bad_fixture$bundles$tree$species_id <- bad_fixture$bundles$tree$species_id[-1L]
bad_fixture_path <- tempfile(fileext = ".json")
jsonlite::write_json(bad_fixture, bad_fixture_path, auto_unbox = TRUE)
expect_error(a4_s4_preflight_payloads(core070, fixtures_path = bad_fixture_path), "malformed fixture")

bad_reference_path <- tempfile(fileext = ".json")
jsonlite::write_json(list(Y_traits_by_observations = list(list(1, 2), list(3))),
  bad_reference_path, auto_unbox = TRUE)
bad_references <- reference_paths
bad_references[["tree"]] <- bad_reference_path
expect_error(a4_s4_preflight_payloads(core070, reference_paths = bad_references), "malformed reference")

write_mutated_reference <- function(path, mutate) {
  reference <- mutate(jsonlite::fromJSON(path, simplifyVector = FALSE))
  output <- tempfile(fileext = ".json")
  jsonlite::write_json(reference, output, auto_unbox = TRUE, digits = 17)
  output
}
bad_source_path <- write_mutated_reference(reference_paths[["tree"]], function(reference) {
  reference$source_pin <- strrep("0", 40L)
  reference
})
bad_references <- reference_paths
bad_references[["tree"]] <- bad_source_path
expect_error(a4_s4_preflight_payloads(core070, reference_paths = bad_references), "source pin")

bad_dll_path <- write_mutated_reference(reference_paths[["pedigree"]], function(reference) {
  reference$dll_sha256 <- strrep("0", 64L)
  reference
})
bad_references <- reference_paths
bad_references[["pedigree"]] <- bad_dll_path
expect_error(a4_s4_preflight_payloads(core070, reference_paths = bad_references), "DLL hash")

bad_data_path <- write_mutated_reference(reference_paths[["tree"]], function(reference) {
  reference$data_sha256 <- strrep("0", 64L)
  reference
})
bad_references <- reference_paths
bad_references[["tree"]] <- bad_data_path
expect_error(a4_s4_preflight_payloads(core070, reference_paths = bad_references), "data hash")

bad_ridge_path <- write_mutated_reference(reference_paths[["dense"]], function(reference) {
  reference$source_covariance$ridge_operation <- "A + 1e-8 I"
  reference
})
bad_references <- reference_paths
bad_references[["dense"]] <- bad_ridge_path
expect_error(a4_s4_preflight_payloads(core070, reference_paths = bad_references), "dense ridge operation")

expect_error(a4_s4_decode_json_matrix(list(c(1, 2), c(3)), "ragged"), "ragged rows")
expect_error(a4_s4_decode_json_matrix(list(c(1, 2), c("x", "y")), "nonnumeric"), "nonnumeric rows")
expect_error(a4_s4_decode_json_matrix(1, "malformed"), "non-list payload")

cat("A4_S4_JSON_MATRIX_OK\n")
