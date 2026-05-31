using GLLVM, Test, Random, LinearAlgebra

if !isdefined(GLLVM, :getLoadings)
    include(joinpath(@__DIR__, "..", "src", "postfit.jl"))
end

@testset "post-fit ordination core" begin
    @testset "rotation + getLoadings (Gaussian)" begin
        Random.seed!(0)
        p, K, n = 5, 2, 120
        Λt = 0.8 .* randn(p, K)
        y = Λt * randn(K, n) .+ 0.5 .* randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)

        R = GLLVM.rotation(fit)
        @test size(R) == (K, K)
        @test R' * R ≈ I(K) atol = 1e-10            # orthogonal

        Lr = GLLVM.getLoadings(fit; rotate = true)
        L0 = GLLVM.getLoadings(fit; rotate = false)
        @test size(Lr) == (p, K)
        @test L0 ≈ fit.pars.Λ                         # raw == stored Λ
        @test Lr ≈ L0 * R                             # rotated == Λ·R
        @test Lr * Lr' ≈ L0 * L0' atol = 1e-9         # rotation-invariant ΛΛ'
        # canonical: rotated columns ordered by decreasing norm
        nrm = [norm(@view Lr[:, k]) for k in 1:K]
        @test issorted(nrm; rev = true)
        # sign-fix: largest-magnitude entry of each rotated column is ≥ 0
        for k in 1:K
            @test Lr[argmax(abs.(@view Lr[:, k])), k] ≥ 0
        end
    end
end
