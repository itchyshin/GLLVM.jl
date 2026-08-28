# One cell of the curvature-adjudication campaign — Binomial non-canonical
# links (Arc 1 extension: the two OPEN Binomial cells).
#
# Binomial-logit is canonical (observed ≡ Fisher pointwise, certified in-suite;
# `_glm_weight_matches_observed(::Binomial, ::LogitLink) = true`), so there is
# nothing to adjudicate there. Under ProbitLink and CLogLogLink the observed
# conditional curvature −∂²ℓ/∂η² DOES depend on y, so `hessian = :fisher` and
# `hessian = :observed` are genuinely different objectives — these are the cells
# this script adjudicates.
#
# Structure mirrors cell.jl exactly:
#   1. simulate Bernoulli draws through the probit (resp. cloglog) inverse link
#      from known truth (K = 1);
#   2. fit twice with GLLVM.fit_binomial_gllvm(Y; K = 1, link, hessian):
#      hessian = :fisher and hessian = :observed (both routed through the
#      generic Laplace core; non-logit links use the finite-difference outer
#      gradient, so expect slower cells than the cell.jl families);
#   3. compute the EXACT marginal loglik by dense log-trapezoid quadrature at
#      each fit's estimates — the integrand is the Bernoulli log-pmf through
#      the SAME inverse link, written tail-robustly via Distributions.logcdf
#      (probit) / expm1 identities (cloglog), independent of the Laplace path;
#   4. report: signed Laplace objective error per selector, exact-marginal
#      ranking of the two θ̂ (exact_pref > 0 ⇒ observed's θ̂ truer), and Λ
#      recovery (sign-invariant RMSE).
#
# Usage: julia --project=<repo> cell_binlinks.jl <family> <regime> <seed> <outdir>
# Families: probit cloglog     Regimes: small medium strong
# Do not run inside the repo's test slot; this is a campaign script.

using GLLVM, Random, Distributions, LinearAlgebra, Printf

const REGIMES = Dict(
    "small"  => (p = 5,  n = 60,  lam = 0.4),
    "medium" => (p = 10, n = 150, lam = 0.6),
    "strong" => (p = 8,  n = 100, lam = 1.0),
)

linkof(fam::String) = fam == "probit" ? GLLVM.ProbitLink() :
    fam == "cloglog" ? GLLVM.CLogLogLink() : error("unknown link family $fam")

# Inverse links (match src/families/links.jl definitions exactly):
#   probit:  μ = Φ(η);   cloglog: μ = 1 − exp(−exp(η)) = −expm1(−exp(η)).
invlink(fam::String, η) = fam == "probit" ? cdf(Normal(), η) : -expm1(-exp(η))

# Per-site integrand: Bernoulli log-pmf log f(y | z) at the FITTED params,
# tail-robust (a diverged Λ̂ can push η far out on the z-grid):
#   probit : y=1 → log Φ(η) = logcdf(N,η); y=0 → log(1−Φ(η)) = logcdf(N,−η)
#   cloglog: y=1 → log(−expm1(−e^η));      y=0 → log(1−μ) = −e^η  (exact)
function site_logdens(fam::String, y, η)
    if fam == "probit"
        return y == 1 ? logcdf(Normal(), η) : logcdf(Normal(), -η)
    elseif fam == "cloglog"
        t = exp(η)                      # overflow → t = Inf handled below
        if y == 1
            # log(1 − e^{−t}); t → 0 gives ≈ log t = η, t → Inf gives 0.
            return t == Inf ? 0.0 : log(-expm1(-t))
        else
            return -t                   # t = Inf → −Inf, correctly impossible
        end
    else
        error("unknown link family $fam")
    end
end

# Exact marginal loglik, K = 1: per site s, log ∫ exp(Σ_t log f + log φ(z)) dz
# by log-sum-exp trapezoid on a dense grid — same grid as cell.jl
# (half-width 10, 8001 nodes).
function exact_marginal(fam, Y, Λ, β)
    p, n = size(Y)
    zs = range(-10.0, 10.0; length = 8001); dz = step(zs)
    total = 0.0
    lw = similar(collect(zs))
    for s in 1:n
        for (i, z) in enumerate(zs)
            lp = logpdf(Normal(), z)
            for t in 1:p
                lp += site_logdens(fam, Y[t, s], β[t] + Λ[t, 1] * z)
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
    Y = zeros(Int, p, n)
    for t in 1:p, s in 1:n
        μ = clamp(invlink(fam, H[t, s]), 1e-12, 1 - 1e-12)
        Y[t, s] = rand(rng, Bernoulli(μ)) ? 1 : 0
    end
    return Y, β, Λ
end

fitcell(fam, Y, h) =
    GLLVM.fit_binomial_gllvm(Y; K = 1, link = linkof(fam), hessian = h)

function run_cell(fam::String, reg::String, seed::Int, outdir::String)
    rng = Xoshiro(seed)
    Y, βtrue, Λtrue = simulate(fam, reg, rng)
    row = Dict{String,Any}("family" => fam, "regime" => reg, "seed" => seed)
    t0 = time()
    for (tag, h) in (("fisher", :fisher), ("observed", :observed))
        fit = fitcell(fam, Y, h)
        ex = fit.converged ? exact_marginal(fam, Y, fit.Λ, fit.β) : NaN
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
