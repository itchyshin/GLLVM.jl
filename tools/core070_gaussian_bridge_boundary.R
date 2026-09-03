# Frozen public-bridge behavior on original data; never unique-model parity.
source("tools/core070_bridge_runtime.R")
source("tools/core070_bridge_receipt.R")
suppressPackageStartupMessages(library(gllvmTMB))
f<-jsonlite::read_json("gaussian-bridge-fixture.json",simplifyVector=TRUE)
Y<-matrix(f$responses,f$p,f$n);K<-f$K
data<-expand.grid(trait=sprintf("trait%02d",seq_len(f$p)),site=sprintf("site%03d",seq_len(f$n)))
data$value<-as.vector(Y)
capture<-function(expr) {
    warnings<-character()
    value<-tryCatch(withCallingHandlers(expr,warning=function(w) {
        warnings<<-c(warnings,conditionMessage(w));invokeRestart("muffleWarning")
    }),error=function(e) structure(list(error=conditionMessage(e)),class="boundary_error"))
    list(value=value,warnings=warnings,error=if(inherits(value,"boundary_error")) value$error else NULL)
}
auto<-capture(gllvmTMB(value~0+latent(0+trait|site,d=K),data=data,
                      unit="site",trait="trait",family=gaussian(),engine="julia"))
explicit<-capture(gllvmTMB(value~0+latent(0+trait|site,d=K,unique=FALSE),data=data,
                          unit="site",trait="trait",family=gaussian(),engine="julia"))
checks<-list(no_errors=is.null(auto$error)&&is.null(explicit$error),
    auto_warning=any(grepl("Fitting the reduced-rank latent block only",auto$warnings,fixed=TRUE)),
    explicit_no_unique_warning=!any(grepl("trait-specific",explicit$warnings,fixed=TRUE)))
if(checks$no_errors) {
    a<-auto$value;b<-explicit$value
    residual<-as.matrix(a$Sigma)-tcrossprod(as.matrix(a$loadings))
    checks$same_reduced_fit<-abs(a$loglik-b$loglik)<=1e-10&&max(abs(a$Sigma-b$Sigma))<=1e-10
    checks$common_residual<-is.finite(a$sigma_eps)&&a$sigma_eps>0&&
        max(abs(residual-diag(a$sigma_eps^2,f$p)))<=1e-10
    checks$zero_mean<-max(abs(a$alpha))<=1e-10
    checks$changed_parameter_count<-a$df==f$p*K+1&&a$df!=2*f$p
    checks$converged<-isTRUE(a$converged)&&isTRUE(b$converged)
}
result<-list(scope="FROZEN_GAUSSIAN_BRIDGE_MODEL_CHANGE_NOT_PARITY",fixture=f,
             auto=auto,explicit=explicit,checks=checks)
saveRDS(result,"gaussian-boundary-results.rds")
jsonlite::write_json(core070_plain_receipt(result),"gaussian-boundary-results.json",
                    auto_unbox=TRUE,pretty=TRUE,digits=NA,null="null")
cat("GAUSSIAN_BOUNDARY_RESULTS_SHA256",system2("sha256sum","gaussian-boundary-results.json",stdout=TRUE),"\n")
print(checks)
stopifnot(core070_all_true(checks,c("no_errors","auto_warning","explicit_no_unique_warning",
    "same_reduced_fit","common_residual","zero_mean","changed_parameter_count","converged")))
cat("CORE070_GAUSSIAN_BRIDGE_BOUNDARY_PASS\n")
