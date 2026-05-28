module gllvmTMB

using LinearAlgebra, Distributions, Optim, ForwardDiff, Random

include("packing.jl")
include("likelihood.jl")
include("fit.jl")
include("simulate.jl")

# Top-level API surface (signature locked here; bodies filled by J1-B)
export fit_gaussian_gllvm, GllvmModel, GllvmFit

end # module gllvmTMB
