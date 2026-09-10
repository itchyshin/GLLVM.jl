using GLLVM, Test

# Contract tests for the future callback-only grouped variance profile route.
# They intentionally do not construct a Gaussian model or call an optimiser.
# The first red run is expected until the two helpers specified here exist:
# `_profile_lr_refit` and `_profile_invert_callback`.

const _GPI_BASELINE_NLL = 10.0
const _GPI_CUTOFF = 1.0
const _GPI_TOL_D = 1e-4

@testset "profile point retains complete constrained-refit evidence" begin
    attempt = [2.0, 3.0]
    callback = (v, stage) -> (accepted=true, objective_nll=10.5, status=:accepted,
        provenance=(stage=stage,), attempts=[(minimizer=attempt,)],
        selected_coordinate=missing, evaluator_vector=[0.0, 2.0])
    point = GLLVM._profile_lr_refit(10.0, 0.0, callback)
    @test point.refit_receipt.attempts[1].minimizer == [2.0, 3.0]
    @test ismissing(point.refit_receipt.selected_coordinate)
    attempt .= 99.0
    @test point.refit_receipt.attempts[1].minimizer == [2.0, 3.0]
end

_gpi_nll(lr) = _GPI_BASELINE_NLL + lr / 2

function _gpi_callback(f; tag = :mock)
    return function (fixed_variance, stage::Symbol)
        value = f(fixed_variance, stage)
        return merge(value, (provenance = (tag = tag, fixed_variance = fixed_variance,
                                           stage = stage),))
    end
end

function _gpi_accepted_lr(f; tag = :accepted)
    _gpi_callback((v, stage) ->
        (accepted = true, objective_nll = _gpi_nll(f(v)), status = :accepted);
        tag = tag)
end

_gpi_observed(callback, v) = GLLVM._profile_lr_refit(
    _GPI_BASELINE_NLL, v, callback; tol_D = _GPI_TOL_D, stage = :historical)

function _gpi_without_provenance(receipt)
    names = filter(name -> name !== :provenance, propertynames(receipt))
    return (; (name => getproperty(receipt, name) for name in names)...)
end

