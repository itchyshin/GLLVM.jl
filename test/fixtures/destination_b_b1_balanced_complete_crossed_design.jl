# Immutable pre-run construction for Destination B B1.  This file constructs
# data and a static design diagnostic only; it never calls a fit or optimiser.

using LinearAlgebra
using Random

const _B1_BALANCED_COMPLETE_CROSSED = (
    seed = 20_260_915,
    n_trait = 2,
    n_unit = 12,
    n_obs_per_unit = 3,
    n_cluster = 10,
    n_cluster2 = 10,
    fixed_coefficients = [-0.20, 0.27],
    loading = [0.72, -0.51],
    sd_obs = [0.36, 0.27],
    sd_cluster = [0.43, 0.32],
    sd_cluster2 = [0.38, 0.29],
    sd_residual = 0.17,
    formula = "value ~ 0 + trait + latent(0 + trait | unit, d = 1, unique = FALSE) + indep(0 + trait | obs) + indep(0 + trait | cluster_id) + indep(0 + trait | cluster2_id)",
    reml = false,
)

# Retrieved from the retained stationary frozen-R B1 receipt.  These values are
# provenance inputs, not an assertion that the retained candidate qualified.
const _B1_BALANCED_COMPLETE_CROSSED_FROZEN_R = (
    git_sha = "b4d5fee64def88bc768dda1f1f77c29b295edd86",
    description_version = "0.7.0",
    archive_sha256 = "0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc",
    shared_library_sha256 = "3b6e7b63e072506d78ca5e468c1478758fa9aae333757b74c1f651cfab81da30",
    reference_runner_path = "tools/destination_b/b1_joint_gaussian_stationary_reference.R",
    runner_sha256 = "9d1f1fa95655bd8887d7e04d2c2d10c0311fac094205a4d47dd7ee6ebb9ca585",
    preflight_path = "tools/destination_b/b1_balanced_complete_crossed_preflight.R",
)

function _b1_complete_crossed_inner(left, nleft::Int, right, nright::Int, nwide::Int)
    if left === :residual || right === :residual
        return nwide
    end
    counts = zeros(Int, nleft, nright)
    @inbounds for i in eachindex(left)
        counts[left[i], right[i]] += 1
    end
    return sum(abs2, counts)
end

