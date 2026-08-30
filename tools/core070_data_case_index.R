# Parse declarations only: never source the fixture or execute model functions.
x <- parse(file=commandArgs(TRUE)[[1]])
rows <- lapply(Filter(function(e) is.call(e) && identical(e[[1]],as.name('add')),as.list(x)),function(e) {
  args <- as.list(e)[-1]
  stopifnot(is.character(args[[1]]),length(args[[1]])==1)
  rejected <- 'error' %in% names(args)
  data.frame(id=args[[1]],classification=if(rejected) 'rejected' else 'required_core',
    reference_expression=paste(deparse(args[[2]],width.cutoff=500L),collapse=' '),
    expectation=paste(deparse(if(rejected) args[['error']] else args[[3]],width.cutoff=500L),collapse=' '))
})
result <- do.call(rbind,rows)
stopifnot(nrow(result)==56L,!anyDuplicated(result$id))
write.table(result,stdout(),sep='\t',row.names=FALSE,quote=TRUE)
