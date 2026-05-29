# Standalone validation of the single-variance branch random-effects (incidence
# form) phylogenetic model. Run via:
#
#   julia --project=. -e 'using GLLVM; include("test/test_phylo_branch_re.jl")'
#
# NOT wired into runtests.jl (matching the constraint not to touch runtests.jl).
# Pulls the new src files in directly, after `using GLLVM`, exactly as
# test_relaxed_clock.jl / test_edge_incidence.jl do.

using GLLVM, Test, Random, LinearAlgebra, SparseArrays, Statistics

include(joinpath(@__DIR__, "..", "src", "edge_incidence.jl"))
include(joinpath(@__DIR__, "..", "src", "phylo_branch_re.jl"))
# Augmented-precision (Hadfield–Nakagawa) path for the head-to-head, and the
# sparse-phy marginal log-lik that drives it.
include(joinpath(@__DIR__, "..", "src", "sparse_phy.jl"))
include(joinpath(@__DIR__, "..", "src", "likelihood_sparse_phy.jl"))

# ---------------------------------------------------------------------------
# Helpers.
# ---------------------------------------------------------------------------

"Balanced binary tree Newick string with `p` leaves and constant branch length."
function _newick_balanced(p::Integer; bl::Real = 0.3)
    p > 1 || error("p must be > 1")
    nodes = ["L$(t):" * string(bl) for t in 1:p]
    while length(nodes) > 1
        nn = String[]
        i = 1
        while i + 1 <= length(nodes)
            push!(nn, "(" * nodes[i] * "," * nodes[i+1] * "):" * string(bl))
            i += 2
        end
        i == length(nodes) && push!(nn, nodes[i])
        nodes = nn
    end
    return nodes[1] * ";"
end

_balanced_edge_phy(p; bl = 0.3) = edge_phy(_newick_balanced(p; bl = bl))

