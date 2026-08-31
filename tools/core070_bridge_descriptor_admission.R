# Pure frozen R bridge descriptor observation: no Julia startup and no fits.
lib<-"/home/snakagaw/core070-aghq-20260830/oracle-build-01/library"
.libPaths(c(lib,.libPaths()))
suppressPackageStartupMessages(library(gllvmTMB))
stopifnot(normalizePath(find.package("gllvmTMB"))==normalizePath(file.path(lib,"gllvmTMB")))
path<-"docs/dev-log/core070/bridge-descriptor-contract.json"
contract<-jsonlite::read_json(path,simplifyVector=FALSE)
stopifnot(identical(contract$reference_commit,"b4d5fee64def88bc768dda1f1f77c29b295edd86"),
          length(contract$cases)==69)
mapper<-getFromNamespace(".gllvm_julia_family","gllvmTMB")
stopifnot(!isTRUE(getFromNamespace(".gllvm_jl_env","gllvmTMB")$ready))
Y<-matrix(1,4,6)
negative_data<-expand.grid(trait=letters[1:4],site=seq_len(6))
negative_data$value<-as.vector(Y)
multinomial_data<-data.frame(value=factor(rep(letters[1:3],8)),
                            trait="response",site=seq_len(24))
known_rejection<-function(x) {
    grepl("GJL-GATE-FAMILY",x,fixed=TRUE) ||
        identical(x,"engine = 'julia': family must resolve to one supported family name.")
}
error_text<-function(expr) tryCatch({expr;"NO_ERROR"},error=conditionMessage)
rows<-lapply(contract$cases,function(c) {
    out<-c
    if(c$native_classification=="intentionally_excluded_constructor_only") {
        out$status<-"EXCLUDED_NOT_EVALUATED";return(out)
    }
    descriptor<-tryCatch(eval(parse(text=c$reference_descriptor_call)),error=function(e)e)
    if(inherits(descriptor,"error")) {
        out$status<-"DESCRIPTOR_ERROR";out$error<-conditionMessage(descriptor);return(out)
    }
    if(inherits(descriptor,"family")) {
        out$requested_family<-descriptor$family
        out$requested_link<-descriptor$link
    }
    result<-tryCatch(mapper(descriptor),error=function(e)e)
    if(inherits(result,"error")) {
        out$status<-"MAPPER_REJECTED";out$error<-conditionMessage(result)
        out$public_matrix_error<-error_text(gllvm_julia_fit(Y,family=descriptor,num.lv=1L))
        formula_data<-if(inherits(descriptor,"family") &&
            identical(descriptor$family,"multinomial")) multinomial_data else negative_data
        out$public_formula_fixture<-if(identical(formula_data,multinomial_data))
            "24_UNITS_THREE_CATEGORIES" else "4_TRAITS_6_UNITS"
        out$public_formula_error<-error_text(gllvmTMB(
            value~0+trait+latent(0+trait|site,d=1,unique=FALSE),
            data=formula_data,unit="site",trait="trait",family=descriptor,engine="julia"))
        out$public_rejections_match<-known_rejection(out$error) &&
            identical(out$public_matrix_error,out$error) &&
            identical(out$public_formula_error,out$error)
    } else {
        out$status<-"MAPPED_KEY_NOT_MODEL_PROOF";out$mapped_family<-unname(result)
    }
    out
})
result<-list(scope=contract$scope,reference_commit=contract$reference_commit,
             contract_sha256=strsplit(system2("sha256sum",path,stdout=TRUE)," ",fixed=TRUE)[[1]][1],
             rows=rows)
saveRDS(result,"bridge-admission-results.rds")
jsonlite::write_json(result,"bridge-admission-results.json",auto_unbox=TRUE,pretty=TRUE,digits=NA)
cat("BRIDGE_ADMISSION_RESULTS_SHA256",system2("sha256sum","bridge-admission-results.json",stdout=TRUE),"\n")
stopifnot(identical(vapply(rows,function(x)x$id,character(1)),
                   vapply(contract$cases,function(x)x$id,character(1))),
          all(vapply(rows,function(x) x$status!="MAPPER_REJECTED"||isTRUE(x$public_rejections_match),logical(1))),
          !isTRUE(getFromNamespace(".gllvm_jl_env","gllvmTMB")$ready))
print(table(vapply(rows,function(x)x$status,character(1))))
cat("CORE070_BRIDGE_DESCRIPTOR_OBSERVATION_PASS\n")
