using GLLVM, Test, LinearAlgebra, SparseArrays

# Destination B multivariate precision consumer: a deliberately tiny dense
# oracle only.  Production must never materialise this p*d covariance.
function _mv_precision_fixture()
    q_base = [4.0 -1.0 -1.0  0.0;
             -1.0  3.0  0.0 -1.0;
             -1.0  0.0  3.0  0.0;
              0.0 -1.0  0.0  3.0]
    applied_scale = 2.5
    q = sparse(applied_scale .* q_base)
    ii, jj, xx = findnz(q)
    pp = PrecisionPhy(ii, jj, xx, 4, 2,
        ["ancestor_1", "ancestor_2", "species_A", "species_B"],
        logdet(cholesky(Symmetric(Matrix(q)))), applied_scale, [3, 4])
    y = [0.4 -0.7 0.2;
         -0.3 0.1 0.9]
    loading = [0.8 0.0;
               -0.2 0.5;
                0.3 -0.4]
    phylo_unique_variance = [0.2, 0.15, 0.3]
    psi = [0.6, 0.9, 0.5]
    return pp, q_base, y, loading, phylo_unique_variance, psi, 0.7
end

function _mv_dense_reference(y, pp, loading, psi, sigma2_phy;
                             phylo_unique_variance = zeros(size(loading, 1)),
                             species_id = collect(1:pp.n_leaves))
    n_obs, d = size(y)
    selector = zeros(n_obs, pp.n_aug)
    for i in 1:n_obs
        selector[i, pp.species_aug_id[species_id[i]]] = 1.0
    end
    prior_cov = sigma2_phy .* inv(Matrix(pp.Q))
    trait_covariance = loading * loading' + Diagonal(phylo_unique_variance)
    residual = kron(Diagonal(psi), Matrix(I, n_obs, n_obs))
    sigma_y = kron(trait_covariance, selector * prior_cov * selector') + residual
    chol = cholesky(Symmetric(sigma_y))
    return -0.5 * (length(y) * log(2pi) + logdet(chol) + dot(vec(y), chol \ vec(y)))
end

function _mv_rewrap(pp; q = pp.Q, scale = pp.scale, map = pp.species_aug_id,
                    log_det = pp.log_det)
    ii, jj, xx = findnz(q)
    PrecisionPhy(ii, jj, xx, pp.n_aug, pp.n_leaves, pp.node_labels,
                 log_det, scale, map)
end

@testset "Destination B multivariate precision consumer" begin
    pp, q_base, y, loading, phylo_unique_variance, psi, sigma2_phy = _mv_precision_fixture()
    expected = _mv_dense_reference(y, pp, loading, psi, sigma2_phy;
                                   phylo_unique_variance = phylo_unique_variance)

    @testset "sparse augmented marginal equals independent dense oracle" begin
        got = GLLVM.multivariate_phylo_precision_loglik(y, pp, loading, psi;
            sigma2_phy = sigma2_phy, phylo_unique_variance = phylo_unique_variance)
        @test isapprox(got, expected; atol = 1e-10, rtol = 1e-10)
    end

    @testset "scale is already represented in Q and is not applied twice" begin
        double_q = pp.scale .* pp.Q
        # This mimics an adapter that applies the already-recorded scale a
        # second time, while still keeping its precision log determinant
        # internally coherent.
        double_scaled = _mv_rewrap(pp; q = double_q,
            log_det = logdet(cholesky(Symmetric(Matrix(double_q)))))
        wrong = GLLVM.multivariate_phylo_precision_loglik(y, double_scaled, loading, psi;
            sigma2_phy = sigma2_phy, phylo_unique_variance = phylo_unique_variance)
        @test !isapprox(wrong, expected; atol = 1e-6, rtol = 1e-6)
        @test_throws ArgumentError GLLVM.multivariate_phylo_precision_loglik(
            y, _mv_rewrap(pp; scale = 0.0), loading, psi;
            sigma2_phy = sigma2_phy, phylo_unique_variance = phylo_unique_variance)
    end

    @testset "adapter converts R covariance log determinant to log|Q|" begin
        covariance_signed_logdet = _mv_rewrap(pp; log_det = -pp.log_det)
        wrong = GLLVM.multivariate_phylo_precision_loglik(
            y, covariance_signed_logdet, loading, psi; sigma2_phy = sigma2_phy,
            phylo_unique_variance = phylo_unique_variance)
        @test !isapprox(wrong, expected; atol = 1e-6, rtol = 1e-6)
    end

    @testset "stored precision log determinant has the exact marginal shift" begin
        delta = 0.37
        shifted = _mv_rewrap(pp; log_det = pp.log_det + delta)
        got_shifted = GLLVM.multivariate_phylo_precision_loglik(
            y, shifted, loading, psi; sigma2_phy = sigma2_phy,
            phylo_unique_variance = phylo_unique_variance)
        active_fields = size(loading, 2) + count(>(0), phylo_unique_variance)
        @test isapprox(got_shifted - expected, active_fields * delta / 2;
                       atol = 1e-10, rtol = 1e-10)

        zero_unique = zeros(3)
        expected_zero = _mv_dense_reference(y, pp, loading, psi, sigma2_phy;
            phylo_unique_variance = zero_unique)
        got_shifted_zero = GLLVM.multivariate_phylo_precision_loglik(
            y, shifted, loading, psi; sigma2_phy = sigma2_phy,
            phylo_unique_variance = zero_unique)
        @test isapprox(got_shifted_zero - expected_zero, size(loading, 2) * delta / 2;
                       atol = 1e-10, rtol = 1e-10)

        partial_unique = [0.2, 0.0, 0.3]
        expected_partial = _mv_dense_reference(y, pp, loading, psi, sigma2_phy;
            phylo_unique_variance = partial_unique)
        got_shifted_partial = GLLVM.multivariate_phylo_precision_loglik(
            y, shifted, loading, psi; sigma2_phy = sigma2_phy,
            phylo_unique_variance = partial_unique)
        partial_fields = size(loading, 2) + count(>(0), partial_unique)
        @test isapprox(got_shifted_partial - expected_partial, partial_fields * delta / 2;
                       atol = 1e-10, rtol = 1e-10)
    end

    @testset "node map controls which retained augmented nodes are observed" begin
        swapped = _mv_rewrap(pp; map = [4, 3])
        wrong = GLLVM.multivariate_phylo_precision_loglik(y, swapped, loading, psi;
            sigma2_phy = sigma2_phy, phylo_unique_variance = phylo_unique_variance)
        @test !isapprox(wrong, expected; atol = 1e-6, rtol = 1e-6)
        @test_throws ArgumentError GLLVM.multivariate_phylo_precision_loglik(
            y, _mv_rewrap(pp; map = [3, 3]), loading, psi;
            sigma2_phy = sigma2_phy, phylo_unique_variance = phylo_unique_variance)
    end

    @testset "repeated observations share their mapped factor row" begin
        repeated_y = vcat(y, y[1:1, :] .+ [0.1 -0.2 0.05])
        species_id = [1, 2, 1]
        repeated_expected = _mv_dense_reference(repeated_y, pp, loading, psi, sigma2_phy;
            species_id = species_id, phylo_unique_variance = phylo_unique_variance)
        repeated_got = GLLVM.multivariate_phylo_precision_loglik(
            repeated_y, pp, loading, psi; sigma2_phy = sigma2_phy,
            phylo_unique_variance = phylo_unique_variance, species_id = species_id)
        @test isapprox(repeated_got, repeated_expected; atol = 1e-10, rtol = 1e-10)
    end

    @testset "residual preserves a nonsingular observed covariance" begin
        @test_throws ArgumentError GLLVM.multivariate_phylo_precision_loglik(
            y, pp, loading, [0.6, 0.0, 0.5]; sigma2_phy = sigma2_phy,
            phylo_unique_variance = phylo_unique_variance)
    end

    @testset "zero U_phy is an explicit low-rank-only case" begin
        zero_unique = zeros(3)
        expected_zero = _mv_dense_reference(y, pp, loading, psi, sigma2_phy;
            phylo_unique_variance = zero_unique)
        got_zero = GLLVM.multivariate_phylo_precision_loglik(
            y, pp, loading, psi; sigma2_phy = sigma2_phy,
            phylo_unique_variance = zero_unique)
        @test isapprox(got_zero, expected_zero; atol = 1e-10, rtol = 1e-10)
    end

    @testset "unique-only and partially-zero U_phy preserve the sparse contract" begin
        unique_only_loading = zeros(size(loading))
        expected_unique = _mv_dense_reference(y, pp, unique_only_loading, psi, sigma2_phy;
            phylo_unique_variance = phylo_unique_variance)
        got_unique = GLLVM.multivariate_phylo_precision_loglik(
            y, pp, unique_only_loading, psi; sigma2_phy = sigma2_phy,
            phylo_unique_variance = phylo_unique_variance)
        @test isapprox(got_unique, expected_unique; atol = 1e-10, rtol = 1e-10)

        partial_unique = [0.2, 0.0, 0.3]
        expected_partial = _mv_dense_reference(y, pp, loading, psi, sigma2_phy;
            phylo_unique_variance = partial_unique)
        got_partial = GLLVM.multivariate_phylo_precision_loglik(
            y, pp, loading, psi; sigma2_phy = sigma2_phy,
            phylo_unique_variance = partial_unique)
        @test isapprox(got_partial, expected_partial; atol = 1e-10, rtol = 1e-10)
    end

    @testset "trait and observation permutations preserve the density" begin
        trait_order = [3, 1, 2]
        trait_permuted = GLLVM.multivariate_phylo_precision_loglik(
            y[:, trait_order], pp, loading[trait_order, :], psi[trait_order];
            sigma2_phy = sigma2_phy, phylo_unique_variance = phylo_unique_variance[trait_order])
        @test isapprox(trait_permuted, expected; atol = 1e-10, rtol = 1e-10)

        repeated_y = vcat(y, y[1:1, :] .+ [0.1 -0.2 0.05])
        species_id = [1, 2, 1]
        repeated = GLLVM.multivariate_phylo_precision_loglik(
            repeated_y, pp, loading, psi; sigma2_phy = sigma2_phy,
            phylo_unique_variance = phylo_unique_variance, species_id = species_id)
        observation_order = [3, 1, 2]
        observation_permuted = GLLVM.multivariate_phylo_precision_loglik(
            repeated_y[observation_order, :], pp, loading, psi; sigma2_phy = sigma2_phy,
            phylo_unique_variance = phylo_unique_variance,
            species_id = species_id[observation_order])
        @test isapprox(observation_permuted, repeated; atol = 1e-10, rtol = 1e-10)
    end

    @testset "nonzero mean is explicitly residualized before kernel evaluation" begin
        trait_mean = [1.2, -0.4, 0.7]
        raw_y = y .+ reshape(trait_mean, 1, :)
        residualized = raw_y .- reshape(trait_mean, 1, :)
        got = GLLVM.multivariate_phylo_precision_loglik(
            residualized, pp, loading, psi; sigma2_phy = sigma2_phy,
            phylo_unique_variance = phylo_unique_variance)
        @test isapprox(got, expected; atol = 1e-10, rtol = 1e-10)
    end

    @testset "posterior-mode quadratic stays finite at high signal and small residual" begin
        high_signal_loading = reshape([1e6], 1, 1)
        high_signal_residual = [1e-8]
        high_signal_y = reshape([1e6, -1e6], 2, 1)
        expected_extreme = _mv_dense_reference(high_signal_y, pp,
            high_signal_loading, high_signal_residual, sigma2_phy;
            phylo_unique_variance = [0.0])
        got_extreme = GLLVM.multivariate_phylo_precision_loglik(
            high_signal_y, pp, high_signal_loading, high_signal_residual;
            sigma2_phy = sigma2_phy, phylo_unique_variance = [0.0])
        @test isfinite(got_extreme)
        @test isapprox(got_extreme, expected_extreme; atol = 1e-6, rtol = 1e-10)
    end
end
