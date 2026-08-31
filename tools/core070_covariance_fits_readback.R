# Read retained fitted objects independently, without refitting or calling TMB.
args <- commandArgs(TRUE); stopifnot(length(args)==1L)
ids <- c('FIT-MODE-ORD-DEP',paste0('FIT-MODE-',rep(c('ANIMAL','KERNEL'),each=3),
                                 '-',rep(c('INDEP','COMMON','DEP'),2)))
for(id in ids) {
 x <- readRDS(file.path(args[[1]],paste0(id,'.rds')))
 stopifnot(identical(x$id,id),!is.null(x$full_fit),!is.null(x$evidence))
 e <- x$evidence; d <- e$data; z <- e$parameters
 mode <- tail(strsplit(id,'-',fixed=TRUE)[[1]],1)
 source <- strsplit(id,'-',fixed=TRUE)[[1]][3]
 ordinary <- source=='ORD'; propto <- source=='ANIMAL' && mode=='COMMON'
 field <- if(ordinary)'theta_rr_B' else if(propto)'loglambda_phy' else 'theta_rr_phy'
 count <- switch(mode,DEP=10L,INDEP=7L,COMMON=5L)
 stopifnot(d$n_sites==36L,d$n_traits==3L,length(d$y)==108L,
           all(d$family_id_vec==0L),d$use_aghq==0L,
           identical(e$covariance_field,field),length(e$outer)==count,
           sum(names(e$outer)=='b_fix')==3L,sum(names(e$outer)=='log_sigma_eps')==1L,
           identical(e$outer,x$full_fit$opt$par))
 # Read the exact retained response bytes, not a new draw made using this
 # host's BLAS (which can differ in the final bit of fixture matrix products).
 Y <- matrix(NA_real_,3L,36L)
 Y[cbind(d$trait_id+1L,d$site_id+1L)] <- as.numeric(d$y)
 stopifnot(all(is.finite(Y)))
 theta <- z[[field]]
 U <- if(propto)diag(exp(theta),3) else {
   L<-diag(theta[1:3]);L[2,1]<-theta[4];L[3,1]<-theta[5];L[3,2]<-theta[6]
   tcrossprod(L)
 }
 stopifnot(max(abs(U-e$covariance))<=1e-12)
 if(mode!='DEP' && !propto) {
   want <- if(mode=='COMMON')c(1L,1L,1L,NA,NA,NA) else c(1L,2L,3L,NA,NA,NA)
   stopifnot(identical(as.integer(e$map[[field]]),want),all(theta[4:6]==0))
 }
 sigma <- exp(z$log_sigma_eps)
 ti <- d$trait_id+1L; g <- e$source_groups
 V <- e$source_effective[g,g]*U[ti,ti] + diag(sigma^2,length(ti))
 res <- d$y-as.vector(d$X_fix%*%z$b_fix)
 ch <- chol(V)
 dense <- (length(res)*log(2*pi)+2*sum(log(diag(ch)))+
           sum(forwardsolve(t(ch),res)^2))/2
 stopifnot(is.finite(dense),abs(dense-e$objective)<=1e-6)
 fields <- list(loglik=e$loglik,objective=e$objective,code=e$code,
                gradient=e$gradient,outer=as.numeric(e$outer),beta=as.numeric(z$b_fix),
                covariance=as.vector(t(e$covariance)),residual_sd=as.numeric(sigma),hessian_min=e$hessian_min,
                Y=as.vector(t(Y)))
 for(field in names(fields)) {
   values<-fields[[field]];stopifnot(is.numeric(values))
   for(i in seq_along(values)) {
     cat(id,field,i,sprintf('%.17g',values[i]),sep='\t');cat('\n')
   }
 }
 cat(id,'dense_objective',1,sprintf('%.17g',dense),sep='\t');cat('\n')
}
cat('COVARIANCE_FITS_R_READBACK_PASS\n')
