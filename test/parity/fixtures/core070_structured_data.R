# Deterministic source fixtures, shared by qualification and public captures.
df<-expand.grid(site=factor(sprintf('u%02d',1:12)),trait=factor(paste0('t',1:3)))
df$species<-factor(rep(rep(c('a','b','c'),each=4),3),levels=c('a','b','c'))
df$value<-sin(seq_len(nrow(df))/3)+as.integer(df$trait)/5
tree<-ape::read.tree(text='((a:1,b:1):1,c:2);')
C<-.7*diag(3)+.3;dimnames(C)<-list(levels(df$species),levels(df$species))
K2<-.6*diag(3)+.4*tcrossprod(c(1,-1,1));dimnames(K2)<-dimnames(C)
ped<-data.frame(id=c('a','b','c','d'),sire=c(NA,NA,'a','a'),dam=c(NA,NA,'b','b'))
dp<-df;dp$animal<-factor(rep(rep(c('c','d'),each=6),3),levels=c('c','d'))
ds<-expand.grid(site=factor(paste0('s',1:4)),trait=factor(paste0('t',1:3)))
ds$species<-ds$site;ds$x<-rep(c(0,1,0,1),3);ds$y<-rep(c(0,0,1,1),3)
ds$value<-cos(seq_len(nrow(ds))/3)+as.integer(ds$trait)/5
set.seed(701L)
mesh<-make_mesh(ds,c('x','y'),cutoff=.25)
fixtures<-list(gaussian=df,tree=tree,C=C,K2=K2,pedigree=ped,pedigree_data=dp,spatial_data=ds,mesh=mesh)
