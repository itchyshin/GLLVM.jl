using Test, JSON3

@testset "Phylogenetic uncertainty CLI receipt safety" begin
    repository = normpath(joinpath(@__DIR__, ".."))
    core070 = joinpath(repository, "docs", "dev-log", "core070")
    checker = joinpath(repository, "tools", "destination_b", "compare_phylo_uncertainty.jl")
    r_source = joinpath(core070, "destination-b-uncertainty", "tree-r-attempt-01.json")
    precision = joinpath(core070, "destination-b-tree", "precision-reference.json")
    julia_fit = joinpath(core070, "destination-b-tree", "independent-attempt-01.json")

    mktempdir() do directory
        unsealed_r = joinpath(directory, "unsealed-tree-r.json")
        cp(r_source, unsealed_r)
        open(unsealed_r, "a") do io
            write(io, "\n")
        end
        receipt = joinpath(directory, "fresh-error-receipt.json")
        @test !ispath(receipt)

        command = `$(Base.julia_cmd()) --startup-file=no --history-file=no --project=$(dirname(Base.active_project())) $checker $unsealed_r $precision $julia_fit $receipt`
        first = run(pipeline(ignorestatus(command), stdout = devnull, stderr = devnull))
        @test !success(first)
        @test isfile(receipt)
        first_bytes = read(receipt)
        error_receipt = JSON3.read(String(copy(first_bytes)), Dict{String,Any})
        @test error_receipt["status"] == "error"
        @test error_receipt["qualified"] === false
        @test occursin("unsealed uncertainty input files", error_receipt["error"])

        second = run(pipeline(ignorestatus(command), stdout = devnull, stderr = devnull))
        @test !success(second)
        @test read(receipt) == first_bytes
    end
end
