# DRAC Wald-coverage campaign worker (maintainer decision round2-3 #8).
# Same chunked-array design as core070_recovery_chunk.jl (25 seeds/task to
# amortize compile), same pinned DGP so coverage is measured on the SAME cells
# the 10,000-fit recovery campaign characterised — but recording INTERVAL
# COVERAGE of the per-trait intercepts β at level 0.95, not point recovery.
#
# Wald only (profile CIs are many refits per endpoint; excluded by decision).
# Runs on the POST-FIX engine (nobs p·n, cloglog observed curvature,
# tier-scoped estimands, Student-t boundary honesty) — that was the
# precondition for launching.
#
# argv: family p n seed_start seed_end outdir
using GLLVM
using Random
using LinearAlgebra
using Statistics

family = ARGS[1]
p = parse(Int, ARGS[2])
n = parse(Int, ARGS[3])
s0 = parse(Int, ARGS[4])
s1 = parse(Int, ARGS[5])
outdir = ARGS[6]
mkpath(outdir)

K = 2
cell_rng = Xoshiro(7000 + 13 * p + n)          # identical cell-pinned truth
Lambda_true = 0.5 .* randn(cell_rng, p, K)
beta_true = 0.3 .* randn(cell_rng, p)
sigma_true = 0.7
phi_true = 10.0
_inv_logit(x) = 1 / (1 + exp(-x))

function draw_Y(rng)
    eta = Lambda_true * randn(rng, K, n) .+ beta_true
    if family == "gaussian"
        return eta .+ sigma_true .* randn(rng, p, n)
    elseif family == "poisson"
        return [rand(rng, GLLVM.Distributions.Poisson(exp(min(eta[i, j], 4.0)))) for i in 1:p, j in 1:n]
    elseif family == "nbinom2"
        return [rand(rng, GLLVM.Distributions.NegativeBinomial(2.0, 2.0 / (2.0 + exp(min(eta[i, j], 4.0))))) for i in 1:p, j in 1:n]
    elseif family == "binomial"
        return [rand(rng) < _inv_logit(eta[i, j]) ? 1 : 0 for i in 1:p, j in 1:n]
    else
        return [clamp(rand(rng, GLLVM.Distributions.Beta(_inv_logit(eta[i, j]) * phi_true,
                                                        (1 - _inv_logit(eta[i, j])) * phi_true)),
                      1e-6, 1 - 1e-6) for i in 1:p, j in 1:n]
    end
end

function fit_one(Y)
    if family == "gaussian"
        X = zeros(p, n, p)
        for j in 1:p
            X[j, :, j] .= 1
        end
        return GLLVM.fit_gaussian_gllvm(float.(Y); K = K, X = X), X
    elseif family == "poisson"
        return GLLVM.fit_poisson_gllvm(Int.(Y); K = K), nothing
    elseif family == "nbinom2"
        return GLLVM.fit_nb_gllvm(Int.(Y); K = K), nothing
    elseif family == "binomial"
        return GLLVM.fit_binomial_gllvm(Int.(Y); K = K), nothing
    else
        return GLLVM.fit_beta_gllvm(float.(Y); K = K), nothing
    end
end

# Coverage of the p per-trait intercepts: does the 95% Wald interval for
# beta[t] contain beta_true[t]? Recorded per seed as a covered-count so the
# aggregator can form a binomial coverage estimate with MC error.
outfile = joinpath(outdir, "cov-$(family)-p$(p)-n$(n)-s$(lpad(s0, 4, '0')).csv")
open(outfile, "w") do io
    println(io, "family,p,n,seed,converged,n_beta,n_covered,mean_width,ci_status,error")
    for seed in s0:s1
        rng = Xoshiro(100_000 + seed)
        Y = draw_Y(rng)
        row = try
            fit, X = fit_one(Y)
            conv = hasproperty(fit, :converged) ? fit.converged : missing
            ci = X === nothing ? GLLVM.confint(fit, float.(Y); level = 0.95, parm = "beta") :
                                 GLLVM.confint(fit, float.(Y); level = 0.95, parm = "beta", X = X)
            lo = Float64.(ci.lower); hi = Float64.(ci.upper)
            m = min(length(lo), p)
            covered = count(t -> isfinite(lo[t]) && isfinite(hi[t]) &&
                                 lo[t] <= beta_true[t] <= hi[t], 1:m)
            width = mean(hi[1:m] .- lo[1:m])
            join([family, p, n, seed, conv, m, covered, round(width, digits = 6), "ok", ""], ",")
        catch err
            # a failed fit or CI is a RECORDED outcome, never a dropped seed
            join([family, p, n, seed, "error", 0, 0, "NaN", "error",
                  replace(sprint(showerror, err)[1:min(end, 120)], "," => ";")], ",")
        end
        println(io, row)
        flush(io)
    end
end
println("COVERAGE_CHUNK_DONE $family p=$p n=$n seeds=$s0:$s1")
