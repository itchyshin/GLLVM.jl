# SPDE convenience auto-mesher: regular triangulated lattice covering a point set.
#
# The SPDE/Matérn-GMRF machinery in `spde.jl` (Lindgren, Rue & Lindström 2011)
# takes a triangular mesh `(nodes, tris)` and assembles the P1 FEM matrices via
# `spde_fem`. Building that mesh is the user's job. The common workflow simply
# wants a regular grid covering the observation locations — a true Delaunay
# triangulation of the points themselves is a future dependency and out of scope
# here. `spde_mesh_grid` provides that convenience: it bounds the points, pads
# the box, lays out an nx × ny lattice, and splits each cell into two triangles,
# returning `(nodes, tris)` ready to feed straight into `spde_fem`.

"""
    spde_mesh_grid(points::AbstractMatrix; nx=20, ny=20, pad=0.1) -> (nodes, tris)

Build a regular triangulated lattice mesh that covers `points` (with padding),
ready to feed into [`spde_fem`](@ref).

`points` is a P × 2 matrix of observation coordinates. The bounding box
`(xmin, xmax, ymin, ymax)` of the points is computed and padded on each side by
`pad * (max - min)` along that axis (a zero range is padded by `pad` in absolute
units, so a degenerate point set still yields a non-degenerate box). An
`nx × ny` lattice of nodes is laid over the padded box (`nx` points along x,
`ny` along y), and each grid cell is split into two triangles.

Node indexing is column-major in the grid sense: `idx(i, j) = (j-1)*nx + i` for
`i in 1:nx`, `j in 1:ny`, so `nodes` is `(nx*ny) × 2`. For each cell with corners
`a = idx(i,j)`, `b = idx(i+1,j)`, `c = idx(i,j+1)`, `d = idx(i+1,j+1)`, two
triangles `[a, b, d]` and `[a, d, c]` are emitted (both counter-clockwise), so
`tris` is `(2*(nx-1)*(ny-1)) × 3` of `Int`.

Requires `nx ≥ 2`, `ny ≥ 2`, and `size(points, 2) == 2`.

Returns `(nodes::Matrix{Float64}, tris::Matrix{Int})`.
"""
function spde_mesh_grid(points::AbstractMatrix; nx::Integer = 20, ny::Integer = 20,
                        pad::Real = 0.1)
    size(points, 2) == 2 || throw(ArgumentError("points must be P × 2; got $(size(points))"))
    nx ≥ 2 || throw(ArgumentError("nx must be ≥ 2; got $nx"))
    ny ≥ 2 || throw(ArgumentError("ny must be ≥ 2; got $ny"))

    xmin = minimum(@view points[:, 1]); xmax = maximum(@view points[:, 1])
    ymin = minimum(@view points[:, 2]); ymax = maximum(@view points[:, 2])

    xrange = xmax - xmin
    yrange = ymax - ymin
    xpad = xrange > 0 ? pad * xrange : float(pad)
    ypad = yrange > 0 ? pad * yrange : float(pad)

    return _spde_mesh_box((xmin - xpad, xmax + xpad), (ymin - ypad, ymax + ypad), nx, ny)
end

"""
    spde_mesh_grid(xlim::Tuple, ylim::Tuple; nx=20, ny=20) -> (nodes, tris)

Mesh an explicit axis-aligned box `xlim = (xmin, xmax)`, `ylim = (ymin, ymax)`
with an `nx × ny` lattice, using the same node indexing and triangle splitting as
the point-set method. No padding is applied (the box is taken as given).
"""
function spde_mesh_grid(xlim::Tuple, ylim::Tuple; nx::Integer = 20, ny::Integer = 20)
    nx ≥ 2 || throw(ArgumentError("nx must be ≥ 2; got $nx"))
    ny ≥ 2 || throw(ArgumentError("ny must be ≥ 2; got $ny"))
    return _spde_mesh_box((float(xlim[1]), float(xlim[2])),
                          (float(ylim[1]), float(ylim[2])), nx, ny)
end

# Shared lattice + triangle assembly over an explicit padded box.
function _spde_mesh_box(xlim::Tuple, ylim::Tuple, nx::Integer, ny::Integer)
    xmin, xmax = xlim
    ymin, ymax = ylim

    xs = range(xmin, xmax; length = nx)
    ys = range(ymin, ymax; length = ny)

    nodes = Matrix{Float64}(undef, nx * ny, 2)
    @inbounds for j in 1:ny, i in 1:nx
        n = (j - 1) * nx + i
        nodes[n, 1] = xs[i]
        nodes[n, 2] = ys[j]
    end

    ncell = (nx - 1) * (ny - 1)
    tris = Matrix{Int}(undef, 2 * ncell, 3)
    idx(i, j) = (j - 1) * nx + i
    t = 0
    @inbounds for j in 1:(ny - 1), i in 1:(nx - 1)
        a = idx(i, j)
        b = idx(i + 1, j)
        c = idx(i, j + 1)
        d = idx(i + 1, j + 1)
        t += 1
        tris[t, 1] = a; tris[t, 2] = b; tris[t, 3] = d
        t += 1
        tris[t, 1] = a; tris[t, 2] = d; tris[t, 3] = c
    end

    return nodes, tris
end
