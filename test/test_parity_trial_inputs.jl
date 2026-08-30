using Test
include(joinpath(@__DIR__, "parity", "parity_trial_inputs.jl"))
@testset "Oracle trial and link preparation" begin
    Y = [0 2 0;1 1 3]; N = [2 4 6;3 5 7]
    for link in (:logit,:probit,:cloglog)
        t,l = parity_trial_inputs(Y,:binomial,N,link)
        @test t == N
        @test vec(t) == [2,3,4,5,6,7]
        @test l == String(link)
        @test t !== N
        t[1] = 99
        @test N[1] == 2
    end
    t,l = parity_trial_inputs(Y,:betabinomial,N)
    @test t == N && l == "logit"
    @test parity_trial_inputs([0 1;1 0],:binomial,nothing)[1] == ones(2,2)
    @test_throws ArgumentError parity_trial_inputs(Y,:binomial,nothing)
    @test_throws ArgumentError parity_trial_inputs(Y,:betabinomial,nothing)
    @test_throws DimensionMismatch parity_trial_inputs(Y,:binomial,ones(3,2))
    for family in (:gaussian,:poisson,:gamma,:negbinomial,:nb1,:beta,:ordinal)
        @test_throws ArgumentError parity_trial_inputs(Y,family,N)
        @test_throws ArgumentError parity_trial_inputs(Y,family,nothing,:probit)
        @test parity_trial_inputs(Y,family,nothing)[1] == ones(2,3)
    end
    @test_throws ArgumentError parity_trial_inputs(Y,:binomial,N,:identity)
    @test_throws ArgumentError parity_trial_inputs(Y,:betabinomial,N,:cloglog)
    for bad in (0,-1,1.5,Inf,NaN,Int64(2)^53+1)
        @test_throws ArgumentError parity_trial_inputs(zeros(2,3),:binomial,fill(bad,2,3))
    end
    for bad in (-1,8,0.5,NaN,Inf,missing)
        @test_throws ArgumentError parity_trial_inputs(fill(bad,2,3),:binomial,N)
    end
    @test parity_trial_inputs(fill(Int64(2)^53,2,3),:binomial,fill(Int64(2)^53,2,3))[1] == fill(Float64(2)^53,2,3)
end

@testset "Actual oracle Julia preparation reaches the R boundary" begin
    # Evaluate the real function prefix, ending before _parity_require_gllvmtmb!.
    # This exercises keyword/validator wiring but intentionally never RCall.
    text = read(joinpath(@__DIR__,"parity","parity_helpers.jl"),String)
    scope = Module(:OraclePreparationProbe)
    Base.include(scope,joinpath(@__DIR__,"parity","parity_trial_inputs.jl"))
    for name in (:fit_gllvmtmb_parity_loglik,:fit_gllvmtmb_parity_loglik_x)
        start = findfirst("function $(name)(",text).start
        stop = findnext("    _parity_require_gllvmtmb!()",text,start).start-1
        Base.include_string(scope,text[start:stop]*"\nreturn trials, binomial_link, trials_provided\nend\n")
        fun = getfield(scope,name)
        y = [0 1 0;1 0 1];n = [2 4 6;3 5 7]
        args = name===:fit_gllvmtmb_parity_loglik ? (y,1) : (y,[-1.,0.,2.],1)
        for link in (:logit,:probit,:cloglog)
            t,l,provided=Base.invokelatest(fun,args...;family=:binomial,N=n,binomial_link=link)
            @test t == n
            @test l == String(link)
            @test provided
        end
        t,l,provided=Base.invokelatest(fun,args...;family=:binomial)
        @test t == ones(2,3)
        @test !provided && l=="logit"
        @test_throws ArgumentError Base.invokelatest(fun,args...;family=:poisson,N=n)
    end
end
