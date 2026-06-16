using Test
using GLLVM

@testset "Ordinal per-trait cutpoints" begin
    Y = [
        1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1
        1 2 3 4 1 2 3 4 1 2 3 4 1 2 3 4
        1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2
    ]
    K = 1
    C = [3, 4, 2]
    fit = fit_ordinal_gllvm_pertrait(Y; K = K, iterations = 120)

    @test fit isa OrdinalPerTraitFit
    @test fit.C == C
    @test size(fit.τ) == (3, 3)
    @test all(isfinite, fit.τ[1, 1:2])
    @test isnan(fit.τ[1, 3])
    @test all(isfinite, fit.τ[2, 1:3])
    @test isfinite(fit.τ[3, 1])
    @test all(isnan, fit.τ[3, 2:3])
    @test issorted(fit.τ[1, 1:2])
    @test issorted(fit.τ[2, 1:3])
    @test GLLVM._nparams(fit) == GLLVM.rr_theta_len(size(Y, 1), K) + sum(C .- 1)
    @test isfinite(fit.loglik)

    P = predict(fit, Y; type = :prob)
    @test size(P) == (3, size(Y, 2), 4)
    for t in axes(Y, 1), s in axes(Y, 2)
        @test isapprox(sum(P[t, s, 1:C[t]]), 1.0; atol = 1e-10, rtol = 0)
        C[t] < size(P, 3) && @test all(==(0.0), P[t, s, (C[t] + 1):end])
    end
    cls = predict(fit, Y; type = :class)
    @test size(cls) == size(Y)
    @test all((cls .>= 1) .& (cls .<= maximum(C)))

    # Shared-cutpoint likelihood is preserved as a special case of the per-trait
    # likelihood when every trait has the same C and row-identical cutpoints.
    Ys = [
        1 2 3 1 2 3 1 2 3
        2 3 1 2 3 1 2 3 1
        3 1 2 3 1 2 3 1 2
    ]
    Λ = reshape([0.35, -0.15, 0.2], :, 1)
    τ = [-0.8, 0.7]
    τmat = repeat(reshape(τ, 1, :), size(Ys, 1), 1)
    Cs = fill(3, size(Ys, 1))
    @test isapprox(
        GLLVM.ordinal_marginal_loglik_laplace(Ys, Λ, τ),
        GLLVM.ordinal_marginal_loglik_laplace_pertrait(Ys, Λ, τmat, Cs);
        atol = 1e-10,
        rtol = 0,
    )
end

@testset "bridge ordinal payload uses per-trait cutpoints" begin
    Y = Float64.([
        1 2 3 1 2 3 1 2 3 1 2 3
        1 2 3 4 1 2 3 4 1 2 3 4
        1 2 1 2 1 2 1 2 1 2 1 2
    ])
    K = 1
    br = bridge_fit(; y = Y, family = "ordinal_probit", d = K,
                    trait_names = ["a", "b", "c"])

    @test br.family == "ordinal_probit"
    @test br.model == "ordinal_probit_rr"
    @test br.cutpoint_mode == "per_trait"
    @test br.cutpoint_link == "ProbitLink"
    @test br.trait_names == ["a", "b", "c"]
    @test br.n_categories == [3, 4, 2]
    @test size(br.cutpoints) == (3, 3)
    @test all(isfinite, br.cutpoints[1, 1:2])
    @test isnan(br.cutpoints[1, 3])
    @test all(isfinite, br.cutpoints[2, 1:3])
    @test isfinite(br.cutpoints[3, 1])
    @test all(isnan, br.cutpoints[3, 2:3])
    @test br.df == GLLVM.rr_theta_len(size(Y, 1), K) + sum(br.n_categories .- 1)
    @test !(:ci_method in keys(br))
    @test_throws ArgumentError bridge_fit(; y = Y, family = "ordinal_probit", d = K,
                                          options = Dict("ci_method" => "wald"))
end
