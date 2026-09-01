# ACC-BRIDGE-GRADIENT (docs/dev-log/core070/real-workflow-acceptance-lessons.md
# class 6): the R side had no way to read Julia's gradient / convergence health
# through the bridge (public_r_bridge.gradient_max = null). Every bridge_fit
# payload must now carry `gradient_max` — the max-abs gradient of the fit's own
# packed negative log-likelihood at the fitted parameters — as a finite,
# converged-scale-small Float64, never silently absent.

using Test
using GLLVM
using Random

function _grad_bridge_latent(p, n, K, seed)
    rng = Random.MersenneTwister(seed)
    Λ = 0.5 .* randn(rng, p, K)
    β = 0.3 .* randn(rng, p)
    Z = randn(rng, K, n)
    η = β .+ Λ * Z
    return η
end

function _grad_sim_gaussian(p, n, K; seed = 401)
    η = _grad_bridge_latent(p, n, K, seed)
    rng = Random.MersenneTwister(seed + 1000)
    return η .+ 0.4 .* randn(rng, p, n)
end

function _grad_sim_binomial(p, n, K, Ntrial; seed = 402)
    η = _grad_bridge_latent(p, n, K, seed)
    rng = Random.MersenneTwister(seed + 1000)
    Y = Matrix{Int}(undef, p, n)
    for i in eachindex(η)
        pr = 1 / (1 + exp(-η[i]))
        Y[i] = rand(rng, GLLVM.Binomial(Ntrial, pr))
    end
    return Y
end

@testset "bridge payload: gradient_max (ACC-BRIDGE-GRADIENT)" begin
    @testset "gaussian" begin
        p, n, K = 6, 60, 1
        Y = _grad_sim_gaussian(p, n, K)
        br = bridge_fit(; y = Y, family = "gaussian", d = K)

        @test haskey(br, :gradient_max)
        @test br.gradient_max isa Float64
        @test isfinite(br.gradient_max)
        @test br.gradient_max <= 1e-3
    end

    @testset "binomial" begin
        p, n, K = 6, 60, 1
        Ntrial = 10
        Y = _grad_sim_binomial(p, n, K, Ntrial)
        br = bridge_fit(; y = Float64.(Y), family = "binomial", d = K, N = Ntrial)

        @test haskey(br, :gradient_max)
        @test br.gradient_max isa Float64
        @test isfinite(br.gradient_max)
        @test br.gradient_max <= 1e-3
    end
end
