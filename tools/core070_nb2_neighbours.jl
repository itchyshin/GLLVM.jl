# Run the existing truncated-NB2 assertions in the qualified parity environment.
# Its test-only dependencies are already loaded as GLLVM dependencies; bind them
# explicitly without changing the parity environment or any test expression.
using GLLVM, Test
@assert realpath(Base.pkgdir(GLLVM)) == realpath(pwd())
const ForwardDiff = GLLVM.ForwardDiff
const loggamma = GLLVM.loggamma
path = joinpath(pwd(), "test/test_truncnb2_precision.jl")
source = read(path, String)
header = "using GLLVM, Test, SpecialFunctions, ForwardDiff"
@assert startswith(source, header * "\n")
@testset "NB2 truncated neighbour precision" begin
    include_string(Main, replace(source, header => "using GLLVM, Test"; count=1), path)
end
println("NB2_NEIGHBOUR_PRECISION_PASS")