# branch-RE marginal log-likelihood at FIXED μ (no profiling) — the form the
# head-to-head needs so it is the exact same model as the HN intercept-free path
# evaluated on (y − μ).
function _bre_loglik_fixed_mu(cache::BranchRECache, y::AbstractVector,
                              σ²::Real, σ²_eps::Real, μ::Real)
    nll, _ = branch_re_profile_negll(cache, y, σ², σ²_eps)   # nll uses GLS μ̂…
    # …so recompute the quadratic at the supplied fixed μ instead.
    inv_eps = 1.0 / σ²_eps
    Λ = inv_eps .* cache.ZtZ
    d = 1.0 ./ (σ² .* cache.ℓ)
    @inbounds for e in 1:cache.E
        Λ[e, e] += d[e]
    end
    cΛ = cholesky(Symmetric(Λ))
    r = y .- μ
    Sinv_r = inv_eps .* r .- (inv_eps^2) .* (cache.Z * (cΛ \ (cache.Z' * r)))
    quad = dot(r, Sinv_r)
    logdetΣ = cache.p * log(σ²_eps) + logdet(cΛ) +
              (cache.E * log(σ²) + cache.sum_log_ℓ)
    return -0.5 * (cache.p * log(2π) + logdetΣ + quad)
end

@testset "single-variance branch-RE phylo model" begin

    # -----------------------------------------------------------------------
    # A. Incidence form is exactly the BM covariance, sparse Woodbury == dense.
    # -----------------------------------------------------------------------
    @testset "incidence V == BM covariance; sparse negll == dense" begin
        phy = edge_phy("((A:0.1,B:0.2):0.3,(C:0.4,D:0.5):0.1);")
        Z = path_membership(phy)
        # Z is 0/1, p × E, one row per leaf path.
        @test size(Z) == (phy.n_leaves, phy.n_edges)
        @test all(in((0.0, 1.0)), Z)
        # V = Z diag(ℓ) Zᵀ equals the edge-incidence BM covariance (rate 1).
        V = Matrix(Z * spdiagm(0 => phy.branch_lengths) * Z')
        @test maximum(abs.(V .- sigma_phy_dense_edge(phy, 1.0))) < 1e-12

        # Sparse Woodbury profile negll matches a dense brute-force marginal.
        cache = branch_re_cache(phy)
        rng = MersenneTwister(1)
        y = randn(rng, phy.n_leaves) .* 2 .+ 1.5
        σ², σ²_eps = 1.3, 0.4
        Σ = σ² .* V
        @inbounds for i in 1:phy.n_leaves
            Σ[i, i] += σ²_eps
        end
        one_p = ones(phy.n_leaves)
        μ_bf = dot(one_p, Σ \ y) / dot(one_p, Σ \ one_p)
        r = y .- μ_bf
        negll_bf = 0.5 * (phy.n_leaves * log(2π) + logdet(Σ) + dot(r, Σ \ r))
        negll_sp, μ_sp = branch_re_profile_negll(cache, y, σ², σ²_eps)
        @test negll_sp ≈ negll_bf atol = 1e-9
        @test μ_sp ≈ μ_bf atol = 1e-10

        # BLUPs match the dense conditional mean ẑ = D Zᵀ Σ⁻¹ (y − μ).
        D = σ² .* phy.branch_lengths
        ẑ_bf = D .* (Z' * (Σ \ (y .- μ_sp)))
        ẑ, _, _ = branch_blups(cache, y, σ², σ²_eps, μ_sp)
        @test maximum(abs.(ẑ .- ẑ_bf)) < 1e-9
    end

    # -----------------------------------------------------------------------
    # HEAD-TO-HEAD: branch-RE incidence vs Hadfield–Nakagawa augmented precision.
    # GATE: identical log-likelihood at p = 100 to ~1e-8 (same model, two sparse
    # representations). Timing lives in bench/phylo_branch_re_bench.jl.
    # -----------------------------------------------------------------------
    @testset "HEAD-TO-HEAD: branch-RE == Hadfield–Nakagawa log-lik (p=100)" begin
        nwk = _newick_balanced(100; bl = 0.4)
        ephy = edge_phy(nwk)
        aphy = augmented_phy(nwk)
        cache = branch_re_cache(ephy)
        rng = MersenneTwister(100)
        σ², σ²_eps, μ = 1.0, 0.5, 1.0
        y, _ = simulate_branch_re(ephy, σ², σ²_eps, 1; rng = rng, μ = μ)
        yv = vec(y)

        ll_bre = _bre_loglik_fixed_mu(cache, yv, σ², σ²_eps, μ)
        ll_hn = gaussian_marginal_loglik_sparse_phy(
            reshape(yv .- μ, 100, 1), zeros(100, 0), sqrt(σ²_eps);
            σ_phy = fill(sqrt(σ²), 100), phy = aphy, σ²_phy = 1.0)
        @test abs(ll_bre - ll_hn) < 1e-8
    end

    # -----------------------------------------------------------------------
    # GATE 1: SINGLE-TRAIT IDENTIFIABILITY. ML recovers σ² AND σ²_eps from ONE
    # trait (n_rep = 1), over ~50 sims, within Monte-Carlo error.
    # This is exactly what the relaxed-clock work WRONGLY said needed n_rep ≥ 30.
    # -----------------------------------------------------------------------
    @testset "GATE 1: single-trait (n_rep=1) recovery of σ² and σ²_eps" begin
        rng = MersenneTwister(20260529)
        p = 256
        σ²_true, σ²_eps_true = 1.0, 0.5
        phy = _balanced_edge_phy(p; bl = 0.5)
        nsim = 50
        σ²hat = Float64[]; σ²epshat = Float64[]; μhat = Float64[]
        for _ in 1:nsim
            y, _ = simulate_branch_re(phy, σ²_true, σ²_eps_true, 1; rng = rng, μ = 3.0)
            fit = fit_branch_re(phy, vec(y))
            push!(σ²hat, fit.σ²); push!(σ²epshat, fit.σ²_eps); push!(μhat, fit.μ)
        end
        # Median across sims recovers both variances; the MC SE of the mean is
        # sd/√nsim, so the mean should sit within a few SE of truth.
        se_σ²  = std(σ²hat)  / sqrt(nsim)
        se_eps = std(σ²epshat) / sqrt(nsim)
        @test abs(median(σ²hat)  - σ²_true)     < 0.20
        @test abs(median(σ²epshat) - σ²_eps_true) < 0.10
        @test abs(mean(σ²hat)  - σ²_true)     < 4 * se_σ²  + 0.05
        @test abs(mean(σ²epshat) - σ²_eps_true) < 4 * se_eps + 0.03
        @test abs(mean(μhat) - 3.0) < 0.3
        @info "GATE 1 (n_rep=1, p=$p, $nsim sims)" σ²_mean=round(mean(σ²hat),digits=3) σ²_median=round(median(σ²hat),digits=3) σ²_sd=round(std(σ²hat),digits=3) σ²eps_mean=round(mean(σ²epshat),digits=3) σ²eps_median=round(median(σ²epshat),digits=3) σ²eps_sd=round(std(σ²epshat),digits=3)
    end

    # -----------------------------------------------------------------------
    # GATE 2: BLUP RATE DETECTION FROM ONE TRAIT. Plant a fast-evolving clade
    # (variable-rate TRUTH), fit the SINGLE-rate model, extract branch BLUPs,
    # show the fast-clade standardized increments are elevated vs background
    # from ONE trait. Report the effect size.
    # -----------------------------------------------------------------------
    @testset "GATE 2: branch BLUPs detect a planted fast clade (one trait)" begin
        rng = MersenneTwister(424242)
        p = 256
        phy = _balanced_edge_phy(p; bl = 0.5)
        # Pick a clade of ~p/8 leaves and inflate its edge rates.
        clade_root = find_clade_root(phy; target_leaves = p ÷ 8)
        fast = clade_edges(phy, clade_root)
        slow = setdiff(1:phy.n_edges, fast)
        σ²_bg, fast_mult = 1.0, 12.0
        rate = fill(σ²_bg, phy.n_edges)
        rate[fast] .*= fast_mult                       # planted rate shift

        # Accumulate detection across a handful of independent single traits to
        # report a stable effect size; EACH fit uses ONE trait (n_rep = 1).
        ds = Float64[]; ts = Float64[]; zs = Float64[]
        for _ in 1:20
            y, _ = simulate_branch_re(phy, σ²_bg, 0.2, 1; rng = rng,
                                      μ = 0.0, σ²_e = rate)
            fit = fit_branch_re(phy, vec(y))
            # |standardized increment| is the per-branch rate signal.
            a = abs.(fit.std_incr[fast]); b = abs.(fit.std_incr[slow])
            t, _, d = welch_t(a, b)
            push!(ts, t); push!(ds, d); push!(zs, rank_sum_z(a, b))
        end
        # From ONE trait the fast clade is detected: positive effect size and a
        # significant rank-sum z on the great majority of single-trait fits.
        @test median(ds) > 0.5                         # at least a medium effect
        @test median(ts) > 2.0                         # Welch t clears ~2
        @test mean(zs .> 1.96) > 0.7                   # rank test significant ≥70%
        @info "GATE 2 (one trait each, 20 reps, fast clade $(length(fast)) edges, ×$(fast_mult))" cohen_d_median=round(median(ds),digits=2) welch_t_median=round(median(ts),digits=2) ranksum_z_median=round(median(zs),digits=2) frac_sig=round(mean(zs .> 1.96),digits=2)
    end

    # -----------------------------------------------------------------------
    # GATE 3: POSTERIOR-vs-PRIOR. When the truth has rate variation, the
    # posterior (BLUP) standardized increments depart from the Gaussian prior
    # (excess kurtosis / QQ departure), whereas under a single-rate truth they
    # do not. One trait.
    # -----------------------------------------------------------------------
    @testset "GATE 3: posterior departs from Gaussian prior under rate variation" begin
        rng = MersenneTwister(31337)
        p = 512
        phy = _balanced_edge_phy(p; bl = 0.5)
        clade_root = find_clade_root(phy; target_leaves = p ÷ 8)
        fast = clade_edges(phy, clade_root)
        rate_var = fill(1.0, phy.n_edges); rate_var[fast] .*= 15.0

        kurt_var = Float64[]; kurt_null = Float64[]
        qq_var = Float64[]; qq_null = Float64[]
        for _ in 1:20
            # variable-rate truth
            yv, _ = simulate_branch_re(phy, 1.0, 0.1, 1; rng = rng, σ²_e = rate_var)
            fv = fit_branch_re(phy, vec(yv))
            push!(kurt_var, excess_kurtosis(fv.std_incr))
            push!(qq_var, qq_max_dev(fv.std_incr))
            # single-rate (null) truth, same machinery
            yn, _ = simulate_branch_re(phy, 1.0, 0.1, 1; rng = rng)
            fn = fit_branch_re(phy, vec(yn))
            push!(kurt_null, excess_kurtosis(fn.std_incr))
            push!(qq_null, qq_max_dev(fn.std_incr))
        end
        # Rate variation inflates the posterior tails relative to the null.
        @test median(kurt_var) > median(kurt_null)
        @test median(kurt_var) > 0.5                   # clearly leptokurtic
        @test median(qq_var) > median(qq_null)
        @info "GATE 3 (one trait each, 20 reps)" excess_kurtosis_varrate=round(median(kurt_var),digits=2) excess_kurtosis_null=round(median(kurt_null),digits=2) qq_maxdev_varrate=round(median(qq_var),digits=3) qq_maxdev_null=round(median(qq_null),digits=3)
    end

    # -----------------------------------------------------------------------
    # GATE 4 (sanity at test scale): the sparse never-densify fit is correct and
    # the sparse log-lik matches the dense reference. Empirical scaling slope is
    # reported by the benchmark, not asserted here. We check sparse == dense fit.
    # -----------------------------------------------------------------------
    @testset "GATE 4 sanity: sparse fit == dense-V reference fit" begin
        rng = MersenneTwister(55)
        phy = _balanced_edge_phy(64; bl = 0.5)
        y, _ = simulate_branch_re(phy, 1.0, 0.4, 1; rng = rng, μ = 2.0)
        yv = vec(y)
        fs = fit_branch_re(phy, yv)
        fd = fit_branch_re_dense(phy, yv)
        @test fs.σ²     ≈ fd.σ²     rtol = 1e-3
        @test fs.σ²_eps ≈ fd.σ²_eps rtol = 1e-3
        @test fs.μ      ≈ fd.μ      rtol = 1e-4
        @test maximum(abs.(fs.ẑ .- fd.ẑ)) < 1e-4 * (maximum(abs.(fd.ẑ)) + 1e-6)
    end

end
