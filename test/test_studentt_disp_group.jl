# `disp_group::Symbol` on fit_studentt_gllvm (2026-08-28) — per-trait scale σ,
# matching gllvmTMB's per-trait `log_sigma_student` (gllvmTMB.cpp:1184, length
# n_traits). `:shared` (default) stays bit-identical to the pre-existing
# single-scalar-dispersion fitter; `:species` is new. Degrees of freedom `ν`
# stays a single shared scalar under BOTH modes — per-trait `ν` is a further
# step (out of scope here); see
# docs/dev-log/decisions/2026-08-28-studentt-parameterisation.md and
# docs/dev-log/decisions/2026-08-28-per-trait-dispersion-synthesis.md. Mirrors
# the delta fitters' `disp_group` precedent (test_delta_disp_group.jl,
# commit 15388b46).
#
# Seeds 710-715 — fresh, outside test_studentt.jl's 701-709 and
# test_delta_disp_group.jl's 180-186.

using GLLVM, Test, Random, Distributions, Statistics

@testset "Student-t family: disp_group mode (:shared / :species)" begin

    @testset ":shared ≡ omitted — bit-identical (compat safety net)" begin
        Random.seed!(710)
        p, K, n = 5, 1, 100
        Y = randn(p, n)

        f_omit = fit_studentt_gllvm(Y; K = K, nu = 4.0)
        f_shared = fit_studentt_gllvm(Y; K = K, nu = 4.0, disp_group = :shared)
        @test f_omit.disp_group == :shared
        @test f_shared.disp_group == :shared
        @test f_omit.loglik == f_shared.loglik
        @test f_omit.β == f_shared.β
        @test f_omit.Λ == f_shared.Λ
        @test f_omit.σ == f_shared.σ
        @test f_omit.σ isa Float64
    end

    @testset "invalid disp_group throws ArgumentError" begin
        Random.seed!(711)
        p, K, n = 4, 1, 40
        Y = randn(p, n)
        @test_throws ArgumentError fit_studentt_gllvm(Y; K = K, disp_group = :bogus)
    end

    @testset ":species recovers per-trait dispersion" begin
        Random.seed!(712)
        p, K, n = 8, 1, 150
        β_true = 0.4 .* randn(p)
        Λ_true = 0.3 .* randn(p, K)
        σ_true = 0.3 .+ 0.7 .* rand(p)     # genuinely different per-trait scales
        ν_true = 5.0
        Z = randn(K, n)
        η = β_true .+ Λ_true * Z
        Y = zeros(p, n)
        for t in 1:p, s in 1:n
            Y[t, s] = η[t, s] + σ_true[t] * rand(TDist(ν_true))
        end

        f = fit_studentt_gllvm(Y; K = K, nu = ν_true, disp_group = :species, iterations = 400)
        @test f isa GLLVM.StudentTFit
        @test f.disp_group == :species
        @test f.σ isa Vector{Float64}
        @test length(f.σ) == p
        @test f.converged
        @test isfinite(f.loglik)
        @test cor(f.σ, σ_true) > 0.5
    end

    @testset ":species logLik >= :shared logLik (nesting)" begin
        Random.seed!(713)
        p, K, n = 5, 1, 120
        β_true = 0.3 .* randn(p)
        Λ_true = 0.3 .* randn(p, K)
        σ_true = 0.3 .+ 0.5 .* rand(p)
        ν_true = 6.0
        Z = randn(K, n)
        η = β_true .+ Λ_true * Z
        Y = zeros(p, n)
        for t in 1:p, s in 1:n
            Y[t, s] = η[t, s] + σ_true[t] * rand(TDist(ν_true))
        end

        f_shared = fit_studentt_gllvm(Y; K = K, nu = ν_true, disp_group = :shared, iterations = 400)
        f_species = fit_studentt_gllvm(Y; K = K, nu = ν_true, disp_group = :species, iterations = 400)
        @test f_shared.converged
        @test f_species.converged
        # :shared is the :species model with all p scales tied — a constrained
        # special case, so the (better-optimised) :species logLik should not be
        # meaningfully below the :shared logLik. Small negative slack tolerates
        # optimiser noise (LBFGS + finite-difference gradient on two different
        # objective shapes), not a systematic ordering violation.
        @test f_species.loglik >= f_shared.loglik - 1e-3
    end

    @testset "composition with hessian = :fisher" begin
        Random.seed!(714)
        p, K, n = 5, 1, 100
        β_true = 0.3 .* randn(p)
        Λ_true = 0.3 .* randn(p, K)
        σ_true = 0.3 .+ 0.4 .* rand(p)
        ν_true = 5.0
        Z = randn(K, n)
        η = β_true .+ Λ_true * Z
        Y = zeros(p, n)
        for t in 1:p, s in 1:n
            Y[t, s] = η[t, s] + σ_true[t] * rand(TDist(ν_true))
        end

        f = fit_studentt_gllvm(Y; K = K, nu = ν_true, disp_group = :species,
                               hessian = :fisher, iterations = 400)
        @test f isa GLLVM.StudentTFit
        @test f.hessian == :fisher
        @test f.disp_group == :species
        @test f.σ isa Vector{Float64}
        @test length(f.σ) == p
        @test f.converged
        @test isfinite(f.loglik)
    end

    @testset "direct kernel eval at θ̂ reproduces fitted loglik (per-trait σ)" begin
        Random.seed!(715)
        p, K, n = 5, 1, 100
        β_true = 0.3 .* randn(p)
        Λ_true = 0.3 .* randn(p, K)
        σ_true = 0.3 .+ 0.5 .* rand(p)
        ν_true = 4.0
        Z = randn(K, n)
        η = β_true .+ Λ_true * Z
        Y = zeros(p, n)
        for t in 1:p, s in 1:n
            Y[t, s] = η[t, s] + σ_true[t] * rand(TDist(ν_true))
        end

        f = fit_studentt_gllvm(Y; K = K, nu = ν_true, disp_group = :species, iterations = 400)
        ll_direct = GLLVM.studentt_marginal_loglik_laplace(Y, f.Λ, f.β, f.σ;
                                                            ν = f.ν, hessian = f.hessian)
        @test ll_direct ≈ f.loglik atol = 1e-8
    end
end
