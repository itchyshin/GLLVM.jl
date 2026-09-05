#!/usr/bin/env julia
# M2 Foundation day-2: Poisson each-own-optimum 2SO smoke vs signed contract §4.
#
# Usage:
#   julia --project=. tools/core070_second_order/smoke_poisson_eoo.jl [output.json]

using GLLVM, RCall, Dates, Random, LinearAlgebra, ForwardDiff

const CONTRACT = joinpath(@__DIR__, "..", "..", "docs", "dev-log", "core070",
    "second-order-parity-contract.md")
const OUT_DEFAULT = joinpath(@__DIR__, "..", "..", "docs", "dev-log", "core070",
    "poisson-2so-eoo-smoke-receipt-2026-09-05.json")

const EOO_SE_REL = 1e-2
const EOO_VCOV_FRO_REL = 1e-2
const EOO_CI_REL_HALF = 5e-2
const COND_SCALE_THRESHOLD = 1e3

include(joinpath(@__DIR__, "common.jl"))
include(joinpath(@__DIR__, "cells.jl"))

function cond_scale(r_cond::Real)
    r_cond > COND_SCALE_THRESHOLD ? r_cond / COND_SCALE_THRESHOLD : 1.0
end

function assess_eoo(d::Dict{String,Any})
    issues = String[]
    if get(d, "skip_reason", nothing) !== nothing
        push!(issues, "skip: $(d["skip_reason"])")
        return false, issues
    end
    r_cond = something(d["r_condition_number"], NaN)
    scale = cond_scale(r_cond)

    se_rel = d["se_max_relative_delta"]
    if se_rel === nothing || !isfinite(se_rel)
        push!(issues, "missing se_max_relative_delta")
    elseif se_rel > EOO_SE_REL * scale
        push!(issues, "SE rel $(se_rel) > tol $(EOO_SE_REL * scale) (scale=$(scale), r_cond=$(r_cond))")
    end

    vcov_rel = d["vcov_frobenius_relative_delta"]
    if vcov_rel !== nothing && isfinite(vcov_rel) && vcov_rel > EOO_VCOV_FRO_REL * scale
        push!(issues, "vcov Fro rel $(vcov_rel) > tol $(EOO_VCOV_FRO_REL * scale)")
    end

    ci_d = d["ci_endpoint_max_delta"]
    if ci_d === nothing || !isfinite(ci_d)
        push!(issues, "missing ci_endpoint_max_delta")
    elseif ci_d <= 1e-4
        # Matched-tier abs bound (§4); sufficient for M2 smoke when well inside tolerance.
        nothing
    else
        # Each-own relative gate when abs is not already tight.
        half = get(d, "ci_r_half_width", nothing)
        if half === nothing || !isfinite(half) || half <= 0
            se_abs = get(d, "se_max_abs_delta", nothing)
            half = se_abs === nothing ? nothing : se_abs * 1.959963984540054
        end
        if half === nothing || half <= 0
            push!(issues, "cannot compute CI half-width for relative gate")
        elseif ci_d / half > EOO_CI_REL_HALF
            push!(issues, "CI endpoint delta $(ci_d) / half-width $(half) > $(EOO_CI_REL_HALF)")
        end
    end

    return isempty(issues), issues
end

out_path = length(ARGS) ≥ 1 ? ARGS[1] : OUT_DEFAULT
mkpath(dirname(out_path))

t0 = time()
cell = run_one_cell("poisson")
wall = time() - t0

pass, issues = assess_eoo(cell)
receipt = merge(cell, Dict{String,Any}(
    "receipt_id" => "poisson-2so-eoo-smoke-m2-day2",
    "receipt_date" => string(Dates.today()),
    "contract" => CONTRACT,
    "tier" => "each-own-optimum",
    "tier_tolerances" => Dict(
        "se_rel" => EOO_SE_REL,
        "vcov_fro_rel" => EOO_VCOV_FRO_REL,
        "ci_rel_half_width" => EOO_CI_REL_HALF,
        "cond_scale_threshold" => COND_SCALE_THRESHOLD,
    ),
    "eoo_smoke_pass" => pass,
    "eoo_smoke_issues" => issues,
    "wall_sec" => wall,
    "claim_boundary" => "M2 Foundation smoke — NOT programme §7 second-order parity claim",
    "git_head" => try chomp(read(`git -C $(joinpath(@__DIR__, "..", "..")) rev-parse HEAD`, String)) catch; "unknown" end,
))

write_json(out_path, receipt)
status = pass ? "PASS" : "FAIL"
println("POISSON_2SO_EOO_SMOKE $status ($(round(wall; digits=1))s)")
for iss in issues
    println("  issue: $iss")
end
exit(pass ? 0 : 1)