@testset "Grouped profile LR callback contract" begin
    @testset "material negative LR refuses the local baseline" begin
        callback = _gpi_accepted_lr(_ -> -2e-4; tag = :material_negative)
        point = GLLVM._profile_lr_refit(_GPI_BASELINE_NLL, 0.3, callback;
            tol_D = _GPI_TOL_D)

        @test point.status === :baseline_not_maximized
        @test point.refit_accepted
        @test point.raw_lr == 2 * (_gpi_nll(-2e-4) - _GPI_BASELINE_NLL)
        @test isnan(point.lr)
        @test point.provenance.tag === :material_negative
    end

    @testset "tiny negative LR retains raw value and records roundoff" begin
        callback = _gpi_accepted_lr(_ -> -1e-14; tag = :roundoff)
        point = GLLVM._profile_lr_refit(_GPI_BASELINE_NLL, 0.3, callback;
            tol_D = _GPI_TOL_D)

        @test point.status === :roundoff_adjusted
        @test point.refit_accepted
        @test isapprox(point.raw_lr, -1e-14; atol = 2e-15)
        @test point.lr == 0.0
        @test point.provenance.tag === :roundoff

        # A caller cannot turn a material discrepancy into roundoff by
        # supplying a permissive override: the approved per-refit bound still
        # caps it below tol_D.
        material = _gpi_accepted_lr(_ -> -2e-4; tag = :override_capped)
        capped = GLLVM._profile_lr_refit(_GPI_BASELINE_NLL, 0.3, material;
            tol_D = _GPI_TOL_D, tol_neg = 1.0)
        @test capped.status === :baseline_not_maximized
        @test isnan(capped.lr)
    end

    @testset "zero has explicit inside, equality, and outside outcomes" begin
        inside = _gpi_accepted_lr(v -> iszero(v) ? 0.7 : 0.0; tag = :zero_inside)
        result_inside = GLLVM._profile_invert_callback(_GPI_BASELINE_NLL, inside;
            side = :lower, inside_v = 1.0, outside_v = 0.0, cutoff = _GPI_CUTOFF,
            tol_D = _GPI_TOL_D, maxiter = 8)
        @test result_inside.status === :boundary_inside
        @test result_inside.endpoint == 0.0
        @test result_inside.at_boundary
        @test result_inside.points[end].provenance.tag === :zero_inside

        equality = _gpi_accepted_lr(v -> iszero(v) ? _GPI_CUTOFF : 0.0; tag = :zero_equal)
        result_equality = GLLVM._profile_invert_callback(_GPI_BASELINE_NLL, equality;
            side = :lower, inside_v = 1.0, outside_v = 0.0, cutoff = _GPI_CUTOFF,
            tol_D = _GPI_TOL_D, maxiter = 8)
        @test result_equality.status === :boundary_crossing
        @test result_equality.endpoint == 0.0
        @test result_equality.at_boundary

        outside = _gpi_accepted_lr(v -> 2.0 * (1.0 - v); tag = :zero_outside)
        result_outside = GLLVM._profile_invert_callback(_GPI_BASELINE_NLL, outside;
            side = :lower, inside_v = 1.0, outside_v = 0.0, cutoff = _GPI_CUTOFF,
            tol_D = _GPI_TOL_D, maxiter = 20)
        @test result_outside.status === :root_verified
        @test !result_outside.at_boundary
        @test isapprox(result_outside.endpoint, 0.5; atol = _GPI_TOL_D)
        @test abs(result_outside.endpoint_check.lr - _GPI_CUTOFF) <= _GPI_TOL_D
        @test result_outside.endpoint_check.provenance.stage === :endpoint_verify
    end

    @testset "finite accepted bracket and final LR verification are required" begin
        callback = _gpi_accepted_lr(v -> 4.0 * (v - 1.0); tag = :finite_root)
        result = GLLVM._profile_invert_callback(_GPI_BASELINE_NLL, callback;
            side = :upper, inside_v = 1.0, outside_v = 2.0, cutoff = _GPI_CUTOFF,
            tol_D = _GPI_TOL_D, maxiter = 24)
        @test result.status === :root_verified
        @test isapprox(result.endpoint, 1.25; atol = _GPI_TOL_D)
        @test result.bracket.inside.refit_accepted
        @test result.bracket.outside.refit_accepted
        @test abs(result.endpoint_check.lr - _GPI_CUTOFF) <= _GPI_TOL_D

        bad_outer = _gpi_callback((v, stage) -> iszero(v) ?
            (accepted = false, objective_nll = Inf, status = :all_starts_failed) :
            (accepted = true, objective_nll = _gpi_nll(0.0), status = :accepted);
            tag = :failed_outer)
        failed = GLLVM._profile_invert_callback(_GPI_BASELINE_NLL, bad_outer;
            side = :lower, inside_v = 1.0, outside_v = 0.0, cutoff = _GPI_CUTOFF,
            tol_D = _GPI_TOL_D, maxiter = 8)
        @test failed.status === :invalid_refit
        @test isnan(failed.endpoint)
        @test !failed.bracket.outside.refit_accepted
        @test failed.bracket.outside.status === :all_starts_failed

        not_inside = _gpi_accepted_lr(v -> isone(v) ? 2.0 : 3.0; tag = :not_inside)
        invalid_inside = GLLVM._profile_invert_callback(_GPI_BASELINE_NLL, not_inside;
            side = :lower, inside_v = 1.0, outside_v = 0.0, cutoff = _GPI_CUTOFF,
            tol_D = _GPI_TOL_D, maxiter = 8)
        @test invalid_inside.status === :invalid_bracket
        @test isnan(invalid_inside.endpoint)
    end

    @testset "iteration midpoint and all-start failure are not evidence" begin
        callback = _gpi_accepted_lr(v -> 2.0 * (1.0 - v); tag = :iteration_limit)
        limited = GLLVM._profile_invert_callback(_GPI_BASELINE_NLL, callback;
            side = :lower, inside_v = 1.0, outside_v = 0.0, cutoff = _GPI_CUTOFF,
            tol_D = _GPI_TOL_D, maxiter = 0)
        @test limited.status === :root_not_verified
        @test isnan(limited.endpoint)
        @test limited.endpoint_check === nothing

        final_refit_fails = _gpi_callback((v, stage) -> stage === :endpoint_verify ?
            (accepted = false, objective_nll = Inf, status = :all_starts_failed) :
            (accepted = true, objective_nll = _gpi_nll(2.0 * (1.0 - v)), status = :accepted);
            tag = :final_refit_fails)
        failed_final = GLLVM._profile_invert_callback(_GPI_BASELINE_NLL, final_refit_fails;
            side = :lower, inside_v = 1.0, outside_v = 0.0, cutoff = _GPI_CUTOFF,
            tol_D = _GPI_TOL_D, maxiter = 20)
        @test failed_final.status === :invalid_refit
        @test isnan(failed_final.endpoint)
        @test failed_final.endpoint_check.status === :all_starts_failed

        all_failed = _gpi_callback((v, stage) ->
            (accepted = false, objective_nll = NaN, status = :all_starts_failed);
            tag = :all_starts_failed)
        point = GLLVM._profile_lr_refit(_GPI_BASELINE_NLL, 0.4, all_failed;
            tol_D = _GPI_TOL_D)
        @test point.status === :all_starts_failed
        @test !point.refit_accepted
        @test isnan(point.raw_lr)
        @test point.provenance.tag === :all_starts_failed
    end

    @testset "outward observed outside-to-inside re-entry refuses both sides" begin
        callback = _gpi_accepted_lr(v -> iszero(v) || isapprox(v, 2.0) ? 2.0 :
            isapprox(v, 0.75) || isapprox(v, 1.25) ? 1.5 :
            isapprox(v, 0.50) || isapprox(v, 1.50) ? 0.5 : 0.0;
            tag = :reentry)
        lower_outward = [_gpi_observed(callback, v) for v in (1.0, 0.75, 0.50)]
        lower = GLLVM._profile_invert_callback(_GPI_BASELINE_NLL, callback;
            side = :lower, inside_v = 1.0, outside_v = 0.0, cutoff = _GPI_CUTOFF,
            tol_D = _GPI_TOL_D, maxiter = 12,
            observed = lower_outward)
        @test lower.status === :nonmonotone_profile
        @test isnan(lower.endpoint)
        @test !isempty(lower.points)

        upper_outward = [_gpi_observed(callback, v) for v in (1.0, 1.25, 1.50)]
        upper = GLLVM._profile_invert_callback(_GPI_BASELINE_NLL, callback;
            side = :upper, inside_v = 1.0, outside_v = 2.0, cutoff = _GPI_CUTOFF,
            tol_D = _GPI_TOL_D, maxiter = 12,
            observed = upper_outward)
        @test upper.status === :nonmonotone_profile
        @test isnan(upper.endpoint)
        @test !isempty(upper.points)
    end

    @testset "historical receipts are complete and cannot be filtered away" begin
        ordinary = _gpi_accepted_lr(v -> 2.0 * (1.0 - v); tag = :historical)
        complete = _gpi_observed(ordinary, 0.8)
        @test hasproperty(complete, :objective_nll)
        @test hasproperty(complete, :raw_lr)
        @test hasproperty(complete, :provenance)
        @test_throws ArgumentError GLLVM._profile_invert_callback(
            _GPI_BASELINE_NLL, ordinary;
            side = :lower, inside_v = 1.0, outside_v = 0.0, cutoff = _GPI_CUTOFF,
            tol_D = _GPI_TOL_D, maxiter = 8,
            observed = [_gpi_without_provenance(complete)])

        negative_callback = _gpi_accepted_lr(v -> isapprox(v, 0.8) ? -2e-4 :
            2.0 * (1.0 - v); tag = :historical_negative)
        negative = _gpi_observed(negative_callback, 0.8)
        @test negative.status === :baseline_not_maximized
        negative_result = GLLVM._profile_invert_callback(_GPI_BASELINE_NLL, negative_callback;
            side = :lower, inside_v = 1.0, outside_v = 0.0, cutoff = _GPI_CUTOFF,
            tol_D = _GPI_TOL_D, maxiter = 20, observed = [negative])
        @test negative_result.status === :baseline_not_maximized
        @test isnan(negative_result.endpoint)

        failed_callback = _gpi_callback((v, stage) -> isapprox(v, 0.8) ?
            (accepted = false, objective_nll = Inf, status = :all_starts_failed) :
            (accepted = true, objective_nll = _gpi_nll(2.0 * (1.0 - v)), status = :accepted);
            tag = :historical_invalid)
        invalid = _gpi_observed(failed_callback, 0.8)
        @test invalid.status === :all_starts_failed
        invalid_result = GLLVM._profile_invert_callback(_GPI_BASELINE_NLL, failed_callback;
            side = :lower, inside_v = 1.0, outside_v = 0.0, cutoff = _GPI_CUTOFF,
            tol_D = _GPI_TOL_D, maxiter = 20, observed = [invalid])
        @test invalid_result.status === :invalid_refit
        @test isnan(invalid_result.endpoint)
    end

    @testset "center_v checks the full outward trace on both sides" begin
        lower_callback = _gpi_accepted_lr(v -> isapprox(v, 0.9) ? 1.5 :
            isapprox(v, 0.8) ? 0.5 : isapprox(v, 0.7) ? 0.2 :
            iszero(v) ? 2.0 : 0.0; tag = :lower_center)
        lower_history = [_gpi_observed(lower_callback, v) for v in (1.0, 0.9, 0.8)]
        lower = GLLVM._profile_invert_callback(_GPI_BASELINE_NLL, lower_callback;
            side = :lower, center_v = 1.0, inside_v = 0.7, outside_v = 0.0,
            cutoff = _GPI_CUTOFF, tol_D = _GPI_TOL_D, maxiter = 12,
            observed = lower_history)
        @test lower.status === :nonmonotone_profile
        @test isnan(lower.endpoint)

        upper_callback = _gpi_accepted_lr(v -> isapprox(v, 1.1) ? 1.5 :
            isapprox(v, 1.2) ? 0.5 : isapprox(v, 1.3) ? 0.2 :
            isapprox(v, 2.0) ? 2.0 : 0.0; tag = :upper_center)
        upper_history = [_gpi_observed(upper_callback, v) for v in (1.0, 1.1, 1.2)]
        upper = GLLVM._profile_invert_callback(_GPI_BASELINE_NLL, upper_callback;
            side = :upper, center_v = 1.0, inside_v = 1.3, outside_v = 2.0,
            cutoff = _GPI_CUTOFF, tol_D = _GPI_TOL_D, maxiter = 12,
            observed = upper_history)
        @test upper.status === :nonmonotone_profile
        @test isnan(upper.endpoint)
    end

    @testset "LR tolerance must be smaller than the cutoff" begin
        callback = _gpi_accepted_lr(v -> 2.0 * (1.0 - v); tag = :bad_tolerance)
        @test_throws ArgumentError GLLVM._profile_invert_callback(_GPI_BASELINE_NLL, callback;
            side = :lower, inside_v = 1.0, outside_v = 0.0, cutoff = _GPI_CUTOFF,
            tol_D = _GPI_CUTOFF, maxiter = 8)
    end

    @testset "accepted flag cannot override a failed refit status" begin
        failed_status = _gpi_callback((v, stage) ->
            (accepted = true, objective_nll = _gpi_nll(-1e-14),
             status = :gradient_not_converged); tag = :failed_status)
        direct = GLLVM._profile_lr_refit(_GPI_BASELINE_NLL, 0.8, failed_status;
            tol_D = _GPI_TOL_D)
        @test direct.status === :gradient_not_converged
        @test !GLLVM._profile_point_usable(direct)
        @test isnan(direct.lr)

        bracket = GLLVM._profile_invert_callback(_GPI_BASELINE_NLL, failed_status;
            side = :lower, inside_v = 1.0, outside_v = 0.0, cutoff = _GPI_CUTOFF,
            tol_D = _GPI_TOL_D, maxiter = 8)
        @test bracket.status === :invalid_refit
        @test isnan(bracket.endpoint)

        historical_callback = _gpi_callback((v, stage) -> isapprox(v, 0.8) ?
            (accepted = true, objective_nll = _gpi_nll(-1e-14),
             status = :gradient_not_converged) :
            (accepted = true, objective_nll = _gpi_nll(2.0 * (1.0 - v)),
             status = :accepted); tag = :historical_failed_status)
        historical = _gpi_observed(historical_callback, 0.8)
        @test historical.status === :gradient_not_converged
        rejected = GLLVM._profile_invert_callback(_GPI_BASELINE_NLL, historical_callback;
            side = :lower, inside_v = 1.0, outside_v = 0.0, cutoff = _GPI_CUTOFF,
            tol_D = _GPI_TOL_D, maxiter = 8, observed = [historical])
        @test rejected.status === :invalid_refit
        @test isnan(rejected.endpoint)
    end

    @testset "historical receipt variance and profile invariants are bound" begin
        active = _gpi_accepted_lr(v -> 2.0 * (1.0 - v); tag = :active_profile)
        receipt = _gpi_observed(active, 0.8)
        retagged_variance = merge(receipt, (fixed_variance = 0.7,))
        @test_throws ArgumentError GLLVM._profile_invert_callback(
            _GPI_BASELINE_NLL, active;
            side = :lower, inside_v = 1.0, outside_v = 0.0, cutoff = _GPI_CUTOFF,
            tol_D = _GPI_TOL_D, maxiter = 8, observed = [retagged_variance])

        foreign = _gpi_accepted_lr(v -> 2.0 * (1.0 - v); tag = :foreign_profile)
        foreign_receipt = _gpi_observed(foreign, 0.8)
        @test_throws ArgumentError GLLVM._profile_invert_callback(
            _GPI_BASELINE_NLL, active;
            side = :lower, inside_v = 1.0, outside_v = 0.0, cutoff = _GPI_CUTOFF,
            tol_D = _GPI_TOL_D, maxiter = 8, observed = [foreign_receipt])
    end
end
