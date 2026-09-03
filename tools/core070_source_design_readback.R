# Independent readback: no TMB calls, no refits and no new fixture draws.
args <- commandArgs(TRUE); stopifnot(length(args)==1L)
z <- readRDS(file.path(args[[1]],'reference.rds'))
d <- z$data; par <- z$parameters
stopifnot(d$n_sites==36L,d$n_traits==3L,length(d$y)==108L,
          all(d$family_id_vec==0L),d$use_aghq==0L,
          identical(z$outer,z$fit$opt$par),length(z$outer)==8L,
          identical(names(z$outer),c(rep('b_fix',4),'log_sigma_eps',rep('theta_rr_phy',3))),
          identical(as.integer(z$map$theta_rr_phy),c(1L,2L,3L,NA,NA,NA)),
          all(par$theta_rr_phy[4:6]==0),is.null(z$map$log_sigma_eps))
ti <- d$trait_id+1L;si <- d$site_id+1L;g <- d$species_aug_id+1L
stopifnot(identical(as.integer(ti),rep(1:3,each=36)),
          identical(as.integer(si),rep(1:36,3)),
          identical(as.integer(g),rep(rep(1:12,each=3),3)))
X <- cbind(diag(3)[ti,,drop=FALSE],sin(si/5))
stopifnot(max(abs(X-d$X_fix))<=1e-15)
# sin() may differ in the last bit across Linux and macOS; use retained X below.
X <- d$X_fix
C <- .7*diag(12)+.3*matrix(1,12,12)+diag(1e-8,12)
# Optional Matrix is needed only to decode the retained sparse precision.
stopifnot(requireNamespace('Matrix',quietly=TRUE))
stopifnot(max(abs(solve(as.matrix(d$Ainv_phy_rr))-C))<=1e-12)
U <- diag(par$theta_rr_phy[1:3]^2); sigma <- exp(par$log_sigma_eps)
V <- C[g,g]*U[ti,ti]+diag(sigma^2,108)
r <- d$y-as.vector(X%*%par$b_fix);ch <- chol(V)
objective <- (108*log(2*pi)+2*sum(log(diag(ch)))+sum(forwardsolve(t(ch),r)^2))/2
stopifnot(is.finite(objective),abs(objective-z$objective)<=1e-6,
          abs(z$loglik+z$objective)<=1e-8)
Y <- matrix(NA_real_,3,36);Y[cbind(ti,si)]<-d$y
fields <- list(r_loglik=z$loglik,r_objective=z$objective,
 r_code=as.integer(z$fit$opt$convergence),r_gradient=z$gradient,
 r_parameters=as.numeric(z$outer),r_beta=as.numeric(par$b_fix),
 r_source_diagonal=as.numeric(par$theta_rr_phy[1:3]),r_sigma_eps=sigma,
 Y=as.vector(t(Y)),dense_objective=objective)
for (field in names(fields)) for(i in seq_along(fields[[field]])) {
 cat(field,i,sprintf('%.17g',fields[[field]][i]),sep='\t');cat('\n')
}
cat('SOURCE_DESIGN_R_READBACK_PASS\n')
