# Pure transcription of retained RDS; no fit, tape or oracle loading.
args<-commandArgs(TRUE);stopifnot(length(args)==1L)
options(warnPartialMatchDollar=TRUE)
stopifnot(requireNamespace('jsonlite',quietly=TRUE),requireNamespace('Matrix',quietly=TRUE))
input<-args[[1L]];records<-readRDS(file.path(input,'records.rds'))
shape<-function(x)list(dim=dim(x),values=as.numeric(x))
cases<-lapply(records,function(r) {
 result<-list(id=r[['id']],call=r[['call']],observed=r[['observed']],check=r[['check']],warnings=r[['warnings']],detail=r[['detail']])
 if(identical(r[['observed']],'PREPARED')) {
  x<-readRDS(file.path(input,paste0(r[['id']],'-input.rds')))
  fields<-names(x[['data']])
  result[['data']]<-setNames(lapply(fields,function(k){v<-x[['data']][[k]];if(inherits(v,'Matrix'))v<-as.matrix(v);shape(v)}),fields)
  result[['random']]<-x[['random']]
  result[['parameters']]<-setNames(lapply(names(x[['parameters']]),function(k) {
   v<-x[['parameters']][[k]];m<-x[['map']][[k]]
   c(shape(v),list(map=if(is.null(m))NULL else as.integer(m),free=if(is.null(m))length(v) else length(unique(as.integer(m)[!is.na(m)])),random=k%in%x[['random']]))
  }),names(x[['parameters']]))
 }
 result
})
f<-readRDS(file.path(input,'fixtures.rds'))
mesh<-f[['mesh']]
frozen<-list(C=shape(f[['C']]),K2=shape(f[['K2']]),A_proj=shape(as.matrix(mesh[['A_st']])),spde_M0=shape(as.matrix(mesh[['spde']][['c0']])),spde_M1=shape(as.matrix(mesh[['spde']][['g1']])),spde_M2=shape(as.matrix(mesh[['spde']][['g2']])))
cat(jsonlite::toJSON(list(cases=cases,fixture=frozen),auto_unbox=FALSE,null='null',digits=17,na='null'))
