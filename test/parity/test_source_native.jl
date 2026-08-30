# Explicit opt-in fixed-point native evaluator check; not optimizer parity.
using Test, GLLVM, LinearAlgebra, ForwardDiff
@assert realpath(Base.pkgdir(GLLVM)) == realpath(pwd())
rows(p) = split.(readlines(p)[2:end], '\t')
matrix(p) = reduce(vcat, [permutedims(parse.(Float64,r)) for r in rows(p)])
@testset "Native additive source vs frozen R" begin
    for model in ("ANIMAL-LATENT", "KERNEL-ONE", "KERNEL-TWO"), point in 1:2
        id = "$model-P$point"; dir = joinpath(ARGS[1],id)
        data = rows(joinpath(dir,"data.tsv"))
        t = [parse(Int,r[1]) for r in data]; s = [parse(Int,r[2]) for r in data]
        groups = [parse(Int,r[3]) for r in data]; y = [parse(Float64,r[4]) for r in data]
        c = only(rows(joinpath(dir,"contract.tsv"))); nr = parse(Int,c[3]); rnll = parse(Float64,c[4])
        Cs = [matrix(joinpath(dir,"source-$r.tsv")) for r in 1:nr]
        pars = rows(joinpath(dir,"parameters.tsv")); names = [r[1] for r in pars]
        theta = [parse(Float64,r[2]) for r in pars]; rg = [parse(Float64,r[3]) for r in pars]
        bi = findall(==("b_fix"),names); li = findall(==(nr==2 ? "theta_rr_kernel" : "theta_rr_phy"),names)
        si = findall(==("log_sigma_eps"),names)
        Y = zeros(3,18); seen = zeros(Int,3,18)
        for j in eachindex(y); Y[t[j],s[j]]=y[j]; seen[t[j],s[j]]+=1; end
        @test all(==(1),seen)
        gs = [only(unique(groups[s.==site])) for site in 1:18]
        incidence = repeat(reshape(gs,18,1),1,nr)
        objective(v) = -GLLVM._gaussian_source_loglik(Y,v[bi],reshape(v[li],3,nr),Cs,incidence,exp(only(v[si])))
        val = objective(theta); g = ForwardDiff.gradient(objective,theta)
        delta = abs(val-rnll); err = maximum(abs.(g-rg)./(1 .+abs.(rg)))
        @test delta <= 1e-6
        @test err <= 1e-6
        println(id," abs_delta=",delta," scaled_gradient_error=",err)
    end
end
