# The fixture is frozen to gllvmTMB commit
# b4d5fee64def88bc768dda1f1f77c29b295edd86.  These bindings are source
# preparation, not fit, likelihood, derivative, recovery, or parity evidence.

using LinearAlgebra

const CORE070_GAUSSIAN_SOURCE_REFERENCE =
    "b4d5fee64def88bc768dda1f1f77c29b295edd86"

const _CORE070_GAUSSIAN_SOURCE_IDS = (
    :STRUCT_PHY_TREE_RR,
    :STRUCT_PHY_DENSE_RR,
    :STRUCT_PHY_TREE_PROPTO,
    :STRUCT_ANI_PED_SPARSE,
    :STRUCT_KER_SINGLE_PSI,
    :STRUCT_KER_MULTI,
)

function _core070_response_matrix(y, trait_id, site_id)
    length(y) == length(trait_id) == length(site_id) ||
        throw(DimensionMismatch("Core070 response, trait_id, and site_id lengths differ"))
    all(t -> 0 <= t < 3, trait_id) || throw(ArgumentError("Core070 trait ids must be 0:2"))
    all(s -> 0 <= s < 12, site_id) || throw(ArgumentError("Core070 site ids must be 0:11"))
    length(y) == 36 || throw(DimensionMismatch("Core070 requires 36 long response rows"))
    Y = fill(NaN, 3, 12)
    for i in eachindex(y)
        row, col = trait_id[i] + 1, site_id[i] + 1
        isnan(Y[row, col]) || throw(ArgumentError("Core070 long response has a duplicate trait/site cell"))
        Y[row, col] = y[i]
    end
    all(isfinite, Y) || throw(ArgumentError("Core070 long response does not cover every 3 × 12 cell"))
    return Y
end

function _core070_response_fixture()
    # Exact retained long rows: trait varies slowest, site varies fastest.
    y = Float64[
        0.52719469679615227, 0.81836980306973706, 1.0414709848078965,
        1.1719379013633127, 1.1954079577517649, 1.1092974268256817,
        0.92308588173832451, 0.65727262663581199, 0.3411200080598672,
        0.0094320371245146251, -0.30127704858834475, -0.55680249530792825,
        -0.52901450127076188, -0.59895491709792825, -0.55892427466313843,
        -0.41332939156757997, -0.17819824174430887, 0.12058450180107416,
        0.45012700988217275, 0.77415123057121993, 1.056986598718789,
        1.2674968696188058, 1.3825077869863733, 1.3893582466233818,
        1.4872941080946944, 1.2875512151130617, 1.0121184852417566,
        0.69131723555474922, 0.36046322686968407, 0.055978889110630203,
        -0.18861628222322424, -0.34639575683810797, -0.3999902065507035,
        -0.34349962701548475, -0.18314284623659005, 0.063427081999565038,
    ]
    trait_id = repeat(collect(0:2), inner = 12)
    site_id = repeat(collect(0:11), outer = 3)
    return _core070_response_matrix(y, trait_id, site_id)
end

_core070_species_groups() = repeat(1:3, inner = 4)
_core070_tree_groups() = repeat(2:4, inner = 4)
_core070_pedigree_groups() = repeat([3, 4], inner = 6)

