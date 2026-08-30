using GLLVM, Test

@testset "CORE-070 Student-t model identity" begin
    p, K = 3, 1
    β = zeros(p)
    Λ = zeros(p, K)
    link = IdentityLink()

    # Existing positional constructors mean fixed ν.  A vector alone cannot
    # encode whether it was supplied by the caller or estimated by the fitter.
    fixed_shared = StudentTFit(β, Λ, 4.0, 0.7, link, -1.0, true, 1)
    fixed_species = StudentTFit(β, Λ, [3.0, 4.0, 5.0], fill(0.7, p),
                                 link, -1.0, true, 1, :observed, :species)
    @test !fixed_shared.estimated_nu
    @test !fixed_species.estimated_nu
    @test GLLVM._nparams(fixed_shared) == 7
    @test GLLVM._nparams(fixed_species) == 9

    # The fitted identity must retain the estimation policy independently of
    # scalar-versus-vector parameter shape so AIC/BIC count ν coordinates.
    estimated_shared = StudentTFit(β, Λ, 4.0, 0.7, link, -1.0, true, 1,
                                   :observed, :shared, true)
    estimated_species = StudentTFit(β, Λ, [3.0, 4.0, 5.0], fill(0.7, p),
                                    link, -1.0, true, 1, :observed, :species, true)
    @test estimated_shared.estimated_nu
    @test estimated_species.estimated_nu
    @test GLLVM._nparams(estimated_shared) == 8
    @test GLLVM._nparams(estimated_species) == 12
end
