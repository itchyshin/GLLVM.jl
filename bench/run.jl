# Entry point for the BenchmarkTools.jl suite.
#
#     julia --project=bench bench/run.jl
#
# Runs every cell and prints a compact median-wall-clock table. Detailed
# trial data lives in the returned `results` object if a caller wants it.

include("benchmarks.jl")
using BenchmarkTools

println("Running gllvmTMB.jl benchmark suite...")
results = run(SUITE; verbose = true, seconds = 10)

println("\nSummary (median wall-clock per cell):\n")
println(rpad("cell", 22), rpad("benchmark", 12), rpad("median", 14))
for cell_id in sort(collect(keys(results)))
    for k in sort(collect(keys(results[cell_id])))
        med = median(results[cell_id][k])
        ms  = round(time(med) / 1e6, digits = 2)
        println(rpad(cell_id, 22), rpad(k, 12), rpad(string(ms) * " ms", 14))
    end
end
