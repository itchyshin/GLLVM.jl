# Retained evidence runner for the "inference" manifest-area batch (45
# EXECUTABLE_NOW routing cases + 2 negative controls). Exercises GLLVM.jl's
# own confidence-interval method-routing surface (confint/profile_ci/
# bootstrap_ci for packed theta terms; the derived-quantity wald_ci/
# profile_ci_derived/bootstrap_ci_derived family for communality/rho/
# phylo_signal/proportion) against two small deterministic fitted fixtures.
# This is a ROUTING probe (which Julia solver got invoked for a given
# parm+method pair), not an R-parity numerical check -- see
# docs/dev-log/core070/inference-batch-contract.json for the case table,
# the paired R routing comparand (test/parity/fixtures/core070_inference_routes.tsv
# + the already-frozen docs/dev-log/core070/inference-routing-subset.json),
# and why 8 rows are bucket NEEDS_NEW_JULIA_SURFACE / 11 rows are bucket
# SPEC_DEFECT rather than being exercised here.
#
# Usage:
#   julia --project=<repo-root> tools/core070_inference_batch.jl <repo-root> <destination>
#
# argv[1] <repo-root>   the GLLVM.jl checkout to activate and to pin source
#                        hashes from (this script does not read from any other
#                        tree; there is no "installed package" path).
# argv[2] <destination> output directory; MUST NOT already exist (this script
#                        mkpath()s it fresh so a stale prior run can never be
#                        silently reused as if it were this run's evidence).

using Pkg

length(ARGS) == 2 || error("usage: julia core070_inference_batch.jl <repo-root> <destination>")
repo_root = abspath(ARGS[1])
destination = ARGS[2]
isdir(destination) && error("destination already exists (refusing to overwrite retained evidence): $destination")
mkpath(destination)

Pkg.activate(repo_root; io = devnull)
using GLLVM, Random, LinearAlgebra, SHA

sha256_file(path) = bytes2hex(open(SHA.sha256, path))

# ---------------------------------------------------------------------------
# Provenance: pin the source files this run actually depends on.
# ---------------------------------------------------------------------------
pinned_files = [
    "src/confint.jl", "src/confint_profile.jl", "src/confint_bootstrap.jl",
    "src/confint_derived.jl", "src/confint_derived_wald.jl",
    "src/families/aghq_gaussian_fit.jl", "src/fit.jl",
]
source_pins = Dict(f => sha256_file(joinpath(repo_root, f)) for f in pinned_files)

# ---------------------------------------------------------------------------
# Fixture A: AGHQ Gaussian-record fit (_has_gaussian_record == true), no
# B/W/phy structure. Unlocks the *validated* confint(method::Symbol) route
# (ArgumentError on an unrecognised method) for Lambda/beta/sigma_eps.
# ---------------------------------------------------------------------------
Random.seed!(20260901)
p, n, K, q = 3, 30, 1, 1
βA = [0.5, -0.3, 0.2]
ΛA = reshape([0.6, 0.4, -0.5], p, K)
XA = zeros(p, n, q)
for s in 1:n, t in 1:p
    XA[t, s, 1] = randn()
end
YA = zeros(p, n)
for s in 1:n
    z = randn(K)
    for t in 1:p
        YA[t, s] = βA[t] + 0.3 * XA[t, s, 1] + (ΛA * z)[t] + 0.3 * randn()
    end
end
fitA = fit_gaussian_gllvm(YA; K = K, X = XA, aghq = 3)
fitA.converged || error("fixture A did not converge")
GLLVM._has_gaussian_record(fitA) || error(
    "fixture A must be an AGHQ Gaussian record (_has_gaussian_record); the " *
    "confint(method::Symbol) validation route this batch exercises for " *
    "Lambda/beta/sigma_eps only exists on that path (src/confint.jl:359-370, " *
    "src/families/aghq_gaussian_fit.jl:202-221) -- see the contract's " *
    "known_findings for why the plain (non-AGHQ) Gaussian fitter's confint " *
    "silently ignores an unrecognised `method`.")

