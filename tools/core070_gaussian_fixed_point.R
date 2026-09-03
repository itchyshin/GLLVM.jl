# Rebuild exact captured frozen-R inputs; fixed outer points, no outer optimizer.
main<-function() {
 a<-commandArgs(TRUE);stopifnot(length(a)==3L)
 lib<-a[[1]];inputs<-a[[2]];out<-a[[3]];stopifnot(!dir.exists(out));dir.create(out,recursive=TRUE)
 .libPaths(c(lib,.libPaths()));suppressPackageStartupMessages(library(gllvmTMB))
 stopifnot(normalizePath(find.package('gllvmTMB'))==normalizePath(file.path(lib,'gllvmTMB')))
 write_tsv<-function(x,path)write.table(x,path,sep='\t',row.names=FALSE,quote=FALSE)
 points<-list(list(beta=c(.2,-.1,.3),lambda=c(.4,-.2,.3),sd=c(.5,.6,.7),common=.45,sigma=.8),list(beta=c(-.1,.25,.05),lambda=c(.7,.1,-.4),sd=c(.4,.8,.6),common=.65,sigma=.55))
 rows<-list()
 for(model in c('DEFAULT','COMMON','LOADINGS')) for(i in seq_along(points)) {
  id<-paste0('GAUSS-',model,'-P',i);dir<-file.path(out,id);dir.create(dir)
  x<-readRDS(file.path(inputs,paste0('INPUT-GAUSS-',model,'-input.rds')));pt<-points[[i]]
  stopifnot(x$DLL=='gllvmTMB',x$data$n_traits==3L,x$data$n_sites==18L,x$data$d_B==1L,all(x$data$family_id_vec==0L),x$data$use_aghq==0L)
  x$parameters$b_fix<-pt$beta;x$parameters$theta_rr_B<-pt$lambda
  psi<-model!='LOADINGS';common<-model=='COMMON'
  if(psi)x$parameters$theta_diag_B<-log(if(common)rep(pt$common,3) else pt$sd)
  if(!psi)x$parameters$log_sigma_eps<-log(pt$sigma)
  sigma<-exp(x$parameters$log_sigma_eps)
  obj<-TMB::MakeADFun(data=x$data,parameters=x$parameters,map=x$map,random=x$random,DLL=x$DLL,silent=TRUE)
  par<-obj$par;value<-obj$fn(par);gradient<-obj$gr(par)
  stopifnot(is.finite(value),all(is.finite(gradient)))
  # Verify design and ordering rather than assuming long-data row order.
  X<-as.matrix(x$data$X_fix);stopifnot(ncol(X)==3L)
  expected<-diag(3)[x$data$trait_id+1L,,drop=FALSE];stopifnot(identical(dim(X),dim(expected)),identical(colnames(X),paste0("traitt",1:3)),identical(as.vector(X),as.vector(expected)))
  Y<-matrix(NA_real_,3,18);Y[cbind(x$data$trait_id+1L,x$data$site_id+1L)]<-x$data$y;stopifnot(!anyNA(Y))
  variance<-rep(sigma^2,3)+if(psi)exp(2*x$parameters$theta_diag_B) else 0
  V<-tcrossprod(pt$lambda)+diag(variance,3);resid<-Y-pt$beta
  dense<-(54*log(2*pi)+18*as.numeric(determinant(V,logarithm=TRUE)$modulus)+sum(resid*solve(V,resid)))/2
  write_tsv(data.frame(trait=x$data$trait_id+1L,site=x$data$site_id+1L,y=x$data$y),file.path(dir,'data.tsv'))
  write_tsv(data.frame(name=names(par),value=unname(par),gradient=as.numeric(gradient)),file.path(dir,'parameters.tsv'))
  write_tsv(data.frame(model=model,point=i,sigma=sigma,has_psi=as.integer(psi),common=as.integer(common),r_nll=value,dense_nll=dense),file.path(dir,'contract.tsv'))
  saveRDS(list(input=x,par=par,nll=value,gradient=gradient),file.path(dir,'reference.rds'))
  rows[[length(rows)+1L]]<-data.frame(id=id,r_nll=value,dense_nll=dense,absolute_delta=abs(value-dense))
  cat(id,'R_DENSE_DELTA',format(abs(value-dense),digits=17),'\n')
 }
 write_tsv(do.call(rbind,rows),file.path(out,'summary.tsv'))
 stopifnot(all(vapply(rows,function(r)r$absolute_delta<=1e-6,logical(1))))
 cat('CORE070_GAUSSIAN_FIXED_R_PASS_NO_OUTER_OPTIMIZATION\n')
}
main()
