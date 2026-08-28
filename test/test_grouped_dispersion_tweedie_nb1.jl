using GLLVM, Test, Random, Distributions, Statistics, LinearAlgebra

# Grouped / species-specific dispersion for NB1 (linear-variance φ) and Tweedie
# (dispersion φ, SHARED power), completing the per-species-dispersion set. Anchors:
#   1. EXACT REDUCTION: a constant per-species dispersion equals the shared-dispersion
#      scalar marginal to machine precision — the grouped path reduces exactly. This
#      is a single cheap marginal eval (NO fit).
#   2. ONE tiny per-species smoke fit each, asserting finite loglik + a positive
#      length-G dispersion vector. Tweedie's marginal is expensive, so the Tweedie
#      smoke fit is kept very small and run ONCE only.

@testset "Grouped / species-specific NB1 & Tweedie dispersion (disp.group)" begin

    @testset "NB1: constant φvec == shared-φ marginal (exact)" begin
        Random.seed!(701)
        p, K, n = 5, 1, 60
        β = 0.3 .* randn(p)
        Λ = 0.4 .* randn(p, K)
        φ = 1.5
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            η = β .+ Λ * randn(K)
            μ = exp.(η)
            for t in 1:p
                # NB1: r = μ/φ, success prob = 1/(1+φ)
                Y[t, s] = rand(NegativeBinomial(μ[t] / φ, 1 / (1 + φ)))
            end
        end
        ll_shared  = GLLVM.nb1_marginal_loglik_laplace(Y, Λ, β, φ)
        ll_grouped = GLLVM.nb1_grouped_marginal_loglik_laplace(Y, Λ, β, fill(φ, p))
        @test ll_grouped ≈ ll_shared atol = 1e-10
        # mixed per-species dispersion also evaluates finitely.
        @test isfinite(GLLVM.nb1_grouped_marginal_loglik_laplace(Y, Λ, β, [0.5, 1.0, 1.5, 2.0, 3.0]))
    end

    @testset "Tweedie: constant φvec == shared-φ marginal (exact)" begin
        Random.seed!(702)
        p, K, n = 4, 1, 40
        β = 0.3 .* randn(p)
        Λ = 0.3 .* randn(p, K)
        φ = 1.2
        power = 1.5
        # Crude compound Poisson–Gamma draws ≥ 0 with a point mass at 0.
        Y = Matrix{Float64}(undef, p, n)
        for s in 1:n
            η = β .+ Λ * randn(K)
            μ = exp.(η)
            for t in 1:p
                λ = μ[t]^(2 - power) / (φ * (2 - power))
                Npois = rand(Poisson(λ))
                if Npois == 0
                    Y[t, s] = 0.0
                else
                    shape = (2 - power) / (power - 1)
                    scale = φ * (power - 1) * μ[t]^(power - 1)
                    Y[t, s] = sum(rand(Gamma(shape, scale)) for _ in 1:Npois)
                end
            end
        end
        # Same FIXED power passed to both — the key cheap correctness check.
        # `tweedie_grouped_marginal_loglik_laplace` has no `hessian` selector at
        # all (unconditional Fisher; see the header comment in
        # grouped_dispersion.jl), while the shared route's DEFAULT flipped to
        # :observed 2026-08-28 (maintainer decision batch). So the exact
        # reduction now holds against the shared route's `hessian = :fisher`
        # call, not its default — pin that explicitly rather than let this
        # test silently encode the pre-2026-08-28 default.
        ll_shared  = GLLVM.tweedie_marginal_loglik_laplace(Y, Λ, β, φ, power; hessian = :fisher)
        ll_grouped = GLLVM.tweedie_grouped_marginal_loglik_laplace(Y, Λ, β, fill(φ, p), power)
        @test ll_grouped ≈ ll_shared atol = 1e-10
        # mixed per-species dispersion also evaluates finitely.
        @test isfinite(GLLVM.tweedie_grouped_marginal_loglik_laplace(Y, Λ, β, [0.8, 1.2, 1.5, 2.0], power))
    end

    @testset "fit_nb1_gllvm_grouped: per-species smoke (group = 1:p)" begin
        Random.seed!(703)
        p, K, n = 4, 1, 50
        β = 0.3 .* randn(p)
        Λ = 0.3 .* randn(p, K)
        φtrue = 1.0
        Z = randn(K, n)
        η = β .+ Λ * Z
        μ = exp.(η)
        Y = [rand(NegativeBinomial(μ[t, i] / φtrue, 1 / (1 + φtrue))) for t in 1:p, i in 1:n]

        fg = fit_nb1_gllvm_grouped(Y; K = K, iterations = 40)  # default group = 1:p
        @test fg isa GLLVM.NB1GroupedFit
        @test length(fg.φ) == p
        @test all(fg.φ .> 0)
        @test isfinite(fg.loglik)
        @test fg.group == collect(1:p)
    end

    # No-X public surfaces for NB1 (Identity 2026-08-16, C1–C4). Both `fit_gllvm`
    # and `@formula` with no covariates must reach the SAME per-trait engine the
    # bridge and the `+ X` route already use — the coerce, not a bare shared-φ arm.
    @testset "NB1 no-X public surfaces: fit_gllvm and @formula" begin
        Random.seed!(705)
        p, K, n = 4, 1, 50
        β = 0.3 .* randn(p)
        Λ = 0.3 .* randn(p, K)
        φtrue = 1.0
        Z = randn(K, n)
        μ = exp.(β .+ Λ * Z)
        Y = [rand(NegativeBinomial(μ[t, i] / φtrue, 1 / (1 + φtrue))) for t in 1:p, i in 1:n]

        # C2: the per-trait coerce, identical to calling the grouped fitter directly.
        fu = fit_gllvm(Y; family = NB1(), K = K, iterations = 40)
        direct = fit_nb1_gllvm_grouped(Y; K = K, group = collect(1:p), iterations = 40)
        @test fu isa GLLVM.NB1GroupedFit
        @test length(fu.φ) == p && all(fu.φ .> 0)
        @test fu.group == collect(1:p)
        @test fu.loglik ≈ direct.loglik atol = 1e-8

        # C1: the marker's φ is a tag payload — never read, never an init.
        @test fit_gllvm(Y; family = NB1(7.5), K = K, iterations = 40).loglik ≈ fu.loglik atol = 1e-8

        # C2: shared φ stays reachable only through the named fitter, and differs.
        shared = fit_nb1_gllvm(Y; K = K, iterations = 40)
        @test shared isa GLLVM.NB1Fit
        @test shared.φ isa Real

        # An explicit group vector routes the same way; :species is the default.
        @test fit_gllvm(Y; family = NB1(), K = K, disp_group = :species,
                        iterations = 40).loglik ≈ fu.loglik atol = 1e-8

        # The `@formula` no-X surface opens by fall-through to `fit_gllvm`.
        ff = gllvm(@formula(y ~ 1), Y, (; temp = randn(n)); family = NB1(), K = K,
                   iterations = 40)
        @test ff isa GLLVM.NB1GroupedFit
        @test ff.loglik ≈ fu.loglik atol = 1e-8
    end

    @testset "fit_tweedie_gllvm_grouped: tiny per-species smoke (group = 1:p)" begin
        Random.seed!(704)
        p, K, n = 3, 1, 40
        β = 0.3 .* randn(p)
        Λ = 0.3 .* randn(p, K)
        φtrue = 1.2
        power = 1.5
        Y = Matrix{Float64}(undef, p, n)
        for i in 1:n
            ηv = β .+ Λ * randn(K)
            μ = exp.(ηv)
            for t in 1:p
                λ = μ[t]^(2 - power) / (φtrue * (2 - power))
                Npois = rand(Poisson(λ))
                if Npois == 0
                    Y[t, i] = 0.0
                else
                    shape = (2 - power) / (power - 1)
                    scale = φtrue * (power - 1) * μ[t]^(power - 1)
                    Y[t, i] = sum(rand(Gamma(shape, scale)) for _ in 1:Npois)
                end
            end
        end

        # ONE small Tweedie fit only — keep CI cheap.
        fg = fit_tweedie_gllvm_grouped(Y; K = K, iterations = 25)  # default group = 1:p
        @test fg isa GLLVM.TweedieGroupedFit
        @test length(fg.φ) == p
        @test all(fg.φ .> 0)
        @test isfinite(fg.loglik)
        @test 1.0 ≤ fg.power ≤ 2.0
        @test fg.group == collect(1:p)
    end
end