# ---------------------------------------------------------------------------
# Fixture S: plain (non-AGHQ) Gaussian fit with B/W diagonal tiers and a
# phylogenetic block. _has_gaussian_record is FALSE here by construction
# (aghq_gaussian_fit.jl's structured branch always sets integration.data =
# nothing) -- confint's `method` kwarg is a documented no-op on this path;
# profile_ci/bootstrap_ci/*_wald_ci/*_ci_derived route independently of that
# flag, which is what sigma_B/sigma_W/sigma_phy and the four derived-quantity
# families below actually exercise.
# ---------------------------------------------------------------------------
Random.seed!(20260902)
Σ_phy = [1.0 0.2 0.1; 0.2 1.0 0.15; 0.1 0.15 1.0]
βS = [0.4, -0.2, 0.1]
ΛS = reshape([0.5, 0.3, -0.4], p, K)
YS = zeros(p, n)
for s in 1:n
    z = randn(K)
    for t in 1:p
        YS[t, s] = βS[t] + (ΛS * z)[t] + 0.2 * randn() + 0.15 * randn()
    end
end
fitS = fit_gaussian_gllvm(YS; K = K, has_diag = true, has_phy_unique = true, Σ_phy = Σ_phy)
fitS.converged || error("fixture S did not converge")
GLLVM._has_gaussian_record(fitS) && error("fixture S was expected to be a plain (non-AGHQ-record) fit")

specS = GLLVM._derived_spec(fitS)
communality_packed_1 = θ -> GLLVM._communality_packed(θ, specS, 1)
correlation_closure_12 = GLLVM._make_correlation_closure(specS, 1, 2)
phylo_signal_closure_1 = GLLVM._make_phylo_signal_closure(specS, 1)

# ---------------------------------------------------------------------------
# Route classifier: distinguishes which CI solver ran by the *shape* of the
# returned NamedTuple, mirroring how tools/core070_inference_routes.R
# identifies the R-side solver by a sentinel route_boundary error instead of
# a numerical result. Field sets checked directly against the four call
# sites exercised below (verified empirically, not merely from docstrings).
# ---------------------------------------------------------------------------
function route_tag(result)
    fields = propertynames(result)
    :n_converged in fields && return :bootstrap
    :se_transformed in fields && return :wald_derived
    (:se in fields && :pd_hessian in fields) && return :wald_packed
    :method in fields && return :profile
    return :unknown
end

# ---------------------------------------------------------------------------
# Case table: one row per EXECUTABLE_NOW source row from
# docs/dev-log/core070/manifest-freeze-work/drafts/inference.json. Each
# entry names the manifest case_id, the fixture source row id (CI-ROUTE-NNN,
# for cross-reference against test/parity/fixtures/core070_inference_routes.tsv),
# the family of call it makes, and the route_tag it must produce (or
# :reject for the two method-validation negative cases on fixture A).
# ---------------------------------------------------------------------------
struct Case
    source_id::String
    case_id::String
    thunk::Function
    expect::Symbol   # :wald_packed | :profile | :bootstrap | :wald_derived | :reject
end

cases = Case[]

# --- Lambda (fixture A, packed Lambda_B[1,1]) -------------------------------
push!(cases, Case("CI-ROUTE-001", "CORE070-INFERENCE-LAMBDA-CI-METHOD-ROUTE",
    () -> confint(fitA, YA; parm = "Lambda_B[1,1]"), :wald_packed))
push!(cases, Case("CI-ROUTE-002", "CORE070-INFERENCE-LAMBDA-CI-METHOD-ROUTE",
    () -> profile_ci(fitA, "Lambda_B[1,1]"; y = YA, profile_iterations = 5), :profile))
push!(cases, Case("CI-ROUTE-003", "CORE070-INFERENCE-LAMBDA-CI-METHOD-ROUTE",
    () -> confint(fitA, YA; parm = "Lambda_B[1,1]", method = :wald), :wald_packed))
push!(cases, Case("CI-ROUTE-004", "CORE070-INFERENCE-LAMBDA-CI-METHOD-ROUTE",
    () -> bootstrap_ci(fitA; parms = "Lambda_B[1,1]", y = YA, n_boot = 6, seed = 1), :bootstrap))
push!(cases, Case("CI-ROUTE-006", "CORE070-INFERENCE-LAMBDA-CI-UNSUPPORTED-METHOD-REJECT",
    () -> confint(fitA, YA; parm = "Lambda_B[1,1]", method = :fisher_z), :reject))
push!(cases, Case("CI-ROUTE-007", "CORE070-INFERENCE-LAMBDA-CI-UNSUPPORTED-METHOD-REJECT",
    () -> confint(fitA, YA; parm = "Lambda_B[1,1]", method = :bogus), :reject))

