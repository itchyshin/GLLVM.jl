# speed_bench.jl — "speed against myself" benchmark for GLLVM.jl
# =============================================================================
#
# A self-contained wall-clock + allocation benchmark for the GLLVM.jl fitters.
# It quantifies fit speed (median seconds) and memory (MB allocated) across a
# small grid of problem sizes and response families, and — crucially — times
# the GLM families with `gradient = :finite` vs `gradient = :analytic` side by
# side so the maintainer can decide whether to flip the default gradient.
#
# HOW TO RUN
# ----------
#     julia --project=. bench/speed_bench.jl
#
# (Uses the root project; the same way `bench/grad_speedup.jl` loads GLLVM.)
#
# WHAT IT MEASURES
# ----------------
#   * Base timing only — `@elapsed`-style via `Base.@timed` for wall-clock AND
#     bytes. No BenchmarkTools dependency. Each fit runs a warm-up (untimed,
#     to exclude compilation) then `REPS` timed reps; we report the MEDIAN.
#   * For the GLM families (Poisson / NB / Binomial / Beta / Gamma) it runs
#     BOTH `gradient = :finite` and `gradient = :analytic` and prints:
#       - seconds and MB for each variant,
#       - the speedup ratio (finite / analytic),
#       - |loglik_finite − loglik_analytic| so you can SEE accuracy is
#         preserved (the analytic gradient should land on the same optimum).
#     The :analytic vs :finite columns are exactly the evidence needed to
#     decide whether to make `:analytic` the package default.
#   * Gaussian (closed-form marginal, no Laplace, no gradient kwarg) is timed
#     once as a baseline.
#   * One `confint(fit, Y; method = :profile, parm = "beta[1]")` per count
#     family at the smallest grid size, to time the profile-CI path.
#
# Each family/gradient/CI combo is wrapped in try/catch: a failure prints a
# NOTE row and the sweep continues rather than aborting.
#
# NOT RUN IN CI. This is maintainer tooling (needs a Julia runtime and takes a
# few minutes); it is intentionally excluded from the test suite.
#
# Absolute numbers are machine-dependent; the ratios and Δloglik are the
# portable, decision-relevant outputs.
# =============================================================================

using GLLVM, Random, Statistics, Printf

# ----------------------------------------------------------------------------
# Timing helpers (Base only)
# ----------------------------------------------------------------------------

const REPS = 3   # timed reps per fit (median reported). Keep modest: a full
                 # sweep should be a few minutes, not an hour.

"""
    timed_median(f; reps = REPS) -> (seconds, megabytes, value)

Run `f` once untimed (warm-up / compilation), then `reps` timed times.
Returns the MEDIAN wall-clock seconds, the MEDIAN allocated megabytes
(both via `Base.@timed`), and the value returned by the last call (so the
caller can inspect e.g. `.loglik`).
"""
function timed_median(f; reps::Int = REPS)
    f()                                   # warm-up (exclude compile cost)
    secs = Float64[]
    mbs  = Float64[]
    val  = nothing
    for _ in 1:reps
        t = Base.@timed f()
        push!(secs, t.time)
        push!(mbs, t.bytes / 2^20)        # bytes → MiB
        val = t.value
    end
    return (median(secs), median(mbs), val)
end

# A fit result's maximised loglik. Gaussian uses `.logLik`; the GLM family
# fits use `.loglik`. Centralise so the table logic stays clean.
_loglik(fit) = hasproperty(fit, :loglik) ? fit.loglik :
               hasproperty(fit, :logLik) ? fit.logLik : NaN

# ----------------------------------------------------------------------------
# Simulators — one per family, at configurable (p, n, K).
# `p` = number of species (rows), `n` = number of sites (cols), `K` = #LVs.
# All seeded for reproducibility; each returns a (p × n) response matrix
# (plus N for the binomial case).
# ----------------------------------------------------------------------------

# GLLVM re-exports Distributions; reach the constructors without an extra dep.
const _D = GLLVM.Distributions
_safe_pois(λ)     = _D.Poisson(max(λ, 0.0))
_safe_gamma(a, θ) = _D.Gamma(max(a, 1e-3), max(θ, 1e-8))
_safe_beta(a, b)  = _D.Beta(max(a, 1e-3), max(b, 1e-3))

"""
    _latent(p, n, K; seed, βscale, λscale) -> (Λ, η0, rng)

Shared latent structure: lower-triangular loadings Λ (positive diagonal for
identifiability), per-site scores z ~ N(0, I_K), and a baseline linear
predictor η0 = β + Λ z with modest intercepts. Returned η0 is (p × n).
"""
function _latent(p::Int, n::Int, K::Int; seed::Int, βscale::Float64 = 0.0,
                 λscale::Float64 = 0.6)
    rng = MersenneTwister(seed)
    Λ = λscale .* randn(rng, p, K)
    for i in 1:p, k in 1:K
        i < k && (Λ[i, k] = 0.0)          # lower-triangular
    end
    for k in 1:min(p, K)
        Λ[k, k] = abs(Λ[k, k]) + 0.5      # positive diagonal
    end
    β = βscale .* randn(rng, p)
    Z = randn(rng, K, n)
    η0 = β .+ Λ * Z                        # (p × n)
    return (Λ, η0, rng)
