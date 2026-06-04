using GLLVM, Test, Random, LinearAlgebra, SparseArrays, Statistics

@testset "SPDE Gaussian spatial fit" begin
    # ---- inline regular triangulated grid over [0, L]² --------------------
    # Built locally (no dependence on spde_mesh_grid) so this test is
    # self-contained.
    m = 8
    L = 7.0
    xs = range(0.0, L; length = m)

    N = m * m
    nodes = Matrix{Float64}(undef, N, 2)
    nodeid(i, j) = (j - 1) * m + i
    for j in 1:m, i in 1:m
        nodes[nodeid(i, j), 1] = xs[i]
        nodes[nodeid(i, j), 2] = xs[j]
    end

    tris = Matrix{Int}(undef, 2 * (m - 1) * (m - 1), 3)
    t = 0
    for j in 1:(m - 1), i in 1:(m - 1)
        a = nodeid(i,     j)
        b = nodeid(i + 1, j)
        c = nodeid(i,     j + 1)
        d = nodeid(i + 1, j + 1)
        t += 1; tris[t, :] = [a, b, d]
        t += 1; tris[t, :] = [a, d, c]
    end

    Cdiag, G = spde_fem(nodes, tris)
    Q = spde_precision(Cdiag, G, 1.0, 1.0; α = 2)

    # M observation sites strictly inside the domain.
    rng = MersenneTwister(20240603)
    M = 12
    locs = 0.5 .+ (L - 1.0) .* rand(rng, M, 2)
    A = spde_projector(nodes, tris, locs)

    # ---- 1. EXACT anchor: sparse loglik == dense brute-force MVN ----------
    y = randn(rng, M)
    σ² = 0.7
    μ = 0.3

    ll_sparse = spde_gaussian_marginal_loglik(y, A, Q, σ²; μ = μ)

    Σy_dense = Matrix(A * inv(Matrix(Symmetric(Q))) * A') + σ² * I
    rr = y .- μ
    ll_dense = -0.5 * (length(y) * log(2π) + logdet(Σy_dense) +
                       rr' * (Σy_dense \ rr))

    @test isapprox(ll_sparse, ll_dense; atol = 1e-6)

    # ---- 2. MACHINERY fit -------------------------------------------------
    # Simulate y ≈ μ + A*u + noise; draw u via the dense Q⁻¹ Cholesky
    # (test-data construction only).
    Σu = inv(Matrix(Symmetric(Q)))
    Lu = cholesky(Symmetric(Σu)).L
    μ_true = 1.5
    σ_true = 0.4
    u = Lu * randn(rng, N)
    y2 = μ_true .+ A * u .+ σ_true .* randn(rng, M)

    fit = fit_spde_gaussian(y2, nodes, tris, locs)

    @test fit isa SPDEGaussianFit
    @test isfinite(fit.loglik)
    @test fit.κ > 0
    @test fit.τ > 0
    @test fit.σ2 > 0

    # Base.show smoke.
    @test occursin("SPDEGaussianFit", sprint(show, fit))
end
