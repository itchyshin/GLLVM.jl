using GLLVM, Test, LinearAlgebra, Random

# core070 formula-recognizer-spec.md §2, Steps 0-6. Lane implementation only —
# these recognizers are NOT wired into the public `gllvm(formula, ...)` front
# door (StatsModels' `@formula` macro does not parse `lhs | group`); tests
# call the internal `GLLVM._...` functions directly on raw quoted `Expr`s.

@testset "Structured-term recognizer: Step 0 scaffolding" begin
    # Red: augmented LHS aborts (R .assert_no_augmented_lhs, brms-sugar.R:2172-2215)
    @test_throws ArgumentError GLLVM._recognize_source_term(:(indep(1 + x | g)))
    # Red: non-literal flag aborts (R .read_common_flag, brms-sugar.R:2464-2483)
    flagvar = true
    @test_throws ArgumentError GLLVM._recognize_source_term(:(indep(0 + trait | g, common = flagvar)))
    # Green: both valid bar-LHS shapes parse and carry the group symbol.
    spec1 = GLLVM._recognize_source_term(:(indep(0 + trait | g)))
    @test spec1.kind === :indep && spec1.group === :g && spec1.common === false
    spec2 = GLLVM._recognize_source_term(:(dep(1 | grp)))
    @test spec2.kind === :dep && spec2.group === :grp
    # Non-bar first argument aborts.
    @test_throws ArgumentError GLLVM._recognize_source_term(:(indep(g)))
    # Unrecognized call name aborts.
    @test_throws ArgumentError GLLVM._recognize_source_term(:(not_a_term(0 + trait | g)))
end

@testset "Structured-term recognizer: Step 1 indep()" begin
    rng = MersenneTwister(70100); p, n = 3, 24
    g = repeat(1:6; inner=4)
    data = (g = g,)
    Y = randn(rng, p, n) .+ [1.0, -0.5, 0.2]
    opts = (sigma_eps_fixed = 0.5, g_tol = 1e-7)

    spec = GLLVM._recognize_source_term(:(indep(0 + trait | g)))
    @test spec.common === false
    source = GLLVM._source_term_covariance(spec, data)
    @test source.mode === :indep && source.common == false
    @test source.covariance == Matrix{Float64}(I, 6, 6)

    formula_fit = GLLVM._fit_gaussian_structured_sources(Y, data, [:(indep(0 + trait | g))]; opts...)
    direct = fit_gaussian_sources(Y; sources = [source], opts...)
    @test formula_fit.loglik ≈ direct.loglik atol = 1e-8
    @test formula_fit.beta ≈ direct.beta atol = 1e-7

    spec_common = GLLVM._recognize_source_term(:(indep(0 + trait | g, common = true)))
    @test spec_common.common === true
    source_common = GLLVM._source_term_covariance(spec_common, data)
    @test GLLVM._source_nparams(source_common, p) == 1
    fit_common = GLLVM._fit_gaussian_structured_sources(Y, data, [:(indep(0 + trait | g, common = true))]; opts...)
    direct_common = fit_gaussian_sources(Y; sources = [source_common], opts...)
    @test fit_common.loglik ≈ direct_common.loglik atol = 1e-8

    @test_throws ArgumentError GLLVM._recognize_source_term(:(indep(0 + trait | g, bogus = true)))
end

@testset "Structured-term recognizer: Step 2 scalar() alias + warn" begin
    rng = MersenneTwister(70200); p, n = 2, 18
    g = repeat(1:3; inner=6); data = (g = g,)
    Y = randn(rng, p, n)
    opts = (sigma_eps_fixed = 0.4, g_tol = 1e-7)

    scalar_fit = GLLVM._fit_gaussian_structured_sources(Y, data, [:(scalar(0 + trait | g))]; opts...)
    indep_common_fit = GLLVM._fit_gaussian_structured_sources(Y, data, [:(indep(0 + trait | g, common = true))]; opts...)
    @test scalar_fit.loglik ≈ indep_common_fit.loglik atol = 1e-8
    @test scalar_fit.beta ≈ indep_common_fit.beta atol = 1e-8

    scalar_spec = GLLVM._recognize_source_term(:(scalar(0 + trait | g)))
    @test scalar_spec.kind === :scalar && scalar_spec.common === true

    GLLVM._SCALAR_DEPRECATION_WARNED[] = false
    @test_logs (:warn, r"deprecated") GLLVM._recognize_source_term(:(scalar(1 | g)))
    # One-shot: a second call in the same session does not re-warn.
    @test_logs GLLVM._recognize_source_term(:(scalar(1 | g)))
    @test GLLVM._SCALAR_DEPRECATION_WARNED[] === true
