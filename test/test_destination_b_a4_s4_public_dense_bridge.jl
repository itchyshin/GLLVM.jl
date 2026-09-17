using Test
using LinearAlgebra
using SparseArrays
using GLLVModels

include(joinpath(@__DIR__, "..", "tools", "destination_b",
    "a4_s4_fixed_coordinate_evaluator.jl"))

@testset "A4/S4 public dense bridge keeps the admission fence" begin
    core070 = joinpath(@__DIR__, "..", "docs", "dev-log", "core070")
    dense = a4_s4_fixed_coordinate_fixture(:dense; core070 = core070)

    # R order is [beta; log residual SD; loadings]; the Julia candidate keeps
    # [beta; loadings; log residual SD].  Iterations = 0 makes this a
    # fixed-coordinate public transport check, not optimiser parity.
    theta_r = [0.4, -0.2, 0.3, -1.2039728043259361, 0.9, 0.5, -0.6]
    theta_julia = [theta_r[1:3]; theta_r[5:7]; theta_r[4]]
    expected_nll = GLLVModels._precision_multivariate_nll(dense.Y, dense.phy,
        theta_julia; rank = 1, mode = :barelowrank, residual_mode = :shared,
        species_id = dense.species_id)

    options = Dict("phylo_model" => "multivariate",
        "species_id" => dense.species_id,
        "mode" => "barelowrank", "residual_mode" => "shared",
        "start" => theta_julia, "iterations" => 0, "ci_method" => "none")
    result = GLLVModels.bridge_fit(y = dense.Y, phylo = dense.phy,
        family = "gaussian", d = 1,
        options = options)

    @test result.parameters == theta_julia
    @test result.loglik ≈ -expected_nll atol = 1e-12
    @test result.admission_status == "closed"
    @test result.admission_scope == "R phylo_rr"
    @test result.scale == dense.phy.scale == 1.0
    @test result.species_id == dense.species_id
    @test result.species_aug_id == dense.phy.species_aug_id
    @test result.log_det == dense.phy.log_det
    @test result.ci_status == "not_requested"

    # The R payload already carries Q = inv(A + ridge*I). Reconstructing and
    # ridging/inverting again is a distinct model and must not be invisible at
    # the public bridge boundary.
    A_once = inv(Matrix(dense.phy.Q))
    Q_twice = Matrix(Symmetric(inv(A_once + 1e-8I)))
    ii, jj, vv = findnz(sparse(Q_twice))
    twice = GLLVModels.PrecisionPhy(ii, jj, vv, dense.phy.n_aug, dense.phy.n_leaves,
        dense.phy.node_labels, logdet(cholesky(Symmetric(Q_twice))), dense.phy.scale,
        dense.phy.species_aug_id)
    twice_result = GLLVModels.bridge_fit(y = dense.Y, phylo = twice,
        family = "gaussian", d = 1, options = options)
    @test abs(twice_result.loglik - result.loglik) > 1e-10
    @test twice_result.admission_status == "closed"
end
