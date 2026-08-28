# One cell of the curvature-adjudication campaign (Arc 1, decision #2).
#
# For a (family, regime, seed) cell with K = 1:
#   1. simulate from known truth;
#   2. fit twice: hessian = :fisher and hessian = :observed;
#   3. compute the EXACT marginal loglik by dense log-trapezoid quadrature at
#      each fit's estimates (independent of the Laplace code path — only the
#      per-observation log-density is shared, and that density is not under
#      test; the integration replaces the Laplace approximation);
#   4. report: objective error per selector (Laplace vs exact at the same θ̂),
#      exact-marginal ranking of the two θ̂ (the estimator-quality verdict),
#      and parameter recovery.
#
# Usage: julia --project=<repo> cell.jl <family> <regime> <seed> <outdir>
# Families: gamma beta negbin negbin1 studentt exponential
# (poisson/binomial are canonical — Fisher ≡ observed, nothing to adjudicate;
#  gp1/tweedie deferred to a follow-up cell type: their density pieces need
#  care in the integrand and their fitters are the slowest.)

using GLLVM, Random, Distributions, LinearAlgebra, Printf, SpecialFunctions

const REGIMES = Dict(
    "small"  => (p = 5,  n = 60,  lam = 0.4),
    "medium" => (p = 10, n = 150, lam = 0.6),
    "strong" => (p = 8,  n = 100, lam = 1.0),
)

logistic(x) = inv(1 + exp(-x))

# Per-site integrand pieces: log f(y_ts | z) for each family at the FITTED params.
function site_logdens(fam::String, y, η, disp)
    if fam == "gamma"           # α = disp; mean exp(η)
        # Direct log-density (robust at extreme η, cf. exponential below):
        # log f = α log α − lgamma(α) + (α−1) log y − α η − α y e^{−η}
        α = disp
        return α * log(α) - loggamma(α) + (α - 1) * log(y) - α * η - α * y * exp(-η)
    elseif fam == "beta"        # φ = disp; mean logistic(η)
        φ = disp; μ = clamp(logistic(η), 1e-12, 1 - 1e-12)
        return logpdf(Beta(μ * φ, (1 - μ) * φ), y)
    elseif fam == "negbin"      # NB2: r = disp
        r = disp; μ = exp(η); return logpdf(NegativeBinomial(r, r / (r + μ)), y)
    elseif fam == "negbin1"     # NB1: var = μ(1+φ) → r = μ/φ, p = 1/(1+φ)
        φ = disp; μ = exp(η); r = μ / φ
        return logpdf(NegativeBinomial(r, 1 / (1 + φ)), y)
    elseif fam == "studentt"    # σ = disp, ν fixed 5
        σ = disp; return logpdf(TDist(5.0), (y - η) / σ) - log(σ)
    elseif fam == "exponential"
        # Direct log-density: -η - y·e^{-η}. Robust where exp(η) under/overflows
        # (a diverged fit's Λ̂ can push η past ±745 on the z-grid; Distributions'
        # Exponential(0.0) constructor throws there, the formula returns -Inf).
        return -η - y * exp(-η)
    else
        error("unknown family $fam")
    end
end

# Exact marginal loglik, K = 1: per site s, log ∫ exp(Σ_t log f + log φ(z)) dz
# by log-sum-exp trapezoid on a dense grid. Grid half-width 10, 8001 nodes:
# richer than the in-suite 4001×[−8,8] oracle.
function exact_marginal(fam, Y, Λ, β, disp)
    p, n = size(Y)
    zs = range(-10.0, 10.0; length = 8001); dz = step(zs)
    total = 0.0
    lw = similar(collect(zs))
    for s in 1:n
        for (i, z) in enumerate(zs)
            lp = logpdf(Normal(), z)
            for t in 1:p
                lp += site_logdens(fam, Y[t, s], β[t] + Λ[t, 1] * z, disp)
            end
            lw[i] = lp
        end
        m = maximum(lw)
        total += m + log(sum(exp, lw .- m) * dz)
    end
    return total
end

function simulate(fam, reg, rng)
    (; p, n, lam) = REGIMES[reg]
    β = 0.3 .* randn(rng, p)
    Λ = reshape(lam .* randn(rng, p), p, 1)
    Z = randn(rng, 1, n)
    H = β .+ Λ * Z
    disp_true = fam == "gamma" ? 2.5 : fam == "beta" ? 10.0 :
                fam == "negbin" ? 3.0 : fam == "negbin1" ? 1.5 :
                fam == "studentt" ? 0.6 : NaN
    Y = zeros(p, n)
    for t in 1:p, s in 1:n
        η = H[t, s]
        Y[t, s] = fam == "gamma" ? rand(rng, Gamma(disp_true, exp(η) / disp_true)) :
            fam == "beta" ? clamp(rand(rng, Beta(logistic(η) * disp_true, (1 - logistic(η)) * disp_true)), 1e-9, 1 - 1e-9) :
            fam == "negbin" ? rand(rng, NegativeBinomial(disp_true, disp_true / (disp_true + exp(η)))) :
            fam == "negbin1" ? rand(rng, NegativeBinomial(exp(η) / disp_true, 1 / (1 + disp_true))) :
            fam == "studentt" ? η + disp_true * rand(rng, TDist(5.0)) :
            rand(rng, Exponential(exp(η)))
    end
    return Y, β, Λ, disp_true
end

function fitcell(fam, Y, h)
    fam == "gamma" && return GLLVM.fit_gamma_gllvm(Y; K = 1, hessian = h)
    fam == "beta" && return GLLVM.fit_beta_gllvm(Y; K = 1, hessian = h)
    fam == "negbin" && return GLLVM.fit_nb_gllvm(Y; K = 1, hessian = h)
    fam == "negbin1" && return GLLVM.fit_nb1_gllvm(Y; K = 1, hessian = h)
    fam == "studentt" && return GLLVM.fit_studentt_gllvm(Y; K = 1, nu = 5.0, hessian = h)
    fam == "exponential" && return GLLVM.fit_exponential_gllvm(Y; K = 1, hessian = h)
    error("unknown family $fam")
end

dispof(fam, fit) = fam == "gamma" ? fit.α : fam == "beta" ? fit.φ :
    fam == "negbin" ? fit.r : fam == "negbin1" ? fit.φ :
    fam == "studentt" ? fit.σ : NaN

function run_cell(fam::String, reg::String, seed::Int, outdir::String)
    rng = Xoshiro(seed)
    Y, βtrue, Λtrue, disp_true = simulate(fam, reg, rng)
    row = Dict{String,Any}("family" => fam, "regime" => reg, "seed" => seed)
    t0 = time()
    for (tag, h) in (("fisher", :fisher), ("observed", :observed))
        fit = fitcell(fam, Y, h)
        d = dispof(fam, fit)
        ex = fit.converged ? exact_marginal(fam, Y, fit.Λ, fit.β, isnan(d) ? 1.0 : d) : NaN
        row["conv_$tag"] = fit.converged
        row["laplace_$tag"] = fit.loglik           # the Laplace objective at its own optimum
        row["exact_at_$tag"] = ex                  # the true marginal at that optimum
        row["objerr_$tag"] = fit.loglik - ex       # signed Laplace-approximation error
        row["lam_rmse_$tag"] = sqrt(sum(abs2, abs.(fit.Λ) .- abs.(Λtrue)) / length(Λtrue))
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
    run_cell(fam, reg, seed, outdir)
end
