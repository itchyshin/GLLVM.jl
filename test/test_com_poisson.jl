using GLLVM, Test, Random, Distributions, Statistics, LinearAlgebra

# Direct (latent-free) CMP loglik over all (t,s): the Λ=0 reference.
_indep_compoisson_loglik(Y, β, ν) = sum(
    GLLVM.compoisson_logpdf(Y[t, s], β[t], ν)
    for t in axes(Y, 1), s in axes(Y, 2))

@testset "Conway-Maxwell-Poisson family" begin

    @testset "ν=1 ⇒ Poisson marginal (KEY ANCHOR)" begin
        Random.seed!(21)
        p, n, K = 4, 60, 1
        β = randn(p) .* 0.5 .+ 1.0          # log-rates around exp(1) ≈ 2.7
        Λ = reshape(0.6 .* randn(p), p, K)  # Λ ≠ 0
        # plausible Poisson-ish counts at η = β
        Y = [rand(Poisson(exp(β[t]))) for t in 1:p, s in 1:n]

        cmp = GLLVM.compoisson_marginal_loglik_laplace(Y, Λ, β, 1.0)
        pois = GLLVM.poisson_marginal_loglik_laplace(Y, Λ, β)
        @test isfinite(cmp)
        @test abs(cmp - pois) ≤ 1e-6
    end

    @testset "Λ=0 exact reduction (machine precision)" begin
        Random.seed!(22)
        p, n, K = 4, 60, 2
        β = randn(p) .* 0.4 .+ 0.8
        Λ0 = zeros(p, K)
        Y = [rand(Poisson(exp(β[t]))) for t in 1:p, s in 1:n]
        for ν in (0.7, 1.0, 1.5)
            lap = GLLVM.compoisson_marginal_loglik_laplace(Y, Λ0, β, ν)
            direct = _indep_compoisson_loglik(Y, β, ν)
            @test lap ≈ direct atol = 1e-8
        end
    end

    @testset "scalar logpdf: ν=1 matches Poisson; logZ=λ" begin
        for (y, η) in ((0, 0.5), (3, 1.2), (7, 2.0))
            λ = exp(η)
            @test GLLVM.compoisson_logpdf(y, η, 1.0) ≈ logpdf(Poisson(λ), y) atol = 1e-10
            @test GLLVM.compoisson_logz(η, 1.0) ≈ λ atol = 1e-8   # Z = e^λ at ν=1
        end
    end

    @testset "underdispersion smoke fit" begin
        Random.seed!(23)
        p, n, K = 4, 60, 1
        β = randn(p) .* 0.4 .+ 1.0
        Λtrue = reshape(0.7 .* randn(p), p, K)
        # CMP draws are hard; fit Poisson-generated data and check it runs and
        # ν̂ lands near 1 within a factor (these counts are exactly equidispersed).
        Z = randn(K, n)
        Y = [rand(Poisson(exp(β[t] + dot(Λtrue[t, :], Z[:, s])))) for t in 1:p, s in 1:n]

        fit = GLLVM.fit_compoisson_gllvm(Y; K = K, iterations = 40)
        @test isfinite(fit.loglik)
        @test fit.ν > 0
        @test 0.2 ≤ fit.ν ≤ 5.0                       # near 1 within a factor
        # loadings recovered up to sign/rotation: Gram correlation > 0.3
        g_true = vec(Λtrue * Λtrue')
        g_hat  = vec(fit.Λ * fit.Λ')
        @test abs(cor(g_true, g_hat)) > 0.3
    end

    @testset "fit_gllvm reaches no-X COM-Poisson via the COMPoisson() marker" begin
        Random.seed!(1608)
        p, K, n = 4, 1, 60
        β = randn(p) .* 0.4 .+ 1.0
        Λtrue = reshape(0.7 .* randn(p), p, K)
        Z = randn(K, n)
        Y = [rand(Poisson(exp(β[t] + dot(Λtrue[t, :], Z[:, s])))) for t in 1:p, s in 1:n]

        @test COMPoisson().ν == 1.0

        fit = fit_gllvm(Y; family = COMPoisson(), K = K, iterations = 40)
        @test fit isa COMPoissonFit
        # FIXED 2026-08-26. Root cause was `compoisson_logz`'s naive `Σ exp(logterm)`
        # overflowing near the series' own mode; rewritten as a streaming log-sum-exp
        # (com_poisson.jl:76). Was: iterations=0, marginal NaN.
        @test fit.converged
        @test isfinite(fit.loglik)
        @test fit.iterations > 0
        direct = fit_compoisson_gllvm(Y; K = K, iterations = 40)
        @test fit.loglik ≈ direct.loglik atol = 1e-8
        @test fit.ν ≈ direct.ν atol = 1e-8

        # Marker ν is a tag payload — never read, never a starting value.
        tagged = fit_gllvm(Y; family = COMPoisson(9.0), K = K, iterations = 40)
        @test tagged.loglik ≈ fit.loglik atol = 1e-8
        @test tagged.ν ≈ fit.ν atol = 1e-8

        # No-X `@formula` inherits the arm via the q == 0 fall-through.
        ff = gllvm(@formula(y ~ 1), Y, (; temp = randn(n));
                   family = COMPoisson(), K = K, iterations = 40)
        @test ff isa COMPoissonFit
        @test ff.loglik ≈ direct.loglik atol = 1e-8
    end
end


@testset "compoisson_logz asymptotic branch (the retired cap limitation)" begin
    # The series' mode j* = exp(logλ/ν); past 80% of _CMP_LOGZ_CAP the Shmueli
    # asymptotic takes over. Crossover validation: on the band where BOTH
    # branches are computable, they must agree tightly.
    for (logl, nu, rtol) in ((7.8, 1.0, 1e-12), (8.9, 1.0, 1e-12),
                             (16.5, 2.0, 1e-7), (8.6, 1.3, 1e-6))
        jstar = exp(logl / nu)
        @test jstar < 0.8 * GLLVM._CMP_LOGZ_CAP      # series branch is the one tested
        series = GLLVM.compoisson_logz(logl, nu)
        asym = nu * jstar - ((nu - 1) / (2nu)) * logl -
               ((nu - 1) / 2) * log(2π) - log(nu) / 2
        @test isapprox(series, asym; rtol = rtol)
    end
    # ν = 1 anchor holds THROUGH the asymptotic branch: log Z = λ exactly.
    for logl in (9.5, 12.0, 20.0)                     # j* = 13360, 1.6e5, 4.9e8 — all past the cap
        @test GLLVM.compoisson_logz(logl, 1.0) ≈ exp(logl) rtol = 1e-12
    end
    # And the value is monotone across the branch switch (no cliff): a fine
    # grid spanning the 0.8·cap boundary must be strictly increasing in logλ —
    # at the exact anchor ν = 1 AND at a genuinely-asymptotic ν
    # (the 2026-08-28 review flagged that ν = 1 alone doesn't test the ν ≠ 1
    # branch terms across the switch; boundary logλ = ν·log(0.8·cap)).
    vals = [GLLVM.compoisson_logz(x, 1.0) for x in 8.90:0.01:9.10]
    @test all(diff(vals) .> 0)
    vals2 = [GLLVM.compoisson_logz(x, 2.0) for x in 17.85:0.01:18.10]
    @test all(diff(vals2) .> 0)
    # Integer arguments must not throw (exported function; a review caught the
    # asymptotic guard computing T(0.8) with T = Int64 → InexactError).
    @test GLLVM.compoisson_logz(2, 1) == GLLVM.compoisson_logz(2.0, 1.0)
    @test GLLVM.compoisson_logz(9, 1) == GLLVM.compoisson_logz(9.0, 1.0)
end
