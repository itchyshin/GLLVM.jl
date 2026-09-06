# M2-R1 θ-map harness implementation — after-task

## Scope

This slice implements the owner-signed, harness-only θ-map clearance for
`beta_logit` and `nb2_log`. `map_r_theta_glm` now accepts dispersion blocks of
length `1` (shared) or `p` (per-trait `fit_gllvm`), and blocks every other
length with an explicit diagnostic. No `src/` or R engine code changed.

## Evidence

- Owner disposition: `docs/dev-log/core070/theta-map-disposition-2026-09-05.md`
  records G0 approval for harness-only implementation.
- Implement tip: `c37ada2e` on
  `cursor/m2-r1-theta-map-implement-20260905`.
- Focused smoke, run locally with Julia and the package project:

```text
THETA_MAP_SMOKE PASS per_trait=ok/11 shared=ok/9 invalid=blocked
```

The smoke checked `p = 3`, `K = 2`, accepted per-trait and shared dispersion
blocks, and rejected an unmapped length of `2`.

## Boundaries

This is harness evidence only. It does not establish matched-coordinate
second-order parity, programme §7 completion, coverage, or a true-parity claim.
The implement PR remains a human merge decision.
# M2-R1 θ-map implementation closeout — 2026-09-05

## Scope

This slice implements the owner-approved, harness-only θ-map fix for the
matched-coordinates diagnostic. It does not edit `src/`, the R twin, or the
public API, and it does not claim completion of programme §7.

Owner G0 signed **IMPLEMENT harness-only** on 2026-09-05. The implementation
landed on `cursor/m2-r1-theta-map-implement-20260905` at `c37ada2e`.

## Change

`tools/core070_second_order/theta_map.jl` now accepts the supported dispersion
block lengths:

- `|log_phi_*| == 1` for a shared dispersion block;
- `|log_phi_*| == p` for the per-trait `fit_gllvm` block.

Other lengths remain blocked with an explicit diagnostic. The harness does not
pool a per-trait block into one value and does not silently map an unknown
group size.

## Smoke receipt

Focused sibling smoke completed successfully from `c37ada2e`:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
  julia --project=. tools/core070_second_order/run_matched_batch1.jl \
  logs/matched-batch1-post-r1-20260905
```

Receipt log: `logs/matched-batch1-smoke-20260905.log`

- `MATCHED_PILOT_DONE pass/fail/blocked/skip = 5/0/0/0`
- Gaussian, Poisson, Binomial-logit, Beta-logit, and NB2-log each reported
  `matched_pass=true`.
- The NB2 run emitted a grouped-dispersion boundary warning and R emitted
  `NaNs produced` warnings while computing a diagnostic covariance summary;
  the process nevertheless exited `0` and reported the declared smoke tally.
- This is a focused harness smoke, not a matched-coordinates programme §7
  completion claim or a multi-seed validation campaign.

## Verification and boundaries

- Branch tip: `c37ada2e`.
- Disposition: `docs/dev-log/core070/theta-map-disposition-2026-09-05.md`.
- No conflict rewrite of `theta_map.jl`.
- No merge performed.
- Smoke receipt: `logs/matched-batch1-smoke-20260905.log` (5/0/0/0).

## Follow-up

The sibling receipt has landed; the check-log records the same evidence. Leave
PR merges to the overnight integrator.
