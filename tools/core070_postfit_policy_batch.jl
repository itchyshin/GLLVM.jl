# Inner executor for the "postfit-policy" manifest-area batch (15 planned
# EXECUTABLE_NOW cases + 2 negative controls).
#
# REPAIR NOTE (2026-09-01, Totoro incident): the prior version of this file
# `include()`d the ENTIRE test/parity/runparity.jl parity runner and used
# RCall to embed a live R session, obtaining the R oracle numbers by @rput
# fixture data into it and driving gllvmTMB(). On Totoro that first
# segfaulted (exit 139 for the subprocess julia process; cured only by
# LD_PRELOAD=<julia>/lib/julia/libunwind.so.8 -- an RCall/libunwind
# interaction worth remembering if a future runner hits the same signal),
# then failed inside test/parity/test_negbin_parity.jl -- an out-of-scope
# RCall fixture the runparity.jl runner reaches internally, well beyond this
# batch's 15-case scope. This file is now a pure-Julia consumer: it reads a
# JSON oracle file the paired R runner (tools/core070_postfit_policy_batch.R)
# writes BEFORE invoking this script -- that R process already has the
# frozen gllvmTMB library loaded and does 100% of the live R fitting itself
# -- refits the identical Y natively with fit_gaussian_gllvm, and compares
# via direct `using GLLVM` module calls only. No RCall, no parity-runner
# include, no R of any kind runs in this process.
#
# argv:
#   ARGS[1]  destination path for the JSON results file (parent dir need not
#            exist yet; this script mkpath()s it). Must not already exist.
#
# Env vars required (set by the outer R runner before invoking this script;
# never defaulted silently here so a misconfigured environment fails loudly
# rather than quietly running against stale or missing oracle data):
#   CORE070_POSTFIT_POLICY_R_ORACLE = <path to the R-written oracle JSON>
#
# Invocation:
#   julia --project=. tools/core070_postfit_policy_batch.jl <out.json>

using GLLVM

# ---------------------------------------------------------------------------
# Minimal JSON reader/writer (no external dependency; mirrors the existing
# repo convention in tools/core070_postfit_1_batch.jl / core070_data_batch.jl).
# ---------------------------------------------------------------------------
function json_read(path::AbstractString)
    txt = read(path, String)
    pos = Ref(1)
    skip_ws!() = begin
        while pos[] <= lastindex(txt) && isspace(txt[pos[]])
            pos[] = nextind(txt, pos[])
        end
    end
    local parse_value
    function parse_string()
        pos[] += 1 # opening quote
        buf = IOBuffer()
        while true
            c = txt[pos[]]
            if c == '"'
                pos[] = nextind(txt, pos[])
                break
            elseif c == '\\'
                pos[] = nextind(txt, pos[])
                e = txt[pos[]]
                if e == 'n'; write(buf, '\n')
                elseif e == 't'; write(buf, '\t')
                elseif e == 'u'
                    hex = txt[nextind(txt, pos[]):nextind(txt, pos[], 4)]
                    write(buf, Char(parse(UInt32, hex; base = 16)))
                    pos[] = nextind(txt, pos[], 4)
                else write(buf, e)
                end
                pos[] = nextind(txt, pos[])
            else
                write(buf, c)
                pos[] = nextind(txt, pos[])
            end
        end
        String(take!(buf))
    end
    function parse_number()
        start = pos[]
        while pos[] <= lastindex(txt) && (isdigit(txt[pos[]]) || txt[pos[]] in ('-', '+', '.', 'e', 'E'))
            pos[] = nextind(txt, pos[])
        end
        s = txt[start:prevind(txt, pos[])]
        return occursin('.', s) || occursin('e', s) || occursin('E', s) ? parse(Float64, s) : parse(Int, s)
    end
    function parse_array()
        pos[] += 1
        out = Any[]
        skip_ws!()
        if txt[pos[]] == ']'
            pos[] = nextind(txt, pos[])
            return out
        end
        while true
            skip_ws!()
            push!(out, parse_value())
            skip_ws!()
            if txt[pos[]] == ','
                pos[] = nextind(txt, pos[])
            elseif txt[pos[]] == ']'
                pos[] = nextind(txt, pos[])
                break
            end
        end
        out
    end
    function parse_object()
        pos[] += 1
        out = Dict{String, Any}()
        skip_ws!()
        if txt[pos[]] == '}'
            pos[] = nextind(txt, pos[])
            return out
        end
        while true
            skip_ws!()
            k = parse_string()
            skip_ws!()
            @assert txt[pos[]] == ':'
            pos[] = nextind(txt, pos[])
            skip_ws!()
            out[k] = parse_value()
            skip_ws!()
            if txt[pos[]] == ','
                pos[] = nextind(txt, pos[])
            elseif txt[pos[]] == '}'
                pos[] = nextind(txt, pos[])
                break
            end
        end
        out
    end
    parse_value = function ()
        skip_ws!()
        c = txt[pos[]]
        if c == '"'; return parse_string()
        elseif c == '['; return parse_array()
        elseif c == '{'; return parse_object()
        elseif c == 't'; pos[] += 4; return true
        elseif c == 'f'; pos[] += 5; return false
        elseif c == 'n'; pos[] += 4; return nothing
        else; return parse_number()
        end
    end
    skip_ws!()
    parse_value()
