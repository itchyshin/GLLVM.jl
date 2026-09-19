using Test
using GLLVModels
using LinearAlgebra
using SparseArrays

_gnp_logistic(x) = inv(1.0 + exp(-x))

function _gnp_design(p::Int, n::Int)
    D = zeros(p * n, p)
    for observation in 1:n, trait in 1:p
        D[(observation - 1) * p + trait, trait] = 1.0
    end
    D
end

function _gnp_fixture(kind::Symbol)
    p, n = 2, 3
    D = _gnp_design(p, n)
    beta = [log(2.0), log(3.0)]
    term = GroupingTerm(:unit; mode = :indep)
    covariance = Matrix(Diagonal([0.25, 0.36]))
    trials = [5.0 10.0 2.0; 4.0 3.0 6.0]
    response = [1.0 2.0 1.0; 2.0 1.0 4.0]
    family, dispersion = if kind === :poisson
        GLLVModels.Poisson(), nothing
    elseif kind === :binomial
        GLLVModels.Binomial(), nothing
    elseif kind === :beta
        GLLVModels.Beta(4.0, 1.0), 4.0
    elseif kind === :nb2
        GLLVModels.NegativeBinomial(3.0, 0.5), 3.0
    else
        error("unsupported fixture kind")
    end
    parameters = [beta; log(0.5); log(0.6); kind in (:beta, :nb2) ? log(dispersion) : Float64[]]
    labels = ["trait1", "trait2", "unit.log_sd[1]", "unit.log_sd[2]"]
    kind === :beta && push!(labels, "log_phi")
    kind === :nb2 && push!(labels, "log_r")
    return GroupedNonGaussianFit(beta, family, dispersion, [covariance], [term], parameters,
        -12.5, true, 1e-8, 0.25, true, 7, :converged, D,
        Union{String,Symbol}["trait1", "trait2"], labels, (p, n), response, trials,
        [sparse(collect(1:n), collect(1:n), ones(n), n, n)], kind,
        kind in (:beta, :nb2) ? :shared : :none, :ok)
end

@testset "Grouped non-Gaussian postfit" begin
    @testset "zero-random-effect link and response means" begin
        for kind in (:poisson, :binomial, :beta, :nb2)
            fit = _gnp_fixture(kind)
            eta = reshape(fit.mean_design * fit.beta, 2, 3)
            expected = kind in (:poisson, :nb2) ? exp.(eta) :
                kind === :binomial ? fit.trials .* _gnp_logistic.(eta) :
                _gnp_logistic.(eta)
            @test GLLVModels.predict(fit; type = :link) == eta
            @test GLLVModels.predict(fit; type = :response) == expected
            @test GLLVModels.predict(fit; type = :mean) == expected
            @test GLLVModels.fitted(fit) == expected
            @test GLLVModels.residuals(fit) == fit.response .- expected
        end
    end

    @testset "standard extractors and covariance parts" begin
        fit = _gnp_fixture(:poisson)
        @test GLLVModels.coef(fit) == fit.beta
        @test GLLVModels.loglikelihood(fit) == -12.5
        @test GLLVModels.nobs(fit) == 6
        @test GLLVModels.dof(fit) == length(fit.parameters)
        total = GLLVModels.extract_Sigma(fit; level = :unit)
        @test total.Sigma == fit.term_covariances[1]
        @test GLLVModels.extract_Sigma(fit; level = :unit, part = :shared).Sigma == zeros(2, 2)
        @test GLLVModels.extract_Sigma(fit; level = :unit, part = :unique).s == [0.25, 0.36]
        @test_throws ArgumentError GLLVModels.extract_Sigma(fit; level = :residual)
        shown = sprint(show, MIME"text/plain"(), fit)
        @test occursin("convergence = true", shown)
        @test occursin("observed curvature PD = true", shown)
    end

    @testset "Binomial new-design trials are explicit" begin
        fit = _gnp_fixture(:binomial)
        new_design = _gnp_design(2, 4)
        new_trials = [4.0 5.0 6.0 7.0; 2.0 3.0 4.0 5.0]
        expected = new_trials .* _gnp_logistic.(reshape(new_design * fit.beta, 2, 4))
        @test_throws ArgumentError GLLVModels.predict(fit, new_design)
        @test GLLVModels.predict(fit, new_design; N = new_trials) == expected
        @test_throws DimensionMismatch GLLVModels.predict(fit, new_design; N = ones(2, 3))
        @test_throws ArgumentError GLLVModels.predict(fit, new_design; N = fill(1.5, 2, 4))
        @test_throws ArgumentError GLLVModels.predict(_gnp_fixture(:poisson), new_design; N = new_trials)
    end

    @testset "nonfinite predictor and response means diagnose" begin
        fit = _gnp_fixture(:poisson)
        nonfinite_eta_design = fill(1e308, 2, 2)
        response_overflow_design = 2_000.0 .* _gnp_design(2, 1)
        @test_throws ArgumentError GLLVModels.predict(fit, nonfinite_eta_design)
        @test_throws ArgumentError GLLVModels.predict(fit, response_overflow_design)
        # Logistic endpoints remain valid zero-effect conditional means.
        binomial = _gnp_fixture(:binomial)
        extreme_design = [2_000.0 0.0; 0.0 -2_000.0]
        extreme = GLLVModels.predict(binomial, extreme_design; N = reshape([5.0, 7.0], 2, 1))
        @test extreme == reshape([5.0, 0.0], 2, 1)
    end
end
