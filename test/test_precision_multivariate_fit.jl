using GLLVModels, Test, LinearAlgebra, SparseArrays, ForwardDiff, Random, StableRNGs

function _pmvf_fixture()
    q = sparse([4.0 -1.0 -1.0 0.0;
                -1.0 3.0 0.0 -1.0;
                -1.0 0.0 3.0 0.0;
                0.0 -1.0 0.0 3.0])
    i, j, x = findnz(q)
    phy = PrecisionPhy(i, j, x, 4, 2, ["a1", "a2", "s1", "s2"],
        logdet(cholesky(Symmetric(Matrix(q)))), 1.0, [3, 4])
    Y = [1.3 0.8 1.1 0.9;
         -0.2 0.3 0.1 -0.1;
          0.7 0.5 0.6 0.8]
    return Y, phy, [1, 2, 1, 2]
end

# Frozen boundary fixture: fixed seed, three traits, rank one, explicit
# phylogenetic uniqueness, 16 related tips, and six observations per tip.
# Its first unique component reaches a lower boundary (estimated variance
# ≈ 3e-9). The marginal finite-difference Hessian least eigenvalue sits at
# ≈ -5.96e-8 on Julia 1.10/macOS OpenBLAS, so interval machinery reports
# :invalid_curvature there; on Julia 1.13/Linux CI the identical frozen Y
# and start can land on the other side of the same BLAS-sensitive sign
# knife-edge and report :available. The structural boundary receipt (trait
# one unique variance collapsed) is version-stable; the coarse interval
# status is not.
function _pmvf_boundary_unique_fixture()
    rng = StableRNG(20260900)
    phy = PrecisionPhy(GLLVModels.random_balanced_tree(16; branch_length = 0.35))
    d, n_tips, repeats = 3, phy.n_leaves, 6
    beta = [0.4, -0.3, 0.7]
    loading = reshape([0.75, -0.45, 0.55], d, 1)
    unique = [0.30, 0.24, 0.34]
    residual = [0.12, 0.16, 0.10]
    precision_factor = cholesky(Symmetric(Matrix(phy.Q))).U
    g = precision_factor \ randn(rng, phy.n_aug)
    h = precision_factor \ randn(rng, phy.n_aug, d)
    species_id = repeat(collect(1:n_tips), inner = repeats)
    Y = Matrix{Float64}(undef, d, length(species_id))
    for obs in eachindex(species_id)
        node = phy.species_aug_id[species_id[obs]]
        for trait in 1:d
            Y[trait, obs] = beta[trait] + loading[trait] * g[node] +
                sqrt(unique[trait]) * h[node, trait] +
                sqrt(residual[trait]) * randn(rng)
        end
    end
    start = vcat(beta, GLLVModels.pack_lambda(loading),
        log.(sqrt.(unique)), log.(sqrt.(residual)))
    return Y, phy, species_id, start
end

# Separately declared intermediate-information fixture. It holds the seed
# fixed and was originally written to show that 32 tips can still put a
# unique component on its boundary. A cross-version grid search (100+
# (n_tips, seed, repeats) combinations spanning 16-128 tips) found that this
# exact fixture's :invalid_curvature classification is a Julia-1.10-only
# artifact of this specific finite-difference Hessian eval: on Julia 1.12+
# the identical fixture can report :available, and no nearby combination in
# the grid reproduced a version-stable coarse status distinct from the
# 16-tip and 128-tip cells (both of which carry their own FD knife-edges).
# It is retained as a curvature diagnostic, but the assertion below checks
# the general invariant (the fit runs and reports a self-consistent status)
# rather than which side of this BLAS-sensitive knife-edge it lands on.
function _pmvf_intermediate_boundary_fixture()
    rng = MersenneTwister(20260907)
    phy = PrecisionPhy(GLLVModels.random_balanced_tree(32; branch_length = 0.35))
    d, n_tips, repeats = 3, phy.n_leaves, 8
    beta = [0.4, -0.3, 0.7]
    loading = reshape([1.05, -0.75, 0.90], d, 1)
    unique = [0.85, 0.72, 0.90]
    residual = [0.10, 0.12, 0.11]
    precision_factor = cholesky(Symmetric(Matrix(phy.Q))).U
    g = precision_factor \ randn(rng, phy.n_aug)
    h = precision_factor \ randn(rng, phy.n_aug, d)
    species_id = repeat(collect(1:n_tips), inner = repeats)
    Y = Matrix{Float64}(undef, d, length(species_id))
    for obs in eachindex(species_id)
        node = phy.species_aug_id[species_id[obs]]
        for trait in 1:d
            Y[trait, obs] = beta[trait] + loading[trait] * g[node] +
                sqrt(unique[trait]) * h[node, trait] +
                sqrt(residual[trait]) * randn(rng)
        end
    end
    start = vcat(beta, GLLVModels.pack_lambda(loading),
        log.(sqrt.(unique)), log.(sqrt.(residual)))
    return Y, phy, species_id, start
end

