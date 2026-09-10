#!/usr/bin/env Rscript
# Exercise only the authorized adapter against the frozen reference namespace.
args <- commandArgs(trailingOnly=TRUE)
if(length(args)!=4L) stop("usage: export_adapter_fixtures.R LIB ADAPTER CORE070 OUTPUT")
lib <- normalizePath(args[1],mustWork=TRUE)
adapter <- normalizePath(args[2],mustWork=TRUE)
root <- normalizePath(args[3],mustWork=TRUE)
output <- args[4]
if(file.exists(output)) stop("refusing existing adapter receipt")
library("gllvmTMB",lib.loc=lib,character.only=TRUE)
sha <- function(p) unname(tools::sha256sum(p))[[1L]]
dll <- normalizePath(getLoadedDLLs()[["gllvmTMB"]][["path"]])
stopifnot(startsWith(dll,paste0(lib,"/")),
 sha(dll)=="91bfa6d90fbf3e4f42e1f4160583f2607f51a7839bb54a02a209da6e31a59beb")
env <- new.env(parent=asNamespace("gllvmTMB"))
sys.source(adapter,envir=env) # definitions only; no Julia initialization
load <- function(p) jsonlite::fromJSON(file.path(root,p))
tree <- load("destination-b-tree/r-fit-attempt-01.json")
ped <- load("destination-b-pedigree-fit/r-attempt-02.json")
dense <- load("destination-b-s3b-pilot/r-attempt-02.json")
sid <- rep(1:8,each=2L)
tree_input <- ape::read.tree(text=tree$precision$newick)
ped_Q <- Matrix::Matrix(ped$precision$Q_canonical,sparse=TRUE)
dimnames(ped_Q) <- rep(list(ped$precision$pedigree$node_labels),2)
dense_C <- dense$source_covariance$A_original
dimnames(dense_C) <- rep(list(dense$fixture$tip_order),2)
bundles <- list(
 tree=env$.gllvm_julia_prepare_phylo_source(tree$precision$observed_labels,sid,tree=tree_input),
 pedigree=env$.gllvm_julia_prepare_phylo_source(ped$precision$observed_labels,sid,vcv=ped_Q),
 dense=env$.gllvm_julia_prepare_phylo_source(dense$fixture$tip_order,sid,vcv=dense_C))
refs <- list(tree=tree$precision,pedigree=ped$precision,dense=dense$precision)
for(kind in names(bundles)) {
 p <- bundles[[kind]]$precision
 Q <- Matrix::sparseMatrix(i=p$i,j=p$j,x=p$x,dims=c(p$n_aug,p$n_aug))
 stopifnot(max(abs(as.matrix(Q)-refs[[kind]]$Q_canonical))<=1e-12,
  abs(p$log_det-refs[[kind]]$log_det_Q)<=1e-12,
  p$scale==refs[[kind]]$scale,identical(bundles[[kind]]$species_id,sid))
}
stopifnot(identical(bundles$tree$precision$species_aug_id,
 as.integer(tree$precision$species_node_one_based-1L)),
 identical(bundles$pedigree$precision$species_aug_id,
 as.integer(ped$precision$observed_node_one_based-1L)),
 identical(bundles$dense$precision$species_aug_id,
 as.integer(dense$precision$species_aug_id_by_tip_zero_based)))
receipt <- list(schema_version="destination-b-adapter-fixtures-1",qualified=FALSE,
 adapter_path=adapter,adapter_sha256=sha(adapter),dll_path=dll,dll_sha256=sha(dll),
 bundles=bundles,claim="actual R adapter payloads only; public admission remains closed")
jsonlite::write_json(receipt,output,pretty=TRUE,auto_unbox=TRUE,digits=17L)
cat("R_ADAPTER_THREE_FROZEN_FIXTURES_PASS\n",sha(output),"\n")
