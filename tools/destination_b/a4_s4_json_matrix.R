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
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("jsonlite is required for A4/S4 JSON preflight", call. = FALSE)
  }
  core070 <- normalizePath(core070, mustWork = TRUE)
  if (is.null(fixtures_path)) fixtures_path <- file.path(core070, "destination-b-adapter", "fixtures-01.json")
  if (is.null(reference_paths)) reference_paths <- a4_s4_reference_paths(core070)
  kinds <- c("tree", "pedigree", "dense")
  if (!setequal(names(reference_paths), kinds) || any(!file.exists(reference_paths))) {
    stop("A4/S4 preflight requires named tree, pedigree, and dense references", call. = FALSE)
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
    list(reference_path = reference_path, reference = reference, bundle = bundle,
      precision = precision, Y = Y, species_id = species_id)
  })
  names(payloads) <- kinds
  payloads
}
