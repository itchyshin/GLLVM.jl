using GLLVM, Test, Random, Distributions, Statistics

# Build a (p,n,q) design carrying `q` shared site covariates broadcast across
# species: X[t,s,k] = x[k][s]. Each species t will later get its own slope row.
function _site_design_q(xs::AbstractVector{<:AbstractVector}, p::Integer)
    q = length(xs)
    n = length(xs[1])
    X = zeros(p, n, q)
    @inbounds for k in 1:q, t in 1:p, s in 1:n
        X[t, s, k] = xs[k][s]
    end
    return X
end

@testset "Species-specific covariates (XB)" begin
    @testset "offset marginal Λ=0 reduces to independent GLM loglik (exact)" begin
        Random.seed!(280)
        p, K, n, q = 5, 2, 40, 2
        β = 0.3 .* randn(p)
        B = 0.5 .* randn(p, q)                       # species-specific slopes
        x1 = randn(n); x2 = randn(n)
        X = _site_design_q([x1, x2], p)
        O = GLLVM._build_offset_species(X, B)
        # hand-computed offset entry: O[3,4] = B[3,1]*x1[4] + B[3,2]*x2[4]
        @test O[3, 4] ≈ B[3, 1] * x1[4] + B[3, 2] * x2[4] atol = 1e-12
        Y = [rand(Poisson(exp(β[t] + O[t, s]))) for t in 1:p, s in 1:n]

        ll = GLLVM._marginal_loglik_offset(Poisson(), Y, ones(Int, p, n),
                                           zeros(p, K), β, O, LogLink())
        ref = 0.0
        for t in 1:p, s in 1:n
            ref += logpdf(Poisson(exp(β[t] + O[t, s])), Y[t, s])
        end
        @test ll ≈ ref atol = 1e-8
    end

    @testset "fit_gllvm_speciescov (Poisson) machinery" begin
        Random.seed!(281)
        p, K, n, q = 6, 2, 200, 2
        β_true = 0.3 .* randn(p)
        B_true = 0.4 .* randn(p, q)
        Λ_true = 0.4 .* randn(p, K)
        x1 = randn(n); x2 = randn(n)
        X = _site_design_q([x1, x2], p)
        Z = randn(K, n)
        O = GLLVM._build_offset_species(X, B_true)
        η = β_true .+ O .+ Λ_true * Z
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]

        fit = fit_gllvm_speciescov(Y; family = Poisson(), X = X, K = K)
        @test fit isa GllvmSpeciesCovFit
        @test isfinite(fit.loglik)
        @test size(fit.B) == (p, q)
        @test size(fit.Λ) == (p, K)
        @test all(isfinite, fit.B)
    end

    @testset "post-fit: getLV/predict" begin
        Random.seed!(282)
        p, K, n, q = 5, 2, 25, 2
        β_true = 0.3 .* randn(p)
        B_true = 0.4 .* randn(p, q)
        x1 = randn(n); x2 = randn(n)
        X = _site_design_q([x1, x2], p)
        Z = randn(K, n)
        O = GLLVM._build_offset_species(X, B_true)
        η = β_true .+ O .+ 0.4 .* randn(p, K) * Z
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]

        fit = fit_gllvm_speciescov(Y; family = Poisson(), X = X, K = K)
        LV = getLV(fit, Y, X)
        @test size(LV) == (n, K)
        @test all(isfinite, LV)
        ηhat = predict(fit, Y, X; type = :link)
        @test size(ηhat) == (p, n)
        μhat = predict(fit, Y, X; type = :response)
        @test size(μhat) == (p, n)
        @test all(isfinite, μhat)
    end
end
