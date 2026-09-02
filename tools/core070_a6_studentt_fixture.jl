# A6 Student-t interior-nu paired fixture -- Julia stage + verifier
# (maintainer round2-3 #11; docs/dev-log/decisions/2026-09-01-maintainer-decisions-round2-3.md #11).
#
# Companion to tools/core070_a6_studentt_fixture.R. Design rationale and the
# full "why this fixture, why these conventions" account live in
# docs/dev-log/core070/a6-studentt-notes.md; the frozen numeric contract lives
# in docs/dev-log/core070/a6-studentt-contract.json (reference_commit
# b4d5fee64def88bc768dda1f1f77c29b295edd86, paired tolerance 1e-4).
#
# This single script plays THREE house-convention roles because the owned
# file set for this leaf is {R, jl, contract.json, notes.md} -- no separate
# tools/core070_..._verify.py, so the "verifier" (argv 2, coverage guard,
# soft-fail, --self-test >=4 mutations) lives here rather than in a third
# file, mirroring e.g. tools/core070_wave6_conversion_batch.jl's
# soft-fail-per-case pattern and tools/core070_verify_wave6_conversion_batch.py's
# --self-test mutation battery, folded into one process:
#
#   julia tools/core070_a6_studentt_fixture.jl <data_path> <r_output_path>
#
#   1. `<data_path>` missing        -> GENERATE the fixture (fixed seed),
#      write Y, fit Julia's own StudentTFit, cache it next to
#      `<r_output_path>`, print instructions for the R stage, exit 0. This is
#      the coverage guard for phase 1: nothing is claimed verified yet.
#   2. `<data_path>` present, `<r_output_path>` missing -> re-fit (or reuse
#      the cache) on the existing data, print that the R stage has not run
#      yet, exit 1 (NOT a pass -- a missing oracle side is never silently
#      treated as agreement; the soft-fail convention this repo uses for a
#      missing/null oracle value, e.g. tools/core070_wave6_conversion_batch.jl:158).
#   3. Both present -> PAIRED COMPARISON at 1e-4 (loglik, beta, sigma, nu,
#      loading up to the K=1 sign indeterminacy) and BOTH-ENGINE health
#      (fit.converged / R's inline health check) -- an interior-nu fixture
#      where EITHER engine failing health is a recorded finding, never
#      fudged away (round2-3 #11's explicit instruction).
#
#   julia tools/core070_a6_studentt_fixture.jl --self-test
#
#   Builds a SYNTHETIC agreeing (julia_result, r_result) pair with no data
#   file, no fit, no R -- confirms `_a6_compare` accepts it, then mutates it
#   >=4 independent ways and confirms every mutation is rejected. Runs with
#   `julia --project=.` alone; never substitutes for the real two-stage run.

using GLLVM
using Random, Distributions, LinearAlgebra, DelimitedFiles, Statistics

const ROOT = normpath(joinpath(@__DIR__, ".."))
const REFERENCE_COMMIT = "b4d5fee64def88bc768dda1f1f77c29b295edd86"
const PAIRED_TOL = 1e-4

# ---------------------------------------------------------------------------
# Fixture design constants (frozen; mirrored in the R stage and in the
# contract JSON -- K is a fixed design constant of THIS fixture, not a
# runtime argument, matching the argv-2 house convention).
# ---------------------------------------------------------------------------
const FIXTURE_SEED = 20260901
const FIXTURE_P = 5
const FIXTURE_K = 1
const FIXTURE_N = 250
const FIXTURE_BETA_TRUE = [0.5, -0.3, 0.2, 0.8, -0.6]
const FIXTURE_LOADING_TRUE = [0.9, -0.7, 0.5, 0.6, -0.4]   # p x K, K = 1
const FIXTURE_SIGMA_TRUE = 0.7
const FIXTURE_NU_TRUE = 6.0   # moderate, genuinely INTERIOR -- both engines expected to land away from any boundary

