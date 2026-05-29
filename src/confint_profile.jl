# Profile-likelihood confidence intervals for the Gaussian GLLVM.
#
# This is a NEW file added alongside the PERF overhaul of src/likelihood.jl
# and src/fit.jl, and the sibling Wald CI implementation in src/confint.jl.
# It deliberately does not touch those files.
#
# For parameter θ_i with MLE θ̂_i and full log-likelihood ℓ̂,
# the profile log-lik at candidate value c is
#     ℓ_p(c) = max_{θ_{-i}} ℓ(c, θ_{-i}),
# i.e., re-optimise over the remaining parameters with θ_i fixed.
# The deviance D(c) = 2(ℓ̂ − ℓ_p(c)) is ~ χ²_1 under the null θ_i = c.
# The 100(1−α)% profile CI is {c : D(c) ≤ qchisq(1−α, df=1)}.
#
# Why profile CIs:
#   For the ADEMP coverage simulation, Wald CIs have poor coverage when
#   σ_eps or σ_phy is near zero (boundary), the likelihood is asymmetric
#   (common for ratios like ICC, H²), or the fit is near-singular.
#   Profile CIs invert the LRT directly — wider tail support, better
#   coverage at boundaries.
#
# Loading model: this file is loaded by the verify command via
#
#     julia --project=. -e 'using GLLVM; include("src/confint_profile.jl"); ...'
#
# We deliberately do NOT modify src/GLLVM.jl (hard constraint). To make
# `GLLVM.profile_ci(...)` callable from the test file, the definitions
# below are injected directly into the `GLLVM` module via Core.eval on
# a single quote block, matching the pattern used by src/confint.jl.
#
# Algorithm:
#   1. Build the full negative log-likelihood closure as a function of the
#      legacy-layout θ_packed vector (same NLL used by confint.jl).
#   2. Compute Wald SEs at the MLE via ForwardDiff.hessian. Used only to
#      seed the initial bracket — the SE doesn't enter the final answer.
#   3. For each side (lower and upper) of θ̂_i, expand c outward in steps
#      of grid_extent·SE/n_steps until the deviance D(c) crosses the
#      chisq cutoff. At each candidate c we re-optimise over θ_{-i} via
#      LBFGS (warm-started from the previous solution) and compute
#      D(c) = 2(ℓ̂ − ℓ_p(c)).
#   4. Bisect inside the bracket to locate the threshold crossing to
#      tolerance tol.
#
# The result on log-SD-style parameters (σ_eps, σ_B, σ_W, σ_phy) is
# converted to the raw scale via exp(.) to match the convention of
# src/confint.jl: bounds are reported on the natural (positive) scale.
#
# Constrained-refit mechanics: Optim.jl has no first-class
# "hold parameter k fixed" interface, so we instead define a closure
# over a reduced parameter vector θ_red ∈ R^{N-1} that inserts the
# fixed value c at index i to form θ_full ∈ R^N before calling
# gaussian_nll_packed. This is the standard Julia idiom and keeps
# ForwardDiff happy (the closure is differentiable in θ_red).
#
# Required for the ADEMP simulation:
#   docs/please-have-a-robust-elephant.md
# Active plan:
#   ~/.claude/plans/please-have-a-robust-elephant.md

