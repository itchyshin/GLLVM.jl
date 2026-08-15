using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions, ForwardDiff

# Own-file harness: conductor has not yet include/export-wired lognormal.jl.
# Load the family module file into GLLVM so focused tests run without editing
# shared choke points (see ADMIT.md).
isf = isdefined(GLLVM, :fit_lognormal_gllvm)
if !isf
    Base.include(GLLVM, joinpath(@__DIR__, "..", "src", "families", "lognormal.jl"))
end

# Central FD (same stencil discipline as test_studentt.jl — avoid Float32 `2f0`).
function _ln_central_fd_gradient(f, theta; h = 1e-6)
    g = similar(theta)
    @inbounds for i in eachindex(theta)
        step = h * max(1.0, abs(theta[i]))
        tp = copy(theta); tp[i] += step
        tm = copy(theta); tm[i] -= step
        g[i] = (f(tp) - f(tm)) / (2 * step)
    end
    return g
end

_ln_max_rel_err(a, b) = maximum(abs.(a .- b) ./ max.(1.0, abs.(b)))

function _rlognormal(η, σ)
    return exp(η + σ * randn())
end

@testset "lognormal family (one-part, twin fid 3)" begin

    @testset "Λ=0 exact reduction vs independent LogNormal + Jacobian" begin
        Random.seed!(501)
        p, K, n = 4, 2, 40
        β = [0.4, 0.9, -0.2, 0.6]
        σ = 0.7
        Y = [_rlognormal(β[t], σ) for t in 1:p, s in 1:n]
        ll = GLLVM.lognormal_marginal_loglik(Y, zeros(p, K), β, σ)
        ll_indep = sum(logpdf(LogNormal(β[t], σ), Y[t, s]) for t in 1:p, s in 1:n)
        @test ll ≈ ll_indep atol = 1e-8
    end

    @testset "marginal = Gaussian(log y) − Σ log y (exact)" begin
        Random.seed!(502)
        p, K, n = 5, 2, 50
        β = [0.5, 1.0, -0.3, 0.8, 0.2]
        Λ = 0.3 .* randn(p, K)
        σ = 0.6
        Y = Matrix{Float64}(undef, p, n)
        for s in 1:n
            z = randn(K)
            for t in 1:p
                Y[t, s] = _rlognormal(β[t] + (Λ * z)[t], σ)
            end
        end
        Z = log.(Y)
        ref = GLLVM.gaussian_marginal_loglik(Z .- β, Λ, σ) - sum(Z)
        ll = GLLVM.lognormal_marginal_loglik(Y, Λ, β, σ)
        @test ll ≈ ref atol = 1e-9
    end

    @testset "response mean uses σ²/2 bias correction" begin
        η, σ = 0.5, 0.8
        @test GLLVM.lognormal_response_mean(η, σ) ≈ exp(η + σ^2 / 2) atol = 0
        @test GLLVM.lognormal_response_mean(η, σ) ≉ exp(η) atol = 1e-12
    end

    @testset "rejects y ≤ 0" begin
        Y = [1.0 2.0; 0.0 3.0]
        @test_throws ArgumentError GLLVM.fit_lognormal_gllvm(Y; K = 1, iterations = 5)
        Y2 = [1.0 2.0; -0.1 3.0]
        @test_throws ArgumentError GLLVM.fit_lognormal_gllvm(Y2; K = 1, iterations = 5)
    end

    @testset "rejects non-LogLink" begin
        Y = exp.(randn(3, 20))
        @test_throws ArgumentError GLLVM.fit_lognormal_gllvm(Y; K = 1,
                                                       link = GLLVM.IdentityLink(),
                                                       iterations = 5)
    end

    @testset "packed NLL FD vs ForwardDiff ≤ 1e-6" begin
        Random.seed!(503)
        p, n, K = 4, 12, 1
        rr = GLLVM.rr_theta_len(p, K)
        β0 = [0.4, 0.9, -0.2, 0.6]
        Λ0 = GLLVM.pack_lambda(0.2 .* randn(p, K))
        σ_true = 0.7
        Y = [_rlognormal(β0[t], σ_true) for t in 1:p, s in 1:n]
        θ0 = vcat(β0, Λ0, log(σ_true))
        f = θ -> -GLLVM.lognormal_marginal_loglik(
            Y, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
            exp(θ[p + rr + 1]))
        gad = ForwardDiff.gradient(f, θ0)
        gfd = _ln_central_fd_gradient(f, θ0)
        relerr = _ln_max_rel_err(gad, gfd)
        @info "lognormal marginal FD-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    @testset "smoke fit recovers (β, ΛΛ', σ)" begin
        Random.seed!(504)
        p, K, n = 6, 2, 400
        β_true = [0.5, 1.2, -0.4, 0.9, 0.1, 0.7]
        Λ_true = 0.5 .* randn(p, K)
        σ_true = 0.5
        Y = Matrix{Float64}(undef, p, n)
        for s in 1:n
            z = randn(K)
            for t in 1:p
                Y[t, s] = _rlognormal(β_true[t] + (Λ_true * z)[t], σ_true)
            end
        end
        fit = GLLVM.fit_lognormal_gllvm(Y; K = K)
        @info "lognormal fit" converged=fit.converged σ̂=fit.σ loglik=fit.loglik
        @test fit isa GLLVM.LognormalFit
        @test size(fit.Λ) == (p, K)
        @test length(fit.theta_packed) == p + GLLVM.rr_theta_len(p, K) + 1
        @test isfinite(fit.loglik)
        @test maximum(abs.(fit.β .- β_true)) < 0.25
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λ_true * Λ_true')) > 0.65
        @test fit.σ ≈ σ_true rtol = 0.25
        # Reported loglik includes Jacobian (not bare Gaussian-on-log).
        Z = log.(Y)
        @test fit.loglik ≈ GLLVM.gaussian_marginal_loglik(Z .- fit.β, fit.Λ, fit.σ) - sum(Z) atol = 1e-6
    end
end
