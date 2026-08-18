using GLLVM, Test, Random, Distributions

# A4(3) affordability: `_aghq_kd_bound` throw-iff k>1 && d>5.
# File-disjoint from #255 (`test/test_aghq_gate.jl` still owns the
# `!isdefined` absence rows). Not a public `aghq=` surface. Not a
# TMB min-fill / treewidth port.

function _bound_site(; k::Integer, d::Integer, kwargs...)
    p = max(d, 3)
    GLLVM.aghq_stage1a_loglik_site(Poisson(), ones(Int, p), ones(Int, p),
                                   ones(p, d), zeros(p), GLLVM.LogLink();
                                   k = k, kwargs...)
end

function _bound_err_names_tensor(err)
    msg = err.msg
    @test occursin("k^d", msg)
    @test occursin("d ≤ 5", msg) || occursin("d<=5", msg)
    @test !occursin("treewidth", lowercase(msg))
    @test !occursin("min-fill", lowercase(msg))
    @test !occursin("sphess", lowercase(msg))
end

@testset "AGHQ A4(3) k^d / d≤5 affordability bound" begin

    @testset "bound(6,3) and (6,2) throw tensor cost, not treewidth" begin
        err = @test_throws ArgumentError GLLVM._aghq_kd_bound(6, 3)
        _bound_err_names_tensor(err.value)
        err = @test_throws ArgumentError GLLVM._aghq_kd_bound(6, 2)
        _bound_err_names_tensor(err.value)
    end

    @testset "site k=3 d=6 throws the bound" begin
        err = @test_throws ArgumentError _bound_site(; k = 3, d = 6)
        _bound_err_names_tensor(err.value)
    end

    @testset "phylo=true is still the phylogenetic error first" begin
        # d=6, k=3 would also trip the bound; eligibility must win.
        err = @test_throws ArgumentError _bound_site(; k = 3, d = 6, phylo = true)
        @test occursin("phylogenetic", err.value.msg)
        @test !occursin("k^d", err.value.msg)
        @test !occursin("treewidth", lowercase(err.value.msg))
    end

    @testset "affordable (d,k) pairs return nothing" begin
        @test GLLVM._aghq_kd_bound(5, 3) === nothing
        @test GLLVM._aghq_kd_bound(1, 3) === nothing
        @test GLLVM._aghq_kd_bound(6, 1) === nothing
        @test GLLVM._aghq_kd_bound(20, 1) === nothing
    end

    @testset "k=1 d=6 site still matches dense Laplace" begin
        Random.seed!(1818)
        p, K = 6, 6
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

    @testset "site k=3 d=5 does not throw" begin
        ll = _bound_site(; k = 3, d = 5)
        @test isfinite(ll)
    end
end
