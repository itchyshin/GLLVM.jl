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

oracle = json_read(".unlazy/core070-aghq/wave4-batches/wave4-famlinks2/r-oracle.json")
c = oracle["cloglog"]
p = Int(c["p"]); n = Int(c["n"]); K = Int(c["K"])
Y = reshape(Float64.(c["y"]), p, n)
beta = Float64.(c["coef"])
Lam = reshape(Float64.(c["loadings"]), p, K)
link = GLLVM.CLogLogLink()
N = ones(p, n)

# per-site contributions under fisher vs observed
println("K = ", K, "  p = ", p, "  n = ", n)
gaps = Float64[]
for i in 1:n
    y = view(Y, :, i); nn = view(N, :, i)
    lf = GLLVM.laplace_loglik_site(GLLVM.Binomial(), y, nn, Lam, beta, link; hessian = :fisher)
    lo = GLLVM.laplace_loglik_site(GLLVM.Binomial(), y, nn, Lam, beta, link; hessian = :observed)
    push!(gaps, lo - lf)
end
idx = sortperm(abs.(gaps); rev = true)
println("Top 10 gap-carrying sites (observed - fisher):")
for i in idx[1:10]
    println("  site $i  gap=", gaps[i], "  sum(y)=", sum(view(Y,:,i)))
end
println("Total gap = ", sum(gaps))

# Quadrature ground truth (K=1) at the single largest-gap site
i0 = idx[1]
y = Y[:, i0]
using QuadGK
function exact_marginal(y, beta, lam::AbstractVector, link)
    f(z) = begin
        eta = beta .+ lam .* z
        mu = clamp.(GLLVM.linkinv.(Ref(link), eta), 1e-12, 1-1e-12)
        ll = sum(y[t]*log(mu[t]) + (1-y[t])*log1p(-mu[t]) for t in eachindex(y))
        exp(ll) * exp(-0.5*z^2) / sqrt(2*pi)
    end
    val, err = quadgk(f, -20.0, 20.0; rtol=1e-13, atol=1e-300)
    return log(val), err
end
lam1 = Lam[:, 1]
lq, err = exact_marginal(y, beta, lam1, link)
lf = GLLVM.laplace_loglik_site(GLLVM.Binomial(), y, ones(p), lam1 |> x->reshape(x,p,1), beta, link; hessian=:fisher)
lo = GLLVM.laplace_loglik_site(GLLVM.Binomial(), y, ones(p), reshape(lam1,p,1), beta, link; hessian=:observed)
println("site $i0: quadrature=", lq, " (quadgk err=", err, ")")
println("  fisher   = ", lf, "  |gap to quad| = ", abs(lf-lq))
println("  observed = ", lo, "  |gap to quad| = ", abs(lo-lq))
