using GLLVM, Test, Random, Distributions, Statistics

@testset "fit_ordinal_gllvm" begin
    @testset "recovers ΛΛ' and ordered cutpoints" begin
        Random.seed!(220)
        p, K, n = 8, 2, 400
        C = 4
        τtrue = [-1.2, 0.0, 1.3]
        Λtrue = 0.7 .* randn(p, K)
        Z = randn(K, n)
        η = Λtrue * Z
        Y = Matrix{Int}(undef, p, n)
        for i in 1:n, t in 1:p
            pr = [GLLVM._ord_prob(c, η[t, i], τtrue) for c in 1:C]
            Y[t, i] = rand(Categorical(pr))
        end

        fit = fit_ordinal_gllvm(Y; K = K)
        @test fit isa OrdinalFit
        @test fit.C == C
        @test fit.converged
        @test issorted(fit.τ)                                      # ordering preserved
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λtrue * Λtrue')) > 0.8  # loadings up to rotation
        @test cor(fit.τ, τtrue) > 0.9                              # cutpoints recovered
    end

    @testset "fit_gllvm(family=Ordinal()) dispatches to OrdinalFit" begin
        Random.seed!(221)
        p, n, C = 5, 150, 3
        τ = [-0.5, 0.8]
        Λ = 0.6 .* randn(p, 1)
        η = Λ * randn(1, n)
        Y = Matrix{Int}(undef, p, n)
        for i in 1:n, t in 1:p
            pr = [GLLVM._ord_prob(c, η[t, i], τ) for c in 1:C]
            Y[t, i] = rand(Categorical(pr))
        end
        f = fit_gllvm(Y; family = Ordinal(), K = 1)
        @test f isa OrdinalFit
        @test f.C == C
        @test issorted(f.τ)
    end
end
