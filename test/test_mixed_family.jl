# Tests for the mixed-family GLLVM (A2b headline; src/families/mixed.jl).
#
# A single shared latent block Λ drives p traits, each with its OWN response
# family/link, yielding a true cross-family trait correlation on the latent scale.
#
# Blocks:
#   (a) a small mixed fit [Normal, Poisson, Binomial] fits & converges;
#   (b) GAUSSIAN REDUCTION: an all-Normal mixed marginal matches the closed-form
#       gaussian_marginal_loglik to machine precision (Laplace is exact for a
#       Gaussian integrand), and an all-Normal mixed FIT recovers the
#       fit_gaussian_gllvm correlation when the data is generated with a shared σ;
#   (c) FD-gradient check of the packed mixed marginal ≤ 1e-6 (central differences
#       of the pure-value objective) — the v1 correctness gate for the direct
#       ForwardDiff gradient the fitter uses;
#   (d) correlation(::MixedFamilyFit) is symmetric / unit-diagonal / in [-1, 1].
#
# Self-runnable: `julia --project=. test/test_mixed_family.jl`.

using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions, ForwardDiff

# Central-difference gradient of a scalar objective (same helper used by
# test_family_forwarddiff_gradients.jl).
function _mixed_central_difference_gradient(f, theta; h = 1e-6)
    g = similar(theta)
    @inbounds for i in eachindex(theta)
        step = h * max(1.0, abs(theta[i]))
        tp = copy(theta); tp[i] += step
        tm = copy(theta); tm[i] -= step
        g[i] = (f(tp) - f(tm)) / (2 * step)
    end
    return g
end

