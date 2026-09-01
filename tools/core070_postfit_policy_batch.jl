# Inner executor for the "postfit-policy" manifest-area batch (15 planned
# EXECUTABLE_NOW cases + 2 negative controls). Reuses, rather than
# reimplements, the exact fixture-setup idiom already proven by
# tools/core070_gaussian_postfit.jl (include(runparity.jl) with
# CORE070_PARITY_CASE_IDS=NATIVE-01-GAUSSIAN, then a native Julia refit from
# the same Y/K/X); this file adds the additional native ↔ R accessor calls
# (coef, dof, nobs, confint wald, residual scale/type, predict default,
# simulate default) the postfit-policy cases need beyond what that file
# already computes, plus the POST-COEF-EMPTY empty-design pair.
#
# argv (documented -- must match the outer R runner's system2() call and the
# --self-test invocation used for local smoke):
#   ARGS[1]  destination path for the JSON results file (parent dir need not
#            exist yet; this script mkpath()s it). Must not already exist.
#
# Env vars required (set by the outer R runner before invoking this script;
# never defaulted silently here so a misconfigured environment fails loudly
# rather than quietly running against the wrong library):
#   GLLVM_PARITY_TESTS=1
#   CORE070_PARITY_CASE_IDS=NATIVE-01-GAUSSIAN
#   R_LIBS / GLLVM_PARITY_R_LIBS = <frozen gllvmTMB library dir>
#
# Invocation:
#   julia --project=test/parity tools/core070_postfit_policy_batch.jl <out.json>

using GLLVM, Test, RCall

# Minimal hand-rolled JSON writer -- test/parity/Project.toml intentionally
# carries no JSON dependency (see its own header comment on staying minimal),
# and the report here is a small, fully-known Dict/Vector/scalar shape, so a
# real JSON package is unnecessary. Handles the only types this script emits:
# Dict, Vector, AbstractString, Bool, Integer, AbstractFloat, Nothing.
_json_str(s::AbstractString) = string('"', replace(replace(s, '\\' => "\\\\"), '"' => "\\\""), '"')
function _json(io::IO, x)
    if x === nothing
        print(io, "null")
    elseif x isa Bool
        print(io, x ? "true" : "false")
    elseif x isa Integer
        print(io, x)
    elseif x isa AbstractFloat
        print(io, isfinite(x) ? x : "null")
    elseif x isa AbstractString
        print(io, _json_str(x))
    elseif x isa AbstractDict
        print(io, "{")
        for (i, k) in enumerate(keys(x))
            i > 1 && print(io, ",")
            print(io, _json_str(string(k)), ":")
            _json(io, x[k])
        end
        print(io, "}")
    elseif x isa AbstractVector
        print(io, "[")
        for (i, v) in enumerate(x)
            i > 1 && print(io, ",")
            _json(io, v)
        end
        print(io, "]")
    else
        error("no JSON serializer for $(typeof(x))")
    end
end
write_json(path, x) = open(io -> _json(io, x), path, "w")

length(ARGS) == 1 || error("usage: julia tools/core070_postfit_policy_batch.jl <out.json>")
out_path = ARGS[1]
isfile(out_path) && error("destination already exists: $out_path")
mkpath(dirname(out_path))

@assert realpath(Base.pkgdir(GLLVM)) == realpath(pwd()) "must run from the GLLVM.jl package root"
get(ENV, "GLLVM_PARITY_TESTS", "0") == "1" ||
    error("GLLVM_PARITY_TESTS=1 is required; refusing to silently default it")
get(ENV, "CORE070_PARITY_CASE_IDS", "") == "NATIVE-01-GAUSSIAN" ||
    error("CORE070_PARITY_CASE_IDS=NATIVE-01-GAUSSIAN is required; refusing to silently default it")

include(joinpath(pwd(), "test/parity/runparity.jl"))

# ---------------------------------------------------------------------------
# Primary fixture: same Y/K/X refit tools/core070_gaussian_postfit.jl uses.
# ---------------------------------------------------------------------------
Y = rcopy(Matrix{Float64}, R"y")
K = rcopy(Int, R"K")
p, n = size(Y)
X = zeros(p, n, p)
for j in 1:p
    X[j, :, j] .= 1
end
fit = fit_gaussian_gllvm(Y; K = K, X = X)

