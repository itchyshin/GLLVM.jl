# Runtime evidence for the postfit-2 batch: for every one of the 39
# native/bridge/readback rows in docs/dev-log/core070/postfit-2-batch-contract.json
# (all classified NEEDS_NEW_JULIA_SURFACE — see that contract's `rows`), records
# whether the GLLVM module genuinely lacks the required surface. This is a
# real runtime check against the loaded module, not an assumption:
#   - `isdefined(GLLVM, Symbol(name))` for every candidate top-level symbol
#     the row's julia_surface could plausibly be exported/bound as;
#   - for rows where a same-named function DOES exist but with materially
#     different required behaviour (predict/residuals/simulate/summary/vcov/
#     nobs/loglikelihood/ordiplot/rotation), a live functional PROBE against a
#     real `fit_gaussian_gllvm(...)` fit -- e.g. checking whether `newdata` is
#     a valid keyword of `predict`, whether `residuals(...; type=:simulation_rank)`
#     is accepted or throws, whether `summary(fit)` returns a String (wrong
#     shape) rather than a structured header+table object, whether `vcov(fit)`
#     can be called with zero extra arguments the way R's `vcov(object)` can.
#   - source-only rows (their whole required contract does not exist under any
#     name) are checked by isdefined() alone and are expected to be false.
#
# ARGV[1] is REQUIRED and is the output JSON path to write the receipt to
# (mkpath'd if its directory does not exist). No frozen R library, no fit
# comparison, no bridge call: this script only touches the local GLLVM module.
# Usage: julia --project=. tools/core070_postfit_2_batch.jl <output.json>

using GLLVM
using Random
using LinearAlgebra

length(ARGS) >= 1 || error("usage: julia --project=. tools/core070_postfit_2_batch.jl <output.json>")
output_path = ARGS[1]

# ---------------------------------------------------------------------------
# Minimal JSON writer (no external dependency; mirrors tools/core070_data_batch.jl).
# ---------------------------------------------------------------------------
json_escape(s::AbstractString) = replace(s, "\\" => "\\\\", "\"" => "\\\"")
to_json(x::Bool) = x ? "true" : "false"
to_json(x::Nothing) = "null"
to_json(x::AbstractString) = "\"" * json_escape(x) * "\""
to_json(x::Integer) = string(x)
to_json(x::AbstractFloat) = string(x)
to_json(x::AbstractVector) = "[" * join(to_json.(x), ",") * "]"
to_json(x::AbstractDict) = "{" * join(("\"$(json_escape(string(k)))\":" * to_json(v) for (k, v) in x), ",") * "}"

function kwarg_names(f)
    names_seen = Set{Symbol}()
    for m in methods(f)
        try
            for k in Base.kwarg_decl(m)
                ks = string(k)
                endswith(ks, "...") && continue
                push!(names_seen, Symbol(ks))
            end
        catch
            continue
        end
    end
    names_seen
end
has_kwarg(f, name::String) = Symbol(name) in kwarg_names(f)

# ---------------------------------------------------------------------------
# One small real fit, used only for functional probes (existence-of-behaviour
# checks), never for any R comparison.
# ---------------------------------------------------------------------------
Random.seed!(20260901)
const P, K, N = 6, 2, 80
const Lt = 0.8 .* randn(P, K)
const Y = Lt * randn(K, N) .+ 0.5 .* randn(P, N)
const FIT = fit_gaussian_gllvm(Y; K = K)

# ---------------------------------------------------------------------------
# 39 rows -> candidate symbol groups (existence-only) or functional probes.
# `probe` entries are (description, closure) -> Bool "required behaviour IS present".
# absent == true means "confirmed absent" (good: matches NEEDS_NEW_JULIA_SURFACE).
# ---------------------------------------------------------------------------
rows = Dict{String,Any}()

function existence_row!(rows, key, candidate_symbols)
    found = [s for s in candidate_symbols if isdefined(GLLVM, Symbol(s))]
    rows[key] = Dict(
        "check_kind" => "existence",
        "candidate_exported_symbols" => candidate_symbols,
        "found_symbols" => found,
        "surface_absent" => isempty(found),
    )
end

function probe_row!(rows, key, description, absent_bool; extra = Dict{String,Any}())
    d = Dict{String,Any}(
        "check_kind" => "functional_probe",
        "probe_description" => description,
        "surface_absent" => absent_bool,
    )
    merge!(d, extra)
    rows[key] = d
end

