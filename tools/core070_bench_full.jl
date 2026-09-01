# M3 full benchmark campaign, Julia side. Reads bench-manifest.csv +
# bench-Y-*.csv from the R stage's output dir; fits the paired canonical
# model natively; 5 reps, median wall seconds.
# Family drivers: fit_gaussian_gllvm (trait-dummy X tensor, ns2 convention),
# fit_poisson_gllvm / fit_nb_gllvm / fit_binomial_gllvm (intrinsic per-trait
# beta intercepts = R's 0 + trait means).
# argv: ARGS[1] = the campaign output dir
using GLLVM
using DelimitedFiles
using Statistics

out = ARGS[1]
man, _ = readdlm(joinpath(out, "bench-manifest.csv"), ',', header = true)
_loglik(fit) = hasproperty(fit, :logLik) ? fit.logLik : fit.loglik

open(joinpath(out, "julia-timings.csv"), "w") do io
    println(io, "case,p,n,family,median_s,min_s,loglik,ok")
    for i in axes(man, 1)
        case = Int(man[i, 1]); p = Int(man[i, 2]); n = Int(man[i, 3])
        fam = String(strip(string(man[i, 4]), ['"', ' ']))
        raw, _ = readdlm(joinpath(out, "bench-Y-" * lpad(case, 3, '0') * ".csv"),
                         ',', header = true)
        Y = Matrix{Float64}(raw)
        @assert size(Y) == (p, n)
        times = Float64[]; ll = NaN; ok = true
        for r in 1:5
            t = @elapsed try
                fit = if fam == "gaussian"
                    X = zeros(p, n, p)
                    for j in 1:p
                        X[j, :, j] .= 1
                    end
                    GLLVM.fit_gaussian_gllvm(Y; K = 2, X = X)
                elseif fam == "poisson"
                    GLLVM.fit_poisson_gllvm(Int.(round.(Y)); K = 2)
                elseif fam == "nbinom2"
                    GLLVM.fit_nb_gllvm(Int.(round.(Y)); K = 2)
                elseif fam == "binomial"
                    GLLVM.fit_binomial_gllvm(Int.(round.(Y)); K = 2)
                else
                    error("unknown family $fam")
                end
                ll = _loglik(fit)
            catch err
                ok = false
                println(stderr, "case=$case $fam FAILED: ", sprint(showerror, err)[1:200])
            end
            push!(times, t)
            ok || break
        end
        println(io, join([case, p, n, fam, median(times), minimum(times), ll, ok], ","))
        flush(io)
        println(stderr, "J done case=$case $fam p=$p n=$n median=$(round(median(times), digits = 3))s ok=$ok")
    end
end
println("BENCH_FULL_JULIA_DONE")
