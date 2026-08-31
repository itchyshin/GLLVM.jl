using Test, GLLVM, LinearAlgebra
include(joinpath(@__DIR__, "..", "tools", "core070_gaussian_source_bindings.jl"))

@testset "Retained Core070 source input bindings (not fitted parity)" begin
    ids = ("STRUCT-PHY-TREE-RR", "STRUCT-PHY-DENSE-RR", "STRUCT-PHY-TREE-PROPTO",
        "STRUCT-ANI-PED-SPARSE", "STRUCT-KER-SINGLE-PSI", "STRUCT-KER-MULTI")
    lengths = (7, 7, 5, 7, 10, 10)
    for (i, id) in enumerate(ids)
        b = core070_gaussian_source_binding(id)
        @test b.captured_id == id
        @test b.reference_commit == "b4d5fee64def88bc768dda1f1f77c29b295edd86"
        @test size(b.Y) == (3, 12)
        @test length(b.start) == lengths[i]
        @test b.start[1:3] == [0.5780424816897325, 0.34689924315484166, 0.29137546026000255]
        @test b.start[end] == -0.3943265630257839
        groups = i == 1 ? repeat(2:4, inner=4) :
            i == 4 ? repeat([3, 4], inner=6) : repeat(1:3, inner=4)
        nodes = i in (1, 4) ? 4 : 3
        expected_projection = [Float64(g == j) for g in groups, j in 1:nodes]
        @test length(b.sources) == (i == 6 ? 2 : 1)
        for s in b.sources
            @test s.projection == expected_projection
            @test size(s.covariance) == (nodes, nodes)
        end
        if i == 1
            Q = [6. -2 -2 0; -2 2 0 0; -2 0 2 0; 0 0 0 1]
            @test Q * b.sources[1].covariance ≈ Matrix(I, 4, 4) atol=1e-12
        elseif i == 4
            Q = [2. 1 -1 -1; 1 2 -1 -1; -1 -1 2 0; -1 -1 0 2]
            @test Q * b.sources[1].covariance ≈ Matrix(I, 4, 4) atol=1e-12
        elseif i == 3
            @test b.sources[1].covariance == [1. .5 0; .5 1 0; 0 0 1] + 1e-8I
            @test b.sources[1].mode == :indep && b.sources[1].common
            @test b.start[4] == 0.0 # retained R logvariance / 2
        else
            @test b.sources[1].covariance == .7Matrix(I, 3, 3) + .3ones(3, 3) + 1e-8I
        end
        if i == 5
            @test b.sources[1].unique
            @test b.start[4:9] == [.5, 0, 0, 0, 0, 0]
        elseif i == 6
            v = [1., -1, 1]
            @test b.sources[2].covariance == .6Matrix(I, 3, 3) + .4v*v' + 1e-8I
            @test b.start[4:9] == [.5, 0, 0, .5, 0, 0]
        end
    end
    @test_throws ArgumentError core070_gaussian_source_binding("STRUCT-SPA-LATENT")
    @test_throws ArgumentError _core070_response_matrix(ones(36), zeros(Int, 36), zeros(Int, 36))
    @test_throws DimensionMismatch _core070_response_matrix(ones(35), zeros(Int, 35), zeros(Int, 35))
end
