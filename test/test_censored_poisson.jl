using GLLVM, Test, Random, Distributions, ForwardDiff, LinearAlgebra

# Local wiring until the admit conductor adds the include / export / runtests entry.
if !isdefined(GLLVM, :CensoredPoisson)
    Base.include(GLLVM, joinpath(@__DIR__, "..", "src", "families", "censored_poisson.jl"))
end

@testset "censored_poisson family (Julia-forward)" begin

    @testset "stable μ≪C evaluation (ENGINE-GATE 1)" begin
        μ, C = 0.3, 30
        logS = GLLVM._censored_poisson_logS(μ, C)
        @test isfinite(logS)
        @test logS ≈ logcdf(Gamma(C, 1.0), μ) atol = 1e-12
        # Naive survival collapses in this regime — document the hazard.
        naive = try
            log1p(-cdf(Poisson(μ), C - 1))
        catch
            -Inf
        end
        @test !isfinite(naive) || naive < -1e6
        @test logS < -50   # deeply in the tail, but finite
    end

    @testset "hand-coded η derivatives vs Richardson FD (ENGINE-GATE 2)" begin
        # Richardson extrapolation kills the O(h²) truncation term that forced the
        # earlier loose absolute tolerance, so both η-derivatives are checked on a
        # *relative* scale: first derivative ≤ 1e-8, second derivative ≤ 1e-6.
        # Step sizes are chosen per derivative order (roundoff ∝ 1/h² for the
        # second difference, so it needs the larger step).
        richardson1 = (f, x, h) -> begin
            d = hh -> (f(x + hh) - f(x - hh)) / (2hh)
            (4 * d(h / 2) - d(h)) / 3
        end
        richardson2 = (f, x, h) -> begin
            d = hh -> (f(x + hh) - 2 * f(x) + f(x - hh)) / hh^2
            (4 * d(h / 2) - d(h)) / 3
        end
        cells = [(3.7, 5), (0.3, 30), (0.05, 10), (25.0, 30), (120.0, 100)]
        for (μ, C) in cells
            G = GLLVM._censored_poisson_G(μ, C)
            # score at LogLink: _glm_score returns G
            s = GLLVM._glm_score(GLLVM.CensoredPoisson(), μ, C, μ, 0)
            @test s ≈ G atol = 1e-14
            W = GLLVM._glm_weight(GLLVM.CensoredPoisson(), μ, C, μ)
            @test W ≈ G * (G + μ - C) atol = 1e-10
            @test W ≥ -1e-12
            ℓ = η -> GLLVM._censored_poisson_logS(exp(η), C)
            η = log(μ)
            g2 = G * (C - μ - G)
            @test abs(G - richardson1(ℓ, η, 1e-3)) ≤ 1e-8 * abs(G)
            @test abs(g2 - richardson2(ℓ, η, 5e-3)) ≤ 1e-6 * abs(g2)
        end
    end

    @testset "non-log link rejected (Identity lock)" begin
        Y = [1 2; 3 4]
        N = zeros(Int, 2, 2)
        @test_throws ArgumentError GLLVM.censored_poisson_marginal_loglik_laplace(
            Y, N, zeros(2, 1), zeros(2), IdentityLink())
        @test isfinite(GLLVM.censored_poisson_marginal_loglik_laplace(
            Y, N, zeros(2, 1), zeros(2), LogLink()))
    end

    @testset "uncensored path matches Poisson (N≡0)" begin
        Random.seed!(60)
        p, K, n = 4, 1, 40
        β = log.([2.0, 3.5, 1.5, 4.0])
        Y = [rand(Poisson(exp(β[t]))) for t in 1:p, s in 1:n]
        N0 = zeros(Int, p, n)
        ll_c = GLLVM.censored_poisson_marginal_loglik_laplace(Y, N0, zeros(p, K), β)
        ll_p = GLLVM.poisson_marginal_loglik_laplace(Y, zeros(p, K), β)
        @test ll_c ≈ ll_p atol = 1e-10
    end

    @testset "Λ=0 exact independent censored Poisson" begin
        Random.seed!(61)
        p, K, n = 3, 2, 30
        β = log.([1.5, 2.0, 2.5])
        Y = Matrix{Int}(undef, p, n)
        N = Matrix{Int}(undef, p, n)
        for t in 1:p, s in 1:n
            if isodd(t + s)
                C = 3 + (t % 3)
                Y[t, s] = C
                N[t, s] = C
            else
                Y[t, s] = rand(Poisson(exp(β[t])))
                N[t, s] = 0
            end
        end
        ll = GLLVM.censored_poisson_marginal_loglik_laplace(Y, N, zeros(p, K), β)
        ll_indep = sum(begin
            μ = exp(β[t])
            if N[t, s] == 0
                logpdf(Poisson(μ), Y[t, s])
            else
                logcdf(Gamma(N[t, s], 1.0), μ)
            end
        end for t in 1:p, s in 1:n)
        @test ll ≈ ll_indep atol = 1e-8
    end

    @testset "interval-ready (lower,upper) encoding (ENGINE-GATE 4)" begin
        Y = [2 5; 3 1]
        L = [2 5; 3 1]
        U = [2 typemax(Int); 3 1]   # (1,2) right-censored at 5
        Y2, N2 = GLLVM.censored_bounds_to_YN(L, U)
        @test Y2 == [2 5; 3 1]
        @test N2 == [0 5; 0 0]
        @test_throws ArgumentError GLLVM.censored_bounds_to_YN([1 2], [3 4])  # finite interval
        @test_throws ArgumentError GLLVM.censored_bounds_to_YN([0 1], [typemax(Int) 1])  # C=0
    end

    @testset "censored=falses fit matches Poisson smoke" begin
        Random.seed!(62)
        p, n, K = 3, 35, 1
        β = randn(p) .* 0.25 .+ 0.9
        Λ = reshape(0.4 .* randn(p), p, K)
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            z = randn(K)
            for t in 1:p
                Y[t, s] = rand(Poisson(exp(β[t] + (Λ * z)[t])))
            end
        end
        fit_c = GLLVM.fit_censored_poisson_gllvm(Y; K = K, censored = falses(p, n),
                                                 iterations = 60)
        fit_p = fit_poisson_gllvm(Y; K = K, iterations = 60, gradient = :finite)
        @test isfinite(fit_c.loglik)
        @test fit_c.loglik ≈ fit_p.loglik rtol = 1e-5 atol = 1e-3
    end

    @testset "independent Laplace oracle on censored-dominated cell (ENGINE-GATE 3)" begin
        # The engine's Laplace value depends on _glm_score (through the mode) and
        # on _glm_weight (through logdet(Λ'WΛ + I)). Comparing two finite-difference
        # steps of the same objective is vacuous — it re-tests the same kernels.
        # This gate rebuilds the Laplace approximation from `_glm_logpdf` ALONE:
        #   · conditional mode by derivative-free golden-section coordinate ascent
        #   · curvature by Richardson-extrapolated finite-difference Hessian
        # so a wrong score or a wrong weight shows up as a log-likelihood mismatch.

        # Derivative-free 1-D minimiser on a bracket (unimodal conditional posterior).
        gss = (f, a, b) -> begin
            φ = (sqrt(5.0) - 1) / 2
            c = b - φ * (b - a); d = a + φ * (b - a)
            fc = f(c); fd = f(d)
            for _ in 1:200
                if fc < fd
                    b, d, fd = d, c, fc
                    c = b - φ * (b - a); fc = f(c)
                else
                    a, c, fc = c, d, fd
                    d = a + φ * (b - a); fd = f(d)
                end
                (b - a) ≤ 1e-15 * (1 + abs(a) + abs(b)) && break
            end
            (a + b) / 2
        end
        fdhess = (f, x, h) -> begin
            m = length(x); H = zeros(m, m); fmid = f(x)
            for a in 1:m
                xp = copy(x); xp[a] += h
                xm = copy(x); xm[a] -= h
                H[a, a] = (f(xp) - 2 * fmid + f(xm)) / h^2
                for b in (a + 1):m
                    xpp = copy(x); xpp[a] += h; xpp[b] += h
                    xpm = copy(x); xpm[a] += h; xpm[b] -= h
                    xmp = copy(x); xmp[a] -= h; xmp[b] += h
                    xmm = copy(x); xmm[a] -= h; xmm[b] -= h
                    v = (f(xpp) - f(xpm) - f(xmp) + f(xmm)) / (4 * h^2)
                    H[a, b] = v; H[b, a] = v
                end
            end
            H
        end
        rhess = (f, x, h) -> (4 .* fdhess(f, x, h / 2) .- fdhess(f, x, h)) ./ 3

        Random.seed!(63)
        p, n, K = 4, 12, 2
        β = randn(p) .* 0.2 .+ 0.6
        Λ = 0.35 .* randn(p, K)
        Y = Matrix{Int}(undef, p, n)
        N = Matrix{Int}(undef, p, n)
        for s in 1:n, t in 1:p
            if (t + s) % 4 == 0
                Y[t, s] = rand(Poisson(exp(β[t]))); N[t, s] = 0
            else
                C = 3 + ((t + s) % 3)
                Y[t, s] = C; N[t, s] = C
            end
        end
        @test count(!iszero, N) / length(N) ≥ 0.75   # censored-dominated cell

        fam = GLLVM.CensoredPoisson()
        worst = 0.0
        worst_grad = 0.0
        min_weight = Inf
        for s in 1:n
            ys = Vector(view(Y, :, s)); ns = Vector(view(N, :, s))
            # Site log-joint, built from `_glm_logpdf` only (no score, no weight).
            q = z -> begin
                μ = exp.(β .+ Λ * z)
                acc = -0.5 * dot(z, z)
                for t in 1:p
                    acc += GLLVM._glm_logpdf(fam, μ[t], ns[t], ys[t])
                end
                acc
            end
            ẑ = zeros(K)
            for _sweep in 1:300
                moved = 0.0
                for d in 1:K
                    along = t -> begin zz = copy(ẑ); zz[d] = t; -q(zz) end
                    znew = gss(along, ẑ[d] - 5.0, ẑ[d] + 5.0)
                    moved = max(moved, abs(znew - ẑ[d]))
                    ẑ[d] = znew
                end
                moved < 1e-13 && break
            end
            # The derivative-free mode really is a stationary point of the log-joint.
            for d in 1:K
                zp = copy(ẑ); zp[d] += 1e-5
                zm = copy(ẑ); zm[d] -= 1e-5
                worst_grad = max(worst_grad, abs((q(zp) - q(zm)) / 2e-5))
            end
            # Laplace: q(ẑ) − ½logdet(−∇²q). The (2π)^{K/2} factors cancel against
            # the N(0,I) prior normaliser, matching `laplace_loglik_site`'s form.
            ℓ_oracle = q(ẑ) - 0.5 * logdet(-rhess(q, ẑ, 5e-3))
            ℓ_engine = GLLVM.laplace_loglik_site(fam, ys, ns, Λ, β, LogLink())
            worst = max(worst, abs(ℓ_oracle - ℓ_engine))
            μ̂ = exp.(β .+ Λ * ẑ)
            for t in 1:p
                min_weight = min(min_weight, GLLVM._glm_weight(fam, μ̂[t], ns[t], μ̂[t]))
            end
        end
        @test worst_grad ≤ 1e-6
        @test min_weight > 0        # the max(W,0) floor is inactive here
        @test worst ≤ 1e-6
    end

    @testset "smoke fit with mixed censored / uncensored" begin
        Random.seed!(64)
        p, n, K = 3, 40, 1
        β = randn(p) .* 0.3 .+ 1.0
        Λ = reshape(0.45 .* randn(p), p, K)
        Y = Matrix{Int}(undef, p, n)
        cens = falses(p, n)
        for s in 1:n
            z = randn(K)
            for t in 1:p
                μ = exp(β[t] + (Λ * z)[t])
                y = rand(Poisson(μ))
                if y ≥ 5 && rand() < 0.4
                    Y[t, s] = 5
                    cens[t, s] = true
                else
                    Y[t, s] = y
                end
            end
        end
        fit = GLLVM.fit_censored_poisson_gllvm(Y; K = K, censored = cens, iterations = 80)
        @test isfinite(fit.loglik)
        @test size(fit.Λ) == (p, K)
        @test length(fit.theta_packed) == p + GLLVM.rr_theta_len(p, K)
    end
end
