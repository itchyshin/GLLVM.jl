# SQUAREM acceleration for the gradient-free EM fit of the Gaussian phylo
# GLLVM (`em_phylo.jl`).
#
# ---------------------------------------------------------------------------
# Why
# ---------------------------------------------------------------------------
# `em_fit_phylo` (in `em_phylo.jl`) converges to the dense MLE but, like every
# plain EM, crawls along a slow linear tail near the optimum — thousands of
# iterations at p = 100–500. SQUAREM (Varadhan & Roland 2008, Scand. J. Statist.
# 35: 335–353) is a deterministic *squared-extrapolation* accelerator for ANY
# EM map G: θ ↦ G(θ). It needs ONLY the update map — no gradients, no Hessian,
# no model change — and keeps the SAME fixed point (hence the same MLE), while
# typically cutting the iteration count 3–10×.
#
# One SQUAREM (order-3, "S3") step, given the current θ0:
#       θ1 = G(θ0)
#       θ2 = G(θ1)
#       r  = θ1 − θ0
#       v  = (θ2 − θ1) − r          # = θ2 − 2θ1 + θ0
#       α  = −‖r‖ / ‖v‖             # the SqS3 steplength
#       θ' = θ0 − 2α r + α² v
#       θ_new = G(θ')               # one stabilising EM step
# The stabilising EM step restores the EM monotonicity/feasibility guarantees
# the raw extrapolation can break. We additionally GLOBALISE with backtracking:
# if the candidate θ_new lowers the marginal log-lik (vs. the plain-EM value at
# θ2) or leaves the domain (σ²_eps must stay > 0), we halve the distance of α
# from the safe value −1 and retry; α = −1 reduces SQUAREM to two plain EM
# steps, so the fallback can never do worse than plain EM. This is exactly the
# Varadhan–Roland recommendation (their §6: project α back toward −1).
#
# ---------------------------------------------------------------------------
# How it wraps em_phylo.jl
# ---------------------------------------------------------------------------
# The EM map of `em_phylo.jl` is `_mstep_dense ∘ _estep_dense`: one E-step
# (closed-form Gaussian posterior) followed by one M-step (per-trait WLS +
# residual-trace σ²_eps). We DO NOT modify `em_phylo.jl`; we `include` it and
# build the one-step closure here. The parameter is packed as a flat vector
# θ = [vec(Λ_B); σ_eps; σ_phy] so the SQUAREM vector algebra (r, v, norms) is
# trivial. The log-lik is scored with the SAME dense closed form
# (`GLLVM.gaussian_marginal_loglik`) the plain EM and the gradient fit use, so
# the trajectories are directly comparable.
#
# New file only — not wired into the GLLVM module (mirrors the em_phylo.jl
# convention). `include` this file AFTER the GLLVM module is loaded; it pulls
# in `em_phylo.jl` itself (guarded so a double-include is harmless).

if !isdefined(@__MODULE__, :_estep_dense)
    include(joinpath(@__DIR__, "em_phylo.jl"))
end

using LinearAlgebra
using Statistics

# ---------------------------------------------------------------------------
# Pack / unpack and the one-step EM map as a closure over the flat parameter.
# ---------------------------------------------------------------------------

# θ = [vec(Λ_B) (p·K_B); σ_eps (1); σ_phy (p)]
@inline _pack_phylo(Λ_B::AbstractMatrix, σ_eps::Real, σ_phy::AbstractVector) =
    vcat(vec(Λ_B), float(σ_eps), Vector{Float64}(σ_phy))

@inline function _unpack_phylo(θ::AbstractVector, p::Integer, K_B::Integer)
    Λ_B   = reshape(θ[1:(p * K_B)], p, K_B)
    σ_eps = θ[p * K_B + 1]
    σ_phy = θ[(p * K_B + 2):end]
    return Λ_B, σ_eps, σ_phy
end

# Domain guard: σ_eps must be a positive real (the M-step floors σ²_eps at eps()
# so a finite map output is always in-domain; this catches NaN/Inf/≤0 that a raw
# extrapolation θ' could produce before the stabilising EM step).
@inline _phylo_in_domain(θ::AbstractVector, p::Integer, K_B::Integer) = begin
    σ_eps = θ[p * K_B + 1]
    all(isfinite, θ) && isfinite(σ_eps) && σ_eps > 0
