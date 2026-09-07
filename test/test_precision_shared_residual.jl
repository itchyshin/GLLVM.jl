using Test, GLLVM, LinearAlgebra, SparseArrays

function _shared_residual_precision_fixture()
    Q = sparse([4.0 -1.0 -1.0 0.0;
                -1.0 3.0 0.0 -1.0;
                -1.0 0.0 3.0 0.0;
                0.0 -1.0 0.0 3.0])
    i, j, x = findnz(Q)
    phy = PrecisionPhy(i, j, x, 4, 2, ["a1", "a2", "s1", "s2"],
        logdet(cholesky(Symmetric(Matrix(Q)))), 1.0, [3, 4])
    Y = [1.3 0.8 1.1 0.9;
         -0.2 0.3 0.1 -0.1;
         0.7 0.5 0.6 0.8]
    beta = [1.0, 0.0, 0.6]
    loading = reshape([0.4, -0.2, 0.3], 3, 1)
    return (; Q, phy, Y, beta, loading, species_id=[1, 2, 1, 2])
end

function _shared_residual_dense_nll(Y, phy, beta, loading, residual_sd, species_id)
    d, m = size(Y)
    selector = zeros(m, phy.n_aug)
    for observation in 1:m
        selector[observation, phy.species_aug_id[species_id[observation]]] = 1.0
    end
    covariance = kron(selector * (Matrix(phy.Q) \ Matrix(I, phy.n_aug, phy.n_aug)) * selector',
        loading * loading') + residual_sd^2 * Matrix(I, d * m, d * m)
    residual = vec(Y) - GLLVM._trait_mean_design(d, m) * beta
    return (length(residual) * log(2pi) + logdet(covariance) +
        dot(residual, covariance \ residual)) / 2
end

@testset "precision multivariate shared residual" begin
    fixture = _shared_residual_precision_fixture()
    d, m = size(fixture.Y)
    log_sd = log(0.55)
    shared_theta = vcat(fixture.beta, GLLVM.pack_lambda(fixture.loading), log_sd)
    trait_theta = vcat(fixture.beta, GLLVM.pack_lambda(fixture.loading),
        fill(log_sd, d))

    shared = GLLVM._precision_multivariate_unpack(shared_theta, d, 1,
        :barelowrank, d; residual_mode=:shared)
    trait = GLLVM._precision_multivariate_unpack(trait_theta, d, 1,
        :barelowrank, d)
    @test length(shared_theta) == GLLVM._pmv_layout(d, 1, :barelowrank, d;
        residual_mode=:shared).total == 7
    @test length(trait_theta) == GLLVM._pmv_layout(d, 1, :barelowrank, d).total == 9
    @test shared.residual_variance == fill(0.55^2, d)
    @test trait.residual_variance == fill(0.55^2, d)

    dense = _shared_residual_dense_nll(fixture.Y, fixture.phy, fixture.beta,
        fixture.loading, 0.55, fixture.species_id)
    sparse_shared = GLLVM._precision_multivariate_nll(fixture.Y, fixture.phy,
        shared_theta; rank=1, mode=:barelowrank, residual_mode=:shared,
        species_id=fixture.species_id)
    sparse_trait = GLLVM._precision_multivariate_nll(fixture.Y, fixture.phy,
        trait_theta; rank=1, mode=:barelowrank, species_id=fixture.species_id)
    @test sparse_shared ≈ dense atol=1e-10
    @test sparse_trait ≈ dense atol=1e-10

    shared_fit = GLLVM.fit_precision_multivariate(fixture.Y, fixture.phy;
        rank=1, mode=:barelowrank, residual_mode=:shared,
        species_id=fixture.species_id, start=shared_theta, iterations=0)
    trait_fit = GLLVM.fit_precision_multivariate(fixture.Y, fixture.phy;
        rank=1, mode=:barelowrank, species_id=fixture.species_id,
        start=trait_theta, iterations=0)
    @test shared_fit.residual_mode === :shared
    @test trait_fit.residual_mode === :trait
    @test length(shared_fit.parameters) == 7 && dof(shared_fit) == 7
    @test length(trait_fit.parameters) == 9 && dof(trait_fit) == 9
    @test shared_fit.parameter_labels[end] == "log_sd_residual_shared"
    @test trait_fit.parameter_labels[end] == "log_sd_residual[3]"
    shared_targets = GLLVM._pmv_targets(shared_fit)
    @test [target.name for target in shared_targets if occursin("residual", target.name)] ==
        ["residual_var_shared[1]", "residual_var_shared[2]", "residual_var_shared[3]"]
    @test all(target -> target.value(shared_fit.parameters) == 0.55^2,
        filter(target -> occursin("residual", target.name), shared_targets))
    @test GLLVM._destination_b_fixed_objective(shared_fit)(shared_fit.parameters) ≈
        sparse_shared atol=1e-10
    public_fit = GLLVM.fit_gllvm(fixture.Y; family=GLLVM.Normal(), phylo=fixture.phy,
        phylo_rank=1, phylo_mode=:barelowrank, residual_mode=:shared,
        species_id=fixture.species_id, start=shared_theta, iterations=0)
    @test public_fit isa GLLVM.PrecisionMultivariateFit
    @test public_fit.residual_mode === :shared
    @test public_fit.parameters == shared_theta
    @test_throws ArgumentError GLLVM._precision_multivariate_unpack(shared_theta, d, 1,
        :barelowrank, d; residual_mode=:invalid)
end
