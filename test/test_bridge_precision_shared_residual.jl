using GLLVM, Test, LinearAlgebra, SparseArrays

function _pmvshared_fixture()
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
    trait_residual = [0.5, 0.7, 0.4]
    shared_residual = 0.5
    trait_start = vcat(beta, GLLVM.pack_lambda(loading),
        log.(sqrt.(unique)), log.(sqrt.(trait_residual)))
    shared_start = vcat(beta, GLLVM.pack_lambda(loading),
        log.(sqrt.(unique)), log(sqrt(shared_residual)))
    return (; Y, phy, species_id, beta, loading, unique, trait_residual,
        shared_residual, trait_start, shared_start)
end

function _pmvshared_options(fixture; residual_mode = nothing, start)
    options = Dict{String,Any}(
        "species_id" => fixture.species_id,
        "mode" => "explicitunique",
        "start" => start,
        "iterations" => 0,
        "g_tol" => 1e-4,
        "ci_method" => "none",
        "phylo_model" => "multivariate",
    )
    residual_mode === nothing || (options["residual_mode"] = residual_mode)
    return options
end

@testset "multivariate precision bridge shared residual" begin
    fixture = _pmvshared_fixture()

    @testset "shared bridge route matches native objective and packed coordinates" begin
        native = GLLVM.fit_precision_multivariate(fixture.Y, fixture.phy;
            rank = 1, mode = :explicitunique, residual_mode = :shared,
            species_id = fixture.species_id, start = fixture.shared_start,
            iterations = 0, g_tol = 1e-4)
        bridged = GLLVM._bridge_fit_precision_multivariate(fixture.Y, fixture.phy;
            family = "gaussian", d = 1,
            options = _pmvshared_options(fixture; residual_mode = "shared",
                start = fixture.shared_start))
        public = bridge_fit(y = fixture.Y, phylo = fixture.phy,
            family = "gaussian", d = 1,
            options = _pmvshared_options(fixture; residual_mode = "shared",
                start = fixture.shared_start))
        expected_nll = GLLVM._precision_multivariate_nll(fixture.Y, fixture.phy,
            fixture.shared_start; rank = 1, mode = :explicitunique,
            residual_mode = :shared, species_id = fixture.species_id)
        unpacked = GLLVM._precision_multivariate_unpack(fixture.shared_start, 3, 1,
            :explicitunique, 3; residual_mode = :shared)

        @test bridged.parameters == fixture.shared_start == native.parameters
        @test bridged.loglik ≈ native.loglik atol = 1e-12
        @test bridged.loglik ≈ -expected_nll atol = 1e-12
        @test unpacked.residual_variance ≈ fill(fixture.shared_residual, 3)
        @test bridged.residual_variance ≈ fill(fixture.shared_residual, 3)
        @test bridged.residual_covariance ≈ Diagonal(fill(fixture.shared_residual, 3))
        @test bridged.residual_mode == "shared"
        @test bridged.parameter_labels == native.parameter_labels
        @test last(bridged.parameter_labels) == "log_sd_residual_shared"
        @test length(bridged.parameter_labels) == length(bridged.parameters)
        @test bridged.admission_status == "closed"
        @test bridged.admission_scope == "R phylo_rr"
        @test bridged.mode == "explicitunique"
        @test public.parameters == bridged.parameters
        @test public.residual_mode == "shared"
        @test public.parameter_labels == bridged.parameter_labels
        @test public.admission_status == "closed"
    end

    @testset "trait default remains backward-compatible" begin
        native = GLLVM.fit_precision_multivariate(fixture.Y, fixture.phy;
            rank = 1, mode = :explicitunique, species_id = fixture.species_id,
            start = fixture.trait_start, iterations = 0, g_tol = 1e-4)
        bridged = GLLVM._bridge_fit_precision_multivariate(fixture.Y, fixture.phy;
            family = "gaussian", d = 1,
            options = _pmvshared_options(fixture; start = fixture.trait_start))
        public = bridge_fit(y = fixture.Y, phylo = fixture.phy,
            family = "gaussian", d = 1,
            options = _pmvshared_options(fixture; start = fixture.trait_start))

        @test bridged.parameters == fixture.trait_start == native.parameters
        @test bridged.residual_variance ≈ fixture.trait_residual
        @test bridged.residual_mode == "trait"
        @test bridged.parameter_labels == native.parameter_labels
        @test bridged.parameter_labels[end-2:end] ==
            ["log_sd_residual[1]", "log_sd_residual[2]", "log_sd_residual[3]"]
        @test length(bridged.parameter_labels) == length(fixture.trait_start)
        @test public.parameters == bridged.parameters
        @test public.residual_mode == "trait"
        @test public.parameter_labels == bridged.parameter_labels
    end

    @testset "invalid residual mode is rejected rather than ignored" begin
        @test_throws ArgumentError GLLVM._bridge_fit_precision_multivariate(
            fixture.Y, fixture.phy; family = "gaussian", d = 1,
            options = _pmvshared_options(fixture; residual_mode = "diagonal",
                start = fixture.trait_start))
    end
end
