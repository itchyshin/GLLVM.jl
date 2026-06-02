using GLLVM, Test, Random, LinearAlgebra, Statistics

# The bootstrap CI source lives in src/confint_bootstrap.jl and is NOT
# wired into the main module file (the hard constraint for this slice
# is "new files only"). The verify recipe in the spec includes the
# source file directly into Main:
#
#   julia --project=. -e 'using GLLVM, Test;
#                          include("src/confint_bootstrap.jl");
#                          include("test/test_confint_bootstrap.jl")'
#
# When loaded that way, `bootstrap_ci` lives in `Main`, not in
# `GLLVM`. The tests below call it unqualified for that reason.

# Local guard: include the source file if it has not already been
# loaded into the current scope (e.g. when running this file via
# `Pkg.test` instead of the verify recipe).
if !isdefined(@__MODULE__, :bootstrap_ci)
    include(joinpath(@__DIR__, "..", "src", "confint_bootstrap.jl"))
end

@testset "parametric bootstrap CI" begin
    @testset "returns expected shape" begin
        Random.seed!(0)
        p, K, n = 4, 1, 100
        Λ_true = reshape([0.7, 0.5, 0.4, -0.3], p, K)
        y = Λ_true * randn(K, n) + 0.5 * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        ci = bootstrap_ci(fit; y = y, n_boot = 30, seed = 1)
        @test length(ci.term) == length(ci.lower) == length(ci.upper)
        @test length(ci.term) == length(ci.estimate)
        # Percentile CI brackets the estimate when it brackets it — but
        # because the percentile is on the *bootstrap distribution* of
        # θ̂_b, not on the original θ̂, the original estimate may sit
        # outside if the bootstrap distribution is heavily shifted. For
        # a clean fixture at n = 100 with n_boot = 30 the brackets are
        # almost always satisfied for the major identifiable params;
        # we just require that the bounds are finite.
        @test all(isfinite, ci.lower)
        @test all(isfinite, ci.upper)
        @test ci.n_converged >= 25
        @test size(ci.replicates) == (30, length(fit.pars.θ_packed))
    end

    @testset "coverage of σ_eps at n=500 with n_boot=200" begin
        # Quick sanity that the bootstrap covers the truth.
        Random.seed!(1)
        p, K, n = 4, 1, 500
        Λ_true = reshape([0.7, 0.5, 0.4, -0.3], p, K)
        σ_true = 0.5
        y = Λ_true * randn(K, n) + σ_true * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        ci = bootstrap_ci(fit; y = y, n_boot = 200, seed = 2)
        idx_se = findfirst(==("sigma_eps"), ci.term)
        @test !isnothing(idx_se)
        # The percentile CI for log σ_eps brackets log(σ_true) — but
        # since θ_packed stores log σ_eps the bracket is on the working
        # (log) scale. Translate truth onto the same scale.
        truth_log = log(σ_true)
        @test ci.lower[idx_se] < truth_log < ci.upper[idx_se]
        @info "σ_eps bootstrap CI (log scale)" lower=ci.lower[idx_se] estimate=ci.estimate[idx_se] upper=ci.upper[idx_se] truth=truth_log raw_lower=exp(ci.lower[idx_se]) raw_upper=exp(ci.upper[idx_se]) raw_truth=σ_true
    end

    @testset "seed reproducibility" begin
        Random.seed!(2)
        p, K, n = 3, 1, 100
        y = 0.5 * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        ci1 = bootstrap_ci(fit; y = y, n_boot = 20, seed = 42)
        ci2 = bootstrap_ci(fit; y = y, n_boot = 20, seed = 42)
        @test ci1.replicates == ci2.replicates
    end

    @testset "parallel and serial use the same per-replicate seeds" begin
        Random.seed!(3)
        p, K, n = 3, 1, 80
        y = 0.5 * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        ci_serial = bootstrap_ci(fit; y = y, n_boot = 12, seed = 43,
                                 parallel = false)
        ci_parallel = bootstrap_ci(fit; y = y, n_boot = 12, seed = 43,
                                   parallel = true)
        @test ci_serial.replicates == ci_parallel.replicates
        @test ci_serial.n_converged == ci_parallel.n_converged

        ci_warm = bootstrap_ci(fit; y = y, n_boot = 12, seed = 43,
                               parallel = false, warm_start = true)
        @test all(isfinite, ci_warm.lower)
        @test ci_warm.n_converged ≥ 10
    end
end