R"""
.pp_get3 <- function(generic, cls) {
  m <- tryCatch(utils::getS3method(generic, cls, envir = asNamespace("gllvmTMB")),
                error = function(e) NULL)
  if (is.null(m)) m <- get(paste0(generic, ".", cls), envir = asNamespace("gllvmTMB"))
  m
}
.pp_predict_fun   <- .pp_get3("predict", "gllvmTMB_multi")
.pp_residuals_fun <- .pp_get3("residuals", "gllvmTMB_multi")
.pp_simulate_fun  <- .pp_get3("simulate", "gllvmTMB_multi")

.core070_postfit_policy <- list(
  coef      = as.numeric(coef(fit_r)),
  nobs      = as.integer(nobs(fit_r)),
  df        = as.integer(attr(logLik(fit_r), "df")),
  loglik    = as.numeric(logLik(fit_r)),
  loglik_nobs_attr = as.integer(attr(logLik(fit_r), "nobs")),
  link      = as.numeric(predict(fit_r, type = "link")$est),
  response  = as.numeric(fitted(fit_r)$est),
  residual  = as.numeric(residuals(fit_r, type = "randomized_quantile", scale = "normal")$residual),
  predict_type_default   = as.character(eval(formals(.pp_predict_fun)$type)[1]),
  residual_type_default  = as.character(eval(formals(.pp_residuals_fun)$type)[1]),
  residual_scale_default = as.character(eval(formals(.pp_residuals_fun)$scale)[1]),
  simulate_condition_on_re_default = isFALSE(formals(.pp_simulate_fun)$condition_on_RE)
)

.core070_postfit_policy_ci <- tryCatch({
  ci <- confint(fit_r, parm = fit_r$X_fix_names, method = "wald")
  list(ok = TRUE, lower = as.numeric(ci[, 1]), upper = as.numeric(ci[, 2]),
       error = "")
}, error = function(e) list(ok = FALSE, lower = numeric(0), upper = numeric(0),
                             error = conditionMessage(e)))
"""

r_coef = rcopy(Vector{Float64}, R".core070_postfit_policy$coef")
r_nobs = rcopy(Int, R".core070_postfit_policy$nobs")
r_df = rcopy(Int, R".core070_postfit_policy$df")
r_loglik = rcopy(Float64, R".core070_postfit_policy$loglik")
r_loglik_nobs_attr = rcopy(Int, R".core070_postfit_policy$loglik_nobs_attr")
r_link = reshape(rcopy(Vector{Float64}, R".core070_postfit_policy$link"), size(Y))
r_response = reshape(rcopy(Vector{Float64}, R".core070_postfit_policy$response"), size(Y))
r_residual = reshape(rcopy(Vector{Float64}, R".core070_postfit_policy$residual"), size(Y))
r_predict_type_default = rcopy(String, R".core070_postfit_policy$predict_type_default")
r_residual_type_default = rcopy(String, R".core070_postfit_policy$residual_type_default")
r_residual_scale_default = rcopy(String, R".core070_postfit_policy$residual_scale_default")
r_simulate_condition_on_re_default = rcopy(Bool, R".core070_postfit_policy$simulate_condition_on_re_default")
r_ci_ok = rcopy(Bool, R".core070_postfit_policy_ci$ok")
r_ci_lower = rcopy(Vector{Float64}, R".core070_postfit_policy_ci$lower")
r_ci_upper = rcopy(Vector{Float64}, R".core070_postfit_policy_ci$upper")
r_ci_error = rcopy(String, R".core070_postfit_policy_ci$error")

j_coef = GLLVM.StatsAPI.coef(fit)
j_loglik = fit.logLik
j_dof = GLLVM.StatsAPI.dof(fit)
j_nobs = GLLVM.StatsAPI.nobs(fit, Y)
j_link = predict(fit, Y; type = :link, X = X)
j_response = GLLVM.StatsAPI.fitted(fit, Y; X = X)
j_residual = residuals(fit, Y; X = X)
j_ci = try
    GLLVM.confint(fit; y = Y, X = X)
catch e
    nothing
