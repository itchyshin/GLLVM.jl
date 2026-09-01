# Julia child for the surface-conversion batch
# (tools/core070_surface_conversion_batch.R). Reads the R-oracle JSON (path
# from ENV["CORE070_SURFACE_CONVERSION_R_ORACLE"], matching the env
# pass-through convention of tools/core070_inference_remainder_batch.jl),
# fits the three canonical fixtures NATIVELY (independent optimiser run on
# the same simulated Y the R process fit, not a replay of R's numbers),
# calls each case's NEW Julia surface, and compares against the R oracle at
# the contract's per-case tolerance. Writes ARGS[1] as the JSON results
# file.
#
# No RCall, no parity-runner include, no R of any kind runs here.
# No external JSON dependency (this project's Project.toml carries none);
# the minimal hand-rolled reader/writer below is copied verbatim from the
# repo convention in tools/core070_inference_remainder_batch.jl /
# tools/core070_namespace_2_batch.jl.
#
# Usage: julia --project=. tools/core070_surface_conversion_batch.jl <out.json>

using GLLVM

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

length(ARGS) == 1 || error("usage: julia core070_surface_conversion_batch.jl <output.json>")
out_path = ARGS[1]
mkpath(dirname(out_path))

oracle_path = get(ENV, "CORE070_SURFACE_CONVERSION_R_ORACLE", "")
isempty(oracle_path) && error("CORE070_SURFACE_CONVERSION_R_ORACLE not set")
isfile(oracle_path) || error("oracle file not found: $oracle_path")
oracle = json_read(oracle_path)

root = normpath(joinpath(@__DIR__, ".."))
contract = json_read(joinpath(root, "docs/dev-log/core070/surface-conversion-batch-contract.json"))
cases = contract["cases"]
length(cases) == contract["expected_case_count"] || error("case count mismatch vs contract")
Int(contract["expected_case_count"]) == 34 || error("expected_case_count drifted from 34; update this script")

# ---------------------------------------------------------------------------
# Fixture 1: gaussian_small -- fit natively on the R oracle's simulated Y.
# ---------------------------------------------------------------------------
gs = oracle["gaussian_small"]
p, K, n = gs["p"], gs["K"], gs["n"]
Y_g = reshape(Float64.(gs["y"]), p, n)                 # R's as.numeric(Y_g) on a p x n matrix
                                                        # is column-major, matching Julia's
                                                        # default reshape(p, n) exactly.
fit_g = fit_gaussian_gllvm(Y_g; K = K)

# ---------------------------------------------------------------------------
# Fixture 2: twolevel_small.
# ---------------------------------------------------------------------------
tl = oracle["twolevel_small"]
p_tl, n_ind, reps = tl["p"], tl["n_individual"], tl["reps_per_individual"]
n_tl = n_ind * reps
Y_tl = reshape(Float64.(tl["y"]), p_tl, n_tl)
individual = Int.(tl["individual"])
fit_tl = fit_twolevel_gaussian(Y_tl, individual; K_B = 1, K_W = 1)

# ---------------------------------------------------------------------------
# Fixture 3: ordinal_small.
# ---------------------------------------------------------------------------
os = oracle["ordinal_small"]
p_o, K_o, n_o = os["p"], os["K"], os["n"]
Y_o = reshape(Int.(os["y"]), p_o, n_o)
fit_o = fit_ordinal_gllvm_pertrait(Y_o; K = K_o, link = ProbitLink(),
                                    g_tol = 1e-7, iterations = 1_000)

