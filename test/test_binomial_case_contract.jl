using Test, TOML
include(joinpath(@__DIR__,"parity","binomial_case_contract.jl"))
root=normpath(joinpath(@__DIR__,".."))
@testset "Predeclared binomial model packet" begin
    path="docs/dev-log/core070/binomial-paired-contract.toml"
    original=TOML.parsefile(joinpath(root,path))
    for row in original["case"]
        c,r=binomial_case_contract(root,row["id"])
        @test r==row
        @test c["status"]=="PREDECLARED_CASES_NOT_EXECUTED"
    end
    @test_throws ErrorException binomial_case_contract(root,"UNKNOWN")
    mktempdir() do tmp
        for name in vcat([path],collect(keys(original["source_pins"])))
            mkpath(dirname(joinpath(tmp,name)));cp(joinpath(root,name),joinpath(tmp,name))
        end
        mutations=[
            c->pop!(c["case"]),
            c->push!(c["case"],deepcopy(c["case"][1])),
            c->(c["case"][1]["seed"]+=99),
            c->(c["case"][1]["link"]="probit"),
            c->(c["case"][1]["trials"]="unknown"),
            c->(c["case"][1]["hessian"]="fisher"),
            c->(c["acceptance"]["loglik_rtol"]=1e-3),
            c->(c["case"][1]["result_status"]="PASS"),
            c->empty!(c["source_pins"]),
            c->(c["source_pins"]["tools/core070_binomial_paired.jl"]="0"^64),
            c->(c["reference_commit"]="0"^40)]
        for change in mutations
            c=deepcopy(original);change(c)
            open(joinpath(tmp,path),"w") do io;TOML.print(io,c);end
            @test_throws ErrorException binomial_case_contract(tmp,"BINOMIAL-LOGIT-BERNOULLI")
        end
    end
    # Syntax only, no macro expansion/import/evaluation of the fitter.
    parsed=Meta.parseall(read(joinpath(root,"tools/core070_binomial_paired.jl"),String))
    has_parse_error(x)=x isa Expr && (x.head in (:error,:incomplete) || any(has_parse_error,x.args))
    @test parsed isa Expr
    @test !has_parse_error(parsed)
end
