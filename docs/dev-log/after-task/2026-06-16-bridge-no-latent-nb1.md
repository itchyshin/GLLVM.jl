# After Task: Bridge No-Latent NB1 Admission

## Goal

Allow the R bridge to request a no-latent (`d = 0`) Julia bridge fit and prove
the immediate NB1 grouped-dispersion row is valid.

## Implemented

- Relaxed `bridge_fit()` from `d >= 1` to `d >= 0`.
- Added a grouped NB1 bridge test with `d = 0`.
- Kept `d < 0` as a fail-loud input error.

## Mathematical Contract

For this row, the model has no latent scores or loading parameters:

```text
eta_ti = beta_t
Var(y_ti) = mu_t * (1 + phi_t)
df = p beta values + p phi values
```

For the two-trait fixture, `df = 4` and `loadings` is a `2 x 0` matrix.

## Files Changed

- `src/bridge.jl`
- `test/test_bridge_grouped_dispersion.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-16-bridge-no-latent-nb1.md`

## Checks Run

- `gh pr list --state open --json number,title,headRefName,baseRefName,updatedAt,isDraft --limit 20`
  -> two older draft PRs visible (`#95`, `#94`); no active PR on this branch.
- `git log --all --oneline --since="6 hours ago" -- src/bridge.jl test/test_bridge_grouped_dispersion.jl docs/dev-log/check-log.md docs/dev-log/after-task | head -120`
  -> current local bridge commits only.
- Direct Julia NB1 grouped `K = 0` probe
  -> finite `NB1GroupedFit(p=2, K=0, G=2)`, `_nparams = 4`, `converged = true`.
- `julia --project=. test/test_bridge_grouped_dispersion.jl`
  -> `49/49 pass`.
- Stale-claim scan:
  `rg -n "d must be a positive integer|d must be a non-negative integer|d = 0|K = 0|no-latent|full parity|complete bridge|CRAN-ready" src/bridge.jl test/test_bridge_grouped_dispersion.jl docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-16-bridge-no-latent-nb1.md`
  -> expected no-latent / `d = 0` hits, the new non-negative error string, and
  historical negative-scope wording only.
- Whitespace:
  `git diff --check` -> clean.
- Paired R fixture in `/Users/z3437171/Dropbox/Github Local/gllvmTMB`
  -> Julia/native no-latent NB1 `logLik` delta `4.253763e-08`, both `df = 4`.

## Tests Of The Tests

The added test is a boundary case: `d = 0` is the lower valid latent-rank
boundary. It also pairs the acceptance case with a `d = -1` rejection case.

## Consistency Audit

No exported symbol, family parameterisation, docstring, README, tutorial, or
Documenter navigation changed. The R-side validation row remains `partial`;
this slice covers no-latent NB1 only.

## What Did Not Go Smoothly

The useful parity fixture first failed through the public bridge with
`d must be a positive integer`, even though the inner grouped NB1 fitter already
supported `K = 0`. The fix was therefore a bridge admission correction, not a
likelihood change.

## Team Learning

- Hopper: R can legitimately send no-latent rows through the bridge.
- Karpinski: grouped NB1 has natural zero-column loading semantics.
- Rose: the claim boundary remains no-latent NB1, not full bridge parity.

## Known Limitations

Reduced-rank (`K > 0`) NB1 fitted-object parity is still unpromoted. CI
endpoints for grouped-dispersion rows remain blocked.

## Next Actions

1. Use this Julia admission in the R-side NB1 fitted-object parity test.
2. Add reduced-rank NB1 fitted-object evidence separately.
