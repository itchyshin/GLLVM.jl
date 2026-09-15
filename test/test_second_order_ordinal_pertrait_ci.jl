# OrdinalPerTraitFit / OrdinalPerTraitCovFit Wald wiring (second-order holdout).
# Bridge ci_method guards stay until a separate bridge lift (#357 foreign).

using Test
using Random
using GLLVM

@testset "OrdinalPerTraitFit second-order Wald CI" begin
    Random.seed!(81)
    p, K, n, C = 4, 1, 180, 4
    β = 0.2 .* randn(p)
    Λ = 0.55 .* ones(p, K)
    # Twin packing: τ₁ = 0; free natural cutpoints for c = 2:(C−1)
    τ_row = [0.0, 0.8, 1.7]
    Y = Matrix{Int}(undef, p, n)
    for s in 1:n
        η = β .+ Λ * randn(K)
        for t in 1:p
            u = rand(); cum = 0.0; cat = C
            for c in 1:C
                Fhi = c == C ? 1.0 : inv(1 + exp(-(τ_row[c] - η[t])))
                Flo = c == 1 ? 0.0 : inv(1 + exp(-(τ_row[c - 1] - η[t])))
                cum += Fhi - Flo
                if u <= cum
                    cat = c; break
                end
            end
            Y[t, s] = cat
        end
    end
    fit = fit_ordinal_gllvm_pertrait(Y; K = K)
    @test fit isa OrdinalPerTraitFit
    @test fit.converged
    @test all(fit.C .== C)

    ci = confint(fit, Y; method = :wald)
    @test ci.method === :wald
    n_free_tau = p * (C - 2)
    @test length(ci.term) == p + GLLVM.rr_theta_len(p, K) + n_free_tau
    @test "beta[1]" in ci.term
    @test "Lambda[1,1]" in ci.term
    @test "tau[1,2]" in ci.term
    @test !("tau[1,1]" in ci.term)   # τ₁ fixed at 0 — not a free Hessian term

    b1 = findfirst(==("beta[1]"), ci.term)
    @test b1 !== nothing
    @test ci.estimate[b1] ≈ fit.β[1] atol = 1e-8
    @test isfinite(ci.se[b1])

    t12 = findfirst(==("tau[1,2]"), ci.term)
    @test t12 !== nothing
    @test ci.estimate[t12] ≈ fit.τ[1, 2] atol = 1e-8
    @test isfinite(ci.se[t12])

    w = confint(fit, Y; method = :wald, parm = "beta[1]")
    @test w.term == ["beta[1]"]
    @test isfinite(w.se[1])
end

@testset "OrdinalPerTraitCovFit second-order Wald CI" begin
    Random.seed!(82)
    p, K, n, q, C = 3, 1, 160, 1, 3
    β = 0.15 .* randn(p)
    γ = [0.35]
    Λ = 0.5 .* ones(p, K)
    τ_row = [0.0, 1.1]   # C=3 → one free cutpoint per trait
    X = randn(p, n, q)
    Y = Matrix{Int}(undef, p, n)
    for s in 1:n
        z = randn(K)
        for t in 1:p
            η = β[t] + X[t, s, 1] * γ[1] + Λ[t, 1] * z[1]
            u = rand(); cum = 0.0; cat = C
            for c in 1:C
                Fhi = c == C ? 1.0 : inv(1 + exp(-(τ_row[c] - η)))
                Flo = c == 1 ? 0.0 : inv(1 + exp(-(τ_row[c - 1] - η)))
                cum += Fhi - Flo
                if u <= cum
                    cat = c; break
                end
            end
            Y[t, s] = cat
        end
    end
    fit = fit_ordinal_gllvm_pertrait_cov(Y; X = X, K = K)
    @test fit isa OrdinalPerTraitCovFit
    @test fit.converged

    @test_throws ArgumentError confint(fit, Y; method = :wald)

    ci = confint(fit, Y; method = :wald, X = X)
    @test ci.method === :wald
    @test "gamma[1]" in ci.term
    @test "tau[1,2]" in ci.term
    g1 = findfirst(==("gamma[1]"), ci.term)
    @test g1 !== nothing
    @test ci.estimate[g1] ≈ fit.γ[1] atol = 1e-8
    @test isfinite(ci.se[g1])
end