function _core070_source_specification(id::Symbol)
    id in _CORE070_GAUSSIAN_SOURCE_IDS || throw(ArgumentError("unsupported Core070 source id: $id"))
    I3 = Matrix{Float64}(I, 3, 3)
    C = 0.7I3 + 0.3ones(3, 3)
    K2 = 0.6I3 + 0.4 * [1.0, -1.0, 1.0] * [1.0, -1.0, 1.0]'
    Qtree = Float64[6 -2 -2 0; -2 2 0 0; -2 0 2 0; 0 0 0 1]
    Qped = Float64[2 1 -1 -1; 1 2 -1 -1; -1 -1 2 0; -1 -1 0 2]
    beta = Float64[0.57804248168973249, 0.34689924315484166, 0.29137546026000255]
    log_sigma_eps = -0.39432656302578389

    if id === :STRUCT_PHY_TREE_RR
        source = GLLVM.SourceCovariance(Symmetric(inv(Symmetric(Qtree)));
            groups = _core070_tree_groups(),
            name = :phylo_tree_rr, mode = :latent, rank = 1)
        start = vcat(beta, [0.5, 0.0, 0.0], log_sigma_eps)
    elseif id === :STRUCT_PHY_DENSE_RR
        source = GLLVM.SourceCovariance(C + 1e-8I3;
            groups = _core070_species_groups(),
            name = :phylo_dense_rr, mode = :latent, rank = 1)
        start = vcat(beta, [0.5, 0.0, 0.0], log_sigma_eps)
    elseif id === :STRUCT_PHY_TREE_PROPTO
        # R's free loglambda is a log variance.  The candidate API expects a
        # log SD, hence the exact transformed start is loglambda_phy / 2 = 0.
        Ctree = Float64[1 0.5 0; 0.5 1 0; 0 0 1]
        source = GLLVM.SourceCovariance(Ctree + 1e-8I3;
            groups = _core070_species_groups(),
            name = :phylo_tree_propto, mode = :indep, common = true)
        start = vcat(beta, 0.0, log_sigma_eps)
    elseif id === :STRUCT_ANI_PED_SPARSE
        source = GLLVM.SourceCovariance(Symmetric(inv(Symmetric(Qped)));
            groups = _core070_pedigree_groups(),
            name = :animal_pedigree_sparse, mode = :latent, rank = 1)
        start = vcat(beta, [0.5, 0.0, 0.0], log_sigma_eps)
    elseif id === :STRUCT_KER_SINGLE_PSI
        source = GLLVM.SourceCovariance(C + 1e-8I3;
            groups = _core070_species_groups(),
            name = :kernel_single_psi, mode = :latent, rank = 1, unique = true)
        start = vcat(beta, [0.5, 0.0, 0.0], [0.0, 0.0, 0.0], log_sigma_eps)
    else # :STRUCT_KER_MULTI
        source1 = GLLVM.SourceCovariance(C + 1e-8I3;
            groups = _core070_species_groups(),
            name = :kernel_k1, mode = :latent, rank = 1)
        source2 = GLLVM.SourceCovariance(K2 + 1e-8I3;
            groups = _core070_species_groups(),
            name = :kernel_k2, mode = :latent, rank = 1)
        source = (source1, source2)
        start = vcat(beta, [0.5, 0.0, 0.0], [0.5, 0.0, 0.0], log_sigma_eps)
    end
    return source, start
end

function _core070_validate_binding(id, Y, sources, start)
    expected_start_length = id === :STRUCT_PHY_TREE_PROPTO ? 5 :
        id === :STRUCT_KER_SINGLE_PSI || id === :STRUCT_KER_MULTI ? 10 : 7
    size(Y) == (3, 12) || throw(DimensionMismatch("Core070 binding Y must be 3 × 12"))
    all(s -> size(s.projection) == (12, size(s.covariance, 1)), sources) ||
        throw(DimensionMismatch("Core070 source projection must be units × source nodes"))
    length(start) == expected_start_length ||
        throw(DimensionMismatch("Core070 binding start has the wrong candidate parameter layout"))
    return nothing
end

"""
    core070_gaussian_source_binding(id::Symbol)

Return a source-pinned preparation binding for one captured nonspatial Core070
reference case. The return value has `Y` (traits × units), named
`GLLVM.SourceCovariance` specifications, and the exact candidate API `start`
vector. It does not call an optimizer. Include this file only after loading
`GLLVM`; construction and the two sparse precision inverses occur only when
this function is called.
"""
function core070_gaussian_source_binding(id::Symbol)
    sources, start = _core070_source_specification(id)
    source_vector = sources isa Tuple ? collect(sources) : [sources]
    Y = _core070_response_fixture()
    _core070_validate_binding(id, Y, source_vector, start)
    return (
        id = id,
        captured_id = replace(String(id), '_' => '-'),
        reference_commit = CORE070_GAUSSIAN_SOURCE_REFERENCE,
        Y = Y,
        sources = source_vector,
        start = start,
        fit_call = "GLLVM.fit_gaussian_sources(binding.Y; sources=binding.sources, start=binding.start)",
    )
end

"""Accept the exact hyphenated ID retained in the Core070 export."""
core070_gaussian_source_binding(id::AbstractString) =
    core070_gaussian_source_binding(Symbol(replace(id, '-' => '_')))