# The actual interior-feasibility cell increases phylogenetic units to 128
# while holding the seed, trait dimension, RR rank, and variance construction
# fixed. Four observations per tip identify independent residual variance.
function _pmvf_large_interior_fixture()
    rng = MersenneTwister(20260907)
    phy = PrecisionPhy(GLLVModels.random_balanced_tree(128; branch_length = 0.35))
    d, n_tips, repeats = 3, phy.n_leaves, 4
    beta = [0.4, -0.3, 0.7]
    loading = reshape([1.05, -0.75, 0.90], d, 1)
    unique = [0.85, 0.72, 0.90]
    residual = [0.10, 0.12, 0.11]
    precision_factor = cholesky(Symmetric(Matrix(phy.Q))).U
    g = precision_factor \ randn(rng, phy.n_aug)
    h = precision_factor \ randn(rng, phy.n_aug, d)
    species_id = repeat(collect(1:n_tips), inner = repeats)
    Y = Matrix{Float64}(undef, d, length(species_id))
    for obs in eachindex(species_id)
        node = phy.species_aug_id[species_id[obs]]
        for trait in 1:d
            Y[trait, obs] = beta[trait] + loading[trait] * g[node] +
                sqrt(unique[trait]) * h[node, trait] +
                sqrt(residual[trait]) * randn(rng)
        end
    end
    start = vcat(beta, GLLVModels.pack_lambda(loading),
        log.(sqrt.(unique)), log.(sqrt.(residual)))
    return Y, phy, species_id, start
end

