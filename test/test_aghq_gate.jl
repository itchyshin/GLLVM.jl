using GLLVM, Test, Random, Distributions, LinearAlgebra

# A4(3): `_aghq_stage1a_reject_extra` fail-loud IS the gate.
# No public `aghq=`. No TMB min-fill / treewidth port.
# Affordability (`k^d` / `d ≤ 5`) is `_aghq_kd_bound` — see
# `test/test_aghq_kd_bound.jl`. Do not re-assert helper absence here.

function _reject_extra(family = Poisson(); row_effects = nothing,
        phylo = nothing, mi = nothing, unique_latent = nothing,
        s_B = nothing, use_lv_B = nothing, multinomial = nothing)
    GLLVM._aghq_stage1a_reject_extra(family, row_effects, phylo, mi,
                                     unique_latent, s_B, use_lv_B, multinomial)
end

function _ineligible_site(; k::Integer = 3, kwargs...)
    p, K = 3, 1
    GLLVM.aghq_stage1a_loglik_site(Poisson(), ones(Int, p), ones(Int, p),
                                   ones(p, K), zeros(p), GLLVM.LogLink();
                                   k = k, kwargs...)
end

@testset "AGHQ A4(3) fail-loud gate" begin

    @testset "_aghq_stage1a_reject_extra is the named gate" begin
        @test isdefined(GLLVM, :_aghq_stage1a_reject_extra)
        @test _reject_extra() === nothing
        @test _reject_extra(; unique_latent = false, use_lv_B = false,
                            multinomial = false) === nothing
    end

    @testset "Stage-1a fences throw from the helper" begin
        err = @test_throws ArgumentError _reject_extra(; row_effects = true)
        @test occursin("row effects", err.value.msg)
        err = @test_throws ArgumentError _reject_extra(; phylo = true)
        @test occursin("phylogenetic", err.value.msg)
        err = @test_throws ArgumentError _reject_extra(; mi = true)
        @test occursin("mi()", err.value.msg)
        err = @test_throws ArgumentError _reject_extra(; unique_latent = true)
        @test occursin("unique / free s_B", err.value.msg)
        err = @test_throws ArgumentError _reject_extra(; s_B = ones(1))
        @test occursin("free s_B", err.value.msg)
        err = @test_throws ArgumentError _reject_extra(; use_lv_B = true)
        @test occursin("use_lv_B", err.value.msg)
        err = @test_throws ArgumentError _reject_extra(; multinomial = true)
        @test occursin("multinomial", err.value.msg)
        err = @test_throws ArgumentError _reject_extra(Multinomial(2, [0.5, 0.5]))
        @test occursin("multinomial", err.value.msg)
    end

    @testset "k>1 site evaluator still routes through the gate" begin
        @test_throws ArgumentError _ineligible_site(; k = 3, row_effects = true)
        @test_throws ArgumentError _ineligible_site(; k = 3, phylo = true)
        @test_throws ArgumentError _ineligible_site(; k = 3, mi = true)
        @test_throws ArgumentError _ineligible_site(; k = 3, unique_latent = true)
        @test_throws ArgumentError _ineligible_site(; k = 3, s_B = ones(1))
        @test_throws ArgumentError _ineligible_site(; k = 3, use_lv_B = true)
        @test_throws ArgumentError _ineligible_site(; k = 3, multinomial = true)
        # Gate fires before the mode / Cholesky path: ineligible kwargs throw
        # ArgumentError even when the site payload cannot be evaluated.
        err = try
            GLLVM.aghq_stage1a_loglik_site(
                Poisson(), Int[], Int[], zeros(0, 1), Float64[],
                GLLVM.LogLink(); k = 3, phylo = true)
            nothing
        catch e
            e
        end
        @test err isa ArgumentError
        @test occursin("phylogenetic", err.msg)
    end

    @testset "k=1 still matches dense Laplace (Stage-1b golden intact)" begin
        Random.seed!(1714)
        p, K = 4, 2
        β = randn(p) .* 0.4 .+ 0.8
        Λ = 0.5 .* randn(p, K)
        y = [rand(Poisson(exp(β[t]))) for t in 1:p]
        n = ones(Int, p)
        link = GLLVM.LogLink()
        fam = Poisson()
        lap = GLLVM.laplace_loglik_site(fam, y, n, Λ, β, link)
        aghq = GLLVM.aghq_stage1a_loglik_site(fam, y, n, Λ, β, link; k = 1)
        @test isfinite(lap) && isfinite(aghq)
        @test aghq ≈ lap atol = 1e-12
    end
end
