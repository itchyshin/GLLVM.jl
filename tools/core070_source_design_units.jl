using GLLVM, Test
@assert realpath(Base.pkgdir(GLLVM))==realpath(pwd())
@testset "Source design integration" begin
    for file in ("test_gaussian_source_design.jl", "test_formula_sources.jl",
                 "test_gaussian_sources.jl", "test_gaussian_sources_fixed_residual.jl",
                 "test_gaussian_source_bindings.jl", "test_formula_pervar.jl")
        include(joinpath(pwd(), "test", file))
    end
end
println("CORE070_SOURCE_DESIGN_UNITS_PASS")
