# Load the complete package through Julia's loader, then run the unchanged regression.
using GLLVModels, Test, SpecialFunctions, ForwardDiff
using Pkg
@assert realpath(pathof(GLLVModels)) == realpath(joinpath(@__DIR__, "..", "src", "GLLVModels.jl"))
println("PACKAGE_PATH ", pathof(GLLVModels))
println("JULIA_VERSION ", VERSION)
for name in ("Optim", "ForwardDiff", "StatsModels", "Distributions")
    rows = filter(p -> p.second.name == name, collect(Pkg.dependencies()))
    @assert length(rows) == 1
    println("DEPENDENCY ", name, " ", only(rows).second.version)
end
include(joinpath(@__DIR__, "..", "test", "test_truncnb2_precision.jl"))
println("CORE070_FULL_MODULE_SCALAR_PASS")
