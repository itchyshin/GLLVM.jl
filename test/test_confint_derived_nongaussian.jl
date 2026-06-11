using GLLVM, Test, Random, LinearAlgebra, Statistics
using Distributions: Normal, Poisson, Binomial, NegativeBinomial, Beta, Gamma

# Derived-quantity CIs (bootstrap + Fisher-z/logit transformed-Wald) for the
# NON-GAUSSIAN one-part fits and the MixedFamilyFit.
#
# Load-on-demand guards mirror the sister confint tests (test_confint_derived.jl,
# test_confint_derived_wald.jl). `using GLLVM` loads the compiled module, which
# already includes the bootstrap-families file (it is in src/GLLVM.jl). The
# transformed-Wald additions live in the on-demand confint_derived_wald.jl, so we
# inject it INTO the GLLVM module (its non-Gaussian methods resolve their compiled
# deps: binomial/ordinal marginal value fns, _binomial_link_residual,
# _unpack_cutpoints, rr_theta_len, ForwardDiff).
if !isdefined(GLLVM, :bootstrap_ci_derived)
    Base.include(GLLVM, joinpath(@__DIR__, "..", "src",
                                 "confint_derived_bootstrap_families.jl"))
end
if !isdefined(GLLVM, :correlation_wald_ci)
    Base.include(GLLVM, joinpath(@__DIR__, "..", "src", "confint_derived_wald.jl"))
end

# Helper: a CI brackets its own point estimate (with a tiny numeric slack).
_brackets(ci) = isfinite(ci.lower) && isfinite(ci.upper) &&
                ci.lower - 1e-9 ≤ ci.estimate ≤ ci.upper + 1e-9

