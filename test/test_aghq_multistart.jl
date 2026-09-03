using Test,GLLVM,Distributions
@testset "AM multistart selection" begin
    @test isdefined(GLLVM,:aghq_multistart_optimize)
    if isdefined(GLLVM,:aghq_multistart_optimize)
        candidate(f,c;u=true,p=[1.])=(objective=f,converged=c,usable=u,parameters=p)
        @test GLLVM._aghq_select_run([candidate(1.,false),candidate(2.,true)])==2
        @test GLLVM._aghq_select_run([candidate(2.,true),candidate(1.,true)])==2
        @test GLLVM._aghq_select_run([candidate(2.,false),candidate(1.,false)])==2
        @test GLLVM._aghq_select_run([candidate(1.,true),candidate(1.,true)])==1
        @test GLLVM._aghq_select_run([candidate(Inf,true),candidate(NaN,true),candidate(1.,true;p=[NaN])])===nothing
        @test GLLVM._aghq_select_run([candidate(1.,true;u=false)])===nothing
        grid=GLLVM.aghq_grid(1,3)
        objective=(t,a)->-GLLVM.aghq_frozen_logintegral(z->logpdf(Normal(),z[1])+logpdf(Normal(t[1]+z[1],1.),2.),a[1],grid)
        # Actual posterior mode depends on response minus beta, not beta.
        adapt=t->[GLLVM.aghq_adaptation([(2-t[1])/2],reshape([2.],1,1))]
        starts=[[-1.],[3.]];before=deepcopy(starts)
        result=GLLVM.aghq_multistart_optimize(starts,adapt,objective;n_adapt=40)
        @test starts==before
        @test length(result.runs)==2
        @test result.usable && result.selected.converged
        @test result.selected.parameters[1] ≈ 2. atol=1e-6
        @test result.selected.objective ≈ -logpdf(Normal(2.,sqrt(2)),2.) atol=1e-8
        @test result.selected===result.runs[result.winner]
        failed=GLLVM.aghq_multistart_optimize(starts,t->error("bad mode"),objective)
        @test !failed.usable && failed.selected===nothing && failed.winner===nothing
        @test length(failed.runs)==2 && all(r->r.stop_reason==:adaptation_failed,failed.runs)
        @test_throws InterruptException GLLVM.aghq_multistart_optimize(starts,t->throw(InterruptException()),objective)
        for bad in (Vector{Float64}[],[Float64[]],[[NaN]],[[1.],[1.,2.]])
            @test_throws ArgumentError GLLVM.aghq_multistart_optimize(bad,adapt,objective)
        end
    end
end