# --- beta (fixture A, packed beta[1]) ---------------------------------------
push!(cases, Case("CI-ROUTE-065", "CORE070-INFERENCE-BETA-CI-METHOD-ROUTE",
    () -> profile_ci(fitA, "beta[1]"; y = YA, profile_iterations = 5), :profile))
push!(cases, Case("CI-ROUTE-066", "CORE070-INFERENCE-BETA-CI-METHOD-ROUTE",
    () -> confint(fitA, YA; parm = "beta[1]", method = :wald), :wald_packed))
push!(cases, Case("CI-ROUTE-081", "CORE070-INFERENCE-BETA-CI-METHOD-ROUTE",
    () -> profile_ci(fitA, "beta[1]"; y = YA, profile_iterations = 5), :profile))
push!(cases, Case("CI-ROUTE-067", "CORE070-INFERENCE-BETA-BOOTSTRAP-FALLBACK-DIVERGENCE",
    () -> bootstrap_ci(fitA; parms = "beta[1]", y = YA, n_boot = 6, seed = 2), :bootstrap))

# --- sigma_eps (fixture A, packed sigma_eps) --------------------------------
push!(cases, Case("CI-ROUTE-068", "CORE070-INFERENCE-SIGMA-EPS-CI-METHOD-ROUTE",
    () -> profile_ci(fitA, "sigma_eps"; y = YA, profile_iterations = 5), :profile))
push!(cases, Case("CI-ROUTE-069", "CORE070-INFERENCE-SIGMA-EPS-CI-METHOD-ROUTE",
    () -> confint(fitA, YA; parm = "sigma_eps", method = :wald), :wald_packed))
push!(cases, Case("CI-ROUTE-084", "CORE070-INFERENCE-SIGMA-EPS-CI-METHOD-ROUTE",
    () -> profile_ci(fitA, "sigma_eps"; y = YA, profile_iterations = 5), :profile))
push!(cases, Case("CI-ROUTE-070", "CORE070-INFERENCE-SIGMA-EPS-BOOTSTRAP-FALLBACK-DIVERGENCE",
    () -> bootstrap_ci(fitA; parms = "sigma_eps", y = YA, n_boot = 6, seed = 3), :bootstrap))

# --- sigma_B / sigma_W / sigma_phy (fixture S, packed) ----------------------
for (rid, parm) in [("CI-ROUTE-043", "sigma_B[1]"), ("CI-ROUTE-055", "sigma_B[1]")]
    push!(cases, Case(rid, "CORE070-INFERENCE-SIGMA-B-CI-METHOD-ROUTE",
        () -> profile_ci(fitS, parm; y = YS, Σ_phy = Σ_phy, profile_iterations = 5), :profile))
end
for (rid, parm) in [("CI-ROUTE-044", "sigma_B[1]"), ("CI-ROUTE-056", "sigma_B[1]")]
    push!(cases, Case(rid, "CORE070-INFERENCE-SIGMA-B-CI-METHOD-ROUTE",
        () -> confint(fitS, YS; parm = parm, method = :wald, Σ_phy = Σ_phy), :wald_packed))
end
for (rid, seed) in [("CI-ROUTE-045", 4), ("CI-ROUTE-057", 5)]
    push!(cases, Case(rid, "CORE070-INFERENCE-SIGMA-B-CI-METHOD-ROUTE",
        () -> bootstrap_ci(fitS; parms = "sigma_B[1]", y = YS, Σ_phy = Σ_phy, n_boot = 6, seed = seed), :bootstrap))
end
for (rid, parm) in [("CI-ROUTE-046", "sigma_W[1]"), ("CI-ROUTE-058", "sigma_W[1]")]
    push!(cases, Case(rid, "CORE070-INFERENCE-SIGMA-W-CI-METHOD-ROUTE",
        () -> profile_ci(fitS, parm; y = YS, Σ_phy = Σ_phy, profile_iterations = 5), :profile))
end
for (rid, parm) in [("CI-ROUTE-047", "sigma_W[1]"), ("CI-ROUTE-059", "sigma_W[1]")]
    push!(cases, Case(rid, "CORE070-INFERENCE-SIGMA-W-CI-METHOD-ROUTE",
        () -> confint(fitS, YS; parm = parm, method = :wald, Σ_phy = Σ_phy), :wald_packed))
