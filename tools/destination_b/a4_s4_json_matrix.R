# Decode a JSON array-of-rows response without relying on jsonlite's optional
# matrix simplification.  This intentionally accepts only rectangular, finite
# numeric rows so the caller can enforce its model-specific dimensions.
a4_s4_decode_json_matrix <- function(payload, label = "JSON matrix") {
  if (!is.list(payload) || !length(payload)) {
    stop(sprintf("%s must be a nonempty list of rows", label), call. = FALSE)
  }
  rows <- lapply(payload, function(row) {
    if (is.atomic(row) && is.numeric(row)) return(as.numeric(row))
    if (is.list(row) && all(vapply(row, function(value)
        is.atomic(value) && is.numeric(value) && length(value) == 1L, logical(1)))) {
      return(unlist(row, use.names = FALSE))
    }
    stop(sprintf("%s rows must be numeric vectors or scalar lists", label), call. = FALSE)
  })
  widths <- vapply(rows, length, integer(1))
  if (any(widths < 1L) || length(unique(widths)) != 1L) {
    stop(sprintf("%s must have nonempty, equal-length rows", label), call. = FALSE)
  }
  values <- unlist(rows, use.names = FALSE)
  if (!is.numeric(values) || any(!is.finite(values))) {
    stop(sprintf("%s must contain finite numeric values", label), call. = FALSE)
  }
  matrix(as.numeric(values), nrow = length(payload), ncol = widths[[1L]], byrow = TRUE)
}

a4_s4_reference_paths <- function(core070) {
  c(
    tree = file.path(core070, "destination-b-tree", "r-bfgs-attempt-01.json"),
    pedigree = file.path(core070, "destination-b-pedigree-fit", "r-bfgs-attempt-01.json"),
    dense = file.path(core070, "destination-b-s3b-pilot", "r-attempt-02.json")
  )
}

a4_s4_frozen_source_pin <- "b4d5fee64def88bc768dda1f1f77c29b295edd86"
a4_s4_frozen_dll_sha256 <- "91bfa6d90fbf3e4f42e1f4160583f2607f51a7839bb54a02a209da6e31a59beb"
a4_s4_expected_data_sha256 <- c(
  tree = "a096e8a4f4408923ea0e906defef936f133b92b65202a9baac9fff0d197373c2",
  pedigree = "025d9ca79375962ef4110c3ce62f84b30cdeea2939957e03f7235e2352e5142b",
  dense = "e33fcb6d2b391e70b1a8a19d8285c6d0205bdf80d97f35c65d82395d9eef3243"
)
a4_s4_reference_file_sha256 <- c(
  tree = "08c2c0f8dca3bb601e716da30d64dae2cd0ce3834766fa557dabb0444ddf4bd7",
  pedigree = "55ebb6e89461dcb6693d2b70d8c845d6ec1c1c3447fbaf20c6c58caaf9f221d3",
  dense = "5166bd887d8e85a962d551fd8670bc6f095d7b7cfff22d927b04cba34f3b981f"
)
a4_s4_fixture_file_sha256 <- "089f87d0dcf3c1014fc99646953d8696a0d5aa747287561dd815b5b8bf097549"
a4_s4_precision_source_sha256 <- c(
  tree = "ab01ee47206565eb1af7da391af313953b8a97c6bb11d9b6160655aaa0429170",
  pedigree = "c428e369e6fb554cc4b9bb03f250418d0d51474ba86e01d1be9c7c7301e615ee",
  dense = "5166bd887d8e85a962d551fd8670bc6f095d7b7cfff22d927b04cba34f3b981f"
)
a4_s4_expected_n_aug <- c(tree = 14L, pedigree = 12L, dense = 8L)
a4_s4_expected_species_aug_id <- list(
  tree = c(13L, 6L, 11L, 8L, 12L, 7L, 10L, 9L),
  pedigree = c(11L, 4L, 8L, 6L, 9L, 5L, 10L, 7L),
  dense = 0:7
)
a4_s4_expected_log_det <- c(tree = 15.706819081565975,
  pedigree = 5.966390909555864, dense = 7.861154398716261)
a4_s4_expected_scale <- c(tree = 4, pedigree = 1, dense = 1)
a4_s4_dense_ridge_operation <- "A_ridged = A_original + 1e-8 * I; Q_canonical = solve(A_ridged)"