@testset "derived-quantity CIs — non-Gaussian + mixed" begin

    # =======================================================================
    # 1. Parametric bootstrap brackets the point estimate, per family.
    # =======================================================================

    @testset "Poisson bootstrap (correlation + communality)" begin
        Random.seed!(101)
        p, K, n = 4, 1, 120
        Λ = reshape([0.9, 0.7, -0.5, 0.4], p, K)
        β = [1.2, 0.8, 1.0, 0.6]
        Y = round.(Int, simulate(Poisson(), β, Λ, n; seed = 7))
        fit = fit_poisson_gllvm(Y; K = K)

        ci = GLLVM.correlation_boot_ci(fit, 1, 2; Y = Y, n_boot = 60, seed = 1)
        @test ci.n_valid ≥ 50
        @test _brackets(ci)
        @test -1 ≤ ci.lower && ci.upper ≤ 1
        @test isapprox(ci.estimate, GLLVM.correlation(fit, Y)[1, 2]; rtol = 1e-10)

        cc = GLLVM.communality_boot_ci(fit, 1; Y = Y, n_boot = 60, seed = 1)
        @test cc.n_valid ≥ 50
        @test _brackets(cc)
        @test 0 ≤ cc.lower && cc.upper ≤ 1
        @test isapprox(cc.estimate, GLLVM.communality(fit, Y)[1]; rtol = 1e-10)
    end

    @testset "Negative Binomial bootstrap (correlation)" begin
        Random.seed!(404)
        p, K, n = 3, 1, 150
        Λ = reshape([0.8, 0.6, -0.5], p, K)
        β = [1.5, 1.2, 1.0]
        Y = round.(Int, simulate(NegativeBinomial(5.0, 0.5), β, Λ, n;
                                 dispersion = 5.0, seed = 1))
        fit = fit_nb_gllvm(Y; K = K)
        ci = GLLVM.correlation_boot_ci(fit, 1, 2; Y = Y, n_boot = 40, seed = 1)
        @test ci.n_valid ≥ 30
        @test _brackets(ci)
    end

    @testset "Beta bootstrap (correlation)" begin
        Random.seed!(505)
        p, K, n = 3, 1, 150
        Λ = reshape([0.8, 0.6, -0.5], p, K)
        Y = simulate(Beta(10.0, 1.0), [0.3, -0.2, 0.1], Λ, n;
                     dispersion = 10.0, seed = 2)
        fit = fit_beta_gllvm(Y; K = K)
        ci = GLLVM.correlation_boot_ci(fit, 1, 2; Y = Y, n_boot = 40, seed = 1)
        @test ci.n_valid ≥ 30
        @test _brackets(ci)
    end

    @testset "Gamma bootstrap (correlation)" begin
        # NOTE: the Gamma inner-mode is the least robust one-part family (see
        # CLAUDE.md / confint_families.jl). We assert a VALID bracketing interval,
        # not a tight width.
        Random.seed!(606)
        p, K, n = 3, 1, 150
        Λ = reshape([0.8, 0.6, -0.5], p, K)
        Y = simulate(Gamma(3.0, 1.0), [0.5, 0.3, 0.4], Λ, n;
                     dispersion = 3.0, seed = 3)
        fit = fit_gamma_gllvm(Y; K = K)
        ci = GLLVM.correlation_boot_ci(fit, 1, 2; Y = Y, n_boot = 40, seed = 1)
        @test ci.n_valid ≥ 30
        @test _brackets(ci)
    end

    @testset "Binomial bootstrap (correlation)" begin
        Random.seed!(303)
        p, K, n = 4, 1, 300
        Λ = reshape([1.0, 0.8, -0.6, 0.5], p, K)
        β = [0.2, -0.3, 0.1, 0.0]
        Y = round.(Int, simulate(Binomial(), β, Λ, n; seed = 9))
        fit = fit_binomial_gllvm(Y; K = K)
        ci = GLLVM.correlation_boot_ci(fit, 1, 2; Y = Y, n_boot = 50, seed = 2)
        @test ci.n_valid ≥ 40
        @test _brackets(ci)
    end

    @testset "Ordinal bootstrap (correlation)" begin
        Random.seed!(707)
        p, K, n = 4, 1, 300
        Λ = reshape([1.2, 1.0, -0.8, 0.6], p, K)
        Y = round.(Int, simulate(Ordinal(), [-1.0, 0.5], Λ, n; seed = 4))
        fit = fit_ordinal_gllvm(Y; K = K)
        ci = GLLVM.correlation_boot_ci(fit, 1, 2; Y = Y, n_boot = 40, seed = 1)
        @test ci.n_valid ≥ 30
        @test _brackets(ci)
    end

    # =======================================================================
    # 2. Mixed-family [Normal, Poisson, Binomial]: a CROSS-FAMILY correlation
    #    CI is produced and brackets the point estimate.
    # =======================================================================

    @testset "mixed [Normal,Poisson,Binomial] cross-family correlation" begin
        Random.seed!(808)
        p, K, n = 3, 1, 200
        fams = [Normal(), Poisson(), Binomial()]
        links = [GLLVM.IdentityLink(), GLLVM.LogLink(), GLLVM.LogitLink()]
        Λ = reshape([0.8, 0.7, 0.9], p, K)
        β = [0.5, 1.0, 0.2]
        Y = simulate(fams, links, β, Λ, n; dispersion = [0.5, NaN, NaN], seed = 11)
        fit = fit_mixed_gllvm(Y; families = fams, K = K)
        @test fit.converged

        # ρ[2,3] is the Poisson–Binomial cross-family correlation.
        R = GLLVM.correlation(fit, Y)
        ci = GLLVM.correlation_boot_ci(fit, 2, 3; Y = Y, n_boot = 50, seed = 3)
        @test ci.n_valid ≥ 40
        @test _brackets(ci)
        @test -1 ≤ ci.lower && ci.upper ≤ 1
        @test isapprox(ci.estimate, R[2, 3]; rtol = 1e-10)

        # communality of the Poisson trait also brackets.
        cc = GLLVM.communality_boot_ci(fit, 2; Y = Y, n_boot = 50, seed = 3)
        @test cc.n_valid ≥ 40
        @test _brackets(cc)
    end

    # =======================================================================
    # 3. Gaussian reduction: an all-Normal MixedFamilyFit through the new
    #    bootstrap path matches the native Gaussian bootstrap_ci_derived
    #    (::GllvmFit) within Monte-Carlo error (same data, same seed).
    # =======================================================================

    @testset "Gaussian reduction (all-Normal mixed ≈ Gaussian fit)" begin
        Random.seed!(202)
        p, K, n = 4, 1, 250
        Λ = reshape([0.8, 0.6, 0.4, -0.3], p, K)
        σ = 0.4
        y = Λ * randn(K, n) + σ * randn(p, n)

        fg = fit_gaussian_gllvm(y; K = K)
        cg = GLLVM.bootstrap_ci_derived(fg, f -> GLLVM.correlation(f)[1, 2];
                                        y = y, n_boot = 80, seed = 5)

        fams = [Normal() for _ in 1:p]
        fm = fit_mixed_gllvm(y; families = fams, K = K)
        cm = GLLVM.correlation_boot_ci(fm, 1, 2; Y = y, n_boot = 80, seed = 5)

        # Point estimates agree to within MC/optimisation slack: the Gaussian fit
        # uses a shared σ²_eps; the all-Normal mixed uses per-trait σ_t² on the
        # Laplace marginal (exact for a Gaussian integrand). Both reduce to the
        # same model.
        @test isapprox(cg.estimate, cm.estimate; atol = 0.03)
        # Bootstrap CI bounds agree within MC error at n_boot = 80.
        @test isapprox(cg.lower, cm.lower; atol = 0.05)
        @test isapprox(cg.upper, cm.upper; atol = 0.05)
    end

    # =======================================================================
    # 4. Transformed-scale Wald (Fisher-z / logit) for the μ̂-free families
    #    (Binomial, Ordinal): exact packed reconstruction, observed-information
    #    Hessian. Brackets the estimate, stays in-range, agrees with bootstrap.
    # =======================================================================

    @testset "Binomial transformed-Wald (Fisher-z + logit)" begin
        Random.seed!(303)
        p, K, n = 4, 1, 300
        Λ = reshape([1.0, 0.8, -0.6, 0.5], p, K)
        β = [0.2, -0.3, 0.1, 0.0]
        Y = round.(Int, simulate(Binomial(), β, Λ, n; seed = 9))
        fit = fit_binomial_gllvm(Y; K = K)
        R = GLLVM.correlation(fit, Y)
        c2 = GLLVM.communality(fit, Y)

        ciρ = GLLVM.correlation_wald_ci(fit, 1, 2; Y = Y)
        @test ciρ.method === :transformed_wald
        @test ciρ.transform === :fisher_z
        @test ciρ.pd_hessian
        @test isapprox(ciρ.estimate, R[1, 2]; rtol = 1e-10)
        @test _brackets(ciρ)
        @test -1 < ciρ.lower && ciρ.upper < 1     # guaranteed by tanh back-transform

        cic = GLLVM.communality_wald_ci(fit, 1; Y = Y)
        @test cic.method === :transformed_wald
        @test cic.transform === :logit
        @test isapprox(cic.estimate, c2[1]; rtol = 1e-10)
        @test _brackets(cic)
        @test 0 < cic.lower && cic.upper < 1      # guaranteed by logistic back-transform

        # Wald and bootstrap agree to within MC + asymptotic-approximation error.
        cib = GLLVM.correlation_boot_ci(fit, 1, 2; Y = Y, n_boot = 80, seed = 2)
        @test isapprox(ciρ.lower, cib.lower; atol = 0.12)
        @test isapprox(ciρ.upper, cib.upper; atol = 0.12)
    end

    @testset "Ordinal transformed-Wald (Fisher-z) agrees with bootstrap" begin
        Random.seed!(707)
        p, K, n = 4, 1, 300
        Λ = reshape([1.2, 1.0, -0.8, 0.6], p, K)
        Y = round.(Int, simulate(Ordinal(), [-1.0, 0.5], Λ, n; seed = 4))
        fit = fit_ordinal_gllvm(Y; K = K)
        R = GLLVM.correlation(fit, Y)

        ciw = GLLVM.correlation_wald_ci(fit, 1, 2; Y = Y)
        @test ciw.method === :transformed_wald
        @test ciw.pd_hessian
        @test isapprox(ciw.estimate, R[1, 2]; rtol = 1e-10)
        @test _brackets(ciw)
        @test -1 < ciw.lower && ciw.upper < 1

        cib = GLLVM.correlation_boot_ci(fit, 1, 2; Y = Y, n_boot = 40, seed = 1)
        @test isapprox(ciw.lower, cib.lower; atol = 0.12)
        @test isapprox(ciw.upper, cib.upper; atol = 0.12)
    end

    # -----------------------------------------------------------------------
    # NA-aware derived bootstrap (#93): on a missing-typed Y the derived bootstrap
    # re-imposes the original missingness pattern on every replicate, so each refit
    # sees the same information loss (FIML parametric bootstrap). The masked-refit
    # path must run end-to-end and return a finite, ordered correlation CI. (On a
    # dense Y any_miss is false ⇒ byte-identical to the complete-data bootstrap.)
    # -----------------------------------------------------------------------
    @testset "NA-aware derived bootstrap (#93)" begin
        Random.seed!(9301)
        p, K, n = 4, 1, 200
        β = log.([5.0, 4.0, 6.0, 5.0]); Λ = 0.35 .* randn(p, K)
        Y = round.(Int, simulate(Poisson(), β, Λ, n; seed = 9302))
        Ym = Matrix{Union{Missing, Int}}(Y)
        Random.seed!(9303)
        for idx in eachindex(Ym)
            rand() < 0.12 && (Ym[idx] = missing)
        end
        fit = fit_poisson_gllvm(Ym; K = K)
        ci = GLLVM.correlation_boot_ci(fit, 1, 2; Y = Ym, n_boot = 40, seed = 1)
        @test ci.n_converged ≥ 20                    # masked refits converge
        @test isfinite(ci.lower) && isfinite(ci.upper)
        @test ci.lower ≤ ci.estimate ≤ ci.upper
        @test -1 ≤ ci.lower ≤ ci.upper ≤ 1
    end

end