end

"""
    _em_map_phylo(θ, y, Σ_phy, p, K_B) -> θ'

One plain-EM update (E-step then M-step) of `em_phylo.jl`, on the packed
parameter `θ = [vec(Λ_B); σ_eps; σ_phy]`. This is the map G whose fixed point
is the (dense) MLE; SQUAREM accelerates iteration of exactly this map.
"""
function _em_map_phylo(θ::AbstractVector, y::AbstractMatrix,
                       Σ_phy::AbstractMatrix, p::Integer, K_B::Integer)
    Λ_B, σ_eps, σ_phy = _unpack_phylo(θ, p, K_B)
    ss = _estep_dense(y, Λ_B, σ_eps, σ_phy, Σ_phy)
    Λ_B′, σ_eps′, σ_phy′ = _mstep_dense(y, ss)
    return _pack_phylo(Λ_B′, σ_eps′, σ_phy′)
end

@inline function _loglik_phylo(θ::AbstractVector, y::AbstractMatrix,
                               Σ_phy::AbstractMatrix, p::Integer, K_B::Integer)
    Λ_B, σ_eps, σ_phy = _unpack_phylo(θ, p, K_B)
    return GLLVM.gaussian_marginal_loglik(y, Λ_B, σ_eps; σ_phy = σ_phy,
                                          Σ_phy = Σ_phy)
end

# ---------------------------------------------------------------------------
# SQUAREM driver
# ---------------------------------------------------------------------------

