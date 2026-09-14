using Test, GLLVM, LinearAlgebra, SparseArrays

# Private foundation interface (no root finding or optimisation):
#
# _grouped_indep_variance_basis_gram(D, terms, incidences)
#   -> (; gram, rank, labels)
#
# _grouped_indep_variance_profile_objective(data, D, terms, incidences;
#     selected::Tuple{Int,Int}, fixed_variance::Real,
#     evaluator_placeholder::Real=0.0)
#   -> (; objective, selected_covariance, selected_coordinate,
#       selected_full_index, selected_label, reduced_length)
#
# The second constructor must fail closed on a deficient mean design or an
# aliased covariance basis. `objective` accepts only finite reduced vectors;
# `selected_coordinate(reduced)` is `missing` at fixed_variance=0.

function _profile_dense_basis(labels, p)
    n = length(first(labels))
    bases = Matrix{Float64}[]
    for values in labels, trait in 1:p
        B = zeros(Float64, p * n, p * n)
        for right_observation in 1:n, left_observation in 1:n
            values[left_observation] == values[right_observation] || continue
            row = trait + p * (left_observation - 1)
            column = trait + p * (right_observation - 1)
            B[row, column] = 1.0
        end
        push!(bases, B)
    end
    residual = Matrix{Float64}(I, p * n, p * n)
    push!(bases, residual)
    return bases
end

function _profile_dense_gram(bases)
    count = length(bases)
    return [dot(bases[row], bases[column]) for row in 1:count, column in 1:count]
end

function _profile_dense_nll(Y, D, gamma, labels, variances, sigma_eps)
    p, n = size(Y)
    V = sigma_eps^2 * Matrix{Float64}(I, p * n, p * n)
    for source in eachindex(labels)
        values = labels[source]
        B = Diagonal(variances[source])
        for right_observation in 1:n, left_observation in 1:n
            values[left_observation] == values[right_observation] || continue
            for right_trait in 1:p, left_trait in 1:p
                row = left_trait + p * (left_observation - 1)
                column = right_trait + p * (right_observation - 1)
                V[row, column] += B[left_trait, right_trait]
            end
        end
    end
    residual = vec(Y) - D * gamma
    return (length(residual) * log(2pi) + logdet(V) + dot(residual, V \ residual)) / 2
end

function _profile_fixture()
    p, n = 2, 8
    unit = [:u1, :u1, :u1, :u1, :u2, :u2, :u2, :u2]
    unit_obs = [:u1a, :u1a, :u1b, :u1b, :u2a, :u2a, :u2b, :u2b]
    labels = [unit, unit_obs]
    terms = [
        GLLVM.GroupingTerm(:unit; mode=:indep, common=false),
        GLLVM.GroupingTerm(:unit_obs; mode=:indep, common=false),
    ]
    incidences = [GLLVM._grouped_incidence(values, n) for values in labels]
    D = GLLVM._trait_mean_design(p, n)
    data = [0.30 -0.15 0.42 0.08 -0.27 0.51 -0.06 0.19;
            -0.11 0.37 -0.22 0.46 0.14 -0.31 0.28 -0.04]
    return (; p, n, unit, unit_obs, labels, terms, incidences, D, data)
end

