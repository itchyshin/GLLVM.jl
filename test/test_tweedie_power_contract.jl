using GLLVM, Test, Random

@testset "Tweedie power parameter contract" begin
    p, K = 3, 1
    rr = GLLVM.rr_theta_len(p, K)
    β = zeros(p)
    Λ = zeros(p, K)
    φ = ones(p)
    group = collect(1:p)

    @testset "three power spaces have explicit coordinate counts" begin
        fixed = GLLVM._tweedie_power_spec(1.5, :shared, p)
        shared = GLLVM._tweedie_power_spec(nothing, :shared, p)
        species = GLLVM._tweedie_power_spec(nothing, :species, p)
        @test fixed.fixed && fixed.nfree == 0 && fixed.values == fill(1.5, p)
        @test !shared.fixed && shared.nfree == 1 && shared.values == fill(1.5, p)
        @test !species.fixed && species.nfree == p && species.values == fill(1.5, p)
        @test_throws ArgumentError GLLVM._tweedie_power_spec(1.0, :shared, p)
        @test_throws ArgumentError GLLVM._tweedie_power_spec(nothing, :unknown, p)
        @test_throws ArgumentError GLLVM._tweedie_power_spec(1.5, :unknown, p)

        fixed_fit = GLLVM.TweedieGroupedFit(β, Λ, φ, 1.5, group, LogLink(),
                                             -1.0, true, 0, :observed, true)
        shared_fit = GLLVM.TweedieGroupedFit(β, Λ, φ, 1.5, group, LogLink(),
                                              -1.0, true, 0, :observed, false)
        species_fit = GLLVM.TweediePerTraitPowerFit(β, Λ, φ, fill(1.5, p), group,
                                                      LogLink(), -1.0, true, 0, :observed)
        @test GLLVM._nparams(fixed_fit) == p + rr + p
        @test GLLVM._nparams(shared_fit) == p + rr + p + 1
        @test GLLVM._nparams(species_fit) == p + rr + p + p
        @test GLLVM.StatsAPI.dof(species_fit) == p + rr + p + p
        @test GLLVM.StatsAPI.loglikelihood(species_fit) == -1.0
        @test GLLVM.StatsAPI.aic(species_fit) == 2 * (p + rr + p + p) + 2
        @test GLLVM.StatsAPI.bic(species_fit, 5) ≈
              (p + rr + p + p) * log(5) + 2
    end

    @testset "per-species likelihood reduces exactly at a common power" begin
        Random.seed!(82)
        n = 5
        Y = rand(p, n)
        scalar = GLLVM.tweedie_grouped_marginal_loglik_laplace(
            Y, Λ, β, φ, 1.5; hessian = :fisher)
        vector = GLLVM.tweedie_grouped_marginal_loglik_laplace(
            Y, Λ, β, φ, fill(1.5, p); hessian = :fisher)
        @test vector ≈ scalar atol = 1e-10

        mask = trues(p, n)
        mask[2, 3] = false
        Y_alt = copy(Y)
        Y_alt[2, 3] = 1e8
        masked = GLLVM.tweedie_grouped_marginal_loglik_laplace(
            Y, Λ, β, φ, fill(1.5, p); mask = mask, hessian = :fisher)
        masked_alt = GLLVM.tweedie_grouped_marginal_loglik_laplace(
            Y_alt, Λ, β, φ, fill(1.5, p); mask = mask, hessian = :fisher)
        @test masked_alt ≈ masked atol = 1e-10
    end

    @testset "fitter retains all three power model identities" begin
        Random.seed!(82)
        n = 12
        Y = [GLLVM._tweedie_sample(exp(0.15 * randn()), 1.0, 1.5,
                                   Random.default_rng()) for _ in 1:p, _ in 1:n]
        fixed = fit_tweedie_gllvm_grouped(Y; K = K, power = 1.5, iterations = 8,
                                           newton_maxiter = 20)
        shared = fit_tweedie_gllvm_grouped(Y; K = K, power_group = :shared,
                                            iterations = 8, newton_maxiter = 20)
        species = fit_tweedie_gllvm_grouped(Y; K = K, power_group = :species,
                                             iterations = 8, newton_maxiter = 20)
        @test fixed isa GLLVM.TweedieGroupedFit
        @test fixed.power_fixed
        @test GLLVM._nparams(fixed) == p + rr + p
        @test shared isa GLLVM.TweedieGroupedFit
        @test !shared.power_fixed
        @test GLLVM._nparams(shared) == p + rr + p + 1
        @test species isa GLLVM.TweediePerTraitPowerFit
        @test length(species.power) == p
        @test GLLVM._nparams(species) == p + rr + p + p

        mask = trues(p, n)
        mask[2, 4] = false
        Y_alt = copy(Y)
        Y_alt[2, 4] = 1e8
        fixed_masked = fit_tweedie_gllvm_grouped(
            Y; K = K, power = 1.5, mask = mask, iterations = 8, newton_maxiter = 20)
        fixed_masked_alt = fit_tweedie_gllvm_grouped(
            Y_alt; K = K, power = 1.5, mask = mask, iterations = 8, newton_maxiter = 20)
        @test fixed_masked_alt.loglik ≈ fixed_masked.loglik atol = 1e-10
    end
end