@testset "Destination B multivariate precision fitter" begin
    Y, phy, species_id = _pmvf_fixture()
    d, m = size(Y)
    beta = [1.0, 0.0, 0.6]
    loading = [0.4; -0.2; 0.3] |> x -> reshape(x, d, 1)
    unique = [0.15, 0.10, 0.2]
    residual = [0.5, 0.7, 0.4]
    theta = vcat(beta, GLLVModels.pack_lambda(loading), log.(sqrt.(unique)), log.(sqrt.(residual)))

    @testset "packed objective is the exact residualized kernel" begin
        got = GLLVModels._precision_multivariate_nll(Y, phy, theta;
            rank = 1, mode = :explicitunique, species_id = species_id)
        z = Y .- reshape(beta, d, 1)
        expected = -GLLVModels.multivariate_phylo_precision_loglik(z', phy, loading, residual;
            sigma2_phy = 1.0, phylo_unique_variance = unique, species_id = species_id)
        @test isapprox(got, expected; atol = 1e-10, rtol = 1e-10)
    end

    @testset "packed transforms preserve separate U and observation residual" begin
        u = GLLVModels._precision_multivariate_unpack(theta, d, 1, :explicitunique, d)
        @test u.beta == beta
        @test u.loading ≈ loading
        @test u.phylo_unique_variance ≈ unique
        @test u.residual_variance ≈ residual
        bare = vcat(beta, GLLVModels.pack_lambda(loading), log.(sqrt.(residual)))
        ub = GLLVModels._precision_multivariate_unpack(bare, d, 1, :barelowrank, d)
        @test ub.phylo_unique_variance === nothing
        @test ub.residual_variance ≈ residual
    end

    @testset "invalid finite-difference stencils are never stationary" begin
        storage = zeros(1)
        sentinel_neighbor = x -> x[1] > 0 ? GLLVModels._PMV_PENALTY : x[1]^2
        gradient = GLLVModels._pmv_fd_gradient!(storage, sentinel_neighbor, [0.0])
        @test isnan(gradient[1])
        @test isnan(GLLVModels._fd_hessian(sentinel_neighbor, [0.0])[1, 1])
    end

    @testset "fixed-seed simulator uses the intended covariance alignment" begin
        # Test-only dense reference. For Q = U' U, U \ z has covariance Q^-1;
        # use a solve rather than reusing the sampling algebra as its oracle.
        precision_factor = cholesky(Symmetric(Matrix(phy.Q))).U
        draw_transform = precision_factor \ Matrix{Float64}(I, phy.n_aug, phy.n_aug)
        reference_covariance = Matrix(phy.Q) \ Matrix{Float64}(I, phy.n_aug, phy.n_aug)
        @test draw_transform * draw_transform' ≈ reference_covariance atol = 1e-12
        trait_factor = hcat(loading, Diagonal(sqrt.(unique)))
        @test trait_factor * trait_factor' ≈ loading * loading' + Diagonal(unique) atol = 1e-12
    end

    @testset "tiny deterministic fit retains trait-major mean metadata" begin
        fit = GLLVModels.fit_precision_multivariate(Y, phy; rank = 1, mode = :barelowrank,
            species_id = species_id, iterations = 80, g_tol = 1e-4)
        @test fit.response_shape == size(Y)
        @test size(fit.mean_design) == (d * m, d)
        @test length(fit.beta) == d
        @test isfinite(fit.loglik)
        @test isfinite(GLLVModels._precision_multivariate_nll(Y, phy, fit.parameters;
            rank = 1, mode = :barelowrank, species_id = species_id,
            mean_design = fit.mean_design))
        targets = GLLVModels._pmv_targets(fit)
        @test any(t -> t.name == "phylo_cov[2,1]", targets)
        @test any(t -> t.name == "residual_var[1]", targets)
        @test all(isfinite, ForwardDiff.gradient(targets[1].value, fit.parameters))
        @test all(isfinite, ForwardDiff.gradient(targets[length(fit.beta) + 1].value,
                                                   fit.parameters))
        signal = GLLVModels._pmv_phylogenetic_signal(fit)
        @test signal.status == :estimand_not_admitted
        @test occursin("species-level", signal.definition)
        @test occursin("excludes observation residual", signal.definition)
        @test !occursin("A_tipdiag", signal.definition)
        fitted_intervals = GLLVModels.precision_multivariate_intervals(fit)
        @test fitted_intervals.status == :partial
        @test any(x -> x.name == "beta[1]" && x.status == :available,
                  fitted_intervals.intervals)
        @test any(x -> x.status == :target_unavailable, fitted_intervals.intervals)
    end

    @testset "frozen unique-boundary fixture stays at boundary with self-consistent intervals" begin
        Y_interior, phy_interior, ids_interior, start = _pmvf_boundary_unique_fixture()
        expected_Y, expected_ids = copy(Y_interior), copy(ids_interior)
        fit = GLLVModels.fit_precision_multivariate(Y_interior, phy_interior;
            rank = 1, mode = :explicitunique, species_id = ids_interior,
            start = start, iterations = 250, g_tol = 1e-4)
        Y_interior .= NaN
        ids_interior .= 1
        @test fit.converged
        @test fit.response == expected_Y
        @test fit.species_id == expected_ids
        @test isapprox(fit.loglik, -GLLVModels._precision_multivariate_nll(
            fit.response, fit.phy, fit.parameters; rank = fit.rank,
            mode = fit.mode, species_id = fit.species_id,
            mean_design = fit.mean_design); atol = 1e-10)
        u = GLLVModels._precision_multivariate_unpack(fit.parameters, size(expected_Y, 1),
            fit.rank, fit.mode, size(expected_Y, 1))
        @test u.phylo_unique_variance[1] < 1e-6
        @test isfinite(fit.hessian_min_eigenvalue)
        @test abs(fit.hessian_min_eigenvalue) < 1e-5
        intervals = GLLVModels.precision_multivariate_intervals(fit)
        # Coarse interval status flips with BLAS/Julia on this fixture (see
        # docstring); require self-consistency, not a platform-specific label.
        @test intervals.status in (:invalid_curvature, :available)
        @test all(x -> x.status == intervals.status, intervals.intervals)
    end

    @testset "fixed-seed intermediate fixture stays internally consistent at its knife-edge" begin
        Y_interior, phy_interior, ids_interior, start = _pmvf_intermediate_boundary_fixture()
        fit = GLLVModels.fit_precision_multivariate(Y_interior, phy_interior;
            rank = 1, mode = :explicitunique, species_id = ids_interior,
            start = start, iterations = 250, g_tol = 1e-4)
        @test fit.converged
        intervals = GLLVModels.precision_multivariate_intervals(fit)
        # This exact fixture sits on a BLAS/Julia-version-sensitive curvature
        # knife-edge (see the fixture's docstring): :invalid_curvature on
        # Julia 1.10, :available on Julia 1.12 for the identical data and
        # start. Both are legitimate outcomes for this design; what must hold
        # on every Julia version is that the reported status is one of the
        # two, and that every per-target interval agrees with it exactly (the
        # coarse and per-target status may never disagree).
        @test intervals.status in (:invalid_curvature, :available)
        @test all(x -> x.status == intervals.status, intervals.intervals)
    end

    @testset "fixed-seed large interior explicit-unique intervals are all available" begin
        Y_interior, phy_interior, ids_interior, start = _pmvf_large_interior_fixture()
        fit = GLLVModels.fit_precision_multivariate(Y_interior, phy_interior;
            rank = 1, mode = :explicitunique, species_id = ids_interior,
            start = start, iterations = 250, g_tol = 1e-4)
        @test fit.converged
        intervals = GLLVModels.precision_multivariate_intervals(fit)
        @test intervals.status == :available
        @test all(x -> x.status == :available, intervals.intervals)
    end

    @testset "malformed and unavailable interval outcomes stay explicit" begin
        @test_throws ArgumentError GLLVModels.fit_precision_multivariate(Y, phy; rank = 4)
        @test_throws ArgumentError GLLVModels.fit_precision_multivariate(Y, phy; mode = :other)
        overflow = copy(theta); overflow[end] = 1000.0
        @test GLLVModels._precision_multivariate_nll(Y, phy, overflow;
            rank = 1, mode = :explicitunique, species_id = species_id) == 1e12
        stalled = GLLVModels.fit_precision_multivariate(Y, phy; rank = 1, mode = :barelowrank,
            species_id = species_id, iterations = 0)
        intervals = GLLVModels.precision_multivariate_intervals(stalled)
        @test intervals.status == :not_converged
        @test all(x -> x.status == :not_converged, intervals.intervals)
    end
end