end

@testset "Structured-term recognizer: Step 3 dep()" begin
    rng = MersenneTwister(70300); p, n = 3, 20
    g = repeat(1:5; inner=4); data = (g = g,)
    Y = randn(rng, p, n)
    opts = (sigma_eps_fixed = 0.5, g_tol = 1e-7)

    spec = GLLVM._recognize_source_term(:(dep(0 + trait | g)))
    @test spec.kind === :dep
    source = GLLVM._source_term_covariance(spec, data)
    @test source.mode === :dep
    @test GLLVM._source_nparams(source, p) == GLLVM.rr_theta_len(p, p)

    formula_fit = GLLVM._fit_gaussian_structured_sources(Y, data, [:(dep(0 + trait | g))]; opts...)
    direct = fit_gaussian_sources(Y; sources = [source], opts...)
    @test formula_fit.loglik ≈ direct.loglik atol = 1e-8
    @test formula_fit.beta ≈ direct.beta atol = 1e-7

    # rank= is not a dep() spelling — reject any keyword.
    @test_throws ArgumentError GLLVM._recognize_source_term(:(dep(0 + trait | g, rank = 2)))
end

@testset "Structured-term recognizer: Step 4 mutual-exclusion gates" begin
    dep_g = :(dep(0 + trait | g))
    indep_g = :(indep(0 + trait | g))
    scalar_g = :(scalar(1 | g))
    klatent_g = :(kernel_latent(g, K = K, d = 1))
    klatent_unique_g = :(kernel_latent(g, K = K, d = 1, unique = true))
    kunique_g = :(kernel_unique(g, K = K))

    specs(exprs) = GLLVM.SourceTermSpec[GLLVM._recognize_source_term(e) for e in exprs]

    @test_throws ArgumentError GLLVM._check_source_term_exclusions(specs([dep_g, indep_g]))
    @test_throws ArgumentError GLLVM._check_source_term_exclusions(specs([dep_g, scalar_g]))
    @test_throws ArgumentError GLLVM._check_source_term_exclusions(specs([dep_g, klatent_g]))
    @test_throws ArgumentError GLLVM._check_source_term_exclusions(specs([indep_g, klatent_g]))
    @test_throws ArgumentError GLLVM._check_source_term_exclusions(specs([dep_g, klatent_unique_g]))
    @test_throws ArgumentError GLLVM._check_source_term_exclusions(specs([dep_g, kunique_g]))
    # Non-conflicting: different groupings never gate each other.
    @test GLLVM._check_source_term_exclusions(specs([dep_g, :(indep(0 + trait | h))])) === nothing
    # Non-conflicting: two indep terms on the same group are allowed by this gate
    # (name-uniqueness is enforced downstream by fit_gaussian_sources).
    @test GLLVM._check_source_term_exclusions(specs([indep_g, indep_g])) === nothing
end

