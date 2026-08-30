# Exact captured source model at fixed outer parameters; no outer optimizer.
main<-function() {
 a<-commandArgs(TRUE);stopifnot(length(a)==3L);lib<-a[[1]];inputs<-a[[2]];out<-a[[3]]
 stopifnot(!dir.exists(out));dir.create(out,recursive=TRUE)
 .libPaths(c(lib,.libPaths()));suppressPackageStartupMessages(library(gllvmTMB))
 stopifnot(normalizePath(find.package('gllvmTMB'))==normalizePath(file.path(lib,'gllvmTMB')))
 write_tsv<-function(x,path)write.table(x,path,sep='\t',row.names=FALSE,quote=FALSE)
 points<-list(list(beta=c(.2,-.1,.3),lambda=c(.4,-.2,.3,-.15,.5,.25),sigma=.8),list(beta=c(-.1,.25,.05),lambda=c(.7,.1,-.4,.2,-.3,.5),sigma=.55))
 rows<-list()
 for(model in c('ANIMAL-LATENT','KERNEL-ONE','KERNEL-TWO')) for(i in seq_along(points)) {
  id<-paste0(model,'-P',i);dir<-file.path(out,id);dir.create(dir)
  x<-readRDS(file.path(inputs,paste0('INPUT-',model,'-input.rds')));pt<-points[[i]]
  stopifnot(x$DLL=='gllvmTMB',x$data$n_traits==3L,x$data$n_sites==18L,all(x$data$family_id_vec==0L),x$data$use_aghq==0L)
  multi<-x$data$n_kernel_tiers==2L;nr<-if(multi)2L else 1L
  if(multi)stopifnot(identical(dim(x$data$Ainv_kernel),c(2L,6L,6L)))
  cs<-if(multi)lapply(1:2,function(r)solve(x$data$Ainv_kernel[r,,])) else list(solve(as.matrix(x$data$Ainv_phy_rr)))
  group<-if(multi)x$data$kernel_group_id+1L else x$data$species_aug_id+1L
  stopifnot(all(vapply(cs,function(C)identical(dim(C),c(6L,6L)),logical(1))))
  x$parameters$b_fix<-pt$beta;x$parameters$log_sigma_eps<-log(pt$sigma)
  if(multi)x$parameters$theta_rr_kernel<-pt$lambda else x$parameters$theta_rr_phy<-pt$lambda[1:3]
  obj<-TMB::MakeADFun(data=x$data,parameters=x$parameters,map=x$map,random=x$random,DLL=x$DLL,silent=TRUE)
  par<-obj$par;value<-obj$fn(par);gradient<-obj$gr(par);stopifnot(is.finite(value),all(is.finite(gradient)))
  X<-as.matrix(x$data$X_fix);E<-diag(3)[x$data$trait_id+1L,,drop=FALSE]
  stopifnot(identical(dim(X),dim(E)),identical(colnames(X),paste0('traitt',1:3)),identical(as.vector(X),as.vector(E)))
  ti<-x$data$trait_id+1L;V<-diag(pt$sigma^2,length(ti))
  for(r in seq_len(nr)) {
   lambda<-pt$lambda[(3*r-2):(3*r)];V<-V+outer(lambda[ti],lambda[ti])*cs[[r]][group,group]
   write_tsv(data.frame(cs[[r]]),file.path(dir,paste0('source-',r,'.tsv')))
  }
  resid<-x$data$y-as.vector(X%*%pt$beta)
  dense<-(length(resid)*log(2*pi)+as.numeric(determinant(V,logarithm=TRUE)$modulus)+sum(resid*solve(V,resid)))/2
  write_tsv(data.frame(trait=ti,site=x$data$site_id+1L,group=group,y=x$data$y),file.path(dir,'data.tsv'))
  write_tsv(data.frame(name=names(par),value=unname(par),gradient=as.numeric(gradient)),file.path(dir,'parameters.tsv'))
  write_tsv(data.frame(model=model,point=i,sources=nr,r_nll=value,dense_nll=dense),file.path(dir,'contract.tsv'))
  saveRDS(list(input=x,par=par,nll=value,gradient=gradient,covariance=V),file.path(dir,'reference.rds'))
  rows[[length(rows)+1L]]<-data.frame(id=id,r_nll=value,dense_nll=dense,absolute_delta=abs(value-dense))
  cat(id,'R_DENSE_DELTA',format(abs(value-dense),digits=17),'\n')
 }
 write_tsv(do.call(rbind,rows),file.path(out,'summary.tsv'))
 stopifnot(all(vapply(rows,function(r)r$absolute_delta<=1e-6,logical(1))))
 cat('CORE070_SOURCE_REFERENCE_PASS_NATIVE_MAPPING_UNPAID\n')
}
main()
