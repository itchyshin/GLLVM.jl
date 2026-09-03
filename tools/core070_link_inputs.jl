using GLLVM, Test
@assert realpath(Base.pkgdir(GLLVM))==realpath(pwd())
include(joinpath(pwd(),"test/test_ordinal_link_input.jl"))
include(joinpath(pwd(),"test/test_core070_link_boundaries.jl"))
