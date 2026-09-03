# Core070 truncated-Poisson bridge input repair

## 1. Goal
Stop the bridge silently changing fractional count responses; preserve all foreign lanes.

## 2. Implemented
Finite positive integer validation, exact Float64/Int representability and conversion without rounding. Added aliases and nonmutation regressions; registered them in the central runner. README, docstring and response-family page explain the constraint.

## 3a. Decisions and Rejected Alternatives
Kept the frozen R admission rule (b4d5fee, R/fit-multi.R3265–3276). Rejected rounding or broad count-family changes. Wald rejection provides a no-fit discriminating regression; valid inputs retain existing CI behavior. No estimator or likelihood change.

## 4. Files Touched
src/bridge.jl; test/test_bridge_truncated_input.jl; test/runtests.jl; README.md; docs/src/response-families.md; tools/core070_bridge_input_validation.jl; tools/core070_verify_bridge_input.py; tools/core070_test_bridge_input.py; scoped contract/evidence, check-log and LOOP checkpoint.

## 5. Checks Run
Red:3pass/1fail,19.46s. Initial green:4pass,16.96s. Expanded:148pass,18.20s. Final actual-module Julia1.10 run:1466pass,22.21s, exit0 (352 truncated NB2,900 Student scalar,66 curvature census,148 bridge). Runtime and source hashes retained. No fit executed; no Pkg.test claim.

## 6. Tests of the Tests
Original code fails the fractional-response diagnostic. Eight evidence negative controls reject false fit/embedding/fullsuite claims, wrong counts, corrupt receipt, stale source and premature full-bridge certification. Evidence verifier passes; embedding gate deliberately unmet.

## 7a. Issue Ledger
Fractional truncated-Poisson bridge coercion: repaired locally with targeted proof. Full embedding/fitted bridge gate: UNMET. Original Student and truncated-NB2 fit-health failures remain. Remote family-recheck-01 final state UNKNOWN; recover before any restart.

## 8. Consistency Audit
Docstring, README, family page and runner updated together. No tolerance or R change. Old whole-source receipts are historical after this edit; final1466 checks bind the changed source for their narrow scopes. Documentation not rendered. No release/version/AGENTS/CLAUDE change.

## 9. What Did Not Go Smoothly
The old >=1 guard let fractions through to rounding; large integer/BigFloat conversions could also lose response precision. Existing Distributions.Multinomial import warning remains. No warning-free claim.

## 10. Known Residuals
Full suite, successful fitting, R embedding, original required parity replay, independent review and current docs rendering remain unpaid. Other count-family coercions were inspected as neighboring leads but are outside this narrowly evidenced change. Full finite manifest remains DRAFT_INCOMPLETE_NOT_FROZEN.

## 11. Team Learning
Test input admission before expensive optimization. A deliberately unsupported downstream option can expose an earlier validation defect without fitting; explicitly retain the downstream rejection as the valid-input control.

## 12. Cross-Product Coverage
This does NOT cover Core/AGHQ completion, successful bridge fits, calibrated recovery, performance, current rendered docs or release readiness. Rose verdict NOT RUN; M1 PARTIAL. No new child, push, merge, release or cleanup. Protected R0.7.1 and article lanes untouched.
