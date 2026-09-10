using Test, LinearAlgebra, SparseArrays, JSON3, SHA, GLLVM

@testset "Destination B height-four frozen tree precision" begin
    path = joinpath(@__DIR__, "..", "docs", "dev-log", "core070",
        "destination-b-tree", "precision-reference.json")
    r = JSON3.read(read(path, String))
    @test bytes2hex(sha256(read(path))) == "ab01ee47206565eb1af7da391af313953b8a97c6bb11d9b6160655aaa0429170"
    @test r.source_pin == "b4d5fee64def88bc768dda1f1f77c29b295edd86"
    @test r.dll_sha256 == "91bfa6d90fbf3e4f42e1f4160583f2607f51a7839bb54a02a209da6e31a59beb"
    @test r.scale == r.height == 4
    @test !r.ridge_applied && !r.fit_performed && !r.qualified
    @test occursin("ultrametric", r.non_ultrametric_rejection)

    # Independent path-sum covariance, with fixture edges fixed independently
    # of the exported R arrays. Each column is one independent edge increment.
    parents = [9,10,11,11,10,12,12,9,13,14,14,13,15,15]
    children = [10,11,1,2,12,3,4,13,14,5,6,15,7,8]
    lengths = [1.,1.,2.,2.,2.,1.,1.,1.5,1.,1.5,1.5,1.5,1.,1.]
    included = [10,11,12,13,14,15,1,2,3,4,5,6,7,8]
    P = zeros(15,14)
    for e in eachindex(children)
        P[children[e],:] = P[parents[e],:]
        P[children[e],e] = 1
    end
    C = P[included,:] * Diagonal(lengths) * P[included,:]'
    @test r.included_node_ids == included
    @test r.edge_length == lengths
    @test all(r.edge[e] == [parents[e],children[e]] for e in eachindex(children))
    @test diag(C)[7:14] == fill(4.,8)
    Q = reduce(vcat, permutedims.(Float64.(row) for row in r.Q_canonical))
    @test Q*(C/4) ≈ Matrix{Float64}(I,14,14) atol=1e-12 rtol=1e-12
    @test r.log_det_Q ≈ 14log(4)-sum(log,lengths) atol=1e-12
    @test logdet(Symmetric(Q)) ≈ r.log_det_Q atol=1e-12
    observed = [14,7,12,9,13,8,11,10]
    species = repeat(collect(1:8);inner=2)
    @test r.species_node_one_based == observed
    @test r.observation_species_one_based == species
    nodes = observed[species]
    loading = reshape([.8,-.4,.6],3,1)
    residual = .09
    Y = reshape(sin.(collect(1.:48)),3,16)
    V = kron(C[nodes,nodes]/4,loading*loading') + residual*I
    F = cholesky(Symmetric(V))
    exact = .5*(48log(2pi)+logdet(F)+dot(vec(Y),F\vec(Y)))
    ii,jj,vv = findnz(sparse(Q))
    phy = PrecisionPhy(ii,jj,vv,14,8,String.(r.node_labels),
        Float64(r.log_det_Q),4.,observed)
    nll(p) = -GLLVM.multivariate_phylo_precision_loglik(permutedims(Y),p,
        loading,fill(residual,3);species_id=species)
    @test nll(phy) ≈ exact atol=1e-10 rtol=1e-10
    conditioned = cholesky(Symmetric(Q[observed,observed])) \ Matrix{Float64}(I,8,8)
    @test norm(conditioned-C[observed,observed]/4) > .1
    # Physically unscaled Q, with a consistent determinant, is the wrong
    # model here. Metadata alone is not an instruction to rescale Q again.
    raw = PrecisionPhy(ii,jj,vv/4,14,8,String.(r.node_labels),
        Float64(r.log_det_Q)-14log(4),1.,observed)
    @test abs(nll(raw)-exact) > 1e-5
    wrongmap = copy(observed)
    wrongmap[1],wrongmap[2] = wrongmap[2],wrongmap[1]
    wrong = PrecisionPhy(ii,jj,vv,14,8,String.(r.node_labels),
        Float64(r.log_det_Q),4.,wrongmap)
    @test abs(nll(wrong)-exact) > 1e-5
end
