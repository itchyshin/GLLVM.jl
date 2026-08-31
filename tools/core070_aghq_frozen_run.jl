using GLLVM,Test,TOML,SHA
@testset "AGHQ frozen adaptation and adjacent regressions" begin
    include(joinpath(@__DIR__,"../test/test_aghq_frozen.jl"))
    include(joinpath(@__DIR__,"../test/test_aghq_grid.jl"))
    include(joinpath(@__DIR__,"../test/test_aghq_adapt.jl"))
    include(joinpath(@__DIR__,"../test/test_aghq_gate.jl"))
    include(joinpath(@__DIR__,"../test/test_aghq_kd_bound.jl"))
end
records=[]
for H in [[2.0 .3;.3 1.0],[-.25 0.;0. 2.],[0. 0.;0. 2.],[1e-12 0.;0. 2.],[2. .4;.2 1.]]
    a=GLLVM.aghq_adaptation([.1,-.2],H)
    push!(records,Dict("mode"=>a.mode,"inverse_root_column_major"=>vec(a.inverse_root),
        "logjac"=>a.logjac,"curvature_repaired"=>a.curvature_repaired,"minimum_eigenvalue"=>a.minimum_eigenvalue))
end
open(io->TOML.print(io,Dict("factors"=>records,"julia_version"=>string(VERSION),"package_root"=>pkgdir(GLLVM))),ENV["CORE070_AGHQ_FROZEN_OUTPUT"],"w")
println("AGHQ_FROZEN_FACTORS_SHA256 ",bytes2hex(sha256(read(ENV["CORE070_AGHQ_FROZEN_OUTPUT"]))))
