using Test, GLLVM, LinearAlgebra, ForwardDiff
using Distributions: Normal, logpdf
@testset "Gaussian additive source covariance" begin
    available = isdefined(GLLVM, :_gaussian_source_loglik)
    @test available
    if available
        f = GLLVM._gaussian_source_loglik
        Y = [0.2 -0.4 0.8; 1.1 0.3 -0.2]
        beta = [0.1, -0.2]; lambda = [0.4; -0.3;;]
        C = [1.0 0.25; 0.25 1.4]; groups = reshape([1, 1, 2], 3, 1)
        sigma = 0.7
        value = f(Y, beta, lambda, [C], groups, sigma)
        residual = vec(Y .- beta)
        V = kron(C[vec(groups),vec(groups)], lambda*lambda') + sigma^2*I(6)
        reference = -(6log(2pi)+logdet(V)+dot(residual,V\residual))/2
        @test value ≈ reference atol=1e-12
        @test isfinite(value) # repeated groups: source alone is rank deficient
        @test f(Y,beta,zero(lambda),[C],groups,sigma) ≈ sum(logpdf(Normal(0,sigma),x) for x in residual) atol=1e-12
        order = [3,1,2]
        @test f(Y[:,order],beta,lambda,[C],groups[order,:],sigma) ≈ value atol=1e-12
        @test f(Y,beta,lambda,[C[[2,1],[2,1]]],3 .-groups,sigma) ≈ value atol=1e-12
        L = hcat(lambda,[0.1,0.6]); Cs = [C,[1.0 0.1;0.1 0.8]]; gs = hcat(vec(groups),[2,1,2])
        v2 = f(Y,beta,L,Cs,gs,sigma)
        @test f(Y,beta,L[:,[2,1]],Cs[[2,1]],gs[:,[2,1]],sigma) ≈ v2 atol=1e-12
        # Different source group counts and incidence, reviewed coverage gap.
        C3 = [1.0 0.1 0.2; 0.1 1.2 0.0; 0.2 0.0 0.9]
        unequal_groups = hcat(vec(groups),[3,1,2])
        Z1 = [1.0 0.0; 1.0 0.0; 0.0 1.0]
        Z2 = [0.0 0.0 1.0; 1.0 0.0 0.0; 0.0 1.0 0.0]
        Vdifferent = sigma^2*I(6) + kron(Z1*C*Z1',L[:,1]*L[:,1]') + kron(Z2*C3*Z2',L[:,2]*L[:,2]')
        different_reference = -(6log(2pi)+logdet(Vdifferent)+dot(residual,Vdifferent\residual))/2
        @test f(Y,beta,L,[C,C3],unequal_groups,sigma) ≈ different_reference atol=1e-12
        theta = vcat(beta,vec(L),log(sigma))
        objective(t) = f(Y,t[1:2],reshape(t[3:6],2,2),Cs,gs,exp(t[7]))
        grad = ForwardDiff.gradient(objective,theta)
        fd = [(objective(theta+1e-5*I(7)[:,j])-objective(theta-1e-5*I(7)[:,j]))/2e-5 for j in 1:7]
        @test maximum(abs.(grad-fd)) < 1e-6
        @test_throws DimensionMismatch f(Y,beta[1:1],lambda,[C],groups,sigma)
        @test_throws DimensionMismatch f(Y,beta,lambda,[C],groups[1:2,:],sigma)
        @test_throws DimensionMismatch f(Y,beta,lambda,[C,C],groups,sigma)
        @test_throws ArgumentError f(Y,beta,lambda,[C],zeros(Int,3,1),sigma)
        @test_throws ArgumentError f(Y,beta,lambda,[C],fill(3,3,1),sigma)
        @test_throws ArgumentError f(Y,beta,lambda,[[1.0 0.5;0.2 1.0]],groups,sigma)
        @test_throws PosDefException f(Y,beta,lambda,[[1.0 2.0;2.0 1.0]],groups,sigma)
        for bad in (0.0,-1.0,Inf,NaN)
            @test_throws ArgumentError f(Y,beta,lambda,[C],groups,bad)
        end
        @test_throws ArgumentError f(fill(NaN,2,3),beta,lambda,[C],groups,sigma)
        @test_throws ArgumentError f(Y,[Inf,0.0],lambda,[C],groups,sigma)
        @test_throws ArgumentError f(Y,beta,fill(NaN,2,1),[C],groups,sigma)
        @test_throws ArgumentError f(Y,beta,lambda,[fill(NaN,2,2)],groups,sigma)
        @test_throws ArgumentError f(Y,beta,zeros(2,3),[C,C,C],ones(Int,3,3),sigma)
    end
end
