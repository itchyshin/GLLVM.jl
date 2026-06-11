using GLLVM, Test, Random, LinearAlgebra, Statistics

# Local guard: load the source files on demand, mirroring the sister
# confint tests (test_confint_derived.jl uses the same pattern). The
# transformed-Wald file depends on _derived_unpack / _sigma_y_site_from_unpacked
# (confint_derived.jl) and _confint_reconstruct_nll (confint.jl).
# `using GLLVM` loads the *compiled* module, which does not include the
# new (additive) transformed-Wald file. Inject it INTO the GLLVM module
# with Base.include so its functions resolve their internal dependencies
# (_derived_unpack, _confint_reconstruct_nll, ForwardDiff, …) correctly
# and become reachable as `GLLVM.*`. Its dependencies confint_derived.jl
# and confint.jl are already compiled into GLLVM.
if !isdefined(GLLVM, :sigma_y_site)
    Base.include(GLLVM, joinpath(@__DIR__, "..", "src", "confint_derived.jl"))
end
if !isdefined(GLLVM, :confint)
    Base.include(GLLVM, joinpath(@__DIR__, "..", "src", "confint.jl"))
end
if !isdefined(GLLVM, :transformed_wald_ci_derived)
    Base.include(GLLVM, joinpath(@__DIR__, "..", "src", "confint_derived_wald.jl"))
end

