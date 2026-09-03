using Test,GLLVM,LinearAlgebra
# Deterministic callbacks expose outer transitions independently of an optimizer.
ao_adapt(t)=[GLLVM.aghq_adaptation(copy(t),Matrix{Float64}(I,length(t),length(t)))]
ao_quad(t,a)=sum(abs2,t)
@testset "AO-01 normalized Gaussian marginal fit" begin
    y=[-1.,.2,.8,1.5,2.];loading=.7;variance=1+loading^2
    adapt=t->[GLLVM.aghq_adaptation([loading*(v-t[1])/variance],reshape([variance],1,1)) for v in y]
    grid=GLLVM.aghq_grid(1,5)
    objective=(t,ads)->-sum(GLLVM.aghq_frozen_logintegral(
        z->-(y[i]-t[1]-loading*z[1])^2/2-z[1]^2/2-log(2pi),ads[i],grid) for i in eachindex(y))
    result=GLLVM.aghq_outer_optimize([3.],adapt,objective)
    truth=sum(y)/length(y)
    @test result.usable && result.converged
    @test result.parameters[1] ≈ truth atol=1e-8
    @test result.objective ≈ sum((v-truth)^2/(2variance)+log(2pi*variance)/2 for v in y) atol=1e-8
    @test result.parameter_shift>1
    @test result.gradient_kind===:frozen_surrogate
    @test result.objective ≈ objective(result.parameters,result.adaptation) atol=1e-12
end
@testset "AO-02 reject stale-node descent" begin
    objective=(t,a)->t[1]^2-10*(t[1]-a[1].mode[1])
    result=GLLVM.aghq_outer_optimize([1.],ao_adapt,objective;step=(f,t,cap)->[4.],n_adapt=20)
    @test !result.converged && result.usable
    @test result.parameters==[1.] && result.objective==1.
    @test result.stop_reason===:no_merit_descent
    @test all(!r.accepted for r in result.trace[2:end])
    @test last(result.trace).rho==1/64
    @test result.adaptation[1].mode==result.parameters
    @test result.frozen_gradient_max==8.
    # Frozen R halves while rho > rho_min; it does not clip to rho_min.
    custom=GLLVM.aghq_outer_optimize([1.],ao_adapt,objective;step=(f,t,cap)->[4.],rho_min=.3)
    @test last(custom.trace).rho==.25
end
@testset "AO-03 continuation ceiling" begin
    caps=Any[]
    step=(f,t,cap)->begin push!(caps,cap);cap==2 ? t.+4 : t.-.1 end
    r=GLLVM.aghq_outer_optimize([3.],ao_adapt,ao_quad;step=step,n_adapt=22,escalate_patience=2)
    @test count(==(2),caps)==1
    @test all(c==1 for c in caps[findfirst(==(2),caps)+1:end])
    @test any(!x.accepted for x in r.trace)
    @test r.objective<9
end
@testset "AO-04 stopping and relative gradient" begin
    zero_step=(f,t,cap)->copy(t)
    r=GLLVM.aghq_outer_optimize([0.],ao_adapt,ao_quad;step=zero_step)
    @test r.converged && r.passes==2
    stuck=GLLVM.aghq_outer_optimize([1.],ao_adapt,ao_quad;step=zero_step)
    @test !stuck.converged && stuck.stop_reason===:warm_start_stagnation
    relative=GLLVM.aghq_outer_optimize([1.],ao_adapt,(t,a)->1e8+sum(abs2,t);step=zero_step)
    @test relative.converged && relative.relative_gradient<1e-6
    absolute=GLLVM.aghq_outer_optimize([1.],ao_adapt,(t,a)->1e8+sum(abs2,t);step=zero_step,grad_tol_rel=0.)
    @test !absolute.converged
    moved=GLLVM.aghq_outer_optimize([1.],ao_adapt,ao_quad;step=(f,t,cap)->[.5])
    @test !moved.converged && moved.stop_reason===:objective_stagnation
