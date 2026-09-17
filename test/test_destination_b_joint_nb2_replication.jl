using Test

if Base.find_package("StableRNGs") === nothing
    @testset "Destination B joint NB2 replication (StableRNGs unavailable)" begin
        @test_broken false
    end
else
    using GLLVModels
    using LinearAlgebra
    using Random
    using SHA
    using StableRNGs

const _DESTINATION_B_JOINT_NB2_REPLICATION_SEED = 20_260_907_8
const _DESTINATION_B_JOINT_NB2_PREFIX_SHA256 =
    "5035068e1990ae61f4e43fef410837d450ab78aaad6fc0f80f371332880fe8f0"

# Provenance: copied directly from the original NB2 fixture in
# test_destination_b_joint_other_families.jl. It intentionally does not
# include that file, so the original prefix remains independently testable.
function _destination_b_joint_nb2_replication_fixture()
    rng = StableRNG(_DESTINATION_B_JOINT_NB2_REPLICATION_SEED)
    p = 2
    nunit, per_unit = 12, 8
    nblock = nunit * per_unit
    unit = repeat(collect(1:nunit), inner = per_unit)
    unit_obs = repeat(collect(1:(nunit * 4)), inner = 2)
    cluster = repeat(collect(1:8), nunit)
    index = collect(0:(nblock - 1))
    cluster2 = mod1.(3 .* index .+ (index .÷ per_unit), 11)
    mean_truth = [0.70, 1.00]
    scales = (unit=0.38, unit_obs=0.30, cluster=0.24, cluster2=0.20)
    size_truth = [1.5, 2.5]
    U = scales.unit .* randn(rng, p, nunit)
    O = scales.unit_obs .* randn(rng, p, nunit * 4)
    C = scales.cluster .* randn(rng, p, 8)
    D = scales.cluster2 .* randn(rng, p, 11)
    eta = Matrix{Float64}(undef, p, nblock)
    for observation in 1:nblock, trait in 1:p
        eta[trait, observation] = mean_truth[trait] +
            U[trait, unit[observation]] + O[trait, unit_obs[observation]] +
            C[trait, cluster[observation]] + D[trait, cluster2[observation]]
    end

    draw_block() = begin
        response = Matrix{Int}(undef, p, nblock)
        for observation in 1:nblock, trait in 1:p
            size_value = size_truth[trait]
            mean_value = exp(eta[trait, observation])
            response[trait, observation] = rand(rng, GLLVModels.NegativeBinomial(
                size_value, size_value / (size_value + mean_value)))
        end
        response
    end
    original = draw_block()
    response = hcat(original, draw_block(), draw_block(), draw_block())
    terms = [
        GLLVModels.GroupingTerm(:unit; mode = :indep, common = true),
        GLLVModels.GroupingTerm(:unit_obs; mode = :indep, common = true),
        GLLVModels.GroupingTerm(:cluster; mode = :indep, common = true),
        GLLVModels.GroupingTerm(:cluster2; mode = :indep, common = true),
    ]
    return (; original, response, terms,
        unit=repeat(unit, 4), unit_obs=repeat(unit_obs, 4),
        cluster=repeat(cluster, 4), cluster2=repeat(cluster2, 4),
        mean_truth, scales, size_truth)
end

@testset "Destination B joint NB2 conditional replication diagnostic" begin
    fixture = _destination_b_joint_nb2_replication_fixture()
    @test size(fixture.original) == (2, 96)
    @test size(fixture.response) == (2, 384)
    @test fixture.response[:, 1:96] == fixture.original
    @test bytes2hex(sha256(join(vec(fixture.original), ","))) ==
        _DESTINATION_B_JOINT_NB2_PREFIX_SHA256
    @test fixture.unit[1:96] == fixture.unit[97:192] == fixture.unit[193:288] == fixture.unit[289:384]
    @test fixture.unit_obs[1:96] == fixture.unit_obs[97:192] == fixture.unit_obs[193:288] == fixture.unit_obs[289:384]
    @test all(count(==(level), fixture.unit_obs) == 8 for level in 1:48)
    @test all(GLLVModels._grouping_term_nparams(term, 2) == 1 for term in fixture.terms)

    elapsed = @elapsed begin
        fit = fit_gllvm(fixture.response;
            family=GLLVModels.NegativeBinomial(1.5, 0.5), grouping=fixture.terms,
            unit=fixture.unit, unit_obs=fixture.unit_obs,
            cluster=fixture.cluster, cluster2=fixture.cluster2,
            iterations=250, g_tol=1e-4)
        intervals = GLLVModels.grouped_nongaussian_intervals(fixture.response, fit;
            unit=fixture.unit, unit_obs=fixture.unit_obs,
            cluster=fixture.cluster, cluster2=fixture.cluster2)
        @test fit isa GLLVModels.GroupedNonGaussianFit
        @test fit.converged
        @test fit.stopping_reason === :converged
        @test fit.inner_status === :ok
        @test fit.hessian_positive_definite
        @test isfinite(fit.loglik) && isfinite(fit.gradient_norm)
        @test fit.gradient_norm <= 1e-4
        @test fit.dispersion_mode === :trait
        @test fit.dispersion isa Vector{Float64} && length(fit.dispersion) == 2
        @test getfield.(fit.terms, :name) == [:unit, :unit_obs, :cluster, :cluster2]
        for (term_index, source) in enumerate((:unit, :unit_obs, :cluster, :cluster2))
            Sigma = GLLVModels.extract_Sigma(fit; level=source).Sigma
            @test Sigma == fit.term_covariances[term_index]
            @test all(isfinite, Sigma) && all(diag(Sigma) .> 1e-4)
            @test Sigma ≈ Diagonal(diag(Sigma)) atol=1e-12
            for trait in 1:2
                interval = only(filter(x -> x.name == "$(source).variance[$trait]", intervals.intervals))
                @test interval.status === :available
                @test isfinite(interval.lower) && isfinite(interval.upper)
                @test interval.lower < interval.estimate < interval.upper
            end
        end
        @test intervals.status === :available
        @test intervals.covariance !== nothing
        for trait in 1:2
            interval = only(filter(x -> x.name == "nb2_size[$trait]", intervals.intervals))
            @test interval.status === :available
            @test interval.lower < interval.estimate < interval.upper
        end
    end
    @info "Destination B joint NB2 conditional replication result" elapsed
    @test elapsed < 120.0
end

end # StableRNGs available
