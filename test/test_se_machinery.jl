# Standalone tests for the core070 E-cluster SE-machinery slice:
#   latent_score_sd, bootstrap_Sigma, tmbprofile_wrapper / profile_targets /
#   profile_phylo_signal.
#
# Run standalone:
#   julia --project=. test/test_se_machinery.jl
#
# Not wired into test/runtests.jl in this slice (that file is owned by a
# sibling agent) — see docs/dev-log/core070/se-machinery-slice-notes.md.

using Test
using Random
using LinearAlgebra
using GLLVM
using Distributions: Poisson

@testset "core070 E-cluster: SE machinery" begin

    # -----------------------------------------------------------------
    # latent_score_sd — Gaussian closed-form path: exact identity vs a direct
    # dense computation via a DIFFERENT formula (Cov(z|y) = I - Λ'Σ_y⁻¹Λ,
    # the standard joint-Gaussian conditioning identity) than the one
    # `latent_score_sd` itself uses (M⁻¹, M = I + Λ'Ψ⁻¹Λ via Woodbury). Agreement
    # to ≤ 1e-10 is a genuine cross-check, not a tautology.
    # -----------------------------------------------------------------
    @testset "latent_score_sd Gaussian: exact vs direct dense (≤1e-10)" begin
        rng = MersenneTwister(1)
        p, n, K = 6, 200, 2
        Λtrue = randn(rng, p, K)
        σ_eps = 0.4
        z = randn(rng, n, K)
        y = Λtrue * z' .+ σ_eps .* randn(rng, p, n)

        fit = fit_gaussian_gllvm(y; K = K)
        sd = latent_score_sd(fit, y; rotate = false)
        @test size(sd) == (n, K)

        Λ = fit.pars.Λ
        Σy = sigma_y_site(fit)
        M_direct = I - Λ' * (Symmetric((Σy + Σy') / 2) \ Λ)   # Cov(z|y) directly, UNROTATED
        sd_direct = sqrt.(max.(diag(M_direct), 0.0))

        for s in 1:n
            @test isapprox(collect(sd[s, :]), sd_direct; atol = 1e-10, rtol = 1e-10)
        end
        # Every row identical (site-independent conditional covariance).
        for s in 2:n
            @test isapprox(collect(sd[s, :]), collect(sd[1, :]); atol = 1e-12)
        end
    end

    # -----------------------------------------------------------------
    # getREsd — deprecated name, forwards to latent_score_sd (maintainer
    # decision docs/dev-log/decisions/2026-09-01-maintainer-decisions-
    # round2-3.md #5). Assert both the depwarn fires and the numeric result
    # agrees exactly with a direct latent_score_sd call.
    # -----------------------------------------------------------------
    @testset "getREsd: deprecated forwarding to latent_score_sd" begin
        rng = MersenneTwister(1)
        p, n, K = 6, 200, 2
        Λtrue = randn(rng, p, K)
        σ_eps = 0.4
        z = randn(rng, n, K)
        y = Λtrue * z' .+ σ_eps .* randn(rng, p, n)

        fit = fit_gaussian_gllvm(y; K = K)
        direct = latent_score_sd(fit, y; rotate = false)
        forwarded = @test_deprecated getREsd(fit, y; rotate = false)
        @test forwarded == direct
    end

    # -----------------------------------------------------------------
    # latent_score_sd — rotate kwarg: DEFAULT must match getLV's default basis
    # (rotate=true, canonical SVD-rotated basis: diag(R'M⁻¹R)), not the
    # unrotated diag(M⁻¹) from the test above. rotate=false must still
    # give the unrotated identity (the sd from the previous testset).
    # -----------------------------------------------------------------
    @testset "latent_score_sd Gaussian: rotate kwarg matches getLV's default basis" begin
        rng = MersenneTwister(1)
        p, n, K = 6, 200, 2
        Λtrue = randn(rng, p, K)
        σ_eps = 0.4
        z = randn(rng, n, K)
        y = Λtrue * z' .+ σ_eps .* randn(rng, p, n)

        fit = fit_gaussian_gllvm(y; K = K)
        Λ = fit.pars.Λ
        Σy = sigma_y_site(fit)
        M_direct = I - Λ' * (Symmetric((Σy + Σy') / 2) \ Λ)
        sd_unrotated = sqrt.(max.(diag(M_direct), 0.0))

        R = GLLVM._svd_rotation(Λ)
        M_rotated = Symmetric(R' * M_direct * R)
        sd_rotated = sqrt.(max.(diag(M_rotated), 0.0))
        @test !isapprox(sd_rotated, sd_unrotated; atol = 1e-8)  # sanity: rotation matters here

        sd_default = latent_score_sd(fit, y)
        sd_explicit_rotate = latent_score_sd(fit, y; rotate = true)
        sd_explicit_norotate = latent_score_sd(fit, y; rotate = false)

        for s in 1:n
            @test isapprox(collect(sd_default[s, :]), sd_rotated; atol = 1e-10, rtol = 1e-10)
            @test isapprox(collect(sd_explicit_rotate[s, :]), sd_rotated; atol = 1e-10, rtol = 1e-10)
            @test isapprox(collect(sd_explicit_norotate[s, :]), sd_unrotated; atol = 1e-10, rtol = 1e-10)
        end
    end

    # -----------------------------------------------------------------
    # latent_score_sd — Poisson dense-Laplace path: vs a direct per-site Hessian
    # inversion built from the textbook Poisson/log-link Fisher weight
    # W_t = μ_t (independent of `_laplace_re_precision_site`'s internals —
    # this recomputes μ and W from scratch with a hand-written formula).
    # -----------------------------------------------------------------
    @testset "latent_score_sd Poisson: vs direct per-site Hessian inversion" begin
        rng = MersenneTwister(2)
        p, n, K = 8, 60, 1
        Λtrue = 0.6 .* randn(rng, p, K)
        β_true = randn(rng, p) .* 0.3
        z = randn(rng, n, K)
        η = β_true .+ Λtrue * z'
        μ = exp.(η)
        Y = [rand(rng, Poisson(μ[t, s])) for t in 1:p, s in 1:n]

        fit = fit_poisson_gllvm(Y; K = K, iterations = 60)
        sd = latent_score_sd(fit, Y)
        @test size(sd) == (n, K)

        Λ̂ = fit.Λ
        β̂ = fit.β
        for s in 1:n
            ẑ = getLV(fit, Y; rotate = false)[s, :]
            ηhat = β̂ .+ Λ̂ * ẑ
            μhat = exp.(ηhat)
            W = μhat                                  # Poisson/log Fisher weight
            A = Λ̂' * Diagonal(W) * Λ̂ + I
            sd_direct = sqrt.(max.(diag(inv(Symmetric(A))), 0.0))
            @test isapprox(collect(sd[s, :]), sd_direct; atol = 1e-8, rtol = 1e-6)
        end
    end

    @testset "latent_score_sd Binomial: predictor-informed (X_lv) fit refuses (honest ArgumentError)" begin
        rng = MersenneTwister(21)
        p, n, K = 5, 60, 1
        Λtrue = 0.6 .* randn(rng, p, K)
        β_true = randn(rng, p) .* 0.2
        X_lv = randn(rng, n, 1)
        α_true = randn(rng, 1, K)
        z = randn(rng, n, K)
        η = β_true .+ Λtrue * (X_lv * α_true .+ z)'
        μ = 1.0 ./ (1.0 .+ exp.(-η))
        Y = [rand(rng) < μ[t, s] ? 1 : 0 for t in 1:p, s in 1:n]

        fit_lv = fit_binomial_gllvm(Y; K = K, X_lv = X_lv, iterations = 20)
        @test GLLVM._has_lv_predictor(fit_lv)
        @test_throws ArgumentError latent_score_sd(fit_lv, Y)
    end

    @testset "latent_score_sd Poisson: AGHQ fit refuses (honest MethodError/ArgumentError)" begin
        rng = MersenneTwister(3)
        p, n, K = 5, 40, 1
        Λtrue = 0.5 .* randn(rng, p, K)
        β_true = randn(rng, p) .* 0.2
        z = randn(rng, n, K)
        η = β_true .+ Λtrue * z'
        μ = exp.(η)
        Y = [rand(rng, Poisson(μ[t, s])) for t in 1:p, s in 1:n]
        fit_aghq = fit_poisson_gllvm(Y; K = K, iterations = 5, aghq = 3)
        @test_throws ArgumentError latent_score_sd(fit_aghq, Y)
    end

    # -----------------------------------------------------------------
    # latent_score_sd — structural guards: refuse (honest ArgumentError) rather than
    # silently returning a wrong "EXACT" answer for fits the closed-form
    # identity does not cover (phylo block, K_W tier, masked Gaussian-record).
    # -----------------------------------------------------------------
    @testset "latent_score_sd Gaussian: structural guards refuse phylo / K_W / masked-record fits" begin
        rng = MersenneTwister(9)
        p, n, K = 4, 100, 1
        Λtrue = randn(rng, p, K)
        σ_eps = 0.4

        # K_W tier.
        Λ_W_true = 0.3 .* randn(rng, p, 1)
        z = randn(rng, n, K)
        w = randn(rng, n, 1)
        y_w = Λtrue * z' .+ Λ_W_true * w' .+ σ_eps .* randn(rng, p, n)
        fit_w = fit_gaussian_gllvm(y_w; K = K, K_W = 1)
        @test fit_w.model.K_W > 0
        @test_throws ArgumentError latent_score_sd(fit_w, y_w)

        # Phylogenetic block (has_phy_unique).
        Σ_phy = Matrix{Float64}(I, p, p)
        σ_phy_true = fill(0.3, p)
        φ = randn(rng, p)
        y_phy = Λtrue * z' .+ σ_eps .* randn(rng, p, n) .+ σ_phy_true .* φ
        fit_phy = fit_gaussian_gllvm(y_phy; K = K, has_phy_unique = true, Σ_phy = Σ_phy)
        @test fit_phy.model.has_phy_unique
        @test_throws ArgumentError latent_score_sd(fit_phy, y_phy)

        # Masked Gaussian-record fit.
        y_plain = Λtrue * z' .+ σ_eps .* randn(rng, p, n)
        mask = trues(p, n)
        mask[1, 1] = false
        fit_masked = fit_gaussian_gllvm(y_plain; K = K, aghq = 3, mask = mask)
        @test GLLVM._has_gaussian_record(fit_masked)
        @test_throws ArgumentError latent_score_sd(fit_masked, y_plain)
    end

    # -----------------------------------------------------------------
    # bootstrap_Sigma — thin driver vs the existing bootstrap CI machinery
    # on the SAME seed: the entrywise `bootstrap_Sigma` result must agree
    # with a direct `bootstrap_ci_derived` call on the same entry.
    # -----------------------------------------------------------------
    @testset "bootstrap_Sigma matches bootstrap_ci_derived (same seed)" begin
        rng = MersenneTwister(4)
        p, n, K = 3, 150, 1
        Λtrue = randn(rng, p, K)
        σ_eps = 0.5
        z = randn(rng, n, K)
        y = Λtrue * z' .+ σ_eps .* randn(rng, p, n)

        fit = fit_gaussian_gllvm(y; K = K)
        tab = bootstrap_Sigma(fit; n_boot = 40, seed = 7, y = y)
        @test length(tab.i) == div(p * (p + 1), 2)

        ref = GLLVM.bootstrap_ci_derived(fit, fb -> sigma_y_site(fb)[1, 1];
                                         n_boot = 40, seed = 7, y = y)
        k = findfirst(t -> tab.i[t] == 1 && tab.j[t] == 1, eachindex(tab.i))
        @test tab.estimate[k] ≈ ref.estimate
        @test isequal(tab.lower[k], ref.lower)
        @test isequal(tab.upper[k], ref.upper)
        @test tab.n_converged[k] == ref.n_converged

        @test_throws ArgumentError bootstrap_Sigma(fit; level = :unit_obs, y = y)
    end

    # -----------------------------------------------------------------
    # tmbprofile_wrapper / profile_targets / profile_phylo_signal —
    # curve monotone-in-|θ−θ̂| near the optimum, and endpoints agree
    # with the existing `profile_ci`.
    # -----------------------------------------------------------------
    @testset "tmbprofile_wrapper: curve + bounds agree with profile_ci" begin
        rng = MersenneTwister(5)
        p, n, K = 4, 120, 1
        Λtrue = randn(rng, p, K)
        σ_eps = 0.4
        z = randn(rng, n, K)
        y = Λtrue * z' .+ σ_eps .* randn(rng, p, n)

        fit = fit_gaussian_gllvm(y; K = K)
        curve = tmbprofile_wrapper(fit, "sigma_eps"; y = y, max_expand = 12)
        bound = profile_ci(fit, "sigma_eps"; y = y, max_expand = 12)

        @test curve.lower === bound.lower || isapprox(curve.lower, bound.lower; atol = 1e-8)
        @test curve.upper === bound.upper || isapprox(curve.upper, bound.upper; atol = 1e-8)
        @test curve.method == bound.method
        @test length(curve.theta) == length(curve.nll)
        @test issorted(curve.theta)

        # nll must be non-increasing as theta -> theta_hat from either side
        # (monotone-in-|θ−θ̂| near the optimum): the point closest to
        # theta_hat on each side has the smallest nll among that side's
        # points.
        ihat = findfirst(==(curve.estimate), curve.theta)
        @test ihat !== nothing
        left = [(curve.theta[k], curve.nll[k]) for k in 1:ihat]
        right = [(curve.theta[k], curve.nll[k]) for k in ihat:length(curve.theta)]
        if length(left) > 1
            # sorted ascending in theta already; nll should be
            # non-increasing walking toward theta_hat (i.e. non-decreasing
            # walking AWAY from theta_hat, from left to right up to ihat).
            for k in 1:(length(left) - 1)
                @test left[k][2] >= left[k + 1][2] - 1e-6
            end
        end
        if length(right) > 1
            for k in 1:(length(right) - 1)
                @test right[k][2] <= right[k + 1][2] + 1e-6
            end
        end
    end

    @testset "tmbprofile_wrapper refuses masked/AGHQ Gaussian-record fits (no mixed surfaces)" begin
        rng = MersenneTwister(3)
        p, n, K = 4, 100, 1
        Λtrue = randn(rng, p, K)
        σ_eps = 0.4
        z = randn(rng, K, n)
        y = Λtrue * z .+ σ_eps .* randn(rng, p, n)
        mask = trues(p, n); mask[1, 1] = false
        fit_masked = fit_gaussian_gllvm(y; K = K, aghq = 3, mask = mask)
        @test GLLVM._has_gaussian_record(fit_masked)
        @test_throws ArgumentError tmbprofile_wrapper(fit_masked, "sigma_eps"; y = y)
        @test_throws ArgumentError tmbprofile_wrapper(fit_masked, 1; y = y)
    end

    @testset "profile_targets batches tmbprofile_wrapper" begin
        rng = MersenneTwister(6)
        p, n, K = 3, 100, 1
        Λtrue = randn(rng, p, K)
        σ_eps = 0.4
        z = randn(rng, n, K)
        y = Λtrue * z' .+ σ_eps .* randn(rng, p, n)
        fit = fit_gaussian_gllvm(y; K = K)

        out = profile_targets(fit, ["sigma_eps"]; y = y, max_expand = 10)
        @test haskey(out, "sigma_eps")
        direct = tmbprofile_wrapper(fit, "sigma_eps"; y = y, max_expand = 10)
        @test out["sigma_eps"].lower === direct.lower ||
              isapprox(out["sigma_eps"].lower, direct.lower; atol = 1e-8)
    end

    @testset "profile_phylo_signal: scoped to sigma_phy[t], requires has_phy_unique" begin
        rng = MersenneTwister(7)
        p, n, K = 4, 80, 1
        # Non-phylo fit: must refuse.
        Λtrue = randn(rng, p, K)
        σ_eps = 0.4
        z = randn(rng, n, K)
        y = Λtrue * z' .+ σ_eps .* randn(rng, p, n)
        fit_nophy = fit_gaussian_gllvm(y; K = K)
        @test_throws ArgumentError profile_phylo_signal(fit_nophy, 1; y = y)

        # Phylo (has_phy_unique) fit: succeeds and matches the equivalent
        # tmbprofile_wrapper("sigma_phy[t]") call.
        Σ_phy = Matrix{Float64}(I, p, p)
        σ_phy_true = fill(0.3, p)
        φ = Σ_phy * randn(rng, p)
        y2 = Λtrue * z' .+ σ_eps .* randn(rng, p, n)
        y2 .+= σ_phy_true .* φ
        fit_phy = fit_gaussian_gllvm(y2; K = K, has_phy_unique = true, Σ_phy = Σ_phy)
        curve = profile_phylo_signal(fit_phy, 1; y = y2, Σ_phy = Σ_phy, max_expand = 10)
        direct = tmbprofile_wrapper(fit_phy, "sigma_phy[1]"; y = y2, Σ_phy = Σ_phy, max_expand = 10)
        @test curve.lower === direct.lower || isapprox(curve.lower, direct.lower; atol = 1e-8)
        @test curve.estimate == direct.estimate

        @test_throws ArgumentError profile_phylo_signal(fit_phy, p + 1; y = y2, Σ_phy = Σ_phy)
    end
end
