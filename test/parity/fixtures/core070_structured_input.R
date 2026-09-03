# Public-call inventory fixed before execution. Reuse the qualified mesh bytes.
suppressPackageStartupMessages(library(Matrix))
fixtures<-readRDS('inputs/fixtures.rds');list2env(fixtures,environment())
df<-gaussian;dp<-pedigree_data;ds<-spatial_data;ped<-pedigree
bad_tree<-tree;bad_tree$edge.length[[1]]<-bad_tree$edge.length[[1]]+.1
negative_tree<-tree;negative_tree$edge.length[[1]]<--1
missing_ped<-ped;missing_ped$sire[[3]]<-'absent'
cycle_ped<-ped;cycle_ped$sire[[1]]<-'c'
asymK<-C;asymK[1,2]<-.5
indefK<-C;indefK[1,1]<--1
raw_mesh<-mesh$mesh
short_mesh<-mesh;short_mesh$A_st<-mesh$A_st[1:9,,drop=FALSE];short_mesh$loc_xy<-mesh$loc_xy[1:9,,drop=FALSE]
control<-gllvmTMBcontrol(n_init=1L,se=FALSE,aghq=FALSE,aghq_ridge=Inf)
cases<-list()
add<-function(id,term,data='df',cluster='species',mesharg=NULL,error=NULL) {
 call<-substitute(gllvmTMB(FORMULA,DATA,cluster=GROUP,family=stats::gaussian(),control=control),list(FORMULA=as.formula(paste('value~0+trait+',term)),DATA=as.name(data),GROUP=cluster))
 if(!is.null(mesharg))call[['mesh']]<-as.name(mesharg)
 nsites<-if(data=='ds')4L else 12L
 check<-local({ns<-nsites;function(x,n) x$data$n_traits==3L&&x$data$n_sites==ns&&all(x$data$family_id_vec==0L)&&x$data$use_aghq==0L&&length(x$random)>0L})
 cases[[length(cases)+1L]]<<-list(id=paste0('STRUCT-',id),call=call,expected=if(is.null(error))'PREPARED' else 'REJECTED_BEFORE_TAPE',check=check,error_class=if(is.null(error))NULL else 'error',error_contains=error)
}
add('PHY-TREE-RR','phylo_latent(species,d=1,tree=tree)')
add('PHY-DENSE-RR','phylo_latent(species,d=1,vcv=C)')
add('PHY-TREE-PROPTO','phylo_scalar(species,tree=tree)')
add('ANI-PED-SPARSE','animal_latent(animal,d=1,pedigree=ped,unique=FALSE)',data='dp',cluster='animal')
add('KER-SINGLE-PSI','kernel_latent(species,K=C,d=1,name="k1",unique=TRUE)')
add('KER-MULTI','kernel_latent(species,K=C,d=1,name="k1",unique=FALSE)+kernel_latent(species,K=K2,d=1,name="k2",unique=FALSE)')
add('SPA-INDEP','spatial_indep(0+trait|coords)',data='ds',mesharg='mesh')
add('SPA-LATENT','spatial_latent(0+trait|coords,d=1,unique=FALSE)',data='ds',mesharg='mesh')
add('SPA-LATENT-PSI','spatial_latent(0+trait|coords,d=1,unique=TRUE)',data='ds',mesharg='mesh')
add('SPA-DEP','spatial_dep(0+trait|coords)',data='ds',mesharg='mesh')
add('SPA-COMMON-MAP','spatial_indep(0+trait|coords,common=TRUE)',data='ds',mesharg='mesh')
# A diagnostic of auto-Psi loss; PREPARED is not requested-model acceptance.
add('KER-MULTI-PSI-PRUNED','kernel_latent(species,K=C,d=1,name="k1",unique=TRUE)+kernel_latent(species,K=K2,d=1,name="k2",unique=TRUE)')
add('BAD-TREE-ULTRA','phylo_latent(species,d=1,tree=bad_tree)',error='`tree` must be ultrametric')
add('BAD-TREE-NEGATIVE','phylo_latent(species,d=1,tree=negative_tree)',error='non-negative')
add('BAD-PED-PARENT','animal_latent(animal,d=1,pedigree=missing_ped,unique=FALSE)',data='dp',cluster='animal',error='phylo_latent() / phylo_slope() found in formula but')
add('BAD-PED-CYCLE','animal_latent(animal,d=1,pedigree=cycle_ped,unique=FALSE)',data='dp',cluster='animal',error='phylo_latent() / phylo_slope() found in formula but')
second<-'+kernel_latent(species,K=K2,d=1,name="k2",unique=FALSE)'
add('BAD-KER-ASYM',paste0('kernel_latent(species,K=asymK,d=1,name="k1",unique=FALSE)',second),error='must be symmetric')
add('BAD-KER-PSD',paste0('kernel_latent(species,K=indefK,d=1,name="k1",unique=FALSE)',second),error='must be positive semidefinite')
add('BAD-KER-RANK',paste0('kernel_latent(species,K=C,d=4,name="k1",unique=FALSE)',second),error='exceeds the number of traits')
add('BAD-KER-GROUP',paste0('kernel_latent(site,K=C,d=1,name="k1",unique=FALSE)',second),error='requires all')
add('BAD-KER-DEP',paste0('kernel_dep(species,K=C,name="k1")',second),error='Multi-kernel `kernel_dep()` is not in the first engine wave')
add('BAD-KER-PSI',paste0('kernel_latent(species,K=C,d=1,name="k1",unique=FALSE)+kernel_unique(species,K=C,name="k1")',second),error='first multi-kernel engine wave is latent-only')
add('BAD-SPA-RAW','spatial_indep(0+trait|coords)',data='ds',mesharg='raw_mesh',error='as a result of `make_mesh()`')
add('BAD-SPA-ROWS','spatial_indep(0+trait|coords)',data='ds',mesharg='short_mesh',error='projection has 9 rows but the long-format data has 12')
stopifnot(length(cases)==24L)
