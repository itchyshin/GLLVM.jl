using Test
using SHA
using TOML

include(joinpath(@__DIR__, "parity", "core070_receipts.jl"))
using .Core070Receipts

_sha(path) = bytes2hex(sha256(read(path)))

@testset "CORE-070 receipt kernel" begin
    nested = @testset "outer fixture" begin
        @testset "inner fixture" begin
            @test true
        end
    end
    @test testset_counts(nested)["passed"] == 1

    mktempdir() do tmp
        expected = joinpath(tmp, "expected")
        other = joinpath(tmp, "other")
        mkpath(joinpath(expected, "src")); mkpath(joinpath(other, "src"))
        write(joinpath(expected, "src", "GLLVM.jl"), "module GLLVM end")
        write(joinpath(other, "src", "GLLVM.jl"), "module GLLVM end")
        @test verify_loaded_source(expected, expected, joinpath(expected, "src", "GLLVM.jl"))
        @test_throws ArgumentError verify_loaded_source(expected, other, joinpath(other, "src", "GLLVM.jl"))
        @test_throws ArgumentError verify_loaded_source(expected, expected, joinpath(other, "src", "GLLVM.jl"))
        fixture = joinpath(tmp, "fixture.jl")
        write(fixture, "# fixture\n")
        inventory_file = joinpath(tmp, "runner.jl")
        write(inventory_file, "# runner\n")
        inventory = execution_inventory(tmp, ["runner.jl"])
        source = Dict("reference_commit" => "pin")

        @test_throws ArgumentError start_run!(tmp;
            requested_case_ids = ["case-a", "case-a"], source, inventory,
            contract_sha256 = "contract")

        run = start_run!(joinpath(tmp, "missing");
            requested_case_ids = ["case-a", "case-b"], source, inventory,
            contract_sha256 = "contract")
        record_case!(run, "case-a", fixture; passed = 2)
        @test_throws ArgumentError finish_run!(run)
        started = TOML.parsefile(joinpath(tmp, "missing", "run.toml"))
        @test started["status"] == "failed"
        @test started["requested_case_ids"] == ["case-a", "case-b"]
        @test started["completed_case_ids"] == ["case-a"]

        run = start_run!(joinpath(tmp, "zero");
            requested_case_ids = ["case-a"], source, inventory,
            contract_sha256 = "contract")
        record_case!(run, "case-a", fixture; passed = 0)
        @test_throws ArgumentError finish_run!(run)
        cell = TOML.parsefile(joinpath(tmp, "zero", "cell-case-a.toml"))
        @test cell["status"] == "failed"
        @test cell["assertions"]["passed"] == 0

        run = start_run!(joinpath(tmp, "broken");
            requested_case_ids = ["case-a"], source, inventory,
            contract_sha256 = "contract")
        record_case!(run, "case-a", fixture; passed = 1, broken = 1)
        @test_throws ArgumentError finish_run!(run)
        cell = TOML.parsefile(joinpath(tmp, "broken", "cell-case-a.toml"))
        @test cell["status"] == "failed"
        @test cell["assertions"]["broken"] == 1

        run = start_run!(joinpath(tmp, "success");
            requested_case_ids = ["case-a"], source, inventory,
            contract_sha256 = "contract")
        record_case!(run, "case-a", fixture; passed = 2)
        @test_throws ArgumentError record_case!(run, "case-a", fixture; passed = 2)
        finish_run!(run)
        complete = TOML.parsefile(joinpath(tmp, "success", "run.toml"))
        @test complete["status"] == "success"
        @test complete["scope"] == "subset"
        @test complete["completed_case_ids"] == ["case-a"]
        @test complete["actual_assertions"] == 2
        @test complete["execution"]["manifest_sha256"] == inventory["manifest_sha256"]
        @test complete["contract_sha256"] == "contract"

        @test _sha(fixture) == complete["cells"]["case-a"]["fixture_sha256"]
    end
end
