using GLLVM, Test, Random, LinearAlgebra

# ── Helpers used only in this test file ──────────────────────────────────────

# Signed area of triangle with vertices (ax,ay), (bx,by), (cx,cy).
# Positive iff CCW.
function _tri_signed_area(ax, ay, bx, by, cx, cy)
    return 0.5 * ((bx - ax) * (cy - ay) - (cx - ax) * (by - ay))
end

# incircle_test: returns > 0 iff point d is strictly inside the circumcircle
# of CCW triangle (a, b, c) — same determinant as the implementation.
function _incircle_test(ax, ay, bx, by, cx, cy, dx, dy)
    adx = ax - dx;  ady = ay - dy
    bdx = bx - dx;  bdy = by - dy
    cdx = cx - dx;  cdy = cy - dy
    adx2 = adx * adx + ady * ady
    bdx2 = bdx * bdx + bdy * bdy
    cdx2 = cdx * cdx + cdy * cdy
    return (adx * (bdy * cdx2 - cdy * bdx2)
          - ady * (bdx * cdx2 - cdx * bdx2)
          + adx2 * (bdx * cdy - bdy * cdx))
end

# ── Main test set ─────────────────────────────────────────────────────────────

@testset "SPDE Delaunay mesh (Bowyer–Watson)" begin

    # ── Test 1: jittered grid (general position) ──────────────────────────────
    # A 4×4 grid jittered off the lattice so no four points are cocircular — the
    # regime Bowyer–Watson is designed for. (Exact lattices are degenerate; use
    # `spde_mesh_grid` for those.) We check the triangulation tiles the hull
    # (total area == FEM area), is valid for FEM, and is Delaunay.
    @testset "Jittered grid (general position)" begin
        Random.seed!(12321)
        xs = [Float64(i) for i in 0:3, j in 0:3]
        ys = [Float64(j) for i in 0:3, j in 0:3]
        pts = hcat(vec(xs), vec(ys)) .+ 0.18 .* (rand(16, 2) .- 0.5)

        nodes, tris = GLLVM.spde_mesh_delaunay(pts)

        @test size(nodes, 1) == size(pts, 1)
        @test size(nodes, 2) == 2
        @test nodes ≈ Float64.(pts)

        N = size(nodes, 1)
        @test all(1 .≤ tris .≤ N)
        @test eltype(tris) <: Integer

        in_tri = falses(N)
        for k in 1:size(tris, 1)
            in_tri[tris[k, 1]] = true
            in_tri[tris[k, 2]] = true
            in_tri[tris[k, 3]] = true
        end
        @test all(in_tri)

        for k in 1:size(tris, 1)
            a = tris[k, 1]; b = tris[k, 2]; c = tris[k, 3]
            area = _tri_signed_area(nodes[a, 1], nodes[a, 2],
                                    nodes[b, 1], nodes[b, 2],
                                    nodes[c, 1], nodes[c, 2])
            @test area > 0
        end

        # Tiling check: total triangle area == FEM-assembled area (a valid,
        # gap/overlap-free triangulation has these equal), and is positive.
        total_area = sum(1:size(tris, 1)) do k
            a = tris[k, 1]; b = tris[k, 2]; c = tris[k, 3]
            _tri_signed_area(nodes[a, 1], nodes[a, 2],
                             nodes[b, 1], nodes[b, 2],
                             nodes[c, 1], nodes[c, 2])
        end
        @test total_area > 0

        Cdiag, G = GLLVM.spde_fem(nodes, tris)
        @test sum(Cdiag) ≈ total_area atol = 1e-8
        @test all(Cdiag .> 0)
        @test G ≈ G'
        @test maximum(abs, vec(sum(G; dims = 2))) < 1e-8

        T = size(tris, 1)
        @test T ≥ N - 2

        tol_incircle = 1e-8
        delaunay_ok = true
        for k in 1:size(tris, 1)
            a = tris[k, 1]; b = tris[k, 2]; c = tris[k, 3]
            ax = nodes[a, 1]; ay = nodes[a, 2]
            bx = nodes[b, 1]; by = nodes[b, 2]
            cx = nodes[c, 1]; cy = nodes[c, 2]
            for p in 1:N
                (p == a || p == b || p == c) && continue
                if _incircle_test(ax, ay, bx, by, cx, cy, nodes[p, 1], nodes[p, 2]) > tol_incircle
                    delaunay_ok = false
                end
            end
        end
        @test delaunay_ok
    end

    # ── Test 2: known-area triangle hull + interior points ────────────────────
    # Outer triangle (0,0)-(4,0)-(0,4), area 8, with fixed interior points in
    # general position. The convex hull is exactly that triangle, so the total
    # triangulation area must equal 8 — a clean tiling (no gaps/overlaps) check
    # that avoids the cocircular degeneracy of a square.
    @testset "Triangle hull + interior points (area = 8)" begin
        outer = [0.0 0.0; 4.0 0.0; 0.0 4.0]
        interior = [1.0 1.0; 2.0 1.0; 1.0 2.0; 0.7 0.5;
                    1.5 1.5; 0.5 2.5; 2.5 0.5; 1.2 0.6]   # all strictly inside
        pts = vcat(outer, interior)

        nodes, tris = GLLVM.spde_mesh_delaunay(pts)
        N = size(nodes, 1)
        @test N == 11

        in_tri = falses(N)
        for k in 1:size(tris, 1)
            in_tri[tris[k, 1]] = true
            in_tri[tris[k, 2]] = true
            in_tri[tris[k, 3]] = true
        end
        @test all(in_tri)

        total_area = sum(1:size(tris, 1)) do k
            a = tris[k, 1]; b = tris[k, 2]; c = tris[k, 3]
            _tri_signed_area(nodes[a, 1], nodes[a, 2],
                             nodes[b, 1], nodes[b, 2],
                             nodes[c, 1], nodes[c, 2])
        end
        @test total_area ≈ 8.0 atol = 1e-8   # hull is the outer triangle

        Cdiag, G = GLLVM.spde_fem(nodes, tris)
        @test sum(Cdiag) ≈ 8.0 atol = 1e-8
        @test all(Cdiag .> 0)
        @test G ≈ G'

        tol_incircle = 1e-8
        delaunay_ok = true
        for k in 1:size(tris, 1)
            a = tris[k, 1]; b = tris[k, 2]; c = tris[k, 3]
            ax = nodes[a, 1]; ay = nodes[a, 2]
            bx = nodes[b, 1]; by = nodes[b, 2]
            cx = nodes[c, 1]; cy = nodes[c, 2]
            for p in 1:N
                (p == a || p == b || p == c) && continue
                if _incircle_test(ax, ay, bx, by, cx, cy, nodes[p, 1], nodes[p, 2]) > tol_incircle
                    delaunay_ok = false
                end
            end
        end
        @test delaunay_ok
    end

    # ── Test 3: random point cloud — FEM + Delaunay property ─────────────────
    @testset "Random points (N=30)" begin
        Random.seed!(20260604)
        N = 30
        pts = hcat(10.0 .* rand(N), 10.0 .* rand(N))

        nodes, tris = GLLVM.spde_mesh_delaunay(pts)

        @test size(nodes, 1) == N
        @test all(1 .≤ tris .≤ N)

        # Every input point in at least one triangle.
        in_tri = falses(N)
        for k in 1:size(tris, 1)
            in_tri[tris[k, 1]] = true
            in_tri[tris[k, 2]] = true
            in_tri[tris[k, 3]] = true
        end
        @test all(in_tri)

        # All areas positive.
        for k in 1:size(tris, 1)
            a = tris[k, 1]; b = tris[k, 2]; c = tris[k, 3]
            area = _tri_signed_area(nodes[a, 1], nodes[a, 2],
                                    nodes[b, 1], nodes[b, 2],
                                    nodes[c, 1], nodes[c, 2])
            @test area > 0
        end

        # FEM gate.
        Cdiag, G = GLLVM.spde_fem(nodes, tris)
        total_area = sum(Cdiag)
        @test total_area > 0
        @test all(Cdiag .> 0)
        @test G ≈ G'
        @test maximum(abs, vec(sum(G; dims = 2))) < 1e-8

        # Euler: T ≥ N - 2.
        @test size(tris, 1) ≥ N - 2

        # Empty-circumcircle (Delaunay) property — the definitive correctness gate.
        tol_incircle = 1e-8
        delaunay_ok = true
        for k in 1:size(tris, 1)
            a = tris[k, 1]; b = tris[k, 2]; c = tris[k, 3]
            ax = nodes[a, 1]; ay = nodes[a, 2]
            bx = nodes[b, 1]; by = nodes[b, 2]
            cx = nodes[c, 1]; cy = nodes[c, 2]
            for p in 1:N
                (p == a || p == b || p == c) && continue
                v = _incircle_test(ax, ay, bx, by, cx, cy,
                                   nodes[p, 1], nodes[p, 2])
                if v > tol_incircle
                    delaunay_ok = false
                end
            end
        end
        @test delaunay_ok
    end

    # ── Test 4: minimum 3-point triangle ──────────────────────────────────────
    @testset "Minimum 3 points" begin
        pts = [0.0 0.0; 1.0 0.0; 0.0 1.0]
        nodes, tris = GLLVM.spde_mesh_delaunay(pts)

        @test size(nodes, 1) == 3
        @test size(tris, 1) == 1
        @test size(tris, 2) == 3
        @test all(1 .≤ tris .≤ 3)

        # Single triangle must be CCW (positive area).
        a = tris[1, 1]; b = tris[1, 2]; c = tris[1, 3]
        area = _tri_signed_area(nodes[a, 1], nodes[a, 2],
                                nodes[b, 1], nodes[b, 2],
                                nodes[c, 1], nodes[c, 2])
        @test area ≈ 0.5 atol = 1e-12

        # FEM gate.
        Cdiag, _ = GLLVM.spde_fem(nodes, tris)
        @test sum(Cdiag) ≈ 0.5 atol = 1e-12
    end

    # ── Test 5: return-convention compatibility with spde_mesh_grid ───────────
    # Both meshers must return the same (nodes::Matrix{Float64}, tris::Matrix{Int})
    # convention and both must feed spde_fem without error.
    @testset "Convention compatibility with spde_mesh_grid" begin
        pts = [0.0 0.0; 1.0 0.0; 1.0 1.0; 0.0 1.0; 0.5 0.25; 0.3 0.7]
        nodes_d, tris_d = GLLVM.spde_mesh_delaunay(pts)
        nodes_g, tris_g = spde_mesh_grid(pts; nx = 5, ny = 5)

        # Both satisfy the FEM contract.
        Cd, _ = GLLVM.spde_fem(nodes_d, tris_d)
        Cg, _ = GLLVM.spde_fem(nodes_g, tris_g)
        @test sum(Cd) > 0
        @test sum(Cg) > 0

        # Return types match.
        @test eltype(nodes_d) == Float64
        @test eltype(tris_d) <: Integer
        @test eltype(nodes_g) == Float64
        @test eltype(tris_g) <: Integer

        # Delaunay nodes are exactly the input points (in order).
        @test nodes_d ≈ Float64.(pts)
    end

end