"""
    generate_fixture(rng) -> Matrix{Float64}

Simulate the p x n Student-t GLLVM response matrix at the frozen fixture
design constants above: `y_tj = beta_t + Lambda_t * z_j + sigma * eps_tj`,
`z_j ~ N(0,1)` iid across sites, `eps_tj ~ t_(nu_true)` (standard, scale 1).
Deliberately genuinely heavy-tailed (nu_true = 6, not the pure-Gaussian
construction of test_studentt_boundary_honesty.jl / test_studentt_boundary.jl)
so the estimated-nu MLE is expected to land INTERIOR on both engines.
"""
function generate_fixture(rng)
    p, K, n = FIXTURE_P, FIXTURE_K, FIXTURE_N
    Λ = reshape(FIXTURE_LOADING_TRUE, p, K)
    Y = zeros(p, n)
    tdist = TDist(FIXTURE_NU_TRUE)
    for j in 1:n
        z = randn(rng, K)
        for t in 1:p
            Y[t, j] = FIXTURE_BETA_TRUE[t] + dot(view(Λ, t, :), z) + FIXTURE_SIGMA_TRUE * rand(rng, tdist)
        end
    end
    return Y
end

# ---------------------------------------------------------------------------
# R-output TSV readback: `key\tvalue` (scalar) or `key\tindex\tvalue` (vector),
# sprintf("%.17g", .) on the R side -- mirrors
# tools/core070_student_warmstart_readback.R's readback shape.
# ---------------------------------------------------------------------------
function read_r_output(path::AbstractString)
    scalars = Dict{String, Float64}()
    vectors = Dict{String, Vector{Float64}}()
    for line in eachline(path)
        isempty(strip(line)) && continue
        parts = split(line, '\t')
        if length(parts) == 2
            scalars[parts[1]] = parse(Float64, parts[2])
        elseif length(parts) == 3
            key = parts[1]
            idx = parse(Int, parts[2])
            v = get!(vectors, key) do
                Float64[]
            end
            length(v) < idx && resize!(v, idx)
            v[idx] = parse(Float64, parts[3])
        else
            error("read_r_output: unparseable line in $path: $(repr(line))")
        end
    end
    return (scalars = scalars, vectors = vectors)
end

# ---------------------------------------------------------------------------
# The comparison itself. Operates on plain Dicts so --self-test can exercise
# it against a SYNTHETIC pair with no fit and no R. Returns (pass, messages).
# ---------------------------------------------------------------------------
function _a6_compare(julia_result::Dict, r_result::Dict; tol::Real = PAIRED_TOL)
    messages = String[]
    ok = true
    fail!(msg) = (ok = false; push!(messages, msg))

    # Coverage guard: every quantity this comparison claims to check must
    # actually be present on both sides -- a missing key is a soft-fail, not
    # a silent skip.
    required = ("loglik", "converged", "nu_boundary", "beta", "sigma", "nu", "loading")
    for k in required
        haskey(julia_result, k) || fail!("julia_result missing required key $(repr(k))")
    end
    required_r = ("loglik", "healthy", "nu_at_boundary", "beta", "sigma_student", "df_student", "loading")
    for k in required_r
        haskey(r_result, k) || fail!("r_result missing required key $(repr(k))")
    end
    ok || return (false, messages)

    # Both-engine health at an INTERIOR fixture: a failure here is a recorded
    # finding, never fudged away (round2-3 #11).
    julia_result["converged"] === true || fail!("Julia fit reports converged=false at the interior-nu fixture")
    julia_result["nu_boundary"] === false || fail!("Julia fit reports nu_boundary=true at the interior-nu fixture")
    r_result["healthy"] == 1.0 || fail!("R fit reports healthy=FALSE at the interior-nu fixture")
    r_result["nu_at_boundary"] == 0.0 || fail!("R fit reports nu_at_boundary=TRUE at the interior-nu fixture")

    # Paired numeric agreement at PAIRED_TOL. Sign-align the loading vector
    # first: K = 1 latent-variable GLLVMs are identified only up to a sign
    # flip of (Lambda, z), so the two engines' MLE loadings may differ by an
    # overall sign even when they are the SAME point in likelihood terms.
    jl_loading = Vector{Float64}(julia_result["loading"])
    r_loading = Vector{Float64}(r_result["loading"])
    if length(jl_loading) == length(r_loading) && length(jl_loading) > 0
        if dot(jl_loading, r_loading) < 0
            jl_loading = -jl_loading
        end
    else
        fail!("loading length mismatch: julia=$(length(jl_loading)) r=$(length(r_loading))")
    end

    close_enough(a, b) = isfinite(a) && isfinite(b) && abs(a - b) <= tol

    close_enough(julia_result["loglik"], r_result["loglik"]) ||
        fail!("loglik disagreement: julia=$(julia_result["loglik"]) r=$(r_result["loglik"]) " *
              "delta=$(abs(julia_result["loglik"] - r_result["loglik"]))")

    jl_beta = Vector{Float64}(julia_result["beta"])
    r_beta = Vector{Float64}(r_result["beta"])
    length(jl_beta) == length(r_beta) || fail!("beta length mismatch: julia=$(length(jl_beta)) r=$(length(r_beta))")
    if length(jl_beta) == length(r_beta)
        for i in eachindex(jl_beta)
            close_enough(jl_beta[i], r_beta[i]) ||
                fail!("beta[$i] disagreement: julia=$(jl_beta[i]) r=$(r_beta[i])")
        end
    end

    jl_sigma = Vector{Float64}(julia_result["sigma"])
    r_sigma = Vector{Float64}(r_result["sigma_student"])
    length(jl_sigma) == length(r_sigma) || fail!("sigma length mismatch: julia=$(length(jl_sigma)) r=$(length(r_sigma))")
    if length(jl_sigma) == length(r_sigma)
        for i in eachindex(jl_sigma)
            close_enough(jl_sigma[i], r_sigma[i]) ||
                fail!("sigma[$i] disagreement: julia=$(jl_sigma[i]) r=$(r_sigma[i])")
        end
    end

    jl_nu = Vector{Float64}(julia_result["nu"])
    r_nu = Vector{Float64}(r_result["df_student"])
    length(jl_nu) == length(r_nu) || fail!("nu length mismatch: julia=$(length(jl_nu)) r=$(length(r_nu))")
    if length(jl_nu) == length(r_nu)
        for i in eachindex(jl_nu)
            close_enough(jl_nu[i], r_nu[i]) ||
                fail!("nu[$i] disagreement: julia=$(jl_nu[i]) r=$(r_nu[i])")
        end
    end

    if length(jl_loading) == length(r_loading)
        for i in eachindex(jl_loading)
            close_enough(jl_loading[i], r_loading[i]) ||
                fail!("loading[$i] disagreement (sign-aligned): julia=$(jl_loading[i]) r=$(r_loading[i])")
        end
    end

    return (ok, messages)
