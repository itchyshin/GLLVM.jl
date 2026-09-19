# bench/profile_grouped_glmm.jl — leaf-S4 gate G4.3.
#
# Profiles the grouped-Poisson route `fit_gllvm(Y1; family = Poisson(),
# grouping = [GroupingTerm(:unit; mode = :indep)], unit = group)`, which
# dispatches to `fit_grouped_nongaussian` (src/grouped_nongaussian_fit.jl:272)
# and its joint Laplace kernel `joint_grouped_laplace_loglik`
# (src/grouped_laplace.jl:165-292) — the route Latte.jl beat 12x on this exact
# 200x5 fixture (0.192 s ours vs 0.015 s Latte).
#
# WALL-CLOCK MEASUREMENT: calls the real, unmodified `GLLVModels.fit_gllvm`
# exactly as ~/local-scratch/latte-prerun-20260918/runs/f3_ours_glmm.jl does
# (one untimed warm-up, then >=3 timed reps via `@elapsed`, median reported).
#
# COUNT MEASUREMENT (outer gradient evaluations / inner Newton iterations /
# fresh CHOLMOD symbolic analyses): `fit_grouped_nongaussian` does not expose
# these counts on its returned `GroupedNonGaussianFit`, and `Optim`'s own
# f/g-call counters are internal to a private optimize call we cannot reach
# from outside. So this script builds a byte-for-byte SHADOW of
# `fit_grouped_nongaussian`'s procedure for THIS exact call pattern (Poisson,
# one :indep GroupingTerm, unit=group, no X, no N, default dispersion=:trait,
# default g_tol/iterations/inner_maxiter/inner_tol) — same internal, unexported
# functions (`GLLVModels._grouped_nongaussian_kind`, `_grouped_labels`,
# `_grouped_incidence`, `_trait_mean_design`, `_grouped_nongaussian_initial_
# parameters`, `_grouped_term_unpack`, `_grouped_nongaussian_family`,
# `_grouped_laplace_design`, `joint_grouped_laplace_loglik`,
# `_grouped_fd_gradient`), same Optim calls (NelderMead then BFGS-with-FD-
# gradient refinement), just with a counting objective wrapped around the
# REAL `joint_grouped_laplace_loglik` call. No src/ edit; no re-derivation of
# its ~90-line Newton/line-search body — we call it, we don't reimplement it.
#
# The shadow's own converged loglik is compared to the real `fit_gllvm` call's
# loglik as a faithfulness check (printed; large disagreement invalidates the
# counts, not just the timing).
#
# "Fresh CHOLMOD symbolic analyses" per `joint_grouped_laplace_loglik` call is
# DERIVED from its returned `.iterations` field, not independently instrumented:
# reading src/grouped_laplace.jl:208-291, each of the `.iterations` NON-
# terminal loop passes performs exactly 2 `cholesky(Symmetric(sparse))` calls
# (Ff at :230-236, Fn at :241-245 — a fresh symbolic+numeric CHOLMOD
# factorization each time, since neither reuses a prior symbolic factor), and
# the terminal (converged) pass performs exactly 1 more (Fo at :218-224). So
# for a `status === :ok` result: chol_count = 2*iterations + 1; otherwise
# (non-convergence / failure before the terminal branch): chol_count =
# 2*iterations (AGENT-INFERRED: exact for the dominant :nonconvergence and
# in-loop-failure branches; a `_joint_grouped_failure` returned from inside the
# state/logpost/curvature checks before any cholesky call in that pass would
# overcount by at most 2 for that single pass — negligible against the total).
#
# USAGE
#   env JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --project=. \
#       bench/profile_grouped_glmm.jl --gate

using GLLVModels
using DelimitedFiles, Statistics, LinearAlgebra, Printf
using Distributions: Poisson
using Optim

const REPS = 5

