# Pure transcription of retained RDS; no fit, tape or oracle loading.
args<-commandArgs(TRUE);stopifnot(length(args)==1L)
options(warnPartialMatchDollar=TRUE)
stopifnot(requireNamespace('jsonlite',quietly=TRUE),requireNamespace('Matrix',quietly=TRUE))
input<-args[[1L]];records<-readRDS(file.path(input,'records.rds'))
fields<-c('y','site_id','trait_id','species_id','species_aug_id','phylo_slope_aug_id',
 'family_id_vec','link_id_vec','n_sites','n_traits','n_lhs_cols','n_lhs_cols_lat',
 'n_lhs_cols_B_lat','n_lhs_cols_B_diag','d_B_slope','d_phy_slope','d_phy',
 'use_rr_B_slope','use_diag_B_slope','use_phylo_slope','use_phylo_dep_slope',
 'use_phylo_latent_slope','use_phylo_rr','use_phylo_slope_correlated','use_aghq',
 'Z_B_lat','Z_B_diag','Z_phy_aug','Z_phy_lat','Ainv_phy_rr','Ainv_phy_slope')
shape<-function(x)list(dim=dim(x),values=as.numeric(x))
cases<-lapply(records,function(r) {
 result<-list(id=r[['id']],call=r[['call']],observed=r[['observed']],check=r[['check']],warnings=r[['warnings']],detail=r[['detail']])
 if(identical(r[['observed']],'PREPARED')) {
  x<-readRDS(file.path(input,paste0(r[['id']],'-input.rds')))
  result[['data']]<-setNames(lapply(fields,function(k){v<-x[['data']][[k]];if(inherits(v,'Matrix'))v<-as.matrix(v);shape(v)}),fields)
  result[['random']]<-x[['random']]
  result[['parameters']]<-setNames(lapply(names(x[['parameters']]),function(k) {
   v<-x[['parameters']][[k]];m<-x[['map']][[k]]
   c(shape(v),list(map=if(is.null(m))NULL else as.integer(m),free=if(is.null(m))length(v) else length(unique(as.integer(m)[!is.na(m)])),random=k%in%x[['random']]))
  }),names(x[['parameters']]))
 }
 result
})
cat(jsonlite::toJSON(list(cases=cases),auto_unbox=FALSE,null='null',digits=17,na='null'))
