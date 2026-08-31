# Fixed finite contract; capture-only until parameter maps are reviewed.
df<-expand.grid(site=factor(paste0('u',1:18)),trait=factor(paste0('t',1:3)))
df$species<-factor(rep(paste0('g',rep(1:6,each=3)),3),levels=paste0('g',1:6))
df$value<-sin(seq_len(nrow(df))/3)+as.integer(df$trait)/5
C<-0.7*diag(6)+0.3;dimnames(C)<-list(levels(df$species),levels(df$species))
fixtures<-list(gaussian=df,C=C)
control<-gllvmTMBcontrol(n_init=1L,se=FALSE,aghq=FALSE)
cases<-list()
add<-function(id,term) {
 call<-substitute(gllvmTMB(FORMULA,df,cluster='species',control=control),list(FORMULA=as.formula(paste('value~0+trait+',term))))
 # Do not infer exact parameter mapping from constructors: inspect the capture.
 check<-function(x,n) x$data$n_traits==3L && x$data$n_sites==18L && all(x$data$family_id_vec==0L) && x$data$use_aghq==0L && length(x$random)>0L
 cases[[length(cases)+1L]]<<-list(id=paste0('MODE-',id),call=call,expected='PREPARED',check=check,error_class=NULL,error_contains=NULL)
}
add('ORD-INDEP','indep(0+trait|site)')
add('ORD-COMMON','indep(0+trait|site,common=TRUE)')
add('ORD-DEP','dep(0+trait|site)')
add('ANIMAL-INDEP','animal_indep(0+trait|species,A=C)')
add('ANIMAL-COMMON','animal_indep(0+trait|species,A=C,common=TRUE)')
add('ANIMAL-DEP','animal_dep(0+trait|species,A=C)')
add('KERNEL-INDEP','kernel_indep(species,K=C,name="known")')
add('KERNEL-COMMON','kernel_indep(species,K=C,name="known",common=TRUE)')
add('KERNEL-DEP','kernel_dep(species,K=C,name="known")')
