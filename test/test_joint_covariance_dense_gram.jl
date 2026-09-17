using Test, GLLVModels, LinearAlgebra, SparseArrays

function _joint_dense_gram_fixture()
    Q = sparse([4.0 -1.0 -1.0 0.0;
                -1.0 3.0 0.0 -1.0;
                -1.0 0.0 3.0 0.0;
                0.0 -1.0 0.0 3.0])
    i, j, x = findnz(Q)
    phy = PrecisionPhy(i, j, x, 4, 2, ["ancestor1", "ancestor2", "tip1", "tip2"],
        logdet(cholesky(Symmetric(Matrix(Q)))), 1.0, [3, 4])
    species = [1, 2, 1, 2, 1]
    unit = [:u1, :u1, :u2, :u2, :u3]
    cluster = [:c1, :c2, :c1, :c2, :c1]
    terms = [GroupingTerm(:unit; mode=:indep), GroupingTerm(:cluster; mode=:indep)]
    incidences = [GLLVModels._grouped_incidence(unit, length(species)),
        GLLVModels._grouped_incidence(cluster, length(species))]
    return (; phy, species, unit, cluster, terms, incidences,
        loading=reshape([0.60, -0.35, 0.45], 3, 1), unique=[0.20, 0.15, 0.25])
end

function _joint_dense_tangent_gram(phy, species, incidences, loading, unique)
    p, rank = size(loading); n = length(species)
    S = zeros(n, phy.n_aug)
    for observation in 1:n
        S[observation, phy.species_aug_id[species[observation]]] = 1.0
    end
    K = S * (Matrix(phy.Q) \ Matrix(I, phy.n_aug, phy.n_aug)) * S'
    candidates = Matrix{Float64}[]
    for column in 1:rank, row in column:p
        dL = zeros(p, rank); dL[row, column] = 1.0
        push!(candidates, kron(K, dL * loading' + loading * dL'))
    end
    for trait in 1:p
        E = zeros(p, p); E[trait, trait] = 2 * unique[trait]
        push!(candidates, kron(K, E))
    end
    for incidence in incidences, trait in 1:p
        E = zeros(p, p); E[trait, trait] = 1.0
        push!(candidates, kron(Matrix(incidence * incidence'), E))
    end
    for trait in 1:p
        E = zeros(p, p); E[trait, trait] = 1.0
        push!(candidates, kron(Matrix(I, n, n), E))
    end
    gram = [dot(left, right) for left in candidates, right in candidates]
    diagonal = diag(gram)
    normalized = gram ./ sqrt.(diagonal * diagonal')
    normalized = (normalized + normalized') ./ 2
    spectrum = eigen(Symmetric(normalized))
    threshold = length(candidates) * eps(Float64) * maximum(abs, spectrum.values)
    return (; gram, normalized, eigenvalues=spectrum.values,
        threshold, rank=count(>(threshold), spectrum.values))
end

@testset "joint covariance dense tangent Gram" begin
    fixture = _joint_dense_gram_fixture()
    dense = _joint_dense_tangent_gram(fixture.phy, fixture.species,
        fixture.incidences, fixture.loading, fixture.unique)
    sparse = GLLVModels._joint_covariance_identification(fixture.phy, fixture.species,
        fixture.terms, fixture.incidences, fixture.loading;
        phylo_unique_variance=fixture.unique)
    @test size(dense.gram) == (15, 15)
    @test dense.gram ≈ sparse.gram atol=1e-11
    @test dense.normalized ≈ sparse.normalized_gram atol=1e-11
    @test dense.eigenvalues ≈ sparse.eigenvalues atol=1e-11
    @test dense.rank == sparse.rank
    @test dense.threshold ≈ sparse.threshold atol=1e-13

    order = [5, 3, 1, 4, 2]
    labels = [fixture.unit[order], fixture.cluster[order]]
    permuted_incidence = [GLLVModels._grouped_incidence(values, length(order)) for values in labels]
    permuted_dense = _joint_dense_tangent_gram(fixture.phy, fixture.species[order],
        permuted_incidence, fixture.loading, fixture.unique)
    permuted_sparse = GLLVModels._joint_covariance_identification(fixture.phy,
        fixture.species[order], fixture.terms, permuted_incidence, fixture.loading;
        phylo_unique_variance=fixture.unique)
    @test permuted_dense.gram ≈ dense.gram atol=1e-11
    @test permuted_sparse.gram ≈ sparse.gram atol=1e-11
    @test permuted_sparse.eigenvalues ≈ sparse.eigenvalues atol=1e-11
    @test permuted_sparse.rank == sparse.rank
end
