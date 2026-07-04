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

function _bridge_test_gaussian_x(seed = 106)
    rng = MersenneTwister(seed)
    p, n = 3, 28
    X = zeros(p, n, 1)
    Y = randn(rng, p, n)
    for t in axes(X, 1), s in axes(X, 2)
        X[t, s, 1] = randn(rng)
        Y[t, s] += 0.35 * X[t, s, 1]
    end
    return Y, X
end

@testset "bridge_fit minimal one-part contract" begin
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

    @testset "Gaussian fixed-effect X bridge parity" begin
        Y, X = _bridge_test_gaussian_x()
        br = bridge_fit(; y = Y, family = "gaussian", d = 1, X = X,
                        trait_names = ["a", "b", "c"],
                        options = Dict("ci_method" => "wald",
                                       "ci_parm" => "beta[1]"))
        fit = fit_gaussian_gllvm(Y; K = 1, X = X)
        ci = confint(fit; y = Y, X = X, parm = "beta[1]")

        @test br.family == "gaussian"
        @test br.trait_names == ["a", "b", "c"]
        @test haskey(br, :mean_coef)
        @test br.mean_coef ≈ fit.pars.β atol = 1e-8
        @test br.loglik ≈ fit.logLik atol = 1e-8
        @test br.loadings ≈ getLoadings(fit; rotate = true) atol = 1e-8
        @test br.ci_method == "wald"
        @test br.ci_status == "ok"
        @test br.ci_param_names == ci.term
        @test br.ci_estimate ≈ ci.estimate atol = 1e-10
        @test br.ci_lower ≈ ci.lower atol = 1e-10
        @test br.ci_upper ≈ ci.upper atol = 1e-10
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

    @testset "selected profile CI payload" begin
        Y = Float64.(_bridge_test_poisson(123))
        br = bridge_fit(; y = Y, family = "poisson", d = 1,
                        options = Dict(
                            "ci_method" => "profile",
                            "ci_parm" => "beta[1]",
                            "profile_max_expand" => 8,
                            "profile_max_bisect" => 12,
                        ))
        fit = fit_poisson_gllvm(Matrix{Int}(Y); K = 1)
        ci = profile_ci(fit, "beta[1]"; y = Matrix{Int}(Y),
                        max_expand = 8, max_bisect = 12)
        @test br.ci_method == "profile"
        @test br.ci_status in ("ok", "partial")
        @test br.ci_param_names == ["beta[1]"]
        @test br.ci_lower ≈ [ci.lower] atol = 1e-8 nans = true
        @test br.ci_upper ≈ [ci.upper] atol = 1e-8 nans = true
        @test br.ci_lower[1] < br.ci_estimate[1] < br.ci_upper[1]
    end

    @testset "postfit response simulation" begin
        rng = MersenneTwister(707)

        Yg = randn(rng, 3, 22)
        fitg = fit_gaussian_gllvm(Yg; K = 1)
        simg = simulate_response(fitg, Yg; rng = MersenneTwister(1))
        @test size(simg) == size(Yg)
        simg3 = simulate_response(fitg, Yg; nsim = 3, rng = MersenneTwister(1))
        @test size(simg3) == (size(Yg, 1), size(Yg, 2), 3)

        Yp = _bridge_test_poisson(708)
        fitp = fit_poisson_gllvm(Matrix{Int}(Yp); K = 1)
        simp = simulate_response(fitp, Matrix{Int}(Yp); rng = MersenneTwister(2))
        @test size(simp) == size(Yp)
        @test eltype(simp) <: Integer
        @test all(simp .>= 0)

        Yb, N = _bridge_test_binomial(709)
        fitb = fit_binomial_gllvm(Matrix{Int}(Yb); K = 1, N = N)
        simb = simulate_response(fitb, Matrix{Int}(Yb); N = N,
                                 rng = MersenneTwister(3))
        @test size(simb) == size(Yb)
        @test all((simb .>= 0) .& (simb .<= N))

        Ynb = rand(MersenneTwister(710), NegativeBinomial(5, 0.7), 3, 22)
        fitnb = fit_nb_gllvm(Matrix{Int}(Ynb); K = 1)
        simnb = simulate_response(fitnb, Matrix{Int}(Ynb); rng = MersenneTwister(4))
        @test size(simnb) == size(Ynb)
        @test all(simnb .>= 0)

        Ybe = _bridge_test_beta(711)
        fitbe = fit_beta_gllvm(Ybe; K = 1)
        simbe = simulate_response(fitbe, Ybe; rng = MersenneTwister(5))
        @test size(simbe) == size(Ybe)
        @test all((simbe .> 0) .& (simbe .< 1))

        Yga = _bridge_test_gamma(712)
        fitga = fit_gamma_gllvm(Yga; K = 1)
        simga = simulate_response(fitga, Yga; rng = MersenneTwister(6))
        @test size(simga) == size(Yga)
        @test all(simga .> 0)

        Yo = _bridge_test_ordinal(713)
        fito = fit_ordinal_gllvm(Matrix{Int}(Yo); K = 1)
        @test_throws ArgumentError simulate_response(fito, Matrix{Int}(Yo))
        @test_throws ArgumentError simulate_response(fitg, Yg; nsim = 0)
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
