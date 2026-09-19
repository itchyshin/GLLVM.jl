#!/usr/bin/env Rscript
# Actual JuliaCall transport; no public R phylo_rr admission implied.
args <- commandArgs(trailingOnly=TRUE)
if(!length(args) %in% c(4L,6L)) stop("usage: juliacall_phylo_pilot.R JULIA_BIN PROJECT CORE070 OUTPUT [KIND R_ADAPTER]")
kind <- if(length(args)==6L) args[5] else "dense"
if(!kind %in% c("dense","tree","pedigree")) stop("unknown fixture kind")
output <- args[4]
if(any(file.exists(c(output,paste0(output,".rds"))))) stop("refusing existing result or raw attempt")
script_path <- sub("^--file=","",commandArgs()[grepl("^--file=",commandArgs())][1L])
source(file.path(dirname(normalizePath(script_path)),"juliacall_phylo_readback.R"))
root <- normalizePath(args[3],mustWork=TRUE)
project <- normalizePath(args[2],mustWork=TRUE)
startup_project <- Sys.getenv("JULIA_PROJECT","")
if(!nzchar(startup_project) || !identical(normalizePath(startup_project,mustWork=TRUE),project))
 stop("start JuliaCall in the target combined environment; do not switch loaded dependency versions")
fixtures <- jsonlite::fromJSON(file.path(root,"destination-b-adapter/fixtures-01.json"))
reference_relative <- switch(kind,dense="destination-b-s3b-pilot/r-attempt-02.json",
 tree="destination-b-tree/r-fit-attempt-01.json",pedigree="destination-b-pedigree-fit/r-attempt-02.json")
reference <- jsonlite::fromJSON(file.path(root,reference_relative))
Y <- if(kind=="dense") reference$response$Y_traits_by_observations else reference$Y_traits_by_observations
expected_path <- file.path(root,paste0("destination-b-adapter/",kind,"-result.json"))
expected <- jsonlite::fromJSON(expected_path)$result
receipt <- list(status="error",qualified=FALSE,stage="setup",warnings=list())
receipt$kind <- kind
receipt$input_sha256 <- as.list(unname(tools::sha256sum(c(file.path(root,reference_relative),expected_path,
 file.path(root,"destination-b-adapter/fixtures-01.json")))))
receipt$environment_path <- project
receipt$environment_sha256 <- as.list(unname(tools::sha256sum(file.path(project,c("Project.toml","Manifest.toml")))))
tryCatch({
 JuliaCall::julia_setup(JULIA_HOME=args[1],installJulia=FALSE,install=FALSE,rebuild=FALSE,verbose=FALSE)
 JuliaCall::julia_command(sprintf("import Pkg; Pkg.activate(%s); using GLLVModels",encodeString(normalizePath(args[2]),quote='"')))
 receipt$stage <- "fit"
 started <- proc.time()[["elapsed"]]
 result <- JuliaCall::julia_call("GLLVModels.bridge_fit",y=Y,
  family="gaussian",d=1L,phylo=fixtures$bundles[[kind]]$precision,
  options=list(phylo_model="multivariate",mode="barelowrank",residual_mode="shared",
   species_id=as.integer(fixtures$bundles[[kind]]$species_id),ci_method="wald",g_tol=1e-5,iterations=400L))
 receipt$elapsed_fit_seconds <- proc.time()[["elapsed"]]-started
 receipt$result <- result
 receipt$stage <- "returned_before_assertions"
 saveRDS(receipt,paste0(output,".rds"))
 if(length(args)==6L) {
  adapter_env <- new.env(parent=asNamespace("gllvmTMB"))
  sys.source(args[6],envir=adapter_env)
  normalized <- adapter_env$.gllvm_julia_normalise_precision_result(result,c("a","b","c"))
  stopifnot(nrow(normalized$intervals)==12L,all(normalized$intervals$status=="available"),
   identical(normalized$admission_status,"closed"),
   identical(rownames(normalized$loadings),c("a","b","c")))
  receipt$normalized_intervals <- normalized$intervals
  receipt$result_converter_sha256 <- unname(tools::sha256sum(args[6]))[[1L]]
  assembled <- adapter_env$.gllvm_julia_assemble_precision_result(result,Y)
  predicted <- adapter_env$fitted.gllvmTMB_julia(assembled)
  pp <- fixtures$bundles[[kind]]$precision
  Q <- Matrix::sparseMatrix(i=pp$i,j=pp$j,x=pp$x,dims=rep(pp$n_aug,2))
  nodes <- as.integer(result$species_aug_id)[as.integer(result$species_id)]
  C <- solve(as.matrix(Q))[nodes,nodes,drop=FALSE]
  K <- kronecker(result$phylo_covariance,C)
  R <- kronecker(result$residual_covariance,diag(ncol(Y)))
  mu <- as.vector(t(matrix(result$mean_design %*% result$coefficients,nrow(Y),ncol(Y))))
  oracle <- t(matrix(mu+K %*% solve(K+R,as.vector(t(Y))-mu),ncol(Y),nrow(Y)))
  error <- max(abs(unname(predicted)-oracle))
  stopifnot(is.finite(error),error<=1e-8)
  receipt$conditional_prediction <- list(status="pass",max_abs_error=error,
    reference="independent dense K(K+R)^-1(y-Xbeta)+Xbeta",fitted_values=unname(predicted))
 }
 result <- destination_b_validate_juliacall_result(result,expected)
 receipt$result <- result
 stopifnot(isTRUE(result$converged),identical(result$admission_status,"closed"),
  abs(result$loglik-expected$loglik)<=1e-8,
  identical(as.integer(result$species_aug_id),as.integer(unlist(expected$species_aug_id))),
  identical(as.character(result$ci_target_names),as.character(unlist(expected$ci_target_names))),
  max(abs(result$ci_lower-unlist(expected$ci_lower)))<=1e-5,
  max(abs(result$ci_upper-unlist(expected$ci_upper)))<=1e-5,
  length(result$ci_target_names)==12L)
 receipt$status <- "pass"
 receipt$stage <- "raw_transport_verified"
 receipt$julia_version <- JuliaCall::julia_eval("string(VERSION)")
 receipt$JuliaCall_version <- as.character(packageVersion("JuliaCall"))
 jsonlite::write_json(receipt,output,auto_unbox=TRUE,pretty=TRUE,digits=17L,null="null")
 cat("JULIACALL_PHYLO_RAW_TRANSPORT_PASS\n")
},error=function(e){
 receipt$status <- "error"
 if(inherits(receipt$result,"JuliaNamedTuple")) receipt$result <- unclass(receipt$result)
 receipt$error <- conditionMessage(e)
 jsonlite::write_json(receipt,output,auto_unbox=TRUE,pretty=TRUE,digits=17L,null="null")
 stop(e)
})
