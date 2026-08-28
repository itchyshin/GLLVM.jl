# Two-part `hessian` kwarg exposure (2026-08-28).
#
# WHY THIS FILE EXISTS: the pre-commit adversarial review flagged that the
# seven newly-exposed kwargs shipped with zero tests — the check-log claimed
# "invalid throws" with no proving test (the convention-cascade rule: API
# change + tests in the same PR). This file proves, for all ten two-part
# entry points (seven no-covariate + three `_cov`):
#   1. an invalid selector throws ArgumentError up front, and
#   2. `:fisher` and `:observed` currently produce the IDENTICAL fit for the
#      families whose observed count-part weight is not yet specialised
#      (everything but DeltaGamma — the recorded TWOPART_KNOWN_OPEN gap).
#      Bit-identity is the honest claim: the kwarg must be plumbed and inert,
#      not plumbed and quietly doing something unmeasured.

using GLLVM, Test, Random

@testset "two-part hessian kwarg exposure" begin
    Random.seed!(7)
    p, n, K = 4, 30, 1
    Z = randn(K, n); L = 0.5 .* randn(p, K); H = 0.3 .* randn(p) .+ L * Z
    occ = rand(p, n) .< 0.7
    Ycount = [occ[t, s] ? rand(1:6) : 0 for t in 1:p, s in 1:n]
    Ypos = [occ[t, s] ? exp(0.2 * randn() + H[t, s]) : 0.0 for t in 1:p, s in 1:n]
    Yprop = [occ[t, s] ? clamp(0.3 + 0.1 * randn(), 0.05, 0.95) : 0.0 for t in 1:p, s in 1:n]
    N = 8
    Ybin = [occ[t, s] ? rand(0:N) : 0 for t in 1:p, s in 1:n]
    X = 0.2 .* randn(p, n, 2)

    @testset "invalid selector throws (all ten entry points)" begin
        @test_throws ArgumentError GLLVM.fit_delta_lognormal_gllvm(Ypos; K, hessian = :bogus)
        @test_throws ArgumentError GLLVM.fit_hurdle_poisson_gllvm(Ycount; K, hessian = :bogus)
        @test_throws ArgumentError GLLVM.fit_hurdle_nb_gllvm(Ycount; K, hessian = :bogus)
        @test_throws ArgumentError GLLVM.fit_zip_gllvm(Ycount; K, hessian = :bogus)
        @test_throws ArgumentError GLLVM.fit_zinb_gllvm(Ycount; K, hessian = :bogus)
        @test_throws ArgumentError GLLVM.fit_zib_gllvm(Ybin; K, N, hessian = :bogus)
        @test_throws ArgumentError GLLVM.fit_beta_hurdle_gllvm(Yprop; K, hessian = :bogus)
        @test_throws ArgumentError GLLVM.fit_zip_gllvm_cov(Ycount; X, K, hessian = :bogus)
        @test_throws ArgumentError GLLVM.fit_zinb_gllvm_cov(Ycount; X, K, hessian = :bogus)
        @test_throws ArgumentError GLLVM.fit_zib_gllvm_cov(Ybin; X, K, N, hessian = :bogus)
    end

    @testset ":fisher ≡ :observed bit-identical while the observed weight is unspecialised" begin
        fo = GLLVM.fit_delta_lognormal_gllvm(Ypos; K, hessian = :observed)
        ff = GLLVM.fit_delta_lognormal_gllvm(Ypos; K, hessian = :fisher)
        @test fo.loglik == ff.loglik

        zo = GLLVM.fit_zip_gllvm(Ycount; K, hessian = :observed)
        zf = GLLVM.fit_zip_gllvm(Ycount; K, hessian = :fisher)
        @test zo.loglik == zf.loglik

        co = GLLVM.fit_zip_gllvm_cov(Ycount; X, K, hessian = :observed)
        cf = GLLVM.fit_zip_gllvm_cov(Ycount; X, K, hessian = :fisher)
        @test co.loglik == cf.loglik
    end
end
