# Capture public frozen-R inputs before the original MakeADFun body executes.
# PREPARED means only that this boundary was reached, never fit convergence.
main <- function() {
 args<-commandArgs(TRUE);stopifnot(length(args)==3L)
 lib<-args[[1]];fixture<-args[[2]];out<-args[[3]]
 stopifnot(!dir.exists(out));dir.create(out,recursive=TRUE)
 .libPaths(c(lib,.libPaths()));suppressPackageStartupMessages(library(gllvmTMB))
 stopifnot(normalizePath(find.package('gllvmTMB'))==normalizePath(file.path(lib,'gllvmTMB')))
 marker<-readLines(file.path(lib,'gllvmTMB','CORE070_SOURCE_PIN.toml'))
 stopifnot(any(grepl('b4d5fee64def88bc768dda1f1f77c29b295edd86',marker,fixed=TRUE)))
 env<-new.env(parent=globalenv());sys.source(fixture,envir=env)
 cases<-env$cases;stopifnot(length(cases)>0L,!anyDuplicated(vapply(cases,`[[`,'','id')))
 capture<-new.env(parent=emptyenv());capture$n<-0L
 assign('.core070_capture',capture,envir=.GlobalEnv)
 trace('MakeADFun',where=asNamespace('TMB'),print=FALSE,tracer=quote({
  e<-get('.core070_capture',envir=.GlobalEnv);e$n<-e$n+1L
  if(!identical(DLL,'gllvmTMB')) stop(structure(list(message='unexpected DLL at capture',call=NULL),class=c('core070_capture_fault','error','condition')))
  e$value<-list(data=data,parameters=parameters,map=map,random=random,DLL=DLL)
  stop(structure(list(message='CORE070_PREPARED_INPUT_STOP',call=NULL),class=c('core070_prepared','error','condition')))
 }))
 on.exit({untrace('MakeADFun',where=asNamespace('TMB'));rm('.core070_capture',envir=.GlobalEnv)},add=TRUE)
 # A broken/wrong tape request must not be mislabeled as prepared.
 bad<-tryCatch(TMB::MakeADFun(data=list(),parameters=list(),DLL='wrong'),error=identity)
 stopifnot(inherits(bad,'core070_capture_fault'),!exists('value',capture,inherits=FALSE))
 free_count<-function(x,name) {
  stopifnot(name %in% names(x$parameters))
  m<-x$map[[name]]
  if(is.null(m)) length(x$parameters[[name]]) else length(unique(as.integer(m)[!is.na(m)]))
 }
 rows<-list();summaries<-list();failed<-FALSE
 for(case in cases) {
  capture$n<-0L;if(exists('value',capture,inherits=FALSE))rm('value',envir=capture)
  warnings<-character();messages<-character()
  set.seed(700L)
  result<-withCallingHandlers(tryCatch(eval(case$call,env),error=identity),warning=function(w){warnings<<-c(warnings,conditionMessage(w));invokeRestart('muffleWarning')},message=function(m){messages<<-c(messages,conditionMessage(m));invokeRestart('muffleMessage')})
  prepared<-inherits(result,'core070_prepared') && capture$n==1L && exists('value',capture,inherits=FALSE)
  status<-if(prepared)'PREPARED' else if(capture$n==0L && inherits(result,'error'))'REJECTED_BEFORE_TAPE' else 'HARNESS_ERROR'
  check<-FALSE;detail<-if(inherits(result,'error'))conditionMessage(result) else 'unexpected normal return'
  if(identical(case$expected,'PREPARED') && prepared) {
   x<-capture$value
   check<-isTRUE(tryCatch(case$check(x,free_count),error=function(e){detail<<-conditionMessage(e);FALSE}))
   saveRDS(x,file.path(out,paste0(case$id,'-input.rds')))
   summaries[[length(summaries)+1L]]<-data.frame(id=case$id,random=paste(x$random,collapse=','),n_traits=x$data$n_traits,n_sites=x$data$n_sites,families=paste(sort(unique(x$data$family_id_vec)),collapse=','),diag_B_skip=paste(x$data$diag_B_skip,collapse=','),free_theta_diag_B=free_count(x,'theta_diag_B'),free_log_sigma_eps=free_count(x,'log_sigma_eps'),kernel_tiers=x$data$n_kernel_tiers,kernel_has_diag=paste(x$data$kernel_has_diag,collapse=','))
  } else if(identical(case$expected,'REJECTED_BEFORE_TAPE') && identical(status,case$expected)) {
   check<-inherits(result,case$error_class) && grepl(case$error_contains,gsub('[[:space:]]+',' ',detail),fixed=TRUE)
  }
  row<-list(id=case$id,expected=case$expected,observed=status,check=check,capture_count=capture$n,condition_class=class(result),detail=detail,warnings=warnings,messages=messages,call=paste(deparse(case$call),collapse=' '))
  saveRDS(row,file.path(out,paste0(case$id,'-record.rds')))
  rows[[length(rows)+1L]]<-row
  cat(case$id,status,if(check)'PASS' else 'FAIL',sep='\t');cat('\n')
  if(!check)cat(detail,'\n',file=stderr())
  failed<-failed || !check
 }
 if(length(summaries))write.table(do.call(rbind,summaries),file.path(out,'prepared-summary.tsv'),sep='\t',row.names=FALSE,quote=TRUE)
 saveRDS(rows,file.path(out,'records.rds'));saveRDS(env$fixtures,file.path(out,'fixtures.rds'))
 writeLines(c(paste('R',getRversion()),paste('package',packageVersion('gllvmTMB')),paste('TMB',packageVersion('TMB')),paste('Matrix',packageVersion('Matrix')),marker),file.path(out,'runtime.txt'))
 if(failed)stop('CORE070_FIT_INPUT_CASE_FAILURE',call.=FALSE)
 cat('CORE070_FIT_INPUT_PASS_NO_OBJECTIVE_OR_OPTIMIZER\n')
}
main()
