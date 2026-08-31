# No installs, original fixtures, all attempts retained before acceptance.
source("tools/core070_bridge_runtime.R")
source("tools/core070_bridge_receipt.R")
suppressPackageStartupMessages(library(gllvmTMB))
JuliaCall::julia_command('include("tools/core070_bridge_models.jl")')
fixtures <- jsonlite::read_json("bridge-fixtures.json",simplifyVector=FALSE)
contract_path <- "docs/dev-log/core070/public-bridge-required-cases.json"
contract <- jsonlite::read_json(contract_path,simplifyVector=FALSE)
required_ids <- unlist(contract$required_case_ids,use.names=FALSE)
stopifnot(identical(contract$reference_commit,"b4d5fee64def88bc768dda1f1f77c29b295edd86"),
    identical(vapply(fixtures,function(f) f$id,character(1)),required_ids),
    identical(vapply(fixtures,function(f) f$family,character(1)),c("poisson","beta","nb2")))
cat("BRIDGE_REQUIRED_CONTRACT_SHA256",system2("sha256sum",contract_path,stdout=TRUE),"\n")
attempts <- list()
capture <- function(expr) {
    warnings <- character()
    value <- tryCatch(withCallingHandlers(expr,warning=function(w) {
        warnings <<- c(warnings,conditionMessage(w)); invokeRestart("muffleWarning")
    }),error=function(e) structure(list(error=conditionMessage(e)),class="bridge_error"))
    list(value=value,warnings=warnings,error=if(inherits(value,"bridge_error")) value$error else NULL)
}
maxdiff <- function(x,y) max(abs(as.numeric(x)-as.numeric(y)))
for (f in fixtures) {
    family <- f$family; p <- f$p; n <- f$n; K <- f$K
    Y <- matrix(unlist(f$Y),p,n)
    dimnames(Y) <- list(sprintf("trait%02d",seq_len(p)),sprintf("site%03d",seq_len(n)))
    data <- expand.grid(trait=rownames(Y),site=colnames(Y));data$value<-as.vector(Y)
    data$trait<-factor(data$trait,levels=rownames(Y));data$site<-factor(data$site,levels=colnames(Y))
    fam <- switch(family,poisson=poisson(),beta=gllvmTMB::Beta(),nb2=gllvmTMB::nbinom2())
    native <- capture(JuliaCall::julia_call("core070_bridge_native",Y,family,as.integer(K)))
    matrix_fit <- capture(gllvmTMB::gllvm_julia_fit(Y,family=fam,num.lv=K,ci_method="none"))
    formula_fit <- capture(gllvmTMB::gllvmTMB(
        value~0+trait+latent(0+trait|site,d=K,unique=FALSE),
        data=data[nrow(data):1,],unit="site",trait="trait",family=fam,
        engine="julia",ci_method="none"))
    checks <- list(no_errors=is.null(native$error)&&is.null(matrix_fit$error)&&is.null(formula_fit$error))
    comparisons <- list()
    if (checks$no_errors) {
        ref<-native$value
        checks$native_health<-isTRUE(ref$converged)&&ref$gradient_max<=1e-4&&
            ref$fd_stability<=1e-4&&ref$objective_delta<=1e-8
        checks$data_identity<-identical(ref$data_sha256,f$data_sha256)
        checks$prior_r_health<-f$prior_r_gradient_max<=1e-4
        for (route in c("matrix","formula")) {
            fit<-if(route=="matrix") matrix_fit$value else formula_fit$value
            L<-as.matrix(fit$loadings)
            delta<-list(loglik=abs(as.numeric(logLik(fit))-ref$loglik),
                alpha=maxdiff(fit$alpha,ref$alpha),
                shared_covariance=maxdiff(tcrossprod(L),ref$shared_covariance),
                dispersion=if(family=="poisson") 0 else max(abs(as.numeric(fit$dispersion)/as.numeric(ref$dispersion)-1)),
                prior_r_loglik=abs(as.numeric(logLik(fit))-f$prior_r_loglik))
            comparisons[[route]]<-delta
            checks[[route]]<-inherits(fit,"gllvmTMB_julia")&&isTRUE(fit$converged)&&
                fit$n_traits==p&&fit$n_units==n&&fit$d==K&&fit$df==ref$df&&
                delta$loglik<=1e-8&&delta$alpha<=1e-8&&delta$shared_covariance<=1e-8&&
                delta$dispersion<=1e-8&&delta$prior_r_loglik<=1e-6*abs(f$prior_r_loglik)
        }
    }
    attempts[[family]]<-list(fixture=f,native=native,matrix=matrix_fit,formula=formula_fit,
                             comparisons=comparisons,checks=checks)
    saveRDS(attempts,"bridge-model-attempts.rds")
    cat("BRIDGE_MODEL_ATTEMPT",family,jsonlite::toJSON(checks,auto_unbox=TRUE),"\n")
}
rejections<-list(
    truncated_nb2=capture(gllvmTMB::gllvm_julia_fit(Y,family=gllvmTMB::truncated_nbinom2(),num.lv=K)),
    explicit_diagonal=capture(gllvmTMB::gllvmTMB(
        value~0+trait+latent(0+trait|site,d=K,unique=FALSE)+indep(0+trait|site),
        data=data,unit="site",trait="trait",family=poisson(),engine="julia")))
rejection_checks<-list(truncated_nb2=grepl("GJL-GATE-FAMILY",rejections$truncated_nb2$error,fixed=TRUE),
    explicit_diagonal=grepl("GJL-GATE-STRUCTURED-TERMS",rejections$explicit_diagonal$error,fixed=TRUE))
result<-list(scope="ORIGINAL_PUBLIC_BRIDGE_REPLAY_NOT_RECOVERY",attempts=attempts,
             requested_case_ids=required_ids,
             completed_case_ids=vapply(attempts,function(a) if(core070_all_true(a$checks,
                 c("no_errors","native_health","data_identity","prior_r_health","matrix","formula")))
                 a$fixture$id else "FAILED",character(1),USE.NAMES=FALSE),
             rejections=rejections,rejection_checks=rejection_checks)
saveRDS(result,"bridge-model-results.rds")
jsonlite::write_json(core070_plain_receipt(result),"bridge-model-results.json",
                    auto_unbox=TRUE,pretty=TRUE,digits=NA,null="null")
cat("BRIDGE_MODEL_RESULTS_SHA256",system2("sha256sum","bridge-model-results.json",stdout=TRUE),"\n")
stopifnot(identical(names(attempts),c("poisson","beta","nb2")),
    all(vapply(attempts,function(a) core070_all_true(a$checks,
        c("no_errors","native_health","data_identity","prior_r_health","matrix","formula")),logical(1))),
    core070_all_true(rejection_checks,c("truncated_nb2","explicit_diagonal")))
cat("CORE070_PUBLIC_BRIDGE_MODELS_PASS\n")
