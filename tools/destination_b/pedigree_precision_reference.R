#!/usr/bin/env Rscript
# Fixed, non-fitting export from the preserved R0.7.0 precision builder.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("usage: pedigree_precision_reference.R PRIVATE_LIBRARY OUTPUT_JSON")
lib <- normalizePath(args[[1L]], mustWork = TRUE)
output <- args[[2L]]
if (file.exists(output)) stop("refusing to overwrite an existing reference")
expected_sha <- "91bfa6d90fbf3e4f42e1f4160583f2607f51a7839bb54a02a209da6e31a59beb"
if ("gllvmTMB" %in% loadedNamespaces()) stop("start a fresh R process")
library("gllvmTMB", lib.loc = lib, character.only = TRUE)
stopifnot(as.character(packageVersion("gllvmTMB")) == "0.7.0")
package_path <- normalizePath(find.package("gllvmTMB"), mustWork = TRUE)
dll <- normalizePath(getLoadedDLLs()[["gllvmTMB"]][["path"]], mustWork = TRUE)
stopifnot(startsWith(package_path, paste0(lib, "/")), startsWith(dll, paste0(lib, "/")))
actual_sha <- unname(tools::sha256sum(dll))[[1L]]
stopifnot(identical(actual_sha, expected_sha))

sire <- c(0L, 0L, 0L, 0L, 1L, 1L, 2L, 2L, 5L, 7L, 9L, 9L)
dam <- c(0L, 0L, 0L, 0L, 3L, 3L, 4L, 4L, 6L, 8L, 10L, 6L)
ids <- paste0("i", seq_len(12L))
parent_labels <- function(index) ifelse(index == 0L, NA_character_, ids[pmax(index, 1L)])
ped <- data.frame(id = ids, sire = parent_labels(sire), dam = parent_labels(dam))
Q <- gllvmTMB::pedigree_to_Ainv_sparse(ped)
observed <- c(12L, 5L, 9L, 7L, 10L, 6L, 11L, 8L)
observed_ids <- ids[observed]
species_id <- rep(seq_along(observed) - 1L, each = 2L)
resolved <- getFromNamespace(".resolve_sparse_phylo_precision", "gllvmTMB")(
  Q, observed_ids, species_id)
transported <- resolved$Ainv_phy_rr
# determinant() may populate Matrix's factor cache. Compare exact canonical
# storage and labels, excluding that non-model cache, with no tolerance.
stopifnot(inherits(Q, "sparseMatrix"), nrow(Q) == 12L,
          identical(rownames(Q), ids),
          identical(transported@i, Q@i), identical(transported@p, Q@p),
          identical(transported@x, Q@x), identical(dim(transported), dim(Q)),
          identical(dimnames(transported), dimnames(Q)),
          resolved$n_aug_phy == 12L,
          identical(as.integer(resolved$species_aug_id), rep(observed - 1L, each = 2L)))
rows <- function(x) unname(lapply(seq_len(nrow(x)), function(i) unname(as.numeric(x[i, ]))))
receipt <- list(
  schema_version = "destination-b-pedigree-precision-1",
  source_pin = "b4d5fee64def88bc768dda1f1f77c29b295edd86",
  package_version = "0.7.0", package_path = package_path,
  dll_path = dll, dll_sha256 = actual_sha,
  session_info = paste(capture.output(sessionInfo()), collapse = "\n"),
  pedigree = list(node_labels = ids, sire_one_based_zero_unknown = sire,
                  dam_one_based_zero_unknown = dam),
  observed_node_one_based = observed, observed_labels = observed_ids,
  matrix_species_id_zero_based = species_id,
  matrix_augmented_id_zero_based = as.integer(resolved$species_aug_id),
  Q_canonical = rows(as.matrix(Q)), n_aug = nrow(Q), n_observed = length(observed),
  log_det_Q = -as.numeric(resolved$log_det_A_phy_rr), scale = 1,
  ridge_applied = FALSE, fit_performed = FALSE,
  claim = "precision transport only; no fit, interval, recovery or admission")
jsonlite::write_json(receipt, output, auto_unbox = TRUE, pretty = TRUE,
                     digits = 17L, null = "null", na = "null")
readback <- jsonlite::fromJSON(output)
stopifnot(identical(unname(readback$Q_canonical), unname(as.matrix(Q))))
cat("FROZEN_PEDIGREE_PRECISION_EXPORT_PASS\n")
cat(unname(tools::sha256sum(output)), "\n")
