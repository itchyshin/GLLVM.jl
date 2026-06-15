using Test
using GLLVM
using Random
using Distributions

function _bridge_test_poisson(seed = 100)
    rng = MersenneTwister(seed)
    return rand(rng, Poisson(2.0), 3, 24)
end

function _bridge_test_binomial(seed = 101)
    rng = MersenneTwister(seed)
    N = fill(5, 3, 24)
    Y = [rand(rng, Binomial(N[i], 0.35 + 0.15 * (i % 3))) for i in eachindex(N)]
    return reshape(Y, 3, 24), N
end

function _bridge_test_beta(seed = 102)
    rng = MersenneTwister(seed)
    return clamp.(rand(rng, Beta(2.0, 5.0), 3, 24), 1e-4, 1 - 1e-4)
end

function _bridge_test_gamma(seed = 103)
    rng = MersenneTwister(seed)
    return rand(rng, Gamma(3.0, 0.8), 3, 24) .+ 1e-6
end

function _bridge_test_ordinal(seed = 104)
    rng = MersenneTwister(seed)
    return rand(rng, 1:3, 3, 30)
end

@testset "bridge_fit minimal no-X contract" begin
    @testset "primitive flat payload and direct-fit parity" begin
        cases = [
            ("gaussian", randn(MersenneTwister(99), 3, 30), nothing),
            ("poisson", Float64.(_bridge_test_poisson()), nothing),
            ("binomial", begin
                Y, N = _bridge_test_binomial()
                Float64.(Y)
            end, begin
                _, N = _bridge_test_binomial()
                N
            end),
            ("negbinomial", Float64.(rand(MersenneTwister(105), NegativeBinomial(5, 0.7), 3, 24)), nothing),
            ("beta", _bridge_test_beta(), nothing),
            ("gamma", _bridge_test_gamma(), nothing),
            ("ordinal", Float64.(_bridge_test_ordinal()), nothing),
        ]
        for (family, Y, N) in cases
            @testset "$family" begin
                br = bridge_fit(; y = Y, family = family, d = 1, N = N,
                                trait_names = ["a", "b", "c"])
                @test br.family == family
                @test br.families == fill(family, size(Y, 1))
                @test br.trait_names == ["a", "b", "c"]
                @test br.unit_names == ["unit$i" for i in 1:size(Y, 2)]
                @test br.loadings isa Matrix{Float64}
                @test br.alpha isa Vector{Float64}
                @test br.dispersion isa Vector{Float64}
                @test br.Sigma isa Matrix{Float64}
                @test br.correlation isa Matrix{Float64}
                @test br.communality isa Vector{Float64}
                @test br.scores isa Matrix{Float64}
                @test br.loglik isa Float64
                @test br.aic isa Float64
                @test br.bic isa Float64
                @test br.df isa Int
                @test br.nobs == length(Y)
                @test br.converged isa Bool
                @test br.iterations isa Int
                @test br.message isa String
                @test br.link isa Vector{String}
                @test br.note isa String

                fit = if family == "gaussian"
                    fit_gaussian_gllvm(Y; K = 1)
                elseif family == "poisson"
                    fit_poisson_gllvm(Matrix{Int}(Y); K = 1)
                elseif family == "binomial"
                    fit_binomial_gllvm(Matrix{Int}(Y); K = 1, N = N)
                elseif family == "negbinomial"
                    fit_nb_gllvm(Matrix{Int}(Y); K = 1)
                elseif family == "beta"
                    fit_beta_gllvm(Y; K = 1)
                elseif family == "gamma"
                    fit_gamma_gllvm(Y; K = 1)
                else
                    fit_ordinal_gllvm(Matrix{Int}(Y); K = 1)
                end
                direct_ll = family == "gaussian" ? fit.logLik : fit.loglik
                @test br.loglik ≈ direct_ll atol = 1e-8
                @test br.loadings ≈ getLoadings(fit; rotate = true) atol = 1e-8
            end
        end
    end

    @testset "Wald CI parity" begin
        Y = Float64.(_bridge_test_poisson(122))
        br = bridge_fit(; y = Y, family = "poisson", d = 1,
                        options = Dict("ci_method" => "wald"))
        fit = fit_poisson_gllvm(Matrix{Int}(Y); K = 1)
        ci = confint(fit; y = Y)
        @test br.ci_method == "wald"
        @test br.ci_status == "ok"
        @test br.ci_param_names == ci.term
        @test br.ci_estimate ≈ ci.estimate atol = 1e-10
        @test br.ci_lower ≈ ci.lower atol = 1e-10 nans = true
        @test br.ci_upper ≈ ci.upper atol = 1e-10 nans = true
    end

    @testset "explicit unsupported bridge cells" begin
        Y = Float64.(_bridge_test_poisson(130))
        X = zeros(size(Y, 1), size(Y, 2), 1)
        @test_throws ArgumentError bridge_fit(; y = Y, family = "poisson", d = 1, X = X)
        @test_throws ArgumentError bridge_fit(; y = Y, family = ["poisson", "gaussian"], d = 1)
        @test_throws ArgumentError bridge_fit(; y = Y, family = "nb1", d = 1)
        @test_throws ArgumentError bridge_fit(; y = Y, family = "poisson", d = 1,
                                              options = Dict("ci_method" => "nonsense"))

        br = bridge_fit(; y = Y, family = "poisson", d = 1,
                        options = Dict("ci_method" => "bootstrap"))
        @test br.ci_method == "bootstrap"
        @test br.ci_status == "unsupported"
        @test isempty(br.ci_lower)
        @test occursin("not routed", br.ci_note)
    end
end
