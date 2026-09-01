using GLLVM, Test, Random, LinearAlgebra, Statistics

# Diagnostics/compare cluster (src/diagnostics.jl) — TDD red-first fixtures.
# Each block cites the R source it ports (see the function docstrings for
# exact file/line references into
# .unlazy/core070-aghq/oracle-source/readback/R/).

@testset "diagnostics" begin

    @testset "sanity_multi — healthy Gaussian fit passes" begin
        Random.seed!(10)
        p, K, n = 5, 1, 400
        Λ_true = reshape([0.7, 0.5, 0.4, -0.3, 0.2], p, K)
        y = Λ_true * randn(K, n) + 0.5 * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        s = GLLVM.sanity_multi(fit; y = y)
        @test s.pass
        @test s.loadings_finite
        @test s.pd_hessian === true
        @test s.gradient_ok
        @test s.gradient_norm < 1e-3
    end

    @testset "sanity_multi — non-finite loadings fail" begin
        Random.seed!(11)
        p, K, n = 4, 1, 100
        Λ_true = reshape([0.7, 0.5, 0.4, -0.3], p, K)
        y = Λ_true * randn(K, n) + 0.5 * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        badpars = merge(fit.pars, (Λ = fill(NaN, size(fit.pars.Λ)),))
        badfit = GLLVM.GllvmFit(fit.model, badpars, fit.logLik, fit.n_iter, fit.converged,
                                 fit.optim_result, fit.cputime)
        s = GLLVM.sanity_multi(badfit)
        @test !s.pass
        @test !s.loadings_finite
    end

    @testset "check_auto_residual — coherent for logit ordinal, flags probit" begin
        Random.seed!(12)
        p, K, n = 4, 1, 300
        Λ_true = reshape([1.0, 0.8, -0.6, 0.5], p, K)
        η = Λ_true * randn(K, n)
        τ = [-1.0, 0.0, 1.0]
        Y = Matrix{Int}(undef, p, n)
        for t in 1:p, s in 1:n
            Y[t, s] = 1 + sum(η[t, s] .> τ)
        end
        fit_logit = fit_ordinal_gllvm(Y; K = K, link = GLLVM.LogitLink())
        r_logit = GLLVM.check_auto_residual(fit_logit)
        @test r_logit.coherent
        @test !r_logit.ordinal_probit

        fit_probit = fit_ordinal_gllvm(Y; K = K, link = GLLVM.ProbitLink())
        r_probit = GLLVM.check_auto_residual(fit_probit)
        @test !r_probit.coherent
        @test r_probit.ordinal_probit
        @test !isempty(r_probit.messages)
    end

    @testset "gllvmTMB_diagnose / check_gllvmTMB — boundary flags on a degenerate fit" begin
        Random.seed!(13)
        p, K, n = 5, 1, 400
        Λ_true = reshape([0.7, 0.5, 0.4, -0.3, 0.2], p, K)
        y = Λ_true * randn(K, n) + 0.5 * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        d = GLLVM.gllvmTMB_diagnose(fit; y = y)
        @test d.pass
        @test isempty(d.boundary_flags)

        # Force a near-zero σ_eps to trigger the variance boundary flag.
        tiny_pars = merge(fit.pars, (σ_eps = 1e-8,))
        tiny_fit = GLLVM.GllvmFit(fit.model, tiny_pars, fit.logLik, fit.n_iter, fit.converged,
                                   fit.optim_result, fit.cputime)
        d2 = GLLVM.gllvmTMB_diagnose(tiny_fit)
        @test !d2.pass
        @test any(f -> startswith(f, "variance_near_zero"), d2.boundary_flags)

        c = GLLVM.check_gllvmTMB(fit; y = y)
        @test c.pass
        @test c.residual.coherent
    end

    @testset "diagnostic_table — one row per named check, matching column lengths" begin
        Random.seed!(14)
        p, K, n = 4, 1, 200
        Λ_true = reshape([0.7, 0.5, 0.4, -0.3], p, K)
        y = Λ_true * randn(K, n) + 0.5 * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        tbl = GLLVM.diagnostic_table(fit; y = y)
        @test length(tbl.check) == length(tbl.status) == length(tbl.message)
        @test "converged" in tbl.check
        @test "pd_hessian" in tbl.check
        @test "auto_residual" in tbl.check
        @test all(s -> s in (:pass, :fail, :unavailable), tbl.status)
    end

    @testset "diagnose_kernel_separability — single-tier fit reports missing" begin
        Random.seed!(15)
        p, K, n = 4, 1, 150
        Λ_true = reshape([0.7, 0.5, 0.4, -0.3], p, K)
        y = Λ_true * randn(K, n) + 0.5 * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        r = GLLVM.diagnose_kernel_separability(fit)
        @test r.separable === missing
    end

    @testset "compare_Sigma_table / compare_loadings — identical fits agree exactly" begin
        Random.seed!(16)
        p, K, n = 5, 2, 300
        Λ_true = randn(p, K)
        y = Λ_true * randn(K, n) + 0.4 * randn(p, n)
        fit1 = fit_gaussian_gllvm(y; K = K)
        fit2 = fit1

        sc = GLLVM.compare_Sigma_table(fit1, fit2)
        @test sc.frobenius_norm ≈ 0.0 atol = 1e-10
        @test sc.max_abs_diff ≈ 0.0 atol = 1e-10

        cl = GLLVM.compare_loadings(fit1, fit2)
        @test cl.frobenius_norm_LLt ≈ 0.0 atol = 1e-10
        @test all(a -> isapprox(a, 0.0; atol = 1e-6), cl.principal_angles)
    end

    @testset "compare_Sigma_table / compare_loadings — a genuinely different fit disagrees" begin
        Random.seed!(17)
        p, K, n = 5, 1, 300
        Λ_true = reshape([0.7, 0.5, 0.4, -0.3, 0.2], p, K)
        y1 = Λ_true * randn(K, n) + 0.3 * randn(p, n)
        y2 = 3.0 .* Λ_true * randn(K, n) .+ 2.0 * randn(p, n)
        fit1 = fit_gaussian_gllvm(y1; K = K)
        fit2 = fit_gaussian_gllvm(y2; K = K)

        sc = GLLVM.compare_Sigma_table(fit1, fit2)
        @test sc.frobenius_norm > 1.0

        cl = GLLVM.compare_loadings(fit1, fit2)
        @test cl.frobenius_norm_LLt > 0.1

        @test_throws ArgumentError GLLVM.compare_Sigma_table(fit1, fit_gaussian_gllvm(y1[1:3, :]; K = K))
    end

    @testset "compare_dep_vs_two_psi / compare_indep_vs_two_psi — bridge shape and self-comparison" begin
        Random.seed!(18)
        p, K, n = 4, 1, 250
        Λ_true = reshape([0.7, 0.5, 0.4, -0.3], p, K)
        y = Λ_true * randn(K, n) + 0.4 * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        r = GLLVM.compare_dep_vs_two_psi(fit, fit, n)
        @test r.aic_delta ≈ 0.0 atol = 1e-8
        @test r.bic_delta ≈ 0.0 atol = 1e-8
        @test r.loglik_dep ≈ r.loglik_alt

        r2 = GLLVM.compare_indep_vs_two_psi(fit, fit, n)
        @test r2.aic_delta ≈ 0.0 atol = 1e-8
    end

    @testset "predictive_check — a well-fitting Poisson model does not flag" begin
        Random.seed!(19)
        rng = MersenneTwister(19)
        p, K, n = 4, 1, 300
        Λ_true = reshape([0.6, 0.5, -0.4, 0.3], p, K)
        β_true = fill(0.5, p)
        Z = randn(rng, K, n)
        η = β_true .+ Λ_true * Z
        Y = [rand(rng, GLLVM.Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]
        fit = fit_poisson_gllvm(Y; K = K, iterations = 100)

        pc = GLLVM.predictive_check(fit, Y; nsim = 100, rng = MersenneTwister(1))
        @test length(pc.stat) == length(pc.trait) == length(pc.observed) == length(pc.p_value)
        @test all(0.0 .<= pc.p_value .<= 1.0)
        # A correctly specified model should rarely flag every trait/stat at once.
        @test !all(pc.p_value .< 0.01)
    end

    @testset "predictive_check — a well-fitting Gaussian model does not flag" begin
        Random.seed!(20)
        p, K, n = 4, 1, 300
        Λ_true = reshape([0.7, 0.5, 0.4, -0.3], p, K)
        y = Λ_true * randn(K, n) + 0.5 * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        pc = GLLVM.predictive_check(fit, y; nsim = 100, rng = MersenneTwister(2))
        @test length(pc.stat) == length(pc.trait) == length(pc.observed) == length(pc.p_value)
        @test all(0.0 .<= pc.p_value .<= 1.0)
        @test !all(pc.p_value .< 0.01)
    end

    @testset "predictive_check — a fit type with no simulate() method documents the gap" begin
        Random.seed!(24)
        p, K, n = 4, 1, 200
        Λ_true = reshape([1.0, 0.8, -0.6, 0.5], p, K)
        η = Λ_true * randn(K, n)
        τ = [-1.0, 0.0, 1.0]
        Y = Matrix{Int}(undef, p, n)
        for t in 1:p, s in 1:n
            Y[t, s] = 1 + sum(η[t, s] .> τ)
        end
        fit = fit_ordinal_gllvm_pertrait(Y; K = K)
        @test_throws ArgumentError GLLVM.predictive_check(fit, Y)
    end

    @testset "confint_inspect — Wald and profile roughly agree on a clean fixture" begin
        Random.seed!(21)
        p, K, n = 3, 1, 400
        Λ_true = reshape([0.7, 0.5, 0.4], p, K)
        σ_true = 0.5
        y = Λ_true * randn(K, n) + σ_true * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        ci = GLLVM.confint_inspect(fit, y; parm = "sigma_eps")
        @test ci.term == ["sigma_eps"]
        @test ci.wald_lower[1] < σ_true < ci.wald_upper[1]
        @test isfinite(ci.profile_lower[1])
        @test !ci.disagree[1]
    end

    @testset "gllvmTMB_check_consistency — correctly specified fit does not flag score non-centring" begin
        Random.seed!(22)
        p, K, n = 4, 1, 300
        Λ_true = reshape([0.7, 0.5, 0.4, -0.3], p, K)
        σ_true = 0.5
        y = Λ_true * randn(K, n) + σ_true * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        cc = GLLVM.gllvmTMB_check_consistency(fit, y; n_sim = 60, seed = 42)
        @test cc.n_sim == 60
        @test length(cc.marginal_bias) == length(fit.pars.θ_packed)
        # Omnibus Hotelling test should not report the score significantly
        # off-centre for a correctly specified model (per-parameter flags can
        # still fire occasionally from multiple-comparison noise, matching R's
        # own per-parameter bias flag, which the omnibus p-value guards against).
        @test !isnan(cc.marginal_p_value)
        @test cc.marginal_p_value > 0.01
    end

    @testset "gllvmTMB_check_consistency — rejects unsupported structure" begin
        Random.seed!(23)
        p, K, n = 4, 1, 100
        y = 0.5 * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K, K_W = 1, has_diag = true)
        @test_throws ArgumentError GLLVM.gllvmTMB_check_consistency(fit, y)
    end
end