@testset "grouped Gaussian profile foundation" begin
    fixture = _profile_fixture()
    dense_bases = _profile_dense_basis(fixture.labels, fixture.p)
    dense_gram = _profile_dense_gram(dense_bases)
    scalable_gram = zeros(Float64, length(dense_bases), length(dense_bases))
    source_count = length(fixture.incidences)
    for right_source in 1:source_count, right_trait in 1:fixture.p,
            left_source in 1:source_count, left_trait in 1:fixture.p
        row = (left_source - 1) * fixture.p + left_trait
        column = (right_source - 1) * fixture.p + right_trait
        scalable_gram[row, column] = left_trait == right_trait ?
            norm(fixture.incidences[left_source]' * fixture.incidences[right_source])^2 : 0.0
    end
    for source in 1:source_count, trait in 1:fixture.p
        index = (source - 1) * fixture.p + trait
        scalable_gram[index, end] = norm(fixture.incidences[source])^2
        scalable_gram[end, index] = scalable_gram[index, end]
    end
    scalable_gram[end, end] = fixture.n * fixture.p
    @test dense_gram ≈ scalable_gram atol=1e-12
    @test rank(dense_gram) == size(dense_gram, 1)
    @test rank(fixture.D) == size(fixture.D, 2)

        gram_result = GLLVM._grouped_indep_variance_basis_gram(
            fixture.D, fixture.terms, fixture.incidences)
        @test gram_result.gram ≈ dense_gram atol=1e-12
        @test gram_result.rank == size(dense_gram, 1)
        @test length(gram_result.labels) == size(dense_gram, 1)
        @test size(gram_result.normalizedGram) == size(dense_gram)
        @test all(isfinite, gram_result.diagonal) && all(>(0.0), gram_result.diagonal)
        @test all(gram_result.eigenvalues .> gram_result.threshold)
        @test isfinite(gram_result.condition) && gram_result.condition >= 1.0
        @test gram_result.designSVD.dimensions == size(fixture.D)
        @test gram_result.designSVD.rank == size(fixture.D, 2)
        @test gram_result.designSVD.threshold >= 0.0

        # Identical source incidences make their trait-specific bases aliased.
        alias_labels = [fixture.unit, fixture.unit]
        alias_incidences = [GLLVM._grouped_incidence(values, fixture.n)
            for values in alias_labels]
        alias_bases = _profile_dense_basis(alias_labels, fixture.p)
        @test rank(_profile_dense_gram(alias_bases)) < length(alias_bases)
        alias_gram = GLLVM._grouped_indep_variance_basis_gram(
            fixture.D, fixture.terms, alias_incidences)
        @test alias_gram.rank < length(alias_gram.labels)
        @test !alias_gram.valid && isinf(alias_gram.condition)
        @test_throws ArgumentError GLLVM._grouped_indep_variance_profile_objective(
            fixture.data, fixture.D, fixture.terms, alias_incidences;
            selected=(1, 1), fixed_variance=0.1)

        # A one-trait identity incidence makes its sole source basis residual-aliased.
        residual_data = reshape([0.2, -0.1, 0.3, 0.4], 1, :)
        residual_D = ones(Float64, 4, 1)
        residual_terms = [GLLVM.GroupingTerm(:unit; mode=:indep, common=false)]
        residual_incidence = [sparse(Matrix{Float64}(I, 4, 4))]
        residual_bases = _profile_dense_basis([collect(1:4)], 1)
        @test rank(_profile_dense_gram(residual_bases)) < length(residual_bases)
        @test_throws ArgumentError GLLVM._grouped_indep_variance_profile_objective(
            residual_data, residual_D, residual_terms, residual_incidence;
            selected=(1, 1), fixed_variance=0.1)

        deficient_D = hcat(ones(Float64, fixture.p * fixture.n),
            ones(Float64, fixture.p * fixture.n))
        @test rank(deficient_D) < size(deficient_D, 2)
        @test_throws ArgumentError GLLVM._grouped_indep_variance_profile_objective(
            fixture.data, deficient_D, fixture.terms, fixture.incidences;
            selected=(1, 1), fixed_variance=0.1)

        common_terms = [GLLVM.GroupingTerm(:unit; mode=:indep, common=true)]
        @test_throws ArgumentError GLLVM._grouped_indep_variance_basis_gram(
            fixture.D, common_terms, fixture.incidences[1:1])
        dependent_terms = [GLLVM.GroupingTerm(:unit; mode=:dep)]
        @test_throws ArgumentError GLLVM._grouped_indep_variance_basis_gram(
            fixture.D, dependent_terms, fixture.incidences[1:1])
        @test_throws ArgumentError GLLVM._grouped_indep_variance_profile_objective(
            fixture.data, fixture.D, fixture.terms, fixture.incidences;
            selected=(1, 2), fixed_variance=-0.1)
        @test_throws ArgumentError GLLVM._grouped_indep_variance_profile_objective(
            fixture.data, fixture.D, fixture.terms, fixture.incidences;
            selected=(1, 2), fixed_variance=0.0, evaluator_placeholder=Inf)
        mismatched_incidence = [GLLVM._grouped_incidence(fixture.unit[1:6], 6),
            fixture.incidences[2]]
        @test_throws DimensionMismatch GLLVM._grouped_indep_variance_profile_objective(
            fixture.data, fixture.D, fixture.terms, mismatched_incidence;
            selected=(1, 2), fixed_variance=0.0)
        duplicate_terms = [fixture.terms[1], fixture.terms[1]]
        @test_throws ArgumentError GLLVM._grouped_indep_variance_basis_gram(
            fixture.D, duplicate_terms, fixture.incidences)
        weighted_incidence = copy(fixture.incidences[1])
        weighted_incidence.nzval[1] = 0.5
        @test_throws ArgumentError GLLVM._grouped_indep_variance_basis_gram(
            fixture.D, fixture.terms[1:1], [weighted_incidence])
        negative_incidence = copy(fixture.incidences[1])
        negative_incidence.nzval[1] = -1.0
        @test_throws ArgumentError GLLVM._grouped_indep_variance_basis_gram(
            fixture.D, fixture.terms[1:1], [negative_incidence])
        multiple_membership = sparse(fixture.incidences[1] +
            sparse([1], [2], [1.0], fixture.n, size(fixture.incidences[1], 2)))
        @test_throws ArgumentError GLLVM._grouped_indep_variance_basis_gram(
            fixture.D, fixture.terms[1:1], [multiple_membership])
        crossing_unit_obs = GLLVM._grouped_incidence(
            [:a, :b, :b, :b, :a, :c, :c, :d], fixture.n)
        @test_throws ArgumentError GLLVM._grouped_indep_variance_basis_gram(
            fixture.D, fixture.terms, [fixture.incidences[1], crossing_unit_obs])
        overflow_value = BigFloat("1e10000")
        @test_throws ArgumentError GLLVM._grouped_indep_variance_profile_objective(
            fixture.data, fixture.D, fixture.terms, fixture.incidences;
            selected=(1, 2), fixed_variance=overflow_value)
        @test_throws ArgumentError GLLVM._grouped_indep_variance_profile_objective(
            fixture.data, fixture.D, fixture.terms, fixture.incidences;
            selected=(1, 2), fixed_variance=0.0,
            evaluator_placeholder=overflow_value)

        # v=0 overlays one selected diagonal exactly, without feeding -Inf to
        # the ordinary full objective. Two finite evaluator placeholders agree.
        zero_a = GLLVM._grouped_indep_variance_profile_objective(
            fixture.data, fixture.D, fixture.terms, fixture.incidences;
            selected=(1, 2), fixed_variance=0.0, evaluator_placeholder=-2.0)
        zero_b = GLLVM._grouped_indep_variance_profile_objective(
            fixture.data, fixture.D, fixture.terms, fixture.incidences;
            selected=(1, 2), fixed_variance=0.0, evaluator_placeholder=1.25)
        reduced = [0.10, -0.15, log(0.40), log(0.35), log(0.30), log(0.45)]
        @test length(reduced) == zero_a.reduced_length == zero_b.reduced_length
        @test isfinite(zero_a.objective(reduced))
        @test zero_a.objective(reduced) ≈ zero_b.objective(reduced) atol=1e-12
        @test zero_a.selected_covariance(reduced) == 0.0
        @test zero_b.selected_covariance(reduced) == 0.0
        @test ismissing(zero_a.selected_coordinate(reduced))
        zero_dense = _profile_dense_nll(fixture.data, fixture.D, reduced[1:2],
            fixture.labels, [[0.40^2, 0.0], [0.35^2, 0.30^2]], 0.45)
        @test zero_a.objective(reduced) ≈ zero_dense atol=1e-12
        positive = GLLVM._grouped_indep_variance_profile_objective(
            fixture.data, fixture.D, fixture.terms, fixture.incidences;
            selected=(1, 2), fixed_variance=0.16)
        @test positive.selected_coordinate(reduced) ≈ log(0.16) / 2 atol=1e-12
        ordinary = GLLVM._grouped_gaussian_objective(fixture.data, fixture.D,
            fixture.terms, fixture.incidences)
        full_with_minus_inf = [0.10, -0.15, log(0.40), -Inf,
            log(0.35), log(0.30), log(0.45)]
        full_positive = [0.10, -0.15, log(0.40), log(0.16) / 2,
            log(0.35), log(0.30), log(0.45)]
        @test positive.objective(reduced) ≈ ordinary(full_positive) atol=1e-12
        @test ordinary(full_with_minus_inf) == GLLVM._NLL_SENTINEL

        # The returned closure owns its design/term/incidence snapshot. Later
        # caller mutation cannot change the recorded objective.
        mutable_D = copy(fixture.D)
        mutable_terms = copy(fixture.terms)
        mutable_incidences = copy.(fixture.incidences)
        frozen = GLLVM._grouped_indep_variance_profile_objective(
            fixture.data, mutable_D, mutable_terms, mutable_incidences;
            selected=(1, 2), fixed_variance=0.0)
        frozen_value = frozen.objective(reduced)
        mutable_D .= 0.0
        mutable_terms[1] = GLLVM.GroupingTerm(:unit; mode=:indep, common=true)
        mutable_incidences[1].nzval .= 0.0
        @test frozen.objective(reduced) ≈ frozen_value atol=1e-12
end

@testset "profile Float64 conversion preserves boundary meaning" begin
    f = _profile_fixture()
    adapter = GLLVM._grouped_indep_variance_profile_objective(f.data, f.D,
        f.terms, f.incidences; selected=(1,2), fixed_variance=0.0)
    bad = BigFloat.([0.10,-0.15,log(0.40),log(0.35),log(0.30),log(0.45)])
    bad[1] = big"1e10000"
    @test adapter.objective(bad) == GLLVM._NLL_SENTINEL
    @test_throws ArgumentError adapter.selected_covariance(bad)
    @test_throws ArgumentError GLLVM._grouped_indep_variance_profile_objective(
        fill(big"1e10000", size(f.data)), f.D, f.terms, f.incidences;
        selected=(1,2), fixed_variance=0.0)
    @test_throws ArgumentError GLLVM._grouped_indep_variance_profile_objective(
        f.data, f.D, f.terms, f.incidences; selected=(1,2), fixed_variance=big"1e-10000")
end