"""
    em_fit_phylo_squarem(y, K_B, Σ_phy;
                         λ_init=nothing, σ_eps_init=nothing, σ_phy_init=nothing,
                         tol=1e-9, max_iter=1000, max_backtrack=20,
                         assert_monotone=true) -> EMPhyloFit

SQUAREM-accelerated version of `em_fit_phylo` (`em_phylo.jl`). Identical model,
identical warm start, identical convergence criterion (|Δ log-lik| < `tol`) and
identical dense log-lik scoring — only the iteration is accelerated by Varadhan
& Roland's (2008) order-3 squared extrapolation with a stabilising EM step and
steplength backtracking toward the safe value α = −1.

Returns the same `EMPhyloFit` struct as `em_fit_phylo`; `n_iter` counts SQUAREM
*cycles* (each cycle invokes the EM map three times: θ1, θ2, and the stabilising
step). The fixed point is the SAME as plain EM, so the MLE is unchanged — this
is verified against `em_fit_phylo` in `test/test_em_squarem.jl`.

Each SQUAREM cycle is guaranteed to be no worse than two plain-EM steps: when
the extrapolation would lower the log-lik or leave the domain, α is repeatedly
moved halfway toward −1, and α = −1 makes θ' = θ2 (two EM steps) exactly.
"""
function em_fit_phylo_squarem(y::AbstractMatrix, K_B::Integer,
                              Σ_phy::AbstractMatrix;
                              λ_init = nothing, σ_eps_init = nothing,
                              σ_phy_init = nothing,
                              tol = 1e-9, max_iter = 1000, max_backtrack = 20,
                              assert_monotone = true)
    p, n = size(y)
    K_B ≥ 1 || throw(ArgumentError("K_B must be ≥ 1"))
    K_B < p || throw(ArgumentError("EM requires K_B < p; got K_B=$K_B, p=$p"))
    size(Σ_phy) == (p, p) ||
        throw(ArgumentError("Σ_phy must be p × p; got $(size(Σ_phy)) for p=$p"))

    yf = Matrix{Float64}(y)

    # ----- Warm start: IDENTICAL to em_fit_phylo (PPCA Λ_B, σ_eps; phylo SD
    #       from the marginal scale) so the two fitters start from one point. --
    if λ_init === nothing || σ_eps_init === nothing
        Λ0, σ0 = GLLVM.ppca_init(yf, K_B)
        Λ_B   = λ_init === nothing ? Matrix{Float64}(Λ0) : Matrix{Float64}(λ_init)
        σ_eps = σ_eps_init === nothing ? float(σ0) : float(σ_eps_init)
    else
        Λ_B   = Matrix{Float64}(λ_init)
        σ_eps = float(σ_eps_init)
    end
    σ_phy = if σ_phy_init === nothing
        fill(0.1 * sqrt(mean(abs2, yf)), p)
    else
        Vector{Float64}(σ_phy_init)
    end

    θ = _pack_phylo(Λ_B, σ_eps, σ_phy)

    loglik_trace = Float64[]
    converged    = false
    cycles_run   = 0

    # Score and record the starting point (matches em_fit_phylo's first trace
    # entry: the log-lik at the warm-start parameters).
    ll_prev = _loglik_phylo(θ, yf, Σ_phy, p, K_B)
    push!(loglik_trace, ll_prev)

    for cycle in 1:max_iter
        cycles_run = cycle

        # --- two base EM steps -------------------------------------------------
        θ1 = _em_map_phylo(θ,  yf, Σ_phy, p, K_B)
        θ2 = _em_map_phylo(θ1, yf, Σ_phy, p, K_B)
        ll2 = _loglik_phylo(θ2, yf, Σ_phy, p, K_B)   # plain-EM log-lik this cycle

        # --- SQUAREM (order-3) extrapolation ----------------------------------
        r = θ1 .- θ
        v = (θ2 .- θ1) .- r                          # = θ2 − 2θ1 + θ0
        rn = norm(r)
        vn = norm(v)

        if vn < eps() || rn < eps()
            # No curvature / no movement: the two EM steps are the whole update.
            θ_cand = θ2
            ll_cand = ll2
        else
            α0 = -rn / vn                            # SqS3 steplength (≤ −1)
            α  = min(α0, -1.0)                       # never extrapolate "inward"
            θ_cand = θ2
            ll_cand = ll2
            # Backtrack α halfway toward −1 until the stabilised candidate is
            # in-domain AND does not lower the log-lik below the plain-EM value.
            for _ in 0:max_backtrack
                θ′ = θ .- (2α) .* r .+ (α^2) .* v    # squared extrapolation
                if _phylo_in_domain(θ′, p, K_B)
                    θ_new = _em_map_phylo(θ′, yf, Σ_phy, p, K_B)  # stabilising EM
                    ll_new = _loglik_phylo(θ_new, yf, Σ_phy, p, K_B)
                    if isfinite(ll_new) && ll_new ≥ ll2 - 1e-9
                        θ_cand  = θ_new
                        ll_cand = ll_new
                        break
                    end
                end
                α ≈ -1.0 && break                    # already at the safe value
                α = (α - 1.0) / 2                     # move halfway toward −1
                if α > -1.0                           # don't overshoot past −1
                    α = -1.0
                end
            end
        end

        ll = ll_cand
        push!(loglik_trace, ll)

        inc = ll - ll_prev
        if assert_monotone && inc < -1e-7
            error("SQUAREM-EM log-lik decreased by $(abs(inc)) at cycle " *
                  "$cycle (was $ll_prev, now $ll) — monotonicity violated.")
        end

        θ = θ_cand
        if abs(inc) < tol
            converged = true
            break
        end
        ll_prev = ll
    end

    Λ_B, σ_eps, σ_phy = _unpack_phylo(θ, p, K_B)

    # Refresh the ancestral-state BLUPs at the converged parameters.
    ss = _estep_dense(yf, Λ_B, σ_eps, σ_phy, Σ_phy)
    blup_phy = copy(ss.μ_z)
    blup_phi = copy(ss.μ_φ)

    ll_final = GLLVM.gaussian_marginal_loglik(yf, Λ_B, σ_eps;
                                              σ_phy = σ_phy, Σ_phy = Σ_phy)
    if !isempty(loglik_trace) && ll_final > loglik_trace[end]
        push!(loglik_trace, ll_final)
    end

    # Global φ-orientation convention (IDENTICAL to em_fit_phylo): anchor the
    # sign so the dominant-magnitude trait's σ_phy is ≥ 0. Flipping ALL σ_phy
    # signs leaves every B[t,t'] = σ_phy[t] σ_phy[t'] Σ_phy[t,t'] unchanged.
    t_anchor = argmax(abs.(σ_phy))
    if σ_phy[t_anchor] < 0
        σ_phy = -σ_phy
        blup_phi = -blup_phi
    end

    return EMPhyloFit(Matrix{Float64}(Λ_B), σ_eps, Vector{Float64}(σ_phy),
                      ll_final, cycles_run, converged, loglik_trace,
                      blup_phy, blup_phi)
end
