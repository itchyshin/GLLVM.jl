# Independent dense reference objects for Destination B; never calls a kernel or fit.
using LinearAlgebra
using Random

const _DB_NOBS, _DB_NTRAIT, _DB_LOG2PI = 8, 2, log(2π)

function destination_b_exact_nll(y::AbstractVector, mean::AbstractVector, covariance::AbstractMatrix)
    @assert length(y) == length(mean) == size(covariance, 1) == size(covariance, 2)
    chol = cholesky(Symmetric(Matrix{Float64}(covariance)))
    z = chol.L \ (Float64.(y) .- Float64.(mean))
    0.5 * (length(y) * _DB_LOG2PI + 2sum(log, diag(chol.L)) + dot(z, z))
end

function destination_b_draw(mean::AbstractVector, covariance::AbstractMatrix; seed::Integer = 20260907)
    chol = cholesky(Symmetric(Matrix{Float64}(covariance)))
    Float64.(mean) .+ chol.L * randn(MersenneTwister(seed), length(mean))
end

# Unequal and intentionally reordered units; crossedcluster crosses unit.
const _DB_UNIT = ["g3", "g1", "g3", "g1", "g2", "g4", "g1", "g3"]
const _DB_OBS = ["o2", "o1", "o2", "o1", "o1", "o2", "o2", "o1"]
const _DB_CROSSED = ["east", "west", "east", "west", "east", "west", "west", "east"]
const _DB_CLUSTER2 = ["d2", "d1", "d2", "d1", "d3", "d3", "d1", "d2"]

function _db_grouping_entry(i, s, j, t; unit, observation, crossed, cluster2,
                            unit_covariance, nested_covariance, crossed_covariance,
                            cluster2_variance, residual_variance)
    value = i == j && s == t ? residual_variance[s] : 0.0
    value += unit[i] == unit[j] ? unit_covariance[s, t] : 0.0
    value += unit[i] == unit[j] && observation[i] == observation[j] ? nested_covariance[s, t] : 0.0
    value += crossed[i] == crossed[j] ? crossed_covariance[s, t] : 0.0
    # cluster2 is diagonal across traits but shared across observations by label.
    value += cluster2[i] == cluster2[j] && s == t ? cluster2_variance[s] : 0.0
    value
end

"""Two-trait oracle with exactly unit, unit_obs, crossedcluster, and cluster2 sources."""
function destination_b_grouping_fixture()
    response = [0.40 -0.90 1.20 -0.10 0.70 -1.10 0.30 0.95;
                -0.20 0.75 -0.45 0.55 -0.80 0.15 1.05 -0.35]
    mean = [0.15 -0.30 0.60 0.05 0.20 -0.55 0.10 0.45;
            -0.10 0.25 -0.20 0.30 -0.35 0.05 0.45 -0.15]
    source_covariance = (unit = [0.64 0.12; 0.12 0.49],
                         nested = [0.36 -0.08; -0.08 0.25],
                         crossed = [0.25 0.05; 0.05 0.16],
                         cluster2 = [0.49, 0.31], residual = [0.21, 0.21])
    covariance = Matrix{Float64}(undef, _DB_NTRAIT * _DB_NOBS, _DB_NTRAIT * _DB_NOBS)
    for t in 1:_DB_NTRAIT, s in 1:_DB_NTRAIT, j in 1:_DB_NOBS, i in 1:_DB_NOBS
        covariance[s + (i - 1) * _DB_NTRAIT, t + (j - 1) * _DB_NTRAIT] =
            _db_grouping_entry(i, s, j, t; unit = _DB_UNIT, observation = _DB_OBS,
                crossed = _DB_CROSSED, cluster2 = _DB_CLUSTER2,
                unit_covariance = source_covariance.unit, nested_covariance = source_covariance.nested,
                crossed_covariance = source_covariance.crossed,
                cluster2_variance = source_covariance.cluster2, residual_variance = source_covariance.residual)
    end
    y, μ = vec(response), vec(mean)
    (response = response, mean = mean, vectorized_response = y, vectorized_mean = μ,
     covariance = covariance, source_covariance = source_covariance,
     labels = (unit = copy(_DB_UNIT), observation = copy(_DB_OBS), crossed = copy(_DB_CROSSED), cluster2 = copy(_DB_CLUSTER2)),
     exact_nll = destination_b_exact_nll(y, μ, covariance))
end

destination_b_grouping_draw(seed::Integer = 20260907) = begin
    f = destination_b_grouping_fixture(); destination_b_draw(f.vectorized_mean, f.covariance; seed)
end

function _db_phylo_entry(i, s, j, t; node_covariance, observation_nodes, trait_loadings, scale, residual_sd)
    value = scale * node_covariance[observation_nodes[i], observation_nodes[j]] * dot(view(trait_loadings, s, :), view(trait_loadings, t, :))
    value + (i == j && s == t ? residual_sd[s]^2 : 0.0)
end

"""Five-node complete covariance with retained but unobserved node 5 and repeated node 3."""
function destination_b_precision_fixture()
    node_covariance = [1.00 0.55 0.30 0.30 0.20; 0.55 1.00 0.30 0.30 0.20;
                       0.30 0.30 1.00 0.62 0.45; 0.30 0.30 0.62 1.00 0.45;
                       0.20 0.20 0.45 0.45 1.00]
    observation_nodes = [3, 1, 3, 4, 2]
    trait_loadings, residual_sd, scale = [1.00 0.20; -0.40 0.70], [0.30, 0.50], 1.40
    response = [0.25 -0.40; 0.90 0.10; -0.15 0.35; 0.60 -0.75; -0.20 0.55]
    mean = [0.10 -0.20; 0.35 0.05; -0.10 0.20; 0.25 -0.30; 0.00 0.40]
    nobs, ntrait = size(response); covariance = Matrix{Float64}(undef, nobs * ntrait, nobs * ntrait)
    for t in 1:ntrait, s in 1:ntrait, j in 1:nobs, i in 1:nobs
        covariance[i + (s - 1) * nobs, j + (t - 1) * nobs] = _db_phylo_entry(i, s, j, t;
            node_covariance, observation_nodes, trait_loadings, scale, residual_sd)
    end
    (response = response, mean = mean, vectorized_response = vec(response), vectorized_mean = vec(mean),
     covariance = covariance, node_covariance = node_covariance, node_precision = inv(node_covariance),
     observation_nodes = observation_nodes, unobserved_nodes = [5], trait_loadings = trait_loadings,
     residual_sd = residual_sd, scale = scale,
     exact_nll = destination_b_exact_nll(vec(response), vec(mean), covariance))
end

destination_b_precision_draw(seed::Integer = 20260907) = begin
    f = destination_b_precision_fixture(); destination_b_draw(f.vectorized_mean, f.covariance; seed)
end
