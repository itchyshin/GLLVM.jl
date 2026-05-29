# =============================================================================
# Coverage simulation for *derived bounded quantities* of a Gaussian GLLVM:
#   transformed-Wald  vs  profile  vs  bootstrap
# =============================================================================
#
# Scientific question
# -------------------
# bench/coverage_sim.jl established that, for the SD parameters, a Wald CI
# built on the LOG scale and back-transformed (`exp(log σ̂ ± z·SE_log)`)
# reaches ~nominal 95% coverage — and the bootstrap is actually *worse* for
# σ_eps / σ_phy. The derived bounded quantities (cross-trait correlation
# ρ ∈ [−1,1], communality c² ∈ [0,1], phylogenetic signal H² ∈ [0,1]) only
# had the expensive profile / bootstrap CIs. src/confint_derived_wald.jl
# adds a cheap transformed-scale Wald CI (Fisher-z for ρ, logit for [0,1]
# quantities). This script asks the natural follow-up:
#
#   Does the cheap transformed-Wald CI reach nominal 95% coverage for these
#   bounded derived quantities, matching the expensive profile / bootstrap?
#
# It runs a Monte-Carlo coverage simulation from KNOWN truth over a phylo
# and a non-phylo cell and, per (derived quantity × method), reports the
# coverage proportion ± Monte-Carlo SE.
#
# Methods
#   transformed-Wald = GLLVM.transformed_wald_ci_derived   (1 Hessian; cheap)
#   profile          = GLLVM.profile_ci_derived            (constrained refits)
#   bootstrap        = GLLVM.bootstrap_ci_derived          (n_boot refits)
#
# Derived quantities (scalar)
#   ρ[i,j]  — a cross-trait correlation (Fisher-z transformed-Wald)
#   c²[t]   — a per-trait communality   (logit transformed-Wald)
#   H²[t]   — per-trait phylo signal    (logit; phylo cell only)
#
# Truth (per-site covariance convention of sigma_y_site: the phylo block is
# NOT part of the per-site covariance)
#   Σ_true = Λ_B Λ_B' + σ_eps² · I
#   ρ_true[i,j] = (Λ_B Λ_B')[i,j] / sqrt(Σ_ii · Σ_jj)
#   c²_true[t]  = (Λ_B Λ_B')[t,t] / Σ_tt
#   H²_true[t]  = σ_phy² · diagΣphy[t] / Σ_tt   (diagΣphy = 1, standardised)
#
# Run
#   julia --project=bench bench/coverage_derived.jl
#
# Budget knobs (environment variables, optional):
#   COVDER_NREPS   Monte-Carlo replicates per cell      (default 100)
#   COVDER_NBOOT   bootstrap resamples per fit          (default 199)
#   COVDER_CELLS   comma-sep cell indices, e.g. "1"     (default all)
#
# Output: a markdown table (derived quantity × methods × cells) + a verdict,
# printed to stdout. Partial results print as they accrue.
# =============================================================================

using GLLVM
using Random
using LinearAlgebra
using Distributions
using Statistics
using Printf

# The transformed-Wald file is additive (not compiled into the installed
# GLLVM); inject it into the module so GLLVM.transformed_wald_ci_derived &
# the wrappers resolve. Its deps (confint_derived.jl, confint.jl) are
# already compiled in.
if !isdefined(GLLVM, :transformed_wald_ci_derived)
    Base.include(GLLVM, joinpath(@__DIR__, "..", "src", "confint_derived_wald.jl"))
end

# -----------------------------------------------------------------------------
# Cell specification
# -----------------------------------------------------------------------------
struct Cell
    name::String
    phylo::Bool
    p::Int
    n::Int
    σ_eps::Float64
    σ_phy::Float64        # used only when phylo == true
    branch_length::Float64
end

# Deliberately small grid: one non-phylo and one phylo cell, sized so the
# transformed-Wald / profile / bootstrap comparison is reachable in budget.
const CELLS = Cell[
    Cell("nophylo_n200_p6", false, 6, 200, 0.5, 0.0, 0.0),
    Cell("phylo_n200_p6",   true,  6, 200, 0.5, 0.8, 0.5),
]

