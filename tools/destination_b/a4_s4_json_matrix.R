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
