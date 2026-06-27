# Predictor-informed latent-score (X_lv) recovery study.
#
# Correctly-specified generative model (matches what the estimator assumes):
#     z_total[s] = X_lv[s] * alpha  +  z_s,     z_s ~ N(0, 1)   (UNIT innovation)
#     eta[t, s]  = beta[t] + Lambda[t] * z_total[s]
# Estimand: B_lv = Lambda * alpha'  (rotation/sign-stable for K = 1).
#
# For each family we draw S independent datasets at each sample size n, fit
# through the user-facing `bridge_fit` (default warm start, NO truth inits), and
# measure the bias and RMSE of the recovered B_lv against the data-generating
# truth. Sweeping n demonstrates that any residual bias is finite-n Laplace bias
# (shrinks ~1/sqrt(n)), not a structural defect.
#
#   LV_REC_N="160,320,640"  LV_REC_S=40  julia --project=. bench/lv_recovery.jl

using GLLVM
using Random, Statistics, LinearAlgebra, Distributions, Printf

const P      = 5
const K      = 1
const LAMBDA = [0.5, -0.4, 0.3, 0.25, -0.2]
const ALPHA  = 0.6
const B_TRUE = LAMBDA .* ALPHA                       # p-vector (K = q_lv = 1)

xlv_grid(n) = reshape(collect(range(-1.1, 1.1; length = n)), n, 1)

function eta_matrix(beta, n, X_lv, rng)
    z_total = vec(X_lv .* ALPHA) .+ randn(rng, n)    # UNIT innovation
    return beta .+ LAMBDA * reshape(z_total, 1, n)   # p x n
end

gen_gaussian(rng, n, X_lv) =
    (Float64.(eta_matrix(zeros(P), n, X_lv, rng) .+ 0.3 .* randn(rng, P, n)), (;))

function gen_binomial(rng, n, X_lv, link)
    eta = eta_matrix([-0.6, -0.25, 0.05, 0.35, 0.65], n, X_lv, rng)
    mu  = clamp.(GLLVM.linkinv.(Ref(link), eta), 1e-4, 1 - 1e-4)
    N   = fill(40, P, n)
    Y   = [rand(rng, Binomial(N[t, s], mu[t, s])) for t in 1:P, s in 1:n]
    return (Float64.(Y), (; N = N))
end

function gen_poisson(rng, n, X_lv)
    eta = eta_matrix(log.([6.0, 4.0, 8.0, 5.0, 7.0]), n, X_lv, rng)
    return (Float64.([rand(rng, Poisson(exp(eta[t, s]))) for t in 1:P, s in 1:n]), (;))
end

function gen_nb2(rng, n, X_lv)
    eta = eta_matrix(log.([6.0, 4.0, 8.0, 5.0, 7.0]), n, X_lv, rng); r = 10.0
    return (Float64.([rand(rng, NegativeBinomial(r, r / (r + exp(eta[t, s])))) for t in 1:P, s in 1:n]), (;))
end

function gen_gamma(rng, n, X_lv)
    eta = eta_matrix(log.([2.0, 1.5, 3.0, 2.5, 1.8]), n, X_lv, rng); a = 6.0
    return (Float64.([rand(rng, Gamma(a, exp(eta[t, s]) / a)) for t in 1:P, s in 1:n]), (;))
end

function gen_beta(rng, n, X_lv)
    eta = eta_matrix([0.3, -0.5, 0.6, -0.2, 0.4], n, X_lv, rng); phi = 15.0
    mu  = 1.0 ./ (1.0 .+ exp.(-eta))
    return (Float64.([rand(rng, Beta(mu[t, s] * phi, (1 - mu[t, s]) * phi)) for t in 1:P, s in 1:n]), (;))
end

const ROUTES = [
    ("gaussian",         (r, n, x) -> gen_gaussian(r, n, x),                "gaussian"),
    ("binomial_logit",   (r, n, x) -> gen_binomial(r, n, x, LogitLink()),  "binomial"),
    ("binomial_probit",  (r, n, x) -> gen_binomial(r, n, x, ProbitLink()), "binomial_probit"),
    ("binomial_cloglog", (r, n, x) -> gen_binomial(r, n, x, CLogLogLink()),"binomial_cloglog"),
    ("poisson",          (r, n, x) -> gen_poisson(r, n, x),                "poisson"),
    ("negbinomial",      (r, n, x) -> gen_nb2(r, n, x),                     "negbinomial"),
    ("gamma",            (r, n, x) -> gen_gamma(r, n, x),                   "gamma"),
    ("beta",             (r, n, x) -> gen_beta(r, n, x),                    "beta"),
]

function run_route(label, genf, family, n, X_lv, S)
    ests = Vector{Vector{Float64}}(); cors = Float64[]; nfail = 0
    for s in 1:S
        rng = MersenneTwister(20260 + 991 * s + 7 * n)
        y, kw = genf(rng, n, X_lv)
        bhat = try
            vec(bridge_fit(; y = y, family = family, d = K, X_lv = X_lv, kw...).lv_effects)
        catch err
            nothing
        end
        if bhat === nothing || length(bhat) != P || any(!isfinite, bhat)
            nfail += 1; continue
        end
        push!(ests, bhat); push!(cors, cor(bhat, B_TRUE))
    end
    nok = length(ests)
    if nok == 0
        @printf("  %-17s  FAILED all %d fits\n", label, S); flush(stdout); return nothing
    end
    aligned = [c < 0 ? -e : e for (e, c) in zip(ests, cors)]
    nflip   = count(<(0), cors)
    E       = reduce(hcat, aligned)
    bias    = vec(mean(E .- B_TRUE; dims = 2))
    rmse    = vec(sqrt.(mean((E .- B_TRUE) .^ 2; dims = 2)))
    @printf("  %-17s ok=%2d/%2d flip=%d  meanbias=% .4f maxbias=% .4f  rmse=%.4f  mean|cor|=%.3f\n",
            label, nok, S, nflip, mean(bias), maximum(abs, bias), mean(rmse), mean(abs.(cors)))
    flush(stdout)
    return (; label, n, bias, rmse, nok, nflip)
end

const NS = [parse(Int, strip(s)) for s in split(get(ENV, "LV_REC_N", "160"), ",")]
const S  = parse(Int, get(ENV, "LV_REC_S", "40"))

println("LV X_lv recovery study | p=$P K=$K S=$S  (unit innovation; bridge_fit default warm start)")
println("B_true = ", round.(B_TRUE; digits = 3))
for n in NS
    X_lv = xlv_grid(n)
    println("="^100)
    println("n = $n")
    for (label, genf, family) in ROUTES
        run_route(label, genf, family, n, X_lv, S)
    end
end
println("="^100)
println("done")
