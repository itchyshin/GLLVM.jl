# Deterministic source-admission fixtures; no fitted-model or recovery claims.
fixture <- function(sources=c("count","detect")) {
  d <- expand.grid(trait=c("a","b"), isdm_source=sources, unit=1:2,
                   stringsAsFactors=FALSE)
  d$value <- ifelse(d$isdm_source=="detect",1,2)
  d$log_support <- log(seq_len(nrow(d))+1)
  d$x <- ifelse(d$isdm_source=="count",seq_len(nrow(d)),NA_real_)
  d$z <- ifelse(d$isdm_source=="detect",seq_len(nrow(d)),NA_real_)
  d
}
laws <- function() isdm_sources(count=poisson(),detect=binomial("cloglog"))
row_ids <- function(f,d) {
  map <- do.call(rbind,lapply(f,.isdm_admitted_law_id))
  map[match(d$isdm_source,names(f)),,drop=FALSE]
}
admitted <- function(f=laws(),d=fixture(),ids=row_ids(f,d),traits=d$trait) {
  .gllvmTMB_integrated_sources_contract(f,d,ids[,"fid"],ids[,"lid"],traits)
}
design_fixture <- function() {
  d <- fixture()
  f <- isdm_sources(count=isdm_source(poisson(),~x),
                    detect=isdm_source(binomial("cloglog"),~z))
  X <- model.matrix(~0+trait,d)
  list(d=d,f=f,X=X)
}
design <- function(x=design_fixture()) {
  .gll_isdm_observation_design(x$X,x$d,x$d$isdm_source,x$f)
}
offset_fixture <- function(off=quote(log_support),allow=TRUE,d=fixture()) {
  f <- laws(); ids <- row_ids(f,d)
  gll_prepare_offset(off,d,environment(),ids[,"fid"],ids[,"lid"],
                     f[match(d$isdm_source,names(f))],d$trait,
                     allow_isdm_cloglog=allow)
}
