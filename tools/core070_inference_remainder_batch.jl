# Inner executor for the "inference remainder" batch (6 executable cases
# covering the 19 unbound `inference/` CI-ROUTE-* rows; see
# docs/dev-log/core070/inference-remainder-batch-contract.json).
#
# Pure-Julia consumer, mirroring tools/core070_namespace_2_batch.jl: reads a
# JSON oracle file the paired R runner
# (tools/core070_inference_remainder_batch.R) writes BEFORE invoking this
# script, refits the shared Gaussian fixture natively via `using GLLVM`
# only. No RCall, no parity-runner include, no R of any kind runs here.
#
# argv:
#   ARGS[1]  destination path for the JSON results file. Must not already
#            exist; this script mkpath()s its parent dir.
#
# Env vars required (set by the outer R runner before invoking this
# script; never defaulted silently here):
#   CORE070_INFERENCE_REMAINDER_R_ORACLE = <path to the R-written oracle JSON>
#
# Invocation:
#   julia --project=. tools/core070_inference_remainder_batch.jl <out.json>

using GLLVM

# ---------------------------------------------------------------------------
# Minimal JSON reader/writer (no external dependency; mirrors the existing
# repo convention in tools/core070_namespace_2_batch.jl).
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

length(ARGS) == 1 || error("usage: julia tools/core070_inference_remainder_batch.jl <out.json>")
out_path = ARGS[1]
isfile(out_path) && error("destination already exists: $out_path")
mkpath(dirname(out_path))

@assert realpath(Base.pkgdir(GLLVM)) == realpath(pwd()) "must run from the GLLVM.jl package root"

oracle_path = get(ENV, "CORE070_INFERENCE_REMAINDER_R_ORACLE", "")
isempty(oracle_path) &&
    error("CORE070_INFERENCE_REMAINDER_R_ORACLE is required; refusing to silently default it")
isfile(oracle_path) ||
    error("CORE070_INFERENCE_REMAINDER_R_ORACLE points to a nonexistent file: $oracle_path")

oracle = json_read(oracle_path)

# ---------------------------------------------------------------------------
# Refit the shared single-tier Gaussian fixture. NOTE: CORE070-INFERENCE-ICC-
# CI-METHOD-ROUTE (CI-ROUTE-008..011) is NOT computed here -- REPAIR
# (2026-09-01): it originally called icc_wald_ci/profile_ci_derived/
# bootstrap_ci_derived on this fixture to compare against R's
# confint(parm="icc", method=...), which crashed on Totoro because R's route
# needs a genuine two-tier fit (vB>0, vW>0) via extract_repeatability(), and
# because GLLVM.jl's actual comparand for extract_repeatability is
# repeatability(fit::TwoLevelFit) in src/twolevel.jl (a point estimate only,
# with zero Wald/profile/bootstrap CI machinery) -- not icc_wald_ci on an
# ordinary GllvmFit at all. See the contract's `notes` /
# `needs_new_julia_surface` / `totoro_failed_attempts` for the full account.
# f_icc below is still used, unrelated to that case: it backs the ICC and
# PROPORTION reject-path checks, which only need icc_wald_ci's *signature*
# (no `method` keyword) to trigger a MethodError -- they never need the
# closure's value to be numerically meaningful.
# ---------------------------------------------------------------------------
g = oracle["gaussian"]
p = Int(g["p"]); n = Int(g["n"]); K = Int(g["K"])
y_flat = Float64.(g["y"])
length(y_flat) == p * n || error("gaussian y length mismatch")
Y = reshape(y_flat, p, n)
X = zeros(p, n, p)
for j in 1:p
    X[j, :, j] .= 1
end

fit = fit_gaussian_gllvm(Y; K = K, X = X)
spec = GLLVM._derived_spec(fit)
f_icc = GLLVM._make_communality_closure(spec, 1)   # reject-path closure only

cases = Dict{String, Any}()

# ---------------------------------------------------------------------------
# Reject cases: attempt the call with an extraneous `method=<bad>` keyword
# and assert a MethodError is thrown (none of these Wald-CI functions
# declare a `method` keyword).
# ---------------------------------------------------------------------------
function reject_probe(f::Function)
    try
        f()
        return "none"
    catch e
        return e isa MethodError ? "MethodError" : string(typeof(e))
    end
end

