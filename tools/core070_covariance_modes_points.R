# Frozen Gaussian covariance modes at declared coordinates; no outer optimizer.
main<-function() {
 args<-commandArgs(TRUE);stopifnot(length(args)==3L)
 lib<-args[[1]];inputs<-args[[2]];out<-args[[3]]
 stopifnot(!dir.exists(out));dir.create(out,recursive=TRUE)
 .libPaths(c(lib,.libPaths()));suppressPackageStartupMessages(library(gllvmTMB))
 stopifnot(normalizePath(find.package('gllvmTMB'))==normalizePath(file.path(lib,'gllvmTMB')))
 fixtures<-readRDS(file.path(inputs,'fixtures.rds'))
 ids<-paste0('MODE-',rep(c('ORD','ANIMAL','KERNEL'),each=3),'-',rep(c('INDEP','COMMON','DEP'),3))
 points<-list(list(beta=c(.2,-.1,.3),sd=c(.4,.7,.9),common=.65,chol=c(.8,.7,.6,.15,-.2,.1),sigma=.8),list(beta=c(-.1,.25,.05),sd=c(.6,.35,.8),common=.45,chol=c(.55,.9,.65,-.1,.25,-.15),sigma=.55))
 write_tsv<-function(x,path)write.table(x,path,sep='\t',row.names=FALSE,quote=FALSE)
 unpack<-function(theta) { stopifnot(length(theta)==6L);L<-diag(theta[1:3]);L[2,1]<-theta[4];L[3,1]<-theta[5];L[3,2]<-theta[6];L }
 free_count<-function(x,k) {m<-x$map[[k]];if(is.null(m))length(x$parameters[[k]]) else length(unique(as.integer(m)[!is.na(m)]))}
 rows<-list();maps<-list();failed<-FALSE
 for(id in ids) {
  x<-readRDS(file.path(inputs,paste0(id,'-input.rds')));d<-x$data
  parts<-strsplit(id,'-',fixed=TRUE)[[1]];source<-parts[2];mode<-parts[3]
  ordinary<-source=='ORD';propto<-source=='ANIMAL'&&mode=='COMMON'
  field<-if(ordinary&&mode!='DEP')'theta_diag_B' else if(ordinary)'theta_rr_B' else if(propto)'loglambda_phy' else 'theta_rr_phy'
  expected_random<-if(field=='theta_diag_B')'s_B' else if(ordinary)'z_B' else if(propto)'p_phy' else 'g_phy'
  free_sigma<-!(ordinary&&mode!='DEP')
  expected_n<-switch(mode,INDEP=3L,COMMON=1L,DEP=6L)
  stopifnot(identical(x$random,expected_random),free_count(x,field)==expected_n,free_count(x,'log_sigma_eps')==as.integer(free_sigma))
  if(field=='theta_rr_phy'&&mode!='DEP') {
   expected_map<-if(mode=='INDEP')c(1L,2L,3L,NA,NA,NA) else c(1L,1L,1L,NA,NA,NA)
   stopifnot(identical(as.integer(x$map[[field]]),expected_map),all(x$parameters[[field]][4:6]==0))
  }
  if(ordinary&&mode=='COMMON')stopifnot(identical(as.integer(x$map[[field]]),c(1L,1L,1L)))
  C<-if(ordinary)diag(d$n_sites) else if(propto)solve(as.matrix(d$Cphy_inv)) else solve(as.matrix(d$Ainv_phy_rr))
  group<-if(ordinary)d$site_id+1L else if(propto)d$species_id+1L else d$species_aug_id+1L
  ti<-d$trait_id+1L
  stopifnot(d$n_traits==3L,d$n_sites==18L,length(d$y)==54L,all(d$family_id_vec==0L),d$use_aghq==0L)
  stopifnot(max(abs(as.matrix(d$X_fix)-diag(3)[ti,,drop=FALSE]))==0)
  # Frozen dense-source preparation adds exactly 1e-8 to each input diagonal.
  # Verify that preprocessing; do not widen tolerance or add our own ridge.
  if(!ordinary)stopifnot(identical(dim(C),c(6L,6L)),max(abs(C-fixtures$C-diag(1e-8,6)))<1e-12,length(unique(group))==6L)
  # Explicit fixed/free and transform contract, not only number of parameters.
  maps[[length(maps)+1L]]<-data.frame(id=id,field=field,free_covariance=expected_n,free_residual=as.integer(free_sigma),random=expected_random,transform=if(field=='theta_diag_B')'log_SD' else if(propto)'log_variance' else 'raw_loadings',map=if(is.null(x$map[[field]]))'unmapped' else paste(as.integer(x$map[[field]]),collapse=','),source_jitter=if(ordinary)0 else 1e-8)
  for(i in seq_along(points)) {
   pt<-points[[i]];xx<-x;xx$parameters$b_fix<-pt$beta
   if(free_sigma)xx$parameters$log_sigma_eps<-log(pt$sigma)
   xx$parameters[[field]]<-if(field=='theta_diag_B')log(if(mode=='COMMON')rep(pt$common,3) else pt$sd) else if(propto)log(pt$common^2) else if(mode=='DEP')pt$chol else c(if(mode=='COMMON')rep(pt$common,3) else pt$sd,0,0,0)
   obj<-TMB::MakeADFun(data=d,parameters=xx$parameters,map=xx$map,random=xx$random,DLL=xx$DLL,silent=TRUE)
   par<-obj$par;value<-as.numeric(obj$fn(par));gradient<-as.numeric(obj$gr(par))
   stopifnot(length(par)==3L+expected_n+as.integer(free_sigma),setequal(unique(names(par)),c('b_fix',field,if(free_sigma)'log_sigma_eps')))
   # Expand only the known free blocks with an independent map implementation.
   expand<-function(par) {
    z<-xx$parameters
    for(k in unique(names(par))) {
     v<-unname(par[names(par)==k]);m<-xx$map[[k]]
     if(is.null(m))z[[k]]<-v else {mask<-as.integer(m);z[[k]][!is.na(mask)]<-v[mask[!is.na(mask)]]}
    };z
   }
   covariance<-function(par,wrong_common=FALSE) {
    z<-expand(par);sigma<-exp(z$log_sigma_eps)
    U<-if(field=='theta_diag_B')diag(exp(2*z[[field]])) else if(propto)diag(exp(z[[field]]),3) else {L<-unpack(z[[field]]);tcrossprod(L)}
    if(wrong_common)U[,]<-U[1,1]
    diag(sigma^2,length(ti))+C[group,group]*U[ti,ti]
   }
   dense<-function(par,wrong_common=FALSE) {
    z<-expand(par);V<-covariance(par,wrong_common);resid<-d$y-as.vector(d$X_fix%*%z$b_fix)
    ch<-chol(V);white<-forwardsolve(t(ch),resid)
    (length(resid)*log(2*pi)+2*sum(log(diag(ch)))+sum(white^2))/2
   }
   fd<-vapply(seq_along(par),function(j){plus<-minus<-par;plus[j]<-plus[j]+1e-5;minus[j]<-minus[j]-1e-5;(dense(plus)-dense(minus))/2e-5},numeric(1))
   independent<-dense(par);delta<-abs(value-independent);grad_error<-max(abs(gradient-fd)/pmax(1,abs(gradient)))
   wrong_delta<-if(mode=='COMMON')abs(value-dense(par,TRUE)) else NA_real_
   # Deliberately wrong mean must also be detected in every model.
   shifted<-par;shifted[names(par)=='b_fix']<-shifted[names(par)=='b_fix']+.1
   mean_delta<-abs(value-dense(shifted))
   pass<-all(is.finite(c(value,gradient,fd)))&&delta<=1e-6&&grad_error<=1e-5&&mean_delta>1e-4&&(mode!='COMMON'||wrong_delta>1e-4)
   record<-data.frame(id=paste0(id,'-P',i),r_nll=value,dense_nll=independent,delta=delta,gradient_error=grad_error,wrong_common_delta=wrong_delta,shifted_mean_delta=mean_delta,pass=pass)
   rows[[length(rows)+1L]]<-record
   dir<-file.path(out,record$id);dir.create(dir)
   write_tsv(data.frame(trait=ti,group=group,y=d$y),file.path(dir,'observations.tsv'))
   write_tsv(data.frame(C),file.path(dir,'source.tsv'));write_tsv(data.frame(name=names(par),value=as.numeric(par),r_gradient=gradient,dense_fd=fd),file.path(dir,'parameters.tsv'))
   write_tsv(data.frame(covariance(par)),file.path(dir,'covariance.tsv'))
   saveRDS(list(input=xx,outer=par,value=value,gradient=gradient,dense_fd=fd,covariance=covariance(par),result=record),file.path(dir,'point.rds'))
   cat(record$id,'delta',format(delta,digits=10),'gradient_error',format(grad_error,digits=10),if(pass)'PASS' else 'FAIL','\n')
   failed<-failed||!pass
  }
 }
 write_tsv(do.call(rbind,rows),file.path(out,'points.tsv'));write_tsv(do.call(rbind,maps),file.path(out,'maps.tsv'))
 stopifnot(length(rows)==18L)
 if(failed)stop('CORE070_COVARIANCE_MODES_POINT_FAILURE',call.=FALSE)
 cat('CORE070_COVARIANCE_MODES_POINTS_PASS_NO_OPTIMIZER\n')
}
main()