end

json_escape(s::AbstractString) = replace(s, "\\" => "\\\\", "\"" => "\\\"", "\n" => "\\n")
to_json(x::Bool) = x ? "true" : "false"
to_json(x::Nothing) = "null"
to_json(x::AbstractString) = "\"" * json_escape(x) * "\""
to_json(x::Integer) = string(x)
to_json(x::AbstractFloat) = isfinite(x) ? repr(x) : "null"
to_json(x::AbstractVector) = "[" * join(to_json.(x), ",") * "]"
to_json(x::AbstractDict) = "{" * join(("\"$(json_escape(string(k)))\":" * to_json(v) for (k, v) in x), ",") * "}"

length(ARGS) == 1 || error("usage: julia tools/core070_postfit_policy_batch.jl <out.json>")
out_path = ARGS[1]
isfile(out_path) && error("destination already exists: $out_path")
mkpath(dirname(out_path))

@assert realpath(Base.pkgdir(GLLVM)) == realpath(pwd()) "must run from the GLLVM.jl package root"

oracle_path = get(ENV, "CORE070_POSTFIT_POLICY_R_ORACLE", "")
isempty(oracle_path) &&
    error("CORE070_POSTFIT_POLICY_R_ORACLE is required; refusing to silently default it")
isfile(oracle_path) ||
    error("CORE070_POSTFIT_POLICY_R_ORACLE points to a nonexistent file: $oracle_path")

oracle = json_read(oracle_path)

# ---------------------------------------------------------------------------
# Read the R-written fixture and oracle numbers. p/n/K/Y come straight from
# the R side's own live fit -- no independent regeneration, no cross-language
# RNG matching required.
# ---------------------------------------------------------------------------
p = Int(oracle["p"])
n = Int(oracle["n"])
K = Int(oracle["K"])
y_flat = Float64.(oracle["y"])
length(y_flat) == p * n || error("oracle y length ($(length(y_flat))) != p*n ($(p*n))")
Y = reshape(y_flat, p, n) # R wrote column-major (p, n): matches Julia reshape directly

X = zeros(p, n, p)
for j in 1:p
    X[j, :, j] .= 1
end

r_coef = Float64.(oracle["coef"])
r_nobs = Int(oracle["nobs"])
r_df = Int(oracle["df"])
r_loglik = Float64(oracle["loglik"])
r_loglik_nobs_attr = Int(oracle["loglik_nobs_attr"])
r_link = reshape(Float64.(oracle["link"]), size(Y))
r_response = reshape(Float64.(oracle["response"]), size(Y))
r_residual = reshape(Float64.(oracle["residual"]), size(Y))
r_predict_type_default = String(oracle["predict_type_default"])
r_residual_type_default = String(oracle["residual_type_default"])
r_residual_scale_default = String(oracle["residual_scale_default"])
r_simulate_condition_on_re_default = Bool(oracle["simulate_condition_on_re_default"])
r_ci_ok = Bool(oracle["ci_ok"])
r_ci_lower = Float64.(oracle["ci_lower"])
r_ci_upper = Float64.(oracle["ci_upper"])
r_ci_error = String(oracle["ci_error"])
r_empty_coef = Float64.(oracle["empty_coef"])

# ---------------------------------------------------------------------------
# Native Julia refit + direct GLLVM module accessor calls (no RCall).
# ---------------------------------------------------------------------------
fit = fit_gaussian_gllvm(Y; K = K, X = X)

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
# R coef.gllvmTMB_multi empty branch (already evaluated by the R stage
# against a synthetic mock object; r_empty_coef comes from the oracle file).
# ---------------------------------------------------------------------------
fit_no_x = fit_gaussian_gllvm(Y; K = 1)
j_empty_coef = GLLVM.StatsAPI.coef(fit_no_x)

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
open(out_path, "w") do io
    print(io, to_json(report))
end
println("CORE070_POSTFIT_POLICY_BATCH_RESULT ",
        overall_ok ? "PASS" : "FAIL",
        " positive=", all_positive_pass, " negatives=", negatives_behaved)
overall_ok || exit(1)
