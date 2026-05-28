# Tests for src/lowrank_cholesky.jl.
#
# The struct + methods are not currently exported from the top-level module
# (this stage is library-internal), so we include the source directly and
# reference the symbols unqualified. If lowrank_cholesky.jl gets wired into
# gllvmTMB.jl proper later, swap the include for `using gllvmTMB`.

using Test, Random, LinearAlgebra

if !@isdefined(low_rank_chol)
    include(joinpath(@__DIR__, "..", "src", "lowrank_cholesky.jl"))
end

@testset "low-rank + diagonal Cholesky" begin
    @testset "solve matches dense M⁻¹ b" begin
        Random.seed!(0)
        for (p, K) in [(5, 1), (10, 2), (20, 3), (50, 5)]
            Λ = randn(p, K)
            d = 0.5 .+ rand(p)
            b = randn(p)
            # Reference: dense solve
            M = Λ * Λ' + Diagonal(d)
            x_ref = M \ b
            # Our solve
            F = low_rank_chol(Λ, d)
            x_ours = F \ b
            @test x_ours ≈ x_ref rtol = 1e-10
        end
    end

    @testset "logdet matches dense" begin
        Random.seed!(1)
        for (p, K) in [(5, 1), (10, 2), (20, 3)]
            Λ = randn(p, K)
            d = 0.5 .+ rand(p)
            M = Λ * Λ' + Diagonal(d)
            F = low_rank_chol(Λ, d)
            @test logdet(F) ≈ logdet(Symmetric(M)) rtol = 1e-10
        end
    end

    @testset "AD-friendly: works with ForwardDiff.Dual" begin
        using ForwardDiff
        p, K = 5, 1
        d = [0.5, 0.6, 0.7, 0.8, 0.9]
        f = (Λ_vec) -> begin
            Λ = reshape(Λ_vec, p, K)
            F = low_rank_chol(Λ, d)
            return logdet(F)
        end
        Λ0 = randn(p * K)
        g = ForwardDiff.gradient(f, Λ0)
        @test all(isfinite, g)

        # Same for a solve-based scalar functional:
        b = randn(p)
        f2 = (Λ_vec) -> begin
            Λ = reshape(Λ_vec, p, K)
            F = low_rank_chol(Λ, d)
            return sum(F \ b)
        end
        g2 = ForwardDiff.gradient(f2, Λ0)
        @test all(isfinite, g2)
    end

    @testset "performance vs generic Cholesky" begin
        # Prefer BenchmarkTools (`@belapsed`) when it is available; otherwise
        # fall back to a warm-up + minimum-of-N @elapsed loop so this testset
        # still passes in a stock Project.toml environment.
        p, K = 50, 3
        Λ = randn(p, K)
        d = 0.5 .+ rand(p)
        b = randn(p)
        M = Λ * Λ' + Diagonal(d)

        # Sanity check that there is something to benchmark.
        F = low_rank_chol(Λ, d)
        @test F \ b ≈ (cholesky(Symmetric(M)) \ b) rtol = 1e-10

        has_btools = try
            @eval Main using BenchmarkTools
            true
        catch
            false
        end

        if has_btools
            # Use @eval so that @belapsed (from BenchmarkTools) is only
            # macroexpanded when the package is actually loaded.
            t_generic = @eval Main @belapsed cholesky(Symmetric($M)) \ $b
            t_ours    = @eval Main @belapsed ($low_rank_chol($Λ, $d) \ $b)
        else
            # Warm-up to compile.
            cholesky(Symmetric(M)) \ b
            low_rank_chol(Λ, d) \ b
            # Minimum across a handful of repeats; each repeat runs N inner
            # iterations to amortise timer overhead.
            N    = 2000
            reps = 5
            time_generic = function ()
                t = @elapsed for _ in 1:N
                    cholesky(Symmetric(M)) \ b
                end
                return t / N
            end
            time_ours = function ()
                t = @elapsed for _ in 1:N
                    low_rank_chol(Λ, d) \ b
                end
                return t / N
            end
            t_generic = minimum(time_generic() for _ in 1:reps)
            t_ours    = minimum(time_ours() for _ in 1:reps)
        end

        @info "Cholesky solve timings (p=$p, K=$K): generic=$(round(t_generic*1e6, digits=1)) μs, ours=$(round(t_ours*1e6, digits=1)) μs, speedup=$(round(t_generic/t_ours, digits=2))×"
        # Don't gate on speedup — depends on p, K, BLAS — but log it.
        @test t_ours > 0
        @test t_generic > 0
    end
end
