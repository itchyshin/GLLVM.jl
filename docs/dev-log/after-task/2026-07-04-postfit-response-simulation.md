# After Task: Postfit Response Simulation Bridge Closure

## 1. Goal

Remove the six non-ordinal postfit-simulation drift rows by adding native
conditional in-sample response simulation to GLLVM.jl and syncing the paired R
bridge expectation.

## 2. Implemented

- Added exported `simulate_response(fit, y; nsim = 1, rng = ..., kwargs...)`.
- Routed Gaussian, Poisson, Binomial, NB2, Beta, and Gamma response draws from
  the fitted in-sample response means returned by `predict`.
- Kept `OrdinalFit` simulation fail-loud until ordinal response semantics are
  reconciled with the R bridge.
- Updated `GLLVM.bridge_capabilities()` so `postfit_simulate` is true for the
  six non-ordinal one-part rows and false for Ordinal.
- Updated README, Documenter pages, the v1 capability matrix, drift-gates note,
  and check-log.

## 3a. Decisions and Rejected Alternatives

- Chose conditional in-sample simulation only. Newdata simulation and
  unconditional random-effect redraws stay gated because they need separate
  contracts.
- Chose an explicit `simulate_response` name instead of overloading Base/R-style
  `simulate` in this slice. That avoids claiming a full generic simulation API.
- Rejected Ordinal simulation for now. Local ordinal probability/class
  prediction exists, but the R bridge response/Pearson residual and endpoint
  semantics are still gated.

## 4. Files Touched

- `README.md`
- `docs/dev-log/after-task/2026-07-04-postfit-response-simulation.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/v1-contract/2026-07-03-bridge-drift-gates.md`
- `docs/dev-log/v1-contract/r-julia-v1-capability-matrix.md`
- `docs/src/changelog.md`
- `docs/src/gllvmtmb-parity.md`
- `docs/src/index.md`
- `docs/src/roadmap.md`
- `docs/src/working-with-a-fit.md`
- `src/GLLVM.jl`
- `src/bridge.jl`
- `src/simulate.jl`
- `test/test_bridge_capabilities.jl`
- `test/test_bridge_fit.jl`

## 5. Checks Run

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Outcome: `bridge_capabilities honest local surface` passed 94/94.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_fit.jl
```

Outcome: `bridge_fit minimal one-part contract` passed 208/208.

```sh
GLLVM_JL_PATH='/Users/z3437171/Dropbox/Github Local/GLLVM.jl' JULIA_HOME='/Users/z3437171/.juliaup/bin' Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge.R")'
```

Outcome: paired configured live gllvmTMB bridge test passed 793/793 after the
R drift expectation refresh.

```sh
GLLVM_JL_PATH='/Users/z3437171/Dropbox/Github Local/GLLVM.jl' JULIA_HOME='/Users/z3437171/.juliaup/bin' Rscript --vanilla - <<'RS'
pkgload::load_all(quiet = TRUE)
gllvmTMB:::gllvm_julia_setup()
engine_caps <- JuliaCall::julia_eval('GLLVM.bridge_capabilities()')
drift <- gllvmTMB:::.gllvm_julia_capability_drift(julia_caps = engine_caps)
print(drift[, c('family', 'capability', 'direction', 'status', 'gate_id')], row.names = FALSE)
cat('n=', nrow(drift), ' unregistered=', sum(drift$status == 'unregistered'), '\n')
RS
```

Outcome: 2 registered drift rows, 0 unregistered rows.

## 6. Tests of the Tests

The capability test now asserts the exact `postfit_simulate` vector
`family != "ordinal"`, so a false non-ordinal simulator flag or a true Ordinal
flag fails. The bridge-fit test draws from every admitted family, checks shape
and support constraints, and asserts that Ordinal plus `nsim = 0` throw.

## 7a. Issue Ledger

- Fixed: stale postfit-simulation drift between R and Julia capability ledgers.
- Deferred: Ordinal response simulation, newdata simulation, unconditional
  random-effect redraws, masks, mixed-family vectors, source-specific
  structural rows, and coverage calibration.

## 8. Consistency Audit

Searched and updated neighbouring docs so the new claim appears only as
conditional in-sample response simulation for Gaussian, Poisson, Binomial, NB2,
Beta, and Gamma. The v1 drift-gates note now treats the prior 8-row state as
historical and the current live drift as 2 registered ordinal rows.

## 9. What Did Not Go Smoothly

The R-side configured test assertion count stayed at 793/793 even though the
drift table shrank from 8 rows to 2. A compact drift printout was needed to make
the real surface reduction visible.

## 10. Known Residuals

This does not complete R/Julia parity or v1.0. Ordinal Wald CI and ordinal
residual semantics remain the only registered live drift rows. Non-Gaussian
fixed-effect X, masks, mixed-family vectors/CIs, source-specific `lv`,
`unique=` parity, and calibrated coverage remain gated.

Rose verdict: PASS WITH NOTES - the stale postfit-simulation drift is closed,
but the remaining ordinal semantics rows still block a full parity claim.

## 11. Team Learning

When a bridge boolean changes, log both the configured test count and a compact
drift printout. The assertion total can stay unchanged while the truth matrix
gets materially better.
