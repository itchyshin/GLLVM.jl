using GLLVM, Test, Random, Distributions

# Wald inference tables for the structural models that route through the unified
# confint(fit, Y) dispatch (no external design matrix needed): quadratic-response
# and community row-effects. Anchors: the table has the right term count/names and
# every finite-SE interval brackets its point estimate; coef_table builds.

@testset "Structural-model inference tables" begin
    Random.seed!(2025)
    p, K, n = 3, 1, 18
    Y = rand(0:4, p, n)
    rr = GLLVM.rr_theta_len(p, K)

    @testset "quadratic Wald CIs + coef_table" begin
        fit = fit_quadratic_gllvm(Y; family = Poisson(), K = K, iterations = 60)
        ci = confint(fit, Y; method = :wald)
        nterm = p + rr + p * K                      # β + Λ + D  (Poisson: no dispersion)
        @test length(ci.term) == nterm
        @test ci.method == :wald
        @test any(t -> startswith(t, "D["), ci.term)
        for i in eachindex(ci.term)
            if isfinite(ci.lower[i]) && isfinite(ci.upper[i])
                @test ci.lower[i] ≤ ci.estimate[i] ≤ ci.upper[i]
            end
        end
        @test coef_table(fit, Y) isa GllvmCoefTable
    end

    @testset "row-effects Wald CIs + coef_table" begin
        fit = fit_roweffect_gllvm(Y; family = Poisson(), K = K, iterations = 60)
        ci = confint(fit, Y; method = :wald)
        nterm = p + (n - 1) + rr                     # β + ρ_2..ρ_n + Λ
        @test length(ci.term) == nterm
        @test ci.method == :wald
        @test any(t -> startswith(t, "rho["), ci.term)
        for i in eachindex(ci.term)
            if isfinite(ci.lower[i]) && isfinite(ci.upper[i])
                @test ci.lower[i] ≤ ci.estimate[i] ≤ ci.upper[i]
            end
        end
        @test coef_table(fit, Y) isa GllvmCoefTable
    end
end
