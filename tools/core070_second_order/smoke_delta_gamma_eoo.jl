#!/usr/bin/env julia
# Delta-Gamma each-own-optimum 2SO smoke (follow-up batch, contract §6).

using GLLVModels, RCall, Dates, Random, LinearAlgebra, ForwardDiff
using Distributions: Gamma

const CONTRACT = joinpath(@__DIR__, "..", "..", "docs", "dev-log", "core070",
    "second-order-parity-contract.md")
const OUT_DEFAULT = joinpath(@__DIR__, "..", "..", "docs", "dev-log", "core070",
    "delta-gamma-2so-eoo-smoke-receipt.json")

include(joinpath(@__DIR__, "common.jl"))
include(joinpath(@__DIR__, "cells.jl"))
include(joinpath(@__DIR__, "eoo_assess.jl"))

out_path = length(ARGS) ≥ 1 ? ARGS[1] : OUT_DEFAULT
mkpath(dirname(out_path))

t0 = time()
cell = run_one_cell("delta_gamma")
wall = time() - t0

pass, issues = assess_eoo(cell)
receipt = merge(cell, Dict{String,Any}(
    "receipt_id" => "delta-gamma-2so-eoo-followup",
    "receipt_date" => string(Dates.today()),
    "contract" => CONTRACT,
    "tier" => "each-own-optimum",
    "eoo_smoke_pass" => pass,
    "eoo_smoke_issues" => issues,
    "wall_sec" => wall,
    "claim_boundary" => "Follow-up batch wiring — NOT programme §7 second-order parity claim",
    "git_head" => try chomp(read(`git -C $(joinpath(@__DIR__, "..", "..")) rev-parse HEAD`, String)) catch; "unknown" end,
))

write_json(out_path, receipt)
status = pass ? "PASS" : "FAIL"
println("DELTA_GAMMA_2SO_EOO_SMOKE $status ($(round(wall; digits=1))s)")
for iss in issues
    println("  issue: $iss")
end
exit(pass ? 0 : 1)
