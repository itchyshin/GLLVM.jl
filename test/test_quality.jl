using GLLVM, Test, SparseArrays

# Quality battery. Aqua (hygiene) + JET (type-stability) live in
# test/Project.toml, so they run under `Pkg.test()` (the full suite — what CI
# runs) and skip gracefully under the bare `julia --project=. test/runtests.jl`
# core run, where they are not installed.

const _HAS_AQUA = Base.find_package("Aqua") !== nothing
const _HAS_JET  = Base.find_package("JET")  !== nothing
_HAS_AQUA && @eval using Aqua
_HAS_JET  && @eval using JET

@testset "quality" begin
    @testset "Aqua (package hygiene)" begin
        if _HAS_AQUA
            # ambiguities=false: method ambiguities here originate in
            # dependencies, not GLLVM, so they are noise for this hygiene gate.
            Aqua.test_all(GLLVM; ambiguities = false)
        else
            @info "Aqua not in this environment — run `Pkg.test()` for the full battery"
            @test_skip false
        end
    end

    @testset "JET type-stability (O(p) Takahashi kernels)" begin
        if _HAS_JET
            # The `JET.@test_opt` macros live in a separate file so they are
            # only PARSED when JET is present — macros expand at lowering,
            # before this runtime guard, so an inline call would UndefVarError
            # under the JET-less core run.
            include("test_quality_jet.jl")
        else
            @info "JET not in this environment — run `Pkg.test()` for the type-stability gate"
            @test_skip false
        end
    end
end
