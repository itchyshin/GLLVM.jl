using Test, GLLVM, LinearAlgebra, TOML, Random, Distributions

# Unit tests for the family-generic cross-objective helpers (panel 2026-09-01
# generalization) added in tools/core070_cross_objective.jl:
# `cross_objective_at` and its `_loadings_from` loadings-vs-crossprod
# resolver. Nothing here runs R (no RCall dependency) — the R-side of the
# known-answer gate is exercised separately by
# test/test_cross_objective_known_answer.jl. `core070_cross_objective_delta`
# in test/parity/parity_helpers.jl is a thin TOML-keyed adapter over
# `cross_objective_at` and is not re-tested here since parity_helpers.jl pulls
# in RCall, which the main project environment does not depend on.
include(joinpath(@__DIR__, "..", "tools", "core070_cross_objective.jl"))

@testset "cross_objective_at — generic helper" begin
    @testset "gaussian_sources vs the retained COV-ORD-LATENT-BARE fixture" begin
        fixture = joinpath(@__DIR__, "fixtures", "core070_latent_bare_retained.toml")
        if !isfile(fixture)
            @warn "retained-coordinate fixture absent; gaussian_sources cross_objective_at check NOT RUN" fixture
            @test_skip false
        else
            res = TOML.parsefile(fixture)
            yrow = include(joinpath(@__DIR__, "fixtures", "input_gauss_loadings_y.jl"))
            Y = collect(reshape(yrow, 18, 3)')
            source = SourceCovariance(Matrix{Float64}(I, 18, 18); groups = 1:18,
                mode = :latent, rank = 1, unique = false, name = :ordinary_latent)
            for route in ("native_julia", "r_reference")
                r = res[route]
                crossprod = Matrix{Float64}(reduce(hcat, [Vector{Float64}(c) for c in r["crossprod"]]))
                ll = cross_objective_at(:gaussian_sources, Y; beta = Vector{Float64}(r["beta"]),
                    crossprod_or_loadings = crossprod, rank = 1,
                    dispersion = Float64(r["residual_variance"]), source = source)
                @test isfinite(ll)
                # Same tolerance as test_cross_objective_known_answer.jl: retained
                # coordinates are serialized at ~15 significant digits, well below
                # any likelihood-function discrepancy this checks for.
                @test abs(ll - Float64(r["loglik"])) <= 1e-8
            end
        end
    end

    @testset "poisson — own fitted coordinates (loadings form)" begin
        Random.seed!(90210)
        p, K, n = 5, 1, 60
        β_true = log.([3.0, 4.0, 2.5, 3.5, 3.0])
        Λ_true = 0.4 .* randn(p, K)
        η = β_true .+ Λ_true * randn(K, n)
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]

        fit = fit_poisson_gllvm(Y; K = K)
        @test fit.converged

        # p != K here, so this hits the "already a loadings matrix" branch of
        # `_loadings_from` rather than the crossprod-factoring branch.
        ll_loadings = cross_objective_at(:poisson, Y; beta = fit.β,
            crossprod_or_loadings = fit.Λ, rank = K, link = fit.link)
        @test isfinite(ll_loadings)
        @test abs(ll_loadings - fit.loglik) <= 1e-9

        # Equivalent crossprod form (ΛΛᵀ): rotation-invariant reconstruction
        # must reproduce the identical value (K=1, so no sign ambiguity here
        # since squaring erases the loading's own sign either way).
        ll_crossprod = cross_objective_at(:poisson, Y; beta = fit.β,
            crossprod_or_loadings = fit.Λ * fit.Λ', rank = K, link = fit.link)
        @test abs(ll_crossprod - fit.loglik) <= 1e-9
    end

    @testset "binomial — own fitted coordinates (loadings form)" begin
        Random.seed!(90211)
        p, K, n = 5, 1, 60
        β_true = [0.2, -0.3, 0.5, -0.1, 0.4]
        Λ_true = 0.4 .* randn(p, K)
        η = β_true .+ Λ_true * randn(K, n)
        Y = [rand(Bernoulli(1 / (1 + exp(-η[t, s])))) for t in 1:p, s in 1:n]
        Y = Int.(Y)

        fit = fit_binomial_gllvm(Y; K = K)
        @test fit.converged

        ll_loadings = cross_objective_at(:binomial, Y; beta = fit.β,
            crossprod_or_loadings = fit.Λ, rank = K, link = fit.link)
        @test isfinite(ll_loadings)
        @test abs(ll_loadings - fit.loglik) <= 1e-9

        ll_crossprod = cross_objective_at(:binomial, Y; beta = fit.β,
            crossprod_or_loadings = fit.Λ * fit.Λ', rank = K, link = fit.link)
        @test abs(ll_crossprod - fit.loglik) <= 1e-9
    end

    @testset "argument errors" begin
        Y = zeros(3, 4)
        @test_throws ArgumentError cross_objective_at(:not_a_family, Y;
            beta = zeros(3), crossprod_or_loadings = zeros(3, 3), rank = 1)
        @test_throws ArgumentError cross_objective_at(:poisson, Y;
            beta = zeros(3), crossprod_or_loadings = zeros(2, 5), rank = 1)
        @test_throws ArgumentError cross_objective_at(:gaussian_sources, Y;
            beta = zeros(3), crossprod_or_loadings = zeros(3, 3), rank = 1)
    end
end
