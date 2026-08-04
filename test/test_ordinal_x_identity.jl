# Identity: per-trait ordinal cutpoints + shared site-X vs no-X per-trait path.
# Contract (decision 2026-08-03): offset O = Xγ enters η = β + O + Λz; zero
# offset matches the no-X per-trait Laplace marginal to ~1e-10. No silent
# tolerance widen (same band spirit as #172 / #175 / Gamma+X).

using Test
using Random
using LinearAlgebra
using Distributions
using GLLVM

function _ox_sim_ordinal(p, n, K, q, C; seed, link = LogitLink())
    rng = Random.MersenneTwister(seed)
    β = 0.25 .* randn(rng, p)
    γ = 0.5 .* randn(rng, q)
    Λ = 0.35 .* randn(rng, p, K)
    X = randn(rng, p, n, q)
    O = GLLVM._build_offset(X, γ)
    Z = randn(rng, K, n)
    η = β .+ O .+ Λ * Z
    τ = fill(NaN, p, C - 1)
    @inbounds for t in 1:p
        τ[t, 1] = 0.0
        for c in 2:(C - 1)
            τ[t, c] = τ[t, c - 1] + exp(-0.2 + 0.1 * randn(rng))
        end
    end
    Y = Matrix{Int}(undef, p, n)
    @inbounds for t in 1:p, s in 1:n
        η_ts = clamp(η[t, s], -6, 6)
        u = rand(rng)
        y = C
        for c in 1:(C - 1)
            F = GLLVM._ord_F(τ[t, c] - η_ts, link)
            if u <= F
                y = c
                break
            end
        end
        Y[t, s] = y
    end
    return Y, X, β, γ, Λ, τ, fill(C, p), O
end

@testset "Ordinal + X identity (API B under X)" begin

    @testset "zero offset: per-trait+X marginal == no-X per-trait" begin
        Random.seed!(8401)
        p, n, K, C = 4, 40, 1, 3
        β = 0.2 .* randn(p)
        Λ = 0.3 .* randn(p, K)
        τ = fill(NaN, p, C - 1)
        for t in 1:p
            τ[t, 1] = 0.0
            τ[t, 2] = 1.2
        end
        Ct = fill(C, p)
        Y = rand(1:C, p, n)
        ll0 = GLLVM.ordinal_marginal_loglik_laplace_pertrait(Y, Λ, β, τ, Ct)
        O = zeros(p, n)
        llX = GLLVM.ordinal_marginal_loglik_laplace_pertrait(Y, Λ, β, τ, Ct; offset = O)
        @test isapprox(ll0, llX; atol = 1e-10, rtol = 0)
    end

    @testset "constant offset absorbed into β matches shifted intercept" begin
        Random.seed!(8402)
        p, n, K, C = 3, 35, 1, 3
        β = 0.15 .* randn(p)
        Λ = 0.25 .* randn(p, K)
        τ = fill(NaN, p, C - 1)
        for t in 1:p
            τ[t, 1] = 0.0
            τ[t, 2] = 0.9
        end
        Ct = fill(C, p)
        Y = rand(1:C, p, n)
        δ = 0.35
        O = fill(δ, p, n)
        ll_off = GLLVM.ordinal_marginal_loglik_laplace_pertrait(Y, Λ, β, τ, Ct; offset = O)
        ll_β = GLLVM.ordinal_marginal_loglik_laplace_pertrait(Y, Λ, β .+ δ, τ, Ct)
        @test isapprox(ll_off, ll_β; atol = 1e-10, rtol = 0)
    end

    @testset "fit_ordinal_gllvm_pertrait_cov zero-X ≈ fit_ordinal_gllvm_pertrait" begin
        Y, X, _, _, _, _, _, _ = _ox_sim_ordinal(4, 90, 1, 1, 3; seed = 8500)
        X0 = zeros(size(X))
        f0 = fit_ordinal_gllvm_pertrait(Y; K = 1, iterations = 200)
        fx = fit_ordinal_gllvm_pertrait_cov(Y; X = X0, K = 1, iterations = 200)
        @test fx isa OrdinalPerTraitCovFit
        @test length(fx.γ) == 1
        @test all(==(3), fx.C)
        @test all(isapprox.(fx.τ[:, 1], 0.0; atol = 1e-12))
        @test isfinite(fx.loglik)
        @test isapprox(fx.loglik, f0.loglik; atol = 1e-2, rtol = 1e-4)
        @test isapprox(fx.γ[1], 0.0; atol = 1e-3)
    end

    @testset "fit recovers finite loglik under non-zero X" begin
        Y, X, _, _, _, _, _, _ = _ox_sim_ordinal(4, 80, 1, 1, 3; seed = 8510)
        fit = fit_ordinal_gllvm_pertrait_cov(Y; X = X, K = 1, iterations = 200)
        @test fit isa OrdinalPerTraitCovFit
        @test isfinite(fit.loglik)
        @test size(fit.Λ) == (4, 1)
        @test length(fit.γ) == 1
        @test all(isapprox.(fit.τ[:, 1], 0.0; atol = 1e-12))
    end

    @testset "FD-gradient of packed cov NLL ≤ 1e-6" begin
        Random.seed!(8520)
        p, n, K, q, C = 3, 25, 1, 1, 3
        Y, X, β, γ, Λ, τ, Ct, _ = _ox_sim_ordinal(p, n, K, q, C; seed = 8520)
        rr = GLLVM.rr_theta_len(p, K)
        ncut = sum(Ct .- 2)
        # Pack ψ from known τ (τ[:,1]=0; free log-spacings for c≥2).
        ψ = Float64[]
        for t in 1:p
            for c in 2:(C - 1)
                push!(ψ, log(max(τ[t, c] - τ[t, c - 1], 1e-3)))
            end
        end
        θ = vcat(β, γ, GLLVM.pack_lambda(Λ), ψ)
        nll = θv -> begin
            βv = @view θv[1:p]
            γv = @view θv[(p + 1):(p + q)]
            Λv = GLLVM.unpack_lambda(@view(θv[(p + q + 1):(p + q + rr)]), p, K)
            τv = GLLVM._unpack_cutpoints_pertrait(
                @view(θv[(p + q + rr + 1):(p + q + rr + ncut)]), Ct)
            O = GLLVM._build_offset(X, γv)
            return -GLLVM.ordinal_marginal_loglik_laplace_pertrait(
                Y, Λv, βv, τv, Ct; offset = O)
        end
        h = 1e-6
        g_fd = similar(θ)
        for i in eachindex(θ)
            θp = copy(θ); θp[i] += h
            θm = copy(θ); θm[i] -= h
            g_fd[i] = (nll(θp) - nll(θm)) / (2h)
        end
        # Independent 5-point reference on a random coordinate subset.
        idxs = unique(clamp.(round.(Int, 1 .+ (length(θ) - 1) .* rand(6)), 1, length(θ)))
        for i in idxs
            θpp = copy(θ); θpp[i] += 2h
            θp  = copy(θ); θp[i]  += h
            θm  = copy(θ); θm[i]  -= h
            θmm = copy(θ); θmm[i] -= 2h
            g5 = (-nll(θpp) + 8nll(θp) - 8nll(θm) + nll(θmm)) / (12h)
            @test abs(g_fd[i] - g5) ≤ 1e-6
        end
        @test all(isfinite, g_fd)
        @test maximum(abs, g_fd) < 1e6   # sanity: not exploding at truth
    end
end
