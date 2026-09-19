using Test
using GLLVModels
using LinearAlgebra
using SparseArrays
using StatsModels

# Public-routing fixture: fixed values, two observed tips repeatedly sampled,
# one rank-one phylogenetic field, and one independent ordinary grouping source.
# This is a dispatch contract, not a recovery or coverage experiment.
function _destination_b_precision_public_fixture()
    Q = sparse([3.0 -0.8 -0.5 0.0;
                -0.8 3.2 0.0 -0.6;
                -0.5 0.0 2.7 0.0;
                0.0 -0.6 0.0 2.9])
    phy = PrecisionPhy(findnz(Q)..., 4, 2,
        ["a1", "a2", "tip1", "tip2"],
        logdet(cholesky(Symmetric(Matrix(Q)))), 1.0, [3, 4])
    Y = [0.12 -0.31 0.27 -0.18 0.43 -0.09 0.35 -0.24;
         -0.22 0.16 -0.14 0.31 -0.05 0.28 -0.37 0.19]
    species_id = repeat([1, 2], 4)
    unit = [1, 1, 2, 2, 3, 3, 4, 4]
    x = [-1.0, -0.5, 0.0, 0.5, 1.0, 0.25, -0.25, 0.75]
    terms = [GroupingTerm(:unit; mode = :indep, common = false)]
    return (; Y, phy, species_id, unit, x, terms)
end

function _destination_b_precision_formula_design(x)
    n = length(x)
    D = zeros(2 * n, 3)
    for observation in 1:n
        rows = (2 * observation - 1):(2 * observation)
        D[rows[1], 1] = 1.0
        D[rows[2], 2] = 1.0
        D[rows, 3] .= x[observation]
    end
    return D
end

@testset "Destination B public PrecisionPhy routing" begin
    fixture = _destination_b_precision_public_fixture()
    common = (; phylo = fixture.phy, phylo_rank = 1,
        phylo_mode = :barelowrank, species_id = fixture.species_id,
        iterations = 0, g_tol = 1e-4)

    # Gaussian-only public route is exactly the established precision consumer.
    existing = GLLVModels.fit_precision_multivariate(fixture.Y, fixture.phy;
        rank = 1, mode = :barelowrank, species_id = fixture.species_id,
        iterations = 0, g_tol = 1e-4)
    routed = fit_gllvm(fixture.Y; common...)
    @test routed isa GLLVModels.PrecisionMultivariateFit
    @test routed.parameters ≈ existing.parameters atol = 1e-12 rtol = 1e-12
    @test routed.loglik ≈ existing.loglik atol = 1e-12 rtol = 1e-12

    # Adding an explicit independent source selects the one joint marginal,
    # rather than a sum of separately fitted phylogenetic/group objectives.
    direct_joint = GLLVModels.fit_joint_phylo_grouped_gaussian(fixture.Y, fixture.phy;
        rank = 1, phylo_mode = :barelowrank, species_id = fixture.species_id,
        terms = fixture.terms, unit = fixture.unit, iterations = 0, g_tol = 1e-4)
    joint = fit_gllvm(fixture.Y; common..., grouping = fixture.terms,
        unit = fixture.unit)
    @test joint isa GLLVModels.JointPhyloGroupedGaussianFit
    @test joint.parameters ≈ direct_joint.parameters atol = 1e-12 rtol = 1e-12
    @test joint.loglik ≈ direct_joint.loglik atol = 1e-12 rtol = 1e-12
    objective = GLLVModels._joint_phylo_grouped_nll(joint.response, joint.phy,
        joint.terms, joint.incidences; rank = joint.rank,
        phylo_mode = joint.phylo_mode, species_id = joint.species_id,
        mean_design = joint.mean_design)
    @test -objective(joint.parameters) ≈ joint.loglik atol = 1e-10 rtol = 1e-10

    # The formula front end owns the complete trait-major mean design and
    # resolves the species map symbol against its site data.
    data = (unit = fixture.unit, tip = fixture.species_id, x = fixture.x)
    formula_fit = gllvm(@formula(y ~ 1 + x), fixture.Y, data;
        phylo = fixture.phy, phylo_rank = 1, phylo_mode = :barelowrank,
        species_id = :tip, grouping = fixture.terms, unit = :unit,
        iterations = 0, g_tol = 1e-4)
    @test formula_fit isa GLLVModels.JointPhyloGroupedGaussianFit
    @test formula_fit.species_id == fixture.species_id
    @test formula_fit.mean_design == _destination_b_precision_formula_design(fixture.x)
    @test formula_fit.coefficient_names == Union{String,Symbol}["trait_1", "trait_2", "x"]

    # The same complete formula design is retained on the phylo-only route.
    formula_phylo = gllvm(@formula(y ~ 1 + x), fixture.Y, data;
        phylo = fixture.phy, phylo_rank = 1, phylo_mode = :barelowrank,
        species_id = :tip, iterations = 0, g_tol = 1e-4)
    @test formula_phylo isa GLLVModels.PrecisionMultivariateFit
    @test formula_phylo.species_id == fixture.species_id
    @test formula_phylo.mean_design == _destination_b_precision_formula_design(fixture.x)

    # Labels alone remain incidence metadata, never an implicit ordinary term.
    @test_throws ArgumentError fit_gllvm(fixture.Y; common..., unit = fixture.unit)

    # Precision controls have no effect without an admitted PrecisionPhy payload.
    @test_throws ArgumentError fit_gllvm(fixture.Y; phylo_rank = 1)
    @test_throws ArgumentError fit_gllvm(fixture.Y; phylo_mode = :barelowrank)
    @test_throws ArgumentError fit_gllvm(fixture.Y; species_id = fixture.species_id)

    # Payload and its controls are checked before a marginal objective runs.
    @test_throws ArgumentError fit_gllvm(fixture.Y; phylo = "not a PrecisionPhy")
    @test_throws ArgumentError fit_gllvm(fixture.Y;
        merge(common, (; phylo_rank = 1.0))...)
    @test_throws ArgumentError fit_gllvm(fixture.Y;
        merge(common, (; phylo_mode = "barelowrank"))...)
    @test_throws ArgumentError fit_gllvm(fixture.Y;
        merge(common, (; species_id = Float64.(fixture.species_id)))...)
    @test_throws ArgumentError fit_gllvm(fixture.Y;
        merge(common, (; species_id = fixture.species_id[1:end-1]))...)

    # This public route is Gaussian-only and excludes the legacy alternatives.
    @test_throws ArgumentError fit_gllvm(fixture.Y; common..., family = GLLVModels.Poisson())
    @test_throws ArgumentError fit_gllvm(fixture.Y; common..., K = 1)
    @test_throws ArgumentError fit_gllvm(fixture.Y; common..., num_lv = 1)
    @test_throws ArgumentError fit_gllvm(fixture.Y; common..., row_eff = :fixed)
    @test_throws ArgumentError fit_gllvm(fixture.Y; common..., pervar = true)
    @test_throws ArgumentError fit_gllvm(fixture.Y; common..., disp_group = :species)
end
