# Independent base-R readback of serialized whole-fit fields; no TMB evaluation.
args <- commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==1L)
x <- readRDS(args[[1]])
stopifnot(identical(x$final_data,x$original_data),
          identical(x$final_map,x$original_map),
          identical(x$final$names,rep(c("b_fix","theta_rr_B","log_sigma_student","log_df_student"),each=5L)))
for (kind in c("original","warm","final")) {
  fit <- x[[kind]]
  for (field in c("loglik","objective","code","gradient","parameters","df","sigma")) {
    values <- fit[[field]]
    stopifnot(is.numeric(values),all(is.finite(values)))
    for(i in seq_along(values)) {
      cat(kind,field,i,sprintf("%.17g",values[i]),sep="\t"); cat("\n")
    }
  }
}
cat("R_WHOLE_FIT_READBACK_PASS\n")
