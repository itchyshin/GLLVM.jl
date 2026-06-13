using GLLVM, Test, LinearAlgebra

# Cross-lineage coevolution kernel (PGLLVM "two lineages", phase C0).
#
# Julia mirror of gllvmTMB::make_cross_kernel (R/kernel-helpers.R). The toy
# inputs below are the same as the gllvmTMB docstring example, so the two
# packages build the byte-identical cross-lineage kernel K* used by the
# coevolution prototype.
@testset "make_cross_kernel (C0)" begin
    A_H = [1.0 0.3 0.1
           0.3 1.0 0.2
           0.1 0.2 1.0]
    A_P = [1.0  0.25
           0.25 1.0]
    W = [1.0 0.0
         0.5 0.0
         1.0 0.25]

    @testset "structural properties (C0.1)" begin
        K = make_cross_kernel(A_H, A_P, W; rho = 0.4)
        Km = Matrix(K)
        # host block first, partner block second
        @test size(K) == (5, 5)
        # (a) symmetric
        @test Km ≈ Km'
        # (b) positive semidefinite
        @test minimum(eigvals(Symmetric(Km))) > -1e-8
        # (c) supplied A_H / A_P sit on the diagonal blocks
        @test Km[1:3, 1:3] ≈ A_H
        @test Km[4:5, 4:5] ≈ A_P
        # (d) unit diagonal (correlation scale)
        @test all(≈(1.0), diag(Km))
    end

    @testset "cross block equals rho * L_H * W̃ * L_P'" begin
        rho = 0.4
        Km = Matrix(make_cross_kernel(A_H, A_P, W; rho = rho))
        sqrtm(A) = (F = eigen(Symmetric(A));
                    F.vectors * Diagonal(sqrt.(max.(F.values, 1e-8))) * F.vectors')
        L_H = sqrtm(A_H)
        L_P = sqrtm(A_P)
        W̃ = W ./ max(svdvals(W)[1], 1e-8)
        C_HP = rho .* L_H * W̃ * L_P'
        @test Km[1:3, 4:5] ≈ C_HP
        @test Km[4:5, 1:3] ≈ C_HP'
    end

    @testset "rho scales the off-diagonal coupling; rho = 0 is the null" begin
        K0 = Matrix(make_cross_kernel(A_H, A_P, W; rho = 0.0))
        # rho = 0 -> block-diagonal (Gamma = 0 baseline)
        @test all(≈(0.0; atol = 1e-12), K0[1:3, 4:5])
        K_lo = Matrix(make_cross_kernel(A_H, A_P, W; rho = 0.2))
        K_hi = Matrix(make_cross_kernel(A_H, A_P, W; rho = 0.6))
        @test maximum(abs, K_hi[1:3, 4:5]) > maximum(abs, K_lo[1:3, 4:5])
    end

    @testset "validation errors" begin
        @test_throws ArgumentError make_cross_kernel(A_H, A_P, W; rho = 1.5)
        @test_throws ArgumentError make_cross_kernel(A_H, A_P, W[1:2, :]; rho = 0.4)
        A_nonsym = [1.0 0.2; 0.4 1.0]
        @test_throws ArgumentError make_cross_kernel(A_nonsym, A_P, W; rho = 0.4)
        A_nonunit = [2.0 0.3 0.1; 0.3 1.0 0.2; 0.1 0.2 1.0]
        @test_throws ArgumentError make_cross_kernel(A_nonunit, A_P, W; rho = 0.4)
    end
end
