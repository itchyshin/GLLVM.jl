using Test

include(joinpath(@__DIR__, "..", "tools", "verify_b1_fixed_coordinate_curvature_protocol.jl"))
using .B1FixedCoordinateCurvatureProtocol

const B1_CURVATURE_PROTOCOL = joinpath(@__DIR__, "..", "docs", "dev-log", "protocols",
    "b1-fixed-coordinate-curvature-audit.toml")

@testset "B1 fixed-coordinate curvature protocol is static and fail-closed" begin
    @test verify_b1_fixed_coordinate_curvature_protocol(B1_CURVATURE_PROTOCOL) === nothing

    protocol_text = read(B1_CURVATURE_PROTOCOL, String)
    mktempdir() do temporary_dir
        hash_drift = joinpath(temporary_dir, "hash-drift.toml")
        write(hash_drift, replace(protocol_text,
            "b4d5fee64def88bc768dda1f1f77c29b295edd86" => "0000000000000000000000000000000000000000"))
        @test_throws ArgumentError verify_b1_fixed_coordinate_curvature_protocol(hash_drift)

        coordinate_drift = joinpath(temporary_dir, "coordinate-drift.toml")
        write(coordinate_drift, replace(protocol_text,
            "\"b_fix\", \"b_fix\", \"log_sigma_eps\"" => "\"log_sigma_eps\", \"b_fix\", \"b_fix\""))
        @test_throws ArgumentError verify_b1_fixed_coordinate_curvature_protocol(coordinate_drift)

        dimension_drift = joinpath(temporary_dir, "dimension-drift.toml")
        write(dimension_drift, replace(protocol_text, "n_observation = 180" => "n_observation = 181"))
        @test_throws ArgumentError verify_b1_fixed_coordinate_curvature_protocol(dimension_drift)
    end
end
