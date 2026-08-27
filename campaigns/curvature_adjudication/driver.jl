# Parallel campaign driver. Usage: julia --project=<repo> driver.jl <nworkers>
# Worker count is a D-143 decision: on Totoro, size so snakagaw's TOTAL stays
# ≤150 cores (check `ps -u snakagaw -o pcpu= | awk '{s+=$1}'` first).
using Distributed
const NW = parse(Int, ARGS[1])
const HERE = @__DIR__
addprocs(NW; exeflags = "--project=$(dirname(dirname(HERE)))",
         env = ["OPENBLAS_NUM_THREADS" => "1"])
@everywhere const CAMPDIR = $HERE
@everywhere include(joinpath(CAMPDIR, "cell.jl"))
rows = readlines(joinpath(HERE, "params.csv"))
out = joinpath(HERE, "results"); mkpath(out)
@info "campaign: $(length(rows)) cells on $NW workers"
t0 = time()
res = pmap(rows) do line
    fam, reg, seed = split(line, ",")
    try
        run_cell(String(fam), String(reg), parse(Int, seed), out)
        "ok"
    catch e
        "ERR $line :: $(sprint(showerror, e)[1:min(end,200)])"
    end
end
nok = count(==("ok"), res)
println("CAMPAIGN_DONE ok=$nok err=$(length(res) - nok) wall_min=$(round((time()-t0)/60, digits=1))")
foreach(r -> r != "ok" && println(r), res)