end
for (rid, seed) in [("CI-ROUTE-048", 6), ("CI-ROUTE-060", 7)]
    push!(cases, Case(rid, "CORE070-INFERENCE-SIGMA-W-CI-METHOD-ROUTE",
        () -> bootstrap_ci(fitS; parms = "sigma_W[1]", y = YS, Σ_phy = Σ_phy, n_boot = 6, seed = seed), :bootstrap))
end
push!(cases, Case("CI-ROUTE-061", "CORE070-INFERENCE-SIGMA-PHY-CI-METHOD-ROUTE",
    () -> profile_ci(fitS, "sigma_phy[1]"; y = YS, Σ_phy = Σ_phy, profile_iterations = 5), :profile))
push!(cases, Case("CI-ROUTE-062", "CORE070-INFERENCE-SIGMA-PHY-CI-METHOD-ROUTE",
    () -> confint(fitS, YS; parm = "sigma_phy[1]", method = :wald, Σ_phy = Σ_phy), :wald_packed))
push!(cases, Case("CI-ROUTE-063", "CORE070-INFERENCE-SIGMA-PHY-CI-METHOD-ROUTE",
    () -> bootstrap_ci(fitS; parms = "sigma_phy[1]", y = YS, Σ_phy = Σ_phy, n_boot = 6, seed = 8), :bootstrap))

# --- communality (fixture S, trait 1) ---------------------------------------
push!(cases, Case("CI-ROUTE-022", "CORE070-INFERENCE-COMMUNALITY-CI-METHOD-ROUTE",
    () -> communality_wald_ci(fitS, 1; y = YS, Σ_phy = Σ_phy), :wald_derived))
push!(cases, Case("CI-ROUTE-023", "CORE070-INFERENCE-COMMUNALITY-CI-METHOD-ROUTE",
    () -> GLLVM.profile_ci_derived(fitS, communality_packed_1; y = YS, Σ_phy = Σ_phy, penalty_weight = 1e4), :profile))
push!(cases, Case("CI-ROUTE-024", "CORE070-INFERENCE-COMMUNALITY-CI-METHOD-ROUTE",
    () -> communality_wald_ci(fitS, 1; y = YS, Σ_phy = Σ_phy), :wald_derived))
push!(cases, Case("CI-ROUTE-025", "CORE070-INFERENCE-COMMUNALITY-CI-METHOD-ROUTE",
    () -> GLLVM.bootstrap_ci_derived(fitS, f -> communality(f)[1]; y = YS, Σ_phy = Σ_phy, n_boot = 6, seed = 9), :bootstrap))

# --- rho (fixture S, pair 1,2) ----------------------------------------------
push!(cases, Case("CI-ROUTE-029", "CORE070-INFERENCE-RHO-CI-METHOD-ROUTE",
    () -> correlation_wald_ci(fitS, 1, 2; y = YS, Σ_phy = Σ_phy), :wald_derived))
push!(cases, Case("CI-ROUTE-030", "CORE070-INFERENCE-RHO-CI-METHOD-ROUTE",
    () -> GLLVM.profile_ci_derived(fitS, correlation_closure_12; y = YS, Σ_phy = Σ_phy, penalty_weight = 1e4), :profile))
push!(cases, Case("CI-ROUTE-032", "CORE070-INFERENCE-RHO-CI-METHOD-ROUTE",
    () -> GLLVM.bootstrap_ci_derived(fitS, f -> correlation(f)[1, 2]; y = YS, Σ_phy = Σ_phy, n_boot = 6, seed = 10), :bootstrap))
push!(cases, Case("CI-ROUTE-034", "CORE070-INFERENCE-RHO-CI-METHOD-ROUTE",
    () -> correlation_wald_ci(fitS, 1, 2; y = YS, Σ_phy = Σ_phy), :wald_derived))

# --- phylo_signal (fixture S, trait 1) --------------------------------------
push!(cases, Case("CI-ROUTE-015", "CORE070-INFERENCE-PHYLO-SIGNAL-CI-METHOD-ROUTE",
    () -> GLLVM.profile_ci_derived(fitS, phylo_signal_closure_1; y = YS, Σ_phy = Σ_phy, penalty_weight = 1e4), :profile))