a4_s4_sha256 <- function(value, label) {
  if (!is.character(value) || length(value) != 1L || !grepl("^[0-9a-f]{64}$", value)) {
    stop(sprintf("%s must be a lowercase SHA-256", label), call. = FALSE)
  }
  value
}

a4_s4_file_sha256 <- function(path, label) {
  if (!file.exists(path)) stop(sprintf("%s does not exist", label), call. = FALSE)
  a4_s4_sha256(unname(tools::sha256sum(path))[[1L]], label)
}

a4_s4_response_sha256 <- function(Y) {
  if (!is.matrix(Y) || !is.numeric(Y) || any(!is.finite(Y))) {
    stop("response hash requires a finite numeric matrix", call. = FALSE)
  }
  digest::digest(writeBin(as.double(c(Y)), raw(), size = 8L, endian = "little"),
    algo = "sha256", serialize = FALSE)
}

a4_s4_precision_source_paths <- function(core070) {
  c(
    tree = file.path(core070, "destination-b-tree", "precision-reference.json"),
    pedigree = file.path(core070, "destination-b-pedigree", "precision-reference.json"),
    dense = file.path(core070, "destination-b-s3b-pilot", "r-attempt-02.json")
  )
}

a4_s4_finite_scalar <- function(value, label) {
  values <- unlist(value, recursive = TRUE, use.names = FALSE)
  if (!is.numeric(values) || length(values) != 1L || !is.finite(values)) {
    stop(sprintf("%s must be one finite number", label), call. = FALSE)
  }
  as.double(values[[1L]])
}

a4_s4_integer_vector <- function(value, label, lower, upper) {
  values <- unlist(value, recursive = TRUE, use.names = FALSE)
  if (!length(values) || !is.numeric(values) || any(!is.finite(values)) ||
      any(values != floor(values)) || any(values < lower) || any(values > upper)) {
    stop(sprintf("%s must contain finite integer values in [%s, %s]", label, lower, upper),
      call. = FALSE)
  }
  as.integer(values)
}

a4_s4_positive_integer <- function(value, label) {
  values <- a4_s4_integer_vector(value, label, 1L, .Machine$integer.max)
  if (length(values) != 1L) {
    stop(sprintf("%s must be one positive integer", label), call. = FALSE)
  }
  values[[1L]]
}