# --- pure existence rows (no same-named symbol anywhere in the module) -----
existence_row!(rows, "loading_profile", ["loading_profile"])
existence_row!(rows, "plot.gllvmTMB_multi", ["plot"])
existence_row!(rows, "plot.profile_derived", ["plot"])
existence_row!(rows, "plot.profile_loadings", ["plot"])
existence_row!(rows, "plot_Sigma_comparison", ["plot_Sigma_comparison", "extract_Sigma"])
existence_row!(rows, "plot_Sigma_heatmap", ["plot_Sigma_heatmap", "extract_Sigma"])
existence_row!(rows, "plot_Sigma_table", ["plot_Sigma_table", "extract_Sigma"])
existence_row!(rows, "plot_anisotropy", ["plot_anisotropy"])
existence_row!(rows, "plot_anisotropy2", ["plot_anisotropy2"])
existence_row!(rows, "plot_correlations", ["plot_correlations", "extract_correlations"])
existence_row!(rows, "plot_loadings_confidence_eye", ["plot_loadings_confidence_eye"])
existence_row!(rows, "plot_rotated_loadings", ["plot_rotated_loadings"])
existence_row!(rows, "predict_cross_covariance", ["predict_cross_covariance"])
existence_row!(rows, "predict_missing", ["predict_missing"])
existence_row!(rows, "predictive_check", ["predictive_check"])
existence_row!(rows, "profile_ci_phylo_signal", ["profile_ci_phylo_signal"])
existence_row!(rows, "profile_ci_total_variance", ["profile_ci_total_variance"])
existence_row!(rows, "profile_cross_rho", ["profile_cross_rho"])
existence_row!(rows, "profile_cross_rho_ci", ["profile_cross_rho_ci"])
existence_row!(rows, "profile_phylo_signal", ["profile_phylo_signal"])
existence_row!(rows, "profile_targets", ["profile_targets"])
existence_row!(rows, "sanity_multi", ["sanity_multi"])
existence_row!(rows, "simulate_site_trait", ["simulate_site_trait"])
existence_row!(rows, "simulate_unit_trait", ["simulate_unit_trait"])
existence_row!(rows, "slope_sd_ci", ["slope_sd_ci"])
existence_row!(rows, "standard_errors", ["standard_errors"])
existence_row!(rows, "tidy.gllvmTMB_multi", ["tidy"])
existence_row!(rows, "tmbprofile_wrapper", ["tmbprofile_wrapper"])

# rotate_loadings: the *name* is absent (only `rotation`/`getLoadings` exist,
# and `rotation` is principal/SVD-only -- no method= kwarg at all).
let found = isdefined(GLLVM, :rotate_loadings)
    absent = !found && !has_kwarg(GLLVM.rotation, "method")
    probe_row!(rows, "rotate_loadings",
        "rotate_loadings not isdefined, and GLLVM.rotation(fit) (the only rotation entry point) has no `method` keyword (varimax/promax/none) -- confirms no varimax/promax rotation surface exists under any name",
        absent; extra = Dict("rotate_loadings_isdefined" => found, "rotation_has_method_kwarg" => has_kwarg(GLLVM.rotation, "method")))
end

# --- functional probes against the live FIT ---------------------------------

# logLik: loglikelihood(fit) exists, but no mspl/likelihood_weights guard-class
# concept anywhere in the module (no field, no throw path to probe against a
# plain Gaussian fit, and no exported guard symbol).
let guard_syms = ["mspl", "MsplFit", "LikelihoodWeights", "likelihood_weights"]
    found_guard = [s for s in guard_syms if isdefined(GLLVM, Symbol(s))]
    has_field = hasfield(typeof(FIT), :mspl) || hasfield(typeof(FIT), :likelihood_weights)
    absent = isempty(found_guard) && !has_field
    probe_row!(rows, "logLik.gllvmTMB_multi",
        "loglikelihood(fit) exists and returns a value, but no mspl-estimator or likelihood_weights guard-class concept is defined anywhere in GLLVM (no matching exported symbol, no matching field on the fit struct) -- the two required rejection branches have no Julia equivalent to test",
        absent; extra = Dict("base_symbol_exists" => isdefined(GLLVM, :loglikelihood), "guard_symbols_found" => found_guard))
end

# nobs: StatsAPI.nobs(fit) exists, but is a site/level count, not a
# missing-data-aware 3-way likelihood-row precedence.
let precedence_syms = ["likelihood_rows", "is_y_observed", "MissingDataControl", "missing_data"]
    found = [s for s in precedence_syms if isdefined(GLLVM, Symbol(s))]
    absent = isempty(found)
    probe_row!(rows, "nobs.gllvmTMB_multi",
        "StatsAPI.nobs(fit) exists (site/level count via hasfield dispatch) but no missing-data-aware likelihood-row-count precedence (likelihood_rows / is_y_observed / MissingDataControl) exists anywhere in GLLVM to exercise the masked-fixture branch the spec requires",
        absent; extra = Dict("base_symbol_exists" => isdefined(GLLVM, Symbol("nobs")), "precedence_symbols_found" => found))
