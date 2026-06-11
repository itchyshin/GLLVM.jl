using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions, ForwardDiff

# Central finite-difference gradient (matches test/test_zip.jl and test/test_zinb.jl).
# The FD step is in θ's Float64 precision to hit the ≤1e-6 target.
function _central_fd_gradient(f, theta; h = 1e-6)
    g = similar(theta)
    @inbounds for i in eachindex(theta)
        step = h * max(1.0, abs(theta[i]))
        tp = copy(theta); tp[i] += step
        tm = copy(theta); tm[i] -= step
        g[i] = (f(tp) - f(tm)) / (2 * step)
    end
    return g
end

_max_rel_err(a, b) = maximum(abs.(a .- b) ./ max.(1.0, abs.(b)))

# Closed-form ZIBinom logpdf reference: π·δ₀ + (1−π)·Binomial(N, p).
function _zibinom_logpdf(N, π, p, k)
    g = (1 - p)^N
    if k == 0
        return log(π + (1 - π) * g)
    else
        return log1p(-π) + logpdf(Binomial(N, p), k)
    end
end

# Draw one ZIBinom(N, π, p) (reference DGP for tests).
_rand_zibinom(rng, N, π, p) = rand(rng) < π ? 0 : rand(rng, Binomial(N, p))

@testset "Zero-inflated binomial (ZIBinom)" begin

    # ---------------------------------------------------------------------
    # Family pieces: score / weight / logpdf sanity against the spec.
    # me = p(1−p) at the logit link (this is what the Laplace core passes).
    # ---------------------------------------------------------------------
    @testset "score, weight, logpdf match the ZIBinom spec" begin
        for N in (1, 4, 10), π in (0.1, 0.3, 0.5), p in (0.2, 0.4, 0.7)
            fam = GLLVM.ZIBinom(π)
            me = p * (1 - p)
            g = (1 - p)^N
            p0 = π + (1 - π) * g
            # logpdf: y=0 mixes both parts; y>0 is log(1−π)+Binomial logpmf.
            @test GLLVM._glm_logpdf(fam, p, N, 0.0) ≈ log(p0)
            @test GLLVM._glm_logpdf(fam, p, N, 1.0) ≈ log1p(-π) + logpdf(Binomial(N, p), 1)
            # logpdf is a normalised pmf over k = 0,1,…,N.
            @test sum(exp(_zibinom_logpdf(N, π, p, k)) for k in 0:N) ≈ 1.0 atol = 1e-9
            # score: y>0 is the binomial-logit score y − N p (π-free); y=0 the zero cell.
            @test GLLVM._glm_score(fam, p, N, me, 1.0) ≈ (1.0 - N * p)
            @test GLLVM._glm_score(fam, p, N, me, 0.0) ≈
                  -(1 - π) * N * (1 - p)^(N - 1) * me / p0
            # weight = expected Fisher information E[s²] ≥ 0.
            Ifull = N * me^2 / (p * (1 - p))
            s0count = N * me / (1 - p)
            zero_term  = (1 - π)^2 * N^2 * (1 - p)^(2N - 2) * me^2 / p0
            count_term = (1 - π) * (Ifull - g * s0count^2)
            @test GLLVM._glm_weight(fam, p, N, me) ≈ zero_term + count_term
            @test GLLVM._glm_weight(fam, p, N, me) > 0
        end
    end

    # ---------------------------------------------------------------------
    # π → 0 reduces every family piece to the plain Binomial (the parent).
    # ---------------------------------------------------------------------
    @testset "π = 0 reduces to Binomial pieces" begin
        for N in (1, 5, 12), p in (0.2, 0.5, 0.8)
            zfam = GLLVM.ZIBinom(0.0)
            bfam = Binomial()
            me = p * (1 - p)
            @test GLLVM._glm_score(zfam, p, N, me, 0.0) ≈ GLLVM._glm_score(bfam, p, N, me, 0.0)
            @test GLLVM._glm_score(zfam, p, N, me, 3.0) ≈ GLLVM._glm_score(bfam, p, N, me, 3.0)
            @test GLLVM._glm_weight(zfam, p, N, me) ≈ GLLVM._glm_weight(bfam, p, N, me)
            @test GLLVM._glm_logpdf(zfam, p, N, 2.0) ≈ GLLVM._glm_logpdf(bfam, p, N, 2.0)
        end
    end

    # ---------------------------------------------------------------------
    # Λ = 0 reduces to the independent ZIBinom-regression loglik (exact).
    # Trial counts N are threaded through (NOT unit-filled).
    # ---------------------------------------------------------------------
    @testset "Λ = 0 reduces to independent ZIBinom-regression loglik (exact)" begin
        Random.seed!(1202)
        p, K, n = 4, 2, 50
        β = [0.5, -0.3, 1.0, -0.8]
        pr = [1 / (1 + exp(-β[t])) for t in 1:p]
        π = 0.3
        Nmat = rand(MersenneTwister(12022), 3:12, p, n)
        rng = MersenneTwister(12021)
        Y = [_rand_zibinom(rng, Nmat[t, s], π, pr[t]) for t in 1:p, s in 1:n]
        ll = GLLVM.zibinom_marginal_loglik_laplace(Y, Nmat, zeros(p, K), β, π)
        ll_indep = sum(_zibinom_logpdf(Nmat[t, s], π, pr[t], Y[t, s]) for t in 1:p, s in 1:n)
        @test ll ≈ ll_indep atol = 1e-7
    end

    # ---------------------------------------------------------------------
    # Marginal → Binomial marginal as π → 0 (the limiting reduction to the parent).
    # ---------------------------------------------------------------------
    @testset "marginal → Binomial marginal as π → 0" begin
        Random.seed!(1201)
        p, K, n = 5, 2, 30
        β = [0.5, -0.3, 1.0, -0.8, 0.2]
        Λ = 0.3 .* randn(p, K)
        Nmat = fill(8, p, n)
        Y = [rand(Binomial(8, 1 / (1 + exp(-β[t])))) for t in 1:p, s in 1:n]
        ll_zibinom = GLLVM.zibinom_marginal_loglik_laplace(Y, Nmat, Λ, β, 1e-8)
        ll_binom   = GLLVM.binomial_marginal_loglik_laplace(Y, Nmat, Λ, β, LogitLink())
        @test ll_zibinom ≈ ll_binom atol = 1e-3
    end

    # ---------------------------------------------------------------------
    # FD gradient of the marginal (ForwardDiff vs central differences) ≤ 1e-6.
    # Packed θ = [β; vec(Λ); logit π]; π enters via the marker. Trial counts N fixed.
    # ---------------------------------------------------------------------
    @testset "marginal gradient: FD ≤ 1e-6" begin
        Random.seed!(1203)
        p, n, K = 4, 8, 1
        rr = GLLVM.rr_theta_len(p, K)
        β0 = fill(0.4, p)
        Λ0 = GLLVM.pack_lambda(0.1 .* randn(p, K))
        π_true = 0.35
        Nmat = rand(MersenneTwister(12032), 4:10, p, n)
        rng = MersenneTwister(12031)
        Y = [_rand_zibinom(rng, Nmat[t, s], π_true, 0.6) for t in 1:p, s in 1:n]
        θ0 = vcat(β0, Λ0, log(π_true / (1 - π_true)))
        f = θ -> -GLLVM.zibinom_marginal_loglik_laplace(
            Y, Nmat, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
            GLLVM._prob_from_logit(θ[p + rr + 1]))
        gad = ForwardDiff.gradient(f, θ0)
        gfd = _central_fd_gradient(f, θ0)
        relerr = _max_rel_err(gad, gfd)
        @info "ZIBinom marginal FD-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    # ---------------------------------------------------------------------
    # The implicit value+gradient the fitter actually optimises vs FD ≤ 1e-6.
    # ---------------------------------------------------------------------
    @testset "implicit fit gradient matches FD ≤ 1e-6" begin
        Random.seed!(1204)
        p, n, K = 4, 10, 1
        rr = GLLVM.rr_theta_len(p, K)
        β0 = fill(0.4, p)
        Λ0 = GLLVM.pack_lambda(0.15 .* randn(p, K))
        π_true = 0.3
        Nmat = rand(MersenneTwister(12042), 4:10, p, n)
        rng = MersenneTwister(12041)
        Y = [_rand_zibinom(rng, Nmat[t, s], π_true, 0.6) for t in 1:p, s in 1:n]
        θ0 = vcat(β0, Λ0, log(π_true / (1 - π_true)))
        family_fromθ = θ -> GLLVM.ZIBinom(GLLVM._prob_from_logit(θ[end]))
        vg = θ -> GLLVM.marginal_loglik_laplace_implicit_value_grad(
            family_fromθ, Y, Nmat, θ, p, K, LogitLink())
        _, gimp = vg(θ0)
        f = θ -> vg(θ)[1]
        gfd = _central_fd_gradient(f, θ0)
        relerr = _max_rel_err(gimp, gfd)
        @info "ZIBinom implicit fit-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    # ---------------------------------------------------------------------
    # simulate → fit → recover (β, ΛΛ' structure, π). Convergence flag is
    # INFORMATIONAL — structure recovery is asserted, not convergence.
    # ---------------------------------------------------------------------
    @testset "simulate → fit → recover (β, ΛΛ', π)" begin
        Random.seed!(1205)
        p, K, n = 6, 2, 1200
        β_true = [0.5, -0.3, 1.0, -0.8, 0.2, 0.6]
        Λ_true = 0.5 .* randn(p, K)
        π_true = 0.3
        Nmat = fill(15, p, n)
        Y = simulate(GLLVM.ZIBinom(π_true), β_true, Λ_true, n;
                     dispersion = π_true, N = Nmat, seed = 12051)
        Yint = round.(Int, Y)
        @test count(==(0), Yint) > 0                # ZIBinom produces zeros
        fit = fit_zibinom_gllvm(Yint; K = K, N = Nmat)
        @info "ZIBinom fit" converged=fit.converged π̂=fit.π loglik=fit.loglik
        @test size(fit.Λ) == (p, K)
        @test maximum(abs.(fit.β .- β_true)) < 0.6
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λ_true * Λ_true')) > 0.5
        @test 0 < fit.π < 1
        @test fit.π ≈ π_true rtol = 0.5            # zero-inflation is identifiable-but-noisy
    end
end
