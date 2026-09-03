using GLLVM, Test

struct FormulaResponseRead <: Exception end
struct FormulaUnreadResponse <: AbstractMatrix{Float64} end
Base.size(::FormulaUnreadResponse) = (3, 8)
Base.getindex(::FormulaUnreadResponse, ::Int, ::Int) = throw(FormulaResponseRead())

@testset "Formula site rows checked before response access" begin
    Y = FormulaUnreadResponse()
    for family in (GLLVM.Normal(),GLLVM.Poisson(),GLLVM.NegativeBinomial(),GLLVM.Beta())
        for m in (7,9), formula in (@formula(y ~ 1),@formula(y ~ 1 + temp))
            @test_throws DimensionMismatch gllvm(formula,Y,(temp=zeros(m),);family=family,K=1)
        end
        @test_throws DimensionMismatch gllvm(@formula(y ~ 1),Y,(site=1:8,unused=zeros(7));family=family,K=1)
        @test_throws FormulaResponseRead gllvm(@formula(y ~ 1),Y,(site=1:8,);family=family,K=1)
        @test_throws FormulaResponseRead gllvm(@formula(y ~ 1),Y,NamedTuple();family=family,K=1)
    end
end
