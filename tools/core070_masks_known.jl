# Independent Julia-side fixed-point reconstruction for the masks-known-contract
# cases. GLLVM.jl has no public `lambda_constraint` / `known_V` surface yet, so
# this is deliberately a hand-coded reference reconstruction (Base + LinearAlgebra
# only) of the Gaussian marginal density the frozen R fixture reports, run
# against the R-retained points/<CASE>-P{1,2}/{observations,source,parameters}.tsv
# artifacts produced by tools/core070_masks_known_points.R. It does not call
# GLLVM.jl at all: there is nothing in the package's public or internal surface
# for this feature to call. See docs/dev-log/core070/masks-known-contract.json.
#
# Usage:
#   julia tools/core070_masks_known.jl <points-dir> <output.json>
#
# <points-dir> is the `out` directory written by core070_masks_known_points.R
# (contains points.tsv, maps.tsv, and one subdirectory per <CASE>-P{1,2}).

using LinearAlgebra

const CONTRACT_PATH = joinpath(@__DIR__, "..", "docs", "dev-log", "core070", "masks-known-contract.json")

# ---------------------------------------------------------------------------
# Minimal TSV reader (no external dependency; header + tab-split rows).
# ---------------------------------------------------------------------------
function read_tsv(path::AbstractString)
    lines = readlines(path)
    isempty(lines) && throw(ArgumentError("empty TSV: $path"))
    header = split(lines[1], '\t')
    rows = [split(l, '\t') for l in lines[2:end] if !isempty(l)]
    return String.(header), rows
end

function read_matrix_tsv(path::AbstractString)
    header, rows = read_tsv(path)
    n = length(header)
    M = Matrix{Float64}(undef, length(rows), n)
    for (i, row) in enumerate(rows)
        length(row) == n || throw(ArgumentError("ragged matrix row in $path"))
        for j in 1:n
            M[i, j] = parse(Float64, row[j])
        end
    end
    return M
end

struct Observations
    trait::Vector{Int}
    group::Vector{Int}
    y::Vector{Float64}
end

function read_observations(path::AbstractString)
    header, rows = read_tsv(path)
    header == ["trait", "group", "y"] || throw(ArgumentError("unexpected observations header in $path"))
    trait = [parse(Int, r[1]) for r in rows]
    group = [parse(Int, r[2]) for r in rows]
    y = [parse(Float64, r[3]) for r in rows]
    return Observations(trait, group, y)
end

struct ParamPoint
    names::Vector{String}
    values::Vector{Float64}
    r_gradient::Vector{Float64}
end

function read_parameters(path::AbstractString)
    header, rows = read_tsv(path)
    header[1:3] == ["name", "value", "r_gradient"] || throw(ArgumentError("unexpected parameters header in $path"))
    names = [r[1] for r in rows]
    values = [parse(Float64, r[2]) for r in rows]
    r_gradient = [parse(Float64, r[3]) for r in rows]
    return ParamPoint(names, values, r_gradient)
end

# ---------------------------------------------------------------------------
# Loading-mask reconstruction (diagonal-first, strict-lower packing of the
# rank-two raw loading vector L11,L22,L21,L31,L32; see masks-known-contract.json).
# ---------------------------------------------------------------------------
function reconstruct_theta(map_tokens::Vector{String}, pins::Vector{Float64}, free::Vector{Float64})
    theta = Vector{Float64}(undef, length(map_tokens))
    pin_i = 1
    for (k, tok) in enumerate(map_tokens)
        if tok == "NA"
            pin_i <= length(pins) || throw(ArgumentError("more NA map slots than pins"))
            theta[k] = pins[pin_i]
            pin_i += 1
        else
            idx = parse(Int, tok)
            idx >= 1 && idx <= length(free) || throw(ArgumentError("map index out of free-vector range"))
            theta[k] = free[idx]
        end
    end
    pin_i == length(pins) + 1 || throw(ArgumentError("not all pins consumed"))
    return theta
end

function build_lambda(theta::Vector{Float64})
    length(theta) == 5 || throw(ArgumentError("raw loading vector must have 5 coordinates"))
    L = zeros(3, 2)
    L[1, 1] = theta[1]
    L[2, 2] = theta[2]
    L[2, 1] = theta[3]
    L[3, 1] = theta[4]
    L[3, 2] = theta[5]
    return L
end