# ---------------------------------------------------------------------------
# Header / provenance helpers (duplicated per leaf-S4's OWNS list).
# ---------------------------------------------------------------------------
function _git_sha()
    try
        strip(read(`git rev-parse --short HEAD`, String))
    catch
        "unknown"
    end
end

function _cpu_brand()
    try
        strip(read(`sysctl -n machdep.cpu.brand_string`, String))
    catch
        string(Sys.MACHINE)
    end
end

function _peak_rss_bytes()
    try
        buf = zeros(UInt8, 160)
        rc = GC.@preserve buf ccall(:getrusage, Cint, (Cint, Ptr{Cvoid}), 0, pointer(buf))
        rc == 0 || return missing
        GC.@preserve buf unsafe_load(Ptr{Int64}(pointer(buf) + 32))
    catch
        missing
    end
end

function header_lines()
    blas = try
        replace(sprint(show, LinearAlgebra.BLAS.get_config()), '\n' => ' ', '\r' => ' ')
    catch
        "unknown"
    end
    return [
        "# git_sha=$(_git_sha())",
        "# julia_version=$(VERSION)",
        "# blas_config=$(blas)",
        "# threads=$(Threads.nthreads())",
        "# os=$(Sys.KERNEL)-$(Sys.MACHINE)",
        "# cpu=$(_cpu_brand())",
        "# peak_rss_bytes=$(_peak_rss_bytes())",
    ]
end

# ---------------------------------------------------------------------------
# CLI (this gate takes no --p; the fixture is fixed at 200x5).
# ---------------------------------------------------------------------------
function parse_args(argv)
    gate = "run"
    for a in argv
        a == "--gate" && (gate = "run")
    end
    return gate
end

# ---------------------------------------------------------------------------
# Fixture — bench/fixtures/glmm_200x5.csv (copied verbatim from the READ-ONLY
# ~/local-scratch/latte-prerun-20260918/data/glmm_200x5.csv: no header, col 1
# = Poisson count, col 2 = group id 1..200).
# ---------------------------------------------------------------------------
function load_fixture()
    path = joinpath(@__DIR__, "fixtures", "glmm_200x5.csv")
    isfile(path) || error("fixture missing: $path (expected a copy of " *
                           "~/local-scratch/latte-prerun-20260918/data/glmm_200x5.csv)")
    M = readdlm(path, ',', Int)
    y = M[:, 1]
    group = M[:, 2]
    G = maximum(group)
    N = length(y)
    return y, group, G, N
end

median_s(f; reps::Int = REPS) = begin
    f()
    ts = [(@elapsed f()) for _ in 1:reps]
    median(ts)
end

