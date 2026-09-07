using Test

if Base.find_package("StableRNGs") === nothing
    @testset "Destination B joint other families (StableRNGs unavailable)" begin
        @test_broken false
    end
else
    using GLLVM
    using LinearAlgebra
    using Random
    using StableRNGs

const _DESTINATION_B_JOINT_BINOMIAL_SEED = 20_260_907_6
const _DESTINATION_B_JOINT_BETA_SEED = 20_260_907_7
const _DESTINATION_B_JOINT_NB2_SEED = 20_260_907_8
const _DESTINATION_B_JOINT_SOURCES = (:unit, :unit_obs, :cluster, :cluster2)

function _destination_b_joint_other_geometry()
    nunit, per_unit = 12, 8
    n = nunit * per_unit
    unit = repeat(collect(1:nunit), inner = per_unit)
    unit_obs = repeat(collect(1:(nunit * 4)), inner = 2)
    cluster = repeat(collect(1:8), nunit)
    index = collect(0:(n - 1))
    cluster2 = mod1.(3 .* index .+ (index .÷ per_unit), 11)
    terms = [
        GLLVM.GroupingTerm(:unit; mode = :indep, common = true),
        GLLVM.GroupingTerm(:unit_obs; mode = :indep, common = true),
        GLLVM.GroupingTerm(:cluster; mode = :indep, common = true),
        GLLVM.GroupingTerm(:cluster2; mode = :indep, common = true),
    ]
    return (; p=2, n, unit, unit_obs, cluster, cluster2, terms)
end

function _destination_b_joint_other_eta(rng, geometry, mean_truth, scales)
    U = scales.unit .* randn(rng, geometry.p, 12)
    O = scales.unit_obs .* randn(rng, geometry.p, 48)
    C = scales.cluster .* randn(rng, geometry.p, 8)
    D = scales.cluster2 .* randn(rng, geometry.p, 11)
    eta = Matrix{Float64}(undef, geometry.p, geometry.n)
    for observation in 1:geometry.n, trait in 1:geometry.p
        eta[trait, observation] = mean_truth[trait] +
            U[trait, geometry.unit[observation]] +
            O[trait, geometry.unit_obs[observation]] +
            C[trait, geometry.cluster[observation]] +
            D[trait, geometry.cluster2[observation]]
    end
    return eta
end

function _destination_b_joint_binomial_fixture()
    geometry = _destination_b_joint_other_geometry()
    rng = StableRNG(_DESTINATION_B_JOINT_BINOMIAL_SEED)
    mean_truth = [-0.30, 0.45]
    scales = (unit=0.52, unit_obs=0.40, cluster=0.30, cluster2=0.25)
    eta = _destination_b_joint_other_eta(rng, geometry, mean_truth, scales)
    trials = fill(20, geometry.p, geometry.n)
    Y = Matrix{Int}(undef, geometry.p, geometry.n)
    for observation in 1:geometry.n, trait in 1:geometry.p
        probability = inv(1 + exp(-eta[trait, observation]))
        Y[trait, observation] = rand(rng, GLLVM.Binomial(trials[trait, observation], probability))
    end
    return (; geometry..., Y, trials, mean_truth, scales)
end

function _destination_b_joint_beta_fixture()
    geometry = _destination_b_joint_other_geometry()
    rng = StableRNG(_DESTINATION_B_JOINT_BETA_SEED)
    mean_truth = [-0.45, 0.25]
    scales = (unit=0.36, unit_obs=0.28, cluster=0.22, cluster2=0.18)
    precision_truth = [12.0, 18.0]
    eta = _destination_b_joint_other_eta(rng, geometry, mean_truth, scales)
    Y = Matrix{Float64}(undef, geometry.p, geometry.n)
    for observation in 1:geometry.n, trait in 1:geometry.p
        mean_value = inv(1 + exp(-eta[trait, observation]))
        phi = precision_truth[trait]
        Y[trait, observation] = rand(rng, GLLVM.Beta(mean_value * phi, (1 - mean_value) * phi))
    end
    return (; geometry..., Y, mean_truth, scales, precision_truth)
end

function _destination_b_joint_nb2_fixture()
    geometry = _destination_b_joint_other_geometry()
    rng = StableRNG(_DESTINATION_B_JOINT_NB2_SEED)
    mean_truth = [0.70, 1.00]
    scales = (unit=0.38, unit_obs=0.30, cluster=0.24, cluster2=0.20)
    size_truth = [1.5, 2.5]
    eta = _destination_b_joint_other_eta(rng, geometry, mean_truth, scales)
    Y = Matrix{Int}(undef, geometry.p, geometry.n)
    for observation in 1:geometry.n, trait in 1:geometry.p
        size_value = size_truth[trait]
        mean_value = exp(eta[trait, observation])
        Y[trait, observation] = rand(rng, GLLVM.NegativeBinomial(
            size_value, size_value / (size_value + mean_value)))
    end
    return (; geometry..., Y, mean_truth, scales, size_truth)
end

