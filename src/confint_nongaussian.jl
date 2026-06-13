# Wald confidence intervals for non-Gaussian (Laplace) GLLVM fits, from the
# observed-information Hessian of the marginal negative log-likelihood. The
# Hessian is the ForwardDiff Hessian of the Laplace marginal — verified to be
# positive-definite and to match a central finite-difference Hessian to FD
# precision (~1e-4). This mirrors the Gaussian `confint` Wald path; the only
# difference is the family-specific reconstruction of `θ̂` and the marginal NLL.
#
# Currently implemented for the Poisson family (θ = [β; pack_lambda(Λ)], all
# identity-scale parameters, no dispersion). Other one-part families follow the
# same pattern — reconstruct their packed θ and marginal NLL, mark any
# log-scale dispersion parameter with kind `:log_sd`, then call
# `_wald_ci_from_nll`.

# Generic Wald construction shared across non-Gaussian families. Given the packed
# MLE `θ̂`, a `θ -> NLL` closure, term names, and per-term back-transform `kinds`,
# returns Wald CIs from the observed-information Hessian. `kind = :log_sd`
# back-transforms via `exp` (positive parameters stored on the log scale); any
# other kind is treated as identity-scale.
function _wald_ci_from_nll(θ̂::AbstractVector, nll, terms::Vector{String},
                           kinds::Vector{Symbol}; level::Real = 0.95, parm = nothing)
    n_par = length(θ̂)
    length(terms) == n_par || error(
        "Internal: term-name length ($(length(terms))) does not match n_par ($n_par).")
    length(kinds) == n_par || error(
        "Internal: kinds length ($(length(kinds))) does not match n_par ($n_par).")

    H = nothing
    pd = true
    try
        H = ForwardDiff.hessian(nll, θ̂)
    catch
        H = nothing
        pd = false
    end

    se_all = fill(NaN, n_par)
    if H !== nothing && all(isfinite, H)
        Σ = nothing
        try
            Hsym = (H .+ H') ./ 2
            Σ = inv(Hsym)
        catch
            Σ = nothing
            pd = false
        end
        if Σ !== nothing
            dΣ = diag(Σ)
            for i in 1:n_par
                v = dΣ[i]
                if isfinite(v) && v > 0
                    se_all[i] = sqrt(v)
                else
                    pd = false
                end
            end
        end
    else
        pd = false
    end

    sel = _confint_select_indices(parm, terms)
    isempty(sel) && throw(ArgumentError("parm selector matched no parameters"))
    z = quantile(Normal(), 0.5 + level / 2)

    term_out = String[]; est_out = Float64[]; lo_out = Float64[]; hi_out = Float64[]; se_out = Float64[]
    for i in sel
        push!(term_out, terms[i])
        push!(se_out, se_all[i])
        θi  = θ̂[i]
        sei = se_all[i]
        if kinds[i] === :log_sd
            push!(est_out, exp(θi))
            if isfinite(sei)
                push!(lo_out, exp(θi - z * sei)); push!(hi_out, exp(θi + z * sei))
            else
                push!(lo_out, NaN); push!(hi_out, NaN)
            end
        else
            push!(est_out, θi)
            if isfinite(sei)
                push!(lo_out, θi - z * sei); push!(hi_out, θi + z * sei)
            else
                push!(lo_out, NaN); push!(hi_out, NaN)
            end
        end
    end
    return (term = term_out, estimate = est_out, lower = lo_out, upper = hi_out,
            se = se_out, pd_hessian = pd)
end

"""
    confint(fit::PoissonFit; y, level=0.95, parm=nothing)

Wald confidence intervals for a Poisson GLLVM fit, from the observed-information
Hessian (the ForwardDiff Hessian of the Laplace marginal). `y` is the same `p×n`
count matrix passed to [`fit_poisson_gllvm`](@ref). Parameters are the per-species
intercepts `beta[t]` and the packed loadings `lambda[i]` (all identity-scale).
`parm` selects a subset by name/regex, as in the Gaussian `confint`.

Returns a named tuple `(term, estimate, lower, upper, se, pd_hessian)`.
`pd_hessian = false` means the observed information was not positive definite
(SEs are `NaN`); prefer the parametric bootstrap there.
"""
function confint(fit::PoissonFit; y::AbstractMatrix, level::Real = 0.95, parm = nothing)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1); got $level"))
    p, K = size(fit.Λ)
    rr   = rr_theta_len(p, K)
    θ̂    = vcat(fit.β, pack_lambda(fit.Λ))
    terms = vcat(["beta[$t]" for t in 1:p], ["lambda[$i]" for i in 1:rr])
    kinds = fill(:identity, length(terms))
    nll = θ -> -poisson_marginal_loglik_laplace(
        y, unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p], fit.link)
    # Convenience group selectors: "beta"/"lambda" select the whole block (the
    # shared selector otherwise only matches exact term names).
    if parm === :beta || parm == "beta"
        parm = ["beta[$t]" for t in 1:p]
    elseif parm === :lambda || parm == "lambda"
        parm = ["lambda[$i]" for i in 1:rr]
    end
    return _wald_ci_from_nll(θ̂, nll, terms, kinds; level = level, parm = parm)
