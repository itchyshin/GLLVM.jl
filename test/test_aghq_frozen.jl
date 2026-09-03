using Test, GLLVM, LinearAlgebra, Distributions
const AF = GLLVM.ForwardDiff

@testset "AF-01 transformed Gaussian normalization and moments" begin
    m=[0.4,-0.3];S=[1.4 0.3;0.3 0.8];H=inv(S)
    a=GLLVM.aghq_adaptation(m,H);grid=GLLVM.aghq_grid(2,3)
    density=MvNormal(m,S)
    @test GLLVM.aghq_frozen_logintegral(z->logpdf(density,z),a,grid) ≈ 0 atol=1e-12
    nodes=[a.mode+a.inverse_root*grid.nodes[j,:] for j in axes(grid.nodes,1)]
    weights=[exp(a.logjac+grid.logw[j]+logpdf(density,nodes[j])) for j in eachindex(nodes)]
    @test sum(weights .* nodes) ≈ m atol=1e-12
    @test sum(weights[j].*((nodes[j]-m)*(nodes[j]-m)') for j in eachindex(nodes)) ≈ S atol=1e-12
    @test a.inverse_root*a.inverse_root' ≈ S atol=1e-12
    @test !a.curvature_repaired
end

# Independent explicit Poisson joint; no existing marginal kernel inside this callback.
function af_joint(z,beta,loading,y)
    eta=beta+loading*z[1]
    return y*eta-exp(eta)-sum(log,1:y;init=0.0)-z[1]^2/2-log(2pi)/2
end
function af_cache(beta,loading,y)
    lambda=reshape([loading],1,1)
    m=GLLVM._laplace_mode(Poisson(),[y],[1],lambda,[beta],GLLVM.LogLink())
    H=AF.hessian(z->-af_joint(z,beta,loading,y),m)
    return GLLVM.aghq_adaptation(m,H)
end
@testset "AF-02 observed k1 Laplace equivalence" begin
    beta=.2;loading=.7;y=3;a=af_cache(beta,loading,y)
    q=GLLVM.aghq_frozen_logintegral(z->af_joint(z,beta,loading,y),a,GLLVM.aghq_grid(1,1))
    ll=GLLVM.laplace_loglik_site(Poisson(),[y],[1],reshape([loading],1,1),[beta],GLLVM.LogLink();hessian=:observed)
    @test q ≈ ll atol=1e-10
end
@testset "AF-03 fixed-cache gradients and AF-05 chain term" begin
    theta=[.2,.7];y=3;a=af_cache(theta...,y);grid=GLLVM.aghq_grid(1,3)
    objective=t->GLLVM.aghq_frozen_logintegral(z->af_joint(z,t[1],t[2],y),a,grid)
    g=AF.gradient(objective,theta)
    for h in [1e-5,2e-5]
        fd=[(objective(theta+h*Matrix{Float64}(I,2,2)[:,j])-objective(theta-h*Matrix{Float64}(I,2,2)[:,j]))/(2h) for j in 1:2]
        @test maximum(abs.(g-fd)) < 1e-6
    end
    h=1e-5
    fresh=b->GLLVM.aghq_frozen_logintegral(z->af_joint(z,b,theta[2],y),af_cache(b,theta[2],y),grid)
    total=(fresh(theta[1]+h)-fresh(theta[1]-h))/(2h)
    @test abs(total-g[1]) > 1e-7
    @test a.mode == af_cache(theta...,y).mode
end
@testset "AF-04 independent quadrature and refinement" begin
    beta=.2;loading=.7;y=3;a=af_cache(beta,loading,y)
    joint=z->af_joint(z,beta,loading,y)
    # Simpson rule: normalized prior tails beyond12 are negligible here.
    n=24000;h=24/n
    f=x->exp(joint([x]))
    integral=h/3*(f(-12)+f(12)+sum((isodd(i) ? 4 : 2)*f(-12+i*h) for i in 1:n-1))
    truth=log(integral)
    errors=[abs(GLLVM.aghq_frozen_logintegral(joint,a,GLLVM.aghq_grid(1,k))-truth) for k in [3,9,21]]
    @test errors[3]<1e-8
    @test errors[3]<errors[2]<errors[1]
end
@testset "AF-06 curvature repair and AF-07 invalid inputs" begin
    m=[.1,-.2]
    for H in [[2.0 .3;.3 1.0],[-.25 0.;0. 2.],[0. 0.;0. 2.],[1e-12 0.;0. 2.],[2. .4;.2 1.]]
        symmetric=(H+H')/2;raw=eigmin(Symmetric(symmetric));repair=!isposdef(Symmetric(symmetric))
        a=GLLVM.aghq_adaptation(m,H)
        E=eigen(Symmetric(symmetric));expected=repair ? E.vectors*Diagonal(max.(E.values,1e-8))*E.vectors' : symmetric
        @test a.curvature_repaired==repair
        @test a.minimum_eigenvalue ≈ raw atol=1e-12
        @test a.inverse_root*a.inverse_root' ≈ inv(expected) rtol=1e-10
        @test a.logjac ≈ -logdet(Symmetric(expected))/2 atol=1e-10
    end
    a=GLLVM.aghq_adaptation(m,Matrix{Float64}(I,2,2));m[1]=99
    @test a.mode[1]==.1
    @test_throws ArgumentError GLLVM.aghq_adaptation([NaN],ones(1,1))
    @test_throws ArgumentError GLLVM.aghq_adaptation([0.],reshape([Inf],1,1))
    @test_throws DimensionMismatch GLLVM.aghq_adaptation([0.],ones(2,2))
    @test_throws ArgumentError GLLVM.aghq_adaptation(Float64[],zeros(0,0))
    @test_throws DimensionMismatch GLLVM.aghq_frozen_logintegral(z->-sum(abs2,z),a,GLLVM.aghq_grid(1,3))
end
