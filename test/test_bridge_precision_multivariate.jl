using GLLVM, Test, LinearAlgebra, SparseArrays

function _pmvb_fixture()
    Q = sparse([4.0 -1.0 -1.0 0.0;
                -1.0 3.0 0.0 -1.0;
                -1.0 0.0 3.0 0.0;
                0.0 -1.0 0.0 3.0])
    i, j, x = findnz(Q)
    phy = PrecisionPhy(i, j, x, 4, 2, ["a1", "a2", "s1", "s2"],
        logdet(cholesky(Symmetric(Matrix(Q)))), 1.7, [3, 4])
    Y = [1.3 0.8 1.1 0.9;
         -0.2 0.3 0.1 -0.1;
          0.7 0.5 0.6 0.8]
    species_id = [1, 2, 1, 2]
    beta = [1.0, 0.0, 0.6]
    loading = reshape([0.4, -0.2, 0.3], 3, 1)
    unique = [0.15, 0.10, 0.2]
    residual = [0.5, 0.7, 0.4]
    start = vcat(beta, GLLVM.pack_lambda(loading),
        log.(sqrt.(unique)), log.(sqrt.(residual)))
    return Y, phy, species_id, start, loading, unique, residual
end

@testset "Destination B multivariate precision bridge" begin
    Y, phy, species_id, start, loading, unique, residual = _pmvb_fixture()
    opts = Dict{String,Any}(
        "species_id" => species_id,
        "mode" => "explicitunique",
        "start" => start,
        "iterations" => 0,
        "g_tol" => 1e-4,
        "ci_method" => "none",
    )

    @testset "flat native and admitted-payload fixed-start routes agree" begin
        native_fit = GLLVM.fit_precision_multivariate(Y, phy;
            rank = 1, mode = :explicitunique, species_id = species_id,
            start = start, iterations = 0, g_tol = 1e-4)
        native = GLLVM._bridge_fit_precision_multivariate(Y, phy;
            family = "gaussian", d = 1, options = opts)
        payload = GLLVM.phylo_precision_payload(phy)
        adapter = GLLVM._bridge_fit_precision_multivariate(Y,
            Dict{String,Any}(String(k) => getfield(payload, k) for k in keys(payload));
            family = "normal", d = 1, options = opts)
        routed = GLLVM._bridge_fit_precision_multivariate(Y, phy;
            family = "gaussian", d = 1,
            options = merge(opts, Dict("phylo_model" => "multivariate")))

        @test native.parameters == start
        @test native.parameters == native_fit.parameters == adapter.parameters
        @test routed.parameters == start
        @test native.coefficients == native_fit.beta == adapter.coefficients
        @test native.loadings ≈ loading
        @test native.phylo_unique_variance ≈ unique
        @test native.residual_variance ≈ residual
        @test native.phylo_covariance ≈ loading * loading' + Diagonal(unique)
        @test native.residual_covariance ≈ Diagonal(residual)
        nodes = phy.species_aug_id[species_id]
        K = kron(loading*loading'+Diagonal(unique),inv(Matrix(phy.Q))[nodes,nodes])
        R = kron(Diagonal(residual),Matrix{Float64}(I,4,4))
        mu = vec(permutedims(reshape(native.mean_design*native.coefficients,3,4)))
        centered = vec(permutedims(Y))-mu
        expected_fitted = permutedims(reshape(mu+K*((K+R)\centered),4,3))
        @test native.fitted_values ≈ expected_fitted atol=1e-10 rtol=1e-10
        @test native.fitted_values ≈ adapter.fitted_values
        @test native.prediction_kind == "conditional_plugin"
        @test native.species_id == species_id == adapter.species_id
        @test native.species_aug_id == phy.species_aug_id == adapter.species_aug_id
        @test native.scale == phy.scale == adapter.scale
        @test native.log_det == phy.log_det == adapter.log_det
        @test native.n_leaves == phy.n_leaves
        @test native.n_aug == phy.n_aug
        @test native.family == "gaussian"
        @test native.admission_status == "closed"
        @test native.admission_scope == "R phylo_rr"
        @test native.phylogenetic_signal_status == "estimand_not_admitted"
        @test native.phylogenetic_signal_definition == adapter.phylogenetic_signal_definition
        @test occursin("excludes observation residual", native.phylogenetic_signal_definition)
        @test native.mode == "explicitunique"
        @test native.ci_method == "none"
        @test native.ci_status == "not_requested"
        @test isempty(native.ci_target_names)
        @test all(v -> v isa Number || v isa AbstractArray || v isa AbstractString || v isa Bool,
                  values(native))
    end

    @testset "complete mean design and Wald arrays remain flat" begin
        X = reshape(collect(1.0:(length(Y))), :, 1)
        start_x = vcat([0.1], GLLVM.pack_lambda(loading),
            log.(sqrt.(unique)), log.(sqrt.(residual)))
        opts_x = merge(opts, Dict("start" => start_x, "ci_method" => "wald",
            "ci_level" => 0.9))
        bridged = GLLVM._bridge_fit_precision_multivariate(Y, phy;
            family = "gaussian", d = 1, X = X, options = opts_x)
        @test size(bridged.mean_design) == (length(Y), 1)
        @test length(bridged.coefficients) == 1
        nodes = phy.species_aug_id[species_id]
        K = kron(loading*loading'+Diagonal(unique),inv(Matrix(phy.Q))[nodes,nodes])
        R = kron(Diagonal(residual),Matrix{Float64}(I,4,4))
        mu = vec(permutedims(reshape(X*bridged.coefficients,3,4)))
        expected = permutedims(reshape(mu+K*((K+R)\(vec(permutedims(Y))-mu)),4,3))
        @test bridged.fitted_values ≈ expected atol=1e-10 rtol=1e-10
        @test bridged.ci_method == "wald"
        @test bridged.ci_level == 0.9
        @test length(bridged.ci_target_names) == length(bridged.ci_statuses)
        @test all(==("not_converged"), bridged.ci_statuses)
    end

    @testset "bridge rejects ambiguous or unsupported requests" begin
        @test_throws ArgumentError GLLVM._bridge_fit_precision_multivariate(Y, phy;
            family = "poisson", d = 1, options = opts)
        @test_throws ArgumentError GLLVM._bridge_fit_precision_multivariate(Y, phy;
            family = "gaussian", d = 1, options = Dict("mode" => "barelowrank"))
        @test_throws ArgumentError GLLVM._bridge_fit_precision_multivariate(Y, phy;
            family = "gaussian", d = 1,
            options = merge(opts, Dict("species_id" => [1, 2, 3, 1])))
        @test_throws ArgumentError GLLVM._bridge_fit_precision_multivariate(Y[:, 1:3], phy;
            family = "gaussian", d = 1, options = opts)
        @test_throws ArgumentError GLLVM._bridge_fit_precision_multivariate(Y, phy;
            family = "gaussian", d = 1,
            options = merge(opts, Dict("ci_method" => "profile")))
        @test_throws ArgumentError GLLVM._bridge_fit_precision_multivariate(Y, phy;
            family = "gaussian", d = 1,
            options = merge(opts, Dict("phylo_model" => "univariate")))
        @test_throws ArgumentError GLLVM._bridge_fit_precision_multivariate(Y, phy;
            family = "gaussian", d = 1,
            options = merge(opts, Dict("unrecognised" => true)))
    end
end

@testset "explicit multivariate public bridge dispatch" begin
    Y, phy, ids, start, _, _, _ = _pmvb_fixture()
    options = Dict{String,Any}("phylo_model"=>"multivariate", "species_id"=>ids,
        "mode"=>"explicitunique", "start"=>start, "iterations"=>0)
    result = bridge_fit(y=Y, phylo=phy, family="gaussian", d=1, options=options)
    @test result.model == "precision_multivariate_candidate"
    @test result.species_id == ids
    @test result.parameters == start
    @test_throws ArgumentError bridge_fit(y=Y, phylo=phy, family="gaussian", N=1, options=options)
    @test_throws ArgumentError bridge_fit(y=Y, family="gaussian", options=options)
end