# ---------------------------------------------------------------------------
# Covariance assembly + normalized Gaussian marginal nll.
# ---------------------------------------------------------------------------
function assemble_sigma(sigma_eps::Real, C::Matrix{Float64}, group::Vector{Int}, trait::Vector{Int};
                         Lambda::Union{Nothing,Matrix{Float64}}=nothing)
    n = length(group)
    Sigma = Matrix{Float64}(undef, n, n)
    sigma2 = sigma_eps^2
    for j in 1:n, i in 1:n
        cij = C[group[i], group[j]]
        s = Lambda === nothing ? cij : cij * dot(view(Lambda, trait[i], :), view(Lambda, trait[j], :))
        Sigma[i, j] = s + (i == j ? sigma2 : 0.0)
    end
    return Sigma
end

function normalized_nll(y::Vector{Float64}, mean::Vector{Float64}, Sigma::Matrix{Float64})
    n = length(y)
    resid = y .- mean
    F = cholesky(Symmetric(Sigma))
    return (n * log(2pi) + logdet(F) + dot(resid, F \ resid)) / 2
end

# ---------------------------------------------------------------------------
# Per-point evaluator: `par` is the exact free-parameter vector TMB reports
# (parameters.tsv row order: b_fix x3, log_sigma_eps, [field x nfree]).
# ---------------------------------------------------------------------------
function evaluate(pp::ParamPoint, obs::Observations, C::Matrix{Float64};
                   field::Union{Nothing,String}=nothing,
                   map_tokens::Union{Nothing,Vector{String}}=nothing,
                   pins::Union{Nothing,Vector{Float64}}=nothing)
    b_idx = findall(==("b_fix"), pp.names)
    length(b_idx) == 3 || throw(ArgumentError("expected 3 b_fix entries"))
    sig_idx = findfirst(==("log_sigma_eps"), pp.names)
    sig_idx === nothing && throw(ArgumentError("missing log_sigma_eps"))
    free_idx = field === nothing ? Int[] : findall(==(field), pp.names)

    function nll_of(values::Vector{Float64})
        beta = values[b_idx]
        sigma_eps = exp(values[sig_idx])
        mean = [beta[t] for t in obs.trait]
        Lambda = if field === nothing
            nothing
        else
            theta = reconstruct_theta(map_tokens, pins, values[free_idx])
            build_lambda(theta)
        end
        Sigma = assemble_sigma(sigma_eps, C, obs.group, obs.trait; Lambda=Lambda)
        return normalized_nll(obs.y, mean, Sigma)
    end

    value = nll_of(pp.values)
    grad = similar(pp.values)
    step = 1e-5
    for k in eachindex(pp.values)
        up = copy(pp.values); up[k] += step
        dn = copy(pp.values); dn[k] -= step
        grad[k] = (nll_of(up) - nll_of(dn)) / (2step)
    end
    return value, grad, nll_of
end

# ---------------------------------------------------------------------------
# Minimal JSON writer (no external dependency).
# ---------------------------------------------------------------------------
json_escape(s::AbstractString) = replace(s, "\\" => "\\\\", "\"" => "\\\"")
to_json(x::Bool) = x ? "true" : "false"
to_json(x::Nothing) = "null"
to_json(x::AbstractString) = "\"" * json_escape(x) * "\""
to_json(x::Real) = isfinite(x) ? string(Float64(x)) : "null"
function to_json(x::AbstractVector)
    "[" * join(to_json.(x), ",") * "]"
end
function to_json(x::AbstractDict)
    "{" * join(("\"$(json_escape(string(k)))\":" * to_json(v) for (k, v) in x), ",") * "}"
end
write_json_pretty(io::IO, x) = print(io, to_json(x))

# ---------------------------------------------------------------------------
# One case-point check against the contract's tolerances.
# ---------------------------------------------------------------------------
function check_point(points_dir::AbstractString, point_id::AbstractString, r_nll::Float64;
                      field::Union{Nothing,String}=nothing,
                      map_tokens::Union{Nothing,Vector{String}}=nothing,
                      pins::Union{Nothing,Vector{Float64}}=nothing,
                      tol_nll::Float64=1e-6, tol_grad::Float64=1e-5)
    dir = joinpath(points_dir, point_id)
    obs = read_observations(joinpath(dir, "observations.tsv"))
    C = read_matrix_tsv(joinpath(dir, "source.tsv"))
    pp = read_parameters(joinpath(dir, "parameters.tsv"))
    value, grad, _ = evaluate(pp, obs, C; field=field, map_tokens=map_tokens, pins=pins)
    abs_nll_delta = abs(value - r_nll)
    scaled_err = maximum(abs.(grad .- pp.r_gradient) ./ max.(1.0, abs.(pp.r_gradient)))
    passed = isfinite(abs_nll_delta) && isfinite(scaled_err) &&
             abs_nll_delta <= tol_nll && scaled_err <= tol_grad
    return Dict{String,Any}(
        "point_id" => point_id,
        "julia_nll" => value,
        "r_nll" => r_nll,
        "abs_nll_delta" => abs_nll_delta,
        "central_fd_scaled_gradient_error" => scaled_err,
        "n_free_parameters" => length(pp.values),
        "pass" => passed,
    )
