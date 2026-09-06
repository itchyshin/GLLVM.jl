# M2-R1 θ-map implementation closeout — 2026-09-05

## Scope

This slice implements the owner-signed, harness-only θ-map clearance for
`beta_logit` and `nb2_log`. `map_r_theta_glm` accepts dispersion blocks of
length `1` (shared) or `p` (per-trait `fit_gllvm`) and blocks every other
length with an explicit diagnostic. No `src/` or R engine code changed.

Owner G0 signed **IMPLEMENT harness-only** on 2026-09-05. The implementation
landed on `cursor/m2-r1-theta-map-implement-20260905` at `c37ada2e`; the
smoke receipt was recorded at `cb8ede10`.

## Focused smoke receipt

Command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
  julia --project=. tools/core070_second_order/run_matched_batch1.jl \
  logs/matched-batch1-post-r1-20260905
```

Receipt: `docs/dev-log/core070/matched-batch1-smoke-receipt-2026-09-05.md`

The process exited 0 and reported **5/0/0/0
pass/fail/blocked/skip**. All five cells reported `matched_pass=true`:

| Cell | SE max relative delta | Vcov Frobenius relative delta | Log-likelihood delta | Result |
|---|---:|---:|---:|---|
| `gaussian` | 2.13e-7 | 4.26e-7 | 3.41e-13 | PASS |
| `poisson` | 1.92e-7 | 1.84e-7 | 2.09e-11 | PASS |
| `binomial_logit` | 4.18e-8 | 8.10e-8 | 8.24e-12 | PASS |
| `beta_logit` | 1.06e-7 | 1.79e-7 | 4.26e-13 | PASS |
| `nb2_log` | 1.91e-7 | 2.48e-7 | 1.71e-12 | PASS |

The two formerly blocked cells now map their per-trait dispersion blocks:
`log_phi_beta = 5 (= p)` and `log_phi_nbinom2 = 5 (= p)`. All values are
inside the declared `1e-4` SE/vcov bars.

## Caveats and boundaries

The NB2 run emitted a grouped-dispersion boundary warning for groups `[1, 3]`
and R emitted `sqrt(diag(cv)) : NaNs produced` warnings twice. The driver still
reported the declared smoke result and exited 0; this is not a claim that the
NB2 Wald/vcov surface is healthy on every diagnostic.

The smoke output's `summary.json` `note` field is stale: it still says
`beta_logit` and `nb2_log` are expected to be blocked. Trust the receipt
tally and per-cell JSON, not that stale note.

This is harness evidence only. It does not establish matched-coordinate
second-order parity, programme §7 completion, coverage, or a true-parity
claim. No merge was performed; the overnight integrator owns PR #301.

## Verification

- Disposition:
  `docs/dev-log/core070/theta-map-disposition-2026-09-05.md`.
- Receipt:
  `docs/dev-log/core070/matched-batch1-smoke-receipt-2026-09-05.md`.
- Raw run log (not committed):
  `logs/matched-batch1-smoke-20260905.log`.
- No conflict rewrite of `theta_map.jl`.
