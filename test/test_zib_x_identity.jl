# Identity: ZIB + shared site-X under ACCEPTED decision 2026-08-15.
# Contract: zero-X ≈ fit_zib_gllvm; packed central FD ≤ 1e-6.
# No silent tolerance widen. Twin light Δ forbidden (twin ZIP/ZINB cut; no twin ZIB).
# Shared choke points (exports / bridge / @formula / runtests) left to ADMIT.md.

using Test
using Random
using LinearAlgebra
using Distributions
using GLLVM

function _zib_x_sim(p, n, K, q, N; seed = 1)
    Random.seed!(seed)
    βz = 0.4 .* randn(p) .- 0.8
    γz = 0.35 .* randn(q)
    βc = 0.25 .* randn(p)
    γc = 0.45 .* randn(q)
    Λc = 0.3 .* randn(p, K)
    X = randn(p, n, q)
    Oz = GLLVM._build_offset(X, γz)
    Oc = GLLVM._build_offset(X, γc)
    Z = randn(K, n)
    Y = Matrix{Int}(undef, p, n)
    for t in 1:p, s in 1:n
        π = 1 / (1 + exp(-(βz[t] + Oz[t, s])))
        μ = 1 / (1 + exp(-(βc[t] + Oc[t, s] + (Λc * Z)[t, s])))
        if rand() < π
            Y[t, s] = 0
        else
            Y[t, s] = rand(Binomial(N, μ))
        end
    end
    return Y, X, βz, γz, βc, γc, Λc
end

@testset "ZIB + X identity (Julia-forward)" begin

    @testset "dual-offset marginal matches hand-built Oz/Oc" begin
        Ntr = 8
        Y, X, βz, γz, βc, γc, Λc = _zib_x_sim(4, 35, 1, 1, Ntr; seed = 8801)
        Oz = GLLVM._build_offset(X, γz)
        Oc = GLLVM._build_offset(X, γc)
        ll = GLLVM.zib_marginal_loglik_laplace(Y, Λc, βz, βc, Ntr; offsetz = Oz, offsetc = Oc)
        @test isfinite(ll)
        Xconst = ones(size(X)...)
        Ozc = GLLVM._build_offset(Xconst, γz)
        Occ = GLLVM._build_offset(Xconst, γc)
        ll_off = GLLVM.zib_marginal_loglik_laplace(Y, Λc, βz, βc, Ntr; offsetz = Ozc, offsetc = Occ)
        ll_abs = GLLVM.zib_marginal_loglik_laplace(Y, Λc, βz .+ γz[1], βc .+ γc[1], Ntr)
        @test isapprox(ll_off, ll_abs; atol = 1e-8, rtol = 0)
    end

    @testset "zero-X fit_zib_gllvm_cov ≈ fit_zib_gllvm" begin
        Random.seed!(8810)
        p, n, K, q, Ntr = 4, 90, 1, 1, 8
        Y, _, _, _, _, _, _ = _zib_x_sim(p, n, K, q, Ntr; seed = 8810)
        X0 = zeros(p, n, q)
        f0 = fit_zib_gllvm(Y; K = K, N = Ntr, iterations = 250)
        fx = GLLVM.fit_zib_gllvm_cov(Y; X = X0, K = K, N = Ntr, iterations = 250)
        @test fx isa GLLVM.ZIBCovFit
        @test fx.N == Ntr
        @test length(fx.γz) == q
        @test length(fx.γc) == q
        @test isfinite(fx.loglik)
        @test isfinite(f0.loglik)
        println("ZIB zero-X identity: loglik_cov=$(fx.loglik) loglik_nox=$(f0.loglik) " *
                "Δ=$(abs(fx.loglik - f0.loglik)) γz=$(fx.γz[1]) γc=$(fx.γc[1])")
        @test isapprox(fx.loglik, f0.loglik; atol = 1e-2, rtol = 1e-4)
        @test isapprox(fx.γz[1], 0.0; atol = 1e-2)
        @test isapprox(fx.γc[1], 0.0; atol = 1e-2)
    end

    @testset "fit recovers finite loglik under non-zero X" begin
        Ntr = 8
        Y, X, _, _, _, _, _ = _zib_x_sim(4, 80, 1, 1, Ntr; seed = 8820)
        fit = GLLVM.fit_zib_gllvm_cov(Y; X = X, K = 1, N = Ntr, iterations = 200)
        @test fit isa GLLVM.ZIBCovFit
        @test isfinite(fit.loglik)
        @test fit.N == Ntr
        @test size(fit.Λc) == (4, 1)
        @test length(fit.γz) == 1
        @test length(fit.γc) == 1
    end

    @testset "packed FD central vs 5-point ≤ 1e-6" begin
        Ntr = 8
        Y, X, βz, γz, βc, γc, Λc = _zib_x_sim(3, 28, 1, 1, Ntr; seed = 8830)
        p, n = size(Y); K = 1; q = 1
        rr = GLLVM.rr_theta_len(p, K)
        θ = vcat(βz, γz, βc, γc, GLLVM.pack_lambda(Λc))
        nll = θv -> begin
            βzv = @view θv[1:p]
            γzv = @view θv[(p + 1):(p + q)]
            βcv = @view θv[(p + q + 1):(2p + q)]
            γcv = @view θv[(2p + q + 1):(2p + 2q)]
            Λcv = GLLVM.unpack_lambda(@view(θv[(2p + 2q + 1):(2p + 2q + rr)]), p, K)
            Oz = GLLVM._build_offset(X, γzv)
            Oc = GLLVM._build_offset(X, γcv)
            return -GLLVM.zib_marginal_loglik_laplace(Y, Λcv, βzv, βcv, Ntr;
                                                      offsetz = Oz, offsetc = Oc)
        end
        h = 1e-6
        g_fd = similar(θ)
        for i in eachindex(θ)
            θp = copy(θ); θp[i] += h
            θm = copy(θ); θm[i] -= h
            g_fd[i] = (nll(θp) - nll(θm)) / (2h)
        end
        idxs = unique(clamp.(round.(Int, 1 .+ (length(θ) - 1) .* rand(6)), 1, length(θ)))
        max_abs_diff = 0.0
        for i in idxs
            θpp = copy(θ); θpp[i] += 2h
            θp  = copy(θ); θp[i]  += h
            θm  = copy(θ); θm[i]  -= h
            θmm = copy(θ); θmm[i] -= 2h
            g5 = (-nll(θpp) + 8nll(θp) - 8nll(θm) + nll(θmm)) / (12h)
            d = abs(g_fd[i] - g5)
            max_abs_diff = max(max_abs_diff, d)
            @test d ≤ 1e-6
        end
        println("ZIB+X packed FD tally: max|central-5pt|=$max_abs_diff (≤1e-6); " *
                "max|g_fd|=$(maximum(abs, g_fd))")
        @test all(isfinite, g_fd)
        @test maximum(abs, g_fd) < 1e6
    end
end
