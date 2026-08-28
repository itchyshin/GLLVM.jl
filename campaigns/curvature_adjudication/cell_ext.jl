# Follow-up cell types for the curvature-adjudication campaign (Arc 1,
# decision #2): gp1 and tweedie — the two families cell.jl deferred because
# their density pieces need care in the exact-marginal integrand and their
# fitters are the slowest (gp1 profiles α over a grid + Brent; tweedie runs a
# joint L-BFGS over [β; Λ; log φ; ξ] with FD gradients — budget accordingly).
#
# Reuses cell.jl's REGIMES and exact-marginal machinery by include; only the
# per-family density, simulator, fit dispatch, and dispersion bookkeeping are
# new. Same protocol: simulate from known truth, fit under hessian = :fisher
# and :observed, evaluate the EXACT marginal (dense log-trapezoid quadrature)
# at each fit's own estimates, report objective error and exact-marginal
# preference.
#
# Density notes (the "care" that deferred these families):
#   gp1 — Famoye/Consul–Jain GP-1 (src/families/gp1.jl), SIGNED dispersion α,
#     μ = exp(η), Var = μ(1+αμ)²:
#       log f = y(log μ − log g) + (y−1) log h − lgamma(y+1) − μ h / g,
#       g = 1+αμ, h = 1+αy;  domain g > 0 AND h > 0, else density 0 (−Inf).
#     On the z-grid a fitted Λ̂ can push η to extremes; for α̂ < 0 the domain
#     guard can zero out an entire z-range (g ≤ 0), and an observed y beyond
#     the α̂ < 0 truncation support (h ≤ 0) makes the site's exact marginal
#     −Inf at that θ̂ — a legitimate oracle statement (θ̂ assigns the sample
#     zero probability), not an integration failure. |α| < 1e-10 short-circuits
#     to the Poisson log-pmf, mirroring _glm_logpdf's cancellation guard.
#     For α ≥ 0 the pmf is exactly normalized; for α < 0 the finite support
#     truncates a small tail mass (intrinsic to GP-1, see src/families/gp1.jl
#     header) — the oracle integrates the same truncated density the fitter
#     maximises, so the comparison stays like-for-like.
#   tweedie — compound Poisson–Gamma, 1 < p < 2 (src/families/tweedie.jl).
#     BOTH the dispersion φ and the power p are estimated; the oracle integrand
#     uses GLLVM.tweedie_logpdf (exact y = 0 atom + Dunn–Smyth series for
#     y > 0) at the FITTED (φ̂, p̂), and both are recorded per selector.
#     tweedie_logpdf is series-based ⇒ the 8001-node grid over every (t, s)
#     makes this the most expensive oracle in the campaign.
#
# Usage: julia --project=<repo> cell_ext.jl <family> <regime> <seed> <outdir>
# Families: gp1 tweedie

include(joinpath(@__DIR__, "cell.jl"))   # REGIMES, logistic, deps; CLI guard inert

# Per-site integrand pieces at the FITTED params. `disp` is α̂ (gp1, signed
# scalar) or the tuple (φ̂, p̂) (tweedie).
function site_logdens_ext(fam::String, y, η, disp)
    if fam == "gp1"
        α = disp
        # Poisson limit short-circuit (avoids 0·(…)/g noise; exp overflow → -Inf).
        abs(α) < 1e-10 && return y * η - exp(η) - loggamma(y + 1.0)
        μ = exp(η)
        g = 1 + α * μ
        h = 1 + α * y
        (g > 0 && h > 0 && isfinite(μ)) || return -Inf   # GP-1 domain / η overflow
        return y * (η - log(g)) + (y - 1) * log(h) - loggamma(y + 1.0) - μ * h / g
    elseif fam == "tweedie"
        φ, pw = disp
        return GLLVM.tweedie_logpdf(y, exp(min(η, 700.0)), φ, pw)
    else
        error("unknown extension family $fam")
    end
end

# Exact marginal, K = 1 — same grid and log-sum-exp trapezoid as cell.jl's
# exact_marginal, dispatching on site_logdens_ext (disp may be a tuple).
function exact_marginal_ext(fam, Y, Λ, β, disp)
    p, n = size(Y)
    zs = range(-10.0, 10.0; length = 8001); dz = step(zs)
    total = 0.0
    lw = similar(collect(zs))
    for s in 1:n
        for (i, z) in enumerate(zs)
            lp = logpdf(Normal(), z)
            for t in 1:p
                lp += site_logdens_ext(fam, Y[t, s], β[t] + Λ[t, 1] * z, disp)
            end
            lw[i] = lp
        end
        m = maximum(lw)
        total += m + log(sum(exp, lw .- m) * dz)
    end
    return total
