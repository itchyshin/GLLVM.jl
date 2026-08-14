# Identity: ZINB + shared site-X under ACCEPTED decision 2026-08-13.
# Contract: zero-X ≈ fit_zinb_gllvm (including shared r); packed central FD ≤ 1e-6.
# No silent tolerance widen. Twin light Δ forbidden (twin ZINB cut).

using Test
using Random
using LinearAlgebra
using Distributions
using GLLVM

function _zinb_x_sim(p, n, K, q; seed = 1, r = 8.0)
    Random.seed!(seed)
    βz = 0.4 .* randn(p) .- 0.8
    γz = 0.35 .* randn(q)
    βc = 0.25 .* randn(p) .+ 0.6
    γc = 0.45 .* randn(q)
    Λc = 0.3 .* randn(p, K)
    X = randn(p, n, q)
    Oz = GLLVM._build_offset(X, γz)
    Oc = GLLVM._build_offset(X, γc)
    Z = randn(K, n)
    Y = Matrix{Int}(undef, p, n)
    for t in 1:p, s in 1:n
        π = 1 / (1 + exp(-(βz[t] + Oz[t, s])))
        μ = exp(clamp(βc[t] + Oc[t, s] + (Λc * Z)[t, s], -4, 4))
        if rand() < π
            Y[t, s] = 0
        else
            Y[t, s] = rand(NegativeBinomial(r, r / (r + μ)))
        end
    end
    return Y, X, βz, γz, βc, γc, Λc, r
end

