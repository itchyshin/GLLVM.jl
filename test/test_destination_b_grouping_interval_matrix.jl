using Test
using GLLVM
using LinearAlgebra
using Random

const _DBIM_SOURCES = (:unit, :unit_obs, :cluster, :cluster2)
const _DBIM_SEEDS = Dict(
    :gaussian => 6_101,
    :poisson => 6_102,
    :binomial => 6_103,
    :beta => 6_104,
    :nb2 => 6_105,
)

function _dbim_geometry()
    p, n = 2, 96
    unit = repeat(1:12; inner = 8)
    unit_obs = repeat(1:48; inner = 2)
    cluster = repeat(1:8, 12)
    observation = 0:(n - 1)
    cluster2 = mod1.(3 .* observation .+ (observation .÷ 8), 11)
    terms = [GroupingTerm(source; mode = :indep, common = true)
        for source in _DBIM_SOURCES]
    return (; p, n, unit, unit_obs, cluster, cluster2, terms)
end

function _dbim_fixture(kind::Symbol)
    geometry = _dbim_geometry()
    rng = MersenneTwister(_DBIM_SEEDS[kind])
    unit_effect = 0.55 .* randn(rng, geometry.p, 12)
    unit_obs_effect = 0.40 .* randn(rng, geometry.p, 48)
    cluster_effect = 0.35 .* randn(rng, geometry.p, 8)
    cluster2_effect = 0.30 .* randn(rng, geometry.p, 11)
    intercept = kind === :gaussian ? 0.20 : kind === :poisson ? 0.70 :
        kind === :binomial ? -0.25 : kind === :beta ? -0.35 : 0.80
    eta = Matrix{Float64}(undef, geometry.p, geometry.n)
    for observation in 1:geometry.n, trait in 1:geometry.p
        eta[trait, observation] = intercept +
            unit_effect[trait, geometry.unit[observation]] +
            unit_obs_effect[trait, geometry.unit_obs[observation]] +
            cluster_effect[trait, geometry.cluster[observation]] +
            cluster2_effect[trait, geometry.cluster2[observation]]
    end
    if kind === :gaussian
        return (; geometry..., family = GLLVM.Normal(),
            Y = eta .+ 0.40 .* randn(rng, geometry.p, geometry.n), N = nothing)
    elseif kind === :poisson
        Y = [rand(rng, GLLVM.Poisson(exp(eta[trait, observation])))
            for trait in 1:geometry.p, observation in 1:geometry.n]
        return (; geometry..., family = GLLVM.Poisson(), Y, N = nothing)
    elseif kind === :binomial
        N = fill(24, geometry.p, geometry.n)
        Y = [rand(rng, GLLVM.Binomial(N[trait, observation],
            inv(1 + exp(-eta[trait, observation]))))
            for trait in 1:geometry.p, observation in 1:geometry.n]
        return (; geometry..., family = GLLVM.Binomial(), Y, N)
    elseif kind === :beta
        Y = [begin
                mean_value = inv(1 + exp(-eta[trait, observation]))
                rand(rng, GLLVM.Beta(14 * mean_value, 14 * (1 - mean_value)))
            end for trait in 1:geometry.p, observation in 1:geometry.n]
        return (; geometry..., family = GLLVM.Beta(14.0, 1.0), Y, N = nothing)
    elseif kind === :nb2
        Y = [begin
                mean_value = exp(eta[trait, observation])
                rand(rng, GLLVM.NegativeBinomial(2.5, 2.5 / (2.5 + mean_value)))
            end for trait in 1:geometry.p, observation in 1:geometry.n]
        return (; geometry..., family = GLLVM.NegativeBinomial(2.5, 0.5),
            Y, N = nothing)
    end
    error("unsupported interval-matrix family: $kind")
end

function _dbim_fit(fixture; iterations = 250)
    kwargs = fixture.N === nothing ? (; ) : (; N = fixture.N)
    return fit_gllvm(fixture.Y; family = fixture.family, grouping = fixture.terms,
        unit = fixture.unit, unit_obs = fixture.unit_obs,
        cluster = fixture.cluster, cluster2 = fixture.cluster2,
        iterations, g_tol = 1e-4, kwargs...)
end

function _dbim_intervals(fixture, fit)
    kwargs = fixture.N === nothing ? (; ) : (; N = fixture.N)
    return fixture.family isa GLLVM.Normal ?
        grouped_gaussian_intervals(fixture.Y, fit;
            unit = fixture.unit, unit_obs = fixture.unit_obs,
            cluster = fixture.cluster, cluster2 = fixture.cluster2) :
        grouped_nongaussian_intervals(fixture.Y, fit;
            unit = fixture.unit, unit_obs = fixture.unit_obs,
            cluster = fixture.cluster, cluster2 = fixture.cluster2, kwargs...)
