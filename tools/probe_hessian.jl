using GLLVM
include(joinpath(@__DIR__, "core070_cross_objective.jl"))

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

oracle_path = ".unlazy/core070-aghq/wave4-batches/wave4-famlinks2/r-oracle.json"
oracle = json_read(oracle_path)
c = oracle["cloglog"]
p = Int(c["p"]); n = Int(c["n"]); K = Int(c["K"])
Y = reshape(Float64.(c["y"]), p, n)
beta = Float64.(c["coef"])
lam = Float64.(c["loadings"])
Lam = reshape(lam, p, K)
for hess in (:fisher, :observed)
    obj = GLLVM.binomial_marginal_loglik_laplace(Y, ones(p,n), Lam, beta, GLLVM.CLogLogLink(); hessian=hess)
    println(hess, " => ", obj, "  delta=", abs(obj - c["loglik"]))
end
