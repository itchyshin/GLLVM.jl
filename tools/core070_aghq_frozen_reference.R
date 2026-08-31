args <- commandArgs(TRUE)
stopifnot(length(args)==2L)
# Evaluate only the named frozen helper; never source the package's fit machinery.
exprs <- parse(args[[1L]])
selected <- Filter(function(e) is.call(e) && identical(e[[1L]],as.name("<-")) &&
  identical(e[[2L]],as.name(".gllvmTMB_aghq_adapt")),as.list(exprs))
stopifnot(length(selected)==1L)
env <- new.env(parent=baseenv());eval(selected[[1L]],env)
m <- c(.1,-.2)
Hs <- list(matrix(c(2,.3,.3,1),2),diag(c(-.25,2)),diag(c(0,2)),diag(c(1e-12,2)),matrix(c(2,.2,.4,1),2))
rows <- lapply(seq_along(Hs),function(i) {
  H <- Hs[[i]]
  obj <- list(fn=function(x) 0,env=list(last.par=setNames(m,c("z_B","z_B")),random=1:2,
    spHess=function(full,random) H))
  a <- env$.gllvmTMB_aghq_adapt(obj,numeric(),2L,1L)
  B <- matrix(a$Lt[1,],2,2,byrow=TRUE)
  c(i,a$mode[1,],as.numeric(B),a$logdet[1])
})
write.table(do.call(rbind,rows),args[[2L]],row.names=FALSE,col.names=FALSE,sep="\t",quote=FALSE)
cat("CORE070_AGHQ_FROZEN_R_FACTORS_PASS 5 reference branches\n")