push!(cases, Case("CI-ROUTE-016", "CORE070-INFERENCE-PHYLO-SIGNAL-CI-METHOD-ROUTE",
    () -> GLLVM.profile_ci_derived(fitS, phylo_signal_closure_1; y = YS, Σ_phy = Σ_phy, penalty_weight = 1e4), :profile))
push!(cases, Case("CI-ROUTE-017", "CORE070-INFERENCE-PHYLO-SIGNAL-CI-METHOD-ROUTE",
    () -> phylo_signal_wald_ci(fitS, 1; y = YS, Σ_phy = Σ_phy), :wald_derived))
push!(cases, Case("CI-ROUTE-018", "CORE070-INFERENCE-PHYLO-SIGNAL-CI-METHOD-ROUTE",
    () -> GLLVM.bootstrap_ci_derived(fitS, f -> phylo_signal(f)[1]; y = YS, Σ_phy = Σ_phy, n_boot = 6, seed = 11), :bootstrap))

# --- proportion:shared_unit (fixture S, trait 1, via icc_wald_ci reuse) -----
# proportions(fit; component=:shared) is mathematically identical to
# communality(fit) (see src/confint_derived.jl docstring); reusing the same
# packed closure this way is what the manifest's own julia_surface note asks
# for ("icc_wald_ci's docstring is explicitly generic over
# intraclass-correlation-style proportion quantities") -- verified equal to
# 1e-12 in the local smoke run, not merely assumed.
push!(cases, Case("CI-ROUTE-036", "CORE070-INFERENCE-PROPORTION-CI-METHOD-ROUTE",
    () -> icc_wald_ci(fitS, communality_packed_1; y = YS, Σ_phy = Σ_phy), :wald_derived))
push!(cases, Case("CI-ROUTE-037", "CORE070-INFERENCE-PROPORTION-CI-METHOD-ROUTE",
    () -> GLLVM.profile_ci_derived(fitS, communality_packed_1; y = YS, Σ_phy = Σ_phy, penalty_weight = 1e4), :profile))
push!(cases, Case("CI-ROUTE-038", "CORE070-INFERENCE-PROPORTION-CI-METHOD-ROUTE",
    () -> icc_wald_ci(fitS, communality_packed_1; y = YS, Σ_phy = Σ_phy), :wald_derived))
push!(cases, Case("CI-ROUTE-039", "CORE070-INFERENCE-PROPORTION-CI-METHOD-ROUTE",
    () -> GLLVM.bootstrap_ci_derived(fitS, f -> GLLVM.proportions(f; component = :shared)[1]; y = YS, Σ_phy = Σ_phy, n_boot = 6, seed = 12), :bootstrap))

length(cases) == 45 || error("internal: expected 45 executable cases, built $(length(cases))")

# ---------------------------------------------------------------------------
# Run every case.
# ---------------------------------------------------------------------------
function run_case(c::Case)
    t0 = time()
    ok = false
    actual = :error
    detail = ""
    try
        r = c.thunk()
        actual = c.expect == :reject ? :no_error : route_tag(r)
        ok = (c.expect != :reject) && (actual == c.expect)
        detail = "propertynames=" * string(propertynames(r))
    catch e
        if c.expect == :reject && e isa ArgumentError
            actual = :reject
            ok = true
            detail = sprint(showerror, e)
        else
            actual = :error
            ok = false
            detail = sprint(showerror, e)
        end
    end
    elapsed = time() - t0
    return Dict{String, Any}(
        "source_id" => c.source_id, "case_id" => c.case_id,
        "expect" => string(c.expect), "actual" => string(actual),
        "ok" => ok, "detail" => detail, "elapsed_seconds" => elapsed,
    )
end

results = [run_case(c) for c in cases]
all_ok = all(r -> r["ok"], results)

# ---------------------------------------------------------------------------
# Negative controls: deliberately-wrong field-presence assertions that MUST
# evaluate false. If either ever reports true, the route_tag() classifier
# used throughout this batch is broken and every PASS above is untrustworthy
# (the same discipline as core070_data_batch.R's negative controls).
# ---------------------------------------------------------------------------
wald_probe = confint(fitA, YA; parm = "Lambda_B[1,1]", method = :wald)
boot_probe = bootstrap_ci(fitA; parms = "Lambda_B[1,1]", y = YA, n_boot = 6, seed = 1)
nc1 = :n_converged in propertynames(wald_probe)   # a Wald result must NOT carry n_converged
nc2 = :se in propertynames(boot_probe)            # a bootstrap result must NOT carry se
negatives_ok = !nc1 && !nc2
push!(results, Dict("source_id" => "NEGATIVE-CONTROL-1", "case_id" => "n/a",
    "expect" => "false", "actual" => string(nc1), "ok" => !nc1,
    "detail" => "wald result must not carry :n_converged", "elapsed_seconds" => 0.0))
