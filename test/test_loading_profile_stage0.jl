using Test

include("parity/fixtures/loading_profile_confirmatory_substrate.jl")
include("parity/loading_profile_confirmatory_substrate.jl")

const _P = LOADING_PROFILE_CONFIRMATORY_P
const _K = LOADING_PROFILE_CONFIRMATORY_K

@testset "loading_profile confirmatory substrate (D3 Stage 0)" begin
    @testset "frozen Core070 pin fixtures match R oracles" begin
        pins = loading_profile_fixture_mask_b_pins()
        @test pins[1, 1] == -0.8
        @test pins[3, 2] == 0.0
        @test isnan(pins[1, 2])
        @test isnan(pins[2, 1])
        @test isnan(pins[2, 2])
        @test isnan(pins[3, 1])

        upper = loading_profile_fixture_mask_b_upper()
        @test isapprox(
            normalize_lambda_constraint_pin_matrix(upper),
            normalize_lambda_constraint_pin_matrix(pins);
            nans=true,
        )

        allfixed = loading_profile_fixture_mask_b_allfixed()
        @test allfixed[1, 1] == 0.8
        @test isnan(allfixed[1, 2])
        @test allfixed[2, 2] == 0.7
    end

    @testset "free-index enumeration matches gllvmTMB loading_profile" begin
        pins = loading_profile_fixture_mask_b_pins()
        free = enumerate_free_lambda_entries(pins, _P, _K)
        @test free == LOADING_PROFILE_ORACLE_FREE_MASK_B_PINS
        @test length(free) == LOADING_PROFILE_ORACLE_FREE_COUNT_MASK_B_PINS

        allfixed = loading_profile_fixture_mask_b_allfixed()
        @test enumerate_free_lambda_entries(allfixed, _P, _K) == LOADING_PROFILE_ORACLE_FREE_MASK_B_ALLFIXED

        @test_throws ArgumentError enumerate_free_lambda_entries(
            pins, _P, _K; entries=[1 1; 3 2],
        )
        @test_throws ArgumentError enumerate_free_lambda_entries(
            pins, _P, _K; entries=[1 2],
        )
    end

    @testset "structural upper-triangle zeros (k > i)" begin
        M = fill(NaN, _P, _K)
        pinned = lambda_constraint_is_pinned(M, _P, _K)
        @test pinned[1, 2]
        @test !pinned[2, 1]
        @test !pinned[3, 1]
        @test !pinned[2, 2]
        @test !pinned[3, 2]
    end

    @testset "profile refit pin matrix preserves other user pins" begin
        pins = loading_profile_fixture_mask_b_pins()
        M = profile_refit_lambda_constraint(pins, _P, _K, 2, 1, 0.42)
        @test M[2, 1] == 0.42
        @test M[1, 1] == -0.8
        @test M[3, 2] == 0.0
        @test isnan(M[1, 2])
    end
end
