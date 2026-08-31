# Structure-only fixture verification. No package load, optimizer, or DLL.
gllvmTMBcontrol <- function(...) list(...)
source('test/parity/fixtures/core070_covariance_fits.R')
ids <- c('FIT-MODE-ORD-DEP',paste0('FIT-MODE-',rep(c('ANIMAL','KERNEL'),each=3),
                                 '-',rep(c('INDEP','COMMON','DEP'),2)))
stopifnot(identical(vapply(cases,`[[`,'','id'),ids))
for (x in cases) {
 stopifnot(identical(dim(x$Y),c(3L,36L)),
   identical(x$data$value,unname(x$Y[cbind(as.integer(x$data$trait),as.integer(x$data$site))])),
   identical(as.integer(x$data$trait),rep(1:3,each=36)),
   identical(as.integer(x$data$site),rep(1:36,3)),
   identical(as.integer(x$data$species),rep(rep(1:12,each=3),3)),
   qr(t(sweep(x$Y,1,rowMeans(x$Y))))$rank==3L,
   identical(dim(x$C),c(12L,12L)),max(abs(x$C-(.7*diag(12)+.3)))==0)
 cat(x$id,'seed',x$seed,'rank3\n')
}
for(i in 2:4) stopifnot(identical(cases[[i]]$Y,cases[[i+3]]$Y))
cat('COVARIANCE_FITTING_FIXTURE_STRUCTURE_PASS\n')
