# Stage-0 substrate helpers for confirmatory Λ profiling (D3).
# Delegates to internal `src/loading_profile_confirmatory_internal.jl` so Stage 1
# fitter wiring shares one implementation with tests.

using GLLVM

const lambda_constraint_is_pinned = GLLVM._lambda_constraint_is_pinned
const normalize_lambda_constraint_pin_matrix = GLLVM._normalize_lambda_constraint_pin_matrix
const enumerate_free_lambda_entries = GLLVM._enumerate_free_lambda_entries
const profile_refit_lambda_constraint = GLLVM._profile_refit_lambda_constraint