end

# ordiplot.gllvmTMB_multi: ordiplot(fit, Y; rotate, biplot, ...) exists but has
# no `level` or `axes` keyword, and `rotate` is a Bool, not a rotation-method
# selector, so `rotate="none"` cannot be expressed.
let has_level = has_kwarg(GLLVM.ordiplot, "level")
    has_axes = has_kwarg(GLLVM.ordiplot, "axes")
    absent = !has_level && !has_axes
    probe_row!(rows, "ordiplot.gllvmTMB_multi",
        "ordiplot(fit, Y; rotate::Bool, biplot, site_labels, species_labels) exists but has no `level` or `axes` keyword (R's ordiplot(fit, level=, axes=c(1,2), rotate=\"none\") cannot be expressed), and returns (sites, species, ...) rather than (scores, loadings, sc)",
        absent; extra = Dict("base_symbol_exists" => isdefined(GLLVM, :ordiplot), "has_level_kwarg" => has_level, "has_axes_kwarg" => has_axes))
end

# predict.gllvmTMB_multi: predict(fit, y; type, ...) exists but is in-sample
# only -- no `newdata`, no `re_form`.
let has_newdata = has_kwarg(GLLVM.predict, "newdata")
    has_re_form = has_kwarg(GLLVM.predict, "re_form")
    absent = !has_newdata && !has_re_form
    probe_row!(rows, "predict.gllvmTMB_multi",
        "predict(fit, y; type=:response|:link, X=, X_lv=, mask=, offset=) exists but has no `newdata` or `re_form` keyword on any method -- R's newdata-based out-of-sample prediction and fixed-vs-conditional re_form path cannot be expressed",
        absent; extra = Dict("base_symbol_exists" => isdefined(GLLVM, :predict), "has_newdata_kwarg" => has_newdata, "has_re_form_kwarg" => has_re_form))
end

# residuals.gllvmTMB_multi: residuals(fit, y; type=...) only accepts
# :dunnsmyth/:pearson; live-probe that the R-required :simulation_rank value
# is rejected (ArgumentError), and that no `nsim`/`seed`/`condition_on_RE`
# keyword exists.
let rejects_simulation_rank = try
        residuals(FIT, Y; type = :simulation_rank)
        false   # did NOT throw -> surface unexpectedly present
    catch e
        e isa ArgumentError
    end
    has_nsim = has_kwarg(GLLVM.residuals, "nsim")
    has_condition = has_kwarg(GLLVM.residuals, "condition_on_RE")
    absent = rejects_simulation_rank && !has_nsim && !has_condition
    probe_row!(rows, "residuals.gllvmTMB_multi",
        "residuals(fit, y; type=:dunnsmyth|:pearson, ...) live-probed with type=:simulation_rank throws ArgumentError (the R-required type value is rejected), and no nsim/condition_on_RE keyword exists -- R's randomized_quantile/simulation_rank + nsim/seed/condition_on_RE contract has no Julia equivalent",
        absent; extra = Dict("base_symbol_exists" => isdefined(GLLVM, :residuals),
                              "type_simulation_rank_rejected" => rejects_simulation_rank,
                              "has_nsim_kwarg" => has_nsim, "has_condition_on_RE_kwarg" => has_condition))
end

# simulate.gllvmTMB_multi: simulate(fit, n; rng) exists but takes a required
# positional draw-count `n`, not `nsim=1`, and has no `newdata`/`condition_on_RE`.
let has_newdata = has_kwarg(GLLVM.simulate, "newdata")
    has_condition = has_kwarg(GLLVM.simulate, "condition_on_RE")
    absent = !has_newdata && !has_condition
    probe_row!(rows, "simulate.gllvmTMB_multi",
        "simulate(fit, n::Integer; rng=) exists (positional draw-count, RNG-object seeding) but has no `newdata` or `condition_on_RE` keyword -- R's newdata-conditional path and the documented Gaussian-on-link-scale newdata fallback cannot be expressed",
        absent; extra = Dict("base_symbol_exists" => isdefined(GLLVM, :simulate), "has_newdata_kwarg" => has_newdata, "has_condition_on_RE_kwarg" => has_condition))
end

