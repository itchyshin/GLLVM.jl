# DRAC recovery-campaign per-seed worker (ADEMP; one seed per SLURM array task).
# Draft/design: docs/dev-log/plans/2026-09-01-drac-recovery-campaign-draft.md.
# src/simulate.jl is a placeholder in this lane, so the DGP is pinned HERE:
# Lambda_true drawn once per cell from a cell-derived seed; per-seed latent
# and noise draws from the task seed. K=2, per-trait intercepts beta_true.
#
# argv: family(p_gaussian|poisson|nbinom2|binomial) p n seed outdir
using GLLVM
using Random
using LinearAlgebra
using Statistics

family = ARGS[1]
p = parse(Int, ARGS[2])
n = parse(Int, ARGS[3])
seed = parse(Int, ARGS[4])
outdir = ARGS[5]
mkpath(outdir)

K = 2
cell_rng = Xoshiro(7000 + 13 * p + n)          # cell-pinned truth
Lambda_true = 0.5 .* randn(cell_rng, p, K)
beta_true = 0.3 .* randn(cell_rng, p)
sigma_true = 0.7

rng = Xoshiro(100_000 + seed)                   # per-seed draws
eta = Lambda_true * randn(rng, K, n) .+ beta_true
Y = if family == "gaussian"
    eta .+ sigma_true .* randn(rng, p, n)
elseif family == "poisson"
    [rand(rng, GLLVM.Distributions.Poisson(exp(min(eta[i, j], 4.0)))) for i in 1:p, j in 1:n]
elseif family == "nbinom2"
    [rand(rng, GLLVM.Distributions.NegativeBinomial(2.0, 2.0 / (2.0 + exp(min(eta[i, j], 4.0))))) for i in 1:p, j in 1:n]
elseif family == "binomial"
    [rand(rng) < 1 / (1 + exp(-eta[i, j])) ? 1 : 0 for i in 1:p, j in 1:n]
else
    error("unknown family $family")
end

_loglik(fit) = hasproperty(fit, :logLik) ? fit.logLik : fit.loglik

t = @elapsed fit = if family == "gaussian"
    X = zeros(p, n, p)
    for j in 1:p
        X[j, :, j] .= 1
    end
    GLLVM.fit_gaussian_gllvm(float.(Y); K = K, X = X)
elseif family == "poisson"
    GLLVM.fit_poisson_gllvm(Int.(Y); K = K)
elseif family == "nbinom2"
    GLLVM.fit_nb_gllvm(Int.(Y); K = K)
else
    GLLVM.fit_binomial_gllvm(Int.(Y); K = K)
end

# Sign/rotation-invariant recovery measures only (never signed loadings).
Lam_hat = hasproperty(fit, :Λ) ? fit.Λ :
          hasproperty(fit, :pars) && haskey(fit.pars, :Λ) ? fit.pars.Λ :
          nothing
C_err = Lam_hat === nothing ? NaN :
        norm(Lam_hat * Lam_hat' - Lambda_true * Lambda_true') / norm(Lambda_true * Lambda_true')
beta_hat = hasproperty(fit, :β) ? fit.β :
           hasproperty(fit, :pars) && haskey(fit.pars, :β) ? vec(fit.pars.β) : fill(NaN, p)
beta_rmse = sqrt(mean((beta_hat .- beta_true) .^ 2))
conv = hasproperty(fit, :converged) ? fit.converged : missing

open(joinpath(outdir, "seed-$(lpad(seed, 4, '0')).csv"), "w") do io
    println(io, "family,p,n,seed,converged,loglik,crossprod_rel_err,beta_rmse,fit_seconds,julia_version")
    println(io, join([family, p, n, seed, conv, _loglik(fit), C_err, beta_rmse,
                      round(t, digits = 3), string(VERSION)], ","))
end
println("RECOVERY_SEED_DONE $family p=$p n=$n seed=$seed conv=$conv")
