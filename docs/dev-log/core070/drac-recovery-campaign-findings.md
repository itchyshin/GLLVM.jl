# DRAC recovery campaign — findings (2026-09-01, Narval job 2207075)

Design: the committed draft (2026-09-01-drac-recovery-campaign-draft.md),
reshaped after the pre-run gate (job 2206979, 10/10 green) into chunked
arrays: 5 families x {p=5,25} x {n=50,200} x 500 seeds = 10,000 native
GLLVM.jl fits, 400 single-core tasks (25 seeds/task amortizing the measured
~20s compile), julia/1.10.10 (exact Manifest match), depot + outputs on
/project. All 400 tasks COMPLETED; wall ~83 min. Retained:
.unlazy/core070-aghq/drac-recovery-01/campaign-out.tar.gz
(sha256 90c2c08b...), source also on Narval /project.

## Summary (median over 500 seeds/cell; conv = fitter's own gate)

Gaussian, Poisson, NB2, Beta: 100.0% convergence in ALL cells; crossprod
relative error and beta-RMSE ~halve from n=50 to n=200 (e.g. beta p=25:
0.309 -> 0.195; poisson p=25: 0.427 -> 0.275). No error rows anywhere.

Binomial (Bernoulli, logit): an information-limited boundary, now
quantified — p=5,n=50: 78.0% conv, med Cerr 2.40; p=25,n=50: 21.8% conv,
med Cerr 1477 (runaway loadings among failed fits); n=200 recovers to
97.2-100% conv with med Cerr ~0.80-0.87, still the worst family. This is
the saturation/information-poverty regime documented in
src/families/binomial.jl (2026-08-28 diagnosis) — multi-seed evidence that
the convergence gate is doing its job at small n, and that Bernoulli cells
below ~8 obs/species should carry a documented health warning rather than a
recovery claim.

## What this is NOT
Not a parity comparison (no R fits in this campaign); not CI coverage
(deliberately excluded — profile-CI cost, separate decision); not evidence
for cells outside {5,25}x{50,200}.

## Follow-ups
- Tutorial/docs: Bernoulli small-n health warning (Darwin/Pat framing).
- Optional paired-R replication of the binomial p=25,n=50 cell to see
  whether the frozen twin's gate behaves identically there.
- CI-coverage campaign decision (maintainer).