function _b1_complete_crossed_tensor_kernel(unit, obs, cluster, cluster2, specification)
    λ1, λ2 = specification.loading
    E1 = [1.0 0.0; 0.0 0.0]
    E2 = [0.0 0.0; 0.0 1.0]
    unit_tangent_1 = [2λ1 λ2; λ2 0.0]
    unit_tangent_2 = [0.0 λ1; λ1 2λ2]
    channels = (
        (name = :unit_loading_1, source = :unit, codes = unit, nlevels = specification.n_unit, tangent = unit_tangent_1),
        (name = :unit_loading_2, source = :unit, codes = unit, nlevels = specification.n_unit, tangent = unit_tangent_2),
        (name = :obs_trait_1, source = :obs, codes = obs, nlevels = specification.n_unit * specification.n_obs_per_unit, tangent = E1),
        (name = :obs_trait_2, source = :obs, codes = obs, nlevels = specification.n_unit * specification.n_obs_per_unit, tangent = E2),
        (name = :cluster_trait_1, source = :cluster, codes = cluster, nlevels = specification.n_cluster, tangent = E1),
        (name = :cluster_trait_2, source = :cluster, codes = cluster, nlevels = specification.n_cluster, tangent = E2),
        (name = :cluster2_trait_1, source = :cluster2, codes = cluster2, nlevels = specification.n_cluster2, tangent = E1),
        (name = :cluster2_trait_2, source = :cluster2, codes = cluster2, nlevels = specification.n_cluster2, tangent = E2),
        (name = :residual_trait_1, source = :residual, codes = :residual, nlevels = length(unit), tangent = E1),
        (name = :residual_trait_2, source = :residual, codes = :residual, nlevels = length(unit), tangent = E2),
    )
    kernel = zeros(Float64, length(channels), length(channels))
    for j in eachindex(channels), i in eachindex(channels)
        left, right = channels[i], channels[j]
        incidence_inner = _b1_complete_crossed_inner(left.codes, left.nlevels, right.codes, right.nlevels, length(unit))
        kernel[i, j] = incidence_inner * sum(left.tangent .* right.tangent)
    end
    scale = sqrt.(diag(kernel))
    normalized = kernel ./ (scale * scale')
    return (; channels, kernel, normalized, rank = rank(normalized), minimum_eigenvalue = minimum(eigvals(Symmetric(normalized))) )
end

"""
    destination_b_b1_balanced_complete_crossed_design()

Construct the immutable, complete-crossed B1 pre-run fixture: 12 units, three
nested observations per unit, and every `cluster × cluster2` pair for each
unit-observation.  The returned response is deterministic under the fixed seed.
It is a construction/static-design artefact, not a frozen-R or Julia fit.
"""
function destination_b_b1_balanced_complete_crossed_design()
    spec = _B1_BALANCED_COMPLETE_CROSSED
    nwide = spec.n_unit * spec.n_obs_per_unit * spec.n_cluster * spec.n_cluster2
    unit = Vector{Int}(undef, nwide)
    obs = Vector{Int}(undef, nwide)
    cluster = Vector{Int}(undef, nwide)
    cluster2 = Vector{Int}(undef, nwide)
    wide_formula = Vector{NamedTuple{(:unit, :obs, :cluster_id, :cluster2_id),Tuple{String,String,String,String}}}(undef, nwide)
    index = 0
    for u in 1:spec.n_unit, w in 1:spec.n_obs_per_unit, c in 1:spec.n_cluster, d in 1:spec.n_cluster2
        index += 1
        unit[index] = u
        obs[index] = (u - 1) * spec.n_obs_per_unit + w
        cluster[index] = c
        cluster2[index] = d
        wide_formula[index] = (unit = "u_$(lpad(u, 2, '0'))", obs = "u_$(lpad(u, 2, '0'))_w_$(lpad(w, 2, '0'))", cluster_id = "c_$(lpad(c, 2, '0'))", cluster2_id = "d_$(lpad(d, 2, '0'))")
    end

    rng = MersenneTwister(spec.seed)
    z_unit = randn(rng, spec.n_unit)
    obs_effect = randn(rng, spec.n_trait, spec.n_unit * spec.n_obs_per_unit) .* reshape(spec.sd_obs, :, 1)
    cluster_effect = randn(rng, spec.n_trait, spec.n_cluster) .* reshape(spec.sd_cluster, :, 1)
    cluster2_effect = randn(rng, spec.n_trait, spec.n_cluster2) .* reshape(spec.sd_cluster2, :, 1)
    response_wide = Matrix{Float64}(undef, spec.n_trait, nwide)
    @inbounds for i in 1:nwide
        response_wide[:, i] = spec.fixed_coefficients .+ spec.loading .* z_unit[unit[i]] .+
            obs_effect[:, obs[i]] .+ cluster_effect[:, cluster[i]] .+
            cluster2_effect[:, cluster2[i]] .+ spec.sd_residual .* randn(rng, spec.n_trait)
    end
    trait = repeat(["trait_1", "trait_2"], nwide)
    long = [(value = response_wide[t, i], trait = trait[(i - 1) * spec.n_trait + t], unit = wide_formula[i].unit,
             obs = wide_formula[i].obs, cluster_id = wide_formula[i].cluster_id, cluster2_id = wide_formula[i].cluster2_id)
            for i in 1:nwide for t in 1:spec.n_trait]
    tensor = _b1_complete_crossed_tensor_kernel(unit, obs, cluster, cluster2, spec)
    return (; specification = spec, nwide, nlong = length(long), unit, obs, cluster, cluster2,
        wide_formula, response_wide, long, tensor, frozen_r = _B1_BALANCED_COMPLETE_CROSSED_FROZEN_R)
end