@testset "Structured-term recognizer: Step 5 kernel_indep/scalar/dep()" begin
    rng = MersenneTwister(70500); p, n = 2, 15
    g = repeat(1:5; inner=3); data = (g = g,)
    Y = randn(rng, p, n)
    L = randn(rng, 5, 5); K = L * L' + 5I
    kernel_env = (K = K,)
    opts = (sigma_eps_fixed = 0.4, g_tol = 1e-7)

    # Named-K omission aborts (R brms-sugar.R:3302-3308).
    @test_throws ArgumentError GLLVM._recognize_source_term(:(kernel_indep(g)))

    for (kind, expr) in ((:kernel_indep, :(kernel_indep(g, K = K, name = "known"))),
                          (:kernel_scalar, :(kernel_scalar(g, K = K, name = "known"))),
                          (:kernel_dep, :(kernel_dep(g, K = K, name = "known"))))
        spec = GLLVM._recognize_source_term(expr)
        @test spec.kind === kind && spec.name === :known
        source = GLLVM._source_term_covariance(spec, data; kernel_env = kernel_env)
        @test source.covariance ≈ K
        fitted = GLLVM._fit_gaussian_structured_sources(Y, data, [expr]; kernel_env = kernel_env, opts...)
        direct = fit_gaussian_sources(Y; sources = [source], opts...)
        @test fitted.loglik ≈ direct.loglik atol = 1e-8
    end

    common_spec = GLLVM._recognize_source_term(:(kernel_indep(g, K = K, common = true)))
    @test common_spec.common === true
end

@testset "Structured-term recognizer: Step 6 kernel_latent()" begin
    rng = MersenneTwister(70600); p, n = 3, 20
    g = repeat(1:5; inner=4); data = (g = g,)
    Y = randn(rng, p, n)
    L = randn(rng, 5, 5); K = L * L' + 5I
    kernel_env = (K = K,)
    opts = (sigma_eps_fixed = 0.4, g_tol = 1e-7)

    spec = GLLVM._recognize_source_term(:(kernel_latent(g, K = K, d = 2, name = "k1")))
    @test spec.kind === :kernel_latent && spec.d == 2 && spec.name === :k1 && spec.unique === false
    source = GLLVM._source_term_covariance(spec, data; kernel_env = kernel_env)
    @test source.mode === :latent && source.rank == 2 && !source.unique

    formula_fit = GLLVM._fit_gaussian_structured_sources(Y, data,
        [:(kernel_latent(g, K = K, d = 2, name = "k1"))]; kernel_env = kernel_env, opts...)
    direct = fit_gaussian_sources(Y; sources = [source], opts...)
    @test formula_fit.loglik ≈ direct.loglik atol = 1e-8
    @test formula_fit.beta ≈ direct.beta atol = 1e-7

    # unique=true folds the Ψ companion into the SAME source (one SourceCovariance).
    unique_spec = GLLVM._recognize_source_term(:(kernel_latent(g, K = K, d = 1, name = "k1", unique = true)))
    @test unique_spec.unique === true
    unique_source = GLLVM._source_term_covariance(unique_spec, data; kernel_env = kernel_env)
    @test unique_source.unique
    @test GLLVM._source_nparams(unique_source, p) ==
        GLLVM.rr_theta_len(p, 1) + p

    unique_fit = GLLVM._fit_gaussian_structured_sources(Y, data,
        [:(kernel_latent(g, K = K, d = 1, name = "k1", unique = true))]; kernel_env = kernel_env, opts...)
    direct_unique = fit_gaussian_sources(Y; sources = [unique_source], opts...)
    @test unique_fit.loglik ≈ direct_unique.loglik atol = 1e-8

    # literal-`unique` gate (R brms-sugar.R:3364-3372)
    flagvar = true
    @test_throws ArgumentError GLLVM._recognize_source_term(
        :(kernel_latent(g, K = K, d = 1, unique = flagvar)))

    # kernel_unique has no standalone SourceCovariance mode: it must fold via
    # kernel_latent(unique=true), per §1.4.
    ku_spec = GLLVM._recognize_source_term(:(kernel_unique(g, K = K, name = "k1")))
    @test ku_spec.kind === :kernel_unique
    @test_throws ArgumentError GLLVM._source_term_covariance(ku_spec, data; kernel_env = kernel_env)

    # PD-strict, no jitter: an indefinite K aborts with the existing isposdef
    # message rather than silently regularizing (structured-native-mapping.md:112-118).
    Kbad = Matrix{Float64}(I, 5, 5); Kbad[1, 1] = -1.0
    bad_spec = GLLVM._recognize_source_term(:(kernel_latent(g, K = Kbad, d = 1)))
    @test_throws ArgumentError GLLVM._source_term_covariance(bad_spec, data; kernel_env = (Kbad = Kbad,))
end
