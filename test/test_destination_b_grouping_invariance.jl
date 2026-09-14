using Test, GLLVM, LinearAlgebra, SparseArrays

function _destination_b_invariance_fixture()
    p, n = 2, 10
    Y = [0.71 -0.18 0.94 0.35 -0.42 0.16 0.83 -0.09 0.52 0.28;
         -0.24 0.62 -0.31 0.48 0.91 -0.44 0.27 0.73 -0.15 0.39]
    unit = [:u1, :u1, :u2, :u2, :u2, :u2, :u3, :u3, :u4, :u4]
    # u2a/u2b are distinct, globally nested, and both replicated twice.
    unit_obs = [:u1a, :u1a, :u2a, :u2a, :u2b, :u2b, :u3a, :u3a, :u4a, :u4a]
    cluster = [:c1, :c2, :c1, :c3, :c2, :c1, :c3, :c2, :c1, :c3]
    cluster2 = [:d1, :d2, :d3, :d4, :d1, :d2, :d3, :d4, :d1, :d2]
    x_observation = [-1.2, 0.4, -0.7, 1.1, 0.0, 0.8, -0.3, 1.4, -0.9, 0.6]
    X = zeros(Float64, p * n, 3)
    for observation in 1:n, trait in 1:p
        row = trait + p * (observation - 1)
        X[row, 1] = 1.0
        X[row, 2] = trait == 2 ? 1.0 : 0.0
        X[row, 3] = trait == 1 ? x_observation[observation] : -0.6 * x_observation[observation]
    end
    terms = [
        GLLVM.GroupingTerm(:unit; mode=:dep),
        GLLVM.GroupingTerm(:unit_obs; mode=:dep),
        GLLVM.GroupingTerm(:cluster; mode=:dep),
        GLLVM.GroupingTerm(:cluster2; mode=:indep),
    ]
    gamma = [0.20, -0.35, 0.18]
    LU = [0.55 0.0; 0.15 0.42]
    LO = [0.40 0.0; -0.10 0.36]
    LC = [0.30 0.0; 0.12 0.46]
    covariance = [LU * LU', LO * LO', LC * LC', Diagonal([0.25^2, 0.35^2])]
    theta = vcat(gamma, [0.55, 0.42, 0.15], [0.40, 0.36, -0.10],
        [0.30, 0.46, 0.12], log.([0.25, 0.35]), log(0.50))
    return (; p, n, Y, X, unit, unit_obs, cluster, cluster2, terms, gamma,
        covariance=Matrix.(covariance), sigma_eps=0.50, theta)
end

function _destination_b_dense_covariance(labels, covariance, sigma_eps, p)
    n = length(first(labels))
    V = sigma_eps^2 * Matrix{Float64}(I, p * n, p * n)
    for source in eachindex(labels)
        values, B = labels[source], covariance[source]
        for right_observation in 1:n, left_observation in 1:n
            values[left_observation] == values[right_observation] || continue
            for right_trait in 1:p, left_trait in 1:p
                row = left_trait + p * (left_observation - 1)
                column = right_trait + p * (right_observation - 1)
                V[row, column] += B[left_trait, right_trait]
            end
        end
    end
    return V
end

function _destination_b_dense_nll(Y, X, gamma, labels, covariance, sigma_eps)
    V = _destination_b_dense_covariance(labels, covariance, sigma_eps, size(Y, 1))
    residual = vec(Y) - X * gamma
    return (length(residual) * log(2pi) + logdet(V) + dot(residual, V \ residual)) / 2
end

function _destination_b_production_covariance(incidences, covariance, sigma_eps)
    p = size(first(covariance), 1)
    n = size(first(incidences), 1)
    V = sigma_eps^2 * Matrix{Float64}(I, p * n, p * n)
    for source in eachindex(incidences)
        V .+= kron(Matrix(incidences[source] * incidences[source]'), covariance[source])
    end
    return V
end

function _destination_b_bijective_rename(values, prefix)
    mapping = Dict(level => Symbol(prefix, "_", index)
        for (index, level) in enumerate(unique(values)))
    return [mapping[value] for value in values]
end

@testset "Destination B four-source grouping invariance" begin
    fixture = _destination_b_invariance_fixture()
    labels = [fixture.unit, fixture.unit_obs, fixture.cluster, fixture.cluster2]
    @test size(fixture.X) == (20, 3)
    @test rank(fixture.X) == 3
    @test [count(==(level), fixture.unit) for level in unique(fixture.unit)] == [2, 4, 2, 2]
    @test all(count(==(level), fixture.unit_obs) >= 2 for level in unique(fixture.unit_obs))
    @test all(length(unique(fixture.unit[findall(==(level), fixture.unit_obs)])) == 1
        for level in unique(fixture.unit_obs))
    @test all(length(unique(fixture.cluster[findall(==(unit_level), fixture.unit)])) >= 2
        for unit_level in unique(fixture.unit))
    @test fixture.cluster2 != fixture.cluster
    @test fixture.covariance[4] == Diagonal(diag(fixture.covariance[4]))

    incidences = [GLLVM._grouped_incidence(values, fixture.n) for values in labels]
    @test Matrix(incidences[1] * incidences[1]') != Matrix(incidences[2] * incidences[2]')
    objective = GLLVM._grouped_gaussian_objective(fixture.Y, fixture.X,
        fixture.terms, incidences)
    _, _, packed_covariance, used_coordinates = GLLVM._grouped_term_unpack(
        fixture.theta[4:end-1], fixture.p, fixture.terms)
    @test used_coordinates == 11
    @test all(isapprox(packed_covariance[index], fixture.covariance[index]; atol=1e-12)
        for index in eachindex(fixture.covariance))
    dense_V = _destination_b_dense_covariance(labels, fixture.covariance,
        fixture.sigma_eps, fixture.p)
    production_V = _destination_b_production_covariance(incidences,
        packed_covariance, fixture.sigma_eps)
    dense_value = _destination_b_dense_nll(fixture.Y, fixture.X, fixture.gamma,
        labels, fixture.covariance, fixture.sigma_eps)
    @test dense_V ≈ production_V atol=1e-12
    @test objective(fixture.theta) ≈ dense_value atol=1e-11

    # Observation permutation must move each trait block of Y and X together.
    observation_order = [8, 3, 10, 1, 6, 2, 7, 4, 5, 9]
    row_order = reduce(vcat, [fixture.p * (observation - 1) .+ (1:fixture.p)
        for observation in observation_order])
    permuted_Y = fixture.Y[:, observation_order]
    permuted_X = fixture.X[row_order, :]
    permuted_labels = [values[observation_order] for values in labels]
    permuted_incidences = [GLLVM._grouped_incidence(values, fixture.n)
        for values in permuted_labels]
    permuted_objective = GLLVM._grouped_gaussian_objective(permuted_Y, permuted_X,
        fixture.terms, permuted_incidences)
    permuted_dense = _destination_b_dense_nll(permuted_Y, permuted_X, fixture.gamma,
        permuted_labels, fixture.covariance, fixture.sigma_eps)
    @test permuted_dense ≈ dense_value atol=1e-11
    @test permuted_objective(fixture.theta) ≈ dense_value atol=1e-11

    renamed_labels = [_destination_b_bijective_rename(values, prefix)
        for (values, prefix) in zip(labels, ("unit", "unit_obs", "cluster", "cluster2"))]
    renamed_incidences = [GLLVM._grouped_incidence(values, fixture.n)
        for values in renamed_labels]
    renamed_objective = GLLVM._grouped_gaussian_objective(fixture.Y, fixture.X,
        fixture.terms, renamed_incidences)
    renamed_dense = _destination_b_dense_nll(fixture.Y, fixture.X, fixture.gamma,
        renamed_labels, fixture.covariance, fixture.sigma_eps)
    @test renamed_dense ≈ dense_value atol=1e-11
    @test renamed_objective(fixture.theta) ≈ dense_value atol=1e-11

    # This changes sharing, unlike renaming or a joint input permutation.
    wrong_cluster2 = copy(fixture.cluster2)
    wrong_cluster2[1], wrong_cluster2[2] = wrong_cluster2[2], wrong_cluster2[1]
    wrong_labels = [fixture.unit, fixture.unit_obs, fixture.cluster, wrong_cluster2]
    wrong_incidences = [GLLVM._grouped_incidence(values, fixture.n) for values in wrong_labels]
    wrong_objective = GLLVM._grouped_gaussian_objective(fixture.Y, fixture.X,
        fixture.terms, wrong_incidences)
    wrong_dense = _destination_b_dense_nll(fixture.Y, fixture.X, fixture.gamma,
        wrong_labels, fixture.covariance, fixture.sigma_eps)
    @test sort(wrong_cluster2) == sort(fixture.cluster2)
    @test wrong_cluster2 != fixture.cluster2
    @test wrong_objective(fixture.theta) ≈ wrong_dense atol=1e-11
    @test abs(wrong_dense - dense_value) > 1e-6
end
