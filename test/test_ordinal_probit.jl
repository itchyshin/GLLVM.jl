# Cumulative-link selection for the ordinal family: logit (default) + probit.
# 1) Regression: no link kwarg ≡ explicit LogitLink() (atol 0).
# 2) Probit Λ=0 exact anchor: marginal == closed-form Σ log(Φ(τ_c)−Φ(τ_{c−1}))
#    (weight-independent ⇒ validates the probit density wiring; atol 1e-8).
# 3) Probit smoke fit: runs, finite loglik, ordered τ̂, returns the probit link.

using GLLVM, Test, Random, Distributions, Statistics

@testset "Ordinal cumulative-link selection (logit default + probit)" begin
    rng = Random.MersenneTwister(20260606)
    p, K, n, C = 4, 1, 60, 4
    Λtrue = 0.6 .* randn(rng, p, K)
    τtrue = [-1.0, 0.0, 1.2]                       # C-1 = 3 ordered cutpoints
    # Simulate logit-cumulative ordinal data (categories 1:C).
    Y = Matrix{Int}(undef, p, n)
    for s in 1:n
        η = Λtrue * randn(rng, K)
        for t in 1:p
            u = rand(rng); cum = 0.0; cat = C
            for c in 1:C
                Fhi = c == C ? 1.0 : inv(1 + exp(-(τtrue[c] - η[t])))
                Flo = c == 1 ? 0.0 : inv(1 + exp(-(τtrue[c - 1] - η[t])))
                cum += Fhi - Flo
                if u <= cum
                    cat = c; break
                end
            end
            Y[t, s] = cat
        end
    end
    @test all(1 .<= Y .<= C)

    Λ = 0.4 .* randn(rng, p, K)

    @testset "regression: default link ≡ explicit LogitLink()" begin
        ll_default = GLLVM.ordinal_marginal_loglik_laplace(Y, Λ, τtrue)
        ll_logit   = GLLVM.ordinal_marginal_loglik_laplace(Y, Λ, τtrue;
                                                           link = GLLVM.LogitLink())
        @test ll_default == ll_logit                # byte-for-byte identical
        @test isfinite(ll_default)
    end

    @testset "probit Λ=0 exact anchor" begin
        Λ0 = zeros(p, K)                            # η ≡ 0 for all sites
        # Closed-form independent probit-cumulative loglik at η=0.
        Φ(x) = cdf(Normal(), x)
        ll_closed = 0.0
        for s in 1:n, t in 1:p
            c = Y[t, s]
            Fhi = c == C ? 1.0 : Φ(τtrue[c])
            Flo = c == 1 ? 0.0 : Φ(τtrue[c - 1])
            ll_closed += log(Fhi - Flo)
        end
        ll_probit = GLLVM.ordinal_marginal_loglik_laplace(Y, Λ0, τtrue;
                                                          link = GLLVM.ProbitLink())
        @test isapprox(ll_probit, ll_closed; atol = 1e-8)
        # Sanity: at Λ=0 probit differs from logit (distinct CDFs).
        ll_logit0 = GLLVM.ordinal_marginal_loglik_laplace(Y, Λ0, τtrue;
                                                          link = GLLVM.LogitLink())
        @test ll_probit != ll_logit0
    end

    @testset "probit smoke fit" begin
        fit = GLLVM.fit_ordinal_gllvm(Y; K = K, link = GLLVM.ProbitLink(),
                                      iterations = 40)
        @test isfinite(fit.loglik)
        @test fit.link isa GLLVM.ProbitLink
        @test issorted(fit.τ)                       # ordered cutpoints
        @test length(fit.τ) == C - 1
        @test size(fit.Λ) == (p, K)
    end
end
