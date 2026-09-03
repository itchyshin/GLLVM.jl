# Dense reference verification and a rejected native mapping, not production parity.
using GLLVM, Test, LinearAlgebra, ForwardDiff
@assert realpath(Base.pkgdir(GLLVM))==realpath(pwd())
root=ARGS[1]
readrows(p)=split.(readlines(p)[2:end],'\t')
readmatrix(p)=reduce(vcat,[permutedims(parse.(Float64,r)) for r in readrows(p)])
@testset "Frozen source covariance and native mapping distinction" begin
 for model in ("ANIMAL-LATENT","KERNEL-ONE","KERNEL-TWO"), point in 1:2
  id="$model-P$point";dir=joinpath(root,id);d=readrows(joinpath(dir,"data.tsv"))
  trait=[parse(Int,r[1]) for r in d];site=[parse(Int,r[2]) for r in d];group=[parse(Int,r[3]) for r in d];y=[parse(Float64,r[4]) for r in d]
  c=only(readrows(joinpath(dir,"contract.tsv")));nr=parse(Int,c[3]);rnll=parse(Float64,c[4]);rdense=parse(Float64,c[5])
  Cs=[readmatrix(joinpath(dir,"source-$r.tsv")) for r in 1:nr]
  p=readrows(joinpath(dir,"parameters.tsv"));names=[r[1] for r in p];θ=[parse(Float64,r[2]) for r in p];rg=[parse(Float64,r[3]) for r in p]
  bi=findall(==("b_fix"),names);li=findall(==(nr==2 ? "theta_rr_kernel" : "theta_rr_phy"),names);si=findall(==("log_sigma_eps"),names)
  @test length(bi)==3 && length(li)==3nr && length(si)==1 && length(θ)==4+3nr
  function covariance(t)
   Λ=reshape(t[li],3,nr);s2=exp(2*only(t[si]));V=Matrix(Diagonal(fill(s2,length(y))))
   for r in 1:nr;v=Λ[trait,r];V=V+(v*v').*Cs[r][group,group];end
   V
  end
  function dense(t)
   V=covariance(t);resid=y-t[bi][trait];ch=cholesky(Symmetric(V))
   (length(y)*log(2π)+logdet(ch)+dot(resid,ch\resid))/2
  end
  value=dense(θ);g=ForwardDiff.gradient(dense,θ);error=maximum(abs.(g.-rg)./(1 .+abs.(rg)))
  @test abs(value-rnll)<=1e-6
  @test abs(value-rdense)<=1e-8
  @test error<=1e-6
  @test isposdef(Symmetric(covariance(θ)))
  # Three repeated observations per source group make the source covariance
  # rank deficient on observation units; independent noise still makes V PD.
  sites=sort(unique(site));gs=[only(unique(group[site.==s])) for s in sites]
  Kobs=Cs[1][gs,gs]
  @test rank(Kobs;rtol=1e-10)==6 && length(sites)==18
  altered=copy(θ);altered[first(bi)]+=0.2
  @test abs(dense(altered)-rnll)>1e-6
  if nr==2
   # Legal one-observation-per-group domain for the existing matrix-normal
   # function. Even here it correlates the residual and is a different model.
   Y=zeros(3,18);for j in eachindex(y);Y[trait[j],site[j]]=y[j];end
   selected=[findfirst(==(k),gs) for k in 1:6];small=Y[:,selected].-θ[bi]
   C=Cs[2];lambda=reshape(θ[li][4:6],3,1);sigma=exp(only(θ[si]))
   Q=kron(C,lambda*lambda')+sigma^2*I(18)
   rr=vec(small);correct=(18log(2π)+logdet(Symmetric(Q))+dot(rr,Q\rr))/2
   eigenvectors,eigenvalues=GLLVM._coevolution_kron_precompute(C)
   legacy=GLLVM._coevolution_kron_nll(vcat(vec(lambda),log(sigma)),small,eigenvectors,eigenvalues,3,6,1)
   @test abs(legacy-correct)>1e-6
   println(id," MATRIX_NORMAL_NOT_EQUIVALENT delta=",legacy-correct)
  end
  println(id," abs_delta=",abs(value-rnll)," scaled_gradient_error=",error)
 end
end
