using GLLVM, Test
# Wald is deliberately unsupported on this route: both old and new code stop
# before fitting. Invalid responses must fail for their own reason first.
function bridge_truncated_input_error(Y;family="truncated_poisson")
    try
        GLLVM.bridge_fit(y=Y,family=family,d=1,options=Dict("ci_method"=>"wald"))
        return nothing
    catch e
        return e
    end
end
@testset "Truncated Poisson bridge preserves count support" begin
    bad=bridge_truncated_input_error([1.5 2.0;3.0 4.0])
    @test bad isa ArgumentError
    @test occursin("positive integer",sprint(showerror,bad))
    valid=bridge_truncated_input_error([1.0 2.0;3.0 4.0])
    @test valid isa ArgumentError
    @test occursin("confidence intervals",sprint(showerror,valid))
end

@testset "Truncated bridge conversion never changes count data" begin
    invalid = (fill(0.0,2,2), fill(-1.0,2,2), fill(1.25,2,2),
        fill(nextfloat(1.0),2,2), fill(NaN,2,2), fill(Inf,2,2),
        fill(-Inf,2,2), fill(Float64(typemax(Int)),2,2),
        fill(typemax(Int),2,2), fill(Int64(2)^53+1,2,2),
        fill(big"1.00000000000000000000000001",2,2))
    valid = ([1 2;3 4], [1.0 2.0;3.0 4.0], fill(Int64(2)^53,2,2),
        fill(prevfloat(Float64(typemax(Int))),2,2), fill(big"3",2,2))
    for family in ("truncated_poisson","Truncated_Poisson","TruncPois")
        for Y in invalid
            original=copy(Y);e=bridge_truncated_input_error(Y;family=family)
            @test e isa ArgumentError
            @test occursin("positive integer",sprint(showerror,e))
            @test isequal(Y,original)
        end
        for Y in valid
            original=copy(Y);e=bridge_truncated_input_error(Y;family=family)
            @test e isa ArgumentError
            @test occursin("confidence intervals",sprint(showerror,e))
            @test isequal(Y,original)
        end
    end
end
