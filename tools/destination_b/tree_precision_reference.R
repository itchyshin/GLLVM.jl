#!/usr/bin/env Rscript
# Non-fitting frozen tree export; no R source edits or independent inversion.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("usage: tree_precision_reference.R PRIVATE_LIBRARY OUTPUT_JSON")
lib <- normalizePath(args[[1L]], mustWork = TRUE)
output <- args[[2L]]
if (file.exists(output)) stop("refusing to overwrite an existing reference")
if ("gllvmTMB" %in% loadedNamespaces()) stop("start a fresh R process")
library("gllvmTMB", lib.loc = lib, character.only = TRUE)
package_path <- normalizePath(find.package("gllvmTMB"), mustWork = TRUE)
dll <- normalizePath(getLoadedDLLs()[["gllvmTMB"]][["path"]], mustWork = TRUE)
sha <- unname(tools::sha256sum(dll))[[1L]]
stopifnot(as.character(packageVersion("gllvmTMB")) == "0.7.0",
          startsWith(package_path, paste0(lib, "/")),
          startsWith(dll, paste0(lib, "/")),
          sha == "91bfa6d90fbf3e4f42e1f4160583f2607f51a7839bb54a02a209da6e31a59beb")
newick <- "(((s1:2,s2:2):1,(s3:1,s4:1):2):1,((s5:1.5,s6:1.5):1,(s7:1,s8:1):1.5):1.5);"
tree <- ape::read.tree(text = newick)
observed <- c("s8", "s1", "s6", "s3", "s7", "s2", "s5", "s4")
species <- factor(rep(observed, each = 2L), levels = observed)
builder <- getFromNamespace(".gllvm_phylo_tree_precision", "gllvmTMB")
correlated <- builder(tree, species = species, correlation = TRUE)
native <- builder(tree, species = species, correlation = FALSE)
stopifnot(correlated$height == 4, correlated$scale == 4,
          nrow(correlated$precision) == 14L,
          identical(as.matrix(correlated$precision), 4 * as.matrix(native$precision)))
bad_tree <- tree
bad_tree$edge.length[[1L]] <- bad_tree$edge.length[[1L]] + 0.25
rejection <- tryCatch({ builder(bad_tree, correlation = TRUE); NULL },
                      error = function(e) conditionMessage(e))
stopifnot(is.character(rejection), length(rejection) == 1L)
rows <- function(x) unname(lapply(seq_len(nrow(x)), function(i) unname(as.numeric(x[i, ]))))
receipt <- list(schema_version = "destination-b-tree-precision-1",
  source_pin = "b4d5fee64def88bc768dda1f1f77c29b295edd86",
  package_version = "0.7.0", package_path = package_path,
  dll_path = dll, dll_sha256 = sha,
  session_info = paste(capture.output(sessionInfo()), collapse = "\n"),
  newick = newick, edge = rows(tree$edge), edge_length = tree$edge.length,
  tip_labels = tree$tip.label, root = correlated$root,
  included_node_ids = correlated$node_id, node_labels = correlated$node_labels,
  observed_labels = observed,
  species_node_one_based = unname(correlated$species_node_index),
  observation_species_one_based = unname(correlated$observation_species_index),
  Q_canonical = rows(as.matrix(correlated$precision)),
  log_det_Q = correlated$log_det_precision, scale = correlated$scale,
  height = correlated$height, n_aug = nrow(correlated$precision),
  non_ultrametric_rejection = rejection, ridge_applied = FALSE,
  fit_performed = FALSE, qualified = FALSE)
jsonlite::write_json(receipt, output, auto_unbox = TRUE, pretty = TRUE,
                     digits = 17L, null = "null", na = "null")
readback <- jsonlite::fromJSON(output)
stopifnot(identical(unname(readback$Q_canonical), unname(as.matrix(correlated$precision))))
cat("FROZEN_TREE_PRECISION_EXPORT_PASS\n", unname(tools::sha256sum(output)), "\n")
