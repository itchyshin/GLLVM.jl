# Julia child for the T5 estimand-alignment re-bind batch
# (tools/core070_estimand_rebind_batch.R). Reads the R-oracle JSON (path
# from ENV["CORE070_ESTIMAND_REBIND_R_ORACLE"]), fits gaussian_small
# NATIVELY (independent optimiser run on the same simulated Y the R
# process fit, not a replay of R's numbers), calls GLLVM.jl's NEW
# tier-scoped-default extract_communality/extract_correlations/
# extract_proportions/extract_Omega (src/extractors.jl, maintainer decision
# round 1 item 3), and compares against the real R accessor's own output at
# a uniform paired-independent-fit tolerance (1e-4, matching the tolerance
# already established for the same-fixture sigma_unit_total/residual_cor
# cases in tools/core070_surface_conversion_batch.R). Writes ARGS[1] as the
# JSON results file.
#
# No RCall, no parity-runner include, no R of any kind runs here.
#
# Usage: julia --project=. tools/core070_estimand_rebind_batch.jl <out.json>

using GLLVM
using LinearAlgebra: diag

# ---------------------------------------------------------------------------
# Minimal JSON reader/writer -- copied verbatim from
# tools/core070_surface_conversion_batch.jl (itself copied from the repo
# convention in tools/core070_inference_remainder_batch.jl).
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Minimal JSON reader/writer (no external dependency; mirrors the existing
# repo convention in tools/core070_inference_remainder_batch.jl).
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
        pos[] += 1
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

length(ARGS) == 1 || error("usage: julia core070_estimand_rebind_batch.jl <output.json>")
out_path = ARGS[1]
mkpath(dirname(out_path))

oracle_path = get(ENV, "CORE070_ESTIMAND_REBIND_R_ORACLE", "")
isempty(oracle_path) && error("CORE070_ESTIMAND_REBIND_R_ORACLE not set")
isfile(oracle_path) || error("oracle file not found: $oracle_path")
oracle = json_read(oracle_path)

# ---------------------------------------------------------------------------
# gaussian_small -- fit natively on the R oracle's simulated Y (same
# convention as tools/core070_surface_conversion_batch.jl: reshape(p, n) on
# R's as.numeric(Y_g), which is column-major and matches exactly).
# ---------------------------------------------------------------------------
gs = oracle["gaussian_small"]
p, K, n = gs["p"], gs["K"], gs["n"]
Y_g = reshape(Float64.(gs["y"]), p, n)
fit_g = fit_gaussian_gllvm(Y_g; K = K)

TRAIT_TO_SOURCE = Dict(
    "communality"  => "postfit/POSTFIT-SURFACE-extract_communality",
    "correlations" => "postfit/POSTFIT-SURFACE-extract_correlations",
    "proportions"  => "postfit/POSTFIT-SURFACE-extract_proportions",
    "omega"        => "postfit/POSTFIT-SURFACE-extract_Omega",
)
CASE_IDS = Dict(
    "communality"  => "CORE070-ESTIMAND-REBIND-EXTRACT-COMMUNALITY",
    "correlations" => "CORE070-ESTIMAND-REBIND-EXTRACT-CORRELATIONS",
    "proportions"  => "CORE070-ESTIMAND-REBIND-EXTRACT-PROPORTIONS",
    "omega"        => "CORE070-ESTIMAND-REBIND-EXTRACT-OMEGA",
)
TOL = 1e-4

function julia_quantity(quantity::AbstractString)
    if quantity == "communality"
        # New default: level = :unit (tier-scoped, matches R's real
        # extract_communality(fit, level="unit") exactly).
        return GLLVM.extract_communality(fit_g)
    elseif quantity == "correlations"
        # New default: level = :unit. Returns a p x p Matrix; flatten in
        # the SAME column-major order the R side's full-matrix
        # reassembly (diag(p) then symmetric fill) implies for
        # as.numeric() on a p x p R matrix.
        return vec(GLLVM.extract_correlations(fit_g))
    elseif quantity == "proportions"
        # New default: component = :shared, level = :unit.
        return GLLVM.extract_proportions(fit_g)
    elseif quantity == "omega"
        # New default: level = :auto (tier-presence-gated).
        return vec(GLLVM.extract_Omega(fit_g))
    else
        error("BOGUS_QUANTITY: no dispatcher entry for '$(quantity)'")
    end
end

results = Dict{String, Any}()
all_ok = true

for (quantity, case_id) in CASE_IDS
    if !haskey(oracle["oracle_values"], case_id)
        r_err = get(get(oracle, "oracle_errors", Dict{String, Any}()), case_id, "(no oracle_errors entry either)")
        results[case_id] = Dict{String, Any}("pass" => false, "quantity" => quantity,
                                              "tolerance" => TOL, "max_abs_diff" => NaN,
                                              "r_len" => 0, "julia_len" => 0,
                                              "error" => "missing_oracle_value: R oracle_errors[$case_id] = $(r_err)")
        global all_ok = false
        continue
    end
    r_vec = Float64.(oracle["oracle_values"][case_id])

    jl_vec = Float64[]
    err = ""
    ok = false
    try
        jl_vec = Float64.(julia_quantity(quantity))
        ok = length(jl_vec) == length(r_vec) && maximum(abs.(jl_vec .- r_vec)) <= TOL
    catch e
        err = sprint(showerror, e)
    end
    maxdiff = (isempty(jl_vec) || length(jl_vec) != length(r_vec)) ? NaN :
        maximum(abs.(jl_vec .- r_vec))

    results[case_id] = Dict{String, Any}("pass" => ok, "quantity" => quantity,
                                          "tolerance" => TOL, "max_abs_diff" => maxdiff,
                                          "r_len" => length(r_vec), "julia_len" => length(jl_vec),
                                          "error" => err, "julia_values" => jl_vec)
    global all_ok &= ok
end

# --- negative controls: mirror the R side's rejections ---------------------
neg_bogus_quantity = try
    julia_quantity("this_quantity_does_not_exist")
    false
catch
    true
end
r_neg = oracle["negative_controls"]
neg_bogus_quantity_r = get(r_neg["bogus_quantity"], "rejected", false)
neg_wrong_fixture_r = get(r_neg["wrong_fixture"], "rejected", false)
neg_ok = neg_bogus_quantity && (neg_bogus_quantity_r == true) && (neg_wrong_fixture_r == true)

report = Dict{String, Any}(
    "status" => (all_ok && neg_ok) ? "PASS" : "FAIL",
    "julia_version" => string(VERSION),
    "package_root" => Base.pkgdir(GLLVM),
    "case_count" => length(CASE_IDS),
    "all_checks" => all_ok,
    "negative_controls_behaved_as_expected" => neg_ok,
    "cases" => results,
)
open(out_path, "w") do io
    write(io, to_json(report))
end
println(report["status"] == "PASS" ? "CORE070_ESTIMAND_REBIND_JULIA_PASS" :
        "CORE070_ESTIMAND_REBIND_JULIA_FAIL")
exit(report["status"] == "PASS" ? 0 : 1)