# ---------------------------------------------------------------------------
# Per-quantity Julia computation. Mirrors the R dispatcher in
# core070_surface_conversion_batch.R one-for-one by `quantity` key.
# ---------------------------------------------------------------------------
function julia_quantity(quantity::AbstractString)
    if quantity == "loadings_crossprod"
        L = GLLVM.getLoadings(fit_g)
        return vec(L' * L)
    elseif quantity == "lv_predictor"
        Z = GLLVM.getLV(fit_g, Y_g)
        return vec(fit_g.pars.Λ * Z)
    elseif quantity == "sigma_unit_total"
        return vec(GLLVM.extract_Sigma(fit_g; level = :unit, part = :total).Sigma)
    elseif quantity == "sigma_table"
        t = GLLVM.extract_Sigma_table(fit_g; level = :unit, part = :total)
        ts = sort(collect(t); by = r -> (r.trait_i, r.trait_j))
        return Float64[r.value for r in ts]
    elseif quantity == "communality"
        return vec(GLLVM.extract_communality(fit_g))
    elseif quantity == "correlations"
        return vec(GLLVM.extract_correlations(fit_g))
    elseif quantity == "cross_correlations"
        return vec(GLLVM.extract_cross_correlations(fit_g; level = :unit,
                                                      traits_i = [1, 2], traits_j = [3, 4, 5]))
    elseif quantity == "residual_cov"
        return vec(GLLVM.extract_residual_cov(fit_g; level = :unit_obs))
    elseif quantity == "residual_cor"
        return vec(GLLVM.extract_residual_cor(fit_g; level = :unit_obs))
    elseif quantity == "ordination_sites"
        sites, _, _ = GLLVM.extract_ordination(fit_g, Y_g)
        S = Matrix(sites)
        return size(S, 1) == n ? vec(sum(abs2, S; dims = 2)) : vec(sum(abs2, S; dims = 1))
    elseif quantity == "proportions"
        return vec(GLLVM.extract_proportions(fit_g; component = :shared))
    elseif quantity == "omega"
        return vec(GLLVM.extract_Omega(fit_g))
    elseif quantity == "icc_site"
        return vec(GLLVM.extract_ICC_site(fit_g))
    elseif quantity == "loading_ci_wald_asym"
        tbl = GLLVM.loading_ci(fit_g, Y_g; method = :wald_asym, conf_level = 0.95)
        return vcat(Float64[r.lower for r in tbl], Float64[r.upper for r in tbl])
    elseif quantity == "loading_profile"
        r = GLLVM.loading_profile(fit_g, 1, 1; level = 0.95)
        return Float64[r.lower, r.upper]
    elseif quantity == "profile_ci_total_variance"
        r = GLLVM.profile_ci_total_variance(fit_g, 1; level = 0.95)
        return Float64[r.lower, r.upper]
    elseif quantity == "standard_errors"
        return vec(GLLVM.standard_errors(fit_g, Y_g).se)
    elseif quantity == "repeatability_point"
        return vec(GLLVM.extract_repeatability(fit_tl))
    elseif quantity in ("icc_ci_default", "icc_ci_wald")
        ci = GLLVM.repeatability_ci(fit_tl, Y_tl, individual; method = :wald)
        return vcat(Float64[r.lower for r in ci], Float64[r.upper for r in ci])
    elseif quantity == "icc_ci_bootstrap"
        ci = GLLVM.repeatability_ci(fit_tl, Y_tl, individual; method = :bootstrap,
                                     nsim = 200, seed = 11)
        return vcat(Float64[r.lower for r in ci], Float64[r.upper for r in ci])
    elseif quantity == "cutpoints"
        τ = GLLVM.extract_cutpoints(fit_o).τ
        return vec(Matrix(τ))
    else
        error("BOGUS_QUANTITY: no dispatcher entry for '$(quantity)'")
    end
end

results = Dict{String, Any}()
all_ok = true

for cs in cases
    case_id = cs["case_id"]
    kind = cs["kind"]
    if kind == "refusal_pair"
        r_val = oracle["oracle_values"][case_id]
        r_raised = get(r_val, "raised", false)
        jl_raised = false
        jl_message = ""
        try
            GLLVM.repeatability_ci(fit_tl, Y_tl, individual; method = :profile)
        catch e
            jl_raised = true
            jl_message = sprint(showerror, e)
        end
        ok = r_raised == true && jl_raised == true
        results[case_id] = Dict{String, Any}("pass" => ok, "kind" => kind,
                                              "r_raised" => r_raised, "julia_raised" => jl_raised,
                                              "julia_message" => jl_message)
        global all_ok &= ok
        continue
    end

    quantity = cs["quantity"]
    tol = Float64(cs["tolerance"])
    haskey(oracle["oracle_values"], case_id) || error("no R oracle value recorded for $case_id")
    r_vec = Float64.(oracle["oracle_values"][case_id])

    jl_vec = Float64[]
    err = ""
    ok = false
    try
        jl_vec = julia_quantity(quantity)
        ok = length(jl_vec) == length(r_vec) && maximum(abs.(jl_vec .- r_vec)) <= tol
    catch e
        err = sprint(showerror, e)
    end
    maxdiff = (isempty(jl_vec) || length(jl_vec) != length(r_vec)) ? NaN :
        maximum(abs.(jl_vec .- r_vec))

    results[case_id] = Dict{String, Any}("pass" => ok, "kind" => kind, "quantity" => quantity,
                                          "tolerance" => tol, "max_abs_diff" => maxdiff,
                                          "r_len" => length(r_vec), "julia_len" => length(jl_vec),
                                          "error" => err)
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
    "case_count" => length(cases),
    "all_checks" => all_ok,
    "negative_controls_behaved_as_expected" => neg_ok,
    "cases" => results,
)
open(out_path, "w") do io
    write(io, to_json(report))
end
println(report["status"] == "PASS" ? "CORE070_SURFACE_CONVERSION_JULIA_PASS" :
        "CORE070_SURFACE_CONVERSION_JULIA_FAIL")
exit(report["status"] == "PASS" ? 0 : 1)