# Structural checks on a correlation matrix.
function _check_correlation(R, p)
    @test size(R) == (p, p)
    @test all(isfinite, R)
    @test maximum(abs.(R - R')) < 1e-10
    for t in 1:p
        @test isapprox(R[t, t], 1.0; atol = 1e-12)
    end
    for j in 1:p, i in 1:p
        @test -1 - 1e-10 ≤ R[i, j] ≤ 1 + 1e-10
    end
end

@testset "mixed-family GLLVM (A2b)" begin

    # -----------------------------------------------------------------------
    # (a) [Normal, Poisson, Binomial] fits & converges; one shared latent block.
    # -----------------------------------------------------------------------
    @testset "(a) [Normal, Poisson, Binomial] fit converges" begin
        Random.seed!(20260610)
        p, n, K = 3, 120, 1
        # Generate from one shared latent factor z_s ~ N(0,1).
        z = randn(n)
        λ = [0.8, 0.6, 1.0]
        β = [0.5, log(3.0), 0.2]
        Y = Matrix{Float64}(undef, p, n)
        for s in 1:n
            η1 = β[1] + λ[1] * z[s]                 # Normal (identity)
            Y[1, s] = η1 + 0.5 * randn()
            η2 = β[2] + λ[2] * z[s]                 # Poisson (log)
            Y[2, s] = float(rand(Poisson(exp(η2))))
            η3 = β[3] + λ[3] * z[s]                 # Binomial (logit), Bernoulli
            Y[3, s] = float(rand(Bernoulli(1 / (1 + exp(-η3)))))
        end
        families = [Normal(), Poisson(), Binomial()]
        fit = fit_mixed_gllvm(Y; families = families, K = K)
        @test fit isa MixedFamilyFit
        @test fit.converged
        @test isfinite(fit.loglik)
        @test size(fit.Λ) == (p, K)
        @test length(fit.β) == p
        # Layout: only the Normal trait carries a dispersion (σ).
        @test fit.disp_index == [1, 0, 0]
        @test fit.n_disp == 1
        @test isfinite(fit.dispersion[1]) && fit.dispersion[1] > 0
        @test isnan(fit.dispersion[2]) && isnan(fit.dispersion[3])

        # Headline output: cross-family latent-scale correlation is well-formed.
        R = correlation(fit, Y)
        _check_correlation(R, p)
        c2 = communality(fit, Y)
        @test all(0 .≤ c2 .≤ 1 + 1e-10)
    end

    # -----------------------------------------------------------------------
    # (b1) Gaussian reduction (VALUE level, exact): all-Normal mixed marginal ==
    #      closed-form gaussian_marginal_loglik at the same parameters.
    # -----------------------------------------------------------------------
    @testset "(b1) all-Normal marginal == gaussian_marginal_loglik (exact)" begin
        Random.seed!(424242)
        p, n, K = 4, 30, 2
        # Lower-triangular Λ (strict upper = 0): this is the packed rr convention,
        # so unpack_lambda(pack_lambda(Λ)) is an exact round-trip and the direct
        # and packed marginals see the identical loadings.
        Λ = [i >= j ? (0.5 * randn()) : 0.0 for i in 1:p, j in 1:K]
        β = 0.3 .* randn(p)
        σ = 0.7
        Y = β .+ Λ * randn(K, n) .+ σ .* randn(p, n)

        families = [Normal() for _ in 1:p]
        links = [IdentityLink() for _ in 1:p]
        fams_t = [Normal(0.0, σ) for _ in 1:p]   # σ baked into the marker
        N = ones(Int, p, n)

        ll_mixed = GLLVM.mixed_marginal_loglik_laplace(fams_t, links, Y, N, Λ, β)
        # gaussian_marginal_loglik assumes zero-mean y ⇒ subtract β.
        ll_gauss = GLLVM.gaussian_marginal_loglik(Y .- β, Λ, σ)
        @test isapprox(ll_mixed, ll_gauss; rtol = 1e-9, atol = 1e-7)

        # And via the packed entry point (β; vec(Λ); log σ tail) — same value.
        disp_index, n_disp = GLLVM._mixed_family_layout(families)
        @test n_disp == p
        θ = vcat(β, GLLVM.pack_lambda(Λ), fill(log(σ), p))
        ll_packed = GLLVM._mixed_marginal_loglik_packed(
            θ, Y, N, p, K, collect(Any, families), links, disp_index)
        @test isapprox(ll_packed, ll_gauss; rtol = 1e-9, atol = 1e-7)
    end

    # -----------------------------------------------------------------------
    # (b2) Gaussian reduction (FIT level): an all-Normal mixed fit recovers the
    #      fit_gaussian_gllvm correlation when data has a shared σ. The mixed
    #      model has per-trait β + per-trait σ (strictly more flexible than the
    #      shared-σ, zero-intercept Gaussian fit), so loglik is ≥ the Gaussian
    #      fit's; the latent-scale correlation (rotation-invariant) should match
    #      closely.
    # -----------------------------------------------------------------------
    @testset "(b2) all-Normal fit ≈ fit_gaussian_gllvm correlation" begin
        Random.seed!(987654)
        p, n, K = 4, 300, 2
        Λtrue = [1.0 0.0; 0.7 0.9; -0.5 0.4; 0.3 -0.8]
        σ = 0.6
        Ycen = Λtrue * randn(K, n) .+ σ .* randn(p, n)   # zero-mean (no intercept)

        gfit = fit_gaussian_gllvm(Ycen; K = K)
        Rg = correlation(gfit)

        families = [Normal() for _ in 1:p]
        mfit = fit_mixed_gllvm(Ycen; families = families, K = K)
        @test mfit.converged
        # Mixed loglik ≥ Gaussian loglik (more parameters), up to optimiser slack.
        @test mfit.loglik ≥ gfit.logLik - 1e-4
        Rm = correlation(mfit, Ycen)
        _check_correlation(Rm, p)
        # Off-diagonal latent correlations agree to a loose tolerance.
        offdiff = maximum(abs.(Rm .- Rg) .- Diagonal(fill(Inf, p)))  # ignore diag
        @test offdiff < 0.1
    end

    # -----------------------------------------------------------------------
    # (c) FD-gradient gate (≤ 1e-6): direct ForwardDiff gradient of the packed
    #     mixed marginal matches central differences on a mixed Y.
    # -----------------------------------------------------------------------
    @testset "(c) FD-gradient ≤ 1e-6 (mixed marginal)" begin
        Random.seed!(20260531)
        p, n, K = 4, 8, 1
        families = [Poisson(), NegativeBinomial(), Binomial(), Beta()]
        links = [LogLink(), LogLink(), LogitLink(), LogitLink()]
        disp_index, n_disp = GLLVM._mixed_family_layout(families)
        @test disp_index == [0, 1, 0, 2]
        @test n_disp == 2

        N = fill(5, p, n)
        Y = Matrix{Float64}(undef, p, n)
        Y[1, :] = float.(rand(Poisson(3.0), n))
        Y[2, :] = float.(rand(NegativeBinomial(8.0, 8.0 / (8.0 + 3.0)), n))
        Y[3, :] = float.(rand(Binomial(5, 0.55), n))
        Y[4, :] = rand(Beta(3.0, 3.0), n)

        rr = GLLVM.rr_theta_len(p, K)
        λ0 = GLLVM.pack_lambda(0.1 .* randn(p, K))
        β0 = [log(3.0), log(3.0), 0.2, 0.2]
        logdisp0 = [log(8.0), log(6.0)]   # NB r, Beta φ
        θ0 = vcat(β0, λ0, logdisp0)

        fams_bare = collect(Any, families)
        f = θ -> GLLVM._mixed_marginal_loglik_packed(
            θ, Y, N, p, K, fams_bare, links, disp_index; tol = 1e-12)
        gad = ForwardDiff.gradient(f, θ0)
        gfd = _mixed_central_difference_gradient(f, θ0)
        @test all(isfinite, gad)
        @test all(isfinite, gfd)
        maxabs = maximum(abs.(gad .- gfd))
        denom = max(1.0, maximum(abs.(gfd)))
        @info "mixed FD-gradient check" max_abs_err=maxabs max_rel_err=(maxabs / denom)
        @test maxabs ≤ 1e-6
    end

    # -----------------------------------------------------------------------
    # (d) correlation(::MixedFamilyFit) symmetric / unit-diagonal / in [-1, 1]
    #     on a four-family mixed fit.
    # -----------------------------------------------------------------------
    @testset "(d) correlation well-formed (4-family mixed fit)" begin
        Random.seed!(20260609)
        p, n, K = 4, 150, 1
        z = randn(n)
        λ = [0.9, 0.7, 1.0, 0.5]
        β = [log(4.0), 0.3, 0.1, log(2.0)]
        N = fill(4, p, n)
        Y = Matrix{Float64}(undef, p, n)
        for s in 1:n
            Y[1, s] = float(rand(Poisson(exp(β[1] + λ[1] * z[s]))))           # Poisson
            μ2 = 1 / (1 + exp(-(β[2] + λ[2] * z[s])))
            Y[2, s] = float(rand(Binomial(4, μ2)))                            # Binomial
            μ3 = 1 / (1 + exp(-(β[3] + λ[3] * z[s])))
            Y[3, s] = clamp(rand(Beta(μ3 * 10, (1 - μ3) * 10)), 1e-4, 1 - 1e-4) # Beta
            Y[4, s] = float(rand(Gamma(3.0, exp(β[4] + λ[4] * z[s]) / 3.0)))  # Gamma
        end
        families = [Poisson(), Binomial(), Beta(), Gamma()]
        fit = fit_mixed_gllvm(Y; families = families, K = K, N = N)
        @test isfinite(fit.loglik)
        @test fit.disp_index == [0, 0, 1, 2]   # Beta φ, Gamma α carry dispersion
        Σ = sigma_y_site(fit, Y; N = N)
        @test maximum(abs.(Σ - Σ')) < 1e-10
        @test minimum(eigvals(Symmetric(Σ))) > -1e-8
        R = correlation(fit, Y; N = N)
        _check_correlation(R, p)
    end

    # -----------------------------------------------------------------------
    # (e) NA-aware FIML on the mixed path (issue #27 slice 1). With all-Normal
    #     families this IS exact Gaussian FIML: the Normal working weight 1/σ² is
    #     constant in z, so the Laplace approximation is exact, and dropping a
    #     missing cell (0 score, 0 weight, skipped in ℓ) is algebraically identical
    #     to running on the observed submatrices ⇒ the per-site marginal equals the
    #     textbook N(y_obs; β_obs, Λ_obs Λ_obsᵀ + diag(σ²_obs)).
    # -----------------------------------------------------------------------
    @testset "(e) NA-aware FIML (all-Normal == observed-submatrix Gaussian FIML)" begin
        # (e1) Complete-data equivalence: a missing-typed Y with NO NAs reproduces the
        # dense all-Normal marginal == gaussian_marginal_loglik (guards are no-ops).
        Random.seed!(525252)
        p, n, K = 4, 60, 2
        Λ = [i >= j ? (0.5 * randn()) : 0.0 for i in 1:p, j in 1:K]
        β = 0.3 .* randn(p)
        σ = 0.7
        Y = β .+ Λ * randn(K, n) .+ σ .* randn(p, n)
        families = [Normal() for _ in 1:p]
        links = [IdentityLink() for _ in 1:p]
        fams_t = [Normal(0.0, σ) for _ in 1:p]
        N = ones(Int, p, n)
        Ym0 = Matrix{Union{Missing, Float64}}(Y)              # missing-typed, no NAs
        ll_dense = GLLVM.mixed_marginal_loglik_laplace(fams_t, links, Y,   N, Λ, β)
        ll_na0   = GLLVM.mixed_marginal_loglik_laplace(fams_t, links, Ym0, N, Λ, β)
        @test isapprox(ll_na0, ll_dense; atol = 1e-9)
        @test isapprox(ll_na0, GLLVM.gaussian_marginal_loglik(Y .- β, Λ, σ);
                       rtol = 1e-9, atol = 1e-7)
        fit_d = fit_mixed_gllvm(Y;   families = families, K = K)
        fit_m = fit_mixed_gllvm(Ym0; families = families, K = K)
        @test isapprox(fit_m.loglik, fit_d.loglik; atol = 1e-6)
        @test maximum(abs.(fit_m.β .- fit_d.β)) < 1e-5
        @test maximum(abs.(fit_m.Λ .- fit_d.Λ)) < 1e-5

        # (e2) NA marginal == hand-rolled observed-submatrix Gaussian FIML, with
        # DISTINCT per-trait σ_t so every masked site is genuinely its own submatrix.
        σvec = [0.5, 0.8, 0.6, 0.9]
        famsσ = [Normal(0.0, σvec[t]) for t in 1:p]
        Ym = Matrix{Union{Missing, Float64}}(Y)
        Ym[1, 1] = missing; Ym[4, 1] = missing               # site 1 drops traits 1,4
        Ym[2, 5] = missing                                   # scattered single drops
        Ym[3, 8] = missing
        ll_mix = GLLVM.mixed_marginal_loglik_laplace(famsσ, links, Ym, N, Λ, β)
        ref = 0.0
        for s in 1:n
            obs = [t for t in 1:p if !ismissing(Ym[t, s])]
            Λo = Λ[obs, :]
            Σo = Λo * Λo' + Diagonal(σvec[obs] .^ 2)
            ro = Float64[Ym[t, s] - β[t] for t in obs]
            ref += -0.5 * (length(obs) * log(2π) + logdet(Σo) + ro' * (Σo \ ro))
        end
        @test isapprox(ll_mix, ref; atol = 1e-8)

        # (e3) NA recovery (~15% missing): the FIML fit recovers the complete-data fit.
        Random.seed!(636363)
        p3, n3, K3 = 6, 800, 2
        Λ3 = [i >= j ? (0.5 * randn()) : 0.0 for i in 1:p3, j in 1:K3]
        β3 = 0.3 .* randn(p3)
        Y3 = β3 .+ Λ3 * randn(K3, n3) .+ 0.7 .* randn(p3, n3)
        fams3 = [Normal() for _ in 1:p3]
        fit_full = fit_mixed_gllvm(Y3; families = fams3, K = K3)
        Y3m = Matrix{Union{Missing, Float64}}(Y3)
        rng = MersenneTwister(6364)
        for idx in eachindex(Y3m)
            rand(rng) < 0.15 && (Y3m[idx] = missing)
        end
        fit_na = fit_mixed_gllvm(Y3m; families = fams3, K = K3)
        @test fit_na.converged
        @test isfinite(fit_na.loglik)
        @test maximum(abs.(fit_na.β .- fit_full.β)) < 0.3
        @test cor(vec(fit_na.Λ * fit_na.Λ'), vec(fit_full.Λ * fit_full.Λ')) > 0.8
        _check_correlation(correlation(fit_na, Y3m), p3)

        # (e4) Edge cases: a fully-missing site (marginal = 0, mode = 0, A = I) and a
        # fully-missing trait must not crash; the observed traits stay finite.
        Random.seed!(747474)
        p4, n4, K4 = 5, 120, 1
        Λ4 = reshape(0.4 .* randn(p4), p4, K4)
        β4 = 0.2 .* randn(p4)
        Y4 = β4 .+ Λ4 * randn(K4, n4) .+ 0.6 .* randn(p4, n4)
        Y4m = Matrix{Union{Missing, Float64}}(Y4)
        Y4m[:, 1] .= missing                                 # fully-missing site
        Y4m[2, :] .= missing                                 # fully-missing trait
        fit4 = fit_mixed_gllvm(Y4m; families = [Normal() for _ in 1:p4], K = K4)
        @test isfinite(fit4.loglik)
        @test all(isfinite, fit4.β[[1, 3, 4, 5]])
        @test size(fit4.Λ) == (p4, K4)
    end
end
