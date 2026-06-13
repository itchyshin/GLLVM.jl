using GLLVM, Test, LinearAlgebra

# Cross-lineage coevolution estimand Γ = Λ_phy Λ_phy' (phase C2), Julia mirror
# of gllvmTMB::extract_Gamma. In GLLVM.jl the phylo loadings Λ_phy (p × K_phy)
# sit on the stacked two-lineage entity index p; the host block is rows 1:n_H
# and the partner block rows n_H+1:p (the make_cross_kernel ordering). Trait
# indexing is POSITIONAL (integer rows), unlike the name-based R API.
@testset "extract_Gamma (coevolution estimand)" begin
    n_H, n_P = 3, 2
    p = n_H + n_P
    Λ_phy = [1.00 0.00
             0.45 0.85
             0.10 0.30
             0.75 0.25
             -0.25 0.90]            # p × K_phy

    # Minimal synthetic GllvmFit carrying a known Λ_phy (mirrors R's fake-fit).
    function fake_fit(Lphy)
        K_phy = Lphy === nothing ? 0 : size(Lphy, 2)
        model = GllvmModel(p, 1, 0, false, K_phy, false)
        pars = (σ_eps = 1.0, Λ = zeros(p, 1), β = nothing, Λ_W = nothing,
                σ²_B = nothing, σ²_W = nothing, Λ_phy = Lphy, σ_phy = nothing,
                θ_packed = Float64[])
        GllvmFit(model, pars, -1.0, 1, true, nothing, 0.0)
    end

    @testset "slices the host × partner block of Λ_phy Λ_phy'" begin
        Γ = extract_Gamma(fake_fit(Λ_phy); row_traits = 1:n_H, col_traits = (n_H + 1):p)
        @test size(Γ) == (n_H, n_P)
        @test Γ ≈ (Λ_phy * Λ_phy')[1:n_H, (n_H + 1):p]
    end

    @testset "rotation-invariant: Λ_phy·Q gives the same Γ" begin
        Q = [0.0 -1.0; 1.0 0.0]      # orthogonal rotation of the two axes
        Γ = extract_Gamma(fake_fit(Λ_phy); row_traits = 1:n_H, col_traits = (n_H + 1):p)
        Γr = extract_Gamma(fake_fit(Λ_phy * Q); row_traits = 1:n_H, col_traits = (n_H + 1):p)
        @test Γr ≈ Γ atol = 1e-12
    end

    @testset "validation errors" begin
        # no phylo loadings
        @test_throws ArgumentError extract_Gamma(fake_fit(nothing);
                                                 row_traits = 1:n_H, col_traits = (n_H + 1):p)
        # out-of-range column indices
        @test_throws ArgumentError extract_Gamma(fake_fit(Λ_phy);
                                                 row_traits = 1:n_H, col_traits = (n_H + 1):(p + 3))
        # out-of-range row indices (0)
        @test_throws ArgumentError extract_Gamma(fake_fit(Λ_phy);
                                                 row_traits = 0:n_H, col_traits = (n_H + 1):p)
    end
end
