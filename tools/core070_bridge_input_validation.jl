# Complete module/source-path guard plus no-fit regressions on the current source.
include(joinpath(@__DIR__, "core070_package_scalar.jl"))
include(joinpath(@__DIR__, "..", "test", "test_studentt_retained_precision.jl"))
include(joinpath(@__DIR__, "..", "test", "test_curvature_census.jl"))
include(joinpath(@__DIR__, "..", "test", "test_bridge_truncated_input.jl"))
println("CORE070_BRIDGE_INPUT_ADJACENT_VALIDATION_PASS")
