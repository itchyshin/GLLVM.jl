# Pure receipt-target predicate shared by the one-control runner and its I/O test.
# `Sys.readlink()` is NA for an absent ordinary path, so guard it explicitly.

b1_balanced_control_output_occupied <- function(path) {
  link_target <- Sys.readlink(path)
  isTRUE(file.exists(path)) || (!is.na(link_target) && nzchar(link_target))
}
