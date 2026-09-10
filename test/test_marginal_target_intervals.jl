using GLLVM, Test, LinearAlgebra

@testset "Destination B marginal target intervals" begin
    H = [4.0 1.5; 1.5 2.0]
    center = [0.3, -0.4]
    f = x -> dot(x-center, H*(x-center))/2
    targets = [(name="beta", value=x->x[1], transform=:identity),
               (name="variance", value=x->exp(2x[2]), transform=:log)]
    result = GLLVM._marginal_target_intervals(f, center, targets; converged=true)
    @test result.status == :available
    redundant = GLLVM._marginal_target_intervals(f, center, targets;
        converged=true, structural_redundancy=true)
    @test redundant.status == :nonidentifiable
    @test all(t -> t.method == :unavailable, redundant.intervals)
    @test result.covariance ≈ inv(H) atol=1e-6
    shifted=GLLVM._marginal_target_intervals(x->f(x)+100,center,targets;converged=true)
    @test shifted.covariance ≈ result.covariance atol=1e-5
    @test !isapprox(result.covariance[1,1], 1/H[1,1]; atol=.01)
    @test result.intervals[1].se_transformed ≈ sqrt(inv(H)[1,1]) atol=1e-6
    @test result.intervals[2].se_transformed ≈ 2sqrt(inv(H)[2,2]) atol=1e-6
    @test 0 < result.intervals[2].lower < exp(2center[2]) < result.intervals[2].upper
    @test GLLVM._marginal_target_intervals(f, center, targets; converged=false).status == :not_converged
    @test GLLVM._marginal_target_intervals(x->GLLVM._NLL_SENTINEL,center,targets;converged=true).status == :invalid_objective
    @test GLLVM._marginal_target_intervals(f, center .+ .1, targets; converged=true).status == :not_stationary
    @test GLLVM._marginal_target_intervals(x->x[1]^2, zeros(2), targets; converged=true).status == :invalid_curvature
    @test GLLVM._marginal_target_intervals(x->-sum(abs2,x), zeros(2), targets; converged=true).status == :invalid_curvature
    boundary = [(name="zero_variance", value=x->zero(x[1]), transform=:log)]
    b = GLLVM._marginal_target_intervals(f, center, boundary; converged=true)
    @test b.intervals[1].status == :target_unavailable
    @test isnan(b.intervals[1].lower)
    @test_throws ArgumentError GLLVM._marginal_target_intervals(f,center,targets;converged=true,level=1.1)
end

@testset "Marginal interval helper on an exact Gaussian MLE" begin
    y=[-1.2,-.7,-.3,.2,.4,.6,1.1,1.8]
    mu=sum(y)/length(y)
    variance=sum(abs2,y .-mu)/length(y)
    theta=[mu,log(sqrt(variance))]
    objective=x->length(y)*(log(2pi)/2+x[2])+sum(abs2,y .-x[1])/(2exp(2x[2]))
    targets=[(name="mean",value=x->x[1],transform=:identity),
             (name="variance",value=x->exp(2x[2]),transform=:log)]
    ci=GLLVM._marginal_target_intervals(objective,theta,targets;converged=true)
    @test ci.status==:available
    @test ci.covariance ≈ Diagonal([variance/length(y),1/(2length(y))]) atol=1e-6
    @test ci.intervals[1].se_transformed ≈ sqrt(variance/length(y)) atol=1e-6
    @test ci.intervals[2].se_transformed ≈ sqrt(2/length(y)) atol=1e-6
end
