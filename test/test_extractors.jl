using GLLVM, Test, Random, LinearAlgebra, Statistics

# src/extractors.jl — post-fit extractor family (core070 missing-surface work
# order, Cluster 1). Verifies the `extract_*`/`get*` public names against
# closed-form formulas and against the existing internal generics they
# forward to (sigma_y_site, communality, correlation, proportions,
# phylo_signal, repeatability, communality_B/W, correlation_B/W, getLoadings,
# ordination).

@testset "extractors.jl — post-fit extractor family" begin

    @testset "extract_Sigma(::GllvmFit) — J1 (no W, no diag)" begin
        Random.seed!(101)
        p, K, n = 4, 2, 300
        Λ_true = 0.6 .* randn(p, K)
        y = Λ_true * randn(K, n) + 0.4 .* randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)

        out_unit = extract_Sigma(fit; level = :unit, part = :total)
        Σ_manual = fit.pars.Λ * fit.pars.Λ'
        @test out_unit.Sigma ≈ Σ_manual atol = 1e-10
        @test out_unit.R ≈ GLLVM._cov2cor(Σ_manual) atol = 1e-10
        @test out_unit.level === :unit

        # J1 has no W tier: :unit_obs collapses to σ_eps² I.
        out_w = extract_Sigma(fit; level = :unit_obs, part = :total)
        @test out_w.Sigma ≈ (fit.pars.σ_eps^2) .* Matrix(I, p, p) atol = 1e-10

        # :B / :W legacy aliases match :unit / :unit_obs.
        @test extract_Sigma(fit; level = :B).Sigma ≈ out_unit.Sigma
        @test extract_Sigma(fit; level = :W).Sigma ≈ out_w.Sigma

        # part = :shared is the Λ Λᵀ term alone (no R field).
        shared = extract_Sigma(fit; level = :unit, part = :shared)
        @test shared.Sigma ≈ Σ_manual atol = 1e-10
        @test !haskey(shared, :R)

        # part = :unique is the diagonal alone; :unit has no σ²_B in J1 → zero.
        uniq = extract_Sigma(fit; level = :unit, part = :unique)
        @test uniq.s ≈ zeros(p) atol = 1e-12
        uniq_w = extract_Sigma(fit; level = :unit_obs, part = :unique)
        @test uniq_w.s ≈ fill(fit.pars.σ_eps^2, p) atol = 1e-10

        # :site tier matches the existing sigma_y_site generic exactly.
        @test extract_Sigma(fit; level = :site).Sigma ≈ GLLVM.sigma_y_site(fit) atol = 1e-12

        @test_throws ArgumentError extract_Sigma(fit; level = :bogus)
        @test_throws ArgumentError extract_Sigma(fit; part = :bogus)
    end

    @testset "extract_Sigma(::GllvmFit) — J2 (W tier + diag)" begin
        Random.seed!(102)
        p, K_B, K_W, n = 4, 1, 1, 400
        Λ_B = 0.6 .* randn(p, K_B); Λ_W = 0.4 .* randn(p, K_W)
        σ_B = 0.2 .+ 0.1 .* rand(p); σ_W = 0.2 .+ 0.1 .* rand(p)
        Y = Λ_B * randn(K_B, n) .+ σ_B .* randn(p, n) .+
            Λ_W * randn(K_W, n) .+ σ_W .* randn(p, n) .+ 0.3 .* randn(p, n)
        fit = fit_gaussian_gllvm(Y; K = K_B, K_W = K_W, has_diag = true)

        out_unit = extract_Sigma(fit; level = :unit)
        Σ_B_manual = fit.pars.Λ * fit.pars.Λ' + Diagonal(fit.pars.σ²_B)
        @test out_unit.Sigma ≈ Σ_B_manual atol = 1e-8

        out_w = extract_Sigma(fit; level = :unit_obs)
        Σ_W_manual = fit.pars.Λ_W * fit.pars.Λ_W' + Diagonal(fit.pars.σ²_W) +
                     (fit.pars.σ_eps^2) .* Matrix(I, p, p)
        @test out_w.Sigma ≈ Σ_W_manual atol = 1e-8

        # extract_Omega sums the two tiers (no phy block here).
        Ω = extract_Omega(fit)
        @test Ω ≈ out_unit.Sigma .+ out_w.Sigma atol = 1e-8

        # extract_ICC_site is v_B / (v_B + v_W) per trait, in [0, 1].
        icc = extract_ICC_site(fit)
        vB = diag(out_unit.Sigma); vW = diag(out_w.Sigma)
        @test icc ≈ vB ./ (vB .+ vW) atol = 1e-10
        @test all(0.0 .≤ icc .≤ 1.0)
    end

    @testset "extract_Sigma_table — tidy long format matches extract_Sigma" begin
        Random.seed!(103)
        p, K, n = 3, 1, 150
        y = (0.5 .* randn(p, K)) * randn(K, n) + 0.4 .* randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        Σ = extract_Sigma(fit; level = :unit).Sigma
        tbl = extract_Sigma_table(fit; level = :unit)
        @test length(tbl) == div(p * (p + 1), 2)
        for row in tbl
            @test row.value ≈ Σ[row.trait_i, row.trait_j] atol = 1e-10
            @test row.trait_i ≤ row.trait_j
        end
        @test_throws ArgumentError extract_Sigma_table(fit; part = :unique)
    end

    @testset "extract_loadings / extract_rotated_loadings forward to getLoadings" begin
        Random.seed!(104)
        p, K, n = 4, 2, 200
        y = (0.5 .* randn(p, K)) * randn(K, n) + 0.3 .* randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)

        @test extract_loadings(fit; rotate = true) ≈ getLoadings(fit; rotate = true)
        @test extract_loadings(fit; rotate = false) ≈ getLoadings(fit; rotate = false)
        @test extract_loadings(fit) ≈ getLoadings(fit; rotate = true)  # default rotate=true

        rl = extract_rotated_loadings(fit)
        @test rl.Λ ≈ getLoadings(fit; rotate = true)
        R = rl.R
        @test R' * R ≈ Matrix(I, K, K) atol = 1e-10
        @test getLoadings(fit; rotate = false) * R ≈ rl.Λ atol = 1e-10
    end

    @testset "extract_communality / extract_correlations (GllvmFit) forward correctly" begin
        Random.seed!(105)
        p, K, n = 4, 1, 300
        y = (0.7 .* randn(p, K)) * randn(K, n) + 0.4 .* randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)

        @test extract_communality(fit) ≈ GLLVM.communality(fit)
        @test extract_correlations(fit) ≈ GLLVM.correlation(fit)
        R = extract_correlations(fit)
        @test all(≈(1.0; atol = 1e-10), diag(R))
        @test all(-1.0 - 1e-9 .≤ R .≤ 1.0 + 1e-9)

        # extract_cross_correlations is a positional submatrix slice.
        sub = extract_cross_correlations(fit; traits_i = [1, 2], traits_j = [3, 4])
        @test sub ≈ R[[1, 2], [3, 4]] atol = 1e-12

        # Regression: `level` was accepted and silently ignored for a
        # GllvmFit (which computes one site-level correlation tier). Match
        # bootstrap_Sigma's validate-and-throw pattern instead.
        @test_throws ArgumentError extract_cross_correlations(fit; level = :unit_obs,
                                                                traits_i = [1, 2], traits_j = [3, 4])
        @test_throws ArgumentError extract_cross_correlations(fit; level = :bogus,
                                                                traits_i = [1, 2], traits_j = [3, 4])
    end

    @testset "extract_proportions / extract_phylo_signal forward to internals" begin
        Random.seed!(106)
        p, K, n = 4, 1, 200
        y = (0.6 .* randn(p, K)) * randn(K, n) + 0.5 .* randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)

        @test extract_proportions(fit) ≈ GLLVM.proportions(fit; component = :shared)
        @test extract_proportions(fit; component = :residual) ≈
              GLLVM.proportions(fit; component = :residual)

        # No phylo block on this fit: phylo signal is all-NaN.
        hs = extract_phylo_signal(fit)
        @test length(hs) == p
        @test all(isnan, hs)
    end

    @testset "extract_ordination forwards to ordination" begin
        Random.seed!(107)
        p, K, n = 3, 2, 100
        y = (0.5 .* randn(p, K)) * randn(K, n) + 0.4 .* randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        ord1 = extract_ordination(fit, y)
        ord2 = ordination(fit, y)
        @test ord1.sites ≈ ord2.sites
        @test ord1.species ≈ ord2.species
        @test ord1.rotation ≈ ord2.rotation
    end

    @testset "extract_cutpoints (OrdinalFit)" begin
        Random.seed!(108)
        p, K, n, C = 4, 1, 200, 4
        Λ_true = 0.7 .* randn(p, K)
        η = Λ_true * randn(K, n)
        τ_true = [-1.0, 0.0, 1.0]
        Y = Matrix{Int}(undef, p, n)
        for j in 1:n, i in 1:p
            c = 1
            while c < C && η[i, j] > τ_true[c]
                c += 1
            end
            Y[i, j] = c
        end
        fit = fit_ordinal_gllvm(Y; K = K)
        cp = extract_cutpoints(fit)
        @test cp.τ == fit.τ
        @test cp.C == fit.C
        @test issorted(cp.τ)
    end

    @testset "TwoLevelFit extractors forward to twolevel.jl generics" begin
        Random.seed!(109)
        p, K_B, K_W = 3, 1, 1
        Λ_B = 0.6 .* randn(p, K_B); Λ_W = 0.4 .* randn(p, K_W)
        σ²_B = 0.1 .+ 0.1 .* rand(p); σ²_W = 0.1 .+ 0.1 .* rand(p)
        nindiv, nobs = 40, 4
        indiv = repeat(1:nindiv, inner = nobs)
        Y = zeros(p, nindiv * nobs)
        col = 0
        for i in 1:nindiv
            b = Λ_B * randn(K_B) .+ sqrt.(σ²_B) .* randn(p)
            for _ in 1:nobs
                col += 1
                Y[:, col] = b .+ Λ_W * randn(K_W) .+ sqrt.(σ²_W) .* randn(p)
            end
        end
        fit = fit_twolevel_gaussian(Y, indiv; K_B = K_B, K_W = K_W)

        @test extract_Sigma(fit; level = :unit).Sigma ≈ fit.Σ_B atol = 1e-10
        @test extract_Sigma(fit; level = :unit_obs).Sigma ≈ fit.Σ_W atol = 1e-10
        @test extract_Sigma(fit; level = :unit, part = :shared).Sigma ≈ fit.Λ_B * fit.Λ_B' atol = 1e-10
        @test extract_Sigma(fit; level = :unit, part = :unique).s ≈ fit.σ²_B atol = 1e-10

        @test extract_communality(fit; level = :unit) ≈ communality_B(fit)
        @test extract_communality(fit; level = :unit_obs) ≈ communality_W(fit)
        @test extract_correlations(fit; level = :unit) ≈ correlation_B(fit)
        @test extract_correlations(fit; level = :unit_obs) ≈ correlation_W(fit)

        @test extract_repeatability(fit) ≈ repeatability(fit)
        @test extract_ICC_site(fit) ≈ repeatability(fit)

        @test extract_residual_cov(fit; level = :unit) ≈ fit.Σ_B atol = 1e-10
        @test extract_residual_cor(fit; level = :unit) ≈ correlation_B(fit) atol = 1e-10
        @test getResidualCov(fit; level = :unit) ≈ extract_residual_cov(fit; level = :unit)
        @test getResidualCor(fit; level = :unit) ≈ extract_residual_cor(fit; level = :unit)
        @test getResidualCov(fit; level = :unit_obs) ≈ fit.Σ_W atol = 1e-10

        sub = extract_cross_correlations(fit; level = :unit, traits_i = [1], traits_j = [2, 3])
        @test sub ≈ correlation_B(fit)[[1], [2, 3]] atol = 1e-12
    end

    @testset "non-Gaussian extract_communality / extract_correlations forward" begin
        Random.seed!(110)
        p, K, n = 3, 1, 300
        Λ_true = 0.5 .* randn(p, K)
        η = Λ_true * randn(K, n)
        μ = exp.(η)
        Y = [rand(GLLVM.Distributions.Poisson(μ[i, j])) for i in 1:p, j in 1:n]
        fit = fit_poisson_gllvm(Y; K = K)

        @test extract_communality(fit, Y) ≈ GLLVM.communality(fit, Y)
        @test extract_correlations(fit, Y) ≈ GLLVM.correlation(fit, Y)
    end
end