end

# ---------------------------------------------------------------------------
# --self-test: synthetic pair, no data/R required.
# ---------------------------------------------------------------------------
function _a6_synthetic_pair()
    julia_result = Dict{String, Any}(
        "loglik" => -812.345, "converged" => true, "nu_boundary" => false,
        "beta" => copy(FIXTURE_BETA_TRUE), "sigma" => fill(FIXTURE_SIGMA_TRUE, 1),
        "nu" => [FIXTURE_NU_TRUE], "loading" => copy(FIXTURE_LOADING_TRUE),
    )
    r_result = Dict{String, Any}(
        "loglik" => -812.345 + 3e-5, "healthy" => 1.0, "nu_at_boundary" => 0.0,
        "beta" => copy(FIXTURE_BETA_TRUE), "sigma_student" => fill(FIXTURE_SIGMA_TRUE, 1),
        "df_student" => [FIXTURE_NU_TRUE], "loading" => -copy(FIXTURE_LOADING_TRUE),  # sign flip: must still pass
    )
    return julia_result, r_result
end

function run_self_test()
    julia_result, r_result = _a6_synthetic_pair()
    ok, messages = _a6_compare(julia_result, r_result)
    ok || error("synthetic agreeing pair rejected: $(join(messages, "; "))")

    rejected = String[]
    function expect_rejected(mutate!, label)
        jl2 = deepcopy(julia_result)
        r2 = deepcopy(r_result)
        mutate!(jl2, r2)
        ok2, _ = _a6_compare(jl2, r2)
        ok2 && error("REJECTED MUTATION FAILED TO BE CAUGHT: $label")
        push!(rejected, label)
    end

    expect_rejected("loglik moved past tolerance") do jl2, r2
        jl2["loglik"] = jl2["loglik"] + 10 * PAIRED_TOL
    end
    expect_rejected("beta[1] moved past tolerance") do jl2, r2
        jl2["beta"][1] = jl2["beta"][1] + 10 * PAIRED_TOL
    end
    expect_rejected("sigma moved past tolerance") do jl2, r2
        jl2["sigma"][1] = jl2["sigma"][1] + 10 * PAIRED_TOL
    end
    expect_rejected("nu moved past tolerance") do jl2, r2
        jl2["nu"][1] = jl2["nu"][1] + 10 * PAIRED_TOL
    end
    expect_rejected("Julia side reports converged=false") do jl2, r2
        jl2["converged"] = false
    end
    expect_rejected("Julia side reports nu_boundary=true") do jl2, r2
        jl2["nu_boundary"] = true
    end
    expect_rejected("R side reports healthy=FALSE") do jl2, r2
        r2["healthy"] = 0.0
    end
    expect_rejected("R side reports nu_at_boundary=TRUE") do jl2, r2
        r2["nu_at_boundary"] = 1.0
    end
    expect_rejected("required key missing from julia_result") do jl2, r2
        delete!(jl2, "sigma")
    end

    length(rejected) >= 4 || error("only $(length(rejected)) rejected mutations ran, need >=4")
    println("CORE070_A6_STUDENTT_SELF_TEST_OK rejected_mutations=$(length(rejected))")