function _assert_destination_b_joint_other_result(fit, intervals;
        require_source_intervals::Bool=true)
    @test fit isa GLLVM.GroupedNonGaussianFit
    @test fit.converged
    @test fit.stopping_reason === :converged
    @test fit.inner_status === :ok
    @test isfinite(fit.loglik) && isfinite(fit.gradient_norm)
    @test fit.gradient_norm <= 1e-4
    @test fit.hessian_positive_definite
    @test getfield.(fit.terms, :name) == collect(_DESTINATION_B_JOINT_SOURCES)
    for (term_index, source) in enumerate(_DESTINATION_B_JOINT_SOURCES)
        Sigma = GLLVM.extract_Sigma(fit; level = source).Sigma
        @test Sigma == fit.term_covariances[term_index]
        @test all(isfinite, Sigma) && all(diag(Sigma) .>= 0.0)
        @test Sigma ≈ Diagonal(diag(Sigma)) atol = 1e-12
        @test diag(Sigma)[1] ≈ diag(Sigma)[2] atol = 1e-12
        if require_source_intervals
            @test all(diag(Sigma) .> 1e-4)
            for trait in 1:2
                interval = only(filter(x -> x.name == "$(source).variance[$trait]", intervals.intervals))
                @test interval.status === :available
                @test isfinite(interval.lower) && isfinite(interval.upper)
                @test interval.lower < interval.estimate < interval.upper
            end
        end
    end
    if require_source_intervals
        @test intervals.status === :available
        @test intervals.covariance !== nothing
    end
end

@testset "Destination B joint Binomial-logit public fit" begin
    fixture = _destination_b_joint_binomial_fixture()
    @test size(fixture.Y) == (2, 96)
    @test all(0 .<= fixture.Y .<= fixture.trials)
    @test all(GLLVM._grouping_term_nparams(term, 2) == 1 for term in fixture.terms)
    elapsed = @elapsed begin
        fit = fit_gllvm(fixture.Y; family=GLLVM.Binomial(), N=fixture.trials,
            grouping=fixture.terms, unit=fixture.unit, unit_obs=fixture.unit_obs,
            cluster=fixture.cluster, cluster2=fixture.cluster2,
            iterations=250, g_tol=1e-4)
        intervals = GLLVM.grouped_nongaussian_intervals(fixture.Y, fit; N=fixture.trials,
            unit=fixture.unit, unit_obs=fixture.unit_obs,
            cluster=fixture.cluster, cluster2=fixture.cluster2)
        _assert_destination_b_joint_other_result(fit, intervals)
    end
    @info "Destination B joint Binomial-logit result" elapsed
    @test elapsed < 120.0
end

@testset "Destination B joint Beta-logit public fit" begin
    fixture = _destination_b_joint_beta_fixture()
    @test size(fixture.Y) == (2, 96)
    @test all(0 .< fixture.Y .< 1)
    elapsed = @elapsed begin
        fit = fit_gllvm(fixture.Y; family=GLLVM.Beta(12.0, 1.0),
            grouping=fixture.terms, unit=fixture.unit, unit_obs=fixture.unit_obs,
            cluster=fixture.cluster, cluster2=fixture.cluster2,
            iterations=250, g_tol=1e-4)
        intervals = GLLVM.grouped_nongaussian_intervals(fixture.Y, fit;
            unit=fixture.unit, unit_obs=fixture.unit_obs,
            cluster=fixture.cluster, cluster2=fixture.cluster2)
        _assert_destination_b_joint_other_result(fit, intervals)
        @test fit.dispersion_mode === :trait
        @test fit.dispersion isa Vector{Float64} && length(fit.dispersion) == 2
        for trait in 1:2
            interval = only(filter(x -> x.name == "beta_precision[$trait]", intervals.intervals))
            @test interval.status === :available
            @test interval.lower < interval.estimate < interval.upper
        end
    end
    @info "Destination B joint Beta-logit result" elapsed
    @test elapsed < 120.0
end

@testset "Destination B joint NB2-log public fit" begin
    fixture = _destination_b_joint_nb2_fixture()
    @test size(fixture.Y) == (2, 96)
    @test all(>=(0), fixture.Y)
    elapsed = @elapsed begin
        fit = fit_gllvm(fixture.Y; family=GLLVM.NegativeBinomial(1.5, 0.5),
            grouping=fixture.terms, unit=fixture.unit, unit_obs=fixture.unit_obs,
            cluster=fixture.cluster, cluster2=fixture.cluster2,
            iterations=250, g_tol=1e-4)
        intervals = GLLVM.grouped_nongaussian_intervals(fixture.Y, fit;
            unit=fixture.unit, unit_obs=fixture.unit_obs,
            cluster=fixture.cluster, cluster2=fixture.cluster2)
        _assert_destination_b_joint_other_result(fit, intervals;
            require_source_intervals=false)
        @test fit.dispersion_mode === :trait
        @test fit.dispersion isa Vector{Float64} && length(fit.dispersion) == 2
        fitted = Dict(source => GLLVM.extract_Sigma(fit; level = source).Sigma[1, 1]
            for source in _DESTINATION_B_JOINT_SOURCES)
        @test fitted[:unit] > 1e-4
        @test fitted[:unit_obs] < 1e-4
        @test fitted[:cluster] < 1e-4
        @test fitted[:cluster2] > 1e-4
        @test intervals.status === :partial
        @test intervals.covariance !== nothing
        for source in (:unit_obs, :cluster), trait in 1:2
            interval = only(filter(x -> x.name == "$(source).variance[$trait]", intervals.intervals))
            @test interval.status === :target_unavailable
            @test isnan(interval.lower) && isnan(interval.upper)
        end
        for source in (:unit, :cluster2), trait in 1:2
            interval = only(filter(x -> x.name == "$(source).variance[$trait]", intervals.intervals))
            @test interval.status === :available
            @test interval.lower < interval.estimate < interval.upper
        end
        for trait in 1:2
            interval = only(filter(x -> x.name == "nb2_size[$trait]", intervals.intervals))
            @test interval.status === :available
            @test interval.lower < interval.estimate < interval.upper
        end
    end
    @info "Destination B joint NB2-log result" elapsed
    @test elapsed < 120.0
end

end # StableRNGs available
