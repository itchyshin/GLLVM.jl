using GLLVM, Test, LinearAlgebra, SparseArrays   # Matérn check uses GLLVM.matern_correlation (no direct SpecialFunctions dep in the test env)

@testset "SPDE / Matérn-GMRF" begin
    # ---- regular triangulated grid over [0, L]² ---------------------------
    m = 21
    L = 10.0
    h = L / (m - 1)                       # grid spacing (0.5 for m=21, L=10)
    xs = range(0.0, L; length = m)

    # Node coordinates, column-major (i fastest); node index = (j-1)*m + i.
    N = m * m
    nodes = Matrix{Float64}(undef, N, 2)
    nodeid(i, j) = (j - 1) * m + i
    for j in 1:m, i in 1:m
        nodes[nodeid(i, j), 1] = xs[i]
        nodes[nodeid(i, j), 2] = xs[j]
    end

    # Two triangles per grid square.
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

    # ---- 1. FEM identities ------------------------------------------------
    @test isapprox(sum(Cdiag), L^2; atol = 1e-8)
    @test G ≈ G'
    @test maximum(abs, vec(sum(G; dims = 2))) < 1e-8
    @test all(Cdiag .> 0)
    @test length(Cdiag) == N
    @test size(G) == (N, N)

    # ---- 2. Precision SPD -------------------------------------------------
    κ = 1.0
    Q = spde_precision(Cdiag, G, κ, 1.0; α = 2)
    @test Q ≈ Q'
    @test size(Q) == (N, N)
    @test isposdef(Matrix(Symmetric(Q)))

    # ---- 3. Matérn-covariance gate ---------------------------------------
    Σ = inv(Matrix(Symmetric(Q)))

    # Central interior node.
    ic = (m + 1) ÷ 2
    i0 = nodeid(ic, ic)
    c0 = nodes[i0, :]

    # Sample interior nodes within the central half of the domain, away from
    # the boundary, at a spread of distances along a ray.
    lo = ic + 1
    hi = ic + (m ÷ 4)                       # stays inside the central half
    js = [nodeid(jj, ic) for jj in lo:hi]

    rs       = Float64[]
    ρ_fems   = Float64[]
    ρ_materns = Float64[]
    for j in js
        r = norm(c0 - nodes[j, :])
        ρ_fem = Σ[i0, j] / sqrt(Σ[i0, i0] * Σ[j, j])
        ρ_mat = matern_correlation(r, κ; ν = 1)
        push!(rs, r)
        push!(ρ_fems, ρ_fem)
        push!(ρ_materns, ρ_mat)
        @test isapprox(ρ_fem, ρ_mat; atol = 0.12)
    end

    # Monotone decreasing in r (small numerical slack).
    @test issorted(rs)
    for k in 2:length(ρ_fems)
        @test ρ_fems[k] ≤ ρ_fems[k - 1] + 1e-6
    end

    # matern_correlation sanity: ρ(0) = 1 and decays.
    @test matern_correlation(0.0, κ; ν = 1) == 1.0
    @test matern_correlation(1.0, κ; ν = 1) < 1.0
    @test 0.0 < matern_correlation(2.0, κ; ν = 1) < matern_correlation(1.0, κ; ν = 1)

    # ---- 4. Projector at mesh nodes --------------------------------------
    A = spde_projector(nodes, tris, nodes[1:3, :])
    @test size(A) == (3, N)
    @test all(isapprox.(vec(sum(A; dims = 2)), 1.0; atol = 1e-10))
    # Each location is exactly at a node → unit weight at that node.
    Adense = Matrix(A)
    for r in 1:3
        @test isapprox(Adense[r, r], 1.0; atol = 1e-8)
        @test isapprox(sum(abs, Adense[r, :]) - Adense[r, r], 0.0; atol = 1e-8)
    end
end