# ---------------------------------------------------------------------------
# Shadow-counted replica of `fit_grouped_nongaussian`'s procedure, specialised
# to (family = Poisson(), terms = [GroupingTerm(:unit; mode=:indep)], no X, no
# N, dispersion = :trait [normalises to :none for Poisson], default
# g_tol/iterations/inner_maxiter/inner_tol). Every function called below is
# the real, unexported GLLVModels internal — see src/grouped_nongaussian_fit.jl
# for the original (lines 272-376) this mirrors.
# ---------------------------------------------------------------------------
function shadow_fit_counts(Y1::Matrix{Float64}, group::Vector{Int})
    p, n = size(Y1)
    termvec = GLLVModels.GroupingTerm[GLLVModels.GroupingTerm(:unit; mode = :indep)]
    kind = GLLVModels._grouped_nongaussian_kind(Poisson())          # :poisson
    mode = GLLVModels._grouped_nongaussian_dispersion_mode(kind, :trait)  # :none for Poisson

    labels = GLLVModels._grouped_labels(n, termvec; unit = group, unit_obs = nothing,
                                         cluster = nothing, cluster2 = nothing)
    incidences = [GLLVModels._grouped_incidence(values, n) for values in labels]

    data = Matrix{Float64}(Y1)
    trials = ones(Float64, size(data))   # Poisson: _grouped_nongaussian_trials returns ones
    D = GLLVModels._trait_mean_design(p, n)
    q = size(D, 2)
    source_coordinates = sum(term -> GLLVModels._grouping_term_nparams(term, p), termvec; init = 0)
    dispersion_indices = GLLVModels._grouped_nongaussian_dispersion_indices(q, source_coordinates,
        kind, mode, p)
    expected_len = q + source_coordinates + length(dispersion_indices)

    theta0 = GLLVModels._grouped_nongaussian_initial_parameters(data, trials, D, termvec,
        kind, Poisson(), mode)

    obj_calls = Ref(0)
    inner_iters_sum = Ref(0)
    chol_count = Ref(0)
    ok_calls = Ref(0)
    failed_calls = Ref(0)
    final_inner_status = Ref(:never_ran)

    function counting_objective(value)
        obj_calls[] += 1
        (length(value) == expected_len && all(isfinite, value)) || return GLLVModels._NLL_SENTINEL
        try
            gamma = collect(view(value, 1:q))
            loads, uniques, _, used = GLLVModels._grouped_term_unpack(
                view(value, (q + 1):(q + source_coordinates)), p, termvec)
            used == source_coordinates || return GLLVModels._NLL_SENTINEL
            family = GLLVModels._grouped_nongaussian_family(kind, value, dispersion_indices, p, n, mode)
            family === nothing && return GLLVModels._NLL_SENTINEL
            W = GLLVModels._grouped_laplace_design(incidences, loads; uniques = uniques)
            result = GLLVModels.joint_grouped_laplace_loglik(family, vec(data), vec(trials), D,
                gamma, W; link = GLLVModels._grouped_nongaussian_link(Val(kind)),
                maxiter = 100, tol = 1e-8)
            inner_iters_sum[] += result.iterations
            if result.status === :ok
                chol_count[] += 2 * result.iterations + 1
                ok_calls[] += 1
            else
                chol_count[] += 2 * result.iterations
                failed_calls[] += 1
            end
            final_inner_status[] = result.status
            return (result.status === :ok && result.converged && isfinite(result.loglik)) ?
                -result.loglik : GLLVModels._NLL_SENTINEL
        catch
            failed_calls[] += 1
            return GLLVModels._NLL_SENTINEL
        end
    end

    grad_calls = Ref(0)
    fd_gradient = (obj, val) -> begin
        grad_calls[] += 1
        GLLVModels._grouped_fd_gradient(obj, val)
    end

    result1 = Optim.optimize(counting_objective, theta0, Optim.NelderMead(),
        Optim.Options(g_tol = 1e-4, iterations = 100))
    candidate = collect(Optim.minimizer(result1))
    candidate_gradient = fd_gradient(counting_objective, candidate)
    final_result = result1
    if all(isfinite, candidate_gradient)
        gradient! = (storage, value) -> (storage .= fd_gradient(counting_objective, value))
        refined = try
            Optim.optimize(counting_objective, gradient!, candidate, Optim.BFGS(),
                Optim.Options(g_tol = 1e-4, iterations = 100))
        catch
            nothing
        end
        if refined !== nothing
            refined_estimate = collect(Optim.minimizer(refined))
            refined_value = counting_objective(refined_estimate)
            if isfinite(refined_value) && !(refined_value >= 1e12) &&
                    refined_value <= counting_objective(candidate)
                final_result = refined
            end
        end
    end
    estimate = collect(Optim.minimizer(final_result))
    shadow_loglik = -counting_objective(estimate)

    return (; shadow_loglik, obj_calls = obj_calls[], grad_calls = grad_calls[],
             inner_iters_sum = inner_iters_sum[], chol_count = chol_count[],
             ok_calls = ok_calls[], failed_calls = failed_calls[],
             final_inner_status = final_inner_status[])
end

