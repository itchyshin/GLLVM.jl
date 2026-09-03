using GLLVM,Test
@assert realpath(Base.pkgdir(GLLVM))==realpath(pwd())
@testset "Ordinary NB2 production kernel precision" begin
 include(joinpath(pwd(),"test/test_nb2_precision.jl"))
end
println("NB2_PRODUCTION_PRECISION_PASS")
