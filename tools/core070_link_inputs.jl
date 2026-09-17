using GLLVModels, Test
@assert realpath(Base.pkgdir(GLLVModels))==realpath(pwd())
include(joinpath(pwd(),"test/test_ordinal_link_input.jl"))
include(joinpath(pwd(),"test/test_core070_link_boundaries.jl"))
