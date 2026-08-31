using GLLVM, LinearAlgebra, Random, Statistics
using GLLVM: Optim, ForwardDiff
    rng=MersenneTwister(8103201);p,n=3,72;groups=repeat(1:24;inner=3)
    x=randn(rng,n);truth=[.2,-.4,.5,.8]
    X=zeros(p,n,4)
    for t in 1:p;X[t,:,t].=1;end
    X[:,:,4].=x'
    group_effect=Diagonal([.4,.5,.6])*randn(rng,p,24)
    Y=reshape(reshape(X,p*n,4)*truth,p,n)+group_effect[:,groups]+.35randn(rng,p,n)
    block=SourceCovariance(Matrix{Float64}(I,24,24);groups=groups,mode=:indep)
    f=fit_gaussian_sources(Y;sources=[block],X=X,g_tol=1e-7,iterations=2000)

println("BASELINE ", f)
D=reshape(X,p*n,4)
objective(t)=GLLVM._gaussian_sources_nll(Y,[block],t;X=D)
g=ForwardDiff.gradient(objective,f.parameters)
H=ForwardDiff.hessian(objective,f.parameters)
t=f.parameters-H\g
println("NEWTON_DIAGNOSTIC ", (objective_before=objective(f.parameters),objective_after=objective(t),gradient_after=maximum(abs,ForwardDiff.gradient(objective,t)),stepnorm=norm(t-f.parameters),hessian_min=eigmin(Symmetric(H))))
start=vcat(D\vec(Y),fill(log(.25),3),log(max(std(vec(Y))/2,.1)))
for (name,algorithm) in (("LBFGS_HZ",Optim.LBFGS()),("BFGS_HZ",Optim.BFGS()))
 result=Optim.optimize(objective,start,algorithm,Optim.Options(g_tol=1e-7,iterations=2000);autodiff=:forward)
 local t=Optim.minimizer(result)
 println(name," ",(converged=Optim.converged(result),iterations=Optim.iterations(result),objective=objective(t),gradient=maximum(abs,ForwardDiff.gradient(objective,t))))
end
