#!/usr/bin/env julia
# M2 remainder: NB2-log each-own-optimum 2SO smoke vs signed contract §4.
# T14: boundary/NaN is recorded, not tolerated-away.
#
# Usage:
#   julia --project=. tools/core070_second_order/smoke_nb2_eoo.jl [output.json]

using GLLVM, RCall, Dates, Random, LinearAlgebra, ForwardDiff

const OUT_DEFAULT = joinpath(@__DIR__, "..", "..", "docs", "dev-log", "core070",
    "nb2-2so-eoo-smoke-receipt-2026-09-06.json")

include(joinpath(@__DIR__, "common.jl"))
include(joinpath(@__DIR__, "cells.jl"))
include(joinpath(@__DIR__, "eoo_assess.jl"))

out_path = length(ARGS) ≥ 1 ? ARGS[1] : OUT_DEFAULT
mkpath(dirname(out_path))

t0 = time()
cell = run_one_cell("nb2_log")
wall = time() - t0

pass, issues = assess_eoo(cell)
receipt = merge(cell, eoo_receipt_extras("nb2_log", "nb2-2so-eoo-smoke-m2-remainder"),
    Dict{String,Any}(
        "eoo_smoke_pass" => pass,
        "eoo_smoke_issues" => issues,
        "wall_sec" => wall,
    ))

write_json(out_path, receipt)
status = pass ? "PASS" : (get(cell, "skip_reason", nothing) !== nothing ? "BLOCKED" : "FAIL")
println("NB2_2SO_EOO_SMOKE $status ($(round(wall; digits=1))s)")
for iss in issues
    println("  issue: $iss")
end
exit(pass ? 0 : 1)