end

# ---------------------------------------------------------------------------
# Batch driver.
# ---------------------------------------------------------------------------
function parse_points_tsv(points_dir::AbstractString)
    header, rows = read_tsv(joinpath(points_dir, "points.tsv"))
    idx = Dict(name => i for (i, name) in enumerate(header))
    out = Dict{String,Float64}()
    for row in rows
        out[row[idx["id"]]] = parse(Float64, row[idx["r_nll"]])
    end
    return out
end

function parse_maps_tsv(points_dir::AbstractString)
    header, rows = read_tsv(joinpath(points_dir, "maps.tsv"))
    idx = Dict(name => i for (i, name) in enumerate(header))
    out = Dict{String,NamedTuple}()
    for row in rows
        id = row[idx["id"]]
        field = row[idx["field"]]
        map_str = row[idx["map"]]
        pins_str = row[idx["pins"]]
        out[id] = (
            field = field == "none" ? nothing : String(field),
            map_tokens = map_str == "none" ? nothing : String.(split(map_str, ',')),
            pins = pins_str == "none" ? nothing : parse.(Float64, split(pins_str, ',')),
        )
    end
    return out
end

const REQUIRED_CASE_IDS = [
    "KNOWN-EXACT", "KNOWN-ALIAS", "KNOWN-BLOCK", "KNOWN-ZERO",
    "MASK-B-PINS", "MASK-B-UPPER", "MASK-B-ALLFIXED", "MASK-PHY-PINS",
]

"""
    run_masks_known_points(points_dir; output)

Independently reconstruct and verify all 16 (8 case x P1/P2) fixed-point
Gaussian normalized nll/gradient checks from the R-retained TSV artifacts
under `points_dir`, plus the KNOWN-POISSON structural-only marker. Writes a
single results JSON to `output` and returns the parsed result Dict.
"""
function run_masks_known_points(points_dir::AbstractString; output::Union{Nothing,AbstractString}=nothing)
    r_nll = parse_points_tsv(points_dir)
    maps = parse_maps_tsv(points_dir)
    cases = Dict{String,Any}()
    all_pass = true
    for case_id in REQUIRED_CASE_IDS
        m = maps[case_id]
        points = Dict{String,Any}()
        for suffix in ("P1", "P2")
            point_id = "$(case_id)-$(suffix)"
            r = check_point(points_dir, point_id, r_nll[point_id];
                             field=m.field, map_tokens=m.map_tokens, pins=m.pins)
            points[suffix] = r
            all_pass &= r["pass"]
        end
        cases[case_id] = Dict{String,Any}("status" => "CHECKED", "points" => points)
    end
    cases["KNOWN-POISSON"] = Dict{String,Any}(
        "status" => "SPEC_DEFECT",
        "reason" => "R reference makes no density/fit claim for this case; nothing for the Julia " *
                    "reconstruction to reproduce numerically. See masks-known-contract.json evidence_kind=structural_only.",
    )
    result = Dict{String,Any}(
        "scope" => "CORE070_MASKS_KNOWN_JULIA_FIXED_POINT_RECONSTRUCTION",
        "points_dir" => abspath(points_dir),
        "cases" => cases,
        "all_gaussian_points_pass" => all_pass,
    )
    if output !== nothing
        open(output, "w") do io
            write_json_pretty(io, result)
        end
    end
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    length(ARGS) == 2 || error("usage: julia tools/core070_masks_known.jl <points-dir> <output.json>")
    result = run_masks_known_points(ARGS[1]; output=ARGS[2])
    println("CORE070_MASKS_KNOWN_JULIA_ALL_PASS ", result["all_gaussian_points_pass"])
    result["all_gaussian_points_pass"] || exit(1)
end
