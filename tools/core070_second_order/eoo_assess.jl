# Shared each-own-optimum assessor for M2 remainder smokes.
# Tolerances copy the signed Gaussian/Poisson day-1/2 drivers
# (second-order-parity-contract.md §4). Do not widen here.

const EOO_SE_REL = 1e-2
const EOO_VCOV_FRO_REL = 1e-2
const EOO_CI_REL_HALF = 5e-2
const COND_SCALE_THRESHOLD = 1e3

const CONTRACT_S5_KEYS = (
    "hessian_selector",
    "hessian_selector_disputed",
    "matched_coordinates",
    "se_max_relative_delta",
    "vcov_frobenius_relative_delta",
    "ci_endpoint_max_delta",
    "native_condition_number",
    "r_condition_number",
    "pd_hessian_native",
    "pd_hessian_r",
    "derived_quantity",
)

function cond_scale(r_cond::Real)
    r_cond > COND_SCALE_THRESHOLD ? r_cond / COND_SCALE_THRESHOLD : 1.0
end

function assess_eoo(d::Dict{String,Any})
    issues = String[]
    if get(d, "skip_reason", nothing) !== nothing
        push!(issues, "skip: $(d["skip_reason"])")
        return false, issues
    end
    r_cond = something(d["r_condition_number"], NaN)
    scale = cond_scale(r_cond)

    se_rel = d["se_max_relative_delta"]
    if se_rel === nothing || !isfinite(se_rel)
        push!(issues, "missing se_max_relative_delta")
    elseif se_rel > EOO_SE_REL * scale
        push!(issues, "SE rel $(se_rel) > tol $(EOO_SE_REL * scale) (scale=$(scale), r_cond=$(r_cond))")
    end

    vcov_rel = d["vcov_frobenius_relative_delta"]
    if vcov_rel !== nothing && isfinite(vcov_rel) && vcov_rel > EOO_VCOV_FRO_REL * scale
        push!(issues, "vcov Fro rel $(vcov_rel) > tol $(EOO_VCOV_FRO_REL * scale)")
    end

    ci_d = d["ci_endpoint_max_delta"]
    if ci_d === nothing || !isfinite(ci_d)
        push!(issues, "missing ci_endpoint_max_delta")
    elseif ci_d <= 1e-4
        nothing
    else
        half = get(d, "ci_r_half_width", nothing)
        if half === nothing || !isfinite(half) || half <= 0
            se_abs = get(d, "se_max_abs_delta", nothing)
            half = se_abs === nothing ? nothing : se_abs * 1.959963984540054
        end
        if half === nothing || half <= 0
            push!(issues, "cannot compute CI half-width for relative gate")
        elseif ci_d / half > EOO_CI_REL_HALF
            push!(issues, "CI endpoint delta $(ci_d) / half-width $(half) > $(EOO_CI_REL_HALF)")
        end
    end

    return isempty(issues), issues
end

function missing_s5_keys(d::AbstractDict)
    [k for k in CONTRACT_S5_KEYS if !haskey(d, k)]
end

function eoo_receipt_extras(cell_id::AbstractString, receipt_id::AbstractString)
    return Dict{String,Any}(
        "receipt_id" => receipt_id,
        "receipt_date" => string(Dates.today()),
        "contract" => joinpath(@__DIR__, "..", "..", "docs", "dev-log", "core070",
            "second-order-parity-contract.md"),
        "tier" => "each-own-optimum",
        "tier_tolerances" => Dict(
            "se_rel" => EOO_SE_REL,
            "vcov_fro_rel" => EOO_VCOV_FRO_REL,
            "ci_rel_half_width" => EOO_CI_REL_HALF,
            "cond_scale_threshold" => COND_SCALE_THRESHOLD,
        ),
        "claim_boundary" => "M2 remainder smoke — NOT programme §7 second-order parity claim; not coverage/recovery/true-parity",
        "git_head" => try
            chomp(read(`git -C $(joinpath(@__DIR__, "..", "..")) rev-parse HEAD`, String))
        catch
            "unknown"
        end,
    )
end
