using GLLVM, Test, LinearAlgebra, ForwardDiff

# SP1.0 foundation: the RE-block descriptor, grouping coding, variance-component
# packing (the only RE params in θ), and the design→per-site expansion. No engine
# wiring yet (that is SP1.1) — these are pure, isolated unit checks.

@testset "random-effects blocks (SP1.0 foundation)" begin

    @testset "re_intercept + grouping coding" begin
        b = re_intercept(:site, [1, 2, 1, 3, 2])          # already integer-coded
        @test b.label === :site
        @test b.grouping == [1, 2, 1, 3, 2]
        @test b.nlevels == 3
        @test b.q == 1
        @test b.cov === :iid
        @test b.Z == ones(5, 1)

        bc = re_intercept(:region, ["b", "a", "b", "c", "a"])   # categorical → codes
        @test bc.grouping == [1, 2, 1, 3, 2]              # b→1, a→2, c→3 (first appearance)
        @test bc.nlevels == 3

        codes, levels = GLLVM._code_grouping(["b", "a", "b", "c"])
        @test codes == [1, 2, 1, 3]
        @test levels == ["b", "a", "c"]
    end

    @testset "re_block design + validation" begin
        n = 6
        Z = hcat(ones(n), Float64.(0:(n - 1)))            # intercept + one slope
        b = re_block(:site, 1:n, Z)
        @test b.q == 2
        @test b.Z == Z
        @test b.nlevels == 6
        @test_throws DimensionMismatch re_block(:site, 1:n, ones(n + 1, 2))
        @test_throws ArgumentError re_block(:site, 1:n, Z; cov = :unstructured)
    end

    @testset "variance-component packing round-trip" begin
        b = re_block(:site, [1, 1, 2, 2, 3], hcat(ones(5), [0.1, 0.2, 0.3, 0.4, 0.5]))  # q=2
        @test GLLVM.re_nhyper(b) == 2
        sds = [0.4, 1.3]
        θ = GLLVM.pack_re_hyper(b, sds)
        @test θ ≈ log.(sds)
        Σ = GLLVM.unpack_re_cov(b, θ)
        @test Σ isa Diagonal
        @test diag(Σ) ≈ sds .^ 2
        @test_throws ArgumentError GLLVM.pack_re_hyper(b, [1.0, -0.5])   # SDs must be > 0
        @test_throws DimensionMismatch GLLVM.pack_re_hyper(b, [1.0])     # wrong q
        @test_throws DimensionMismatch GLLVM.unpack_re_cov(b, [0.0])     # wrong slice length
    end

    @testset "re_expand: per-level U → per-site contribution" begin
        b = re_intercept(:site, [1, 2, 1, 3])            # intercept ⇒ contribution = U[g(i)]
        U = reshape([10.0, 20.0, 30.0], 3, 1)
        @test GLLVM.re_expand(b, U) == [10.0, 20.0, 10.0, 30.0]

        Z = [1.0 0.5; 1.0 2.0; 1.0 -1.0]                 # slope block: Z[i,:]·U[g(i),:]
        bs = re_block(:site, [1, 2, 1], Z)
        Us = [1.0 2.0; 3.0 4.0]                          # 2 levels × 2 components
        # site1: 1·1 + 0.5·2 = 2 ; site2: 1·3 + 2·4 = 11 ; site3: 1·1 + (−1)·2 = −1
        @test GLLVM.re_expand(bs, Us) == [2.0, 11.0, -1.0]
        @test_throws DimensionMismatch GLLVM.re_expand(bs, ones(3, 2))  # wrong nlevels
    end

    @testset "AD-friendliness (Duals flow through)" begin
        b = re_intercept(:g, [1, 2, 2])
        # unpack_re_cov + re_expand preserve eltype under ForwardDiff
        f = logσ -> sum(GLLVM.re_expand(b, reshape([logσ[1], 2.0], 2, 1)))
        @test ForwardDiff.gradient(f, [0.5]) ≈ [1.0]    # ∂/∂U[1] of (U[1]+U[2]+U[2]) summed over sites {1,2,2}
        g = logσ -> diag(GLLVM.unpack_re_cov(b, [logσ[1]]))[1]
        @test ForwardDiff.gradient(g, [0.3])[1] ≈ 2 * exp(2 * 0.3)   # d exp(2x)/dx
    end
end
