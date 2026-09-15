# §2 Hessian (A) — binomial_cloglog each-own-optimum receipt stays within contract
# tolerances and records hessian_selector_disputed=false.
# Gated like other twin second-order cells (RCall + gllvmTMB pin).

using Test

const _RUN = get(ENV, "GLLVM_PARITY_TESTS", "0") == "1"

@testset "Second-order §2 (A): binomial_cloglog ratified receipt" begin
    if !_RUN
        @test_skip "GLLVM_PARITY_TESTS=1 required (RCall + gllvmTMB)"
    else
        include(joinpath(@__DIR__, "..", "tools", "core070_second_order", "common.jl"))
        include(joinpath(@__DIR__, "..", "tools", "core070_second_order", "cells.jl"))
        include(joinpath(@__DIR__, "..", "tools", "core070_second_order", "eoo_assess.jl"))

        d = run_one_cell("binomial_cloglog")
        @test d["hessian_selector_disputed"] == false
        ok, issues = assess_eoo(d)
        @test ok
        @test isempty(issues)
    end
end
