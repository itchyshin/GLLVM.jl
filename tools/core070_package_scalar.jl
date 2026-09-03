# Load the complete package through Julia's loader, then run the unchanged regression.
using GLLVM, Test, SpecialFunctions, ForwardDiff
using Pkg
@assert realpath(pathof(GLLVM)) == realpath(joinpath(@__DIR__, "..", "src", "GLLVM.jl"))
println("PACKAGE_PATH ", pathof(GLLVM))
println("JULIA_VERSION ", VERSION)
for name in ("Optim", "ForwardDiff", "StatsModels", "Distributions")
    rows = filter(p -> p.second.name == name, collect(Pkg.dependencies()))
    @assert length(rows) == 1
    println("DEPENDENCY ", name, " ", only(rows).second.version)
end
include(joinpath(@__DIR__, "..", "test", "test_truncnb2_precision.jl"))
println("CORE070_FULL_MODULE_SCALAR_PASS")
