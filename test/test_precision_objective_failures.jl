using GLLVM, Test

@testset "precision multivariate objective failure handling" begin
    # This lies above the shared finite-difference failure threshold but below
    # the former private 1e12 cap. It must poison every precision stencil in
    # exactly the same way as the marginal interval helper.
    shared_failure = GLLVM._NLL_FAIL_THRESHOLD + 1.0
    failed_arm = x -> x[1] > 0 ? shared_failure : x[1]^2

    @test !GLLVM._pmv_valid_objective(shared_failure)
    storage = zeros(1)
    gradient = GLLVM._pmv_fd_gradient!(storage, failed_arm, [0.0])
    @test isnan(gradient[1])
    @test !all(isfinite, GLLVM._fd_hessian(failed_arm, [0.0]))

    targets = [(name = "theta", value = theta -> theta[1], transform = :identity)]
    marginal = GLLVM._marginal_target_intervals(failed_arm, [0.0], targets;
        converged = true)
    @test marginal.status === :invalid_objective

    # Interrupts are control flow, not numerical failure. Diagnostic recovery
    # may convert numerical exceptions to unavailable curvature, but cannot
    # swallow an explicit user interrupt.
    @test_throws InterruptException GLLVM._pmv_hessian_diagnostics(
        theta -> throw(InterruptException()), [0.0])
end
