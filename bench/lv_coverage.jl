# Wald interval COVERAGE for the predictor-informed latent-score effects B_lv.
#
# Same correctly-specified generative model as bench/lv_recovery.jl (unit
# innovation). For each of S datasets we fit NATIVELY with the default warm start
# (no truth inits), build the 95% Wald interval with confint_lv_effects, and
# record whether each true B_lv[t] falls inside. A calibrated interval covers at
# the nominal rate (~0.95). Gaussian is omitted (its X_lv CI path is separate).
#
#   LV_COV_N=200 LV_COV_S=80 julia --project=. bench/lv_coverage.jl

using GLLVM
using Random, Statistics, LinearAlgebra, Distributions, Printf

const P      = 5
const K      = 1
const LAMBDA = [0.5, -0.4, 0.3, 0.25, -0.2]
const ALPHA  = 0.6
const B_TRUE = LAMBDA .* ALPHA
const LEVEL  = 0.95

xlv_grid(n) = reshape(collect(range(-1.1, 1.1; length = n)), n, 1)

function eta_matrix(beta, n, X_lv, rng)
    z_total = vec(X_lv .* ALPHA) .+ randn(rng, n)
    return beta .+ LAMBDA * reshape(z_total, 1, n)
end

# each route: (label, generate -> (Y, N or nothing), fit -> fit, needs_N)
function fit_pois(Y, X_lv, N); fit_poisson_gllvm(Y; K = K, X_lv = X_lv, iterations = 300, g_tol = 1e-6); end
function fit_binom(Y, X_lv, N, link); fit_binomial_gllvm(Y; K = K, N = N, link = link, X_lv = X_lv, iterations = 250, g_tol = 1e-6); end
function fit_nb(Y, X_lv, N); fit_nb_gllvm(Y; K = K, X_lv = X_lv, iterations = 300, g_tol = 1e-6); end
function fit_gam(Y, X_lv, N); fit_gamma_gllvm(Y; K = K, X_lv = X_lv, iterations = 300, g_tol = 1e-6); end
function fit_bet(Y, X_lv, N); fit_beta_gllvm(Y; K = K, X_lv = X_lv, iterations = 300, g_tol = 1e-6); end

function gen_binomial(rng, n, X_lv, link)
    eta = eta_matrix([-0.6, -0.25, 0.05, 0.35, 0.65], n, X_lv, rng)
    mu  = clamp.(GLLVM.linkinv.(Ref(link), eta), 1e-4, 1 - 1e-4)
    N   = fill(40, P, n)
    Y   = [rand(rng, Binomial(N[t, s], mu[t, s])) for t in 1:P, s in 1:n]
    return (Float64.(Y), N)
end
function gen_poisson(rng, n, X_lv)
    eta = eta_matrix(log.([6.0,4.0,8.0,5.0,7.0]), n, X_lv, rng)   # eta ONCE (shared z_s)
    return (Float64.([rand(rng, Poisson(exp(eta[t,s]))) for t in 1:P, s in 1:n]), nothing)
end
function gen_nb2(rng, n, X_lv)
    eta = eta_matrix(log.([6.0,4.0,8.0,5.0,7.0]), n, X_lv, rng); r=10.0
    (Float64.([rand(rng, NegativeBinomial(r, r/(r+exp(eta[t,s])))) for t in 1:P, s in 1:n]), nothing)
end
function gen_gamma(rng, n, X_lv)
    eta = eta_matrix(log.([2.0,1.5,3.0,2.5,1.8]), n, X_lv, rng); a=6.0
    (Float64.([rand(rng, Gamma(a, exp(eta[t,s])/a)) for t in 1:P, s in 1:n]), nothing)
end
function gen_beta(rng, n, X_lv)
    eta = eta_matrix([0.3,-0.5,0.6,-0.2,0.4], n, X_lv, rng); phi=15.0
    mu = 1.0 ./ (1.0 .+ exp.(-eta))
    (Float64.([rand(rng, Beta(mu[t,s]*phi, (1-mu[t,s])*phi)) for t in 1:P, s in 1:n]), nothing)
end

routes = [
    ("binomial_logit",   (r,n,x)->gen_binomial(r,n,x,LogitLink()),   (Y,x,N)->fit_binom(Y,x,N,LogitLink())),
    ("binomial_probit",  (r,n,x)->gen_binomial(r,n,x,ProbitLink()),  (Y,x,N)->fit_binom(Y,x,N,ProbitLink())),
    ("binomial_cloglog", (r,n,x)->gen_binomial(r,n,x,CLogLogLink()), (Y,x,N)->fit_binom(Y,x,N,CLogLogLink())),
    ("poisson",          (r,n,x)->gen_poisson(r,n,x),                fit_pois),
    ("negbinomial",      (r,n,x)->gen_nb2(r,n,x),                    fit_nb),
    ("gamma",            (r,n,x)->gen_gamma(r,n,x),                  fit_gam),
    ("beta",             (r,n,x)->gen_beta(r,n,x),                   fit_bet),
]

function run_route(label, genf, fitf, n, X_lv, S)
    covered = 0; total = 0; widths = Float64[]; nok = 0; npd = 0
    pertrait = zeros(Int, P); pertrait_tot = zeros(Int, P)
    for s in 1:S
        rng = MersenneTwister(31415 + 977 * s + 13 * n)
        Y, N = genf(rng, n, X_lv)
        ci = try
            fit = fitf(Y, X_lv, N)
            fit.converged ? confint_lv_effects(fit, Y, X_lv; N = N, level = LEVEL) : nothing
        catch err
            nothing
        end
        ci === nothing && continue
        nok += 1
        ci.pd_hessian && (npd += 1)
        ci.pd_hessian || continue
        for t in 1:P
            lo, hi = ci.lower[t], ci.upper[t]
            (isfinite(lo) && isfinite(hi)) || continue
            inside = (lo <= B_TRUE[t] <= hi)
            covered += inside; total += 1
            pertrait[t] += inside; pertrait_tot[t] += 1
            push!(widths, hi - lo)
        end
    end
    if total == 0
        @printf("  %-17s  no usable CIs (ok=%d/%d pd=%d)\n", label, nok, S, npd); flush(stdout); return nothing
    end
    cov = covered / total
    @printf("  %-17s ok=%2d/%2d pd=%2d  coverage=%.3f (%d/%d)  meanwidth=%.4f  pertrait=[%s]\n",
            label, nok, S, npd, cov, covered, total, mean(widths),
            join([@sprintf("%.2f", pertrait[t]/max(pertrait_tot[t],1)) for t in 1:P], " "))
    flush(stdout)
    return (; label, cov, n, total)
end

const N0 = parse(Int, get(ENV, "LV_COV_N", "200"))
const S  = parse(Int, get(ENV, "LV_COV_S", "80"))
X_lv = xlv_grid(N0)
println("LV X_lv Wald-interval coverage | p=$P n=$N0 K=$K S=$S level=$LEVEL  (default warm start)")
println("B_true = ", round.(B_TRUE; digits = 3))
println("="^100)
for (label, genf, fitf) in routes
    run_route(label, genf, fitf, N0, X_lv, S)
end
println("="^100); println("done")