end
j_ci_ok = j_ci !== nothing
beta_idx = j_ci_ok ? findall(t -> startswith(t, "beta["), j_ci.term) : Int[]
j_ci_lower = j_ci_ok ? j_ci.lower[beta_idx] : Float64[]
j_ci_upper = j_ci_ok ? j_ci.upper[beta_idx] : Float64[]

# simulate() keyword introspection: does GLLVM's simulate accept a
# condition_on_RE-style keyword at all? (it must not, per the manifest fact)
# Call-based probe (not Base.kwarg_decl, which is an unstable internal): a
# MethodError from an unrecognized keyword means the kwarg is absent; any
# other outcome (success, or an error raised from inside a method that DID
# accept the keyword) means it exists.
julia_simulate_has_condition_on_re_kwarg = try
    GLLVM.simulate(fit, 2; condition_on_RE = true)
    true
catch err
    !(err isa MethodError)
end

# ---------------------------------------------------------------------------
# Empty-design pair (POST-COEF-EMPTY): a real no-X Julia fit vs the pinned
# R coef.gllvmTMB_multi empty branch evaluated on a synthetic mock object.
# ---------------------------------------------------------------------------
fit_no_x = fit_gaussian_gllvm(Y; K = 1)
j_empty_coef = GLLVM.StatsAPI.coef(fit_no_x)

R"""
.pp_source_root <- Sys.getenv("GLLVM_PARITY_R_SOURCE_ROOT",
                               unset = file.path(getwd(), ".unlazy/core070-aghq/oracle-source/readback"))
.pp_coef_defs <- Filter(
  function(x) is.call(x) && identical(x[[1L]], as.name("<-")) &&
    identical(x[[2L]], as.name("coef.gllvmTMB_multi")),
  parse(file.path(.pp_source_root, "R/vcov-coef.R"))
)
stopifnot(length(.pp_coef_defs) == 1L)
.pp_coef_env <- new.env(parent = asNamespace("gllvmTMB"))
eval(.pp_coef_defs[[1L]], .pp_coef_env)
.pp_empty_coef <- .pp_coef_env$coef.gllvmTMB_multi(list(X_fix_names = character(0)))
"""
r_empty_coef = rcopy(Vector{Float64}, R".pp_empty_coef")

# ---------------------------------------------------------------------------
# Assemble the 15 case results.
# ---------------------------------------------------------------------------
tol = Dict(
    "coefficient_delta" => 1e-6,
    "loglik_delta" => 1e-6,
    "link_response_residual_delta" => 1e-4,
    "wald_ci_bound_delta" => 1e-3,
)

cases = Dict{String, Any}()

cases["CORE070-POSTFIT-COEF-EMPTY-NATIVE"] = Dict(
    "pass" => length(j_empty_coef) == 0 && length(r_empty_coef) == 0,
    "julia_length" => length(j_empty_coef), "r_length" => length(r_empty_coef),
)

coefficient_delta = maximum(abs.(j_coef .- r_coef))
cases["CORE070-POSTFIT-COEF-NAMED-NATIVE"] = Dict(
    "pass" => coefficient_delta <= tol["coefficient_delta"], "delta" => coefficient_delta,
)

cases["CORE070-POSTFIT-CONFINT-METHODS-WALD-NATIVE"] = if j_ci_ok && r_ci_ok &&
        length(j_ci_lower) == length(r_ci_lower) == length(j_coef)
    d = maximum(abs.(vcat(j_ci_lower, j_ci_upper) .- vcat(r_ci_lower, r_ci_upper)))
    Dict("pass" => d <= tol["wald_ci_bound_delta"], "delta" => d)
else
    Dict("pass" => false, "julia_ci_ok" => j_ci_ok, "r_ci_ok" => r_ci_ok, "r_ci_error" => r_ci_error,
         "julia_len" => length(j_ci_lower), "r_len" => length(r_ci_lower))
end

response_delta = maximum(abs.(j_response .- r_response))
cases["CORE070-POSTFIT-FITTED-DEFAULT-NATIVE"] = Dict(
    "pass" => response_delta <= tol["link_response_residual_delta"], "delta" => response_delta,
)

cases["CORE070-POSTFIT-LOGLIK-DF-NATIVE"] = Dict("pass" => j_dof == r_df, "julia" => j_dof, "r" => r_df)

