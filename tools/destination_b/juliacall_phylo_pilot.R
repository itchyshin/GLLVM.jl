#!/usr/bin/env Rscript
# Actual JuliaCall transport; no public R phylo_rr admission implied.
args <- commandArgs(trailingOnly=TRUE)
if(length(args)!=4L) stop("usage: juliacall_phylo_pilot.R JULIA_BIN PROJECT CORE070 OUTPUT")
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
dense <- jsonlite::fromJSON(file.path(root,"destination-b-s3b-pilot/r-attempt-02.json"))
expected <- jsonlite::fromJSON(file.path(root,"destination-b-adapter/dense-result.json"))$result
receipt <- list(status="error",qualified=FALSE,stage="setup",warnings=list())
receipt$environment_path <- project
receipt$environment_sha256 <- as.list(unname(tools::sha256sum(file.path(project,c("Project.toml","Manifest.toml")))))
tryCatch({
 JuliaCall::julia_setup(JULIA_HOME=args[1],installJulia=FALSE,install=FALSE,rebuild=FALSE,verbose=FALSE)
 JuliaCall::julia_command(sprintf("import Pkg; Pkg.activate(%s); using GLLVM",encodeString(normalizePath(args[2]),quote='"')))
 receipt$stage <- "fit"
 started <- proc.time()[["elapsed"]]
 result <- JuliaCall::julia_call("GLLVM.bridge_fit",y=dense$response$Y_traits_by_observations,
  family="gaussian",d=1L,phylo=fixtures$bundles$dense$precision,
  options=list(phylo_model="multivariate",mode="barelowrank",residual_mode="shared",
   species_id=as.integer(fixtures$bundles$dense$species_id),ci_method="wald",g_tol=1e-5,iterations=400L))
 receipt$elapsed_fit_seconds <- proc.time()[["elapsed"]]-started
 receipt$result <- result
 receipt$stage <- "returned_before_assertions"
 saveRDS(receipt,paste0(output,".rds"))
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
