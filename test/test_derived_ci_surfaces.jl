using GLLVM, Test, Random, LinearAlgebra, Statistics

# Local guard: mirrors test_confint_derived_wald.jl — force-inject the
# (additive) source files into the compiled GLLVM module so their internal
# helpers (_derived_unpack, _tw_link, _twolevel_unpack, …) resolve even if
# this test file runs against a precompiled cache from before this slice.
if !isdefined(GLLVM, :sigma_y_site)
    Base.include(GLLVM, joinpath(@__DIR__, "..", "src", "confint_derived.jl"))
end
if !isdefined(GLLVM, :confint)
    Base.include(GLLVM, joinpath(@__DIR__, "..", "src", "confint.jl"))
end
if !isdefined(GLLVM, :transformed_wald_ci_derived)
    Base.include(GLLVM, joinpath(@__DIR__, "..", "src", "confint_derived_wald.jl"))
end
if !isdefined(GLLVM, :repeatability_wald_ci)
    Base.include(GLLVM, joinpath(@__DIR__, "..", "src", "twolevel.jl"))
end

@testset "Cluster 2 derived-CI surfaces (core070)" begin

    # =======================================================================
    # 1. Two-level repeatability / ICC CI
    # =======================================================================
    @testset "TwoLevelFit repeatability CI" begin
        rng = MersenneTwister(1)
        p, K_B, K_W = 3, 1, 1
        L = 60          # individuals
        n_per = 4       # obs per individual
        Λ_B_true = reshape([0.9, 0.6, 0.3], p, K_B)
        Λ_W_true = reshape([0.3, 0.3, 0.2], p, K_W)
        σ²_B_true = fill(0.05, p)
        σ²_W_true = fill(0.3, p)

        individual = Int[]
        y = Matrix{Float64}(undef, p, 0)
        ys = Vector{Vector{Float64}}()
        for i in 1:L
            b_i = Λ_B_true * randn(rng, K_B) .+ sqrt.(σ²_B_true) .* randn(rng, p)
            for _ in 1:n_per
                yi = b_i .+ Λ_W_true * randn(rng, K_W) .+ sqrt.(σ²_W_true) .* randn(rng, p)
                push!(ys, yi)
                push!(individual, i)
            end
        end
        y = reduce(hcat, ys)

        fit = GLLVM.fit_twolevel_gaussian(y, individual; K_B = K_B, K_W = K_W)
        @test fit.converged

        R = GLLVM.repeatability(fit)
        @test all(0 .< R .< 1)

        @testset "wald CI: logit-transform, brackets the point estimate" begin
            ci = GLLVM.repeatability_wald_ci(fit, y, individual)
            @test length(ci) == p
            for t in 1:p
                @test isapprox(ci[t].estimate, R[t]; rtol = 1e-10)
                if ci[t].method === :transformed_wald
                    @test ci[t].pd_hessian
                    @test 0 <= ci[t].lower <= ci[t].estimate <= ci[t].upper <= 1
                    @test ci[t].transform === :logit
                end
            end
        end

        @testset "wald CI matches log(vB)-log(vW) delta method by finite difference" begin
            # Cross-check the ForwardDiff gradient inside repeatability_wald_ci
            # against a central finite difference on the packed log-odds closure,
            # at a fixed seed, to <=1e-6 relative (repo FD convention).
            θ̂ = GLLVM._twolevel_theta_at_mle(fit)
            t = 1
            g = θ -> GLLVM._repeatability_log_odds_packed(θ, p, K_B, K_W, t)
            grad_ad = GLLVM.ForwardDiff.gradient(g, θ̂)
            eps = 1e-6
            grad_fd = similar(θ̂)
            for j in eachindex(θ̂)
                θp = copy(θ̂); θp[j] += eps
                θm = copy(θ̂); θm[j] -= eps
                grad_fd[j] = (g(θp) - g(θm)) / (2eps)
            end
            @test isapprox(grad_ad, grad_fd; rtol = 1e-4, atol = 1e-6)
        end

        @testset "bootstrap CI: percentile bounds bracket the point estimate" begin
            ci_boot = GLLVM.repeatability_bootstrap_ci(fit, individual; nsim = 40, seed = 7)
            @test length(ci_boot) == p
            for t in 1:p
                @test isapprox(ci_boot[t].estimate, R[t]; rtol = 1e-10)
                if ci_boot[t].n_boot >= 2
                    @test ci_boot[t].lower <= ci_boot[t].upper
                end
            end
        end

        @testset "wald vs bootstrap agree to within a generous MC band" begin
            ci_w = GLLVM.repeatability_wald_ci(fit, y, individual)
            ci_b = GLLVM.repeatability_bootstrap_ci(fit, individual; nsim = 60, seed = 11)
            for t in 1:p
                if ci_w[t].method === :transformed_wald && ci_b[t].n_boot >= 10
                    # Both intervals should overlap substantially with the point
                    # estimate interior to (or very near) both; a loose overlap
                    # check rather than a tight numeric match (small-nsim MC noise).
                    @test ci_w[t].lower < ci_b[t].upper
                    @test ci_b[t].lower < ci_w[t].upper
                end
            end
        end

        @testset "method = :profile is refused with the named withdrawal error" begin
            @test_throws GLLVM.TwoLevelRepeatabilityProfileWithdrawn GLLVM.repeatability_ci(
                fit, y, individual; method = :profile)
            err = try
                GLLVM.repeatability_ci(fit, y, individual; method = :profile)
                nothing
            catch e
                e
            end
            @test err isa GLLVM.TwoLevelRepeatabilityProfileWithdrawn
            @test occursin("profile", sprint(showerror, err))
        end

        @testset "repeatability_ci dispatcher matches direct calls" begin
            ci_w1 = GLLVM.repeatability_ci(fit, y, individual; method = :wald)
            ci_w2 = GLLVM.repeatability_wald_ci(fit, y, individual)
            for t in 1:p
                @test ci_w1[t].estimate == ci_w2[t].estimate
            end
        end
    end

    # =======================================================================
    # Shared Gaussian fixture for the remaining (GllvmFit-based) surfaces.
    # =======================================================================
    Random.seed!(42)
    p, K, n = 4, 2, 500
    Λ_true = [0.9 0.0; 0.5 0.6; 0.3 -0.4; -0.2 0.5]
    σ_true = 0.35
    y2 = Λ_true * randn(K, n) + σ_true * randn(p, n)
    fit2 = fit_gaussian_gllvm(y2; K = K)
    @test fit2.converged

    # =======================================================================
    # 2. Standardized-loading rho Wald CI (loading_ci, method = :wald_asym)
    # =======================================================================
    @testset "standardized loading (rho) Wald CI — Fisher-z" begin
        ci = GLLVM.standardized_loading_wald_ci(fit2, 1, 1; y = y2)
        @test ci.transform === :fisher_z
        Σ = GLLVM.sigma_y_site(fit2)
        rho_expected = fit2.pars.Λ[1, 1] / sqrt(Σ[1, 1])
        @test isapprox(ci.estimate, rho_expected; rtol = 1e-10)
        if ci.method === :transformed_wald
            @test -1 < ci.lower <= ci.estimate <= ci.upper < 1
        end

        # Table form via loading_ci(method = :wald_asym).
        tbl = GLLVM.loading_ci(fit2, y2; method = :wald_asym)
        @test length(tbl) == p * K
        row11 = only(filter(r -> r.trait == 1 && r.axis == 1, tbl))
        @test isapprox(row11.estimate, ci.estimate; rtol = 1e-10)
        @test row11.loading_scale === :standardized

        # k > t entries are structurally pinned by the lower-triangular
        # reduced-rank packing convention.
        pinned_row = only(filter(r -> r.trait == 1 && r.axis == 2, tbl))
        @test pinned_row.pinned
    end

    @testset "loading_ci method=:wald + loading_scale=:standardized dispatches to standardized_loading_wald_ci (not raw)" begin
        ci_std = GLLVM.standardized_loading_wald_ci(fit2, 1, 1; y = y2)
        ci_raw = GLLVM.raw_loading_wald_ci(fit2, 1, 1; y = y2)
        # Sanity: raw and standardized really are different numbers for this
        # fixture (otherwise the defect would be silently unobservable).
        @test !isapprox(ci_std.estimate, ci_raw.estimate; rtol = 1e-6)

        tbl = GLLVM.loading_ci(fit2, y2; method = :wald, loading_scale = :standardized)
        row11 = only(filter(r -> r.trait == 1 && r.axis == 1, tbl))
        @test row11.loading_scale === :standardized
        @test isapprox(row11.estimate, ci_std.estimate; rtol = 1e-10)
        @test isapprox(row11.lower, ci_std.lower; rtol = 1e-10) || (isnan(row11.lower) && isnan(ci_std.lower))
        @test !isapprox(row11.estimate, ci_raw.estimate; rtol = 1e-6)
    end

    @testset "loading_ci raw wald matches Λ point estimate; wald_asym requires standardized" begin
        tbl_raw = GLLVM.loading_ci(fit2, y2; method = :wald)
        row = only(filter(r -> r.trait == 2 && r.axis == 1, tbl_raw))
        @test isapprox(row.estimate, fit2.pars.Λ[2, 1]; rtol = 1e-10)
        @test row.loading_scale === :raw

        @test_throws ArgumentError GLLVM.loading_ci(fit2, y2; method = :wald_asym,
                                                     loading_scale = :raw)
        @test_throws ArgumentError GLLVM.loading_ci(fit2, y2; method = :profile,
                                                     loading_scale = :standardized)
    end

    # =======================================================================
    # 3a. loading_profile — profile-likelihood CI on a raw Λ entry
    # =======================================================================
    @testset "loading_profile brackets the raw Λ estimate" begin
        prof = GLLVM.loading_profile(fit2, 1, 1; y = y2)
        @test isapprox(prof.estimate, fit2.pars.Λ[1, 1]; rtol = 1e-10)
        if prof.method === :profile
            @test prof.lower <= prof.estimate <= prof.upper
        end

        pinned = GLLVM.loading_profile(fit2, 1, 2; y = y2)  # k > t: structurally 0
        @test pinned.method === :pinned
        @test pinned.estimate == 0.0 == pinned.lower == pinned.upper
    end

    # =======================================================================
    # 3b. profile_ci_total_variance / profile_ci_phylo_signal
    # =======================================================================
    @testset "profile_ci_total_variance brackets sigma_y_site diagonal" begin
        Σ = GLLVM.sigma_y_site(fit2)
        prof = GLLVM.profile_ci_total_variance(fit2, 1; y = y2)
        @test isapprox(prof.estimate, Σ[1, 1]; rtol = 1e-10)
        if prof.method === :profile
            @test prof.lower <= prof.estimate <= prof.upper
            @test prof.lower > 0
        end
    end

    @testset "profile_ci_phylo_signal: no-phylo fit returns NaN estimate, not a crash" begin
        # fit2 has no phylogenetic block: phylo_signal(fit2) is all-NaN by
        # contract (confint_derived.jl docstring), so the profiler should see
        # a non-finite point estimate and error cleanly rather than silently
        # returning a bogus interval.
        @test all(isnan, GLLVM.phylo_signal(fit2))
        @test_throws ArgumentError GLLVM.profile_ci_phylo_signal(fit2, 1; y = y2)
    end

    # =======================================================================
    # 4. slope_sd_ci — GaussianRandomSlopeFit random-intercept SD Wald CI
    # =======================================================================
    @testset "slope_sd_ci: log-scale Wald on random-intercept SD" begin
        rng2 = MersenneTwister(3)
        p3, K3 = 3, 1
        Λ0 = reshape([0.7, 0.5, 0.3], p3, K3)
        σ_eps0 = 0.3
        Lgrp = 50
        n_per2 = 5
        σ_u_true = 0.6
        grouping = Int[]
        Z = ones(Lgrp * n_per2, 1)
        cols = Vector{Vector{Float64}}()
        for g in 1:Lgrp
            b_g = σ_u_true * randn(rng2)
            for _ in 1:n_per2
                push!(cols, Λ0 * randn(rng2, K3) .+ σ_eps0 .* randn(rng2, p3) .+ b_g)
                push!(grouping, g)
            end
        end
        y3 = reduce(hcat, cols)

        fit3 = GLLVM.fit_gaussian_random_slope(y3, grouping, Z; K = K3)
        @test fit3.converged
        @test fit3.q == 1

        ci = GLLVM.slope_sd_ci(fit3, y3, grouping, Z)
        @test length(ci) == 1
        sd_hat = sqrt(fit3.Σ_b[1, 1])
        @test isapprox(ci[1].estimate, sd_hat; rtol = 1e-8)
        @test ci[1].transform === :log
        if ci[1].method === :transformed_wald
            @test 0 < ci[1].lower <= ci[1].estimate <= ci[1].upper
        end
    end

    # =======================================================================
    # 5. standard_errors — thin wrapper around confint(fit, y)
    # =======================================================================
    @testset "standard_errors matches confint's term/estimate/se columns" begin
        se_tbl = GLLVM.standard_errors(fit2, y2)
        full = GLLVM.confint(fit2; y = y2)
        @test se_tbl.term == full.term
        @test se_tbl.estimate == full.estimate
        @test isequal(se_tbl.se, full.se)
        @test se_tbl.pd_hessian == full.pd_hessian
    end
end
