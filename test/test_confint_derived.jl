using GLLVM, Test, Random, LinearAlgebra, Statistics

# Local guard: include the source files if they haven't been loaded.
# The CI infrastructure follows the same "load on demand" pattern as
# the sister files (see test/test_confint_bootstrap.jl).
if !isdefined(GLLVM, :bootstrap_ci)
    include(joinpath(@__DIR__, "..", "src", "confint_bootstrap.jl"))
end
if !isdefined(GLLVM, :sigma_y_site)
    include(joinpath(@__DIR__, "..", "src", "confint_derived.jl"))
end

@testset "derived-quantity CIs" begin

    @testset "sigma_y_site shape and PSD" begin
        Random.seed!(0)
        p, K, n = 4, 1, 100
        Λ_true = reshape([0.7, 0.5, 0.4, -0.3], p, K)
        y = Λ_true * randn(K, n) + 0.5 * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)

        Σ = GLLVM.sigma_y_site(fit)
        @test size(Σ) == (p, p)
        # Symmetric (up to round-off)
        @test maximum(abs.(Σ - Σ')) < 1e-12
        # PSD: smallest eigenvalue ≥ 0 (up to round-off)
        λmin = minimum(eigvals(Symmetric(Σ)))
        @test λmin > -1e-10
    end

    @testset "communality in [0, 1]" begin
        Random.seed!(1)
        p, K, n = 4, 1, 200
        Λ_true = reshape([0.8, 0.6, 0.4, -0.3], p, K)
        y = Λ_true * randn(K, n) + 0.4 * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)

        c2 = GLLVM.communality(fit)
        @test length(c2) == p
        @test all(0.0 .≤ c2 .≤ 1.0)
        # Independently verify against the explicit formula
        Λ_B = fit.pars.Λ
        ΛΛt = Λ_B * Λ_B'
        Σ = GLLVM.sigma_y_site(fit)
        c2_manual = [ΛΛt[t, t] / Σ[t, t] for t in 1:p]
        @test c2 ≈ c2_manual rtol = 1e-12
    end

    @testset "proportions sum to ~1 for shared + residual (J1)" begin
        Random.seed!(2)
        p, K, n = 4, 1, 200
        Λ_true = reshape([0.7, 0.5, 0.4, -0.3], p, K)
        y = Λ_true * randn(K, n) + 0.5 * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        shared   = GLLVM.proportions(fit; component = :shared)
        residual = GLLVM.proportions(fit; component = :residual)
        # For J1 (no W, no diag) shared + residual must equal 1 per trait.
        @test all(abs.(shared .+ residual .- 1.0) .< 1e-12)
        # unique_W / unique_B / unique_Wd are zero for J1.
        @test all(iszero, GLLVM.proportions(fit; component = :unique_W))
        @test all(iszero, GLLVM.proportions(fit; component = :unique_B))
        @test all(iszero, GLLVM.proportions(fit; component = :unique_Wd))
    end

    @testset "correlation is unit-diagonal and bounded" begin
        Random.seed!(3)
        p, K, n = 4, 1, 200
        Λ_true = reshape([0.7, 0.5, 0.4, -0.3], p, K)
        y = Λ_true * randn(K, n) + 0.5 * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        R = GLLVM.correlation(fit)
        @test size(R) == (p, p)
        for t in 1:p
            @test isapprox(R[t, t], 1.0; atol = 1e-12)
        end
        # Off-diagonals must be in [-1, 1] (rounding tolerance)
        for j in 1:p, i in 1:p
            @test -1 - 1e-12 ≤ R[i, j] ≤ 1 + 1e-12
        end
    end

    @testset "phylo_signal is NaN with no phy block" begin
        Random.seed!(4)
        p, K, n = 4, 1, 100
        Λ_true = reshape([0.7, 0.5, 0.4, -0.3], p, K)
        y = Λ_true * randn(K, n) + 0.5 * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        h2 = GLLVM.phylo_signal(fit)
        @test length(h2) == p
        @test all(isnan, h2)
    end

    @testset "bootstrap CI for communality[1] brackets the truth" begin
        # Clean fixture: n = 500, n_boot = 200 — the spec's required gate.
        Random.seed!(5)
        p, K, n = 4, 1, 500
        Λ_true = reshape([0.8, 0.5, 0.4, -0.3], p, K)
        σ_true = 0.4
        y = Λ_true * randn(K, n) + σ_true * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        @test fit.converged

        # Truth: for trait 1, c²_true = Λ²_true[1] / (Λ²_true[1] + σ²)
        ΛΛt_true = Λ_true * Λ_true'
        c2_truth = ΛΛt_true[1, 1] / (ΛΛt_true[1, 1] + σ_true^2)

        ci = GLLVM.bootstrap_ci_derived(fit, fb -> GLLVM.communality(fb)[1];
                                        y = y, n_boot = 200, seed = 11)
        @info "communality[1] bootstrap CI" lower=ci.lower estimate=ci.estimate upper=ci.upper truth=c2_truth n_converged=ci.n_converged n_valid=ci.n_valid
        @test isfinite(ci.lower) && isfinite(ci.upper)
        @test ci.lower < ci.upper
        @test ci.lower < c2_truth < ci.upper
        # Estimate should be sensible: in [0, 1] and near the truth.
        @test 0.0 ≤ ci.estimate ≤ 1.0
    end

    @testset "profile CI for σ_eps² agrees with parameter profile CI on σ_eps" begin
        # Sanity: profile_ci_derived for the derived quantity σ_eps²
        # should yield the same bounds as profile_ci on σ_eps, squared.
        Random.seed!(6)
        p, K, n = 4, 1, 300
        Λ_true = reshape([0.7, 0.5, 0.4, -0.3], p, K)
        σ_true = 0.5
        y = Λ_true * randn(K, n) + σ_true * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        @test fit.converged

        # Per-parameter profile CI on σ_eps (raw scale).
        if !isdefined(GLLVM, :profile_ci)
            include(joinpath(@__DIR__, "..", "src", "confint_profile.jl"))
        end
        ci_param = GLLVM.profile_ci(fit, "sigma_eps"; y = y)
        @test isfinite(ci_param.lower) && isfinite(ci_param.upper)

        # Derived profile CI on σ_eps². log_σ_eps is at packed index q + 1.
        # For this fit q = 0 (no X), so β is an empty vector and the
        # σ_eps² closure is θ -> exp(2 θ[1]).
        @test isempty(fit.pars.β)
        f_se2 = θ -> exp(2 * θ[1])
        ci_der = GLLVM.profile_ci_derived(fit, f_se2;
                                          y = y, level = 0.95,
                                          penalty_weight = 1e7,
                                          initial_step = 0.05)
        @info "σ_eps profile CIs" param_lower=ci_param.lower param_upper=ci_param.upper der_lower=ci_der.lower der_upper=ci_der.upper der_estimate=ci_der.estimate
        @test ci_der.method === :profile
        @test isfinite(ci_der.lower) && isfinite(ci_der.upper)
        # Compare on the σ_eps² scale.
        # Tolerance is loose because the penalty-method profile is an
        # approximation to the equality-constrained problem, and the
        # bisection on the derived axis uses a different parameterisation
        # than the bisection on the raw σ_eps axis.
        sq_lower_param = ci_param.lower^2
        sq_upper_param = ci_param.upper^2
        @test isapprox(ci_der.lower, sq_lower_param; rtol = 0.20)
        @test isapprox(ci_der.upper, sq_upper_param; rtol = 0.20)
    end

end
