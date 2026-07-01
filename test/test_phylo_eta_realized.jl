using Test
using GLLVM
using LinearAlgebra
using Statistics

@testset "phylo Model A eta-realized target" begin
    X_lv = [1.0  0.0;
            2.0  1.0;
            4.0 -1.0;
            5.0  2.0;
            7.0 -2.0;
            8.0  1.5]
    alpha = [0.5 -0.2;
             0.1  0.4]
    innovation = [0.2 -0.1;
                 -0.3  0.4;
                  0.1  0.2;
                  0.0 -0.5;
                  0.4  0.3;
                 -0.2 -0.2]
    Z_truth = X_lv * alpha + innovation
    Lambda = [0.8 -0.3;
             -0.4  0.6;
              0.2  0.5]

    target = GLLVM._eta_realized_lv_effects(X_lv, Z_truth, Lambda)

    Xc = X_lv .- mean(X_lv; dims = 1)
    eta = Z_truth * Lambda'
    etac = eta .- mean(eta; dims = 1)
    manual = transpose((Xc' * Xc) \ (Xc' * etac))

    @test size(target) == (size(Lambda, 1), size(X_lv, 2))
    @test target ≈ manual atol = 1e-12

    # The target is centred: intercept shifts in X_lv or eta_truth do not move it.
    shifted_X = X_lv .+ [10.0 -3.0]
    shifted_Z = Z_truth .+ [2.0 -1.5]
    @test GLLVM._eta_realized_lv_effects(shifted_X, shifted_Z, Lambda) ≈ target atol = 1e-12

    # The eta-scale truth is not the noisy observed-response saturated slope.
    noise = [1.0 -0.5 0.2 1.3 -0.7 0.4;
            -0.2 0.9 -0.6 0.1 0.8 -1.1;
             0.5 0.4 -1.2 0.6 -0.3 1.0]
    Y = transpose(eta) + noise
    design = hcat(ones(size(X_lv, 1)), X_lv)
    response_slopes = transpose((design \ transpose(Y))[2:end, :])
    @test maximum(abs.(target .- response_slopes)) > 0.05

    @test_throws ArgumentError GLLVM._eta_realized_lv_effects(X_lv[1:5, :], Z_truth, Lambda)
    @test_throws ArgumentError GLLVM._eta_realized_lv_effects(X_lv, Z_truth[:, 1:1], Lambda)
    @test_throws ArgumentError GLLVM._eta_realized_lv_effects(ones(6, 2), Z_truth, Lambda)
end