end

function sim_gaussian(p, n, K; seed = 1)
    _, η0, rng = _latent(p, n, K; seed = seed, βscale = 1.0)
    return η0 .+ randn(rng, p, n)          # identity link + N(0,1) noise
end

function sim_poisson(p, n, K; seed = 2)
    _, η0, rng = _latent(p, n, K; seed = seed, βscale = 0.5, λscale = 0.4)
    μ = exp.(clamp.(η0, -10, 4))           # log link; clamp to avoid huge rates
    return [Int(rand(rng, _safe_pois(μ[t, i]))) for t in 1:p, i in 1:n]
end

function sim_nb(p, n, K; seed = 3, r = 5.0)
    _, η0, rng = _latent(p, n, K; seed = seed, βscale = 0.5, λscale = 0.4)
    μ = exp.(clamp.(η0, -10, 4))           # log link
    # NB2 via Gamma–Poisson mixture: λ ~ Gamma(r, μ/r), y ~ Poisson(λ).
    out = Matrix{Int}(undef, p, n)
    for t in 1:p, i in 1:n
        λ = rand(rng, _safe_gamma(r, μ[t, i] / r))
        out[t, i] = Int(rand(rng, _safe_pois(λ)))
    end
    return out
end

function sim_binomial(p, n, K; seed = 4, Ntrials = 10)
    _, η0, rng = _latent(p, n, K; seed = seed, βscale = 0.0, λscale = 0.7)
    prob = 1.0 ./ (1.0 .+ exp.(-η0))       # logit link
    Y = [Int(sum(rand(rng) < prob[t, i] for _ in 1:Ntrials)) for t in 1:p, i in 1:n]
    N = fill(Ntrials, p, n)
    return (Y, N)
end

function sim_beta(p, n, K; seed = 5, φ = 8.0)
    _, η0, rng = _latent(p, n, K; seed = seed, βscale = 0.0, λscale = 0.6)
    μ = 1.0 ./ (1.0 .+ exp.(-η0))          # logit link → mean in (0,1)
    Y = Matrix{Float64}(undef, p, n)
    for t in 1:p, i in 1:n
        a = μ[t, i] * φ; b = (1 - μ[t, i]) * φ
        Y[t, i] = clamp(rand(rng, _safe_beta(a, b)), 1e-4, 1 - 1e-4)
    end
    return Y
end

function sim_gamma(p, n, K; seed = 6, α = 4.0)
    _, η0, rng = _latent(p, n, K; seed = seed, βscale = 0.5, λscale = 0.4)
    μ = exp.(clamp.(η0, -6, 6))            # log link → positive mean
    Y = Matrix{Float64}(undef, p, n)
    for t in 1:p, i in 1:n
        Y[t, i] = rand(rng, _safe_gamma(α, μ[t, i] / α))  # mean = α·(μ/α) = μ
    end
    return Y
end

# ----------------------------------------------------------------------------
# Result-row collection + table printing
# ----------------------------------------------------------------------------

struct Row
    size::String
    family::String
    variant::String
    seconds::Float64
    mb::Float64
    dll::Float64        # loglik − reference loglik (NaN if no reference / N/A)
    note::String
end

const ROWS = Row[]

push_row!(size, fam, variant, secs, mb, dll; note = "") =
    push!(ROWS, Row(size, fam, variant, secs, mb, dll, note))

function print_table()
    println("\n", "="^98)
    println("RESULTS  (median of $REPS timed reps; warm-up excluded)")
    println("="^98)
    @printf("%-12s %-9s %-12s %10s %10s %13s  %s\n",
            "size", "family", "variant", "seconds", "MB alloc", "Δloglik", "note")
    println("-"^98)
    for r in ROWS
        s = isnan(r.seconds) ? "         —" : @sprintf("%10.4f", r.seconds)
        m = isnan(r.mb)      ? "         —" : @sprintf("%10.2f", r.mb)
        d = isnan(r.dll)     ? "            —" : @sprintf("%13.3e", r.dll)
        @printf("%-12s %-9s %-12s %s %s %s  %s\n",
                r.size, r.family, r.variant, s, m, d, r.note)
    end
    println("-"^98)
    println("Δloglik for GLM families = loglik(:analytic) − loglik(:finite) within a")
    println("size×family cell; ~0 means :analytic reaches the same optimum.")
    println("="^98)
end

# ----------------------------------------------------------------------------
# Per-family benchmarking
# ----------------------------------------------------------------------------

_errsummary(err) = first(split(sprint(showerror, err), '\n'))

