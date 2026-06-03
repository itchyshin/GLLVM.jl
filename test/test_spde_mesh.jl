using GLLVM, Test, Random, LinearAlgebra

@testset "SPDE grid mesh" begin
    Random.seed!(20260603)
    points = 10 .* rand(40, 2)

    nx, ny, pad = 15, 12, 0.1
    nodes, tris = spde_mesh_grid(points; nx = nx, ny = ny, pad = pad)

    # Shapes
    @test size(nodes) == (nx * ny, 2)
    @test size(tris) == (2 * (nx - 1) * (ny - 1), 3)
    @test eltype(tris) <: Integer
    @test all(1 .≤ tris .≤ size(nodes, 1))

    # Coverage: node bounding box contains every point (with pad margin)
    pxmin = minimum(points[:, 1]); pxmax = maximum(points[:, 1])
    pymin = minimum(points[:, 2]); pymax = maximum(points[:, 2])

    nxmin = minimum(nodes[:, 1]); nxmax = maximum(nodes[:, 1])
    nymin = minimum(nodes[:, 2]); nymax = maximum(nodes[:, 2])

    @test nxmin ≤ pxmin
    @test nxmax ≥ pxmax
    @test nymin ≤ pymin
    @test nymax ≥ pymax

    # Padded box extents (what the mesher should have produced)
    xpad = pad * (pxmax - pxmin)
    ypad = pad * (pymax - pymin)
    padded_xmin = pxmin - xpad; padded_xmax = pxmax + xpad
    padded_ymin = pymin - ypad; padded_ymax = pymax + ypad

    @test nxmin ≈ padded_xmin
    @test nxmax ≈ padded_xmax
    @test nymin ≈ padded_ymin
    @test nymax ≈ padded_ymax

    # FEM consistency (the gate)
    Cdiag, G = GLLVM.spde_fem(nodes, tris)

    padded_area = (padded_xmax - padded_xmin) * (padded_ymax - padded_ymin)
    @test sum(Cdiag) ≈ padded_area atol = 1e-6
    @test all(Cdiag .> 0)

    @test G ≈ G'
    @test maximum(abs, vec(sum(G; dims = 2))) < 1e-8
end
