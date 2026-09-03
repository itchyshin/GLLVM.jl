
.admission_run <- function(Y, fam, rformula, seed, aghq=FALSE, weights=NULL) {
 p <- nrow(Y); n <- ncol(Y)
 df <- data.frame(site=factor(rep(seq_len(n),each=p)),trait=factor(rep(paste0('t',seq_len(p)),times=n)),value=as.vector(Y))
 ff <- as.formula(rformula, env=environment())
 family <- switch(fam,gaussian=gaussian(),poisson=poisson(),binomial=binomial())
 warnings <- character();messages <- character();set.seed(seed)
 fit <- withCallingHandlers(gllvmTMB(ff,data=df,unit='site',trait='trait',family=family,weights=weights,
   control=gllvmTMBcontrol(aghq=aghq,aghq_ridge=Inf,n_init=1L,se=FALSE,
     optimizer=if(fam=="gaussian") "optim" else "nlminb",
     optArgs=if(fam=="gaussian") list(method="BFGS",control=list(reltol=1e-14,maxit=2000)) else list())),
   warning=function(w){warnings <<- c(warnings,conditionMessage(w));invokeRestart('muffleWarning')},
   message=function(m){messages <<- c(messages,conditionMessage(m));invokeRestart('muffleMessage')})
 obj <- fit$tmb_obj;value <- as.numeric(obj$fn(fit$opt$par));gradient <- as.numeric(obj$gr(fit$opt$par))
 list(fit=fit,value=value,gradient=gradient,warnings=warnings,messages=messages,
  random=unique(names(obj$env$last.par)[obj$env$random]),
  params=obj$env$parList(x=fit$opt$par,par=obj$env$last.par))
}