# Materialize all retained inputs before Julia setup.  This preflight is an R
# boundary only: it decodes JSON, checks the fixed response shape, and proves
# the observation-to-species map can be applied without asking Julia to load.
a4_s4_preflight_payloads <- function(core070, fixtures_path = NULL, reference_paths = NULL) {
  if (!requireNamespace("jsonlite", quietly = TRUE) || !requireNamespace("digest", quietly = TRUE)) {
    stop("jsonlite and digest are required for A4/S4 JSON preflight", call. = FALSE)
  }
  core070 <- normalizePath(core070, mustWork = TRUE)
  if (is.null(fixtures_path)) fixtures_path <- file.path(core070, "destination-b-adapter", "fixtures-01.json")
  if (is.null(reference_paths)) reference_paths <- a4_s4_reference_paths(core070)
  kinds <- c("tree", "pedigree", "dense")
  if (!setequal(names(reference_paths), kinds) || any(!file.exists(reference_paths))) {
    stop("A4/S4 preflight requires named tree, pedigree, and dense references", call. = FALSE)
  }
  a4_s4_file_sha256(fixtures_path, "retained fixture") == a4_s4_fixture_file_sha256 ||
    stop("retained fixture bytes differ from the frozen artifact", call. = FALSE)
  precision_source_paths <- a4_s4_precision_source_paths(core070)
  for (kind in kinds) {
    a4_s4_file_sha256(reference_paths[[kind]], sprintf("%s retained reference", kind)) ==
      a4_s4_reference_file_sha256[[kind]] ||
      stop(sprintf("%s retained reference bytes differ from the frozen artifact", kind), call. = FALSE)
    a4_s4_file_sha256(precision_source_paths[[kind]], sprintf("%s precision source", kind)) ==
      a4_s4_precision_source_sha256[[kind]] ||
      stop(sprintf("%s precision source bytes differ from the frozen artifact", kind), call. = FALSE)
  }
  fixtures <- jsonlite::fromJSON(fixtures_path, simplifyVector = FALSE)
  if (!is.list(fixtures$bundles) || !all(kinds %in% names(fixtures$bundles))) {
    stop("the retained fixture bundle does not contain tree, pedigree, and dense rows", call. = FALSE)
  }
  payloads <- lapply(kinds, function(kind) {
    reference_path <- reference_paths[[kind]]
    reference <- jsonlite::fromJSON(reference_path, simplifyVector = FALSE)
    response <- if (identical(kind, "dense")) reference$response$Y_traits_by_observations else
      reference$Y_traits_by_observations
    Y <- a4_s4_decode_json_matrix(response, sprintf("%s retained response", kind))
    if (!identical(dim(Y), c(3L, 16L)) || any(!is.finite(Y))) {
      stop(sprintf("%s retained response must be a finite 3-by-16 numeric matrix", kind), call. = FALSE)
    }
    source_pin <- if (identical(kind, "dense")) reference$provenance$frozen_source_pin else reference$source_pin
    dll_sha256 <- if (identical(kind, "dense")) reference$provenance$dll_sha256 else reference$dll_sha256
    data_sha256 <- if (identical(kind, "dense")) reference$response$data_sha256 else reference$data_sha256
    if (!identical(source_pin, a4_s4_frozen_source_pin) ||
        !identical(dll_sha256, a4_s4_frozen_dll_sha256)) {
      stop(sprintf("%s retained reference does not name the frozen R source/DLL", kind), call. = FALSE)
    }
    a4_s4_sha256(data_sha256, sprintf("%s retained data hash", kind)) == a4_s4_expected_data_sha256[[kind]] ||
      stop(sprintf("%s retained data hash differs from its frozen reference", kind), call. = FALSE)
    a4_s4_response_sha256(Y) == a4_s4_expected_data_sha256[[kind]] ||
      stop(sprintf("%s decoded response bytes differ from its frozen reference", kind), call. = FALSE)
    ridge_operation <- NULL
    if (identical(kind, "dense")) {
      ridge_operation <- reference$source_covariance$ridge_operation
      if (!identical(ridge_operation, a4_s4_dense_ridge_operation)) {
        stop("dense retained source does not document the canonical one-ridge operation", call. = FALSE)
      }
    }
    bundle <- fixtures$bundles[[kind]]
    if (!is.list(bundle) || !is.list(bundle$precision)) {
      stop(sprintf("%s retained fixture lacks a precision payload", kind), call. = FALSE)
    }
    precision <- bundle$precision
    n_leaves <- a4_s4_positive_integer(precision$n_leaves, sprintf("%s n_leaves", kind))
    n_aug <- a4_s4_positive_integer(precision$n_aug, sprintf("%s n_aug", kind))
    if (n_aug < n_leaves) {
      stop(sprintf("%s retained fixture has fewer augmented nodes than leaves", kind), call. = FALSE)
    }
    species_id <- a4_s4_integer_vector(bundle$species_id, sprintf("%s species_id", kind), 1L, n_leaves)
    species_aug_id <- a4_s4_integer_vector(precision$species_aug_id,
      sprintf("%s species_aug_id", kind), 0L, n_aug - 1L)
    if (length(species_id) != ncol(Y) || length(species_aug_id) != n_leaves ||
        length(unique(species_aug_id)) != n_leaves) {
      stop(sprintf("%s retained fixture has no valid observation-level species map", kind), call. = FALSE)
    }
    log_det <- a4_s4_finite_scalar(precision$log_det, sprintf("%s log_det", kind))
    scale <- a4_s4_finite_scalar(precision$scale, sprintf("%s scale", kind))
    if (n_aug != a4_s4_expected_n_aug[[kind]] ||
        !identical(species_aug_id, a4_s4_expected_species_aug_id[[kind]]) ||
        !isTRUE(all.equal(log_det, a4_s4_expected_log_det[[kind]], tolerance = 1e-14)) ||
        !isTRUE(all.equal(scale, a4_s4_expected_scale[[kind]], tolerance = 0))) {
      stop(sprintf("%s precision payload differs from the frozen canonical Q identity", kind), call. = FALSE)
    }
    list(reference_path = reference_path, reference = reference, bundle = bundle,
      precision = precision, Y = Y, species_id = species_id, source_pin = source_pin,
      dll_sha256 = dll_sha256, data_sha256 = data_sha256, ridge_operation = ridge_operation)
  })
  names(payloads) <- kinds
  payloads
}
