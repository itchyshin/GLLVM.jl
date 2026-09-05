#!/usr/bin/env julia
# run_cell.jl -- core070 second-order (SE / vcov / Wald-CI) receipt driver,
# 2026-09-03. Extends the 5-cell se=TRUE pre-run
# (docs/dev-log/core070/second-order-prerun-2026-09-02.md) to every paired
# harness cell this arc could pair inside the D-139 time box.
#
# Usage: julia --project=. run_cell.jl <cell_id>
# Writes out/<cell_id>.json (one receipt) plus out/<cell_id>_julia.log /
# out/<cell_id>_r.log style stdout is just left on the process's own stdout
# (redirected by the caller).

using GLLVM
using RCall
using LinearAlgebra
using Random
using Distributions: Gamma, NegativeBinomial, Beta, Binomial

const CELL = length(ARGS) >= 1 ? ARGS[1] : error("usage: run_cell.jl <cell_id>")

mkpath("out")

include(joinpath(@__DIR__, "common.jl"))
include(joinpath(@__DIR__, "cells.jl"))

result = run_one_cell(CELL)
write_json(joinpath("out", "$(CELL).json"), result)
println("DONE $CELL")
for (k, v) in result
    println("  $k = $v")
end
