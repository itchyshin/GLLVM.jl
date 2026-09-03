# Actual public preparation, not isolated parser/helper admission.
df<-expand.grid(site=factor(paste0('u',1:18)),trait=factor(paste0('t',1:3)))
df$species<-factor(rep(paste0('g',rep(1:6,each=3)),3),levels=paste0('g',1:6))
df$value<-sin(seq_len(nrow(df))/3)+as.integer(df$trait)/5
df$x<-rep(seq(-1,1,length.out=18),3);df$x2<-df$x^2-.3
counts<-df;counts$value<-as.numeric(rep(0:4,length.out=nrow(df)))
C<-0.7*diag(6)+0.3;dimnames(C)<-list(levels(df$species),levels(df$species))
fixtures<-list(gaussian=df,poisson=counts,C=C)
control<-gllvmTMBcontrol(n_init=1L,se=FALSE,aghq=FALSE,aghq_ridge=Inf)
cases<-list()
add<-function(id,term,poisson=FALSE,error=NULL) {
 call<-substitute(gllvmTMB(FORMULA,DATA,cluster='species',family=FAMILY,control=control),list(FORMULA=as.formula(paste('value~0+trait+',term)),DATA=as.name(if(poisson)'counts' else 'df'),FAMILY=if(poisson)quote(stats::poisson()) else quote(stats::gaussian())))
 fid<-if(poisson)2L else 0L
 check<-local({family_id<-fid;function(x,n)x$data$n_traits==3L&&x$data$n_sites==18L&&all(x$data$family_id_vec==family_id)&&x$data$use_aghq==0L&&length(x$random)>0L})
 cases[[length(cases)+1L]]<<-list(id=paste0('SLOPE-',id),call=call,expected=if(is.null(error))'PREPARED' else 'REJECTED_BEFORE_TAPE',check=check,error_class=if(is.null(error))NULL else 'error',error_contains=error)
}
add('ORD-LAT-DEFAULT','latent(1+x|site,d=2)')
add('ORD-LAT-NOUNIQUE','latent(1+x|site,d=2,unique=FALSE)')
add('ORD-LAT-RANK4','latent(1+x|site,d=4,unique=FALSE)')
add('ORD-LAT-RANK7','latent(1+x|site,d=7,unique=FALSE)',error='exceeds the augmented random-regression coefficient dimension')
add('ORD-INDEP-BAR','indep(1+x|site)',error='`indep()` augmented LHS is not yet supported.')
add('ORD-INDEP-DBAR','indep(1+x||site)',error='is not yet supported for `indep()`.')
add('ORD-DEP-BAR','dep(1+x|site)',error='`dep()` augmented LHS is not yet supported.')
add('ORD-DEP-DBAR','dep(1+x||site)',error='is not yet supported for `dep()`.')
add('ANIMAL-INDEP-BAR','animal_indep(1+x|species,A=C)')
add('ANIMAL-INDEP-DBAR','animal_indep(1+x||species,A=C)')
add('ANIMAL-DEP-BAR','animal_dep(1+x|species,A=C)')
add('ANIMAL-DEP-DBAR','animal_dep(1+x||species,A=C)')
add('ANIMAL-LAT-NOUNIQUE','animal_latent(1+x|species,A=C,d=2,unique=FALSE)')
add('ANIMAL-LAT-DEFAULT','animal_latent(1+x|species,A=C,d=2)')
add('ANIMAL-DEP-MULTIGAUSS','animal_dep(1+x+x2|species,A=C)')
add('ANIMAL-DEP-MULTIPOIS','animal_dep(1+x+x2|species,A=C)',poisson=TRUE)
add('ORD-LAT-POISDEFAULT','latent(1+x|site,d=2)',poisson=TRUE)
add('ORD-LAT-POISNOUNIQUE','latent(1+x|site,d=2,unique=FALSE)',poisson=TRUE)
add('ORD-LAT-COMBINE','latent(1+x|site,d=2)+latent(0+trait|site,d=1)',error='Do not combine augmented ordinary')
add('ANIMAL-LAT-RANK4','animal_latent(1+x|species,A=C,d=4,unique=FALSE)',error='exceeds the number of traits')
# Retain actual reference discrepancies, not successful requested slope models.
for(i in seq_along(cases))if(cases[[i]]$id %in% c('SLOPE-ANIMAL-DEP-MULTIGAUSS','SLOPE-ANIMAL-DEP-MULTIPOIS')) {
 cases[[i]]$check<-function(x,n)x$data$use_phylo_dep_slope==0L&&x$data$use_phylo_rr==1L&&identical(x$random,'g_phy')&&length(x$parameters[['theta_rr_phy']])==6L&&is.null(x$map[['theta_rr_phy']])&&n(x,'theta_rr_phy')==6L
}
add('PHYLO-DEP-MULTIGAUSS','phylo_dep(1+x+x2|species,vcv=C)')
add('PHYLO-DEP-MULTIPOIS','phylo_dep(1+x+x2|species,vcv=C)',poisson=TRUE,error='not yet validated for non-Gaussian families.')