end

function simulate_ext(fam, reg, rng)
    (; p, n, lam) = REGIMES[reg]
    β = 0.3 .* randn(rng, p)
    Λ = reshape(lam .* randn(rng, p), p, 1)
    Z = randn(rng, 1, n)
    H = β .+ Λ * Z
    Y = zeros(p, n)
    if fam == "gp1"
        # Counts like negbin, GP-1 truth with moderate overdispersion:
        # α_true = 0.3 ⇒ Var = μ(1 + 0.3 μ)². Drawn with the package's
        # inverse-CDF sampler — same pmf as the density above (the density is
        # shared, not under test, per the campaign preamble).
        disp_true = 0.3
        f = GLLVM.GeneralizedPoisson1(disp_true)
        for t in 1:p, s in 1:n
            Y[t, s] = GLLVM._rand_gp1(rng, f, exp(H[t, s]))
        end
        return Y, β, Λ, disp_true
    elseif fam == "tweedie"
        # Compound Poisson–Gamma like test/test_tweedie.jl:48-63: k ~ Poisson(μ),
        # positive part a sum of k Gamma(2, μ/(2μ)) draws. This DGP has implied
        # power p = (a+2)/(a+1) = 4/3 but a μ-dependent (non-scalar) implied φ,
        # so there is no single dispersion truth to recover; disp_true is NaN
        # and the recovery column is Λ only. The oracle uses the FITTED (φ̂, p̂).
        disp_true = NaN
        for t in 1:p, s in 1:n
            μ = exp(H[t, s])
            λ = μ
            k = rand(rng, Poisson(λ))
            Y[t, s] = k == 0 ? 0.0 : sum(rand(rng, Gamma(2.0, μ / (2.0 * λ + 1e-9)), k))
        end
        return Y, β, Λ, disp_true
    end
    error("unknown extension family $fam")
end

function fitcell_ext(fam, Y, h)
    fam == "gp1" && return GLLVM.fit_gp1_gllvm(Y; K = 1, hessian = h)
    fam == "tweedie" && return GLLVM.fit_tweedie_gllvm(Y; K = 1, hessian = h)
    error("unknown extension family $fam")
end

# Fitted dispersion in the form site_logdens_ext expects.
dispof_ext(fam, fit) = fam == "gp1" ? fit.α : (fit.φ, fit.p)

function run_cell_ext(fam::String, reg::String, seed::Int, outdir::String)
    rng = Xoshiro(seed)
    Y, βtrue, Λtrue, disp_true = simulate_ext(fam, reg, rng)
    row = Dict{String,Any}("family" => fam, "regime" => reg, "seed" => seed)
    t0 = time()
    for (tag, h) in (("fisher", :fisher), ("observed", :observed))
        fit = fitcell_ext(fam, Y, h)
        d = dispof_ext(fam, fit)
        ex = fit.converged ? exact_marginal_ext(fam, Y, fit.Λ, fit.β, d) : NaN
        row["conv_$tag"] = fit.converged
        row["laplace_$tag"] = fit.loglik           # the Laplace objective at its own optimum
        row["exact_at_$tag"] = ex                  # the true marginal at that optimum
        row["objerr_$tag"] = fit.loglik - ex       # signed Laplace-approximation error
        row["lam_rmse_$tag"] = sqrt(sum(abs2, abs.(fit.Λ) .- abs.(Λtrue)) / length(Λtrue))
        if fam == "gp1"
            row["alpha_$tag"] = fit.α              # signed dispersion estimate
        else
            row["phi_$tag"] = fit.φ                # tweedie: record BOTH estimated
            row["power_$tag"] = fit.p              # dispersion parameters
        end
    end
    row["exact_pref"] = row["exact_at_observed"] - row["exact_at_fisher"]  # >0 ⇒ observed's θ̂ truer
    row["wall_s"] = round(time() - t0; digits = 1)
    open(joinpath(outdir, "cell_$(fam)_$(reg)_$(seed).csv"), "w") do io
        ks = sort(collect(keys(row)))
        println(io, join(ks, ","))
        println(io, join([row[k] for k in ks], ","))
    end
    @printf("%s/%s seed=%d  objerr f=%.4f o=%.4f  exact_pref=%.4f  wall=%.0fs\n",
            fam, reg, seed, row["objerr_fisher"], row["objerr_observed"],
            row["exact_pref"], row["wall_s"])
    return row
end

if abspath(PROGRAM_FILE) == @__FILE__
    fam, reg, seed, outdir = ARGS[1], ARGS[2], parse(Int, ARGS[3]), ARGS[4]
    mkpath(outdir)
    run_cell_ext(fam, reg, seed, outdir)
end