@testset "ZINB + X identity (Julia-forward)" begin

    @testset "dual-offset marginal matches hand-built Oz/Oc" begin
        Y, X, βz, γz, βc, γc, Λc, r = _zinb_x_sim(4, 35, 1, 1; seed = 8701)
        Oz = GLLVM._build_offset(X, γz)
        Oc = GLLVM._build_offset(X, γc)
        ll = GLLVM.zinb_marginal_loglik_laplace(Y, Λc, βz, βc, r; offsetz = Oz, offsetc = Oc)
        @test isfinite(ll)
        # Absorbing a constant γ into β leaves the likelihood unchanged when X is
        # constant across sites — smoke that offsetz path is live (not only offsetc).
        Xconst = ones(size(X)...)
        Ozc = GLLVM._build_offset(Xconst, γz)
        Occ = GLLVM._build_offset(Xconst, γc)
        ll_off = GLLVM.zinb_marginal_loglik_laplace(Y, Λc, βz, βc, r; offsetz = Ozc, offsetc = Occ)
        ll_abs = GLLVM.zinb_marginal_loglik_laplace(Y, Λc, βz .+ γz[1], βc .+ γc[1], r)
        @test isapprox(ll_off, ll_abs; atol = 1e-8, rtol = 0)
    end

    @testset "zero-X fit_zinb_gllvm_cov ≈ fit_zinb_gllvm (incl. r)" begin
        Random.seed!(8710)
        p, n, K, q = 4, 90, 1, 1
        Y, _, _, _, _, _, _, _ = _zinb_x_sim(p, n, K, q; seed = 8710)
        X0 = zeros(p, n, q)
        f0 = fit_zinb_gllvm(Y; K = K, iterations = 250)
        fx = fit_zinb_gllvm_cov(Y; X = X0, K = K, iterations = 250)
        @test fx isa ZINBCovFit
        @test length(fx.γz) == q
        @test length(fx.γc) == q
        @test fx.r isa Float64
        @test fx.r > 0
        @test isfinite(fx.loglik)
        @test isfinite(f0.loglik)
        println("ZINB zero-X identity: loglik_cov=$(fx.loglik) loglik_nox=$(f0.loglik) " *
                "Δ=$(abs(fx.loglik - f0.loglik)) r_cov=$(fx.r) r_nox=$(f0.r) " *
                "γz=$(fx.γz[1]) γc=$(fx.γc[1])")
        @test isapprox(fx.loglik, f0.loglik; atol = 1e-2, rtol = 1e-4)
        @test isapprox(fx.r, f0.r; atol = 1e-2, rtol = 1e-3)
        @test isapprox(fx.γz[1], 0.0; atol = 1e-2)
        @test isapprox(fx.γc[1], 0.0; atol = 1e-2)
    end

    @testset "fit recovers finite loglik under non-zero X" begin
        Y, X, _, _, _, _, _, _ = _zinb_x_sim(4, 80, 1, 1; seed = 8720)
        fit = fit_zinb_gllvm_cov(Y; X = X, K = 1, iterations = 200)
        @test fit isa ZINBCovFit
        @test isfinite(fit.loglik)
        @test fit.r > 0
        @test size(fit.Λc) == (4, 1)
        @test length(fit.γz) == 1
        @test length(fit.γc) == 1
        Z = getLV(fit, Y, X; rotate = true)
        @test size(Z) == (80, 1)
        @test all(isfinite, Z)
    end

    @testset "packed FD central vs 5-point ≤ 1e-6 (incl. log r)" begin
        Y, X, βz, γz, βc, γc, Λc, r = _zinb_x_sim(3, 28, 1, 1; seed = 8730)
        p, n = size(Y); K = 1; q = 1
        rr = GLLVM.rr_theta_len(p, K)
        θ = vcat(βz, γz, βc, γc, GLLVM.pack_lambda(Λc), log(r))
        nll = θv -> begin
            βzv = @view θv[1:p]
            γzv = @view θv[(p + 1):(p + q)]
            βcv = @view θv[(p + q + 1):(2p + q)]
            γcv = @view θv[(2p + q + 1):(2p + 2q)]
            Λcv = GLLVM.unpack_lambda(@view(θv[(2p + 2q + 1):(2p + 2q + rr)]), p, K)
            rv = exp(θv[2p + 2q + rr + 1])
            Oz = GLLVM._build_offset(X, γzv)
            Oc = GLLVM._build_offset(X, γcv)
            return -GLLVM.zinb_marginal_loglik_laplace(Y, Λcv, βzv, βcv, rv;
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
        # Always include the log-r tail (shared scalar lock).
        push!(idxs, length(θ))
        idxs = unique(idxs)
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
        println("ZINB+X packed FD tally: max|central-5pt|=$max_abs_diff (≤1e-6); " *
                "max|g_fd|=$(maximum(abs, g_fd)); log_r_g=$(g_fd[end])")
        @test all(isfinite, g_fd)
        @test maximum(abs, g_fd) < 1e6
    end

    @testset "@formula / ZINegBin routes" begin
        Y, X, _, _, _, _, _, _ = _zinb_x_sim(3, 40, 1, 1; seed = 8740)
        n = size(Y, 2)
        site = (temp = X[1, :, 1],)
        f0 = gllvm(@formula(y ~ 1), Y, site; family = ZINegBin(), K = 1, iterations = 80)
        @test f0 isa ZINBFit
        fx = gllvm(@formula(y ~ 1 + temp), Y, site; family = ZINegBin(), K = 1, iterations = 80)
        @test fx isa ZINBCovFit
        @test isfinite(fx.loglik)
        @test fx.r > 0
    end

    @testset "bridge admits no-X zinb and ZINB+X" begin
        Y, X, _, _, _, _, _, _ = _zinb_x_sim(3, 40, 1, 1; seed = 8750)
        br0 = bridge_fit(; y = Float64.(Y), family = "zinb", d = 1)
        @test br0.family == "zinb"
        @test br0.model == "zinb_rr"
        @test all(>(0), br0.dispersion)
        @test occursin("shared scalar r", br0.note)
        brx = bridge_fit(; y = Float64.(Y), family = "zinb", d = 1, X = X)
        @test brx.family == "zinb"
        @test brx.model == "zinb_x_rr"
        @test length(brx.gamma_z) == 1
        @test length(brx.gamma_c) == 1
        @test all(x -> isapprox(x, brx.dispersion[1]; atol = 0), brx.dispersion)
    end
end
