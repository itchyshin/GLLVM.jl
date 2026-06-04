using GLLVM, Test, Random, Distributions, Statistics

# Deterministic small Poisson GLLVM (p=4, K=1, n=120).
function _sim_poisson_ct(p, K, n; seed = 7)
    Random.seed!(seed)
    β = 0.5 .* randn(p) .+ 1.0
    Λ = 0.5 .* randn(p, K)
    Y = Matrix{Int}(undef, p, n)
    for s in 1:n
        η = β .+ Λ * randn(K)
        for t in 1:p
            Y[t, s] = rand(Poisson(exp(η[t])))
        end
    end
    return Y
end

@testset "Summary / coefficient table" begin
    Y = _sim_poisson_ct(4, 1, 120; seed = 7)
    fit = fit_poisson_gllvm(Y; K = 1)
    ct = coef_table(fit, Y)

    @test ct isa GllvmCoefTable
    @test length(ct.term) == length(ct.estimate) == length(ct.pvalue)
    @test length(ct.term) == length(ct.std_error) == length(ct.z) ==
          length(ct.lower) == length(ct.upper)

    # Estimates exactly match the Wald confint estimates.
    ci = confint(fit, Y; method = :wald)
    @test ct.estimate == ci.estimate            # atol 0 (same source)

    # Finite-SE terms: bracketed bounds, valid p-values, z = estimate / se.
    fin = isfinite.(ct.std_error)
    @test any(fin)
    @test all(ct.lower[fin] .< ct.estimate[fin] .< ct.upper[fin])
    @test all(0 .<= ct.pvalue[fin] .<= 1)
    @test all(ct.z[fin] .≈ ct.estimate[fin] ./ ct.std_error[fin])

    # Non-finite SE ⇒ NaN z and p.
    @test all(isnan, ct.z[.!fin])
    @test all(isnan, ct.pvalue[.!fin])

    # parm passes through to confint.
    ct_b = coef_table(fit, Y; parm = "beta")
    @test length(ct_b.term) == 4
    @test all(startswith.(ct_b.term, "beta["))

    # show runs without error and prints the term names.
    str = sprint(show, MIME("text/plain"), ct)
    @test occursin("estimate", str)
    @test occursin(ct.term[1], str)
end
