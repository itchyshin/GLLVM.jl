# Inner executor for the "aghq control" M2 batch (16 paired-control cases,
# all decided here; see docs/dev-log/core070/aghq-batch-contract.json for the
# full case list and the 22 NEEDS_NEW_JULIA_SURFACE deferrals).
#
# Pure-Julia consumer, mirroring tools/core070_namespace_2_batch.jl: reads a
# JSON oracle file the paired R runner (tools/core070_aghq_batch.R) writes
# BEFORE invoking this script (that R process already has the frozen
# gllvmTMB library loaded and evaluates every frozen r_call/r_assertion pair
# itself), then evaluates the identical GLLVM._aghq_request(...) calls
# natively via direct `using GLLVM` module calls only. No RCall, no parity-
# runner include, no R of any kind runs in this process. No model fit
# anywhere: GLLVM._aghq_request is a pure scalar-argument normalizer.
#
# argv:
#   ARGS[1]  destination path for the JSON results file (parent dir need not
#            exist yet; this script mkpath()s it). Must not already exist.
#
# Env vars required (set by the outer R runner before invoking this script;
# never defaulted silently here so a misconfigured environment fails loudly
# rather than quietly running against stale or missing oracle data):
#   CORE070_AGHQ_R_ORACLE = <path to the R-written oracle JSON>
#
# Invocation:
#   julia --project=. tools/core070_aghq_batch.jl <out.json>

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

length(ARGS) == 1 || error("usage: julia tools/core070_aghq_batch.jl <out.json>")
out_path = ARGS[1]
isfile(out_path) && error("destination already exists: $out_path")
mkpath(dirname(out_path))

@assert realpath(Base.pkgdir(GLLVM)) == realpath(pwd()) "must run from the GLLVM.jl package root"

oracle_path = get(ENV, "CORE070_AGHQ_R_ORACLE", "")
isempty(oracle_path) &&
    error("CORE070_AGHQ_R_ORACLE is required; refusing to silently default it")
isfile(oracle_path) ||
    error("CORE070_AGHQ_R_ORACLE points to a nonexistent file: $oracle_path")

oracle = json_read(oracle_path)
r_cases = oracle["cases"]

# ---------------------------------------------------------------------------
# Native normalization label helper: mirrors expected strings from the
# frozen contract ("off", "auto", "1"/"2"/"9", "ArgumentError").
# ---------------------------------------------------------------------------
function _label(v)
    v === :off && return "off"
    v === :auto && return "auto"
    v isa Integer && return string(v)
    return "unexpected:$(repr(v))"
end

function _run(f)
    try
        return (label = _label(f()), errored = false)
    catch e
        e isa ArgumentError && return (label = "ArgumentError", errored = true)
        return (label = "unexpected_exception:$(sprint(showerror, e))", errored = true)
    end
end

