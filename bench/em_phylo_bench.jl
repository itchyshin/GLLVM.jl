# Benchmark the gradient-free EM fit for the Gaussian phylo_unique GLLVM.
# Run via:
#
#     julia --project=bench bench/em_phylo_bench.jl
#
# Two honest measurements:
#
#   (1) PER-E-STEP CORE SOLVE. The E-step's dominant linear-algebra cost is
#       applying (A + n B)⁻¹ to vectors, where A = Λ_B Λ_B' + σ²_eps I and
#       B = diag(σ_phy) Σ_phy diag(σ_phy). We time:
#         * DENSE: form (A + n B) explicitly, dense Cholesky, then solve.
#                  O(p³) — the cost the gradient-based dense fit pays per
#                  evaluation, and what the reference E-step pays per iter.
#         * SPARSE (amortised): `solve_AnB` reusing a pre-built augmented-state
#                  saddle-point factorisation. O(p) per solve — this is the
#                  fast sparse phylo path repurposed for the EM E-step.
#         * SPARSE (build + solve): include the per-E-step factorisation cost.
#       Reported at p ∈ {100, 500, 1000}.
#
#   (2) FULL EM CONVERGENCE. Total wall-clock and iteration count for a real
#       `em_fit_phylo` to converge on an interior fixture, at p ∈ {100, 500}.
#       HONEST CAVEAT: the EM driver here uses the DENSE E-step (it forms a
#       dense p×p posterior covariance V_φ, O(p³)/iter) because the dense path
#       is what the correctness gate verifies. EM's well-known slow-tail
#       convergence means MANY iterations — total time, not per-iter time, is
#       what matters. The sparse (A+nB)⁻¹ solve in (1) shows the O(p) E-step
#       core is available; wiring it (plus a selected-inverse for diag(V_φ))
#       into the driver to kill the O(p³)/iter term is left as the obvious
#       next step.

using BenchmarkTools
using Random
using LinearAlgebra
using SparseArrays
using Statistics
using GLLVM

# em_phylo.jl is not wired into the GLLVM module (PERF+++++ hard constraint:
# do NOT modify src/GLLVM.jl). Pull it in directly; it references the loaded
# GLLVM module for `gaussian_marginal_loglik`, `ppca_init`, `AugmentedPhy`.
include(joinpath(@__DIR__, "..", "src", "em_phylo.jl"))

const SEED = 30

# Build a representative interior fixture for a given p.
function make_fixture(p; K_B = 1, n = 200, σ_phy_scale = 0.9, σ_eps = 0.5)
    Random.seed!(SEED)
    phy   = GLLVM.random_balanced_tree(p; branch_length = 0.1)
    Σ_phy = GLLVM.sigma_phy_dense(phy; σ²_phy = 1.0)
    Λ_B   = randn(p, K_B)
    for k in 1:K_B, i in 1:(k - 1)
        Λ_B[i, k] = 0.0
    end
    σ_phy = fill(σ_phy_scale, p)
    η_B   = randn(K_B, n)
    φ     = cholesky(Symmetric(Σ_phy)).L * randn(p)
    z     = σ_phy .* φ
    y     = Λ_B * η_B .+ reshape(z, p, 1) .+ σ_eps .* randn(p, n)
    return (; phy, Σ_phy, Λ_B, σ_phy, σ_eps, y, n)
end

println("=" ^ 72)
println("(1) PER-E-STEP CORE SOLVE: (A + n B)⁻¹ · rhs   [K_B = 1, n = 200]")
println("=" ^ 72)
println(rpad("p", 8), rpad("dense (ms)", 14), rpad("sparse amort (ms)", 20),
        rpad("sparse+build (ms)", 20), "speedup (amort)")
println("-" ^ 72)

for p in (100, 500, 1000)
    fx = make_fixture(p)
    A   = fx.Λ_B * fx.Λ_B' + fx.σ_eps^2 * I
    Bm  = (fx.σ_phy * fx.σ_phy') .* fx.Σ_phy
    rhs = randn(p)

    # DENSE: form (A + n B), Cholesky, solve (the per-iter dense E-step cost).
    t_dense = @belapsed begin
        AnB = $A .+ $(fx.n) .* $Bm
        cF  = cholesky(Symmetric((AnB + AnB') ./ 2))
        cF \ $rhs
    end seconds = 2

    # SPARSE amortised: pre-build the saddle factorisation, time only the solve.
    solver = build_AnB_sparse(fx.Λ_B, fx.σ_eps, fx.σ_phy, fx.phy, fx.n)
    t_sparse_amort = @belapsed solve_AnB($solver, $rhs) seconds = 2

    # SPARSE build + solve: include the per-E-step factorisation.
    t_sparse_build = @belapsed begin
        s = build_AnB_sparse($(fx.Λ_B), $(fx.σ_eps), $(fx.σ_phy), $(fx.phy), $(fx.n))
        solve_AnB(s, $rhs)
    end seconds = 2

    speedup = t_dense / t_sparse_amort
    println(rpad(string(p), 8),
            rpad(string(round(t_dense * 1e3, digits = 3)), 14),
            rpad(string(round(t_sparse_amort * 1e3, digits = 4)), 20),
            rpad(string(round(t_sparse_build * 1e3, digits = 3)), 20),
            string(round(speedup, digits = 1), "x"))
end

println()
println("=" ^ 72)
println("(2) FULL EM CONVERGENCE  [em_fit_phylo, dense E-step, K_B = 1]")
println("=" ^ 72)
println(rpad("p", 8), rpad("n", 8), rpad("iters", 10), rpad("total (s)", 14),
        rpad("ms/iter", 12), "converged")
println("-" ^ 72)

for (p, n) in ((100, 200), (500, 200))
    fx = make_fixture(p; n = n)
    # Warmup (JIT) on the same shapes.
    em_fit_phylo(fx.y, 1, fx.Σ_phy; tol = 1e-8, max_iter = 5)

    t0  = time()
    emf = em_fit_phylo(fx.y, 1, fx.Σ_phy; tol = 1e-9, max_iter = 50_000)
    dt  = time() - t0

    ms_per_iter = 1e3 * dt / max(emf.n_iter, 1)
    println(rpad(string(p), 8), rpad(string(n), 8),
            rpad(string(emf.n_iter), 10),
            rpad(string(round(dt, digits = 3)), 14),
            rpad(string(round(ms_per_iter, digits = 3)), 12),
            string(emf.converged))
end

println()
println("Notes:")
println("  * (1) shows the sparse augmented-state (A+nB)⁻¹ solve is O(p) and")
println("    increasingly outpaces the dense O(p³) Cholesky as p grows.")
println("  * (2) total time is dominated by EM iteration COUNT (slow tail) and")
println("    the dense E-step's O(p³) per-iter cost. The sparse solve in (1)")
println("    is the drop-in to remove the latter; the former is intrinsic EM.")
