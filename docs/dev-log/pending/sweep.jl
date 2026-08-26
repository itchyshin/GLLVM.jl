using Pkg; Pkg.activate(@__DIR__; io=devnull)
Pkg.add(["Distributions","StatsModels"]; io=devnull)
using GLLVM, StatsBase, StatsAPI, Distributions, StatsModels

gl = setdiff(names(GLLVM), [:GLLVM])
others = Dict("StatsBase"=>StatsBase, "Distributions"=>Distributions,
              "StatsModels"=>StatsModels, "Base"=>Base)

rows = Tuple{Symbol,String}[]
for n in gl
    for (mn, m) in others
        if n in names(m) && isdefined(m, n) && isdefined(GLLVM, n)
            if getfield(GLLVM, n) !== getfield(m, n)
                push!(rows, (n, mn))
            end
        end
    end
end
byname = Dict{Symbol,Vector{String}}()
for (n,m) in rows; push!(get!(byname, n, String[]), m); end

println("GLLVM exports scanned: ", length(gl))
println("COLLIDING EXPORTS: ", length(byname))
println()
for n in sort(collect(keys(byname)))
    println(rpad(String(n), 22), "shadows: ", join(sort(byname[n]), ", "))
end
