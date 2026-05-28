# Optim.jl-driven L-BFGS minimisation of the Gaussian GLLVM marginal
# negative log-likelihood. Matches the R engine's initial values and
# convergence tolerances; the head-to-head benchmark depends on this.

"""
    GllvmModel(p, K)

Immutable spec describing a single-tier Gaussian GLLVM: p traits, K
latent factors, single-tier (no unit_obs / phylo) for MVP. Extended in
J2 (multi-tier) and J3 (phylogenetic).
"""
struct GllvmModel
    p::Int
    K::Int
end

"""
    GllvmFit

Result of `fit_gaussian_gllvm`. Holds the fitted parameters, the
converged log-likelihood, convergence info, and the raw Optim result.
"""
struct GllvmFit
    model::GllvmModel
    pars::NamedTuple
    logLik::Float64
    n_iter::Int
    converged::Bool
    optim_result
    cputime::Float64
end

"""
    fit_gaussian_gllvm(y; K, σ_eps_init=1.0, λ_init=nothing,
                        x_tol=1e-8, f_tol=1e-10, g_tol=1e-6,
                        iterations=500) -> GllvmFit

L-BFGS minimisation of the closed-form Gaussian marginal NLL via
ForwardDiff gradients. Returns a `GllvmFit` with parameter estimates,
convergence diagnostics, and wall-clock fit time.
"""
function fit_gaussian_gllvm(y::AbstractMatrix;
                            K::Integer,
                            σ_eps_init = 1.0,
                            λ_init = nothing,
                            x_tol = 1e-8,
                            f_tol = 1e-10,
                            g_tol = 1e-6,
                            iterations = 500)
    p, n = size(y)
    @assert K ≥ 1
    @assert n ≥ p "Need n_sites ≥ p for a well-posed Gaussian GLLVM"

    # Build initial parameter vector
    θ₀ = isnothing(λ_init) ? init_theta_rr(p, K) : pack_lambda(λ_init)
    params₀ = [log(σ_eps_init); θ₀]

    # Objective
    nll = params -> gaussian_nll_packed(params, y, p, K)

    # Optimise with ForwardDiff gradients (autodiff = :forward)
    opts = Optim.Options(
        x_abstol = x_tol,
        f_reltol = f_tol,
        g_tol    = g_tol,
        iterations = iterations,
        show_trace = false,
    )

    t0 = time()
    res = Optim.optimize(nll, params₀, Optim.LBFGS(), opts; autodiff = :forward)
    t1 = time()

    params_hat = Optim.minimizer(res)
    σ_eps_hat  = exp(params_hat[1])
    Λ_hat      = unpack_lambda(@view(params_hat[2:end]), p, K)
    nll_hat    = Optim.minimum(res)

    return GllvmFit(
        GllvmModel(p, K),
        (σ_eps = σ_eps_hat, Λ = Λ_hat, θ_packed = collect(params_hat)),
        -nll_hat,
        Optim.iterations(res),
        Optim.converged(res),
        res,
        t1 - t0,
    )
end