# -----------------------------------------------------------------------------
# Fixtures: Λ_B (one true latent axis), and (phylo) the tree-derived Σ_phy.
# Built ONCE per cell so the truth is fixed across replicates; only the
# random draws vary per rep. No covariate (q = 0) — the focus here is the
# derived bounded quantities, not β.
# -----------------------------------------------------------------------------
function build_fixture(cell::Cell)
    p = cell.p
    K = 1
    rng0 = MersenneTwister(7_000 + p)
    Λ_B = reshape(0.4 .+ 0.4 .* abs.(randn(rng0, p)), p, K)
    Λ_B[2:2:end] .*= -1.0   # mix signs so it is a genuine factor

    Σ_phy = nothing
    L_phy = nothing
    if cell.phylo
        phy = GLLVM.random_balanced_tree(p; branch_length = cell.branch_length)
        Σ = GLLVM.sigma_phy_dense(phy; σ²_phy = 1.0)
        Σ_phy = Matrix(Symmetric((Σ .+ Σ') ./ 2))
        L_phy = cholesky(Symmetric(Σ_phy)).L
    end
    return (; K, Λ_B, Σ_phy, L_phy)
end

# True per-site covariance Σ_true = Λ_B Λ_B' + σ_eps² I (phylo excluded).
function sigma_true(cell::Cell, fx)
    p = cell.p
    A = fx.Λ_B * fx.Λ_B'
    for t in 1:p
        A[t, t] += cell.σ_eps^2
    end
    return A
end

# -----------------------------------------------------------------------------
# Derived-quantity targets for a cell: (label, kind, index-tuple, truth,
# transform). We pick indices whose TRUE value is comfortably interior so the
# transformed link is well-defined and all three methods test the same
# estimand. `kind` ∈ {:correlation, :communality, :phylo_signal}.
# -----------------------------------------------------------------------------
function targets(cell::Cell, fx)
    Σ = sigma_true(cell, fx)
    ΛΛt = fx.Λ_B * fx.Λ_B'
    p = cell.p

    # --- pick a correlation pair (i, j) with |ρ_true| comfortably interior ---
    best_pair = (1, 2); best_ρ = 0.0
    for j in 1:p, i in 1:(j - 1)
        ρ = ΛΛt[i, j] / sqrt(Σ[i, i] * Σ[j, j])
        if 0.15 < abs(ρ) < 0.85 && abs(ρ) > abs(best_ρ)
            best_pair = (i, j); best_ρ = ρ
        end
    end
    i, j = best_pair
    ρ_true = ΛΛt[i, j] / sqrt(Σ[i, i] * Σ[j, j])

    # --- pick a communality trait with c²_true comfortably interior ---
    c2 = [ΛΛt[t, t] / Σ[t, t] for t in 1:p]
    t_c2 = argmin(abs.(c2 .- 0.5))   # closest to 0.5 → most interior
    c2_true = c2[t_c2]

    out = Any[
        (label = "ρ[$i,$j]", kind = :correlation, idx = (i, j),
         truth = ρ_true, transform = :fisher_z),
        (label = "c²[$t_c2]", kind = :communality, idx = (t_c2,),
         truth = c2_true, transform = :logit),
    ]

    if cell.phylo
        # H²_true[t] = σ_phy² · diagΣphy[t] / Σ_tt (diagΣphy standardised = 1).
        diagΣphy = diag(fx.Σ_phy)
        h2 = [cell.σ_phy^2 * diagΣphy[t] / Σ[t, t] for t in 1:p]
        t_h2 = argmin(abs.(h2 .- 0.5))
        push!(out, (label = "H²[$t_h2]", kind = :phylo_signal, idx = (t_h2,),
                    truth = h2[t_h2], transform = :logit))
    end
    return out
end

# -----------------------------------------------------------------------------
# Simulate one data matrix y from KNOWN truth.
#   y[:,s] = Λ_B·η_s + (phylo: σ_phy·φ, shared across sites) + σ_eps·ε_s
# -----------------------------------------------------------------------------
function simulate_y(cell::Cell, fx, rng::AbstractRNG)
    p, n = cell.p, cell.n
    K = fx.K
    y = fx.Λ_B * randn(rng, K, n)
    if cell.phylo
        φ = cell.σ_phy .* (fx.L_phy * randn(rng, p))
        for s in 1:n, t in 1:p
            y[t, s] += φ[t]
        end
    end
    y .+= cell.σ_eps .* randn(rng, p, n)
    return y
end

# -----------------------------------------------------------------------------
# Build the packed-θ closure for a derived target on a given fit's spec.
# -----------------------------------------------------------------------------
function closure_for(target, spec, diagΣphy)
    if target.kind === :correlation
        i, j = target.idx
        return GLLVM._make_correlation_closure(spec, i, j)
    elseif target.kind === :communality
        t = target.idx[1]
        return GLLVM._make_communality_closure(spec, t)
    elseif target.kind === :phylo_signal
        t = target.idx[1]
        return GLLVM._make_phylo_signal_closure(spec, t; diag_Σphy = diagΣphy)
    else
        error("unknown derived kind $(target.kind)")
    end
end

# -----------------------------------------------------------------------------
# CIs for one fit & one target. Returns method => (lo, hi) on the natural
# scale; non-finite / failed → (NaN, NaN), excluded from the denominator.
# -----------------------------------------------------------------------------
function cis_for_target(target, fit, y, Σ_phy; n_boot::Int, boot_seed::Int)
    spec = GLLVM._derived_spec(fit)
    diagΣphy = Σ_phy === nothing ? nothing : diag(Σ_phy)
    f = closure_for(target, spec, diagΣphy)

    out = Dict{Symbol, Tuple{Float64,Float64}}()

    # ---- transformed-Wald ----
    try
        w = GLLVM.transformed_wald_ci_derived(fit, f;
                                              transform = target.transform,
                                              y = y, Σ_phy = Σ_phy)
        out[:twald] = (w.method === :transformed_wald &&
                       isfinite(w.lower) && isfinite(w.upper)) ?
                      (w.lower, w.upper) : (NaN, NaN)
    catch
        out[:twald] = (NaN, NaN)
    end

    # ---- profile ----
    try
        pf = GLLVM.profile_ci_derived(fit, f; y = y, Σ_phy = Σ_phy)
        out[:profile] = (pf.method === :profile &&
                         isfinite(pf.lower) && isfinite(pf.upper)) ?
                        (pf.lower, pf.upper) : (NaN, NaN)
    catch
        out[:profile] = (NaN, NaN)
    end

    # ---- bootstrap ----
    try
        bt = GLLVM.bootstrap_ci_derived(fit, f; y = y, Σ_phy = Σ_phy,
                                        n_boot = n_boot, seed = boot_seed)
        out[:bootstrap] = (isfinite(bt.lower) && isfinite(bt.upper)) ?
                          (bt.lower, bt.upper) : (NaN, NaN)
    catch
        out[:bootstrap] = (NaN, NaN)
    end

    return out
end

# -----------------------------------------------------------------------------
# Run one cell: n_reps replicates, tally coverage per (target × method).
# -----------------------------------------------------------------------------
function run_cell(cell::Cell; n_reps::Int, n_boot::Int)
    fx = build_fixture(cell)
    tgts = targets(cell, fx)
    methods = (:twald, :profile, :bootstrap)
    Σ_phy = cell.phylo ? fx.Σ_phy : nothing

    # counters: target-label => method => [n_covered, n_usable]
    cov = Dict(t.label => Dict(m => [0, 0] for m in methods) for t in tgts)
    n_fit_ok = 0

    println("\n--- Cell $(cell.name)  (phylo=$(cell.phylo), p=$(cell.p), n=$(cell.n), " *
            "n_reps=$n_reps, n_boot=$n_boot) ---")
    for t in tgts
        @printf("    target %-7s truth = %.4f  (%s)\n", t.label, t.truth, t.transform)
    end
    flush(stdout)

    for r in 1:n_reps
        rng = MersenneTwister(500_000 * (cell.phylo ? 2 : 1) + 1000 * cell.p + r)
        y = simulate_y(cell, fx, rng)

        local fit
        try
            fit = fit_gaussian_gllvm(y; K = fx.K,
                                     has_phy_unique = cell.phylo,
                                     Σ_phy = Σ_phy)
        catch
            continue
        end
        fit.converged || continue
        n_fit_ok += 1

        for t in tgts
            cis = cis_for_target(t, fit, y, Σ_phy;
                                 n_boot = n_boot, boot_seed = 7919 * r + cell.p)
            for m in methods
                lo, hi = cis[m]
                if isfinite(lo) && isfinite(hi)
                    cov[t.label][m][2] += 1
                    if lo ≤ t.truth ≤ hi
                        cov[t.label][m][1] += 1
                    end
                end
            end
        end

        if r % 10 == 0 || r == n_reps
            # running coverage on the correlation target (first target)
            lab = tgts[1].label
            w = cov[lab][:twald]; pf = cov[lab][:profile]; b = cov[lab][:bootstrap]
            @printf("  rep %3d/%3d | fits ok %3d | running %s cover  TW=%s P=%s B=%s\n",
                    r, n_reps, n_fit_ok, lab,
                    w[2] > 0 ? @sprintf("%.2f", w[1]/w[2]) : "  - ",
                    pf[2] > 0 ? @sprintf("%.2f", pf[1]/pf[2]) : "  - ",
                    b[2] > 0 ? @sprintf("%.2f", b[1]/b[2]) : "  - ")
            flush(stdout)
        end
    end

    return (; cell, tgts, cov, n_fit_ok)
end

# coverage proportion and Monte-Carlo SE (binomial) from [n_cov, n_use]
function prop_mcse(c::Vector{Int})
    n_cov, n_use = c[1], c[2]
    n_use == 0 && return (NaN, NaN, 0)
    p̂ = n_cov / n_use
    se = sqrt(p̂ * (1 - p̂) / n_use)
    return (p̂, se, n_use)
end

fmt_cell(c::Vector{Int}) = begin
    p̂, se, _ = prop_mcse(c)
    isnan(p̂) ? "  n/a  " : @sprintf("%.2f ± %.2f", p̂, se)
end

# -----------------------------------------------------------------------------
# Markdown report
# -----------------------------------------------------------------------------
function print_markdown(results)
    println("\n", "="^82)
    println("RESULTS — 95% CI coverage for derived bounded quantities " *
            "(proportion ± MCSE, nominal 0.95)")
    println("="^82)
    println()
    println("| Cell | Derived quantity | truth | Transformed-Wald | Profile | Bootstrap | n used (TW/P/B) |")
    println("|------|------------------|-------|------------------|---------|-----------|-----------------|")
    for res in results
        cell = res.cell
        for t in res.tgts
            w = res.cov[t.label][:twald]
            pf = res.cov[t.label][:profile]
            b = res.cov[t.label][:bootstrap]
            @printf("| %s | %s | %.3f | %s | %s | %s | %d/%d/%d |\n",
                    cell.name, t.label, t.truth,
                    fmt_cell(w), fmt_cell(pf), fmt_cell(b),
                    w[2], pf[2], b[2])
        end
    end
    println()
    println("Fits converged per cell:")
    for res in results
        @printf("  %-18s  %d\n", res.cell.name, res.n_fit_ok)
    end
end

# Verdict: does transformed-Wald reach nominal, matching profile / bootstrap?
function print_verdict(results)
    println("\n", "="^82)
    println("VERDICT — does cheap transformed-Wald reach nominal 95% for bounded " *
            "derived quantities?")
    println("="^82)
    for res in results
        for t in res.tgts
            w, _, _ = prop_mcse(res.cov[t.label][:twald])
            pf, _, _ = prop_mcse(res.cov[t.label][:profile])
            b, _, _ = prop_mcse(res.cov[t.label][:bootstrap])
            @printf("  %-18s %-7s  coverage:  Transformed-Wald=%.2f  Profile=%.2f  Bootstrap=%.2f\n",
                    res.cell.name, t.label, w, pf, b)
        end
    end
    println()
end

# -----------------------------------------------------------------------------
# Driver
# -----------------------------------------------------------------------------
function main()
    n_reps = parse(Int, get(ENV, "COVDER_NREPS", "100"))
    n_boot = parse(Int, get(ENV, "COVDER_NBOOT", "199"))
    cell_sel = get(ENV, "COVDER_CELLS", "")
    idxs = isempty(cell_sel) ? collect(1:length(CELLS)) :
           parse.(Int, split(cell_sel, ","))

    println("="^82)
    println("Derived-quantity CI coverage simulation (transformed-Wald / profile / bootstrap)")
    println("n_reps=$n_reps  n_boot=$n_boot  cells=$(idxs)")
    println("="^82)

    t0 = time()
    results = NamedTuple[]
    for i in idxs
        push!(results, run_cell(CELLS[i]; n_reps = n_reps, n_boot = n_boot))
        print_markdown(results)   # incremental so a truncated run is informative
    end
    print_verdict(results)
    @printf("\nTotal wall-clock: %.1f s\n", time() - t0)
    return results
end

main()
