# Separately declared fitting data; never replaces core070_covariance_modes.R.
# No package engine runs while this fixture is sourced.
stopifnot(exists('gllvmTMBcontrol', mode='function'))
control <- gllvmTMBcontrol(n_init=1L, se=FALSE, aghq=FALSE)
cases <- list()
for (source in c('ORD','ANIMAL','KERNEL')) {
 for (mode in if(source=='ORD') 'DEP' else c('INDEP','COMMON','DEP')) {
  n <- 36L; p <- 3L; groups <- rep(seq_len(12L),each=3L)
  df <- expand.grid(site=factor(sprintf('u%02d',seq_len(n))),
                    trait=factor(paste0('t',seq_len(p))))
  df$species <- factor(rep(sprintf('g%02d',groups),p),
                       levels=sprintf('g%02d',seq_len(12L)))
  C <- .7*diag(12L)+.3
  dimnames(C) <- list(levels(df$species),levels(df$species))
  effective <- if(source=='ORD') diag(n) else C+diag(1e-8,12L)
  projection <- if(source=='ORD') seq_len(n) else groups
  L <- if(mode=='DEP') matrix(c(.8,.15,-.2,0,.7,.1,0,0,.6),3L) else
       diag(if(mode=='COMMON') rep(.7,p) else c(.5,.7,.9))
  seed <- 700700L + match(mode,c('INDEP','COMMON','DEP')) +
          if(source=='ORD') 10L else 0L
  set.seed(seed)
  # Neither latent draws nor errors are centered or standardized after sampling.
  latent <- L %*% matrix(rnorm(p*nrow(effective)),p) %*% chol(effective)
  Y <- sweep(latent[,projection,drop=FALSE] +
             .35*matrix(rnorm(p*n),p),1L,c(.2,-.1,.3),'+')
  df$value <- as.vector(t(Y))
  term <- if(source=='ORD') 'dep(0+trait|site)' else if(source=='ANIMAL')
    switch(mode,INDEP='animal_indep(0+trait|species,A=C)',
           COMMON='animal_indep(0+trait|species,A=C,common=TRUE)',
           DEP='animal_dep(0+trait|species,A=C)') else
    switch(mode,INDEP='kernel_indep(species,K=C,name="known")',
           COMMON='kernel_indep(species,K=C,name="known",common=TRUE)',
           DEP='kernel_dep(species,K=C,name="known")')
  call <- substitute(gllvmTMB(FORMULA,df,cluster='species',control=control),
    list(FORMULA=as.formula(paste('value~0+trait+',term))))
  original_id <- paste('MODE',source,mode,sep='-')
  cases[[length(cases)+1L]] <- list(id=paste0('FIT-',original_id),
    original_id=original_id,source=source,mode=mode,data=df,C=C,Y=Y,call=call,
    seed=seed,truth=list(beta=c(.2,-.1,.3),sigma_eps=.35,
                         trait_covariance=tcrossprod(L)),
    fit_seed=700710L+length(cases)+1L)
 }
}
stopifnot(length(cases)==7L)
