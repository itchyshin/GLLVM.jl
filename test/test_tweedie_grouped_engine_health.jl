using GLLVM, Test, Random, Distributions, Statistics, LinearAlgebra

# Engine-health gates for `fit_tweedie_gllvm_grouped` — the same three defects
# #236 closed on the scalar fitter (Identity §T6 / PR note OWED #1):
#
#   src/families/grouped_dispersion.jl warm start `log.(max.(Yc, 1e-6))`
#   bare `1e12` failure sentinel returned as a maximised log-likelihood
#   naked `Optim.converged(res)` advertised as a maximum
#
# On the shipped `test/test_tweedie.jl` cell with one shared group, the old
# fitter reported `converged = true` at start-pinned / sentinel points just as
# the scalar fitter did. These tests fail under that behaviour.

@testset "Tweedie grouped engine health" begin

    function shipped_cell()
        Random.seed!(2024)
        p_sp = 5; n = 40; K = 2
        β = log.(rand(p_sp) .* 2 .+ 0.5)
        Λ = randn(p_sp, K) .* 0.4
        Y = zeros(p_sp, n)
        for s in 1:n
            z = randn(K)
            for t in 1:p_sp
                μ = exp(β[t] + dot(Λ[t, :], z))
                λ = μ
                k = rand(Poisson(λ))
                Y[t, s] = k == 0 ? 0.0 : sum(rand(Gamma(2.0, μ / (2.0 * λ + 1e-9)), k))
            end
        end
        return Y, K
    end

    # -------------------------------------------------------------------
    # One shared group on the shipped cell: same estimand as the scalar
    # fitter. Under the old warm start + naked Optim verdict this sweep
    # disagreed by ~9 orders of magnitude and returned the 1e12 sentinel.
    # -------------------------------------------------------------------
    @testset "one-group power-start agreement on the shipped cell" begin
        Y, K = shipped_cell()
        g = ones(Int, size(Y, 1))
        starts = [1.1, 1.5, 1.9]
        fits = [fit_tweedie_gllvm_grouped(Y; K = K, group = g, power_init = s)
                for s in starts]

        @test all(f -> f.converged, fits)
        @test all(f -> length(f.φ) == 1, fits)

        ref = fits[1]
        for f in fits
            @test isapprox(f.power, ref.power; rtol = 1e-4)
            @test isapprox(f.φ[1], ref.φ[1]; rtol = 1e-4)
            @test isapprox(f.loglik, ref.loglik; rtol = 1e-6)
            @test isfinite(f.loglik)
            @test f.loglik > -1e4
            @test f.loglik != -GLLVM._TWEEDIE_FAIL_PENALTY
            @test 1 < f.power < 2
            @test abs(log((f.power - 1) / (2 - f.power))) <= GLLVM._TWEEDIE_XI_MAX
        end

        # Same repair bar as the scalar G-a pin: beat the pre-repair best start.
        @test ref.loglik > -569.74

        # One group is the scalar estimand. After both repairs the two fitters
        # land on the same numerical optimum (not merely both report converged).
        # `fit_tweedie_gllvm_grouped` has no `hessian` selector at all
        # (unconditional Fisher); the shared route's DEFAULT flipped to
        # :observed 2026-08-28 (maintainer decision batch), so it must be
        # pinned to `hessian = :fisher` explicitly here to stay the same
        # estimand as `ref` — otherwise this compares two different
        # objectives and calls the difference a bug.
        # Note: scalar and grouped fitters use slightly different parameter vector
        # packings and optimization trajectories, matching to numerical tolerance.
        fs = fit_tweedie_gllvm(Y; K = K, p_init = 1.5, hessian = :fisher)
        @test fs.converged
        @test isapprox(ref.power, fs.p; rtol = 1e-3)
        @test isapprox(ref.φ[1], fs.φ; rtol = 5e-3)
        @test isapprox(ref.loglik, fs.loglik; rtol = 1e-3)
    end

    # -------------------------------------------------------------------
    # Per-species φ (the public `disp_group = :species` route). Smaller
    # cell, correct compound Poisson–Gamma DGP. Old behaviour could still
    # advertise a start-pinned / sentinel point as converged.
    # -------------------------------------------------------------------
    @testset "per-species power-start agreement" begin
        Random.seed!(704)
        p, K, n = 3, 1, 40
        β = 0.3 .* randn(p)
        Λ = 0.3 .* randn(p, K)
        φtrue = 1.2
        power = 1.5
        Y = Matrix{Float64}(undef, p, n)
        for i in 1:n
            ηv = β .+ Λ * randn(K)
            μ = exp.(ηv)
            for t in 1:p
                λ = μ[t]^(2 - power) / (φtrue * (2 - power))
                Npois = rand(Poisson(λ))
                if Npois == 0
                    Y[t, i] = 0.0
                else
                    shape = (2 - power) / (power - 1)
                    scale = φtrue * (power - 1) * μ[t]^(power - 1)
                    Y[t, i] = sum(rand(Gamma(shape, scale)) for _ in 1:Npois)
                end
            end
        end

        starts = [1.1, 1.5]
        fits = [fit_tweedie_gllvm_grouped(Y; K = K, power_init = s) for s in starts]
        @test all(f -> f.converged, fits)
        @test all(f -> length(f.φ) == p, fits)

        ref = fits[1]
        for f in fits
            @test isapprox(f.power, ref.power; rtol = 1e-3)
            @test isapprox(f.loglik, ref.loglik; rtol = 1e-5)
            @test isfinite(f.loglik)
            @test f.loglik > -1e4
            @test f.loglik != -GLLVM._TWEEDIE_FAIL_PENALTY
            @test 1 < f.power < 2
            @test all(>(0), f.φ)
        end
    end
end