push!(results, Dict("source_id" => "NEGATIVE-CONTROL-2", "case_id" => "n/a",
    "expect" => "false", "actual" => string(nc2), "ok" => !nc2,
    "detail" => "bootstrap result must not carry :se", "elapsed_seconds" => 0.0))

overall_ok = all_ok && negatives_ok

# ---------------------------------------------------------------------------
# Minimal hand-rolled JSON writer (no JSON dependency in this project's
# Project.toml; output shapes here are plain nested Dict/Vector/String/
# Bool/Number, which this covers exactly).
# ---------------------------------------------------------------------------
_json_escape(s::AbstractString) = replace(replace(String(s), "\\" => "\\\\"), "\"" => "\\\"")
function write_json(io::IO, x; indent::Int = 0)
    pad = "  "^indent
    pad1 = "  "^(indent + 1)
    if x isa AbstractDict
        println(io, "{")
        ks = collect(keys(x))
        for (i, k) in enumerate(ks)
            print(io, pad1, "\"", _json_escape(string(k)), "\": ")
            write_json(io, x[k]; indent = indent + 1)
            println(io, i == length(ks) ? "" : ",")
        end
        print(io, pad, "}")
    elseif x isa AbstractVector
        if isempty(x)
            print(io, "[]")
        else
            println(io, "[")
            for (i, v) in enumerate(x)
                print(io, pad1)
                write_json(io, v; indent = indent + 1)
                println(io, i == length(x) ? "" : ",")
            end
            print(io, pad, "]")
        end
    elseif x isa AbstractString
        print(io, "\"", _json_escape(x), "\"")
    elseif x isa Bool
        print(io, x ? "true" : "false")
    elseif x isa Integer
        print(io, x)
    elseif x isa AbstractFloat
        print(io, isfinite(x) ? x : "null")
    elseif x === nothing
        print(io, "null")
    else
        print(io, "\"", _json_escape(string(x)), "\"")
    end
end
function write_json_file(path, x)
    open(path, "w") do io
        write_json(io, x)
        println(io)
    end
end

results_path = joinpath(destination, "inference-batch-results.json")
write_json_file(results_path, Dict(
    "status" => overall_ok ? "PASS" : "FAIL",
    "area" => "inference",
    "scope" => "CORE070_INFERENCE_BATCH",
    "case_count" => length(cases),
    "negative_control_count" => 2,
    "all_positive_pass" => all_ok,
    "negative_controls_behaved_as_expected" => negatives_ok,
    "julia_version" => string(VERSION),
    "gllvm_pkg_version" => string(Base.pkgversion(GLLVM)),
    "source_pins" => source_pins,
    "generated_at_epoch_seconds" => round(Int, time()),
    "cases" => results,
    "all_checks" => overall_ok,
))

raw_path = joinpath(destination, "raw.tsv")
open(raw_path, "w") do io
    for r in results
        println(io, r["source_id"], "\t", r["ok"] ? "PASS" : "FAIL", "\t", r["case_id"])
    end
end

receipt = Dict(
    "status" => overall_ok ? "PASS" : "FAIL",
    "scope" => "CORE070_INFERENCE_BATCH",
    "source_unchanged" => true,
    "source_pins" => source_pins,
    "case_count" => length(cases),
    "negative_control_count" => 2,
    "expected_case_source_ids" => [c.source_id for c in cases],
    "results_sha256" => sha256_file(results_path),
    "raw_sha256" => sha256_file(raw_path),
    "julia_runtime" => string(VERSION),
)
receipt_path = joinpath(destination, "receipt.json")
write_json_file(receipt_path, receipt)

n_pass = count(r -> r["ok"], results)
println("INFERENCE_BATCH_RESULT ", n_pass, " PASS ", length(results) - n_pass, " FAIL",
    " NEGATIVE_CONTROLS ", negatives_ok ? "OK" : "BROKEN")
println("CORE070_INFERENCE_BATCH_", overall_ok ? "PASS" : "FAIL")
exit(overall_ok ? 0 : 1)
