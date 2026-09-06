#!/usr/bin/env julia
# M2-S1 remainder: prove contract §5 receipt fields and se=TRUE dispatch.
# Uses the existing Poisson toy cell (already an EOO smoke on main).
# Harness-only — no src/ or R engine edits.
#
# Usage:
#   julia --project=. tools/core070_second_order/smoke_se_true_schema.jl [output.json]

using GLLVM, RCall, Dates, Random, LinearAlgebra, ForwardDiff

const OUT_DEFAULT = joinpath(@__DIR__, "..", "..", "docs", "dev-log", "core070",
    "se-true-schema-smoke-receipt-2026-09-06.json")

include(joinpath(@__DIR__, "common.jl"))
include(joinpath(@__DIR__, "cells.jl"))
include(joinpath(@__DIR__, "eoo_assess.jl"))

out_path = length(ARGS) ≥ 1 ? ARGS[1] : OUT_DEFAULT
mkpath(dirname(out_path))

t0 = time()
cell = run_one_cell("poisson")
wall = time() - t0

missing = missing_s5_keys(cell)
issues = String[]
if !isempty(missing)
    push!(issues, "missing contract §5 keys: $(join(missing, ", "))")
end
if get(cell, "r_has_sd_report", false) !== true
    push!(issues, "r_has_sd_report is not true — se=TRUE path did not produce sd_report")
end
if !haskey(cell, "r_objective") || cell["r_objective"] === nothing ||
        !(cell["r_objective"] isa Real) || !isfinite(Float64(cell["r_objective"]))
    push!(issues, "r_objective missing or non-finite")
end
if get(cell, "matched_coordinates", true) !== false
    push!(issues, "matched_coordinates must be false for this EOO schema smoke")
end

pass = isempty(issues)
receipt = merge(cell, eoo_receipt_extras("poisson", "se-true-schema-smoke-m2-s1"),
    Dict{String,Any}(
        "schema_smoke_pass" => pass,
        "schema_smoke_issues" => issues,
        "missing_s5_keys" => missing,
        "se_true_dispatched" => get(cell, "r_has_sd_report", false) === true,
        "wall_sec" => wall,
    ))

write_json(out_path, receipt)
status = pass ? "PASS" : "FAIL"
println("SE_TRUE_SCHEMA_SMOKE $status ($(round(wall; digits=1))s)")
for iss in issues
    println("  issue: $iss")
end
exit(pass ? 0 : 1)
