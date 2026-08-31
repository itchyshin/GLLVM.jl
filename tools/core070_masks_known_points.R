# Independent Gaussian normalization/derivative checks of frozen public maps.
# No outer optimizer; TMB integrates Gaussian random effects by exact Laplace.
main<-function() {
 args<-commandArgs(TRUE);stopifnot(length(args)==3L)
 lib<-args[[1]];inputs<-args[[2]];out<-args[[3]]
 stopifnot(!dir.exists(out));dir.create(out,recursive=TRUE)
 .libPaths(c(lib,.libPaths()));suppressPackageStartupMessages(library(gllvmTMB))
 stopifnot(normalizePath(find.package('gllvmTMB'))==normalizePath(file.path(lib,'gllvmTMB')))
 f<-readRDS(file.path(inputs,'fixtures.rds'))
 getinput<-function(id)readRDS(file.path(inputs,paste0(id,'-input.rds')))
 stopifnot(identical(getinput('MASK-B-PINS'),getinput('MASK-B-UPPER')),
           identical(getinput('KNOWN-EXACT'),getinput('KNOWN-ALIAS')))
 # Independently reconstruct the block matrix, including noncontiguous rows.
 vb<-outer(sqrt(diag(f$V)),sqrt(diag(f$V)))*.25*outer(as.character(f$gaussian$species),as.character(f$gaussian$species),'==')
 diag(vb)<-diag(f$V);stopifnot(max(abs(vb-f$VB))<1e-14)
 ids<-c('MASK-B-PINS','MASK-B-UPPER','MASK-PHY-PINS','MASK-B-ALLFIXED','KNOWN-EXACT','KNOWN-ALIAS','KNOWN-BLOCK','KNOWN-ZERO')
 points<-list(list(beta=c(.2,-.1,.3),sigma=.8,theta=c(.8,.7,.1,.2,-.15)),list(beta=c(-.1,.25,.05),sigma=.55,theta=c(.55,.9,-.1,.25,.15)))
 write_tsv<-function(x,path)write.table(x,path,sep='\t',row.names=FALSE,quote=FALSE)
 rows<-maps<-list();failed<-FALSE
 for(id in ids) {
  x<-getinput(id);d<-x$data;known<-startsWith(id,'KNOWN');phy<-id=='MASK-PHY-PINS'
  field<-if(known)'none' else if(phy)'theta_rr_phy' else 'theta_rr_B'
  expected_random<-if(known)'e_eq' else if(phy)'g_phy' else 'z_B'
  mask<-if(known)integer() else as.integer(x$map[[field]])
  expected_map<-if(known)integer() else if(id=='MASK-B-ALLFIXED')rep(NA_integer_,5) else c(NA_integer_,1L,2L,3L,NA_integer_)
  stopifnot(identical(mask,expected_map),identical(x$random,expected_random),is.null(x$map$log_sigma_eps),length(x$parameters$log_sigma_eps)==1L)
  ti<-d$trait_id+1L;group<-if(known)seq_along(ti) else if(phy)d$species_aug_id+1L else d$site_id+1L
  C<-if(known)solve(as.matrix(d$V_inv)) else if(phy)solve(as.matrix(d$Ainv_phy_rr)) else diag(d$n_sites)
  expectedC<-if(known)(if(id=='KNOWN-BLOCK')vb else if(id=='KNOWN-ZERO')f$V0 else f$V)+diag(1e-8,length(ti)) else if(phy)f$C+diag(1e-8,6) else diag(18)
  stopifnot(length(ti)==54L,all(d$family_id_vec==0L),d$use_aghq==0L,identical(as.numeric(d$y),f$gaussian$value),max(abs(C-expectedC))<1e-12,max(abs(as.matrix(d$X_fix)-diag(3)[ti,,drop=FALSE]))==0)
  nfree<-length(unique(mask[!is.na(mask)]))
  maps[[length(maps)+1L]]<-data.frame(id=id,field=field,free_loadings=nfree,free_residual=1L,random=expected_random,map=if(known)'none' else paste(mask,collapse=','),pins=if(known)'none' else paste(x$parameters[[field]][is.na(mask)],collapse=','))
  for(i in seq_along(points)) {
   pt<-points[[i]];xx<-x;xx$parameters$b_fix<-pt$beta;xx$parameters$log_sigma_eps<-log(pt$sigma)
   if(!known)xx$parameters[[field]][!is.na(mask)]<-pt$theta[!is.na(mask)]
   obj<-TMB::MakeADFun(data=d,parameters=xx$parameters,map=xx$map,random=xx$random,DLL=xx$DLL,silent=TRUE)
   par<-obj$par;value<-as.numeric(obj$fn(par));gradient<-as.numeric(obj$gr(par))
   stopifnot(length(par)==4L+nfree,setequal(unique(names(par)),c('b_fix','log_sigma_eps',if(nfree)field)))
   expand<-function(par) {
    z<-xx$parameters
    for(k in unique(names(par))) {
     v<-unname(par[names(par)==k]);m<-xx$map[[k]]
     if(is.null(m))z[[k]]<-v else {m<-as.integer(m);z[[k]][!is.na(m)]<-v[m[!is.na(m)]]}
    };z
   }
   covariance<-function(par,drop=FALSE) {
    z<-expand(par);V<-diag(exp(2*z$log_sigma_eps),54)
    if(known)return(V+if(drop)matrix(0,54,54) else C)
    L<-matrix(0,3,2);L[1,1]<-z[[field]][1];L[2,2]<-z[[field]][2];L[2:3,1]<-z[[field]][3:4];L[3,2]<-z[[field]][5]
    V+C[group,group]*tcrossprod(L)[ti,ti]
   }
   dense<-function(par,drop=FALSE) {
    z<-expand(par);ch<-chol(covariance(par,drop));resid<-d$y-as.vector(d$X_fix%*%z$b_fix)
    white<-forwardsolve(t(ch),resid);(54*log(2*pi)+2*sum(log(diag(ch)))+sum(white^2))/2
   }
   independent<-dense(par)
   fd<-vapply(seq_along(par),function(j){a<-b<-par;a[j]<-a[j]+1e-5;b[j]<-b[j]-1e-5;(dense(a)-dense(b))/2e-5},numeric(1))
   delta<-abs(value-independent);error<-max(abs(gradient-fd)/pmax(1,abs(gradient)))
   shifted<-par;shifted[names(par)=='b_fix']<-shifted[names(par)=='b_fix']+.1
   mean_delta<-abs(value-dense(shifted));drop_delta<-if(known)abs(value-dense(par,TRUE)) else NA_real_
   pass<-all(is.finite(c(value,gradient,fd)))&&delta<=1e-6&&error<=1e-5&&mean_delta>1e-4&&(!known||id=='KNOWN-ZERO'||drop_delta>1e-4)
   row<-data.frame(id=paste0(id,'-P',i),r_nll=value,dense_nll=independent,delta=delta,gradient_error=error,shifted_mean_delta=mean_delta,drop_known_delta=drop_delta,pass=pass)
   rows[[length(rows)+1L]]<-row;dir<-file.path(out,row$id);dir.create(dir)
   write_tsv(data.frame(trait=ti,group=group,y=d$y),file.path(dir,'observations.tsv'))
   write_tsv(data.frame(C),file.path(dir,'source.tsv'))
   write_tsv(data.frame(name=names(par),value=as.numeric(par),r_gradient=gradient,dense_fd=fd),file.path(dir,'parameters.tsv'))
   write_tsv(data.frame(covariance(par)),file.path(dir,'covariance.tsv'))
   saveRDS(list(input=xx,outer=par,value=value,gradient=gradient,dense_fd=fd,covariance=covariance(par),result=row),file.path(dir,'point.rds'))
   cat(row$id,'delta',format(delta,digits=10),'gradient_error',format(error,digits=10),if(pass)'PASS' else 'FAIL','\n');failed<-failed||!pass
  }
 }
 write_tsv(do.call(rbind,rows),file.path(out,'points.tsv'));write_tsv(do.call(rbind,maps),file.path(out,'maps.tsv'))
 stopifnot(length(rows)==16L)
 if(failed)stop('CORE070_MASKS_KNOWN_POINT_FAILURE',call.=FALSE)
 cat('CORE070_MASKS_KNOWN_POINTS_PASS_NO_OPTIMIZER\n')
}
main()
