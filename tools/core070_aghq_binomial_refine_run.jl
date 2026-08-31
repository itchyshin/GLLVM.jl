using GLLVM,TOML,LinearAlgebra,SHA,Test
r=TOML.parsefile(ENV["CORE070_BINOMIAL_PAIR_INPUT"])
d=TOML.parsefile(ENV["CORE070_BINOMIAL_FIXTURE_INPUT"])
p,n,K=d["p"],d["n"],d["K"];Y=reshape(d["responses"],p,n);theta=r["native_parameters"]
rows=Dict[]
for k in (5,9,15,21)
 q=GLLVM.aghq_binomial_problem(Y,K;k=k);cache=q.adapt(theta)
 frozen=t->q.objective(t,cache);fresh=t->q.objective(t,q.adapt(t))
 g=GLLVM.ForwardDiff.gradient(frozen,theta)
 h=1e-5;basis=Matrix{Float64}(I,length(theta),length(theta))
 total=[(fresh(theta+h*basis[:,j])-fresh(theta-h*basis[:,j]))/(2h) for j in eachindex(theta)]
 row=Dict("k"=>k,"objective"=>frozen(theta),"frozen_gradient"=>g,"total_gradient_fd"=>total,
 "chain_delta"=>maximum(abs.(total-g)),"merit_slope_negative_frozen"=>-dot(g,total))
 push!(rows,row)
 println("AB_NODE_DIAGNOSTIC ",k," ",row["objective"]," ",row["chain_delta"]," ",row["merit_slope_negative_frozen"])
end
@testset "AB node diagnostic identity" begin
 @test rows[1]["objective"] ≈ r["native_objective"] atol=1e-10
 @test rows[1]["frozen_gradient"] ≈ r["native_gradient"] atol=1e-10
 @test all(x->isfinite(x["objective"]) && all(isfinite,x["frozen_gradient"]) && all(isfinite,x["total_gradient_fd"]),rows)
end
out=ENV["CORE070_AGHQ_PAIR_OUTPUT"]
open(io->TOML.print(io,Dict("scope"=>"fixed-parameter node diagnostic; original k5 fit still required",
 "parameters"=>theta,"rows"=>rows,"source_pair_sha256"=>bytes2hex(sha256(read(ENV["CORE070_BINOMIAL_PAIR_INPUT"]))))),out,"w")
println("AB_NODE_RECEIPT_SHA256 ",bytes2hex(sha256(read(out))))
