# Independent stdlib verification of retained finite-difference matrices and steps.
using LinearAlgebra, TOML, Test
function check_math(r)
    q=r["q"]
    @assert q>0 && length(r["parameters"])==length(r["gradient"])==q
    @assert length(r["curvature_h1_column_major"])==length(r["curvature_h2_column_major"])==q*q
    A=reshape(r["curvature_h1_column_major"],q,q)
    B=reshape(r["curvature_h2_column_major"],q,q)
    scale=max(1.0,maximum(abs,B))
    stable=maximum(abs,A-B)/scale
    asym=maximum(abs,B-transpose(B))/scale
    @assert stable==r["curvature_relative_stability"] && asym==r["curvature_relative_asymmetry"]
    H=Symmetric((B+transpose(B))/2)
    values=eigvals(H)
    @assert isapprox(values,r["eigenvalues"];rtol=1e-10,atol=1e-10)
    admitted=all(isfinite,H) && stable<=1e-4 && asym<=1e-4 && minimum(values)>1e-8*maximum(values)
    @assert admitted==r["diagnostic_step_admitted"]
    @assert r["checks"]["curvature_stable"]==(stable<=1e-4)
    @assert r["checks"]["curvature_symmetric"]==(asym<=1e-4)
    @assert length(r["objectives"])==5 && all(isfinite,r["objectives"])
    if admitted
        step=-(H\r["gradient"])
        @assert isapprox(step,r["diagnostic_step"];rtol=1e-10,atol=1e-12)
        @assert isapprox(-dot(r["gradient"],step)/2,r["quadratic_predicted_decrease"];rtol=1e-10,atol=1e-20)
        @assert [o["alpha"] for o in r["observations"]]==[0.,0.25,0.5,1.,2.]
        for o in r["observations"]
            @assert length(o["objectives"])==5 && length(o["gradient"])==q
            @assert all(isfinite,o["objectives"]) && all(isfinite,o["gradient"])
            @assert isapprox(o["parameters"],r["parameters"]+o["alpha"]*step;rtol=1e-12,atol=1e-14)
        end
    else
        @assert isempty(r["observations"]) && all(iszero,r["diagnostic_step"])
    end
    true
end
if ARGS==["--self-test"]
    r=Dict{String,Any}("q"=>2,"parameters"=>[0.,0.],"gradient"=>[2.,4.],
      "curvature_h1_column_major"=>[2.,0.,0.,4.],"curvature_h2_column_major"=>[2.,0.,0.,4.],
      "curvature_relative_stability"=>0.,"curvature_relative_asymmetry"=>0.,"eigenvalues"=>[2.,4.],
      "diagnostic_step_admitted"=>true,"diagnostic_step"=>[-1.,-1.],"quadratic_predicted_decrease"=>3.,
      "objectives"=>zeros(5),"checks"=>Dict("curvature_stable"=>true,"curvature_symmetric"=>true),
      "observations"=>[Dict("alpha"=>a,"parameters"=>[-a,-a],"gradient"=>[2.,4.]*(1-a),"objectives"=>fill(3a*a-6a,5)) for a in [0.,.25,.5,1.,2.]])
    @testset "Curvature evidence negative controls" begin
        @test check_math(r)
        for key in ["q","eigenvalues","diagnostic_step","quadratic_predicted_decrease","curvature_relative_stability"]
            b=deepcopy(r)
            b[key]=key=="q" ? 3 : b[key] isa Vector ? b[key].+1 : b[key]+1
            @test_throws AssertionError check_math(b)
        end
        b=deepcopy(r); pop!(b["observations"])
        @test_throws AssertionError check_math(b)
    end
    println("CURVATURE_MATH_7_ASSERTIONS_PASS")
else
    for path in ARGS
        check_math(TOML.parsefile(path))
    end
    length(ARGS)==6 || error("all six cases required")
    println("CURVATURE_MATH_ALL_SIX_VERIFIED")
end
