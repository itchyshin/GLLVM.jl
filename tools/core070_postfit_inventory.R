# Parse source; never source/evaluate function bodies or fit a model.
a<-commandArgs(TRUE);stopifnot(length(a)==3L)
source<-a[[1]];requested<-read.delim(a[[2]],check.names=FALSE,stringsAsFactors=FALSE);out<-a[[3]]
found<-list()
for(path in list.files(file.path(source,'R'),pattern='\\.R$',full.names=TRUE)) {
 code<-parse(path,keep.source=TRUE);refs<-attr(code,'srcref')
 for(i in seq_along(code)) {
  x<-code[[i]]
  if(!is.call(x)||!is.symbol(x[[1]])||!as.character(x[[1]])%in%c('<-','=')||length(x)!=3L||!is.symbol(x[[2]]))next
  name<-as.character(x[[2]])
  if(!name%in%requested$function_name)next
  stopifnot(is.null(found[[name]]))
  rhs<-x[[3]];ref<-as.integer(refs[[i]])
  isfun<-is.call(rhs)&&identical(rhs[[1]],as.name('function'))
  signature<-if(isfun)paste(deparse(rhs[[2]],width.cutoff=500L),collapse=' ') else paste(deparse(rhs,width.cutoff=500L),collapse=' ')
  found[[name]]<-list(name=name,file=paste0('R/',basename(path)),line_start=ref[[1]],line_end=ref[[3]],kind=if(isfun)'function' else 'alias',formals=signature)
 }
}
# Re-exported generics have a namespace import, not a local function body.
ns<-readLines(file.path(source,'NAMESPACE'))
for(name in setdiff(requested$function_name,names(found))) {
 hits<-which(grepl(paste0('^importFrom\\([^,]+,',name,'\\)$'),ns))
 if(length(hits)==1L)found[[name]]<-list(name=name,file='NAMESPACE',line_start=hits,line_end=hits,kind='reexport',formals=ns[[hits]])
}
missing<-setdiff(requested$function_name,names(found));if(length(missing))stop('Missing definitions: ',paste(missing,collapse=', '))
jsonlite::write_json(found,out,pretty=TRUE,auto_unbox=TRUE)
cat('FROZEN_POSTFIT_DEFINITIONS_PARSED',length(found),'\n')
