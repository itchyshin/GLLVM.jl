# Fixed mean-design extension of one declared kernel-independent Gaussian case.
source('test/parity/fixtures/core070_covariance_fits.R')
base_case <- cases[[5L]]
stopifnot(base_case$id=='FIT-MODE-KERNEL-INDEP')
df <- base_case$data; C <- base_case$C
x <- sin(seq_len(36L)/5)
df$x <- rep(x,3L)
df$value <- df$value+.65*df$x
Y <- matrix(df$value,nrow=36L,ncol=3L)
control <- gllvmTMBcontrol(n_init=1L,se=FALSE,aghq=FALSE,
  optArgs=list(control=list(rel.tol=1e-12,sing.tol=1e-12,eval.max=2000L,iter.max=1500L)))
source_mean_call <- quote(gllvmTMB(value~0+trait+x+
  kernel_indep(species,K=C,name='known'),df,cluster='species',control=control))
source_mean_id <- 'SOURCE-MEAN-KERNEL-INDEP-X'
source_mean_seed <- 700801L
