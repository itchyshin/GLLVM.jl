# One-off diagnostic (not part of any contract): run the cross-objective
# identity check on BOTH famlinks cases to discriminate a coordinate-transport
# error (both links miss alike) from a genuine cloglog likelihood
# disagreement (probit identity tight, cloglog off).
#
# argv: ARGS[1] = path to wave4-famlinks2/r-oracle.json

using GLLVM
include(joinpath(@__DIR__, "core070_cross_objective.jl"))

# Reuse the batch's minimal JSON reader by parsing with a tiny regex-free
# extraction: the oracle is small and flat enough to use Meta-free parsing.
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
                pos[] = nextind(txt, pos[]); break
            elseif c == '\\'
                pos[] = nextind(txt, pos[]); e = txt[pos[]]
                if e == 'n'; write(buf, '\n')
                elseif e == 't'; write(buf, '\t')
                else write(buf, e) end
                pos[] = nextind(txt, pos[])
            else
                write(buf, c); pos[] = nextind(txt, pos[])
            end
        end
        String(take!(buf))
    end
    function parse_number()
        start = pos[]
        while pos[] <= lastindex(txt) && (txt[pos[]] in "+-.eE0123456789")
            pos[] = nextind(txt, pos[])
        end
        parse(Float64, txt[start:prevind(txt, pos[])])
    end
    function parse_value()
        skip_ws!()
        c = txt[pos[]]
        if c == '{'
            d = Dict{String,Any}(); pos[] = nextind(txt, pos[]); skip_ws!()
            if txt[pos[]] == '}'; pos[] = nextind(txt, pos[]); return d; end
            while true
                skip_ws!(); k = parse_string(); skip_ws!()
                @assert txt[pos[]] == ':'; pos[] = nextind(txt, pos[])
                d[k] = parse_value(); skip_ws!()
                if txt[pos[]] == ','; pos[] = nextind(txt, pos[]); continue; end
                @assert txt[pos[]] == '}'; pos[] = nextind(txt, pos[]); return d
            end
        elseif c == '['
            a = Any[]; pos[] = nextind(txt, pos[]); skip_ws!()
            if txt[pos[]] == ']'; pos[] = nextind(txt, pos[]); return a; end
            while true
                push!(a, parse_value()); skip_ws!()
                if txt[pos[]] == ','; pos[] = nextind(txt, pos[]); continue; end
                @assert txt[pos[]] == ']'; pos[] = nextind(txt, pos[]); return a
            end
        elseif c == '"'
            return parse_string()
        elseif startswith(txt[pos[]:end], "null"); pos[] += 4; return nothing
        elseif startswith(txt[pos[]:end], "true"); pos[] += 4; return true
        elseif startswith(txt[pos[]:end], "false"); pos[] += 5; return false
        else
            return parse_number()
        end
    end
    parse_value()
end

oracle = json_read(ARGS[1])
for (key, link) in (("probit", GLLVM.ProbitLink()), ("cloglog", GLLVM.CLogLogLink()))
    c = oracle[key]
    p = Int(c["p"]); n = Int(c["n"]); K = Int(c["K"])
    # "y" is the flat vector as R serialized matrix(Y, p, n) column-major
    Y = reshape(Float64.(c["y"]), p, n)
    beta = Float64.(c["coef"])
    lam = Float64.(c["loadings"])
    Lam = reshape(lam, p, K)
    obj = cross_objective_at(:binomial, Y; beta = beta,
        crossprod_or_loadings = Lam, rank = K, link = link)
    println(key, " r_loglik=", c["loglik"], " julia_obj_at_r=", obj,
        " identity_delta=", abs(obj - c["loglik"]))
end
