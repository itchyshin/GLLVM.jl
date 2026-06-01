using GLLVM, Test, Random, Distributions, Statistics

@testset "@formula front-end (v1)" begin
    @testset "Gaussian: formula == hand-built X (exact parity)" begin
        Random.seed!(200)
        p, K, n = 6, 2, 90
        temp = randn(n); depth = randn(n)
        Λ = 0.5 .* randn(p, K); Z = randn(K, n)
        Y = Λ * Z .+ 0.3 .* randn(p, n) .+ 0.8 .* temp'
        data = (temp = temp, depth = depth)

        f1 = gllvm(@formula(y ~ 1 + temp + depth), Y, data; family = Normal(), K = K)
        X = zeros(p, n, 2)
        for s in 1:n, t in 1:p
            X[t, s, 1] = temp[s]; X[t, s, 2] = depth[s]
        end
        f2 = fit_gaussian_gllvm(Y; X = X, K = K)
        @test f1.logLik ≈ f2.logLik atol = 1e-8
    end

    @testset "intercept-only reduces to the plain fit" begin
        Random.seed!(201)
        p, K, n = 5, 1, 70
        Y = randn(p, n)
        data = (temp = randn(n),)
        f1 = gllvm(@formula(y ~ 1), Y, data; family = Normal(), K = K)
        f2 = fit_gaussian_gllvm(Y; K = K)
        @test f1.logLik ≈ f2.logLik atol = 1e-8
    end

    @testset "Poisson covariate via formula == fit_gllvm_cov" begin
        Random.seed!(202)
        p, K, n = 6, 1, 150
        temp = randn(n)
        β = 0.3 .* randn(p); γ = 0.7; Λ = 0.4 .* randn(p, K); Z = randn(K, n)
        η = β .+ γ .* temp' .+ Λ * Z
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]
        data = (temp = temp,)

        f1 = gllvm(@formula(y ~ 1 + temp), Y, data; family = Poisson(), K = K)
        @test f1 isa GllvmCovFit
        @test length(f1.γ) == 1
        X = zeros(p, n, 1); for s in 1:n, t in 1:p; X[t, s, 1] = temp[s]; end
        f2 = fit_gllvm_cov(Y; family = Poisson(), X = X, K = K)
        @test f1.loglik ≈ f2.loglik atol = 1e-6
    end

    @testset "unsupported terms error clearly" begin
        p, n = 4, 30
        Y = randn(p, n)
        data = (temp = randn(n), depth = randn(n), grp = string.(rand(1:2, n)))
        @test_throws ArgumentError gllvm(@formula(y ~ 1 + temp & depth), Y, data; family = Normal(), K = 1)
        @test_throws ArgumentError gllvm(@formula(y ~ 1 + grp), Y, data; family = Normal(), K = 1)    # categorical
        @test_throws ArgumentError gllvm(@formula(y ~ 1 + nope), Y, data; family = Normal(), K = 1)   # missing column
    end

    @testset "long-format front door == wide (exact round-trip)" begin
        Random.seed!(203)
        p, K, n = 5, 1, 40
        temp = randn(n)
        Λ = 0.5 .* randn(p, K); Z = randn(K, n)
        Y = Λ * Z .+ 0.3 .* randn(p, n) .+ 0.6 .* temp'
        site_data = (temp = temp,)
        fwide = gllvm(@formula(y ~ 1 + temp), Y, site_data; family = Normal(), K = K)

        # melt to long (species 1:p, site 1:n) so reconstruction matches wide order
        sp = Int[]; st = Int[]; yv = Float64[]; tv = Float64[]
        for s in 1:n, t in 1:p
            push!(sp, t); push!(st, s); push!(yv, Y[t, s]); push!(tv, temp[s])
        end
        long = (y = yv, species = sp, site = st, temp = tv)
        flong = gllvm(@formula(y ~ 1 + temp), long; family = Normal(), K = K,
                      species = :species, site = :site)
        @test flong.logLik ≈ fwide.logLik atol = 1e-8
    end

    @testset "long-format validation errors" begin
        # incomplete species×site grid (missing the (2,2) cell)
        long_bad = (y = [1.0, 2.0, 3.0], species = [1, 2, 1], site = [1, 1, 2])
        @test_throws ArgumentError gllvm(@formula(y ~ 1), long_bad; family = Normal(), K = 1)
        # site covariate not constant within site
        long_nc = (y = randn(4), species = [1, 2, 1, 2], site = [1, 1, 2, 2],
                   temp = [0.5, 0.9, 0.1, 0.2])
        @test_throws ArgumentError gllvm(@formula(y ~ 1 + temp), long_nc; family = Normal(), K = 1)
    end
end
