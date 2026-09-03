# M3 performance pre-run, Julia side: fit the identical matrices the R stage
# saved (bench-Y-*.csv + bench-manifest.csv) with the paired canonical model
# (trait-dummy X mean design, matching value ~ 0 + trait + latent(..., d=2,
# unique=FALSE)), timing 3 reps each. Same convention as the ns2 batch.
# argv: ARGS[1] = the pre-run output dir written by core070_bench_prerun.R
using GLLVM
using DelimitedFiles
using Statistics

out = ARGS[1]
man, _ = readdlm(joinpath(out, "bench-manifest.csv"), ',', header = true)
_loglik(fit) = hasproperty(fit, :logLik) ? fit.logLik : fit.loglik

open(joinpath(out, "julia-timings.csv"), "w") do io
    println(io, "case,p,n,family,median_s,min_s,loglik")
    for i in axes(man, 1)
        case = Int(man[i, 1]); p = Int(man[i, 2]); n = Int(man[i, 3])
        fam = String(strip(string(man[i, 4])))
        raw, _ = readdlm(joinpath(out, "bench-Y-" * lpad(case, 2, '0') * ".csv"),
                         ',', header = true)
        Y = Matrix{Float64}(raw)
        @assert size(Y) == (p, n)
        X = zeros(p, n, p)
        for j in 1:p
            X[j, :, j] .= 1
        end
        times = Float64[]; ll = NaN
        for r in 1:3
            t = @elapsed begin
                # Poisson's per-trait intercepts β are intrinsic to the native
                # model (no X kwarg) and correspond to R's `0 + trait` means;
                # the Gaussian path takes the trait-dummy X tensor (ns2 convention).
                fit = fam == "poisson" ?
                    GLLVM.fit_poisson_gllvm(Int.(round.(Y)); K = 2) :
                    GLLVM.fit_gaussian_gllvm(Y; K = 2, X = X)
                ll = _loglik(fit)
            end
            push!(times, t)
        end
        println(io, join([case, p, n, fam, median(times), minimum(times), ll], ","))
        println(stderr, "done case=$case fam=$fam p=$p n=$n median=$(round(median(times), digits = 3))s ll=$ll")
    end
end
println("BENCH_PRERUN_JULIA_DONE")
