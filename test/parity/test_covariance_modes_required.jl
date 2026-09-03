# Isolate driver globals; keep Test.jl assertions in the enclosing testset.
module Core070CovarianceModesFixture
const ARGS = [joinpath(Main._core070_receipt_dir(), "covariance-modes-raw"), "tight-control"]
include(joinpath(@__DIR__, "..", "..", "tools", "core070_covariance_mode_fits.jl"))
end
