# Pure-kernel loader: actual source bytes, deliberately not whole-package proof.
using Test, SpecialFunctions, ForwardDiff, SHA, TOML
module Core070Kernel
using Distributions, SpecialFunctions
include(joinpath(pwd(),"src/families/links.jl"))
source=read(joinpath(pwd(),"src/families/truncated_nbinom2.jl"),String)
parts=split(source,"\n_laplace_mode_should_backtrack";limit=2)
length(parts)==2 || error("kernel source boundary missing")
include_string(@__MODULE__,parts[1],"src/families/truncated_nbinom2.jl")
end
const GLLVM=Core070Kernel
const LogLink=Core070Kernel.LogLink
fixture="test/test_truncnb2_precision.jl"
source=read(fixture,String)
startswith(source,"using GLLVM, Test, SpecialFunctions, ForwardDiff\n") || error("unexpected test imports")
source=replace(source,"using GLLVM, Test, SpecialFunctions, ForwardDiff\n"=>"";count=1)
include_string(Main,source,fixture)
println("TRUNCNB2_SOURCE_KERNEL_TESTS_PASS")