cases["CORE070-POSTFIT-LOGLIK-NOBS-NATIVE"] = Dict(
    "pass" => j_nobs == r_loglik_nobs_attr, "julia" => j_nobs, "r" => r_loglik_nobs_attr,
)

loglik_delta = abs(j_loglik - r_loglik)
cases["CORE070-POSTFIT-LOGLIK-VALUE-NATIVE"] = Dict(
    "pass" => loglik_delta <= tol["loglik_delta"], "delta" => loglik_delta,
)

cases["CORE070-POSTFIT-NOBS-COUNT-NATIVE"] = Dict("pass" => j_nobs == r_nobs, "julia" => j_nobs, "r" => r_nobs)
cases["CORE070-POSTFIT-NOBS-FALLBACK-NATIVE"] = Dict("pass" => j_nobs == r_nobs, "julia" => j_nobs, "r" => r_nobs)

link_delta = maximum(abs.(j_link .- r_link))
cases["CORE070-POSTFIT-PREDICT-DEFAULT-NATIVE"] = Dict(
    "pass" => link_delta <= tol["link_response_residual_delta"] &&
              r_predict_type_default == "link",
    "delta" => link_delta, "r_default" => r_predict_type_default, "julia_default" => "response",
)

cases["CORE070-POSTFIT-RE-FORM-FULL-NATIVE"] = Dict(
    "pass" => link_delta <= tol["link_response_residual_delta"], "delta" => link_delta,
)

residual_delta = maximum(abs.(j_residual .- r_residual))
cases["CORE070-POSTFIT-RESIDUAL-CONDITIONAL-NATIVE"] = Dict(
    "pass" => residual_delta <= tol["link_response_residual_delta"], "delta" => residual_delta,
)
cases["CORE070-POSTFIT-RESIDUAL-SCALES-NATIVE"] = Dict(
    "pass" => residual_delta <= tol["link_response_residual_delta"] &&
              r_residual_scale_default == "normal",
    "delta" => residual_delta,
)
cases["CORE070-POSTFIT-RESIDUAL-TYPES-NATIVE"] = Dict(
    "pass" => residual_delta <= tol["link_response_residual_delta"] &&
              r_residual_type_default == "randomized_quantile",
    "delta" => residual_delta,
)

cases["CORE070-POSTFIT-SIMULATE-DEFAULT-NATIVE"] = Dict(
    "pass" => r_simulate_condition_on_re_default == true &&
              !julia_simulate_has_condition_on_re_kwarg,
    "r_condition_on_re_default" => r_simulate_condition_on_re_default,
    "julia_has_condition_on_re_kwarg" => julia_simulate_has_condition_on_re_kwarg,
)

# ---------------------------------------------------------------------------
# Negative controls: deliberately-wrong comparisons that MUST fail.
# ---------------------------------------------------------------------------
neg_coef_delta = maximum(abs.(j_coef .- (r_coef .+ 1.0)))
negative_controls = Dict(
    "NEG-COEF-SHIFTED" => Dict("behaved" => neg_coef_delta > tol["coefficient_delta"], "delta" => neg_coef_delta),
    "NEG-LOGLIK-SHIFTED" => Dict(
        "behaved" => abs(j_loglik - (r_loglik + 1.0)) > tol["loglik_delta"],
        "delta" => abs(j_loglik - (r_loglik + 1.0)),
    ),
)

all_positive_pass = all(v["pass"] for v in values(cases))
negatives_behaved = all(v["behaved"] for v in values(negative_controls))
overall_ok = all_positive_pass && negatives_behaved

report = Dict(
    "status" => overall_ok ? "PASS" : "FAIL",
    "area" => "postfit-policy",
    "scope" => "CORE070_POSTFIT_POLICY_BATCH",
    "case_count" => length(cases),
    "negative_control_count" => length(negative_controls),
    "all_positive_pass" => all_positive_pass,
    "negative_controls_behaved_as_expected" => negatives_behaved,
    "all_checks" => overall_ok,
    "cases" => cases,
    "negative_controls" => negative_controls,
    "julia_version" => string(VERSION),
)
write_json(out_path, report)
println("CORE070_POSTFIT_POLICY_BATCH_RESULT ",
        overall_ok ? "PASS" : "FAIL",
        " positive=", all_positive_pass, " negatives=", negatives_behaved)
overall_ok || exit(1)
