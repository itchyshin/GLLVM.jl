# Independent dense oracle for the future joint Gaussian phylogeny + ordinary
# grouping consumer. This fixture deliberately calls no production likelihood
# or fit routine.

using LinearAlgebra
using SparseArrays

const _DBJ_LOG2PI = log(2π)

function _dbj_commutation_np(n::Integer, p::Integer)
    K = zeros(Float64, n * p, n * p)
    for trait in 1:p, observation in 1:n
        K[(observation - 1) * p + trait, (trait - 1) * n + observation] = 1.0
    end
    return K
end

function _dbj_blockdiag(left::AbstractMatrix, right::AbstractMatrix)
    nl, ml = size(left)
    nr, mr = size(right)
    answer = zeros(Float64, nl + nr, ml + mr)
    answer[1:nl, 1:ml] .= left
    answer[(nl + 1):(nl + nr), (ml + 1):(ml + mr)] .= right
    return answer
end

function destination_b_joint_phylo_grouping_dense_nll(
        response::AbstractVector, mean::AbstractVector, covariance::AbstractMatrix)
    length(response) == length(mean) == size(covariance, 1) == size(covariance, 2) ||
        throw(DimensionMismatch("response, mean, and covariance dimensions disagree"))
    chol = cholesky(Symmetric(Matrix{Float64}(covariance)))
    residual = Float64.(response) .- Float64.(mean)
    quadratic = dot(residual, chol \ residual)
    return 0.5 * (length(response) * _DBJ_LOG2PI +
                  2sum(log, diag(chol.L)) + quadratic)
end

"""
    destination_b_joint_phylo_grouping_fixture()

Return an independent, dense, two-trait oracle for the proposed joint Gaussian
phylogenetic-plus-ordinary-grouped likelihood. The response is traits by
observations, so `vectorized_response == vec(response)` has observation blocks
with traits inside each block. Neither this fixture nor its NLL calls a GLLVModels
likelihood or optimiser.
"""
function destination_b_joint_phylo_grouping_fixture()
    # Nodes 1:2 are retained ancestors and are never observed directly. Tips
    # 1:2 map to nodes 3:4; tip 1 is observed three times and tip 2 twice.
    q_base = [4.0 -1.0 -1.0  0.0;
             -1.0  3.0  0.0 -1.0;
             -1.0  0.0  3.0  0.0;
              0.0 -1.0  0.0  3.0]
    applied_scale = 1.7
    Q = applied_scale .* q_base
    n_aug, n_tip = 4, 2
    species_aug_id = [3, 4]
    species_id = [1, 2, 1, 2, 1]
    n = length(species_id)
    p = 2
    S_phy = zeros(Float64, n, n_aug)
    for observation in 1:n
        S_phy[observation, species_aug_id[species_id[observation]]] = 1.0
    end

    # Rank-one low-rank block and an explicit phylogenetic unique companion.
    loading = reshape([0.70, -0.45], p, 1)
    phylo_unique_variance = [0.16, 0.09]
    phylo_factor = hcat(loading, Matrix(Diagonal(sqrt.(phylo_unique_variance))))
    n_fields = size(phylo_factor, 2)

    # One crossed ordinary source: its labels cross the repeated-tip pattern.
    crossed_labels = ["east", "west", "east", "north", "west"]
    crossed_code = [1, 2, 1, 3, 2]
    Z_group = sparse(collect(1:n), crossed_code, ones(Float64, n), n, 3)
    grouped_variance = [0.12, 0.22]
    W_group = kron(Matrix(Z_group), Matrix(Diagonal(sqrt.(grouped_variance))))

    # The native p x n response has observation-major trait blocks when vec'd.
    response = [0.25 -0.40 0.10 0.62 -0.18;
                -0.55 0.20 0.38 -0.71 0.44]
    x = [-1.0, -0.25, 0.15, 0.70, 1.10]
    mean_design = zeros(Float64, n * p, 3)
    for observation in 1:n
        mean_design[(observation - 1) * p + 1, 1] = 1.0
        mean_design[(observation - 1) * p + 2, 2] = 1.0
        mean_design[(observation - 1) * p + 1, 3] = x[observation]
        mean_design[(observation - 1) * p + 2, 3] = x[observation]
    end
    beta = [0.18, -0.12, 0.22]
    mean = mean_design * beta
    psi = [0.35, 0.55]

    # A_phy maps field-major/node-within-field f, whose precision is
    # I_fields kron Q, into observation-major/trait-within-observation y.
    K_np = _dbj_commutation_np(n, p)
    A_phy = K_np * kron(phylo_factor, S_phy)
    P_phy = kron(Matrix(I, n_fields, n_fields), Q)
    P_group = Matrix(I, size(W_group, 2), size(W_group, 2))
    prior_precision = _dbj_blockdiag(P_phy, P_group)
    A = hcat(A_phy, W_group)

    phylo_covariance = kron(S_phy * (Q \ S_phy'),
                             loading * loading' + Diagonal(phylo_unique_variance))
    grouped_covariance = kron(Matrix(Z_group * Z_group'), Diagonal(grouped_variance))
    residual_covariance = kron(Matrix(I, n, n), Diagonal(psi))
    covariance = Matrix(phylo_covariance + grouped_covariance + residual_covariance)
    precision_covariance = A * (prior_precision \ A') + residual_covariance
    vectorized_response = vec(response)
    expected_nll = destination_b_joint_phylo_grouping_dense_nll(
        vectorized_response, mean, covariance)

    return (
        response = response,
        vectorized_response = vectorized_response,
        mean_design = mean_design,
        beta = beta,
        mean = mean,
        Q = Q,
        n_aug = n_aug,
        n_tip = n_tip,
        node_labels = ["ancestor_1", "ancestor_2", "tip_A", "tip_B"],
        species_aug_id = species_aug_id,
        species_id = species_id,
        observed_augmented_nodes = species_aug_id[species_id],
        unobserved_ancestors = [1, 2],
        applied_scale = applied_scale,
        precision_logdet = logdet(cholesky(Symmetric(Q))),
        covariance_logdet_for_R = -logdet(cholesky(Symmetric(Q))),
        selection = S_phy,
        loading = loading,
        phylo_unique_variance = phylo_unique_variance,
        phylo_factor = phylo_factor,
        crossed_labels = crossed_labels,
        crossed_incidence = Z_group,
        grouped_variance = grouped_variance,
        psi = psi,
        A_phy = A_phy,
        W_group = W_group,
        prior_precision = prior_precision,
        phylo_covariance = Matrix(phylo_covariance),
        grouped_covariance = Matrix(grouped_covariance),
        residual_covariance = Matrix(residual_covariance),
        covariance = covariance,
        precision_covariance = Matrix(precision_covariance),
        expected_nll = expected_nll,
    )
end