end

function _dbim_objective(fit)
    if fit isa GLLVM.GroupedGaussianFit
        return GLLVM._grouped_gaussian_objective(fit.response, fit.mean_design,
            fit.terms, fit.incidences)
    end
    return GLLVM._grouped_nongaussian_objective(fit.response, fit.trials,
        fit.mean_design, fit.terms, fit.incidences, fit.family_kind;
        dispersion_mode = fit.dispersion_mode,
        inner_maxiter = 100, inner_tol = 1e-8)
end

function _dbim_source_interval_rows(intervals, source)
    return filter(row -> startswith(row.name, "$(source).variance["), intervals.intervals)
end

@testset "Destination B deterministic four-source interval-feasibility matrix" begin
    for kind in (:gaussian, :poisson, :binomial, :beta, :nb2)
        @testset "$kind public joint route" begin
            fixture = _dbim_fixture(kind)
            @test size(fixture.Y) == (fixture.p, fixture.n)
            @test all(count(==(level), fixture.unit_obs) == 2 for level in unique(fixture.unit_obs))
            @test fixture.cluster != fixture.cluster2

            fit = _dbim_fit(fixture)
            @test fit.converged
            @test fit.stopping_reason === :converged
            @test isfinite(fit.loglik) && isfinite(fit.gradient_norm)
            @test fit.hessian_positive_definite
            !(fit isa GLLVM.GroupedGaussianFit) && @test fit.inner_status === :ok
            @test getfield.(fit.terms, :name) == collect(_DBIM_SOURCES)
            @test length(fit.term_covariances) == length(_DBIM_SOURCES)
            @test rank(fit.mean_design) == size(fit.mean_design, 2)

            incidence_grams = [Matrix(incidence * incidence') for incidence in fit.incidences]
            for right in 2:length(incidence_grams), left in 1:(right - 1)
                @test norm(incidence_grams[left] - incidence_grams[right]) > 1e-6
            end
            @test rank(hcat(vec.(incidence_grams)...)) == length(_DBIM_SOURCES)

            objective = _dbim_objective(fit)
            baseline = objective(fit.parameters)
            @test isfinite(baseline)
            for source_index in eachindex(_DBIM_SOURCES)
                perturbed = copy(fit.parameters)
                # Fixed positive log-SD displacement: every selected source
                # must affect the joint marginal objective appreciably.
                perturbed[fixture.p + source_index] += log(1.1)
                effect_size = abs(objective(perturbed) - baseline)
                @test isfinite(effect_size) && effect_size > 1e-6
            end

            intervals = _dbim_intervals(fixture, fit)
            @test intervals.status === :available
            @test intervals.covariance !== nothing
            for source in _DBIM_SOURCES
                rows = _dbim_source_interval_rows(intervals, source)
                @test length(rows) == fixture.p
                @test all(row -> row.status === :available, rows)
                @test all(row -> isfinite(row.lower) && isfinite(row.upper) &&
                    row.lower < row.estimate < row.upper, rows)
            end
        end
    end

    # Labels cannot silently add random-effect sources. The public API must
    # reject the first unused label and name the required explicit term.
    fixture = _dbim_fixture(:gaussian)
    unit_only = merge(fixture, (; terms = [first(fixture.terms)]))
    unused_label_error = try
        fit_gllvm(unit_only.Y; family = unit_only.family,
            grouping = unit_only.terms, unit = unit_only.unit,
            unit_obs = unit_only.unit_obs, iterations = 0)
        nothing
    catch error
        error
    end
    @test unused_label_error isa ArgumentError
    @test unused_label_error.msg ==
        "unit_obs labels do not add a random term; select GroupingTerm(:unit_obs, ...) explicitly"

    # Altering the sharing map for an active source changes the four-source
    # public route even with the optimizer deliberately held at its start.
    changed_cluster2 = copy(fixture.cluster2)
    changed_cluster2[1], changed_cluster2[2] = changed_cluster2[2], changed_cluster2[1]
    baseline = _dbim_fit(fixture; iterations = 0)
    altered = _dbim_fit(merge(fixture, (; cluster2 = changed_cluster2)); iterations = 0)
    @test sort(changed_cluster2) == sort(fixture.cluster2)
    @test changed_cluster2 != fixture.cluster2
    @test abs(baseline.loglik - altered.loglik) > 1e-6
end
