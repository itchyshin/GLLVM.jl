# No optimizer run: evaluate the same model at the retained frozen-R point.
using GLLVM, Test, Random, Distributions, SHA, TOML
root, params_path, output = ARGS
@assert realpath(Base.pkgdir(GLLVM)) == realpath(root)
isdir(output) && error("output must be fresh")
mkpath(output)
rows = split.(readlines(params_path)[2:end],',')
getparam(name) = [parse(Float64,row[3]) for row in rows if row[1]==name]
λ,β,σ,ν = getparam.( ("lambda","beta","sigma","nu") )
# Same explicit loading constants as parity_loadings_p5k2, read from its helper
# to avoid introducing a second fixture definition.
include(joinpath(root,"test/parity/parity_helpers.jl"))
Random.seed!(71)
p,K,n=5,1,130
η=[0.2,-0.1,0.3,0.0,-0.2] .+ (0.5 .* parity_loadings_p5k2()[:,1:K])*randn(K,n)
Y=zeros(p,n)
for t in 1:p,s in 1:n;Y[t,s]=η[t,s]+0.7*rand(TDist(4.0));end
θ=vcat(λ,β,log.(σ),log.(ν.-1))
objective(x) = -GLLVM.studentt_marginal_loglik_laplace(Y,reshape(x[1:5],5,1),x[6:10],exp.(x[11:15]);ν=1 .+exp.(x[16:20]))
value=objective(θ)
gradient=GLLVM.ForwardDiff.gradient(objective,θ)
hessian=GLLVM.ForwardDiff.hessian(objective,θ)
@test isfinite(value)
@test all(isfinite,gradient)
@test all(isfinite,hessian)
report=Dict("scope"=>"FROZEN_POINT_DIAGNOSTIC_NO_OPTIMIZATION","objective"=>value,
    "gradient"=>gradient,"hessian_rows"=>[collect(row) for row in eachrow(hessian)],
    "max_abs_gradient"=>maximum(abs,gradient),
    "data_sha256"=>bytes2hex(sha256(reinterpret(UInt8,vec(Y)))),
    "parameter_file_sha256"=>bytes2hex(sha256(read(params_path))))
open(joinpath(output,"point.toml"),"w") do io;TOML.print(io,report);end
println("STUDENT_FROZEN_POINT_FINITE_NO_OPTIMIZER_CLAIM objective=",value)
