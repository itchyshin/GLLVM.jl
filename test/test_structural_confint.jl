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

    # ---- Covariate structural models: dedicated confint_* (need the design) ----
    q, r = 2, 2
    bracket_ok(ci) = all(i -> !(isfinite(ci.lower[i]) && isfinite(ci.upper[i])) ||
                              ci.lower[i] ≤ ci.estimate[i] ≤ ci.upper[i], eachindex(ci.term))

    @testset "species-covariate confint_speciescov" begin
        X = randn(p, n, q)
        fit = fit_gllvm_speciescov(Y; family = Poisson(), X = X, K = K, iterations = 60)
        ci = confint_speciescov(fit, Y, X)
        @test length(ci.term) == p + p * q + rr
        @test ci.method == :wald
        @test any(t -> startswith(t, "B["), ci.term)
        @test bracket_ok(ci)
    end

    @testset "fourth-corner confint_fourthcorner" begin
        Xenv = randn(n, q); TR = randn(p, r)
        fit = fit_fourthcorner_gllvm(Y; family = Poisson(), Xenv = Xenv, TR = TR, K = K, iterations = 60)
        ci = confint_fourthcorner(fit, Y, Xenv, TR)
        @test length(ci.term) == p + q * r + rr
        @test any(t -> startswith(t, "C["), ci.term)
        @test bracket_ok(ci)
    end

    @testset "RRR confint_rrr" begin
        X = randn(n, q)
        fit = fit_rrr_gllvm(Y; family = Poisson(), X = X, K = K, iterations = 60)
        ci = confint_rrr(fit, Y, X)
        @test length(ci.term) == p + rr + q * K
        @test any(t -> startswith(t, "B["), ci.term)
        @test bracket_ok(ci)
    end

    @testset "constrained confint_constrained" begin
        X = randn(n, q)
        fit = fit_constrained_gllvm(Y; family = Poisson(), X = X, K = K, iterations = 60)
        ci = confint_constrained(fit, Y, X)
        @test length(ci.term) == p + rr + q * K
        @test any(t -> startswith(t, "B["), ci.term)
        @test bracket_ok(ci)
    end
end
