# Optim.jl-driven L-BFGS minimisation of the Gaussian GLLVM marginal
# negative log-likelihood. Matches the R engine's initial values and
# convergence tolerances; the head-to-head benchmark depends on this.

"""
    GllvmModel(p, K; K_W=0, has_diag=false, K_phy=0, has_phy_unique=false)

Immutable spec describing a Gaussian GLLVM. `p` traits, `K` (= K_B)
unit-tier latent factors, plus optional W tier (`K_W`), per-trait
diagonal random effects (`has_diag`), and phylogenetic block
(`K_phy` axes of `Λ_phy` and/or per-trait `σ_phy` when
`has_phy_unique`). The single-tier J1 case is the default
`K_W = 0`, `has_diag = false`, `K_phy = 0`, `has_phy_unique = false`.
"""
struct GllvmModel
    p::Int
    K::Int          # K_B (unit-tier rank); name kept for backward compatibility
    K_W::Int
    has_diag::Bool
    K_phy::Int
    has_phy_unique::Bool
end

GllvmModel(p::Integer, K::Integer) = GllvmModel(Int(p), Int(K), 0, false, 0, false)
GllvmModel(p::Integer, K::Integer, K_W::Integer, has_diag::Bool) =
    GllvmModel(Int(p), Int(K), Int(K_W), has_diag, 0, false)
GllvmModel(p::Integer, K::Integer, K_W::Integer, has_diag::Bool,
           K_phy::Integer, has_phy_unique::Bool) =
    GllvmModel(Int(p), Int(K), Int(K_W), has_diag, Int(K_phy), has_phy_unique)

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
    fit_gaussian_gllvm(y; K, K_W=0, has_diag=false, K_phy=0,
                       has_phy_unique=false, Σ_phy=nothing, X=nothing,
                       σ_eps_init=1.0, λ_init=nothing, λ_W_init=nothing,
                       λ_phy_init=nothing,
                       σ²_B_init=0.1, σ²_W_init=0.1, σ_phy_init=0.1,
                       β_init=nothing, x_tol=1e-8, f_tol=1e-10,
                       g_tol=1e-6, iterations=500) -> GllvmFit

L-BFGS minimisation of the closed-form Gaussian marginal NLL via
ForwardDiff gradients. Returns a `GllvmFit` with parameter estimates,
convergence diagnostics, and wall-clock fit time.

J1 behaviour (`K_W = 0`, `has_diag = false`, `X = nothing`,
`K_phy = 0`, `has_phy_unique = false`, `Σ_phy = nothing`) is preserved
unchanged.

Optional extensions:
- J2-A-WD: `K_W::Integer = 0` (W-tier rank), `has_diag::Bool = false`
  (per-trait diagonal RE σ²_B, σ²_W).
- J3 phylogenetic: `K_phy::Integer = 0` (Λ_phy rank),
  `has_phy_unique::Bool = false` (per-trait σ_phy), and
  `Σ_phy::AbstractMatrix` (p × p species covariance, required when
  `K_phy > 0` or `has_phy_unique`).

Optional fixed effects:
- `X::AbstractArray{<:Real, 3}` of shape `(p, n_sites, q)`.
- `β_init::AbstractVector` of length q (defaults to `zeros(q)`).

