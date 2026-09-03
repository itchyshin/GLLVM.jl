# NB2 benchmark repair: the original Julia column used fit_nb_gllvm (SHARED
# dispersion r) against R's per-trait-phi default — a wrong-model comparison
# (logLik gap grew ~proportionally with p; all multistarts confirmed a stable
# shared-r optimum, so this was model mismatch, not an optimizer miss).
# This rerun fits the matched model: fit_nb_gllvm_grouped with group = 1:p
# (per-trait dispersion). argv: ARGS[1] = the bench-full output dir.
using GLLVM
using DelimitedFiles
using Statistics

out = ARGS[1]
man, _ = readdlm(joinpath(out, "bench-manifest.csv"), ',', header = true)
open(joinpath(out, "julia-timings-nb2-pertrait.csv"), "w") do io
    println(io, "case,p,n,family,median_s,min_s,loglik,ok")
    for i in axes(man, 1)
        fam = String(strip(string(man[i, 4]), ['"', ' ']))
        fam == "nbinom2" || continue
        case = Int(man[i, 1]); p = Int(man[i, 2]); n = Int(man[i, 3])
        raw, _ = readdlm(joinpath(out, "bench-Y-" * lpad(case, 3, '0') * ".csv"),
                         ',', header = true)
        Y = Int.(round.(Matrix{Float64}(raw)))
        times = Float64[]; ll = NaN; ok = true
        for r in 1:5
            t = @elapsed try
                fit = GLLVM.fit_nb_gllvm_grouped(Y; K = 2, group = collect(1:p))
                ll = hasproperty(fit, :logLik) ? fit.logLik : fit.loglik
            catch err
                ok = false
                println(stderr, "case=$case FAILED: ", sprint(showerror, err)[1:200])
            end
            push!(times, t)
            ok || break
        end
        println(io, join([case, p, n, "nbinom2_pertrait", median(times), minimum(times), ll, ok], ","))
        flush(io)
        println(stderr, "J done case=$case p=$p n=$n median=$(round(median(times), digits = 3))s ll=$ll ok=$ok")
    end
end
println("NB2_PERTRAIT_DONE")
