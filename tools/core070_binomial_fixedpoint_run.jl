using GLLVM,TOML,LinearAlgebra,SHA,Test
r=TOML.parsefile(ENV["CORE070_BINOMIAL_PAIR_INPUT"])
d=TOML.parsefile(ENV["CORE070_BINOMIAL_FIXTURE_INPUT"])
p,n,K=d["p"],d["n"],d["K"];Y=reshape(d["responses"],p,n)
q=GLLVM.aghq_binomial_problem(Y,K;k=5)
function evaluate(t)
 a=q.adapt(t);f=q.objective(t,a)
 g=GLLVM.ForwardDiff.gradient(v->q.objective(v,a),t)
 (f=f,g=g)
end
fresh(t)=q.objective(t,q.adapt(t))
function jacobian(t;h=1e-5)
 J=zeros(length(t),length(t))
 for j in eachindex(t)
  step=h*(1+abs(t[j]));e=zeros(length(t));e[j]=step
  J[:,j]=(evaluate(t+e).g-evaluate(t-e).g)/(2step)
 end
 J
end
function total(t;h=1e-5)
 [let step=h*(1+abs(t[j]));e=zeros(length(t));e[j]=step
   (fresh(t+e)-fresh(t-e))/(2step)
  end for j in eachindex(t)]
end
function diagnostic(start,label)
 t=copy(start);trace=Dict[];trials=Dict[];reason="iteration_cap";err=""
 try
  for iter in 0:8
   e=evaluate(t)
   push!(trace,Dict("iteration"=>iter,"parameters"=>copy(t),"objective"=>e.f,
                   "frozen_gradient"=>e.g,"gradient_max"=>maximum(abs,e.g)))
   println("BF_POINT ",label," ",iter," ",e.f," ",maximum(abs,e.g))
   if maximum(abs,e.g)<1e-6;reason="frozen_residual_met";break;end
   iter==8 && break
   J=jacobian(t);step=-(J\e.g)
   all(isfinite,step) || error("nonfinite Newton proposal")
   scale=max(1.,maximum(abs,step));step/=scale
   trace[end]["jacobian_singular_values"]=svdvals(J)
   trace[end]["jacobian_asymmetry"]=maximum(abs,J-J')
   accepted=false
   for j in 0:8
    rho=2.0^(-j);trial=t+rho*step
    local value
    try
     value=evaluate(trial)
    catch ex
     ex isa InterruptException && rethrow()
     push!(trials,Dict("iteration"=>iter,"rho"=>rho,"parameters"=>trial,
                      "accepted"=>false,"error"=>sprint(showerror,ex)))
     continue
    end
    accepted=sum(abs2,value.g)<sum(abs2,e.g)
    push!(trials,Dict("iteration"=>iter,"rho"=>rho,"parameters"=>trial,
       "objective"=>value.f,"frozen_gradient"=>value.g,"accepted"=>accepted))
    if accepted;t=trial;break;end
   end
   if !accepted;reason="no_residual_descent";break;end
  end
 catch ex
  ex isa InterruptException && rethrow()
  reason="diagnostic_failed";err=sprint(showerror,ex)
 end
 e=evaluate(t);g1=total(t);g2=total(t;h=2e-5)
 md=q.mode_diagnostics(t);L=GLLVM.unpack_lambda(t[p+1:end],p,K)
 Dict("start_label"=>label,"start"=>start,"parameters"=>t,"trace"=>trace,"trials"=>trials,
      "stop_reason"=>reason,"error"=>err,"objective"=>e.f,"frozen_gradient"=>e.g,
      "frozen_residual_met"=>maximum(abs,e.g)<1e-6,"total_gradient_fd"=>g1,
      "total_gradient_double_step"=>g2,"fd_stability"=>maximum(abs,g1-g2),
      "objective_change_from_start"=>e.f-evaluate(start).f,
      "objective_change_from_native"=>e.f-evaluate(r["native_parameters"]).f,
      "objective_change_from_R"=>e.f-evaluate(r["r_native_parameters"]).f,
      "mode_gradient_max"=>maximum(x.gradient_max for x in md),
      "curvature_repairs"=>count(x->x.curvature_repaired,md),
      "mode_site_count"=>length(md),"loading_covariance"=>vec(L*L'),
      "parity_pass"=>false)
end
native=evaluate(r["native_parameters"]);rg=evaluate(r["r_native_parameters"])
@testset "BF retained endpoint identity" begin
 @test native.f≈r["native_objective"] atol=1e-10
 @test native.g≈r["native_gradient"] atol=1e-10
 @test rg.f≈r["r_objective"]+r["readapted_rpoint_delta"] atol=1e-10
 @test [p,K,n]==[5,2,60]
end
runs=[diagnostic(r["native_parameters"],"native"),diagnostic(r["r_native_parameters"],"R")]
@testset "BF finite diagnostic receipts" begin
 @test length(runs)==2
 @test all(x->length(x["parameters"])==14 && isfinite(x["objective"]),runs)
 @test all(x->!x["parity_pass"],runs)
 @test all(x->x["fd_stability"]<1e-5,runs)
 @test all(x->x["mode_site_count"]==n && x["mode_gradient_max"]<=1e-7,runs)
 @test all(x->length(x["loading_covariance"])==p*p,runs)
end
out=ENV["CORE070_AGHQ_PAIR_OUTPUT"]
record=Dict("scope"=>"DIAGNOSTIC_ONLY_NOT_FIT_OR_PARITY","case_id"=>"BF-SEED43-K5",
 "reference"=>"b4d5fee64def88bc768dda1f1f77c29b295edd86","k"=>5,"runs"=>runs,
 "source_pair_sha256"=>bytes2hex(sha256(read(ENV["CORE070_BINOMIAL_PAIR_INPUT"]))),
 "fixture_sha256"=>bytes2hex(sha256(read(ENV["CORE070_BINOMIAL_FIXTURE_INPUT"]))),
 "julia_version"=>string(VERSION),"package_root"=>pkgdir(GLLVM))
open(io->TOML.print(io,record),out,"w")
println("BF_RECEIPT_SHA256 ",bytes2hex(sha256(read(out))))