The fit's `pars` NamedTuple always contains
`(σ_eps, Λ, β, Λ_W, σ²_B, σ²_W, Λ_phy, σ_phy, θ_packed)` where
`Λ_W`, `σ²_B`, `σ²_W`, `Λ_phy`, `σ_phy` are `nothing` when the
corresponding flag is off.
"""
function fit_gaussian_gllvm(y::AbstractMatrix;
                            K::Integer,
                            K_W::Integer = 0,
                            has_diag::Bool = false,
                            K_phy::Integer = 0,
                            has_phy_unique::Bool = false,
                            Σ_phy::Union{Nothing, AbstractMatrix} = nothing,
                            X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing,
                            σ_eps_init = 1.0,
                            λ_init = nothing,
                            λ_W_init = nothing,
                            λ_phy_init = nothing,
                            σ²_B_init = 0.1,
                            σ²_W_init = 0.1,
                            σ_phy_init = 0.1,
                            β_init = nothing,
                            x_tol = 1e-8,
                            f_tol = 1e-10,
                            g_tol = 1e-6,
                            iterations = 500)
    p, n = size(y)
    @assert K ≥ 1
    @assert K_W ≥ 0
    @assert K_phy ≥ 0
    @assert n ≥ p "Need n_sites ≥ p for a well-posed Gaussian GLLVM"

    if (K_phy > 0 || has_phy_unique) && Σ_phy === nothing
        throw(ArgumentError(
            "Σ_phy is required when K_phy > 0 or has_phy_unique = true"))
    end
    if Σ_phy !== nothing
        size(Σ_phy, 1) == p && size(Σ_phy, 2) == p ||
            throw(ArgumentError(
                "Σ_phy must be p × p; got $(size(Σ_phy)) for p = $p"))
    end

    # Validate X dims if present
    q = 0
    if X !== nothing
        size(X, 1) == p ||
            throw(ArgumentError("X first dim ($(size(X,1))) must equal p ($p)"))
        size(X, 2) == n ||
            throw(ArgumentError("X second dim ($(size(X,2))) must equal n_sites ($n)"))
        q = size(X, 3)
    end

    # ----- Decide on the NLL flavour and assemble the initial parameter vector.
    has_phy_block = (K_phy > 0) || has_phy_unique
    use_spec = (K_W > 0) || has_diag || has_phy_block
    rr_B     = rr_theta_len(p, K)
    rr_W     = K_W > 0 ? rr_theta_len(p, K_W) : 0
    rr_phy   = K_phy > 0 ? rr_theta_len(p, K_phy) : 0

    # β initial values (shared between the two flavours)
    β₀ = if q > 0
        if isnothing(β_init)
            zeros(Float64, q)
        else
            length(β_init) == q ||
                throw(ArgumentError("β_init length ($(length(β_init))) must equal q ($q)"))
            collect(Float64, β_init)
        end
    else
        Float64[]
    end

    # θ_rr_B initial values
    θ_B₀ = isnothing(λ_init) ? init_theta_rr(p, K) : pack_lambda(λ_init)

    if !use_spec
        # ----- J1 / J2-A path: keep the legacy packed layout untouched.
        params₀ = vcat(β₀, log(σ_eps_init), θ_B₀)
        nll     = params -> gaussian_nll_packed(params, y, p, K; X = X, q = q)
    else
        # ----- J2-A-WD / J3 path: extended packed layout.
        log_σ_B₀ = has_diag ? fill(0.5 * log(σ²_B_init), p) : Float64[]
        log_σ_W₀ = has_diag ? fill(0.5 * log(σ²_W_init), p) : Float64[]
        θ_W₀ = if K_W > 0
            isnothing(λ_W_init) ? init_theta_rr(p, K_W) : pack_lambda(λ_W_init)
        else
            Float64[]
        end
        log_σ_phy₀ = has_phy_unique ? fill(log(σ_phy_init), p) : Float64[]
        θ_phy₀ = if K_phy > 0
            isnothing(λ_phy_init) ? init_theta_rr(p, K_phy) : pack_lambda(λ_phy_init)
        else
            Float64[]
        end
        params₀ = vcat(β₀, log(σ_eps_init), log_σ_B₀, log_σ_W₀,
                       θ_B₀, θ_W₀, log_σ_phy₀, θ_phy₀)
        spec    = (q = q, p = p, K_B = Int(K), K_W = Int(K_W),
                   has_diag = has_diag, K_phy = Int(K_phy),
                   has_phy_unique = has_phy_unique)
        nll     = params -> gaussian_nll_packed(params, y;
                                                spec = spec, X = X,
                                                Σ_phy = Σ_phy)
    end

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
    nll_hat    = Optim.minimum(res)

    # Unpack
    cursor   = 0
    β_hat    = q > 0 ? collect(params_hat[1:q]) : Float64[]
    cursor  += q
    σ_eps_hat = exp(params_hat[cursor + 1])
    cursor  += 1
    if has_diag
        log_σ_B_hat = params_hat[(cursor + 1):(cursor + p)]
        cursor     += p
        log_σ_W_hat = params_hat[(cursor + 1):(cursor + p)]
        cursor     += p
        σ²_B_hat = exp.(2 .* log_σ_B_hat)
        σ²_W_hat = exp.(2 .* log_σ_W_hat)
    else
        σ²_B_hat = nothing
        σ²_W_hat = nothing
    end
    Λ_hat   = unpack_lambda(@view(params_hat[(cursor + 1):(cursor + rr_B)]), p, K)
    cursor += rr_B
    Λ_W_hat = if K_W > 0
        out = unpack_lambda(@view(params_hat[(cursor + 1):(cursor + rr_W)]), p, K_W)
        cursor += rr_W
        out
    else
        nothing
    end
    σ_phy_hat = if has_phy_unique
        log_σ_phy_hat = params_hat[(cursor + 1):(cursor + p)]
        cursor       += p
        exp.(log_σ_phy_hat)
    else
        nothing
    end
    Λ_phy_hat = if K_phy > 0
        out = unpack_lambda(@view(params_hat[(cursor + 1):(cursor + rr_phy)]),
                            p, K_phy)
        cursor += rr_phy
        out
    else
        nothing
    end

    return GllvmFit(
        GllvmModel(Int(p), Int(K), Int(K_W), has_diag,
                   Int(K_phy), has_phy_unique),
        (σ_eps = σ_eps_hat,
         Λ = Λ_hat,
         β = β_hat,
         Λ_W = Λ_W_hat,
         σ²_B = σ²_B_hat,
         σ²_W = σ²_W_hat,
         Λ_phy = Λ_phy_hat,
         σ_phy = σ_phy_hat,
         θ_packed = collect(params_hat)),
        -nll_hat,
        Optim.iterations(res),
        Optim.converged(res),
        res,
        t1 - t0,
    )
end