# Time a GLM family at :finite and :analytic; report both + speedup + Δloglik.
# `mkfit(grad)` must return a zero-arg closure that performs the fit.
# Returns (fit_finite_or_nothing,) so the caller can chain a profile CI.
function bench_glm_family!(sz, fam, mkfit)
    ll_finite = NaN
    finite_secs = NaN
    fit_fd = nothing
    # --- finite reference ---
    try
        s, m, fit = timed_median(mkfit(:finite))
        fit_fd = fit
        ll_finite = _loglik(fit)
        finite_secs = s
        push_row!(sz, fam, ":finite", s, m, NaN)
    catch err
        push_row!(sz, fam, ":finite", NaN, NaN, NaN;
                  note = "NOTE failed: $(_errsummary(err))")
    end
    # --- analytic candidate/current default, depending on family ---
    try
        s, m, fit = timed_median(mkfit(:analytic))
        dll = isnan(ll_finite) ? NaN : _loglik(fit) - ll_finite
        spd = (isfinite(finite_secs) && s > 0) ? finite_secs / s : NaN
        note = isnan(spd) ? "" : @sprintf("speedup %.2fx vs :finite", spd)
        push_row!(sz, fam, ":analytic", s, m, dll; note = note)
    catch err
        push_row!(sz, fam, ":analytic", NaN, NaN, NaN;
                  note = "NOTE failed: $(_errsummary(err))")
    end
    return fit_fd
end

# Time one profile CI for beta[1] on a given (already-fit) GLM result.
function bench_profile_ci!(sz, fam, fit, Y; kw...)
    fit === nothing && return
    try
        s, m, _ = timed_median(() ->
            confint(fit, Y; method = :profile, parm = "beta[1]", kw...))
        push_row!(sz, fam, "profileCI", s, m, NaN; note = "parm=beta[1]")
    catch err
        push_row!(sz, fam, "profileCI", NaN, NaN, NaN;
                  note = "NOTE failed: $(_errsummary(err))")
    end
end

# ----------------------------------------------------------------------------
# Driver
# ----------------------------------------------------------------------------

# (p = species, n = sites, K = latent dims). Modest sizes keep the full run to
# a few minutes; bump these once you trust the script.
const GRID = [(20, 100, 2), (50, 200, 2), (100, 300, 2)]

# Cap optimiser iterations so a single fit can't run away on a hard cell.
const ITERS = 300

function main()
    println("GLLVM.jl speed benchmark — Base timing, no BenchmarkTools")
    println("grid (p, n, K): ", GRID, "   reps: ", REPS, "   iterations cap: ", ITERS)
    println("Julia ", VERSION, "   threads: ", Threads.nthreads())

    for (p, n, K) in GRID
        sz = "$(p)x$(n)x$(K)"
        @info "Benchmarking size $sz (p=$p species, n=$n sites, K=$K LVs)"

        # --- Gaussian: closed-form marginal, single baseline (no gradient kwarg) ---
        try
            Yg = sim_gaussian(p, n, K)
            s, m, _ = timed_median(() -> fit_gaussian_gllvm(Yg; K = K))
            push_row!(sz, "Gaussian", "closed", s, m, NaN)
        catch err
            push_row!(sz, "Gaussian", "closed", NaN, NaN, NaN;
                      note = "NOTE failed: $(_errsummary(err))")
        end

        # --- Poisson ---
        Yp = sim_poisson(p, n, K)
        fit_p = bench_glm_family!(sz, "Poisson",
            g -> () -> fit_poisson_gllvm(Yp; K = K, gradient = g, iterations = ITERS))

        # --- Negative Binomial ---
        Yn = sim_nb(p, n, K)
        fit_n = bench_glm_family!(sz, "NB",
            g -> () -> fit_nb_gllvm(Yn; K = K, gradient = g, iterations = ITERS))

        # --- Binomial ---
        Yb, Nb = sim_binomial(p, n, K)
        fit_b = bench_glm_family!(sz, "Binomial",
            g -> () -> fit_binomial_gllvm(Yb; K = K, N = Nb, gradient = g, iterations = ITERS))

        # --- Beta ---
        Ybe = sim_beta(p, n, K)
        bench_glm_family!(sz, "Beta",
            g -> () -> fit_beta_gllvm(Ybe; K = K, gradient = g, iterations = ITERS))

        # --- Gamma ---
        Yga = sim_gamma(p, n, K)
        bench_glm_family!(sz, "Gamma",
            g -> () -> fit_gamma_gllvm(Yga; K = K, gradient = g, iterations = ITERS))

        # --- one profile CI per count family, at the smallest size only ---
        # (Profile CI re-fits per bracket point — the slow path. One cell is
        # enough to time it.)
        if (p, n, K) == first(GRID)
            bench_profile_ci!(sz, "Poisson", fit_p, Yp)
            bench_profile_ci!(sz, "NB",       fit_n, Yn)
            bench_profile_ci!(sz, "Binomial", fit_b, Yb; N = Nb)
        end
    end

    print_table()

    println("""

    DECISION GUIDE
    --------------
    Compare each family's :finite vs :analytic rows:
      * speedup column = how much faster the analytic-gradient fit is;
      * Δloglik column = accuracy gap (want ~0, i.e. same optimum).
    If :analytic is consistently faster AND Δloglik stays at noise level, it is
    safe to make that family's default `gradient = :analytic`. See
    bench/SPEED_NOTES.md for the current default decision and broader speed roadmap.
    """)
end

main()
