# After Task: Scalar-Aux Analytic Derivatives

## Goal

Take the next safe speed slice for non-Gaussian fitters without colliding with
the non-Gaussian CI PR or the sparse-phy performance lane.

## Implemented

Negative Binomial log-link and Beta logit-link scalar-auxiliary dense-Laplace
gradients now use analytic per-observation derivatives for `ℓ`, `s`, and `W`
with respect to `(η, log r)` or `(η, log φ)`. The corresponding observation log
densities are evaluated with closed-form `loggamma` expressions instead of
constructing `Distributions` objects in the hot loop. A cache-backed
scalar-auxiliary value/gradient helper was added and verified against the
stateless reference, but production NB/Beta fitters remain stateless because the
NB recovery fixture can lose the Optim convergence flag when cache state enters
line-search probes.

## Mathematical Contract

The Laplace site contribution remains

```text
q_s(θ) = ℓ(y_s | zhat_s, θ) - 0.5 zhat_s'zhat_s
         - 0.5 logdet(I + Λ'W_sΛ),
```

with `zhat_s` solving `F(z, θ) = Λ's - z = 0` and
`dq/dθ = q_θ - F_θ'F_z^{-T}q_z`. For NB2,
`y ~ NegBinomial(r, r / (r + μ))`, `μ = exp(η)`, and the auxiliary coordinate is
`log r`. For Beta,
`y ~ Beta(μφ, (1 - μ)φ)`, `μ = logistic(η)`, and the auxiliary coordinate is
`log φ`. The analytic derivatives were checked against central finite
differences through the packed objective.

## Files Changed

- `src/GLLVM.jl`
- `src/families/laplace.jl`
- `test/test_family_forwarddiff_gradients.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-31-scalar-aux-analytic-derivatives.md`

No edits were made to `src/sparse_phy_grad.jl` or `src/em_phylo.jl`.

## Tests

- `julia --project=. --startup-file=no -e 'include("test/test_family_forwarddiff_gradients.jl")'`
  passed: 92/92.
- Targeted recovery for Binomial, Poisson, NB, Beta, Gamma, and Ordinal passed:
  45/45 across the six family recovery files.
- `julia --project=. --startup-file=no test/runtests.jl` passed with exit code
  0. Manual tally from emitted summaries: 2214 pass, 3 broken placeholders, 0
  fail, 0 error. The broken entries are the existing sparse-phy precision check
  plus direct-run Aqua/JET placeholders.
- `julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'` passed:
  quality 12/12 and `Testing GLLVM tests passed`. Manual tally from emitted
  summaries: 2226 pass, 1 existing broken sparse-phy precision check, 0 fail, 0
  error.

The new cached scalar-auxiliary test would have failed before this slice because
`marginal_loglik_laplace_aux_value_grad!` did not exist; it now checks
cache-backed values and gradients against the stateless reference at the base,
perturbed, and repeated parameter vectors.

## Benchmarks

Production scalar-auxiliary value/gradient kernel, p = 80, n = 400, K = 3,
24 reps:

| family | median (s) | min (s) | mean allocations |
| --- | ---: | ---: | ---: |
| negative-binomial | 0.0180 | 0.0173 | 43.9 MB |
| beta | 0.0429 | 0.0417 | 44.0 MB |

Compared with the earlier generic-observation-AD scalar-aux path in this same
branch, the production kernel is now about 2.5x faster for NB and 1.7x faster
for Beta on this cell.

Cache-backed scalar-auxiliary helper, same cell:

| family | median (s) | mean allocations | verdict |
| --- | ---: | ---: | --- |
| negative-binomial | 0.0134 | 21.1 MB | verified as value/gradient-equivalent, not production-wired |
| beta | 0.0296 | 21.1 MB | verified as value/gradient-equivalent, not production-wired |

R comparator smoke, small cell only, warmed with 3 warmup fits and 3 measured
reps:

| family | Julia (s) | gllvmTMB (s) | R / Julia | agreement_status |
| --- | ---: | ---: | ---: | --- |
| negative-binomial | 0.0488 | 1.1510 | 23.58x | same_data_parameterization_audit_needed |
| beta | 0.0524 | 0.9980 | 19.04x | same_data_parameterization_audit_needed |

The zero-warmup smoke showed Julia cold-start compilation cost, not per-fit
engine speed; the warmed rows above are the relevant comparator evidence.

Medium warmed smoke, one warmup and one measured repetition:

| family | Julia (s) | gllvmTMB (s) | R / Julia | agreement_status |
| --- | ---: | ---: | ---: | --- |
| negative-binomial | 0.8803 | 27.7240 | 31.49x | same_data_parameterization_audit_needed |
| beta | 2.9037 | 10.3560 | 3.57x | same_data_parameterization_audit_needed |

## Confidence Intervals

Gaussian Wald/profile/bootstrap and derived CIs are already present on this
branch and passed in both core and full suites. Non-Gaussian CIs are owned by
open draft PR #59 (`claude/package-work-catchup-mQiZM`); this task deliberately
did not edit that lane.

## R-Parity Verdict

R parity for strict NB/Beta likelihood interpretation is still pending the
separate parameterisation audit. The warmed small-cell benchmark is useful for
timing, but both rows remain labelled `same_data_parameterization_audit_needed`.

## JET / Allocs / Aqua

JET: clean under the `Pkg.test()` quality block.

Aqua: clean under the `Pkg.test()` quality block.

Allocs: not run; allocation evidence was captured with `@allocated` in the
targeted kernel benchmark.

## Hygiene Scans

- `git diff --check`: clean.
- `rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src CLAUDE.md AGENTS.md -g '!docs/node_modules/**'`:
  existing `AGENTS.md` status snapshot hit only; not edited because AGENTS
  changes require maintainer approval.
- Sensitive-provenance guard scan over public repo artifacts: clean.

## Remaining Risks

- Warmed NB fitting is 24x to 31x faster than R `gllvmTMB` on the small/medium
  smoke cells, but still below the aspirational 100x structured-model target.
- Warmed Beta is 19x faster on the small cell but only 3.6x faster on the
  medium cell; Beta is now the named scalar-auxiliary bottleneck.
- The next NB/Beta lane is parameterisation parity plus larger-cell warmed
  benchmark replication, not the local NB derivative formula.
- The cache-backed scalar-auxiliary helper is faster and verified as a
  value/gradient kernel, but it is not safe enough to wire into fitters until
  accepted-step or trust-region cache discipline is implemented.
- Gamma still uses the generic scalar-auxiliary fallback and remains a future
  analytic derivative candidate.
- Non-Gaussian confidence intervals are intentionally left to PR #59 to avoid
  overlapping edits.

## Rose Verdict

Rose verdict: PASS WITH NOTES — production NB/Beta scalar-auxiliary gradients
are faster and verified, warmed small-cell fits are 19x to 24x faster than R,
and the faster cache-backed helper remains a prototype until optimizer
line-search semantics are controlled.
