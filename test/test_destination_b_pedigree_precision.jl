using Test, LinearAlgebra, SparseArrays, JSON3, SHA, GLLVModels
include(joinpath(@__DIR__, "fixtures", "destination_b_pedigree.jl"))

@testset "Destination B frozen pedigree ancestor precision" begin
    path = joinpath(@__DIR__, "..", "docs", "dev-log", "core070",
        "destination-b-pedigree", "precision-reference.json")
    reference = JSON3.read(read(path, String))
    @test bytes2hex(sha256(read(path))) == "c428e369e6fb554cc4b9bb03f250418d0d51474ba86e01d1be9c7c7301e615ee"
    @test reference.dll_sha256 == "91bfa6d90fbf3e4f42e1f4160583f2607f51a7839bb54a02a209da6e31a59beb"
    @test reference.schema_version == "destination-b-pedigree-precision-1"
    @test reference.scale == 1
    f = destination_b_pedigree_fixture()
    Q = reduce(vcat, [permutedims(Float64.(row)) for row in reference.Q_canonical])
    @test reference.source_pin == "b4d5fee64def88bc768dda1f1f77c29b295edd86"
    @test reference.package_version == "0.7.0"
    @test reference.fit_performed === false
    @test reference.ridge_applied === false
    @test reference.n_aug == 12 && reference.n_observed == 8
    @test reference.pedigree.sire_one_based_zero_unknown == f.sire
    @test reference.pedigree.dam_one_based_zero_unknown == f.dam
    @test reference.observed_node_one_based == f.observed
    @test reference.matrix_augmented_id_zero_based .+ 1 == f.observation_nodes
    @test f.F[9:10] ≈ [0.25, 0.25] atol=1e-14
    @test f.F[12] > 0
    @test Q ≈ f.Q atol=1e-12 rtol=1e-12
    @test Q*f.A ≈ Matrix{Float64}(I, 12, 12) atol=1e-12 rtol=1e-12
    @test reference.log_det_Q ≈ f.log_det_Q atol=1e-12

    # Trait-fast data order; a fixed response exercises a likelihood as well
    # as covariance. This is not a generated recovery dataset or fitted model.
    m = length(f.observation_nodes)
    loading = reshape([0.8, -0.4, 0.6], 3, 1)
    residual = 0.3^2
    Y = reshape(sin.(collect(1.0:3m)), 3, m)
    Aobs = f.A[f.observation_nodes, f.observation_nodes]
    V = kron(Aobs, loading*loading') + residual*I
    dense = cholesky(Symmetric(V))
    exact = 0.5 * (3m*log(2pi) + logdet(dense) + dot(vec(Y), dense \ vec(Y)))
    ii, jj, vv = findnz(sparse(Q))
    raw = PrecisionPhy(ii, jj, vv, 12, 8, String.(reference.pedigree.node_labels),
        Float64(reference.log_det_Q), Float64(reference.scale), f.observed)
    phy = GLLVModels._validate_precision_fit_input(raw)
    species_id = repeat(collect(1:8); inner=2)
    # The evaluation-only kernel is observations x traits; the public fitter
    # is traits x observations and makes this same transpose internally.
    @test_throws ArgumentError GLLVModels.multivariate_phylo_precision_loglik(Y, phy,
        loading, fill(residual, 3); species_id=species_id)
    got = -GLLVModels.multivariate_phylo_precision_loglik(permutedims(Y), phy, loading,
        fill(residual, 3); species_id=species_id)
    @test got ≈ exact atol=1e-10 rtol=1e-10

    # Dropping unobserved ancestors from Q conditions on them. It must not
    # accidentally reproduce the full marginal observation covariance.
    conditioned = cholesky(Symmetric(Q[f.observed, f.observed])) \ Matrix{Float64}(I, 8, 8)
    @test norm(conditioned - f.A[f.observed, f.observed]) > 0.1
    wrongmap = copy(f.observed)
    wrongmap[1], wrongmap[2] = wrongmap[2], wrongmap[1]
    wrong = PrecisionPhy(ii, jj, vv, 12, 8, String.(reference.pedigree.node_labels),
        Float64(reference.log_det_Q), 1.0, wrongmap)
    wrongnll = -GLLVModels.multivariate_phylo_precision_loglik(permutedims(Y), wrong, loading,
        fill(residual, 3); species_id=species_id)
    @test abs(wrongnll - exact) > 1e-5
end
