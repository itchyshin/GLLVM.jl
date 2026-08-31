# Frozen public-call admission cases. PREPARED is not a completed fit.
df<-expand.grid(site=factor(paste0('u',1:18)),trait=factor(paste0('t',1:3)))
df$species<-factor(rep(paste0('g',rep(1:6,each=3)),3),levels=paste0('g',1:6))
df$value<-sin(seq_len(nrow(df))/3)+as.integer(df$trait)/5
df$x<-rep(seq(-1,1,length.out=18),3)
C<-0.7*diag(6)+0.3;dimnames(C)<-list(levels(df$species),levels(df$species))
V<-diag(seq(.1,.4,length.out=nrow(df)))
VB<-block_V(df$species,diag(V),rho_within=.25)
V0<-matrix(0,nrow(df),nrow(df))
mask<-matrix(NA_real_,3,2);mask[1,1]<-.8;mask[3,2]<-0
upper<-mask;upper[1,2]<-99
allfixed<-matrix(c(.8,.1,.2,NA,.7,-.15),3,2)
fixtures<-list(gaussian=df,C=C,V=V,VB=VB,V0=V0,mask=mask,upper=upper,allfixed=allfixed)
control<-gllvmTMBcontrol(n_init=1L,se=FALSE,aghq=FALSE,aghq_ridge=Inf)
cases<-list()
add<-function(id,call,check=NULL,error=NULL) {
 cases[[length(cases)+1L]]<<-list(id=id,call=call,expected=if(is.null(error))'PREPARED' else 'REJECTED_BEFORE_TAPE',check=check,error_class=if(is.null(error))NULL else 'error',error_contains=error)
}
maskcheck<-function(field,free,pins) {
 force(field);force(free);force(pins)
 function(x,n) {
  m<-as.integer(x$map[[field]])
  x$data$n_traits==3L && all(x$data$family_id_vec==0L) &&
   n(x,field)==free && length(x$parameters[[field]])==5L &&
   identical(which(is.na(m)),as.integer(names(pins))) &&
   identical(as.numeric(x$parameters[[field]][as.integer(names(pins))]),unname(pins))
 }
}
knowncheck<-function(V,family=0L) {
 force(V);force(family)
 function(x,n) x$data$use_equalto==1L && identical(x$random,'e_eq') &&
  all(x$data$family_id_vec==family) && identical(as.numeric(x$data$y),as.numeric(if(family==0L)df$value else counts$value)) &&
  max(abs(solve(as.matrix(x$data$V_inv))-V-diag(1e-8,nrow(V))))<1e-12
}
add('MASK-B-PINS',quote(gllvmTMB(value~0+trait+latent(0+trait|site,d=2,unique=FALSE),df,lambda_constraint=list(B=mask),control=control)),maskcheck('theta_rr_B',3L,c('1'=.8,'5'=0)))
add('MASK-B-UPPER',quote(gllvmTMB(value~0+trait+latent(0+trait|site,d=2,unique=FALSE),df,lambda_constraint=list(B=upper),control=control)),maskcheck('theta_rr_B',3L,c('1'=.8,'5'=0)))
add('MASK-PHY-PINS',quote(gllvmTMB(value~0+trait+animal_latent(species,A=C,d=2,unique=FALSE),df,cluster='species',lambda_constraint=list(phy=mask),control=control)),maskcheck('theta_rr_phy',3L,c('1'=.8,'5'=0)))
add('MASK-PHY-INDEP-CONFLICT',quote(gllvmTMB(value~0+trait+animal_indep(0+trait|species,A=C),df,cluster='species',lambda_constraint=list(phy=mask),control=control)),error='supplies its own diagonal lambda_constraint')
add('MASK-B-DIM',quote(gllvmTMB(value~0+trait+latent(0+trait|site,d=2,unique=FALSE),df,lambda_constraint=list(B=matrix(NA_real_,3,3)),control=control)),error='lambda_constraint matrix has wrong dimensions.')
add('MASK-B-NONMATRIX',quote(gllvmTMB(value~0+trait+latent(0+trait|site,d=2,unique=FALSE),df,lambda_constraint=list(B=rep(NA_real_,6)),control=control)),error='lambda_constraint entries must be matrices.')
add('MASK-B-SLOPE',quote(gllvmTMB(value~0+trait+latent(1+x|site,d=1,unique=FALSE),df,lambda_constraint=list(B=mask),control=control)),error='not yet implemented for augmented ordinary `latent()` random-regression slopes.')
add('MASK-B-ALLFIXED',quote(gllvmTMB(value~0+trait+latent(0+trait|site,d=2,unique=FALSE),df,lambda_constraint=list(B=allfixed),control=control)),maskcheck('theta_rr_B',0L,c('1'=.8,'2'=.7,'3'=.1,'4'=.2,'5'=-.15)))
add('KNOWN-EXACT',quote(gllvmTMB(value~0+trait+meta_V(V=V),df,known_V=V,control=control)),knowncheck(V))
add('KNOWN-ALIAS',quote(gllvmTMB(value~0+trait+meta_known_V(V=V),df,known_V=V,control=control)),knowncheck(V))
add('KNOWN-BLOCK',quote(gllvmTMB(value~0+trait+meta_V(V=VB),df,known_V=VB,control=control)),knowncheck(VB))
add('KNOWN-ZERO',quote(gllvmTMB(value~0+trait+meta_V(V=V0),df,known_V=V0,control=control)),knowncheck(V0))
add('KNOWN-MISSING',quote(gllvmTMB(value~0+trait+meta_V(V=V),df,control=control)),error='`known_V` is NULL.')
add('KNOWN-DIM',quote(gllvmTMB(value~0+trait+meta_V(V=V),df,known_V=V[-1,-1],control=control)),error='known_V must be n_obs x n_obs')
add('KNOWN-PROP',quote(gllvmTMB(value~0+trait+meta_V(V=V,type='proportional'),df,known_V=V,control=control)),error='`meta_V(type = "proportional")` is not implemented.')
add('KNOWN-LIST',quote(gllvmTMB(value~0+trait+meta_V(V=V),df,known_V=list(V),control=control)),error='known_V must be n_obs x n_obs')
counts<-df;counts$value<-as.numeric(rep(0:4,length.out=nrow(df)))
fixtures$counts<-counts
add('KNOWN-POISSON',quote(gllvmTMB(value~0+trait+meta_V(V=V),counts,known_V=V,family=poisson(),control=control)),knowncheck(V,2L))
