#!/usr/bin/env Rscript
# No fits: exercise registered S3 methods against retained actual JuliaCall output.
args <- commandArgs(trailingOnly=TRUE)
if(!length(args) %in% c(4L,5L)) stop(paste(
  "usage: test_installed_precision_readers.R",
  "LIBRARY CORE070 RAW_DIRECTORY [CONTROLLED_DIRECTORY] OUTPUT"))
controlled_directory <- if(length(args)==5L) normalizePath(args[4],mustWork=TRUE) else NULL
output_path <- args[[length(args)]]
if(file.exists(output_path)) stop("refusing to overwrite receipt")
.libPaths(c(normalizePath(args[1]),.libPaths()))
library(gllvmTMB)
stopifnot(normalizePath(find.package("gllvmTMB"))==normalizePath(file.path(args[1],"gllvmTMB")))
package_path <- find.package("gllvmTMB")
installed_artifacts <- c(
  r_loader=file.path(package_path,"R","gllvmTMB"),
  r_database=file.path(package_path,"R","gllvmTMB.rdb"),
  r_index=file.path(package_path,"R","gllvmTMB.rdx"),
  description=file.path(package_path,"DESCRIPTION")
)
stopifnot(all(file.exists(installed_artifacts)))
receipt <- list(status="error",qualified=FALSE,library=normalizePath(args[1]),
  package_version=as.character(packageVersion("gllvmTMB")),
  installed_package=as.list(stats::setNames(
    unname(tools::sha256sum(unname(installed_artifacts))),names(installed_artifacts))),
  cases=list())
tryCatch({
  dll <- file.path(find.package("gllvmTMB"),"libs","gllvmTMB.so")
  receipt$dll_sha256 <- unname(tools::sha256sum(dll))[[1L]]
  stopifnot(receipt$dll_sha256=="91bfa6d90fbf3e4f42e1f4160583f2607f51a7839bb54a02a209da6e31a59beb")
  for(kind in c("tree","pedigree","dense")) {
    raw_path <- file.path(args[3],paste0("juliacall-",kind,"-02.json.rds"))
    raw <- readRDS(raw_path)$result
    rel <- switch(kind,tree="destination-b-tree/r-fit-attempt-01.json",
      pedigree="destination-b-pedigree-fit/r-attempt-02.json",
      dense="destination-b-s3b-pilot/r-attempt-02.json")
    ref_path <- file.path(args[2],rel)
    ref <- jsonlite::fromJSON(ref_path)
    y <- if(kind=="dense") ref$response$Y_traits_by_observations else ref$Y_traits_by_observations
    object <- gllvmTMB:::.gllvm_julia_assemble_precision_result(raw,y)
    stopifnot(inherits(object,"gllvmTMB_julia"),length(coef(object)$mean_coef)==3L,
      attr(logLik(object),"df")==7L,nrow(confint(object))==12L)
    mu <- fitted(object)
    stopifnot(identical(unname(mu),unname(raw$fitted_values)),
      identical(predict(object)$est,as.vector(mu)),
      isTRUE(all.equal(unname(residuals(object)),unname(y-mu))),
      isTRUE(all.equal(unname(residuals(object,type="pearson")),
        unname((y-mu)/sqrt(raw$residual_variance)))))
    stopifnot(identical(summary(object)$covariance$phylogenetic,object$phylo_covariance),
      identical(summary(object)$status$admission_status,"closed"))
    draw <- simulate(object,nsim=2,seed=73)
    stopifnot(identical(dim(draw),c(length(y),2L)),all(is.finite(draw)),
      identical(draw,simulate(object,nsim=2,seed=73)))
    receipt$cases[[kind]] <- list(status="pass",n_intervals=nrow(confint(object)),
      n_predictions=length(mu),raw_sha256=unname(tools::sha256sum(raw_path))[[1L]],
      reference_sha256=unname(tools::sha256sum(ref_path))[[1L]])
  }
  if(!is.null(controlled_directory)) {
    receipt$controlled_dispatch <- list()
    for(kind in c("tree","pedigree","dense")) {
      dispatch_path <- file.path(controlled_directory,
        paste0("controlled-dispatch-",kind,"-03.json"))
      if(!file.exists(dispatch_path)) stop("missing controlled dispatch receipt for ",kind)
      dispatch <- jsonlite::fromJSON(dispatch_path)
      actual_julia_bin <- as.character(dispatch$actual_julia_bin)
      actual_julia_sha256 <- as.character(dispatch$actual_julia_bin_sha256)
      requested_julia_sha256 <- as.character(dispatch$input_hashes$requested_julia_bin)
      stopifnot(
        identical(dispatch$status,"pass"),
        identical(dispatch$admission_status,"closed"),
        identical(dispatch$ordinary_formula_gate,"rejected_before_julia_startup"),
        isTRUE(dispatch$candidate_opt_in),
        length(actual_julia_bin)==1L,
        file.exists(actual_julia_bin),
        identical(actual_julia_sha256,requested_julia_sha256),
        identical(unname(tools::sha256sum(actual_julia_bin))[[1L]],actual_julia_sha256)
      )
      receipt$controlled_dispatch[[kind]] <- list(
        receipt_sha256=unname(tools::sha256sum(dispatch_path))[[1L]],
        actual_julia_bin=actual_julia_bin,
        actual_julia_bin_sha256=actual_julia_sha256
      )
    }
  }
  receipt$status <- "pass"
  jsonlite::write_json(receipt,output_path,pretty=TRUE,auto_unbox=TRUE)
  cat("INSTALLED_PRECISION_READERS_PASS\n")
},error=function(e){
  receipt$error <- conditionMessage(e)
  jsonlite::write_json(receipt,output_path,pretty=TRUE,auto_unbox=TRUE)
  stop(e)
})
