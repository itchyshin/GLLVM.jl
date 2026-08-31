# Public frozen-R fits and retained-input objectives; no reference source edits.
main <- function() {
 a<-commandArgs(TRUE);stopifnot(length(a)==3L)
 lib<-a[[1]];inputs<-a[[2]];out<-a[[3]]
 stopifnot(!dir.exists(out));dir.create(out,recursive=TRUE)
 .libPaths(c(lib,.libPaths()));suppressPackageStartupMessages(library(gllvmTMB))
 stopifnot(normalizePath(find.package('gllvmTMB'))==normalizePath(file.path(lib,'gllvmTMB')))
 marker<-readLines(file.path(lib,'gllvmTMB','CORE070_SOURCE_PIN.toml'))
 stopifnot(any(grepl('b4d5fee64def88bc768dda1f1f77c29b295edd86',marker,fixed=TRUE)))
 options(warnPartialMatchDollar=TRUE,digits=17)
 env<-new.env(parent=globalenv())
 sys.source('test/parity/fixtures/core070_structured_input.R',envir=env)
 ids<-c('STRUCT-PHY-TREE-RR','STRUCT-PHY-DENSE-RR','STRUCT-PHY-TREE-PROPTO','STRUCT-ANI-PED-SPARSE','STRUCT-KER-SINGLE-PSI','STRUCT-KER-MULTI')
 cases<-env$cases[vapply(env$cases,function(c)c$id %in% ids,logical(1))]
 stopifnot(identical(vapply(cases,`[[`,'','id'),ids))
 write_tsv<-function(x,p)write.table(x,p,sep='\t',row.names=FALSE,quote=FALSE,na='NaN')
 rows<-list();failed<-FALSE
 for(case in cases) {
  id<-case$id;folder<-file.path(out,id);dir.create(folder);warnings<-character()
  result<-withCallingHandlers(tryCatch({
   x<-readRDS(file.path(inputs,paste0(id,'-input.rds')))
   stopifnot(x$DLL=='gllvmTMB',x$data$n_traits==3L,x$data$n_sites==12L,all(x$data$family_id_vec==0L),x$data$use_aghq==0L)
   obj<-TMB::MakeADFun(data=x$data,parameters=x$parameters,map=x$map,random=x$random,DLL=x$DLL,silent=TRUE)
   start<-obj$par;f0<-obj$fn(start);g0<-obj$gr(start)
   set.seed(700L);fit<-eval(case$call,env)
   fo<-fit[['tmb_obj',exact=TRUE]];opt<-fit[['opt',exact=TRUE]]
   stopifnot(is.list(fo),is.list(opt),identical(names(start),names(opt$par)),length(start)==length(opt$par))
   t<-opt$par;v<-fo$fn(t);g<-fo$gr(t)
   # Public fit and retained prepared model must share their objective.
   captured_value<-obj$fn(t);captured_gradient<-obj$gr(t)
   stopifnot(is.finite(v),all(is.finite(g)),abs(v-captured_value)<=1e-6,max(abs(g-captured_gradient))<=1e-5)
   H<-optimHess(t,fo$fn,fo$gr);mineig<-min(eigen((H+t(H))/2,symmetric=TRUE,only.values=TRUE)$values)
   disagreement<-max(abs(v-opt$objective),abs(v+as.numeric(logLik(fit))))
   write_tsv(data.frame(name=names(start),start=as.numeric(start),estimate=as.numeric(t),gradient_start=as.numeric(g0),gradient_fit=as.numeric(g)),file.path(folder,'parameters.tsv'))
   saveRDS(list(input=x,start=start,estimate=t,objective=v,gradient=g,hessian=H,opt=opt,call=case$call),file.path(folder,'reference.rds'))
   writeLines(c(paste(deparse(case$call),collapse=' '),paste('optimizer_message',opt$message)),file.path(folder,'call.txt'))
   data.frame(id=id,r_nll_start=f0,r_nll_fit=v,r_gradient_max=max(abs(g)),r_hessian_min=mineig,r_convergence=opt$convergence,r_objective_disagreement=disagreement)
  },error=function(e)e),warning=function(w){warnings<<-c(warnings,conditionMessage(w));invokeRestart('muffleWarning')})
  writeLines(warnings,file.path(folder,'warnings.txt'))
  if(inherits(result,'error')) {
   failed<-TRUE;detail<-conditionMessage(result);writeLines(detail,file.path(folder,'error.txt'))
   result<-data.frame(id=id,r_nll_start=NaN,r_nll_fit=NaN,r_gradient_max=Inf,r_hessian_min=NaN,r_convergence=999L,r_objective_disagreement=Inf)
   cat(id,'ERROR',detail,'\n')
  }
  rows[[length(rows)+1L]]<-result
  write_tsv(do.call(rbind,rows),file.path(out,'summary.tsv'))
  cat(id,'R_GRADIENT',result$r_gradient_max,'R_CONVERGENCE',result$r_convergence,'\n')
 }
 writeLines(c(paste('R',getRversion()),paste('TMB',packageVersion('TMB')),marker),file.path(out,'runtime.txt'))
 if(failed)stop('CORE070_SOURCE_R_EXPORT_ERRORS',call.=FALSE)
 cat('CORE070_SOURCE_R_EXPORT_COMPLETE_NOT_PARITY\n')
}
main()
