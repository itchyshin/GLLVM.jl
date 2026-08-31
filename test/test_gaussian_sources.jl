using Test, GLLVM, LinearAlgebra, ForwardDiff, Statistics
@testset "Gaussian source model layer" begin
    available=all(s->isdefined(GLLVM,s),(:SourceCovariance,:fit_gaussian_sources,:GaussianSourcesFit))
    @test available
    if available
        C=[1.0 .2;.2 1.4]; D=[1.0 .1 .2;.1 1.2 .0;.2 .0 .9]
        s1=SourceCovariance(C;groups=[1,1,2],name=:a,rank=1)
        s2=SourceCovariance(D;groups=[3,1,2],name=:b,mode=:indep)
        Y=[.2 -.4 .8;1.1 .3 -.2]; beta=[.1,-.2]
        theta=[beta;.4;-.3;log(.2);log(.6);log(.7)]
        objective(t)=GLLVM._gaussian_sources_nll(Y,[s1,s2],t)
        L=[.4;-.3;;]; B1=L*L';B2=Diagonal([.2^2,.6^2])
        V=.7^2*Matrix(I,6,6)
        # Independent observation-loop reference, not production Kronecker assembly.
        for j in 1:3,i in 1:3,b in 1:2,a in 1:2
            V[a+2*(i-1),b+2*(j-1)]+=C[[1,1,2][i],[1,1,2][j]]*B1[a,b]+D[[3,1,2][i],[3,1,2][j]]*B2[a,b]
        end
        r=vec(Y.-beta); expected=(6log(2pi)+logdet(V)+dot(r,V\r))/2
        @test objective(theta)≈expected atol=1e-12
        grad=ForwardDiff.gradient(objective,theta)
        fd=[(objective(theta+1e-5*I(7)[:,j])-objective(theta-1e-5*I(7)[:,j]))/2e-5 for j in 1:7]
        @test maximum(abs.(grad-fd))<1e-6
        @test GLLVM._gaussian_sources_nll(Y,[s2,s1],theta[[1,2,5,6,3,4,7]])≈expected atol=1e-12
        order=[3,1,2]
        perm=[SourceCovariance(C;groups=[2,1,1],name=:a),SourceCovariance(D;groups=[2,3,1],name=:b,mode=:indep)]
        @test GLLVM._gaussian_sources_nll(Y[:,order],perm,theta)≈expected atol=1e-12
        common=SourceCovariance(C;groups=[1,1,2],mode=:indep,common=true)
        B=only(GLLVM._source_trait_covariances([common],2,[log(.3)]))
        @test B≈.09*Matrix(I,2,2) atol=1e-14
        @test B[1,2]==0 # equal independent fields, not a common field
        dep=SourceCovariance(C;groups=[1,1,2],mode=:dep)
        @test only(GLLVM._source_trait_covariances([dep],2,[.4,.6,.1]))≈[.16 .04;.04 .37] atol=1e-14
        unique=SourceCovariance(C;groups=[1,1,2],rank=1,unique=true,common=true)
        @test only(GLLVM._source_trait_covariances([unique],2,[.4,-.3,log(.2)]))≈B1+.04I atol=1e-14
        # Analytic ML control: Gaussian independent noise, no latent-source fitting.
        fit=fit_gaussian_sources(Y;sources=SourceCovariance[],g_tol=1e-7)
        means=vec(mean(Y,dims=2));sigma=sqrt(sum(abs2,Y.-means)/length(Y))
        @test fit.beta≈means atol=1e-6
        @test fit.sigma_eps≈sigma atol=1e-6
        @test fit.converged && fit.gradient_norm<=1e-7
        @test loglikelihood(fit)≈sum(-log(sigma*sqrt(2pi)).-(Y.-means).^2/(2sigma^2)) atol=1e-8
        @test coef(fit)==fit.beta && nobs(fit)==6
        # A nonempty-source fit with independently derived interior ML estimates.
        # Four balanced groups, three replicates; orthogonal within/between spaces.
        ids=repeat(1:4;inner=3)
        groupmeans=[-1.5,-.5,.5,1.5]
        within=[-.2,0.,.2]
        response=reshape([.7+groupmeans[g]+within[j] for g in 1:4 for j in 1:3],1,:)
        block=SourceCovariance(Matrix{Float64}(I,4,4);groups=ids,name=:group,mode=:indep)
        interior=fit_gaussian_sources(response;sources=[block],g_tol=1e-7)
        residual_variance=sum(abs2,within)/2
        source_variance=sum(abs2,groupmeans)/4-residual_variance/3
        @test interior.converged && interior.gradient_norm<=1e-7
        @test interior.beta[1]≈.7 atol=1e-6
        @test interior.sigma_eps^2≈residual_variance atol=1e-6
        @test only(interior.trait_covariances)[1,1]≈source_variance atol=1e-6
        # Each within-group contrast has eigenvalue residual_variance (8 df),
        # each group-constant direction has eigenvalue residual+3*source (4 df).
        between_eigenvalue=residual_variance+3source_variance
        independent_ll=-.5*(12log(2pi)+8log(residual_variance)+
            4log(between_eigenvalue)+4sum(abs2,within)/residual_variance+
            3sum(abs2,groupmeans)/between_eigenvalue)
        @test loglikelihood(interior)≈independent_ll atol=1e-8
        @test interior.hessian_positive_definite
        @test interior.stopping_reason===:converged
        # The retained source snapshot must not alias mutable caller arrays.
        saved_covariance=copy(interior.sources[1].covariance)
        block.covariance[1,1]=2
        @test interior.sources[1].covariance==saved_covariance
        stopped=fit_gaussian_sources(Y;sources=[s1,s2],iterations=0)
        @test !stopped.converged
        @test stopped.stopping_reason===:iteration_limit
        @test isfinite(stopped.loglik) && isfinite(stopped.gradient_norm)
        @test length(stopped.trait_covariances)==2
        @test_throws ArgumentError SourceCovariance([1.0 2;2 1];groups=[1,2])
        @test_throws ArgumentError SourceCovariance([1.0 .3;.2 1];groups=[1,2])
        @test_throws ArgumentError SourceCovariance(C;groups=[0,1])
        @test_throws ArgumentError SourceCovariance(C;groups=[1,3])
        @test_throws ArgumentError SourceCovariance(C;groups=[1,2],mode=:nonsense)
        @test_throws ArgumentError SourceCovariance(C;groups=[1,2],mode=:indep,rank=1)
        @test_throws ArgumentError SourceCovariance(C;groups=[1,2],common=true)
        @test_throws ArgumentError SourceCovariance(C;groups=[1,2],mode=:dep,unique=true)
        @test_throws DimensionMismatch SourceCovariance(C,ones(3,3))
        @test_throws ArgumentError SourceCovariance(C,fill(NaN,3,2))
        @test_throws ArgumentError fit_gaussian_sources(Y;sources=[s1,s1])
        @test_throws DimensionMismatch fit_gaussian_sources(Y;sources=[SourceCovariance(C;groups=[1,2])])
        @test_throws ArgumentError fit_gaussian_sources(Y;sources=[SourceCovariance(C;groups=[1,1,2],rank=3)])
        @test_throws ArgumentError fit_gaussian_sources(fill(NaN,2,3);sources=[s1])
        @test_throws ArgumentError fit_gaussian_sources(Y;sources=[],g_tol=0)
        @test_throws ArgumentError fit_gaussian_sources(Y;sources=[],iterations=-1)
        @test_throws DimensionMismatch fit_gaussian_sources(Y;sources=[s1],start=[0.])
        @test_throws ArgumentError fit_gaussian_sources(ones(2,1);sources=[])
        @test_throws ArgumentError fit_gaussian_sources(ones(2,3);sources=[])
        @test_throws ArgumentError fit_gaussian_sources(Y;sources=[],start=[.1,.2,1000.])
    end
end
