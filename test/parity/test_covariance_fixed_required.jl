# Isolate driver globals; keep Test.jl assertions in the enclosing testset.
module Core070CovarianceFixedFixture
const ARGS = [joinpath(Main._core070_receipt_dir(), "covariance-fixed-raw")]
include(joinpath(@__DIR__, "..", "..", "tools", "core070_source_fixed_residual_pair.jl"))
end
