# Fixed-coordinate Gaussian equality; not fitted-model or recovery evidence.
using GLLVM, Test, LinearAlgebra, ForwardDiff
@assert realpath(Base.pkgdir(GLLVM)) == realpath(pwd())
root=ARGS[1]
readrows(path)=split.(readlines(path)[2:end],'\t')
@testset "Frozen Gaussian fixed-point model identity" begin
 for model in ("DEFAULT","COMMON","LOADINGS"), point in 1:2
  id="GAUSS-$model-P$point";dir=joinpath(root,id)
  dr=readrows(joinpath(dir,"data.tsv"));Y=fill(NaN,3,18)
  for row in dr;Y[parse(Int,row[1]),parse(Int,row[2])]=parse(Float64,row[3]);end
  pr=readrows(joinpath(dir,"parameters.tsv"));names=[r[1] for r in pr];θ=[parse(Float64,r[2]) for r in pr];rg=[parse(Float64,r[3]) for r in pr]
  c=only(readrows(joinpath(dir,"contract.tsv")));sigma=parse(Float64,c[3]);psi=c[4]=="1";common=c[5]=="1";rnll=parse(Float64,c[6]);rdense=parse(Float64,c[7])
  @test Set(names)==Set(psi ? ["b_fix","theta_rr_B","theta_diag_B"] : ["b_fix","theta_rr_B","log_sigma_eps"])
  bi=findall(==("b_fix"),names);li=findall(==("theta_rr_B"),names);di=findall(==("theta_diag_B"),names);si=findall(==("log_sigma_eps"),names)
  @test length(bi)==3 && length(li)==3 && length(di)==(psi ? (common ? 1 : 3) : 0) && length(si)==(psi ? 0 : 1)
  function quantities(t)
   β=t[bi];Λ=reshape(t[li],3,1);s=psi ? sigma : exp(only(t[si]))
   d=psi ? (common ? fill(exp(2*only(t[di])),3) : exp.(2 .* t[di])) : zeros(eltype(t),3)
   return β,Λ,s,d
  end
  function native(t)
   β,Λ,s,d=quantities(t)
   -GLLVM.gaussian_marginal_loglik(Y.-β,Λ,s;σ²_B=d)
  end
  function dense(t)
   β,Λ,s,d=quantities(t);V=Λ*Λ'+Diagonal(d.+s^2);r=Y.-β
   (length(Y)*log(2π)+size(Y,2)*logdet(Symmetric(V))+sum(r.*(V\r)))/2
  end
  jnll=native(θ);dnll=dense(θ);jg=ForwardDiff.gradient(native,θ);dg=ForwardDiff.gradient(dense,θ)
  error=maximum(abs.(jg.-rg)./(1 .+ abs.(rg)))
  @test abs(jnll-rnll)<=1e-6
  @test abs(jnll-rdense)<=1e-6
  @test abs(jnll-dnll)<=1e-8
  @test error<=1e-6
  @test maximum(abs.(jg.-dg)./(1 .+abs.(dg)))<=1e-8
  # Discriminating control: a shifted intercept is a different fixed point.
  altered=copy(θ);altered[first(bi)]+=0.2
  @test abs(native(altered)-rnll)>1e-6
  println(id," abs_delta=",abs(jnll-rnll)," scaled_gradient_error=",error)
 end
end
