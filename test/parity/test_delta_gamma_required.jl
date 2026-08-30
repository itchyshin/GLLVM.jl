# Required same-model check; historical shared-dispersion diagnostic stays intact.
isdefined(@__MODULE__, :core070_delta_matched) ||
    include(joinpath(@__DIR__, "..", "..", "tools", "core070_delta_matched.jl"))
core070_delta_matched(:delta_gamma; tight_r=true)
