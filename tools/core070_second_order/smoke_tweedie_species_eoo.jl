# Manual / receipt smoke: each-own-optimum second-order for tweedie_species.
# Not CI-gated. Writes under tools/core070_second_order/second-order-batch-out/ when run.
#
# Option A: compare b_fix only; Julia Wald plug-ins per-trait power. Record Δ; no D1 claim.

using GLLVM
using RCall
using Random
using LinearAlgebra
using Statistics
using Dates
using JSON

include(joinpath(@__DIR__, "common.jl"))
include(joinpath(@__DIR__, "cells.jl"))
include(joinpath(@__DIR__, "eoo_assess.jl"))

cell = run_one_cell("tweedie_species")
ok_ll, issues_ll = assess_loglik_receipt(cell)
ok_eoo, issues_eoo = assess_eoo(cell)
cell["eoo_claimed"] = false
cell["eoo_would_pass"] = ok_eoo
cell["eoo_informational_issues"] = issues_eoo
cell["receipt_gate"] = "loglik_only"

println("TWEEDIE_SPECIES_EOO loglik_ok=$ok_ll issues=$(join(issues_ll, "; "))")
println("TWEEDIE_SPECIES_EOO eoo_claimed=false eoo_would_pass=$ok_eoo (informational: $(join(issues_eoo, "; ")))")
println("TWEEDIE_SPECIES_EOO se_rel=$(cell["se_max_relative_delta"]) vcov=$(cell["vcov_frobenius_relative_delta"]) ci=$(cell["ci_endpoint_max_delta"])")
println("TWEEDIE_SPECIES_EOO logLik_delta=$(cell["loglik_delta_jl_minus_r"])")

outdir = joinpath(@__DIR__, "second-order-batch-out")
mkpath(outdir)
open(joinpath(outdir, "tweedie_species.json"), "w") do io
    JSON.print(io, cell, 2)
end
ok_ll || error("tweedie_species logLik receipt FAIL")