# ---------------------------------------------------------------------------
# The 16 paired-control cases, literally matching each case's `julia_call`
# in docs/dev-log/core070/aghq-batch-contract.json.
# ---------------------------------------------------------------------------
case_specs = [
    ("CORE070-AGHQ-CTRL-FALSE-PAIRED-CONTROL",    () -> GLLVM._aghq_request(false),   "off"),
    ("CORE070-AGHQ-CTRL-NULL-PAIRED-CONTROL",     () -> GLLVM._aghq_request(nothing), "off"),
    ("CORE070-AGHQ-CTRL-TRUE-PAIRED-CONTROL",     () -> GLLVM._aghq_request(true),    "auto"),
    ("CORE070-AGHQ-CTRL-AUTO-PAIRED-CONTROL",     () -> GLLVM._aghq_request(:auto),   "auto"),
    ("CORE070-AGHQ-CTRL-ONE-PAIRED-CONTROL",      () -> GLLVM._aghq_request(1),       "1"),
    ("CORE070-AGHQ-CTRL-TWO-PAIRED-CONTROL",      () -> GLLVM._aghq_request(2),       "2"),
    ("CORE070-AGHQ-CTRL-NINE-PAIRED-CONTROL",     () -> GLLVM._aghq_request(9),       "9"),
    ("CORE070-AGHQ-INVALID-ZERO-PAIRED-CONTROL",     () -> GLLVM._aghq_request(0),      "ArgumentError"),
    ("CORE070-AGHQ-INVALID-NEGATIVE-PAIRED-CONTROL", () -> GLLVM._aghq_request(-1),     "ArgumentError"),
    ("CORE070-AGHQ-INVALID-FRACTION-PAIRED-CONTROL", () -> GLLVM._aghq_request(1.5),    "ArgumentError"),
    ("CORE070-AGHQ-INVALID-INF-PAIRED-CONTROL",       () -> GLLVM._aghq_request(Inf),    "ArgumentError"),
    ("CORE070-AGHQ-INVALID-NAN-PAIRED-CONTROL",       () -> GLLVM._aghq_request(NaN),    "ArgumentError"),
    ("CORE070-AGHQ-INVALID-NA-PAIRED-CONTROL",        () -> GLLVM._aghq_request(missing),"ArgumentError"),
    ("CORE070-AGHQ-INVALID-VECTOR-PAIRED-CONTROL",    () -> GLLVM._aghq_request([3, 5]), "ArgumentError"),
    ("CORE070-AGHQ-INVALID-EMPTY-PAIRED-CONTROL",     () -> GLLVM._aghq_request(Int[]),  "ArgumentError"),
    ("CORE070-AGHQ-INVALID-STRING-PAIRED-CONTROL",    () -> GLLVM._aghq_request("9"),    "ArgumentError"),
]

cases = Dict{String, Any}()
run_result = Dict{String, Any}()  # case_id -> (label, errored) for negative-control reuse below
for (cid, f, expected) in case_specs
    r = _run(f)
    run_result[cid] = r
    r_pass = haskey(r_cases, cid) && r_cases[cid]["r_assertion_pass"] === true
    julia_pass = r.label == expected
    cases[cid] = Dict(
        "pass" => r_pass && julia_pass,
        "r_assertion_pass" => r_pass,
        "julia_label" => r.label,
        "expected" => expected,
        "julia_pass" => julia_pass,
    )
end

# ---------------------------------------------------------------------------
# Negative controls: deliberately-wrong comparisons that MUST fail.
# ---------------------------------------------------------------------------
false_label = run_result["CORE070-AGHQ-CTRL-FALSE-PAIRED-CONTROL"].label   # "off"
one_label   = run_result["CORE070-AGHQ-CTRL-ONE-PAIRED-CONTROL"].label     # "1"
zero_label  = run_result["CORE070-AGHQ-INVALID-ZERO-PAIRED-CONTROL"].label # "ArgumentError"

neg_flipped = false_label == "auto"        # must be false: "off" != "auto"
neg_valid_as_error = one_label == "ArgumentError"  # must be false: "1" != "ArgumentError"
neg_invalid_as_value = zero_label == "off"         # must be false: "ArgumentError" != "off"

negative_controls = Dict(
    "NEG-EXPECTED-VALUE-FLIPPED" => Dict(
        "behaved" => !neg_flipped, "mismatch_detected" => !neg_flipped),
    "NEG-VALID-CASE-MISCLASSIFIED-AS-ERROR" => Dict(
        "behaved" => !neg_valid_as_error, "mismatch_detected" => !neg_valid_as_error),
    "NEG-INVALID-CASE-MISCLASSIFIED-AS-VALUE" => Dict(
        "behaved" => !neg_invalid_as_value, "mismatch_detected" => !neg_invalid_as_value),
)

all_positive_pass = all(v["pass"] for v in values(cases))
negatives_behaved = all(v["behaved"] for v in values(negative_controls))
overall_ok = all_positive_pass && negatives_behaved

report = Dict(
    "status" => overall_ok ? "PASS" : "FAIL",
    "area" => "aghq-control",
    "scope" => "CORE070_AGHQ_CONTROL_BATCH",
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
println("CORE070_AGHQ_CONTROL_BATCH_RESULT ",
        overall_ok ? "PASS" : "FAIL",
        " positive=", all_positive_pass, " negatives=", negatives_behaved)
overall_ok || exit(1)
