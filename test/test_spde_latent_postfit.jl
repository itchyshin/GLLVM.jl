using GLLVM, Test, LinearAlgebra, SparseArrays, Random

# Build a regular triangulated grid over [0, L]² (identical to test_spde_latent.jl).
function _grid_mesh_pf(m, L)
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
        a = nodeid(i, j); b = nodeid(i + 1, j)
        c = nodeid(i, j + 1); d = nodeid(i + 1, j + 1)
        t += 1; tris[t, :] = [a, b, d]
        t += 1; tris[t, :] = [a, d, c]
    end
    return nodes, tris
end

@testset "SPDE-latent postfit: getLV / predict / predict_spatial" begin

    # Build a small mesh and fit a Poisson SPDE-latent model.
    Random.seed!(7777)
    m, L = 6, 5.0
    nodes, tris = _grid_mesh_pf(m, L)
    Nn = m * m                              # number of mesh nodes

    # Training locations: a subset of mesh nodes (deterministic, no random jitter).
    site_nodes = collect(1:3:Nn)            # every 3rd node → 12 sites
    locs = nodes[site_nodes, :]
    M = size(locs, 1)
    p = 3; K = 1

    Y = rand(0:4, p, M)

    # Fit with a small iteration budget (just enough for the test to run quickly).
    fit = fit_spde_latent_gllvm(Y, nodes, tris, locs;
                                family = Poisson(), K = K,
                                iterations = 40, newton_maxiter = 40)

    # ---- Shape checks -------------------------------------------------------

    @testset "getLV returns M×K" begin
        Z = GLLVM.getLV(fit, Y, locs)
        @test size(Z) == (M, K)
        @test all(isfinite, Z)
    end

    @testset "predict returns p×M (link)" begin
        η = GLLVM.predict(fit, Y, locs; type = :link)
        @test size(η) == (p, M)
        @test all(isfinite, η)
    end

    @testset "predict returns p×M (response)" begin
        μ = GLLVM.predict(fit, Y, locs; type = :response)
        @test size(μ) == (p, M)
        @test all(isfinite, μ)
        @test all(μ .> 0)                   # Poisson means are positive
    end

    @testset "predict_spatial at M′ new locs returns p×M′" begin
        # New locations: interior points of the mesh (not coinciding with nodes).
        xs_new = range(0.3, L - 0.3; length = 5)
        new_locs = hcat([x for x in xs_new, y in xs_new][:],
                        [y for x in xs_new, y in xs_new][:])
        M_new = size(new_locs, 1)

        η_new = GLLVM.predict_spatial(fit, Y, locs, new_locs; type = :link)
        @test size(η_new) == (p, M_new)
        @test all(isfinite, η_new)

        μ_new = GLLVM.predict_spatial(fit, Y, locs, new_locs; type = :response)
        @test size(μ_new) == (p, M_new)
        @test all(isfinite, μ_new)
        @test all(μ_new .> 0)
    end

    # ---- Consistency anchor -------------------------------------------------
    # predict_spatial(fit, Y, locs, locs) must equal predict(fit, Y, locs)
    # to machine precision: same projector rows → identical η.

    @testset "Consistency: predict_spatial(new_locs=locs) == predict(locs)" begin
        η_train   = GLLVM.predict(fit, Y, locs; type = :link)
        η_spatial = GLLVM.predict_spatial(fit, Y, locs, locs; type = :link)
        @test η_train ≈ η_spatial          # should be bitwise equal (same computation)
    end

    # ---- Mode stationarity anchor -------------------------------------------
    # At the returned field mode Û, the gradient of the Laplace objective
    #   φ(U) = ℓ_data(U) − ½ Σ_k u_kᵀ Q u_k
    # satisfies ∇φ(Û) = Aᵀ S Λ − Q Û ≈ 0 (stationarity condition).
    # We verify that max|∇φ(Û)| < 1e-6 at the mode returned by getLV.

    @testset "Mode stationarity: |∇φ(Û)| < 1e-6" begin
        # Reconstruct Q and A (same parameters as the fit).
        Cdiag, G = spde_fem(nodes, tris)
        Q  = spde_precision(Cdiag, G, fit.κ, fit.τ; α = 2)
        Qs = sparse(Q)
        A  = spde_projector(nodes, tris, locs)

        # Retrieve Û and Z = A·Û from getLV.
        Z, U = GLLVM.getLV(fit, Y, locs; return_nodes = true)

        # Compute score S (p×M) at the mode.
        link = fit.link
        Λ    = fit.Λ
        β    = fit.β
        η    = GLLVM._clamp_eta.(β .+ Λ * Z')
        μ    = GLLVM._clamp_mu.(Ref(fit.family),
                                 GLLVM.linkinv.(Ref(link), η))
        me   = GLLVM.mu_eta.(Ref(link), η)
        Ntr  = ones(p, M)
        S    = GLLVM._glm_score.(Ref(fit.family), μ, Ntr, me, Y)

        # Gradient: N×K matrix.
        Grad = A' * (S' * Λ) - Qs * U

        @test maximum(abs, Grad) < 1e-6
    end

    # ---- getLV return_nodes flag -------------------------------------------

    @testset "getLV return_nodes=true exposes Û (N×K)" begin
        Z, U = GLLVM.getLV(fit, Y, locs; return_nodes = true)
        @test size(Z) == (M, K)
        @test size(U) == (Nn, K)
        @test all(isfinite, U)
        # Z must equal A·U exactly.
        A = spde_projector(nodes, tris, locs)
        @test A * U ≈ Z
    end

    @testset "aic / bic wired for SPDELatentFit" begin
        k = p + GLLVM.rr_theta_len(p, K) + 2     # Poisson ⇒ no dispersion param
        @test GLLVM._nparams(fit) == k
        @test aic(fit) ≈ 2k - 2 * fit.loglik
        @test bic(fit, M) ≈ k * log(M) - 2 * fit.loglik
    end

end