Core.eval(GLLVM, quote

using ForwardDiff
using Distributions: Chisq, quantile
using LinearAlgebra
using Optim

# Build the lambda part of the term-name list in pack_lambda order.
# Diagonals (k = 1..K) first, then strict-lower entries column-by-column.
# Mirrors `pack_lambda` / `unpack_lambda` in src/packing.jl.
function _profile_lambda_term_names(prefix::String, p::Integer, K::Integer)
    out = String[]
    for k in 1:K
        push!(out, "$(prefix)[$k,$k]")
    end
    for k in 1:K
        for i in (k + 1):p
            push!(out, "$(prefix)[$i,$k]")
        end
    end
    return out
end

# Build the canonical term-name + kind vectors matching the legacy
# θ_packed layout, identical to the sister Wald confint.jl.
#
#     [β[1..q]; sigma_eps;
#      sigma_B[1..p]; sigma_W[1..p]      (if has_diag)
#      Lambda_B[i,k]                      (pack_lambda order)
#      Lambda_W[i,k]                      (if K_W > 0)
#      sigma_phy[1..p]                    (if has_phy_unique)
#      Lambda_phy[i,k]                    (if K_phy > 0)]
#
# kinds[i] ∈ {:linear, :log_sd} drives the raw-vs-working transform.
function _profile_all_term_names(fit::GllvmFit)
    model = fit.model
    p     = model.p
    K_B   = model.K
    K_W   = model.K_W
    has_diag = model.has_diag
    K_phy    = model.K_phy
    has_phy_unique = model.has_phy_unique
    q = fit.pars.β === nothing ? 0 : length(fit.pars.β)

    terms = String[]
    kinds = Symbol[]

    for j in 1:q
        push!(terms, "beta[$j]")
        push!(kinds, :linear)
    end

    push!(terms, "sigma_eps")
    push!(kinds, :log_sd)

    if has_diag
        for t in 1:p
            push!(terms, "sigma_B[$t]")
            push!(kinds, :log_sd)
        end
        for t in 1:p
            push!(terms, "sigma_W[$t]")
            push!(kinds, :log_sd)
        end
    end

    for nm in _profile_lambda_term_names("Lambda_B", p, K_B)
        push!(terms, nm)
        push!(kinds, :linear)
    end

    if K_W > 0
        for nm in _profile_lambda_term_names("Lambda_W", p, K_W)
            push!(terms, nm)
            push!(kinds, :linear)
        end
    end

    if has_phy_unique
        for t in 1:p
            push!(terms, "sigma_phy[$t]")
            push!(kinds, :log_sd)
        end
    end

    if K_phy > 0
        for nm in _profile_lambda_term_names("Lambda_phy", p, K_phy)
            push!(terms, nm)
            push!(kinds, :linear)
        end
    end

    return terms, kinds
end

# Resolve a parm name (matching the confint() naming convention) to
# the integer index into θ_packed.
function _profile_parm_index(fit::GllvmFit, parm::AbstractString)
    terms, _ = _profile_all_term_names(fit)
    selector = String(parm)
    idx = findfirst(==(selector), terms)
    if !isnothing(idx)
        return idx
    end
    if startswith(selector, "Lambda:")
        return _profile_parm_index(fit, "Lambda_B[" * selector[length("Lambda:") + 1:end] * "]")
    end
    for prefix in ("Lambda_B:", "Lambda_W:", "Lambda_phy:")
        if startswith(selector, prefix)
            base = prefix[1:end-1]
            return _profile_parm_index(fit, "$(base)[" * selector[length(prefix) + 1:end] * "]")
        end
    end
    throw(ArgumentError(
        "Could not resolve parm selector \"$selector\" to a single θ_packed index. " *
        "Use one of the names returned by confint(fit).term."))
end

# Build the spec NamedTuple used by gaussian_nll_packed.
function _profile_spec(fit::GllvmFit)
    model = fit.model
    q = fit.pars.β === nothing ? 0 : length(fit.pars.β)
    return (q = q, p = model.p, K_B = model.K, K_W = model.K_W,
            has_diag = model.has_diag, K_phy = model.K_phy,
            has_phy_unique = model.has_phy_unique)
end

# Wald SE at θ̂_i via the observed information matrix. Returns NaN if
# the Hessian is non-finite or the i-th diagonal of inv(H) is ≤ 0.
function _profile_wald_se(fit::GllvmFit, i::Integer,
                          y::AbstractMatrix,
                          X::Union{Nothing, AbstractArray{<:Real, 3}},
                          Σ_phy::Union{Nothing, AbstractMatrix})
    spec = _profile_spec(fit)
    θ̂ = fit.pars.θ_packed
    nll = θ -> gaussian_nll_packed(θ, y; spec = spec, X = X, Σ_phy = Σ_phy)
    H = try
        ForwardDiff.hessian(nll, θ̂)
    catch
        return NaN
    end
    if !all(isfinite, H)
        return NaN
    end
    Σ_inv = try
        inv((H .+ H') ./ 2)
    catch
        return NaN
    end
    v = diag(Σ_inv)[i]
    return (isfinite(v) && v > 0) ? sqrt(v) : NaN
end

# Constrained refit: re-optimise the NLL over θ_{-i} with θ_i fixed at c.
# Returns (ll_profile::Float64, success::Bool). On optimisation failure
# returns (NaN, false).
#
# Mechanics — how we "fix" a parameter for Optim:
#   Optim has no first-class held-constant interface, so we wrap the NLL
#   in a closure that maps a reduced (N-1)-vector θ_red to the full
#   N-vector by inserting c at index i, then evaluates gaussian_nll_packed
#   on the full vector. ForwardDiff differentiates through the insertion
#   because it's just an indexing/concat operation.
function _profile_refit_with_fixed(fit::GllvmFit, i::Integer, c::Real,
                                   y::AbstractMatrix,
                                   X::Union{Nothing, AbstractArray{<:Real, 3}},
                                   Σ_phy::Union{Nothing, AbstractMatrix};
                                   θ_red_warm::Union{Nothing, AbstractVector} = nothing,
                                   x_tol::Real = 1e-6,
                                   f_tol::Real = 1e-8,
                                   g_tol::Real = 1e-4,
                                   iterations::Integer = 200)
    spec = _profile_spec(fit)
    θ̂ = fit.pars.θ_packed
    N = length(θ̂)
    1 ≤ i ≤ N || throw(ArgumentError("param_index $i out of range 1:$N"))

    # Reduced warm-start: drop index i.
    θ_red0 = if θ_red_warm === nothing
        vcat(θ̂[1:(i - 1)], θ̂[(i + 1):N])
    else
        collect(Float64, θ_red_warm)
    end

    function _full_from_red(θ_red, c_val)
        # Insert c_val at position i. Preserve eltype for AD.
        T = promote_type(eltype(θ_red), typeof(c_val))
        θ_full = Vector{T}(undef, N)
        @inbounds for j in 1:(i - 1)
            θ_full[j] = θ_red[j]
        end
        θ_full[i] = c_val
        @inbounds for j in (i + 1):N
            θ_full[j] = θ_red[j - 1]
        end
        return θ_full
    end

    c_float = float(c)
    nll_red = θ_red -> gaussian_nll_packed(_full_from_red(θ_red, c_float), y;
                                           spec = spec, X = X, Σ_phy = Σ_phy)

    opts = Optim.Options(
        x_abstol = x_tol,
        f_reltol = f_tol,
        g_tol    = g_tol,
        iterations = iterations,
        show_trace = false,
    )

    res = try
        Optim.optimize(nll_red, θ_red0, Optim.LBFGS(), opts; autodiff = :forward)
    catch
        return (NaN, false, θ_red0)
    end

    nll_min = Optim.minimum(res)
    if !isfinite(nll_min)
        return (NaN, false, θ_red0)
    end
    return (-nll_min, true, Optim.minimizer(res))
end

# Bracket-then-bisect on one side (lower if Δ_init < 0, upper if > 0).
#
# We walk outward from x0 = θ̂_i in steps of step_init until the deviance
# D(c) crosses cutoff or we exhaust max_iter expansions. On bracket
# failure we return NaN (the bracket simply isn't reached within
# max_iter * step_init of the MLE).
#
# Inside a successful bracket, we bisect to locate D(c) = cutoff with
# absolute tolerance tol_x in the parameter and fall-back stop on tol_D
# in the deviance.
function _profile_bisect_side(D::Function, x0::Real, step_init::Real,
                              cutoff::Real;
                              max_expand::Integer = 20,
                              max_bisect::Integer = 30,
                              tol_x::Real = 1e-4,
                              tol_D::Real = 1e-3)
    sign_step = sign(step_init)
    sign_step == 0 && return NaN
    abs_step = abs(step_init)

    # Expansion phase: find x_out such that D(x_out) ≥ cutoff while
    # D(x_in) < cutoff. x_in starts at x0 (where D ≈ 0).
    x_in = float(x0)
    D_in = 0.0  # D(θ̂_i) = 0 by construction
    x_out = x_in + sign_step * abs_step
    D_out = NaN
    found_bracket = false
    for k in 1:max_expand
        D_val = D(x_out)
        if !isfinite(D_val)
            # Refit failed at this candidate. Treat as having crossed
            # (bracket the singular region) but also tighten the bracket
            # towards the last successful x_in. Conservatively, set
            # D_out to a "high" sentinel so bisection contracts in.
            D_out = Inf
            found_bracket = true
            break
        end
        if D_val ≥ cutoff
            D_out = D_val
            found_bracket = true
            break
        end
        # Still below cutoff — advance x_in to here and step further out.
        x_in = x_out
        D_in = D_val
        # Geometric expansion: each step doubles. This keeps the worst
        # case at O(log) refits even for very wide intervals.
        abs_step *= 2
        x_out = x_in + sign_step * abs_step
    end
    found_bracket || return NaN

    # Bisection: shrink the bracket [x_in, x_out] until |x_out - x_in| < tol_x.
    lo, hi = x_in, x_out
    D_lo, D_hi = D_in, D_out
    for _ in 1:max_bisect
        mid = (lo + hi) / 2
        D_mid = D(mid)
        if !isfinite(D_mid)
            # If refit fails, step the bracket conservatively inward
            # by half from the failing side, treating the failing region
            # as outside the CI.
            if sign_step > 0
                hi = mid
                D_hi = Inf
            else
                hi = mid
                D_hi = Inf
            end
        elseif D_mid ≥ cutoff
            hi = mid
            D_hi = D_mid
        else
            lo = mid
            D_lo = D_mid
        end
        if abs(hi - lo) < tol_x
            break
        end
        if isfinite(D_hi) && abs(D_hi - cutoff) < tol_D &&
           isfinite(D_lo) && abs(D_lo - cutoff) < tol_D
            break
        end
    end
    return (lo + hi) / 2
end

"""
    profile_ci(fit::GllvmFit, param_index::Integer;
               level = 0.95, grid_extent = 5, max_expand = 20,
               max_bisect = 30, y = nothing, X = nothing,
               Σ_phy = nothing)
        -> NamedTuple{(:lower, :upper, :method)}

Profile-likelihood CI for the parameter at packed position `param_index`
in `fit.pars.θ_packed`.

`grid_extent` controls how far (in Wald SEs from θ̂_i, geometrically
expanding) the initial bracket walks before bisection. Larger values
help for asymmetric likelihoods; the geometric expansion keeps the
total number of refits at O(log) even at large `grid_extent`.

`level` is the nominal coverage (default 0.95 → χ²_1 cutoff ≈ 3.841).

The data matrix `y` (the same `y` passed to `fit_gaussian_gllvm`) must
be supplied so this function can reconstruct the NLL closure. `X` and
`Σ_phy` are required iff the fit used them.

Returns a NamedTuple with fields:
  - `lower::Float64` — lower CI bound on the raw scale for SD-style
    parameters (σ_eps, σ_B, σ_W, σ_phy), native scale for β / Λ.
  - `upper::Float64` — upper CI bound, same scale convention.
  - `method::Symbol` — `:profile` if both bounds were bracketed,
    `:partial` if only one side was found (the other is NaN), or
    `:failed` if neither side could be bracketed (both NaN).

Failure modes (each side independently):
  - The bracket never crosses the chisq cutoff within
    `max_expand` geometric expansions → that bound is `NaN`.
  - A constrained refit at a candidate value fails → bracket contracts
    inward on that side, still typically yielding a finite bound.
"""
function profile_ci(fit::GllvmFit, param_index::Integer;
                    level::Real = 0.95,
                    grid_extent::Real = 5,
                    max_expand::Integer = 20,
                    max_bisect::Integer = 30,
                    y::Union{Nothing, AbstractMatrix} = nothing,
                    X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing,
                    Σ_phy::Union{Nothing, AbstractMatrix} = nothing)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1); got $level"))
    y === nothing && throw(ArgumentError(
        "profile_ci requires the data matrix `y` (the same matrix passed to fit_gaussian_gllvm)"))

    θ̂ = fit.pars.θ_packed
    N = length(θ̂)
    1 ≤ param_index ≤ N ||
        throw(ArgumentError("param_index $param_index out of range 1:$N"))

    cutoff = quantile(Chisq(1), level)
    θ̂_i = float(θ̂[param_index])
    ll_full = fit.logLik

    # Wald SE on the working scale; fall back to a heuristic if non-PD.
    se_i = _profile_wald_se(fit, param_index, y, X, Σ_phy)
    if isnan(se_i) || se_i ≤ 0
        se_i = max(abs(θ̂_i) / 2, 0.1)
    end

    # Warm-start cache for the constrained refits. Re-using the previous
    # θ_red on each step typically cuts LBFGS iterations to ~5–15 because
    # the constrained MLE is a smooth function of c.
    θ_red_warm_lower = vcat(θ̂[1:(param_index - 1)], θ̂[(param_index + 1):N])
    θ_red_warm_upper = copy(θ_red_warm_lower)

    function deviance_lower(c)
        ll_c, ok, θ_red_new = _profile_refit_with_fixed(
            fit, param_index, c, y, X, Σ_phy;
            θ_red_warm = θ_red_warm_lower)
        if ok
            # Update warm-start in the enclosing scope for the next call.
            θ_red_warm_lower = θ_red_new
            return 2.0 * (ll_full - ll_c)
        else
            return NaN
        end
    end
    function deviance_upper(c)
        ll_c, ok, θ_red_new = _profile_refit_with_fixed(
            fit, param_index, c, y, X, Σ_phy;
            θ_red_warm = θ_red_warm_upper)
        if ok
            θ_red_warm_upper = θ_red_new
            return 2.0 * (ll_full - ll_c)
        else
            return NaN
        end
    end

    # Initial step: one Wald SE in each direction. Geometric expansion
    # inside _profile_bisect_side handles the rest.
    step_init = max(grid_extent * se_i / max_expand, 1e-3)

    lower = _profile_bisect_side(deviance_lower, θ̂_i, -step_init, cutoff;
                                 max_expand = max_expand,
                                 max_bisect = max_bisect)
    upper = _profile_bisect_side(deviance_upper, θ̂_i,  step_init, cutoff;
                                 max_expand = max_expand,
                                 max_bisect = max_bisect)

    # Raw-scale conversion for log-SD parameters (σ_eps etc.).
    _, kinds = _profile_all_term_names(fit)
    if kinds[param_index] === :log_sd
        lower = isnan(lower) ? NaN : exp(lower)
        upper = isnan(upper) ? NaN : exp(upper)
    end

    method = if isnan(lower) && isnan(upper)
        :failed
    elseif isnan(lower) || isnan(upper)
        :partial
    else
        :profile
    end
    return (lower = lower, upper = upper, method = method)
end

"""
    profile_ci(fit::GllvmFit, parm::AbstractString; kwargs...)
        -> NamedTuple{(:lower, :upper, :method)}

Convenience method that looks up `parm` by name (e.g., `"sigma_eps"`,
`"Lambda_B[1,1]"`, `"Lambda:1,1"`) and calls the integer-index method.

Naming convention matches `confint(fit)` from src/confint.jl: SDs are
reported on the raw (positive) scale, β and Λ on their native scale.
"""
function profile_ci(fit::GllvmFit, parm::AbstractString; kwargs...)
    idx = _profile_parm_index(fit, parm)
    return profile_ci(fit, idx; kwargs...)
end

function profile_ci(fit::GllvmFit, parm::Symbol; kwargs...)
    return profile_ci(fit, String(parm); kwargs...)
end

end) # Core.eval(GLLVM, quote ... end)
