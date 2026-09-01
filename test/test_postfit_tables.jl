using GLLVM, Test, Random, LinearAlgebra, Statistics

# src/postfit_tables.jl — final missing-surface cluster (core070 spec §1),
# smallest-first per docs/dev-log/core070/final-surface-spec.md.

@testset "postfit_tables.jl — final missing-surface cluster" begin

    @testset "1.1 deviance — -2*loglikelihood, exact R contract" begin
        Random.seed!(1)
        p, K, n = 4, 2, 200
        Λ_true = 0.6 .* randn(p, K)
        y = Λ_true * randn(K, n) + 0.4 .* randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        @test deviance(fit) ≈ -2 * loglikelihood(fit)
        @test deviance(fit) ≈ -2 * fit.logLik
    end

end
