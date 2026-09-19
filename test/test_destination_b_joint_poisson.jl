using Test

# StableRNGs is intentionally a quality-environment dependency rather than a
# GLLVModels core dependency. Its absence is visible and cannot count as a fitted
# integration result.
if Base.find_package("StableRNGs") === nothing
    @testset "Destination B joint Poisson (StableRNGs unavailable)" begin
        @test_broken false
    end
else
    using GLLVModels
    using LinearAlgebra
    using Random
    using StableRNGs

const _DESTINATION_B_JOINT_POISSON_SEED = 20_260_907_5

function _destination_b_joint_poisson_fixture()
    rng = StableRNG(_DESTINATION_B_JOINT_POISSON_SEED)
    p = 2
    nunit, per_unit = 12, 8
    n = nunit * per_unit
    unit = repeat(collect(1:nunit), inner = per_unit)
    # Four globally unique, twice-replicated levels within every unit.
    unit_obs = repeat(collect(1:(nunit * 4)), inner = 2)
    # Both crossed sources vary within every unit and have distinct level maps.
    cluster = repeat(collect(1:8), nunit)
    index = collect(0:(n - 1))
    cluster2 = mod1.(3 .* index .+ (index .÷ per_unit), 11)

    mean_truth = [0.75, 1.05]
    scales = (unit = 0.48, unit_obs = 0.38, cluster = 0.30, cluster2 = 0.26)
    draw(sd, levels) = sd .* randn(rng, p, levels)
    U = draw(scales.unit, nunit)
    O = draw(scales.unit_obs, nunit * 4)
    C = draw(scales.cluster, 8)
    D = draw(scales.cluster2, 11)

    Y = Matrix{Int}(undef, p, n)
    for observation in 1:n, trait in 1:p
        eta = mean_truth[trait] + U[trait, unit[observation]] +
            O[trait, unit_obs[observation]] + C[trait, cluster[observation]] +
            D[trait, cluster2[observation]]
        Y[trait, observation] = rand(rng, GLLVModels.Poisson(exp(eta)))
    end
    terms = [
        GLLVModels.GroupingTerm(:unit; mode = :indep, common = true),
        GLLVModels.GroupingTerm(:unit_obs; mode = :indep, common = true),
        GLLVModels.GroupingTerm(:cluster; mode = :indep, common = true),
        GLLVModels.GroupingTerm(:cluster2; mode = :indep, common = true),
    ]
    return (; Y, terms, unit, unit_obs, cluster, cluster2, mean_truth, scales)
end

@testset "Destination B joint four-source Poisson public fit" begin
    fixture = _destination_b_joint_poisson_fixture()
    @test size(fixture.Y) == (2, 96)
    @test all(isfinite, fixture.Y) && all(>=(0), fixture.Y)
    @test all(GLLVModels._grouping_term_nparams(term, 2) == 1 for term in fixture.terms)
    @test sum(GLLVModels._grouping_term_nparams(term, 2) for term in fixture.terms) + 2 == 6
    @test all(all(fixture.unit_obs[8 * unit_index - 7:8 * unit_index] .==
        repeat(4 * (unit_index - 1) .+ (1:4), inner = 2)) for unit_index in 1:12)
    @test all(length(unique(fixture.cluster[findall(==(unit_index), fixture.unit)])) == 8
        for unit_index in 1:12)
    @test length(unique(fixture.cluster2)) == 11
    @test fixture.cluster != fixture.cluster2

    fit = fit_gllvm(fixture.Y; family = GLLVModels.Poisson(), grouping = fixture.terms,
        unit = fixture.unit, unit_obs = fixture.unit_obs,
        cluster = fixture.cluster, cluster2 = fixture.cluster2,
        iterations = 250, g_tol = 1e-4)

    @test fit isa GLLVModels.GroupedNonGaussianFit
    @test fit.converged
    @test fit.stopping_reason === :converged
    @test fit.inner_status === :ok
    @test isfinite(fit.loglik) && isfinite(fit.gradient_norm)
    @test fit.gradient_norm <= 1e-4
    @test fit.hessian_positive_definite
    @test getfield.(fit.terms, :name) == [:unit, :unit_obs, :cluster, :cluster2]

    for term in fixture.terms
        Sigma = GLLVModels.extract_Sigma(fit; level = term.name).Sigma
        @test Sigma == fit.term_covariances[findfirst(==(term.name), getfield.(fit.terms, :name))]
        @test all(isfinite, Sigma) && all(diag(Sigma) .> 1e-4)
        @test Sigma ≈ Diagonal(diag(Sigma)) atol = 1e-12
        @test diag(Sigma)[1] ≈ diag(Sigma)[2] atol = 1e-12
    end

    intervals = GLLVModels.grouped_nongaussian_intervals(fixture.Y, fit;
        unit = fixture.unit, unit_obs = fixture.unit_obs,
        cluster = fixture.cluster, cluster2 = fixture.cluster2)
    @test intervals.status === :available
    @test intervals.covariance !== nothing
    for name in ("unit.variance[1]", "unit_obs.variance[1]",
                 "cluster.variance[1]", "cluster2.variance[1]")
        interval = only(filter(x -> x.name == name, intervals.intervals))
        @test interval.status === :available
        @test isfinite(interval.lower) && isfinite(interval.upper)
        @test interval.lower < interval.estimate < interval.upper
    end
end

end # StableRNGs available
