# Independent base-R readback; no fitting or DLL evaluation.
args<-commandArgs(TRUE);stopifnot(length(args)==1L)
for(id in c('MODE-ORD-INDEP','MODE-ORD-COMMON')) {
 x<-readRDS(file.path(args[[1]],paste0(id,'.rds')))
 stopifnot(identical(x$id,id),x$data$n_traits==3L,x$data$n_sites==18L,
           all(x$data$family_id_vec==0L),length(x$parameters$log_sigma_eps)==1L,
           !any(names(x$outer)=='log_sigma_eps'),all(is.na(x$map$log_sigma_eps)),
           sum(names(x$outer)=='b_fix')==3L,
           sum(names(x$outer)=='theta_diag_B')==if(id=='MODE-ORD-COMMON')1L else 3L)
 fields<-list(r_loglik=x$loglik,r_objective=x$objective,r_code=x$optimizer$convergence,
              r_gradient=x$gradient,r_parameters=x$outer,r_beta=x$parameters$b_fix,
              r_source_sd=exp(x$parameters$theta_diag_B),sigma_eps_fixed=exp(x$parameters$log_sigma_eps))
 for(field in names(fields)) {
   values<-fields[[field]];stopifnot(is.numeric(values),all(is.finite(values)))
   for(i in seq_along(values)) {cat(id,field,i,sprintf('%.17g',values[i]),sep='\t');cat('\n')}
 }
}
cat('FIXED_SOURCE_R_READBACK_PASS\n')