function main()
    parse_args(ARGS)
    println("Julia ", VERSION, "  threads=", Threads.nthreads())
    sha = _git_sha()

    y, group, G, N = load_fixture()
    Y1 = reshape(Float64.(y), 1, :)
    terms = [GLLVModels.GroupingTerm(:unit; mode = :indep)]

    # --- (1) real, unmodified wall-clock, exactly as f3_ours_glmm.jl does ---
    warm_s = median_s(() -> GLLVModels.fit_gllvm(Y1; family = Poisson(), grouping = terms, unit = group))
    real_fit = GLLVModels.fit_gllvm(Y1; family = Poisson(), grouping = terms, unit = group)
    println("real fit: converged=", real_fit.converged, " loglik=", real_fit.loglik,
            " iterations=", real_fit.iterations, " stopping_reason=", real_fit.stopping_reason)
    @printf("warm median wall (%d reps): %.4f s\n", REPS, warm_s)

    # --- (2) shadow-counted replica for outer/inner/CHOLMOD counts ---
    counts = shadow_fit_counts(Matrix{Float64}(Y1), group)
    @printf("shadow: loglik=%.6f  obj_calls=%d  outer_gradient_evals=%d  inner_newton_iters_sum=%d  fresh_cholmod_analyses=%d  ok_inner_calls=%d  failed_inner_calls=%d  final_inner_status=%s\n",
            counts.shadow_loglik, counts.obj_calls, counts.grad_calls, counts.inner_iters_sum,
            counts.chol_count, counts.ok_calls, counts.failed_calls, counts.final_inner_status)

    loglik_gap = abs(counts.shadow_loglik - real_fit.loglik)
    loglik_gap_rel = loglik_gap / max(abs(real_fit.loglik), 1.0)
    @printf("shadow-vs-real loglik gap: abs=%.3e  rel=%.3e\n", loglik_gap, loglik_gap_rel)

    banked = 0.192
    band_lo, band_hi = 0.15, 0.25
    reasons = String[]
    ok = true
    if !(band_lo <= warm_s <= band_hi)
        ok = false
        push!(reasons, "warm_median_wall=$(round(warm_s, digits=4))s outside [$(band_lo),$(band_hi)]s (banked $(banked)s)")
    end
    if loglik_gap_rel > 1e-4
        ok = false
        push!(reasons, "shadow replica loglik diverges from real fit_gllvm by rel=$(round(loglik_gap_rel, sigdigits=3)) " *
                       "(shadow may not faithfully reproduce fit_grouped_nongaussian; counts are then unreliable)")
    end
    if counts.obj_calls == 0 || counts.grad_calls == 0
        ok = false
        push!(reasons, "zero objective/gradient calls recorded — instrumentation did not engage")
    end

    mkpath(joinpath(@__DIR__, "results"))
    out = joinpath(@__DIR__, "results", "grouped_glmm_$(sha).tsv")
    open(out, "w") do io
        for l in header_lines()
            println(io, l)
        end
        println(io, "N\tG\treps\twarm_median_wall_s\treal_loglik\treal_iterations\t",
                     "shadow_loglik\tobj_calls\touter_gradient_evals\tinner_newton_iters_sum\t",
                     "fresh_cholmod_analyses\tok_inner_calls\tfailed_inner_calls\tloglik_gap_rel")
        println(io, N, "\t", G, "\t", REPS, "\t", warm_s, "\t", real_fit.loglik, "\t", real_fit.iterations, "\t",
                     counts.shadow_loglik, "\t", counts.obj_calls, "\t", counts.grad_calls, "\t",
                     counts.inner_iters_sum, "\t", counts.chol_count, "\t", counts.ok_calls, "\t",
                     counts.failed_calls, "\t", loglik_gap_rel)
    end
    println("TSV written: ", out)

    if ok
        println("GATE G4.3 PASS")
    else
        println("GATE G4.3 FAIL ", join(reasons, "; "))
    end
    exit(ok ? 0 : 1)
end

main()
