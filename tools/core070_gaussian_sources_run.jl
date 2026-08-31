using GLLVM, Test
@assert realpath(Base.pkgdir(GLLVM))==realpath(pwd())
include(joinpath(pwd(),"test/test_gaussian_sources.jl"))
include(joinpath(pwd(),"test/test_gaussian_source_bindings.jl"))
println("CORE070_GAUSSIAN_SOURCES_UNIT_PASS")
