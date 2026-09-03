using GLLVM, Test, Random, LinearAlgebra

@testset "Per-species Gaussian requested fixed design" begin
    rng = MersenneTwister(7091)
    p, n, K, q = 4, 80, 1, 6
    X = zeros(p,n,q)
    for t in 1:p; X[t,:,t] .= 1; end
    X[:,:,5:6] .= randn(rng,p,n,2)
    A = reshape(X,p*n,q)
    β = [0.2,-0.4,0.1,0.6,1.5,-0.9]
    residual = [0.7,-0.4,0.5,0.3] * randn(rng,1,n) +
               [0.5,0.7,0.9,0.6] .* randn(rng,p,n)
    Y = reshape(A*β,p,n) + residual
    fit = fit_gaussian_pervar_gllvm(Y;K,X,method=:lbfgs)
    @test length(fit.β) == q
    @test fit.converged
    @test GLLVM._nparams(fit) == q + GLLVM.rr_theta_len(p,K) + p
    if length(fit.β) == q
        V = fit.Λ*fit.Λ' + Diagonal(fit.φ²)
        C = cholesky(Symmetric(kron(Matrix{Float64}(I,n,n),V)))
        expected_β = (A'*(C\A)) \ (A'*(C\vec(Y)))
        @test fit.β ≈ expected_β atol=1e-9 rtol=1e-9
        ε = vec(Y)-A*fit.β
        dense_ll = -(length(Y)*log(2π)+logdet(C)+dot(ε,C\ε))/2
        @test fit.loglik ≈ dense_ll atol=1e-8 rtol=0
        @test maximum(abs,A'*(C\ε)) <= 1e-8
        δ = [1.0,-0.8,0.3,0.7,-0.5,1.2]
        shifted = fit_gaussian_pervar_gllvm(Y+reshape(A*δ,p,n);K,X,method=:lbfgs)
        @test shifted.converged
        @test shifted.β ≈ fit.β+δ atol=1e-6 rtol=0
        @test shifted.Λ*shifted.Λ'+Diagonal(shifted.φ²) ≈ V atol=1e-6 rtol=0
        @test shifted.loglik ≈ fit.loglik atol=1e-7 rtol=0
    end
end

@testset "Per-species Gaussian design boundaries" begin
    rng = MersenneTwister(7092)
    p,n,K = 4,70,1
    Y = randn(rng,p,n)
    @test_throws DimensionMismatch fit_gaussian_pervar_gllvm(Y;K,X=zeros(p-1,n,1))
    @test_throws DimensionMismatch fit_gaussian_pervar_gllvm(Y;K,X=zeros(p,n-1,1))
    @test_throws ArgumentError fit_gaussian_pervar_gllvm(Y;K,X=ones(p,n,2))
    @test_throws ArgumentError fit_gaussian_pervar_gllvm(Y;K,X=fill(NaN,p,n,1))
    bad = copy(Y); bad[1,1] = Inf
    @test_throws ArgumentError fit_gaussian_pervar_gllvm(bad;K)
    @test_throws ArgumentError fit_gaussian_pervar_gllvm(Y;K,method=:unknown)
    no_mean = fit_gaussian_pervar_gllvm(Y;K,X=zeros(p,n,0))
    @test isempty(no_mean.β)
    @test no_mean.converged
    @test GLLVM._nparams(no_mean) == GLLVM.rr_theta_len(p,K)+p
    @test no_mean.loglik ≈ gaussian_pervar_marginal_loglik(Y,no_mean.Λ,no_mean.φ²) atol=1e-8 rtol=0
    intercepts = zeros(p,n,p)
    for j in 1:p; intercepts[j,:,j] .= 1; end
    explicit = fit_gaussian_pervar_gllvm(Y;K,X=intercepts)
    implicit = fit_gaussian_pervar_gllvm(Y;K,method=:lbfgs)
    @test explicit.β ≈ implicit.β atol=1e-10 rtol=0
    @test explicit.loglik ≈ implicit.loglik atol=1e-7 rtol=0
    @test coef(explicit) == explicit.β
    copyβ = coef(explicit); copyβ[1] += 1
    @test copyβ != explicit.β
end

@testset "Per-species Gaussian small-diagonal stability" begin
    Λ = reshape([1.0,0.3,-0.4],3,1)
    d = [1e-30,0.7,1.1]
    Y = [0.3 -0.8 1.2; 0.2 0.5 -0.4; -0.1 0.9 0.2]
    C = cholesky(Symmetric(Λ*Λ'+Diagonal(d)))
    expected = -(length(Y)*log(2π)+size(Y,2)*logdet(C)+sum(Y.*(C\Y)))/2
    @test gaussian_pervar_marginal_loglik(Y,Λ,d) ≈ expected atol=1e-12 rtol=0
    @test isfinite(gaussian_pervar_marginal_loglik(Y,Λ,d))
    @test_throws ArgumentError gaussian_pervar_marginal_loglik(Y,Λ,[-1.0,0.7,1.1])
end
