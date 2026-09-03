using Test

include(joinpath(@__DIR__, "shard_util.jl"))

@testset "test sharding: _shard_indices / _parse_shard_spec" begin
    @testset "N shards partition 1:n exactly (disjoint, complete)" begin
        n = 61
        for N in (1, 3, 4, 7)
            shards = [_shard_indices(n, k, N) for k in 1:N]
            @test sort(vcat(shards...)) == collect(1:n)
            for k1 in 1:N, k2 in (k1 + 1):N
                @test isempty(intersect(shards[k1], shards[k2]))
            end
        end
    end

    @testset "_parse_shard_spec accepts well-formed specs" begin
        @test _parse_shard_spec("1/4") == (1, 4)
        @test _parse_shard_spec("4/4") == (4, 4)
        @test _parse_shard_spec("1/1") == (1, 1)
    end

    @testset "_parse_shard_spec rejects malformed/out-of-range specs" begin
        @test_throws ArgumentError _parse_shard_spec("0/4")
        @test_throws ArgumentError _parse_shard_spec("5/4")
        @test_throws ArgumentError _parse_shard_spec("a/b")
        @test_throws ArgumentError _parse_shard_spec("1/0")
        @test_throws ArgumentError _parse_shard_spec("1")
        @test_throws ArgumentError _parse_shard_spec("1/2/3")
    end
end