end
@testset "AO-05 failures and no unchecked final iterate" begin
    r=GLLVM.aghq_outer_optimize([1.],ao_adapt,ao_quad;step=(f,t,cap)->[0.],n_adapt=1)
    @test r.parameters==[1.] && r.objective==1. && !r.converged
    @test r.stop_reason===:adaptation_cap
    bad=t->t[1]==1 ? ao_adapt(t) : error("trial adaptation failure")
    r=GLLVM.aghq_outer_optimize([1.],bad,ao_quad;step=(f,t,cap)->[0.])
    @test r.usable && !r.converged && r.parameters==[1.]
    @test r.stop_reason===:adaptation_failed && occursin("trial adaptation",r.error)
    r=GLLVM.aghq_outer_optimize([1.],ao_adapt,ao_quad;step=(f,t,cap)->error("optimizer failure"))
    @test r.usable && r.stop_reason===:optimizer_failed && r.parameters==[1.]
    calls=Ref(0)
    lastbad=t->begin calls[]+=1;calls[]>1 && error("final failure");ao_adapt(t) end
    r=GLLVM.aghq_outer_optimize([1.],lastbad,ao_quad;n_adapt=1)
    @test !r.usable && !r.converged && r.stop_reason===:finalization_failed
    @test_throws InterruptException GLLVM.aghq_outer_optimize([1.],t->throw(InterruptException()),ao_quad)
end
@testset "AO-06 invalid controls and shapes" begin
    for kw in [(;n_adapt=0),(;iter_cap=0),(;escalate_patience=0),(;rho_min=0.),(;rho_min=2.),(;grad_tol=NaN),(;f_tol=-1.),(;shift_tol=Inf),(;n_adapt=true)]
        @test_throws ArgumentError GLLVM.aghq_outer_optimize([1.],ao_adapt,ao_quad;kw...)
    end
    @test_throws ArgumentError GLLVM.aghq_outer_optimize([NaN],ao_adapt,ao_quad)
    @test_throws ArgumentError GLLVM.aghq_outer_optimize(Float64[],ao_adapt,ao_quad)
    r=GLLVM.aghq_outer_optimize([1.],t->GLLVM.AGHQAdaptation[],ao_quad)
    @test !r.usable && r.stop_reason===:adaptation_failed
end

@testset "AO-06 malformed caches and finalization; gradient diagnostics" begin
    for a in [GLLVM.AGHQAdaptation([0.],ones(2,2),0.,false,1.),
              GLLVM.AGHQAdaptation([0.],ones(1,1),NaN,false,1.)]
        r=GLLVM.aghq_outer_optimize([1.],t->[a],ao_quad)
        @test !r.usable && r.stop_reason===:adaptation_failed
    end
    changed=t->t[1]==1 ? ao_adapt(t) : [GLLVM.aghq_adaptation([0.,0.],Matrix{Float64}(I,2,2))]
    r=GLLVM.aghq_outer_optimize([1.],changed,ao_quad;step=(f,t,cap)->[0.])
    @test r.usable && r.parameters==[1.] && !r.converged && r.stop_reason===:adaptation_failed
    calls=Ref(0)
    finalchanged=t->begin calls[]+=1;calls[]==1 ? ao_adapt(t) : changed([0.]) end
    r=GLLVM.aghq_outer_optimize([1.],finalchanged,ao_quad;n_adapt=1)
    @test !r.usable && !r.converged && r.stop_reason===:finalization_failed
    # A callback without Dual support still yields an explicit nonconverged diagnostic.
    nondiff=(t,a)->Float64(t[1])^2
    r=GLLVM.aghq_outer_optimize([1.],ao_adapt,nondiff;step=(f,t,cap)->copy(t))
    @test r.usable && !r.converged && isnan(r.frozen_gradient_max)
end

@testset "AO-03 full schedule and explicit continuation controls" begin
    caps=Any[]
    step=(f,t,cap)->begin push!(caps,cap);t.-.01 end
    GLLVM.aghq_outer_optimize([3.],ao_adapt,ao_quad;step=step,n_adapt=18)
    @test isequal(unique(caps),Any[1,2,5,25,nothing])
    empty!(caps)
    GLLVM.aghq_outer_optimize([3.],ao_adapt,ao_quad;step=step,n_adapt=5,continuation=false)
    @test length(caps)==4 && all(==(1),caps)
    empty!(caps)
    GLLVM.aghq_outer_optimize([3.],ao_adapt,ao_quad;step=step,n_adapt=5,iter_cap=2)
    @test length(caps)==4 && all(==(2),caps)
    ordinary=GLLVM._aghq_outer_step(t->sum(abs2,t),[1.],nothing,50,1e-8)
    @test maximum(abs,ordinary)<1e-8
end
