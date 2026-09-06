using Test, GLLVM, LinearAlgebra, Random

# Structured-covariance bridge route, v1 (design:
# docs/dev-log/julia-bridge-structured-design-julia-side.md). Gaussian-only,
# single source, default trait-intercept mean; everything unsupported rejects
# loudly. The decisive checks: bridge-vs-native identity, and reproduction of
# the frozen COV-ORD-LATENT-BARE retained log-likelihood.
@testset "bridge sources route (gaussian, v1)" begin
    rng = MersenneTwister(4242)
    p, n = 3, 24
    Y = reshape([0.7, 0.35, -0.25], p, 1) * randn(rng, 1, n) + 0.6 .* randn(rng, p, n)
    C = Matrix{Float64}(I, n, n)
    groups = collect(1:n)
    srcdict(; kw...) = begin
        d = Dict{String, Any}(
            "name" => "ord", "covariance" => C, "groups" => groups,
            "mode" => "latent", "rank" => 1, "unique" => false, "common" => false)
        for (k, v) in kw
            d[String(k)] = v
        end
        d
    end

    # 1. bridge vs native identity
    br = GLLVM.bridge_fit(; y = Y, family = "gaussian", d = 1,
        sources = [srcdict()], options = Dict{String, Any}("ci_method" => "none"))
    native = fit_gaussian_sources(Y;
        sources = [SourceCovariance(C; groups = groups, mode = :latent, rank = 1,
            unique = false, name = :ord)], g_tol = 1e-6, iterations = 500)
    @test br.loglik ≈ native.loglik atol = 1e-10
    @test br.sigma_eps ≈ native.sigma_eps atol = 1e-10
    @test br.converged == native.converged
    @test br.source_names == ["ord"]
    @test br.source_modes == ["latent"]
    @test br.source_covariance ≈ Matrix(only(native.trait_covariances)) atol = 1e-12
    @test isfinite(br.gradient_max)

    # 1b. Dense kernel + repeated groups + Psi: the bridge must be a thin
    # transport layer over the native one-source fit.  In particular, B is the
    # source covariance Lambda*Lambda' + Psi, not residual-inclusive Sigma.
    Kcross = [1.4 0.2 0.1; 0.2 1.1 0.25; 0.1 0.25 1.3]
    cross_groups = [2, 1, 2, 3, 1, 3]
    Ycross = [
        0.4 -0.2 0.8 0.1 -0.5 0.6
        -0.3 0.5 0.1 -0.7 0.2 0.4
    ]
    cross_spec = Dict{String, Any}(
        "name" => "cross", "covariance" => Kcross, "groups" => cross_groups,
        "mode" => "latent", "rank" => 1, "unique" => true, "common" => false)
    bridge_cross = GLLVM.bridge_fit(; y = Ycross, family = "gaussian", d = 1,
        sources = [cross_spec], options = Dict{String, Any}("ci_method" => "none",
            "g_tol" => 1e-6, "iterations" => 500))
    native_cross = fit_gaussian_sources(Ycross;
        sources = [SourceCovariance(Kcross; groups = cross_groups, name = :cross,
            mode = :latent, rank = 1, unique = true, common = false)],
        g_tol = 1e-6, iterations = 500)
    Bcross = Matrix(only(native_cross.trait_covariances))
    source_cor = B -> B ./ sqrt.(diag(B) * diag(B)')
    @test bridge_cross.loglik ≈ native_cross.loglik atol = 1e-10
    @test bridge_cross.sigma_eps ≈ native_cross.sigma_eps atol = 1e-10
    @test bridge_cross.converged == native_cross.converged
    @test bridge_cross.source_unique == [true]
    @test bridge_cross.source_covariance ≈ Bcross atol = 1e-12
    @test source_cor(bridge_cross.source_covariance) ≈ source_cor(Bcross) atol = 1e-12

    # 2. groups vs projection equivalence
    P = zeros(n, n); for (i, g) in enumerate(groups) P[i, g] = 1.0 end
    br2 = GLLVM.bridge_fit(; y = Y, family = "gaussian", d = 1,
        sources = [srcdict(projection = P, groups = nothing)],
        options = Dict{String, Any}("ci_method" => "none"))
    @test br2.loglik ≈ br.loglik atol = 1e-10

    # 3. malformed sources reject loudly
    Cbad = copy(C); Cbad[1, 2] = 0.3   # asymmetric
    @test_throws ArgumentError GLLVM.bridge_fit(; y = Y, family = "gaussian",
        d = 1, sources = [srcdict(covariance = Cbad)])
    @test_throws ArgumentError GLLVM.bridge_fit(; y = Y, family = "gaussian",
        d = 1, sources = [srcdict(mode = "bogus")])
    @test_throws ArgumentError GLLVM.bridge_fit(; y = Y, family = "gaussian",
        d = 1, sources = [srcdict(mode = "indep", rank = 2)])

    # 4. unsupported compositions reject loudly
    @test_throws ArgumentError GLLVM.bridge_fit(; y = Y, family = "poisson",
        d = 1, sources = [srcdict()])
    @test_throws ArgumentError GLLVM.bridge_fit(; y = Y, family = "gaussian",
        d = 1, sources = [srcdict()], X = ones(p, n, 1))
    @test_throws ArgumentError GLLVM.bridge_fit(; y = Y, family = "gaussian",
        d = 1, sources = [srcdict()], mask = trues(p, n))
    @test_throws ArgumentError GLLVM.bridge_fit(; y = Y, family = "gaussian",
        d = 1, sources = [srcdict()],
        options = Dict{String, Any}("ci_method" => "wald"))
    @test_throws ArgumentError GLLVM.bridge_fit(; y = Y, family = "gaussian",
        d = 1, sources = [srcdict(), srcdict(name = "b")])

    # 5. frozen COV-ORD-LATENT-BARE reproduction (retained four-route loglik)
    yrow = include(joinpath(@__DIR__, "fixtures", "input_gauss_loadings_y.jl"))
    Yfz = collect(reshape(yrow, 18, 3)')
    brfz = GLLVM.bridge_fit(; y = Yfz, family = "gaussian", d = 1,
        sources = [Dict{String, Any}(
            "name" => "ordinary_latent",
            "covariance" => Matrix{Float64}(I, 18, 18),
            "groups" => collect(1:18), "mode" => "latent", "rank" => 1,
            "unique" => false, "common" => false)],
        options = Dict{String, Any}("ci_method" => "none", "g_tol" => 1e-7,
            "iterations" => 2000))
    @test brfz.converged
    @test brfz.loglik ≈ -20.9253282433994 atol = 1e-8
end
