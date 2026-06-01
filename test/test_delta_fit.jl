using GLLVM, Test, Random, Distributions, Statistics

@testset "fit_delta_lognormal_gllvm" begin
    Random.seed!(140)
    p, K, n = 8, 2, 400
    βz_true = 0.5 .* randn(p) .+ 0.4         # occurrence logits (≈ 60% presence)
    βc_true = 0.5 .* randn(p)                # positive meanlog
    Λc_true = 0.6 .* randn(p, K)
    σ_true = 0.5
    Z = randn(K, n)
    ηc = βc_true .+ Λc_true * Z
    π = inv.(1 .+ exp.(-βz_true))
    Y = zeros(p, n)
    for t in 1:p, s in 1:n
        if rand() < π[t]
            Y[t, s] = exp(ηc[t, s] + σ_true * randn())
        end
    end

    fit = fit_delta_lognormal_gllvm(Y; K = K)
    @test fit isa DeltaLogNormalFit
    @test fit.converged
    @test cor(fit.βz, βz_true) > 0.8                                  # occurrence
    @test cor(fit.βc, βc_true) > 0.8                                  # positive meanlog
    @test cor(vec(fit.Λc * fit.Λc'), vec(Λc_true * Λc_true')) > 0.7   # loadings (Gram)
    @test 0.5 * σ_true < fit.σ < 2 * σ_true                           # log-scale SD
end
