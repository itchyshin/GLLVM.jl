args<-commandArgs(TRUE);stopifnot(length(args)==3L)
lib<-args[[1L]];fixture<-args[[2L]];out<-args[[3L]]
stopifnot(!dir.exists(out));dir.create(out,recursive=TRUE)
.libPaths(c(lib,.libPaths()));suppressPackageStartupMessages(library(gllvmTMB))
stopifnot(normalizePath(find.package('gllvmTMB'))==normalizePath(file.path(lib,'gllvmTMB')))
dependencies<-c('ape','Matrix','fmesher','gllvmTMB','TMB')
for(p in dependencies){stopifnot(requireNamespace(p,quietly=TRUE));cat(p,as.character(packageVersion(p)),find.package(p),'\n')}
env<-new.env(parent=globalenv());sys.source(fixture,envir=env)
f<-env$fixtures;m<-f$mesh
stopifnot(ape::is.ultrametric(f$tree),all(f$tree$edge.length>0),inherits(m,'gllvmTMBmesh'),
 inherits(m$A_st,'sparseMatrix'),nrow(m$A_st)==nrow(f$spatial_data),ncol(m$A_st)==m$mesh$n,
 all(abs(Matrix::rowSums(m$A_st)-1)<1e-8),all(c('c0','g1','g2')%in%names(m$spde)))
saveRDS(f,file.path(out,'fixtures.rds'))
cat('mesh_vertices',m$mesh$n,'projection',dim(m$A_st),'\n')
writeLines(capture.output(sessionInfo()),file.path(out,'session-info.txt'))
cat('CORE070_STRUCTURED_FIXTURES_QUALIFIED_NO_FIT\n')
