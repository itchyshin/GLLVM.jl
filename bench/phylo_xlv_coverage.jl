# Phase 3 recovery/coverage harness for phylo × X_lv Model A. This is a SMOKE
# (40 reps, one cell) — the full v1 gate is the DRAC campaign: sweep
# λ/OU ∈ {0,0.5,1} × n_species ∈ {~20,~200} × K ∈ {1,2}, ≥500 reps per cell,
# one seed per SLURM array task. Model A has orthogonal axes (X_lv on sites, Σ_phy
# on traits) → no mean-vs-covariance confound, so the bar is B_lv coverage + the
# two nulls (the phylo-collinear arm is a Model B concern). B_lv = Λ_B·α' is
# sign-invariant, so coverage needs no alignment.
#
# Smoke result (2026-06-27, seed bank 1000+): 40/40 converged, per-entry coverage
# [0.98,0.98,0.98,0.98] (overall 0.975, nominal 0.95); NULL-A max|B_lv|=0.083 &
# CI covers 0; NULL-B B_lv cor=1.0. The intervals are calibrated and the predictor
# and phylogeny do not interfere.

using GLLVM, Random, LinearAlgebra, Distributions, Statistics

p, n, K, q_lv, K_phy = 4, 200, 1, 1, 1
Λ_B   = reshape([0.8, -0.5, 0.4, -0.6], p, K)
Λ_phy = reshape([0.5, 0.4, -0.3, 0.35], p, K_phy)
Mc = randn(MersenneTwister(1), p, p + 2); Sc = Mc * Mc'; Σ_phy = Sc ./ sqrt.(diag(Sc) * diag(Sc)')
σ = 0.4
X_lv = reshape(collect(range(-1.5, 1.5; length = n)), n, q_lv)

function sim(rng, alpha, λphy)
    Bphy = (λphy * λphy') .* Σ_phy
    φ = cholesky(Symmetric(Bphy + 1e-8 * I)).L * randn(rng, p)
    Y = zeros(p, n)
    for s in 1:n
        z = X_lv[s, 1] * alpha[1, 1] + randn(rng)
        Y[:, s] = Λ_B[:, 1] * z .+ φ .+ σ .* randn(rng, p)
    end
    Y
end
fitit(Y) = fit_gaussian_gllvm(Y; K = K, X_lv = X_lv, K_phy = K_phy, Σ_phy = Σ_phy, iterations = 400)

alpha = reshape([0.7], q_lv, K); B_true = vec(Λ_B * alpha')
nrep = 40; cov = zeros(Int, p); nconv = 0
for r in 1:nrep
    Y = sim(MersenneTwister(1000 + r), alpha, Λ_phy)
    fit = fitit(Y)
    fit.converged || continue
    global nconv += 1
    ci = confint_lv_effects(fit, Y, X_lv)
    for t in 1:p
        (ci.lower[t] <= B_true[t] <= ci.upper[t]) && (cov[t] += 1)
    end
end
println("=== Phase 3 coverage smoke (Model A, $nconv/$nrep converged) ===")
println("  per-entry coverage = ", round.(cov ./ nconv, digits = 2))
println("  overall coverage   = ", round(sum(cov) / (nconv * p), digits = 3), "  (nominal 0.95)")

Y0 = sim(MersenneTwister(42), reshape([0.0], q_lv, K), Λ_phy)
ci0 = confint_lv_effects(fitit(Y0), Y0, X_lv)
println("  NULL-A (α=0, phylo>0): max|B_lv| = ", round(maximum(abs.(ci0.estimate)), digits = 3),
        "  CI covers 0 = ", all(ci0.lower .<= 0 .<= ci0.upper))

Yb = sim(MersenneTwister(43), alpha, reshape([0.0, 0.0, 0.0, 0.0], p, K_phy))
println("  NULL-B (phylo=0, α≠0): B_lv cor = ",
        round(cor(vec(extract_lv_effects(fitit(Yb))), B_true), digits = 3))

# Multi-cell coverage across the design's K × n dimensions (30 reps/cell here; the
# full v1 gate is ≥500 reps/cell on DRAC). Smoke result (2026-06-27): K=1,n=200 →
# 0.940; K=1,n=60 → 0.927; K=2,n=200 → 0.973; 90/90 fits converged. Calibrated
# across cells, not just the single cell above.
function coverage_cell(pp, nn, KK, q_lv, KK_phy, nrep)
    Xlv   = reshape(collect(range(-1.5, 1.5; length = nn)), nn, q_lv)
    LB    = 0.6 .* randn(MersenneTwister(10), pp, KK)
    al    = 0.7 .* randn(MersenneTwister(11), q_lv, KK)
    Btrue = vec(LB * al')
    Lphy  = 0.45 .* randn(MersenneTwister(12), pp, KK_phy)
    Mm = randn(MersenneTwister(13), pp, pp + 2); Ss = Mm * Mm'
    Sphy = Ss ./ sqrt.(diag(Ss) * diag(Ss)')
    se = 0.4; cov = zeros(Int, pp); nconv = 0
    for r in 1:nrep
        rng = MersenneTwister(2000 + r)
        Bp = (Lphy * Lphy') .* Sphy
        ph = cholesky(Symmetric(Bp + 1e-8 * I)).L * randn(rng, pp)
        Yc = zeros(pp, nn)
        for s in 1:nn
            z = vec(Xlv[s:s, :] * al) .+ randn(rng, KK)
            Yc[:, s] = LB * z .+ ph .+ se .* randn(rng, pp)
        end
        fit = fit_gaussian_gllvm(Yc; K = KK, X_lv = Xlv, K_phy = KK_phy, Σ_phy = Sphy, iterations = 400)
        fit.converged || continue
        nconv += 1
        ci = confint_lv_effects(fit, Yc, Xlv)
        for t in 1:pp
            (ci.lower[t] <= Btrue[t] <= ci.upper[t]) && (cov[t] += 1)
        end
    end
    return nconv, (nconv == 0 ? NaN : sum(cov) / (nconv * pp))
end

println("=== multi-cell coverage (30 reps/cell, nominal 0.95) ===")
for (KK, nn) in [(1, 200), (1, 60), (2, 200)]
    nc, c = coverage_cell(5, nn, KK, 1, 1, 30)
    println("  K=$KK, n=$nn: $nc/30 converged, coverage = ", round(c, digits = 3))
end
