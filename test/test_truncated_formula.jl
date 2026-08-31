module Core070TruncatedFormulaTests
using GLLVM, Test, Random, Distributions
# Exact seed-58 DGP from parity/test_truncated_nbinom2_parity.jl; no RCall dependency.
const _TNB2_SEED = 58
function parity_loadings_p5k2()
    return [
        0.8   0.0
        0.5   0.6
        0.3  -0.4
       -0.2   0.5
        0.1   0.3
    ]
end
Random.seed!(_TNB2_SEED)
p, K, n = 5, 1, 120
# Intercepts chosen so μ ≳ 3: keeps p₀ small (cheap rejection sampling), the
# truncation correction well conditioned, and the Laplace modes stable.
β = log.([4.0, 5.0, 3.5, 4.5, 4.0])
r_true = 4.0
Λ = 0.2 .* parity_loadings_p5k2()[:, 1:K]
Z = randn(K, n)
η = β .+ Λ * Z
Y = Matrix{Int}(undef, p, n)
for t in 1:p, s in 1:n
    μ = exp(clamp(η[t, s], -3.0, 3.5))
    while true                      # zero-truncated draw by rejection
        v = rand(Distributions.NegativeBinomial(r_true, r_true / (r_true + μ)))
        if v >= 1
            Y[t, s] = v
            break
        end
    end
end

parameters(f)=vcat(f.β,GLLVM.pack_lambda(f.Λ),log.(f.r))
@testset "Truncated NB2 explicit per-trait dispatch and formulas" begin
    native=fit_truncated_nbinom2_gllvm_pertrait(Y;K=K)
    unified=fit_gllvm(Y;family=TruncatedNegBin2(),K=K,disp_group=:species)
    wide=gllvm(@formula(y ~ 1),Y,(site=collect(1:n),);family=TruncatedNegBin2(),K=K,disp_group=:species)
    long=(y=reverse(vec(Y)),species=reverse(repeat(collect(1:p),n)),site=reverse(repeat(collect(1:n);inner=p)))
    longfit=gllvm(@formula(y ~ 1),long;family=TruncatedNegBin2(),K=K,disp_group=:species)
    relabelled=fit_gllvm(Y;family=TruncatedNegBin2(),K=K,disp_group=reverse(collect(11:15)))
    @test native.converged
    for fit in (unified,wide,longfit,relabelled)
        @test fit isa TruncatedNegBin2PerTraitFit
        @test fit.converged
        @test length(fit.r)==p
        @test parameters(fit)≈parameters(native) rtol=0 atol=1e-10
        @test fit.loglik≈native.loglik rtol=0 atol=1e-10
    end
    for groups in ([1,1,2,2,3],[1,2,3,4],[0,2,3,4,5])
        @test_throws ArgumentError fit_gllvm(Y;family=TruncatedNegBin2(),K=K,disp_group=groups)
    end
    @test_throws DimensionMismatch gllvm(@formula(y ~ 1),Y,(site=1:n-1,);family=TruncatedNegBin2(),K=K,disp_group=:species)
    @test_throws ArgumentError gllvm(@formula(y ~ 1),map(x->x[2:end],long);family=TruncatedNegBin2(),K=K,disp_group=:species)
    @test_throws ArgumentError gllvm(@formula(y ~ 1),map(x->vcat(x,x[1]),long);family=TruncatedNegBin2(),K=K,disp_group=:species)
    shared=fit_gllvm(Y;family=TruncatedNegBin2(),K=K,iterations=2)
    @test shared isa TruncatedNegBin2Fit
    @test shared.r isa Real
end
end
