using Test

# QuadGK is a direct dependency of the isolated numerical-quality environment,
# rather than of GLLVModels's lean core project. Its absence in a bare core run is
# intentionally visible as a skip: it is never interpreted as an oracle pass.
if Base.find_package("QuadGK") === nothing
    @testset "Destination B scalar quadrature (QuadGK unavailable)" begin
        @test_skip false
    end
else
    using GLLVModels
    using Distributions
    using QuadGK
    using SparseArrays

    _logistic(eta::Float64) = inv(1.0 + exp(-eta))

    # Outside this machine-safe predictor band the standard-Normal tail is
    # negligible for these fixed interior fixtures; returning zero avoids
    # invalid distribution constructors after floating-point link saturation.
    function _conditional_logpdf(density, eta::Float64, i::Int, y::Float64)
        (!isfinite(eta) || abs(eta) > 30.0) && return -Inf
        return logpdf(density(eta, i), y)
    end

    "Independent scalar log-integral for one shared standard-Normal effect."
    function _scalar_logmarginal(density, beta::Float64, y::Vector{Float64})
        logkernel(b) = sum(_conditional_logpdf(density, beta + b, i, y[i]) for i in eachindex(y)) +
                       logpdf(Normal(), b)
        reference = logkernel(0.0)
        value, _ = quadgk(b -> exp(logkernel(b) - reference), -Inf, Inf;
                           rtol = 1e-12, atol = 1e-13)
        return log(value) + reference
    end

    const _QUADRATURE_CASES = (
        (
            label = :poisson,
            family = Poisson(),
            link = LogLink(),
            beta = log(3.0),
            y = Float64[2, 4, 3, 5, 2, 3, 4, 3],
            trials = ones(8),
            density = (eta, _) -> Poisson(exp(eta)),
        ),
        (
            label = :binomial,
            family = Binomial(),
            link = LogitLink(),
            beta = -0.2,
            y = Float64[3, 4, 5, 2, 4, 3, 4, 5],
            trials = fill(8.0, 8),
            density = (eta, _) -> Binomial(8, _logistic(eta)),
        ),
        (
            label = :beta,
            family = Beta(20.0, 1.0),
            link = LogitLink(),
            beta = 0.15,
            y = Float64[0.46, 0.55, 0.52, 0.49, 0.58, 0.50, 0.53, 0.47],
            trials = ones(8),
            density = (eta, _) -> begin
                mu = _logistic(eta)
                Beta(20.0 * mu, 20.0 * (1.0 - mu))
            end,
        ),
        (
            label = :nb2,
            family = NegativeBinomial(8.0, 0.5),
            link = LogLink(),
            beta = log(3.0),
            y = Float64[2, 5, 3, 4, 2, 3, 5, 4],
            trials = ones(8),
            density = (eta, _) -> NegativeBinomial(8.0, 8.0 / (8.0 + exp(eta))),
        ),
    )

    @testset "Destination B scalar quadrature anchors" begin
        for case in _QUADRATURE_CASES
            @testset "$(case.label)" begin
                nobs = length(case.y)
                X = ones(nobs, 1)

                # Exact conditional check: a mismatch here is a normalization
                # or objective-constant implementation error, not Laplace error.
                no_effect = GLLVModels.joint_grouped_laplace_loglik(
                    case.family, case.y, case.trials, X, [case.beta], spzeros(nobs, 0);
                    link = case.link,
                )
                conditional = sum(logpdf(case.density(case.beta, i), case.y[i]) for i in 1:nobs)
                @test no_effect.status === :ok
                @test no_effect.converged
                @test isfinite(no_effect.loglik)
                @test isapprox(no_effect.loglik, conditional; atol = 1e-12, rtol = 0.0)

                # One W column is deliberately shared by all observations;
                # this verifies a joint mode rather than per-observation modes.
                shared_effect = GLLVModels.joint_grouped_laplace_loglik(
                    case.family, case.y, case.trials, X, [case.beta], sparse(ones(nobs, 1));
                    link = case.link,
                )
                oracle = _scalar_logmarginal(case.density, case.beta, case.y)
                @test shared_effect.status === :ok
                @test shared_effect.converged
                @test isfinite(shared_effect.loglik)
                @test isfinite(oracle)
                @test abs(shared_effect.loglik - oracle) <= 0.01
            end
        end
    end
end