end

# ---------------------------------------------------------------------------
# Fit Julia's own StudentTFit and package it into the comparison Dict shape.
# ---------------------------------------------------------------------------
function fit_julia_side(Y::AbstractMatrix)
    fit = fit_studentt_gllvm(Y; K = FIXTURE_K)
    return Dict{String, Any}(
        "loglik" => fit.loglik,
        "converged" => fit.converged,
        "nu_boundary" => fit.nu_boundary,
        "beta" => copy(fit.β),
        "sigma" => fit.σ isa Real ? [fit.σ] : copy(fit.σ),
        "nu" => fit.ν isa Real ? [fit.ν] : copy(fit.ν),
        "loading" => vec(fit.Λ),
    ), fit
end

function read_r_result(path::AbstractString)
    scalars, vectors = read_r_output(path)
    return Dict{String, Any}(
        "loglik" => scalars["loglik"],
        "healthy" => scalars["healthy"],
        "nu_at_boundary" => scalars["nu_at_boundary"],
        "beta" => vectors["beta"],
        "sigma_student" => vectors["sigma_student"],
        "df_student" => vectors["df_student"],
        "loading" => vectors["loading"],
    )
end

# ---------------------------------------------------------------------------
# Two-stage generate-or-verify driver.
# ---------------------------------------------------------------------------
function main(argv)
    if length(argv) == 1 && argv[1] == "--self-test"
        run_self_test()
        return 0
    end
    length(argv) == 2 || error(
        "usage: julia tools/core070_a6_studentt_fixture.jl <data_path> <r_output_path>" *
        "  (or: julia tools/core070_a6_studentt_fixture.jl --self-test)")
    data_path, r_output_path = argv

    if !isfile(data_path)
        rng = MersenneTwister(FIXTURE_SEED)
        Y = generate_fixture(rng)
        writedlm(data_path, Y)
        println("CORE070_A6_STUDENTT_FIXTURE_GENERATED $(data_path) p=$(FIXTURE_P) K=$(FIXTURE_K) n=$(FIXTURE_N) " *
                "seed=$(FIXTURE_SEED) nu_true=$(FIXTURE_NU_TRUE) sigma_true=$(FIXTURE_SIGMA_TRUE)")
        println("Next: Rscript --vanilla tools/core070_a6_studentt_fixture.R $(data_path) $(r_output_path)")
        return 0   # coverage guard phase 1: generation only, nothing verified yet
    end

    Y = readdlm(data_path)
    size(Y, 1) == FIXTURE_P || error("data_path row count $(size(Y,1)) != fixed design p=$(FIXTURE_P)")
    julia_result, fit = fit_julia_side(Y)
    println("CORE070_A6_STUDENTT_JULIA_FIT loglik=$(fit.loglik) converged=$(fit.converged) " *
            "nu_boundary=$(fit.nu_boundary) nu=$(fit.ν) sigma=$(fit.σ)")

    if !isfile(r_output_path)
        println("CORE070_A6_STUDENTT_AWAITING_R $(r_output_path) does not exist yet -- Julia fit done and " *
                "printed above; run the R stage next, then re-run this exact command to verify.")
        return 1   # soft-fail: a missing oracle side is never silently a pass
    end

    r_result = read_r_result(r_output_path)
    ok, messages = _a6_compare(julia_result, r_result)
    if ok
        println("CORE070_A6_STUDENTT_PAIRED_VERIFIED tol=$(PAIRED_TOL) reference_commit=$(REFERENCE_COMMIT)")
        return 0
    else
        println("CORE070_A6_STUDENTT_PAIRED_FAILED tol=$(PAIRED_TOL)")
        for m in messages
            println("  - ", m)
        end
        return 1
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(main(ARGS))
end
