# Manual / receipt smoke: each-own-optimum second-order for tweedie_fixed.
# Not CI-gated. Writes under tools/core070_second_order/second-order-batch-out/ when run.

using GLLVModels
using RCall
using Random
using LinearAlgebra
using Statistics
using Dates
using JSON

include(joinpath(@__DIR__, "common.jl"))
include(joinpath(@__DIR__, "cells.jl"))
include(joinpath(@__DIR__, "eoo_assess.jl"))

cell = run_one_cell("tweedie_fixed")
ok, issues = assess_eoo(cell)
println("TWEEDIE_FIXED_EOO ok=$ok issues=$(join(issues, "; "))")
println("TWEEDIE_FIXED_EOO se_rel=$(cell["se_max_relative_delta"]) vcov=$(cell["vcov_frobenius_relative_delta"]) ci=$(cell["ci_endpoint_max_delta"])")
println("TWEEDIE_FIXED_EOO logLik_delta=$(cell["loglik_delta_jl_minus_r"])")

outdir = joinpath(@__DIR__, "second-order-batch-out")
mkpath(outdir)
open(joinpath(outdir, "tweedie_fixed.json"), "w") do io
    JSON.print(io, cell, 2)
end
ok || error("tweedie_fixed EOO smoke FAIL")
