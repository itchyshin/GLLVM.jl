using GLLVM, Test
module Core070OrdinalLinkInput
using GLLVM, Test
struct ResponseRead <: Exception end
struct NoRead <: AbstractMatrix{Int} end
Base.size(::NoRead)=(3,5)
Base.getindex(::NoRead,::Int,::Int)=throw(ResponseRead())
Y=NoRead(); X=reshape(collect(1.0:15.0),3,5,1)
routes=(
    link->fit_ordinal_gllvm(Y;K=1,link=link),
    link->fit_ordinal_gllvm_pertrait(Y;K=1,link=link),
    link->fit_ordinal_gllvm_pertrait_cov(Y;K=1,X=X,link=link),
    link->fit_gllvm(Y;family=Ordinal(),K=1,link=link),
    link->gllvm(@formula(y~1),Y,(site=1:5,);family=Ordinal(),K=1,link=link),
    link->gllvm(@formula(y~1+x),Y,(x=collect(1.0:5.0),);family=Ordinal(),K=1,link=link))
@testset "Ordinal supported links checked before responses" begin
    for route in routes
        for link in (IdentityLink(),LogLink(),CLogLogLink())
            error=try route(link);nothing catch e;e end
            @test error isa ArgumentError
            @test error isa ArgumentError && occursin("LogitLink or ProbitLink",sprint(showerror,error))
        end
        for link in (LogitLink(),ProbitLink())
            @test_throws ResponseRead route(link)
        end
    end
    long=(y=repeat([1,2,3],5),species=repeat(1:3,5),site=repeat(1:5;inner=3))
    @test_throws ArgumentError gllvm(@formula(y~1),long;family=Ordinal(),K=1,link=IdentityLink())
end
end
