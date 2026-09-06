# theta_map.jl — R opt$par → Julia θ for matched-coordinates second-order tier.
# Anchor: R's converged opt$par (contract §4 matched-coordinates diagnostic).
# Returns either (:ok, θ_julia) or (:blocked, blocker_dict).

struct ThetaMapBlocker
    reason::String
    r_param_counts::Dict{String, Int}
    julia_theta_len::Int
    note::String
end

function _count_names(names::AbstractVector{<:AbstractString})
    d = Dict{String, Int}()
    for nm in names
        d[nm] = get(d, nm, 0) + 1
    end
    return d
end

"""Standard GLM cells: θ = [b_fix; theta_rr_B] (+ optional dispersion of length 1 or p).

Dispersion gate (memo `theta-map-parameter-alignment-2026-09-05.md`):
accept `|log_phi_*| == 1` (shared) or `|log_phi_*| == p` (`fit_gllvm` grouped ×p).
Reject other lengths — no silent p→1 pooling and no unmapped G ∉ {1, p}.
"""
function map_r_theta_glm(rpar, rnames, p, K; disp_name=nothing, julia_theta_len=nothing)
    counts = _count_names(rnames)
    bidx = findall(==("b_fix"), rnames)
    lidx = findall(==("theta_rr_B"), rnames)
    length(bidx) == p || return (:blocked, ThetaMapBlocker(
        "b_fix length mismatch",
        counts, julia_theta_len === nothing ? 0 : julia_theta_len,
        "expected $(p) b_fix entries, got $(length(bidx))"))
    length(lidx) == GLLVM.rr_theta_len(p, K) || return (:blocked, ThetaMapBlocker(
        "theta_rr_B length mismatch",
        counts, julia_theta_len === nothing ? 0 : julia_theta_len,
        "expected $(GLLVM.rr_theta_len(p, K)) theta_rr_B entries, got $(length(lidx))"))
    parts = [rpar[bidx], rpar[lidx]]
    if disp_name !== nothing
        didx = findall(==(disp_name), rnames)
        nd = length(didx)
        # Memo lines 23–24, 107–116: batch-1 `fit_gllvm` is per-trait length p.
        # Length-1-only was a harness false-negative, not a model mismatch.
        if nd != 1 && nd != p
            return (:blocked, ThetaMapBlocker(
                "dispersion parameterization mismatch",
                counts, julia_theta_len === nothing ? 0 : julia_theta_len,
                "expected |$(disp_name)| ∈ {1, p=$p} (shared or fit_gllvm per-trait); R has $nd entries — no group map for G ∉ {1,p}"))
        end
        push!(parts, rpar[didx])
    end
    θ = vcat(parts...)
    if julia_theta_len !== nothing && length(θ) != julia_theta_len
        return (:blocked, ThetaMapBlocker(
            "packed length mismatch after map",
            counts, julia_theta_len,
            "mapped length $(length(θ)) != Julia nll length $julia_theta_len"))
    end
    return (:ok, θ)
end

"""Gaussian no-X (Y pre-centred): θ = [log_sigma_eps; theta_rr_B]; R b_fix excluded."""
function map_r_theta_gaussian(rpar, rnames, p, K; julia_theta_len=nothing)
    counts = _count_names(rnames)
    sidx = findfirst(==("log_sigma_eps"), rnames)
    lidx = findall(==("theta_rr_B"), rnames)
    sidx === nothing && return (:blocked, ThetaMapBlocker(
        "missing log_sigma_eps", counts, julia_theta_len === nothing ? 0 : julia_theta_len,
        "R par has no log_sigma_eps"))
    length(lidx) == GLLVM.rr_theta_len(p, K) || return (:blocked, ThetaMapBlocker(
        "theta_rr_B length mismatch", counts, julia_theta_len === nothing ? 0 : julia_theta_len,
        "expected $(GLLVM.rr_theta_len(p, K)) theta_rr_B entries"))
    θ = vcat(rpar[sidx], rpar[lidx])
    if julia_theta_len !== nothing && length(θ) != julia_theta_len
        return (:blocked, ThetaMapBlocker(
            "packed length mismatch after map", counts, julia_theta_len,
            "mapped length $(length(θ)) != Julia nll length $julia_theta_len"))
    end
    note = "R b_fix ($(count(==("b_fix"), rnames)) entries) excluded — Julia Gaussian path has no trait intercept (Y pre-centred)"
    return (:ok, θ, note)
end

function map_r_to_julia_theta(cell_id::AbstractString, rpar, rnames, p, K; julia_theta_len=nothing)
    if cell_id in ("poisson", "binomial_logit")
        return map_r_theta_glm(rpar, rnames, p, K; julia_theta_len=julia_theta_len)
    elseif cell_id == "gaussian"
        return map_r_theta_gaussian(rpar, rnames, p, K; julia_theta_len=julia_theta_len)
    elseif cell_id == "beta_logit"
        return map_r_theta_glm(rpar, rnames, p, K;
            disp_name="log_phi_beta", julia_theta_len=julia_theta_len)
    elseif cell_id == "nb2_log"
        return map_r_theta_glm(rpar, rnames, p, K;
            disp_name="log_phi_nbinom2", julia_theta_len=julia_theta_len)
    else
        return (:blocked, ThetaMapBlocker(
            "unknown cell_id", _count_names(rnames), julia_theta_len === nothing ? 0 : julia_theta_len,
            "no θ map registered for $cell_id"))
    end
end

function blocker_dict(b::ThetaMapBlocker)
    return Dict{String, Any}(
        "status" => "blocked",
        "blocker_reason" => b.reason,
        "r_param_counts" => b.r_param_counts,
        "julia_theta_len" => b.julia_theta_len,
        "blocker_note" => b.note,
    )
end
