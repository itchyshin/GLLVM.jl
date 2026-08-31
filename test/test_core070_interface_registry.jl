using Test,TOML
isdefined(@__MODULE__, :Core070Receipts) || include(joinpath(@__DIR__,"parity","core070_receipts.jl"))
using .Core070Receipts

@testset "Receipt scope is not inferred from count" begin
    mktempdir() do root
        write(joinpath(root,"fixture.jl"),"# synthetic")
        inventory=execution_inventory(root,["fixture.jl"])
        run=start_run!(joinpath(root,"receipts");requested_case_ids=["case-$i" for i in 1:17],
            source=Dict(),inventory=inventory,contract_sha256="synthetic")
        receipt=TOML.parsefile(joinpath(run.dir,"run.toml"))
        @test receipt["scope"]=="subset"
    end
end

include(joinpath(@__DIR__, "parity", "core070_case_registry.jl"))
using .Core070CaseRegistry
@testset "Separate family and interface registration" begin
    @test length(FAMILY_IDS) == 17
    @test length(INTERFACE_IDS) == 5
    @test length(requested_ids()) == 41
    @test isempty(intersect(FAMILY_IDS, INTERFACE_IDS))
    @test requested_ids(first(INTERFACE_IDS)) == [first(INTERFACE_IDS)]
    @test length(MODEL_IDS) == 1
    @test requested_ids(join(GAUSSIAN_IDS,",")) == GAUSSIAN_IDS
    @test_throws ArgumentError requested_ids(first(GAUSSIAN_IDS))
    @test_throws ArgumentError requested_ids(last(GAUSSIAN_IDS))
    for invalid in ("unknown", "NATIVE-06-NB2,NATIVE-06-NB2", "NATIVE-06-NB2,", "NATIVE-05-GAMMA")
        @test_throws ArgumentError requested_ids(invalid)
    end
    @test length(requested_ids("NATIVE-05-GAMMA,NATIVE-09-BETABINOMIAL,NATIVE-16-NB1")) == 3
    contract = TOML.parsefile(joinpath(@__DIR__, "..", "docs/dev-log/core070/frozen-r070-contract.toml"))
    @test validate_manifest(contract)
    for change in (
        d -> empty!(d["interface_case_ids"]),
        d -> push!(d["families"], deepcopy(d["families"][1])),
        d -> (d["interfaces"][1]["fixture"] = "wrong.jl"),
        d -> (d["family_smoke_case_ids"][1] = first(INTERFACE_IDS)),
    )
        bad = deepcopy(contract); change(bad)
        @test_throws ArgumentError validate_manifest(bad)
    end
    for (ids, scope, count) in ((FAMILY_IDS, "all17", 17),
                              (REGISTERED_IDS, "subset", 17),
                              (vcat(FAMILY_IDS[2:end], INTERFACE_IDS), "subset", 16))
        mktempdir() do root
            write(joinpath(root,"fixture.jl"), "# scope fixture")
            run = start_run!(joinpath(root,"receipts"); requested_case_ids=ids,
                family_smoke_case_ids=FAMILY_IDS, source=Dict(),
                inventory=execution_inventory(root,["fixture.jl"]), contract_sha256="synthetic")
            r = TOML.parsefile(joinpath(run.dir,"run.toml"))
            @test r["scope"] == scope
            @test r["selected_family_count"] == count
        end
    end
end

@testset "Required Poisson/Beta cells include complete health" begin
    @test FIXTURES["NATIVE-03-POISSON"] == "test/parity/test_poisson_required.jl"
    @test FIXTURES["NATIVE-08-BETA"] == "test/parity/test_beta_required.jl"
end

@testset "Formula cases require a fresh native comparison" begin
    for (formula, native) in [
        ("CORE070-FAMILY-02-LOG-FORMULA-INTERFACE", "NATIVE-03-POISSON"),
        ("CORE070-FAMILY-07-LOGIT-FORMULA-INTERFACE", "NATIVE-08-BETA"),
        ("CORE070-FAMILY-11-LOG-FORMULA-INTERFACE", "NATIVE-12-TRUNCATED-NB2")]
        @test formula in INTERFACE_IDS
        @test_throws ArgumentError requested_ids(formula)
        @test requested_ids(native * "," * formula) == [native, formula]
        @test_throws ArgumentError requested_ids("NATIVE-06-NB2," * formula)
    end
end
