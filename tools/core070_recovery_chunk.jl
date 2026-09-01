# DRAC recovery-campaign chunked worker: one Julia process runs a contiguous
# seed range for one cell, amortizing the ~20s compile the pre-run measured
# per single-seed task. DGP identical to core070_recovery_seed.jl (cell-pinned
# truth, per-seed draws); adds the beta family per the campaign draft.
#
# argv: family(gaussian|poisson|nbinom2|binomial|beta) p n seed_start seed_end outdir
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
cell_rng = Xoshiro(7000 + 13 * p + n)
Lambda_true = 0.5 .* randn(cell_rng, p, K)
beta_true = 0.3 .* randn(cell_rng, p)
sigma_true = 0.7
phi_true = 10.0

_loglik(fit) = hasproperty(fit, :logLik) ? fit.logLik : fit.loglik
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
    elseif family == "beta"
        return [clamp(rand(rng, GLLVM.Distributions.Beta(_inv_logit(eta[i, j]) * phi_true,
                                                         (1 - _inv_logit(eta[i, j])) * phi_true)),
                      1e-6, 1 - 1e-6) for i in 1:p, j in 1:n]
    else
        error("unknown family $family")
    end
end

function fit_one(Y)
    if family == "gaussian"
        X = zeros(p, n, p)
        for j in 1:p
            X[j, :, j] .= 1
        end
        return GLLVM.fit_gaussian_gllvm(float.(Y); K = K, X = X)
    elseif family == "poisson"
        return GLLVM.fit_poisson_gllvm(Int.(Y); K = K)
    elseif family == "nbinom2"
        return GLLVM.fit_nb_gllvm(Int.(Y); K = K)
    elseif family == "binomial"
        return GLLVM.fit_binomial_gllvm(Int.(Y); K = K)
    else
        return GLLVM.fit_beta_gllvm(float.(Y); K = K)
    end
end

outfile = joinpath(outdir, "chunk-$(family)-p$(p)-n$(n)-s$(lpad(s0, 4, '0')).csv")
open(outfile, "w") do io
    println(io, "family,p,n,seed,converged,loglik,crossprod_rel_err,beta_rmse,fit_seconds,error")
    for seed in s0:s1
        rng = Xoshiro(100_000 + seed)
        Y = draw_Y(rng)
        row = try
            t = @elapsed fit = fit_one(Y)
            Lam_hat = hasproperty(fit, :Λ) ? fit.Λ :
                      hasproperty(fit, :pars) && haskey(fit.pars, :Λ) ? fit.pars.Λ : nothing
            C_err = Lam_hat === nothing ? NaN :
                    norm(Lam_hat * Lam_hat' - Lambda_true * Lambda_true') / norm(Lambda_true * Lambda_true')
            beta_hat = hasproperty(fit, :β) ? fit.β :
                       hasproperty(fit, :pars) && haskey(fit.pars, :β) ? vec(fit.pars.β) : fill(NaN, p)
            conv = hasproperty(fit, :converged) ? fit.converged : missing
            join([family, p, n, seed, conv, _loglik(fit), C_err,
                  sqrt(mean((beta_hat .- beta_true) .^ 2)), round(t, digits = 3), ""], ",")
        catch err
            # a failed fit is a recorded outcome, never a dropped seed (ADEMP)
            join([family, p, n, seed, "error", "NaN", "NaN", "NaN", "NaN",
                  replace(sprint(showerror, err)[1:min(end, 120)], "," => ";")], ",")
        end
        println(io, row)
        flush(io)
    end
end
println("RECOVERY_CHUNK_DONE $family p=$p n=$n seeds=$s0:$s1")