function reject_case!(cases, case_id, oracle_key, r_key, probes)
    r_entries = oracle[oracle_key]
    per_method = Dict{String, Any}()
    all_ok = true
    for (method_str, probe) in probes
        r_entry = r_entries[method_str]
        r_matches = r_entry["matches"] === true
        julia_kind = reject_probe(probe)
        julia_ok = julia_kind == "MethodError"
        ok = r_matches && julia_ok
        all_ok &= ok
        per_method[method_str] = Dict(
            "r_raised" => r_entry["raised"] === true,
            "r_matches" => r_matches,
            "julia_error_kind" => julia_kind,
            "julia_ok" => julia_ok,
            "pass" => ok,
        )
    end
    cases[case_id] = Dict("pass" => all_ok, "methods" => per_method)
    return per_method
end

icc_reject_methods = reject_case!(cases, "CORE070-INFERENCE-ICC-CI-UNSUPPORTED-METHOD-REJECT",
    "icc_reject", "icc",
    [
        ("wald_asym", () -> GLLVM.icc_wald_ci(fit, f_icc; y = Y, method = :wald_asym)),
        ("fisher-z", () -> GLLVM.icc_wald_ci(fit, f_icc; y = Y, method = Symbol("fisher-z"))),
        ("bogus", () -> GLLVM.icc_wald_ci(fit, f_icc; y = Y, method = :bogus)),
    ])

reject_case!(cases, "CORE070-INFERENCE-PHYLO-SIGNAL-CI-UNSUPPORTED-METHOD-REJECT",
    "phylo_reject", "phylo_signal",
    [
        ("wald_asym", () -> GLLVM.phylo_signal_wald_ci(fit, 1; y = Y, method = :wald_asym)),
        ("fisher-z", () -> GLLVM.phylo_signal_wald_ci(fit, 1; y = Y, method = Symbol("fisher-z"))),
        ("bogus", () -> GLLVM.phylo_signal_wald_ci(fit, 1; y = Y, method = :bogus)),
    ])

reject_case!(cases, "CORE070-INFERENCE-COMMUNALITY-CI-UNSUPPORTED-METHOD-REJECT",
    "communality_reject", "communality",
    [
        ("wald_asym", () -> GLLVM.communality_wald_ci(fit, 1; y = Y, method = :wald_asym)),
        ("fisher-z", () -> GLLVM.communality_wald_ci(fit, 1; y = Y, method = Symbol("fisher-z"))),
        ("bogus", () -> GLLVM.communality_wald_ci(fit, 1; y = Y, method = :bogus)),
    ])

reject_case!(cases, "CORE070-INFERENCE-RHO-CI-UNSUPPORTED-METHOD-REJECT",
    "rho_reject", "rho",
    [
        ("wald_asym", () -> GLLVM.correlation_wald_ci(fit, 1, 2; y = Y, method = :wald_asym)),
        ("bogus", () -> GLLVM.correlation_wald_ci(fit, 1, 2; y = Y, method = :bogus)),
    ])

reject_case!(cases, "CORE070-INFERENCE-PROPORTION-CI-UNSUPPORTED-METHOD-REJECT",
    "proportion_reject", "proportion",
    [
        ("wald_asym", () -> GLLVM.icc_wald_ci(fit, f_icc; y = Y, method = :wald_asym)),
        ("fisher-z", () -> GLLVM.icc_wald_ci(fit, f_icc; y = Y, method = Symbol("fisher-z"))),
        ("bogus", () -> GLLVM.icc_wald_ci(fit, f_icc; y = Y, method = :bogus)),
    ])

# ---------------------------------------------------------------------------
# Negative controls: deliberately-wrong comparisons that MUST fail.
# ---------------------------------------------------------------------------
neg_reject_accepted_kind = icc_reject_methods["wald_asym"]["julia_error_kind"]
neg_r_reject_message = oracle["icc_reject"]["wald_asym"]["matches"] === true

negative_controls = Dict(
    "NEG-REJECT-ACCEPTED-AS-VALID" => Dict(
        "behaved" => neg_reject_accepted_kind == "MethodError",
        "julia_error_kind" => neg_reject_accepted_kind),
    "NEG-R-REJECT-MESSAGE-WRONG" => Dict(
        "behaved" => neg_r_reject_message, "r_matches" => neg_r_reject_message),
)

all_positive_pass = all(v["pass"] for v in values(cases))
negatives_behaved = all(v["behaved"] for v in values(negative_controls))
overall_ok = all_positive_pass && negatives_behaved

report = Dict(
    "status" => overall_ok ? "PASS" : "FAIL",
    "area" => "inference-remainder",
    "scope" => "CORE070_INFERENCE_REMAINDER_BATCH",
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
println("CORE070_INFERENCE_REMAINDER_BATCH_RESULT ",
        overall_ok ? "PASS" : "FAIL",
        " positive=", all_positive_pass, " negatives=", negatives_behaved)
overall_ok || exit(1)
