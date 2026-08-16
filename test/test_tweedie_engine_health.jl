using GLLVM, Test, Random, Distributions, Statistics, LinearAlgebra

# Engine-health gates G-a…G-d for `fit_tweedie_gllvm`, specified in
# docs/dev-log/decisions/2026-08-16-tweedie-fit-gllvm-identity.md §T6.
#
# Before the repair, on the shipped `test/test_tweedie.jl` cell verbatim, the
# fitter reported `converged = true` at points that were not maxima:
#
#   p_init=1.1 -> p̂=1.25195  φ̂=2.07988    loglik=-569.74       conv=true
#   p_init=1.3 -> p̂=1.30000  φ̂=1.0        loglik=-1090.07      conv=true
#   p_init=1.5 -> p̂=1.50000  φ̂=1.0        loglik=-3.8886709e11 conv=true
#   p_init=1.7 -> p̂=1.00000  φ̂=3.24777e54 loglik=-1.0e12       conv=true
#   p_init=1.9 -> p̂=1.00000  φ̂=2.20421e205 loglik=-1.0e12      conv=true
#
# i.e. the dispersion pair pinned at its start, ~9 orders of magnitude of
# log-likelihood left on the table, the internal 1e12 failure sentinel returned
# as a maximised log-likelihood, and p̂ = 1.0 outside the open interval (1,2)
# that `TweedieFit`'s own docstring promises. The shipped assertions
# (`isfinite`, `1 < p < 2`, `φ > 0`) passed on all of that at the default start.
#
# These tests fail on every one of those rows under the old behaviour.

@testset "Tweedie engine health (G-a…G-d)" begin

    # The shipped test cell, verbatim (test/test_tweedie.jl:48-63).
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

    # -----------------------------------------------------------------------
    # G-b / G-c, unit level: the convergence contract itself. Each row below is
    # a verbatim replay of an observed pre-repair failure.
    # -----------------------------------------------------------------------
    @testset "G-b/G-c convergence contract" begin
        # Flat 1e12 failure plateau: the finite-difference gradient is exactly
        # zero there, so Optim reports g_converged. Never a result.
        conv, ll, why = GLLVM._tweedie_verdict(true, 0.0, 1e12, -60.0, 1e-5)
        @test !conv
        @test why === :objective_failed
        @test ll == -Inf                      # not -1e12  (G-b)

        # Non-finite objective at the returned point is the same failure.
        conv, ll, why = GLLVM._tweedie_verdict(true, 0.0, Inf, 0.0, 1e-5)
        @test !conv && why === :objective_failed && ll == -Inf

        # Power run to the closed end of (1,2): ξ = -60 ⇒ p̂ rounds to 1.0.  (G-c)
        conv, ll, why = GLLVM._tweedie_verdict(true, 1e-9, 336.6, -60.0, 1e-5)
        @test !conv
        @test why === :power_at_boundary
        @test isfinite(ll)
        # …and symmetrically at the p → 2 end.
        @test GLLVM._tweedie_verdict(true, 1e-9, 336.6, 60.0, 1e-5)[3] === :power_at_boundary

        # The stall that used to advertise as success: Optim's relative f-change
        # test fires while the gradient residual is ~1e15.
        conv, ll, why = GLLVM._tweedie_verdict(true, 8.077e15, 3.8886709e11, 0.0, 1e-5)
        @test !conv
        @test why === :gradient_not_small

        # A healthy point is still reported as converged.
        conv, ll, why = GLLVM._tweedie_verdict(true, 5.585e-6, 336.594, -1.16, 1e-5)
        @test conv
        @test why === :ok
        @test ll ≈ -336.594
        # …and Optim's own "not converged" is never overridden upward.
        @test !GLLVM._tweedie_verdict(false, 5.585e-6, 336.594, -1.16, 1e-5)[1]
    end

    # -----------------------------------------------------------------------
    # G-a: the answer must not depend on where the power search starts.
    # -----------------------------------------------------------------------
    @testset "G-a power-start agreement on the shipped cell" begin
        Y, K = shipped_cell()
        starts = [1.1, 1.5, 1.9]
        fits = [fit_tweedie_gllvm(Y; K = K, p_init = s) for s in starts]

        @test all(f -> f.converged, fits)

        ref = fits[1]
        for f in fits
            @test isapprox(f.p, ref.p; rtol = 1e-4)
            @test isapprox(f.φ, ref.φ; rtol = 1e-4)
            @test isapprox(f.loglik, ref.loglik; rtol = 1e-6)
        end

        # G-b at fit level: no converged fit may carry the failure sentinel, and
        # the optimum is nowhere near the pre-repair stall (-3.9e11 / -1e12).
        for f in fits
            @test isfinite(f.loglik)
            @test f.loglik > -1e4
        end

        # G-c at fit level: strictly interior power, with room to spare.
        for f in fits
            @test 1 < f.p < 2
            @test abs(log((f.p - 1) / (2 - f.p))) <= GLLVM._TWEEDIE_XI_MAX
        end

        # The repair must not be a lateral move: the pre-repair best start
        # (p_init = 1.1) reached -569.74, and the default start -3.889e11.
        @test ref.loglik > -569.74
    end

    # -----------------------------------------------------------------------
    # G-d: ADEMP recovery on (φ, power) from the correct compound Poisson–Gamma
    # DGP (AGENTS.md design rule 1) — note the shipped `test_tweedie.jl` cell
    # draws from a "rough Poisson intensity" approximation, not a Tweedie, so it
    # cannot support a recovery claim at all.
    #
    # Measured on this branch (3 replicates, p=6, n=80, K=1, φ=1.0, power=1.5):
    #   φ̂ = 0.9778, 0.9496, 1.1374  (mean 1.0216)
    #   p̂ = 1.4640, 1.5025, 1.5295  (mean 1.4987)
    # The (φ, power) ridge is genuinely flat, so the bounds below are a recovery
    # floor with room for platform-to-platform optimiser drift, not a precision
    # claim — but they are bounds on the estimand, which "isfinite" is not.
    # -----------------------------------------------------------------------
    @testset "G-d (φ, power) recovery" begin
        φ_true = 1.0
        p_true = 1.5
        p_sp = 6; n = 80; K = 1
        nrep = 3

        φs = Float64[]; ps = Float64[]
        for rep in 1:nrep
            rng = MersenneTwister(1000 + rep)
            β = log.(rand(rng, p_sp) .* 2 .+ 1.0)
            Λ = randn(rng, p_sp, K) .* 0.4
            Y = Matrix{Float64}(undef, p_sp, n)
            for s in 1:n
                z = randn(rng, K)
                for t in 1:p_sp
                    μ = exp(β[t] + dot(Λ[t, :], z))
                    Y[t, s] = GLLVM._tweedie_sample(μ, φ_true, p_true, rng)
                end
            end
            f = fit_tweedie_gllvm(Y; K = K)
            @test f.converged
            # Per replicate: the pre-repair engine returned φ̂ up to 2e205 and p̂
            # pinned at its start or at 1.0, so these bounds are not vacuous.
            @test 0.4 < f.φ < 2.5
            @test abs(f.p - p_true) < 0.25
            push!(φs, f.φ); push!(ps, f.p)
        end

        @test isapprox(mean(φs), φ_true; rtol = 0.15)
        @test isapprox(mean(ps), p_true; atol = 0.06)
    end
end
