# ZI-trio ADEMP recovery worker (maintainer decision round2-3 #12: the
# zero-inflated families ship as JULIA-BEYOND capability — no R twin exists to
# pair against, so the evidence is simulation-based recovery, never parity).
#
# ADEMP (Morris et al. 2019):
#   Aim        — can the ZI fitters recover the DGP they are fitted to?
#   Data       — pinned per-cell truth; per-seed draws (same scheme as the
#                recovery/coverage campaigns so the three read as one grid).
#   Estimand   — zero-inflation intercepts βz, count/conditional intercepts βc,
#                and the rotation-invariant Λc Λcᵀ.
#   Methods    — fit_zip_gllvm / fit_zinb_gllvm / fit_zib_gllvm at defaults.
#   Performance— convergence rate, bias and RMSE of βz/βc, relative crossprod
#                error; failures RECORDED, never dropped.
#
# argv: family(zip|zinb|zib) p n seed_start seed_end outdir
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

K = 1
N_TRIALS = 5                                    # zib only
cell_rng = Xoshiro(9100 + 13 * p + n)
Lambda_true = 0.5 .* randn(cell_rng, p, K)
betac_true = 0.3 .* randn(cell_rng, p)          # conditional/count intercepts
betaz_true = -0.4 .+ 0.2 .* randn(cell_rng, p)  # zero-inflation intercepts (~40% zeros)
r_true = 2.0                                    # zinb size
_inv_logit(x) = 1 / (1 + exp(-x))

function draw_Y(rng)
    eta_c = Lambda_true * randn(rng, K, n) .+ betac_true
    Y = zeros(Int, p, n)
    for i in 1:p, j in 1:n
        if rand(rng) < _inv_logit(betaz_true[i])        # structural zero
            Y[i, j] = 0
        elseif family == "zip"
            Y[i, j] = rand(rng, GLLVM.Distributions.Poisson(exp(min(eta_c[i, j], 4.0))))
        elseif family == "zinb"
            mu = exp(min(eta_c[i, j], 4.0))
            Y[i, j] = rand(rng, GLLVM.Distributions.NegativeBinomial(r_true, r_true / (r_true + mu)))
        else
            Y[i, j] = rand(rng, GLLVM.Distributions.Binomial(N_TRIALS, _inv_logit(eta_c[i, j])))
        end
    end
    return Y
end

fit_one(Y) = family == "zip"  ? GLLVM.fit_zip_gllvm(Y; K = K) :
             family == "zinb" ? GLLVM.fit_zinb_gllvm(Y; K = K) :
                                GLLVM.fit_zib_gllvm(Y; K = K, N = N_TRIALS)

outfile = joinpath(outdir, "zi-$(family)-p$(p)-n$(n)-s$(lpad(s0, 4, '0')).csv")
open(outfile, "w") do io
    println(io, "family,p,n,seed,converged,loglik,betaz_bias,betaz_rmse,betac_bias,betac_rmse,crossprod_rel_err,fit_seconds,error")
    for seed in s0:s1
        rng = Xoshiro(300_000 + seed)
        Y = draw_Y(rng)
        row = try
            t = @elapsed fit = fit_one(Y)
            bz = fit.βz; bc = fit.βc; Lam = fit.Λc
            cerr = norm(Lam * Lam' - Lambda_true * Lambda_true') / norm(Lambda_true * Lambda_true')
            join([family, p, n, seed, fit.converged, fit.loglik,
                  mean(bz .- betaz_true), sqrt(mean((bz .- betaz_true) .^ 2)),
                  mean(bc .- betac_true), sqrt(mean((bc .- betac_true) .^ 2)),
                  cerr, round(t, digits = 3), ""], ",")
        catch err
            join([family, p, n, seed, "error", "NaN", "NaN", "NaN", "NaN", "NaN", "NaN", "NaN",
                  replace(sprint(showerror, err)[1:min(end, 120)], "," => ";")], ",")
        end
        println(io, row)
        flush(io)
    end
end
println("ZI_ADEMP_CHUNK_DONE $family p=$p n=$n seeds=$s0:$s1")