@testset "transformed-Wald CIs for derived bounded quantities" begin

    # ----- Shared non-phylo fixture (J1: K_B = 1, no W, no diag) -----
    Random.seed!(20)
    p, K, n = 4, 1, 400
    Λ_true = reshape([0.8, 0.6, 0.4, -0.3], p, K)
    σ_true = 0.4
    y = Λ_true * randn(K, n) + σ_true * randn(p, n)
    fit = fit_gaussian_gllvm(y; K = K)
    @test fit.converged

    spec = GLLVM._derived_spec(fit)

    @testset "link round-trips" begin
        for ρ in (-0.9, -0.3, 0.0, 0.5, 0.95)
            @test isapprox(GLLVM._tw_fisher_z_inv(GLLVM._tw_fisher_z(ρ)), ρ;
                           atol = 1e-12)
        end
        for x in (0.05, 0.3, 0.5, 0.8, 0.97)
            @test isapprox(GLLVM._tw_logistic(GLLVM._tw_logit(x)), x; atol = 1e-12)
        end
    end

    @testset "packed closures equal public accessors at θ̂" begin
        R = GLLVM.correlation(fit)
        c2 = GLLVM.communality(fit)
        θ̂ = fit.pars.θ_packed
        # Correlation: a couple of off-diagonals.
        for (i, j) in ((1, 2), (2, 3), (1, 4))
            @test isapprox(GLLVM._correlation_packed(θ̂, spec, i, j), R[i, j];
                           rtol = 1e-10)
        end
        # Communality per trait.
        for t in 1:p
            @test isapprox(GLLVM._communality_packed(θ̂, spec, t), c2[t];
                           rtol = 1e-10)
        end
    end

    @testset "correlation transformed-Wald: estimate, bounds, range" begin
        R = GLLVM.correlation(fit)
        for (i, j) in ((1, 2), (1, 3), (2, 4))
            ci = GLLVM.correlation_wald_ci(fit, i, j; y = y)
            @test ci.method === :transformed_wald
            @test ci.transform === :fisher_z
            @test ci.pd_hessian
            # Point estimate == raw derived quantity.
            @test isapprox(ci.estimate, R[i, j]; rtol = 1e-10)
            # Bounds are finite, ordered, and strictly inside [-1, 1].
            @test isfinite(ci.lower) && isfinite(ci.upper)
            @test ci.lower < ci.upper
            @test -1.0 ≤ ci.lower
            @test ci.upper ≤ 1.0
            # Estimate inside its own interval.
            @test ci.lower ≤ ci.estimate ≤ ci.upper
        end
    end

    @testset "communality transformed-Wald: estimate, bounds, range" begin
        c2 = GLLVM.communality(fit)
        for t in 1:p
            ci = GLLVM.communality_wald_ci(fit, t; y = y)
            @test ci.method === :transformed_wald
            @test ci.transform === :logit
            @test ci.pd_hessian
            @test isapprox(ci.estimate, c2[t]; rtol = 1e-10)
            @test isfinite(ci.lower) && isfinite(ci.upper)
            @test ci.lower < ci.upper
            # Bounds strictly inside [0, 1].
            @test 0.0 ≤ ci.lower
            @test ci.upper ≤ 1.0
            @test ci.lower ≤ ci.estimate ≤ ci.upper
        end
    end

    @testset "generic API matches the wrapper" begin
        f_ρ = GLLVM._make_correlation_closure(spec, 1, 2)
        ci_generic = GLLVM.transformed_wald_ci_derived(fit, f_ρ;
                                                       transform = :fisher_z, y = y)
        ci_wrap = GLLVM.correlation_wald_ci(fit, 1, 2; y = y)
        @test isapprox(ci_generic.lower, ci_wrap.lower; rtol = 1e-12)
        @test isapprox(ci_generic.upper, ci_wrap.upper; rtol = 1e-12)
        @test isapprox(ci_generic.estimate, ci_wrap.estimate; rtol = 1e-12)
    end

    @testset "invalid transform symbol errors" begin
        f_ρ = GLLVM._make_correlation_closure(spec, 1, 2)
        @test_throws ArgumentError GLLVM.transformed_wald_ci_derived(
            fit, f_ρ; transform = :probit, y = y)
    end

    @testset "missing y errors" begin
        f_ρ = GLLVM._make_correlation_closure(spec, 1, 2)
        @test_throws ArgumentError GLLVM.transformed_wald_ci_derived(
            fit, f_ρ; transform = :fisher_z)
    end

    @testset "phylo signal transformed-Wald in [0, 1] (phylo fixture)" begin
        # Small phylo fixture (has_phy_unique path; K_phy = 0).
        Random.seed!(21)
        p2, n2 = 6, 200
        Λ2 = reshape(0.3 .+ 0.4 .* abs.(randn(p2)), p2, 1)
        Λ2[2:2:end] .*= -1.0
        phy = GLLVM.random_balanced_tree(p2; branch_length = 0.5)
        Σ_phy = Matrix(Symmetric(GLLVM.sigma_phy_dense(phy; σ²_phy = 1.0)))
        L_phy = cholesky(Symmetric(Σ_phy)).L
        σ_phy_true = 0.8
        # Simulate: latent factor + species-shared phylo + residual.
        y2 = Λ2 * randn(1, n2)
        φ = σ_phy_true .* (L_phy * randn(p2))
        for s in 1:n2, t in 1:p2
            y2[t, s] += φ[t]
        end
        y2 .+= 0.5 .* randn(p2, n2)
        fit2 = fit_gaussian_gllvm(y2; K = 1, has_phy_unique = true, Σ_phy = Σ_phy)
        @test fit2.converged

        h2_vec = GLLVM.phylo_signal(fit2; Σ_phy = Σ_phy)
        # Test a trait whose point estimate is interior (not on a boundary).
        t_test = findfirst(h -> isfinite(h) && 0.02 < h < 0.98, h2_vec)
        @test t_test !== nothing
        ci = GLLVM.phylo_signal_wald_ci(fit2, t_test; y = y2, Σ_phy = Σ_phy)
        @test ci.transform === :logit
        # FIXED (issue #92): `_derived_unpack` was reconstructing the phylo-unique
        # σ_phy as exp(θ_slot), but the Gaussian phylo fitter packs σ_phy on the
        # NATURAL (signed, identity-link) scale — so the exp over-transformed it
        # (H²≈6.5, out of range) and destroyed its sign. Removing the exp reconciles
        # the packed numerator with the public `phylo_signal` extractor; σ_y-site and
        # the shared profile-CI path are unaffected (they never read u.σ_phy). The CI
        # now returns method :transformed_wald with bounds in [0, 1].
        @test ci.method === :transformed_wald
        @test isapprox(ci.estimate, h2_vec[t_test]; rtol = 1e-8)
        @test isfinite(ci.lower) && isfinite(ci.upper)
        @test ci.lower < ci.upper
        @test 0.0 ≤ ci.lower ≤ ci.upper ≤ 1.0
        @test ci.lower ≤ ci.estimate ≤ ci.upper

        # Regression guard (issue #92): the PACKED phylo-signal numerator must equal
        # the PUBLIC phylo_signal(fit; Σ_phy)[t] to rtol 1e-8 — has_phy_unique path.
        spec2 = GLLVM._derived_spec(fit2)
        for t in 1:p2
            isfinite(h2_vec[t]) || continue
            hp = GLLVM._phylo_signal_packed(fit2.pars.θ_packed, spec2, t;
                                            diag_Σphy = diag(Σ_phy))
            @test isapprox(hp, h2_vec[t]; rtol = 1e-8)
        end

        # Same packed≡public equivalence on the K_phy>0 (phylo-loadings) path: refit
        # the same data with a phylogenetic latent column instead of per-trait σ_phy.
        # Λ_phy is unpacked via unpack_lambda (never exp'd), so this path was already
        # correct; the guard pins it across both phylo parameterisations.
        fit3 = fit_gaussian_gllvm(y2; K = 1, K_phy = 1, Σ_phy = Σ_phy)
        if fit3.converged
            h3 = GLLVM.phylo_signal(fit3; Σ_phy = Σ_phy)
            spec3 = GLLVM._derived_spec(fit3)
            for t in 1:p2
                isfinite(h3[t]) || continue
                hp3 = GLLVM._phylo_signal_packed(fit3.pars.θ_packed, spec3, t;
                                                 diag_Σphy = diag(Σ_phy))
                @test isapprox(hp3, h3[t]; rtol = 1e-8)
            end
        end
    end

end
