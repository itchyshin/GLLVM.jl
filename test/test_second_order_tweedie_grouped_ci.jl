# Second-order follow-up: TweedieGroupedFit Wald `_family_ci` (post §2 A).
# Clears the holdout `_CIFit` gap for grouped Tweedie; power held at fit (TweedieFit contract).
# Paired R SO cell still not wired (`r_fit_se` has no :tweedie) — ≠ programme §7.

using GLLVM, Test, Random

@testset "second-order TweedieGroupedFit Wald wiring" begin
    @testset "fixed power: θ packing + public Wald on beta" begin
        Random.seed!(182)
        p, K, n = 5, 1, 80
        β = [0.4, -0.1, 0.2, -0.3, 0.05]
        Λ = 0.35 .* ones(p, K)
        Λ[2, 1] = 0.15
        φ = [0.7, 0.9, 1.1, 0.8, 1.0]
        pw = 1.5
        Z = randn(K, n)
        μ = exp.(β .+ Λ * Z)
        Y = zeros(p, n)
        for t in 1:p, s in 1:n
            Y[t, s] = GLLVM._tweedie_sample(μ[t, s], φ[t], pw, Random.default_rng())
        end
        fit = fit_tweedie_gllvm_grouped(Y; K = K, power = pw, iterations = 250)
        @test fit isa GLLVM.TweedieGroupedFit
        @test fit.power_fixed
        ad = GLLVM._family_ci(fit, Y)
        @test length(ad.θ) == p + GLLVM.rr_theta_len(p, K) + p
        @test count(startswith("beta["), ad.names) == p
        @test count(startswith("phi["), ad.names) == p
        ci = confint(fit, Y; method = :wald, parm = "beta")
        @test length(ci.term) == p
        fin = isfinite.(ci.se)
        @test count(fin) ≥ 3
        @test all(ci.lower[fin] .< ci.estimate[fin] .< ci.upper[fin])
    end

    @testset "shared estimated power: power plug-in; φ still in θ" begin
        Random.seed!(183)
        p, K, n = 4, 1, 60
        β = 0.2 .* randn(p)
        Λ = 0.3 .* randn(p, K)
        φ = fill(0.9, p)
        pw = 1.45
        Z = randn(K, n)
        μ = exp.(β .+ Λ * Z)
        Y = zeros(p, n)
        for t in 1:p, s in 1:n
            Y[t, s] = GLLVM._tweedie_sample(μ[t, s], φ[t], pw, Random.default_rng())
        end
        fit = fit_tweedie_gllvm_grouped(Y; K = K, power_group = :shared, iterations = 200)
        @test fit isa GLLVM.TweedieGroupedFit
        @test !fit.power_fixed
        ad = GLLVM._family_ci(fit, Y)
        # CI profiles φ only; shared power is plug-in (same as TweedieFit)
        @test length(ad.θ) == p + GLLVM.rr_theta_len(p, K) + length(fit.φ)
        ci = confint(fit, Y; method = :wald, parm = "beta[1]")
        @test ci.term == ["beta[1]"]
        @test length(ad.θ) == GLLVM._nparams(fit) - 1  # minus free power coordinate
    end
end
