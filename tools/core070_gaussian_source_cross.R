# Evaluate retained frozen-R model at the Julia endpoint; no optimization.
a<-commandArgs(TRUE);stopifnot(length(a)==3L)
.libPaths(c(a[[1]],.libPaths()));suppressPackageStartupMessages(library(gllvmTMB))
stopifnot(normalizePath(find.package('gllvmTMB'))==normalizePath(file.path(a[[1]],'gllvmTMB')))
ids<-c('STRUCT-PHY-TREE-RR','STRUCT-PHY-DENSE-RR','STRUCT-PHY-TREE-PROPTO','STRUCT-ANI-PED-SPARSE','STRUCT-KER-SINGLE-PSI','STRUCT-KER-MULTI')
rows<-list();failed<-FALSE;options(digits=17)
for(id in ids) {
 row<-tryCatch({
  ref<-readRDS(file.path(a[[2]],id,'reference.rds'));x<-ref$input
  obj<-TMB::MakeADFun(data=x$data,parameters=x$parameters,map=x$map,random=x$random,DLL=x$DLL,silent=TRUE)
  native<-read.delim(file.path(a[[3]],id,'native-parameters.tsv'),check.names=FALSE)
  stopifnot(identical(native$name,names(obj$par)),all(is.finite(native$value)))
  par<-setNames(native$value,native$name);nll<-obj$fn(par);gradient<-obj$gr(par)
  stopifnot(is.finite(nll),all(is.finite(gradient)))
  data.frame(id=id,r_at_native_nll=nll,r_at_native_gradient_max=max(abs(gradient)),error='')
 },error=function(e){failed<<-TRUE;data.frame(id=id,r_at_native_nll=NaN,r_at_native_gradient_max=Inf,error=gsub('[\t\n]',' ',conditionMessage(e)))})
 rows[[length(rows)+1L]]<-row
}
write.table(do.call(rbind,rows),file.path(a[[3]],'r-cross.tsv'),sep='\t',quote=FALSE,row.names=FALSE,na='NaN')
if(failed)stop('CORE070_SOURCE_CROSS_ERRORS',call.=FALSE)
cat('CORE070_SOURCE_CROSS_RECORDED_NOT_PARITY\n')