end

"""
    confint(fit::BinomialFit; y, N=nothing, level=0.95, parm=nothing)

Wald CIs for a Binomial GLLVM fit, as for [`confint(::PoissonFit)`](@ref). `y` is
the `p×n` response matrix and `N` the trials matrix (defaults to all-ones, i.e.
Bernoulli/binary data). Same observed-information construction.
"""
function confint(fit::BinomialFit; y::AbstractMatrix, N = nothing,
                 level::Real = 0.95, parm = nothing)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1); got $level"))
    p, K = size(fit.Λ)
    rr   = rr_theta_len(p, K)
    Nm   = N === nothing ? fill(1, size(y)) : N
    θ̂    = vcat(fit.β, pack_lambda(fit.Λ))
    terms = vcat(["beta[$t]" for t in 1:p], ["lambda[$i]" for i in 1:rr])
    kinds = fill(:identity, length(terms))
    nll = θ -> -binomial_marginal_loglik_laplace(
        y, Nm, unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p], fit.link)
    if parm === :beta || parm == "beta"
        parm = ["beta[$t]" for t in 1:p]
    elseif parm === :lambda || parm == "lambda"
        parm = ["lambda[$i]" for i in 1:rr]
    end
    return _wald_ci_from_nll(θ̂, nll, terms, kinds; level = level, parm = parm)
end

"""
    confint(fit::NBFit; y, level=0.95, parm=nothing)

Wald CIs for a Negative-Binomial GLLVM fit. As for [`confint(::PoissonFit)`](@ref),
plus the dispersion `r`: its packed parameter is `log r`, so the `r` interval is
reported on the natural (positive) scale via the `:log_sd` back-transform.
"""
function confint(fit::NBFit; y::AbstractMatrix, level::Real = 0.95, parm = nothing)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1); got $level"))
    p, K = size(fit.Λ)
    rr   = rr_theta_len(p, K)
    θ̂    = vcat(fit.β, pack_lambda(fit.Λ), log(fit.r))
    terms = vcat(["beta[$t]" for t in 1:p], ["lambda[$i]" for i in 1:rr], ["r"])
    kinds = vcat(fill(:identity, p + rr), [:log_sd])
    nll = θ -> -nb_marginal_loglik_laplace(
        y, unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
        exp(θ[p + rr + 1]); link = fit.link)
    if parm === :beta || parm == "beta"
        parm = ["beta[$t]" for t in 1:p]
    elseif parm === :lambda || parm == "lambda"
        parm = ["lambda[$i]" for i in 1:rr]
    end
    return _wald_ci_from_nll(θ̂, nll, terms, kinds; level = level, parm = parm)
end