# print.gllvmTMB_multi: Base.show(io, MIME"text/plain", fit) exists (live-
# probed via sprint) but the printed text has none of the required structural
# fields (n_traits/unit-count/covstruct-labels/fixed-effect-count/estimator-
# engine-mspl); fit struct also carries none of these fields, confirming the
# text is not merely differently worded but structurally missing the data.
let text = sprint(show, MIME("text/plain"), FIT)
    missing_fields = [f for f in (:n_traits, :covstruct, :estimator, :engine, :mspl) if !hasfield(typeof(FIT), f)]
    absent = length(missing_fields) == 5 &&
             !occursin("covstruct", text) && !occursin("estimator", text) && !occursin("engine", text)
    probe_row!(rows, "print.gllvmTMB_multi",
        "sprint(show, MIME(\"text/plain\"), fit) is live-probed: prints only p/K/integration/logLik/AIC/converged/iterations, and the fit struct has none of n_traits/covstruct/estimator/engine/mspl as fields -- the required structural-summary fields have no Julia representation to print",
        absent; extra = Dict("base_symbol_exists" => true, "missing_fields" => string.(missing_fields), "probed_text_length" => length(text)))
end

# print.summary.gllvmTMB_multi: cascades from summary.gllvmTMB_multi (below):
# since summary(fit) is a plain String, there is no structured object for a
# print method to render fields of at all.
probe_row!(rows, "print.summary.gllvmTMB_multi",
    "depends entirely on summary.gllvmTMB_multi's structured header+fixef-table+Sigma_B object, which does not exist (summary(fit) returns a plain String; see the summary.gllvmTMB_multi row) -- there is nothing structured for a print method to render",
    true; extra = Dict("depends_on" => "summary.gllvmTMB_multi"))

# summary.gllvmTMB_multi: Base.summary(fit) exists but returns a plain String
# (one-line description), not a structured header+fixef-table+Sigma_B object.
let result = summary(FIT)
    wrong_shape = result isa AbstractString
    probe_row!(rows, "summary.gllvmTMB_multi",
        "summary(fit) is live-probed and returns a plain String (one-line fit description), not the required structured header-list + fixef-table + Sigma_B object",
        wrong_shape; extra = Dict("base_symbol_exists" => isdefined(GLLVM, Symbol("summary")), "probed_return_type" => string(typeof(result))))
end

# vcov.gllvmTMB_multi: StatsAPI.vcov requires an explicit `y`/Y argument and
# returns a Diagonal (SE^2 only, no off-diagonal covariance, no dimnames),
# whereas R's vcov(object) takes the fit alone and returns a named dense
# p x p matrix aligned to the free/fixed coefficient mask.
let zero_arg_fails = try
        Base.invokelatest(GLLVM.StatsAPI.vcov, FIT)
        false
    catch e
        true
    end
    result = GLLVM.StatsAPI.vcov(FIT, Y)
    is_diagonal_only = result isa Diagonal
    absent = zero_arg_fails && is_diagonal_only
    probe_row!(rows, "vcov.gllvmTMB_multi",
        "vcov(fit) alone (no y/Y) throws ArgumentError (R's zero-extra-argument vcov(object) contract cannot be expressed), and vcov(fit, Y) live-probed returns a Diagonal (SE^2 only) rather than a named dense p x p covariance matrix aligned to a free/fixed coefficient mask",
        absent; extra = Dict("base_symbol_exists" => isdefined(GLLVM, Symbol("vcov")), "zero_arg_vcov_throws" => zero_arg_fails, "probed_return_type" => string(typeof(result))))
end

all_absent = all(r["surface_absent"] for r in values(rows))
expected_row_count = 39
row_count_ok = length(rows) == expected_row_count

receipt = Dict(
    "schema" => "core070-postfit-2-batch-julia-introspection/v1",
    "scope" => "CORE070_POSTFIT_2_BATCH_JULIA_SURFACE_ABSENCE",
    "reference_commit" => "b4d5fee64def88bc768dda1f1f77c29b295edd86",
    "julia_version" => string(VERSION),
    "gllvm_exported_symbol_count" => length(names(GLLVM)),
    "probe_fit" => Dict("p" => P, "K" => K, "n" => N, "fit_type" => string(typeof(FIT))),
    "rows" => rows,
    "row_count" => length(rows),
    "expected_row_count" => expected_row_count,
    "row_count_ok" => row_count_ok,
    "all_planned_surfaces_absent" => all_absent,
)

mkpath(dirname(abspath(output_path)))
open(output_path, "w") do io
    print(io, to_json(receipt))
end

ok = all_absent && row_count_ok
println("CORE070_POSTFIT_2_BATCH_JULIA_INTROSPECTION_", ok ? "ALL_39_SURFACES_ABSENT" : "SURFACE_FOUND_OR_ROW_MISMATCH_REVIEW_CONTRACT")
exit(ok ? 0 : 1)
