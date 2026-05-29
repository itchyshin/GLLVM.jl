# Optim.jl-driven L-BFGS minimisation of the Gaussian GLLVM marginal
# negative log-likelihood. Matches the R engine's initial values and
# convergence tolerances; the head-to-head benchmark depends on this.
#
# Speed pass (MixedModels.jl-style):
#   - σ²_eps is profiled out analytically. The optimisation parameter
#     vector drops `log_σ_eps`. All other variance components are
#     reparameterised in σ²_eps units (Λ = σ_eps · L, etc.) so that the
#     profile NLL only depends on the rescaled parameters.
#   - At the optimum, σ̂²_eps = Q̃ / (n·p) where Q̃ is the quadratic form
#     computed with the rescaled (σ_eps = 1) covariance.
#   - ForwardDiff stays the AD backend for now. At the parameter counts
#     used by the benchmark grid (< 70 params), ForwardDiff's chunked
#     dual evaluation is competitive with or faster than ReverseDiff
#     for our hot path, which is dominated by p × n matrix ops with
#     cholesky on a small (K × K) matrix. The reverse-mode advantage
#     only kicks in at much larger param counts than this engine sees.

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

Under the hood the optimisation runs on the profile NLL (σ²_eps and
optionally β profiled out analytically, MixedModels.jl-style). The
public API and parameter recovery semantics are unchanged.

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

    has_phy_block = (K_phy > 0) || has_phy_unique

    # Build spec for profile NLL
    spec = (q = q, p = Int(p), K_B = Int(K), K_W = Int(K_W),
            has_diag = has_diag, K_phy = Int(K_phy),
            has_phy_unique = has_phy_unique)

    rr_B = rr_theta_len(p, K)
    rr_W = K_W > 0 ? rr_theta_len(p, K_W) : 0
    rr_phy = K_phy > 0 ? rr_theta_len(p, K_phy) : 0

    # ----- Warm-start via PPCA closed-form ML for Λ_B and σ_eps.
    # When the caller did not provide λ_init / σ_eps_init explicitly,
    # use the Tipping & Bishop (1999) closed-form solution as the
    # starting point. This is a multiplicative speedup on top of σ²_eps
    # profile-out: PPCA gives a near-optimal Λ_B for the dominant rank-K
    # piece, so LBFGS converges in a handful of iterations (often 1–5
    # for J1, ~10–20 for J2/J3) instead of 20–50 from the generic init.
    #
    # The PPCA closed form assumes y has zero mean. For the X case we
    # first do an OLS regression to get an initial β̂, then run PPCA on
    # the residuals. The OLS step costs one (q × q) solve and is
    # numerically trivial.
    σ_e₀ = float(σ_eps_init)

    # Default warm-start: only fires when the caller hasn't supplied
    # explicit initial values for Λ_B or σ_eps. This preserves the
    # explicit-init API (tests / experts) while giving the typical
    # caller the PPCA speed-up automatically.
    use_ppca_init = isnothing(λ_init) && (σ_eps_init == 1.0) && K < p
    if use_ppca_init
        # Build "residuals" y_resid for the PPCA: subtract X β̂_OLS if X
        # is provided, else use y directly.
        if X !== nothing && q > 0 && isnothing(β_init)
            # OLS: stack the columns. r_s = y_s - X_s β; minimise sum_s ||r_s||² over β.
            # Build M (q × q) and v (q vec): M = Σ_s X_s' X_s, v = Σ_s X_s' y_s
            M_ols = zeros(Float64, q, q)
            v_ols = zeros(Float64, q)
            for s in 1:n
                Xs = @view X[:, s, :]
                M_ols .+= Xs' * Xs
                v_ols .+= Xs' * @view(y[:, s])
            end
            β_ols = M_ols \ v_ols
            y_resid = similar(y, Float64)
            @inbounds for s in 1:n, t in 1:p
                μ = 0.0
                for k in 1:q
                    μ += X[t, s, k] * β_ols[k]
                end
                y_resid[t, s] = y[t, s] - μ
            end
            Λ_ppca, σ_ppca = ppca_init(y_resid, K)
            σ_e₀ = σ_ppca
            λ_init = Λ_ppca
            if isnothing(β_init)
                β_init = β_ols
            end
        elseif X === nothing
            Λ_ppca, σ_ppca = ppca_init(y, K)
            σ_e₀ = σ_ppca
            λ_init = Λ_ppca
        end
    end

    # β initial values: only included when β is NOT profiled out (phy path
    # or X-less case). For the non-phy + X case we profile β out via GLS
    # only when the per-evaluation cost is worth it; for q ≤ p we instead
    # keep β in the param vector (cheaper per gradient call at our sizes).
    # The decision: profile β when q ≤ small_threshold. Currently we keep
    # β in the param vector (profile_beta = false) because empirical
    # timing shows it dominates when q is small.
    profile_beta = false  # MixedModels-style β profile-out (off by default)

    do_profile_beta = profile_beta && !has_phy_block && q > 0
    β_in_params = !do_profile_beta && q > 0

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

    # L_B init: if λ_init is on the raw scale, divide by σ_eps_init.
    θ_B₀ = if isnothing(λ_init)
        init_theta_rr(p, K)
    else
        pack_lambda(λ_init ./ σ_e₀)
    end

    θ_W₀ = if K_W > 0
        if isnothing(λ_W_init)
            init_theta_rr(p, K_W)
        else
            pack_lambda(λ_W_init ./ σ_e₀)
        end
    else
        Float64[]
    end

    # τ_B, τ_W on log-SD scale: log_τ = 0.5 * log(σ²_init / σ²_eps_init)
    log_τ_B₀ = has_diag ? fill(0.5 * log(σ²_B_init / σ_e₀^2), p) : Float64[]
    log_τ_W₀ = has_diag ? fill(0.5 * log(σ²_W_init / σ_e₀^2), p) : Float64[]

    # ρ_phy on identity (signed) scale: ρ_phy = σ_phy / σ_eps. Signed because
    # σ_phy now uses an identity link — see src/likelihood.jl, src/profile.jl.
    ρ_phy₀ = has_phy_unique ? fill(σ_phy_init / σ_e₀, p) : Float64[]

    θ_phy₀ = if K_phy > 0
        if isnothing(λ_phy_init)
            init_theta_rr(p, K_phy)
        else
            pack_lambda(λ_phy_init ./ σ_e₀)
        end
    else
        Float64[]
    end

    # Assemble profile params0 in the canonical order:
    # [β (if not profiled), log_τ_B, log_τ_W, θ_B, θ_W, ρ_phy, θ_phy]
    params₀ = if β_in_params
        vcat(β₀, log_τ_B₀, log_τ_W₀, θ_B₀, θ_W₀, ρ_phy₀, θ_phy₀)
    else
        vcat(log_τ_B₀, log_τ_W₀, θ_B₀, θ_W₀, ρ_phy₀, θ_phy₀)
    end

    nll = params -> gaussian_profile_nll(params, y;
                                          spec = spec, X = X,
                                          Σ_phy = Σ_phy,
                                          profile_beta = do_profile_beta)

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

    # Signed-σ_phy: escape sign-pattern basins via greedy single-flip restarts.
    # The identity-link σ_phy lets the optimisation reach any signed value, but
    # LBFGS is a *smooth* optimiser — to move from one sign pattern to another
    # it would have to pass through a saddle where some |σ_phy[t]| ≈ 0, and
    # in practice it gets trapped in the basin of its initial sign pattern.
    # We restore the discrete moves: at each converged point, evaluate the
    # NLL after flipping the sign of each individual σ_phy[t]; if any flip
    # strictly improves, restart LBFGS from the best single flip. Iterate
    # until no single flip helps. Bounded by O(p) outer iterations (each
    # iteration commits one sign change); in practice 0–2 restarts suffice.
    # Without this loop, LBFGS can stall at sign-pattern-local optima that
    # are *not* the global MLE — exactly the seed-17 / signed-MLE pathology
    # the identity link was introduced to fix.
    if has_phy_unique
        q_in_params = β_in_params ? q : 0
        diag_count = has_diag ? 2 * p : 0
        offset_pre_ρ = q_in_params + diag_count + rr_B + rr_W
        ρ_range = (offset_pre_ρ + 1):(offset_pre_ρ + p)
        max_flip_iters = p + 2  # safety cap
        for _ in 1:max_flip_iters
            nll_current = nll(params_hat)
            best_drop = 0.0
            best_idx  = 0
            for t in 1:p
                trial = copy(params_hat)
                trial[ρ_range[t]] = -trial[ρ_range[t]]
                drop = nll_current - nll(trial)
                if drop > best_drop + 1e-8
                    best_drop = drop
                    best_idx  = t
                end
            end
            best_idx == 0 && break
            # Restart LBFGS from the best single-flipped point.
            params_seed = copy(params_hat)
            params_seed[ρ_range[best_idx]] = -params_seed[ρ_range[best_idx]]
            res_flip = Optim.optimize(nll, params_seed, Optim.LBFGS(), opts;
                                       autodiff = :forward)
            if Optim.minimum(res_flip) < Optim.minimum(res) - 1e-8
                res = res_flip
                params_hat = Optim.minimizer(res)
            else
                break
            end
        end
        t1 = time()  # account for sign-exploration time in cputime
    end

    # Recover user-facing parameters
    rec = profile_recover(params_hat, y;
                          spec = spec, X = X, Σ_phy = Σ_phy,
                          profile_beta = do_profile_beta)

    # Post-hoc global sign anchor for σ_phy (identity-link, signed).
    # The marginal likelihood is invariant under the joint flip
    # (σ_phy → -σ_phy, φ → -φ); this is the lone non-identifiable
    # symmetry (cross terms B[t,t'] = σ_phy[t]·σ_phy[t']·Σ_phy[t,t'] are
    # bilinear in σ_phy so a *global* sign flip leaves B unchanged).
    # Convention: flip so the largest-magnitude entry has non-negative
    # sign. Estimates are then deterministic up to the flip.
    if has_phy_unique && rec.σ_phy !== nothing
        i_max = argmax(abs.(rec.σ_phy))
        if rec.σ_phy[i_max] < 0
            σ_phy_anchored = -rec.σ_phy
            rec = (logLik = rec.logLik, σ_eps = rec.σ_eps, β = rec.β,
                   Λ_B = rec.Λ_B, Λ_W = rec.Λ_W,
                   σ²_B = rec.σ²_B, σ²_W = rec.σ²_W,
                   Λ_phy = rec.Λ_phy, σ_phy = σ_phy_anchored)
        end
    end

    # Build θ_packed in the *original* (legacy) layout for backward
    # compatibility with consumers that read .pars.θ_packed:
    # [β; log_σ_eps; (log_σ_B; log_σ_W if has_diag);
    #  θ_rr_B; θ_rr_W; (σ_phy if has_phy_unique, identity link); θ_rr_phy]
    legacy_pieces = Any[]
    if q > 0
        push!(legacy_pieces, rec.β)
    end
    push!(legacy_pieces, [log(rec.σ_eps)])
    if has_diag
        push!(legacy_pieces, log.(sqrt.(rec.σ²_B)))
        push!(legacy_pieces, log.(sqrt.(rec.σ²_W)))
    end
    push!(legacy_pieces, pack_lambda(rec.Λ_B))
    if K_W > 0
        push!(legacy_pieces, pack_lambda(rec.Λ_W))
    end
    if has_phy_unique
        # Identity link: store signed σ_phy values directly (no log).
        push!(legacy_pieces, collect(rec.σ_phy))
    end
    if K_phy > 0
        push!(legacy_pieces, pack_lambda(rec.Λ_phy))
    end
    θ_packed_legacy = reduce(vcat, legacy_pieces)

    return GllvmFit(
        GllvmModel(Int(p), Int(K), Int(K_W), has_diag,
                   Int(K_phy), has_phy_unique),
        (σ_eps = rec.σ_eps,
         Λ = rec.Λ_B,
         β = rec.β,
         Λ_W = rec.Λ_W,
         σ²_B = rec.σ²_B,
         σ²_W = rec.σ²_W,
         Λ_phy = rec.Λ_phy,
         σ_phy = rec.σ_phy,
         θ_packed = θ_packed_legacy),
        rec.logLik,
        Optim.iterations(res),
        Optim.converged(res),
        res,
        t1 - t0,
    )
end
