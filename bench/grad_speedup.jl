# Benchmark: opt-in analytic Laplace gradient vs the finite-difference gradient,
# across the GLM families. Run from the repo root with the package available, e.g.
#
#     julia --project=. bench/grad_speedup.jl
#
# Reports, per family, the median wall-clock fit time for gradient=:finite vs
# :analytic and the speedup, plus the maximised-loglik difference (should be ~0 —
# same optimum, faster/exact gradient). Timing is wall-clock (@elapsed) with a
# warm-up to exclude compilation; absolute numbers are machine-dependent.
#
# This measures the INTERNAL speedup. The cross-language comparison vs R's gllvmTMB
# (timing + loglik parity per ADEMP cell) needs an R + gllvmTMB runtime — see the
# companion harness note at the bottom — and is the runtime-session piece of #65.

using GLLVM, Random, Statistics

_med_time(f; reps = 5) = begin
    f()                                   # warm-up (compile)
    median(@elapsed(f()) for _ in 1:reps)
end

function bench_family(name, fit_fd, fit_an)
    r_fd = fit_fd(); r_an = fit_an()      # results for loglik comparison
    t_fd = _med_time(fit_fd)
    t_an = _med_time(fit_an)
    dll  = abs(r_fd.loglik - r_an.loglik)
    @printf("%-10s  finite %8.4fs   analytic %8.4fs   speedup %5.2fx   |Δloglik| %.2e\n",
            name, t_fd, t_an, t_fd / t_an, dll)
end

using Printf

function main()
    Random.seed!(20260605)
    p, K, n = 12, 2, 200                  # moderate p — where the 2·nθ FD factor bites
    println("Analytic vs finite-difference gradient — fit wall-clock (p=$p, K=$K, n=$n)\n")

    Yp = rand(0:6, p, n)
    bench_family("Poisson",
                 () -> fit_poisson_gllvm(Yp; K = K, iterations = 300),
                 () -> fit_poisson_gllvm(Yp; K = K, gradient = :analytic, iterations = 300))

    Nb = fill(8, p, n); Yb = [rand(0:8) for _ in 1:p, _ in 1:n]
    bench_family("Binomial",
                 () -> fit_binomial_gllvm(Yb; K = K, N = Nb, iterations = 300),
                 () -> fit_binomial_gllvm(Yb; K = K, N = Nb, gradient = :analytic, iterations = 300))

    Yn = rand(0:10, p, n)
    bench_family("NB",
                 () -> fit_nb_gllvm(Yn; K = K, iterations = 300),
                 () -> fit_nb_gllvm(Yn; K = K, gradient = :analytic, iterations = 300))

    Yg = 0.5 .+ 2 .* rand(p, n)
    bench_family("Gamma",
                 () -> fit_gamma_gllvm(Yg; K = K, iterations = 300),
                 () -> fit_gamma_gllvm(Yg; K = K, gradient = :analytic, iterations = 300))

    Ybe = clamp.(rand(p, n), 0.02, 0.98)
    bench_family("Beta",
                 () -> fit_beta_gllvm(Ybe; K = K, iterations = 300),
                 () -> fit_beta_gllvm(Ybe; K = K, gradient = :analytic, iterations = 300))

    println("\nNote: the analytic gradient does one mode solve + one ForwardDiff pass per")
    println("step; the finite-difference gradient does ~2·nθ marginal evaluations, so the")
    println("speedup grows with the parameter count nθ = p + p·K (− triangular) + dispersion.")
end

main()
