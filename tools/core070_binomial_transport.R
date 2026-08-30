# Execute actual helper R blocks up to the fit boundary; capture arguments only.
# This is NOT RCall embedding or gllvmTMB fitting qualification.
args <- commandArgs(TRUE)
helper <- if (length(args)) args[[1]] else 'test/parity/parity_helpers.jl'
text <- paste(readLines(helper, warn=FALSE), collapse='\n')
pass <- 0L; fail <- 0L
check <- function(ok,label) {
 if (isTRUE(ok)) pass <<- pass+1L else {fail <<- fail+1L; cat('FAIL ',label,'\n',sep='')}
}
for (route in c('fit_gllvmtmb_parity_loglik(', 'fit_gllvmtmb_parity_loglik_x(')) {
 start <- regexpr(paste0('function ',route),text,fixed=TRUE)[[1]]
 stopifnot(start>0)
 rest <- substring(text,start)
 open <- regexpr('R"""',rest,fixed=TRUE)[[1]]
 rest <- substring(rest,open+4L)
 close <- regexpr('"""',rest,fixed=TRUE)[[1]]
 block <- substring(rest,1L,close-1L)
 # Result extraction requires real fit objects and is intentionally not executed.
 end <- regexpr('    .gllvm_parity_last',block,fixed=TRUE)[[1]]
 stopifnot(end>0)
 block <- substring(block,1L,end-1L)
 for (link in c('logit','probit','cloglog')) for (kind in c('default','common','varying')) {
  e <- new.env(parent=globalenv())
  e$p <- 2L;e$n <- 3L;e$K <- 1L;e$fam <- 'binomial';e$binomial_link <- link
  e$trials_provided <- kind!='default'
  e$y <- if(kind=='default') matrix(c(0,1,1,1,0,0),2,3) else matrix(c(0,1,2,1,0,3),2,3)
  e$trials <- if(kind=='varying') matrix(c(2,3,4,5,6,7),2,3) else matrix(if(kind=='default') 1 else 8,2,3)
  e$x <- c(-1,0,2)
  e$gllvmTMBcontrol <- function(...) list(...)
  e$gllvmTMB <- function(formula,data,unit,trait,family,weights,control) {
   list(formula=formula,data=data,unit=unit,trait=trait,family=family,weights=weights,control=control)
  }
  eval(parse(text=block),envir=e)
  z <- e$fit_r;label <- paste(route,link,kind)
  check(identical(z$family$link,link),paste(label,'link'))
  check(identical(z$weights,if(kind=='default') NULL else as.vector(e$trials)),paste(label,'trials'))
  check(identical(z$data$value,as.vector(e$y)),paste(label,'response'))
  check(identical(as.character(z$data$site),c('1','1','2','2','3','3')),paste(label,'site'))
  check(identical(as.character(z$data$trait),c('t1','t2','t1','t2','t1','t2')),paste(label,'trait'))
  check(identical(z$control,list(n_init=1L,se=FALSE)),paste(label,'control'))
  if (grepl('_x(',route,fixed=TRUE)) check(identical(z$data$x,c(-1,-1,0,0,2,2)),paste(label,'covariate'))
 }
 # Verify other-family weight selection independently, using the actual assignment.
 lines <- strsplit(block,'\n',fixed=TRUE)[[1]]
 assignment <- lines[grepl('weights_vec <-',lines,fixed=TRUE)]
 stopifnot(length(assignment)==1L)
 for (f in c('betabinomial','poisson','gaussian','negbinomial','beta')) {
  e$fam <- f;eval(parse(text=assignment),envir=e)
  expected <- if(f=='betabinomial') as.vector(e$trials) else NULL
  check(identical(e$weights_vec,expected),paste(route,f,'weight routing'))
 }
}
cat(sprintf('BINOMIAL_TRANSPORT_CAPTURE pass=%d fail=%d fits=0 embedding=unqualified\n',pass,fail))
quit(status=if(fail) 1L else 0L)
