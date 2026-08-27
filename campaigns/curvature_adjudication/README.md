# Curvature adjudication campaign (Arc 1, decision #2)

Measures, per family × regime × seed (K = 1): which Laplace curvature
(`:fisher` vs `:observed`) better approximates the exact marginal, and whose
fitted estimates achieve the higher exact marginal. The exact marginal is a
dense log-trapezoid quadrature (8001 nodes on [−10, 10]) — independent of the
Laplace code path; only the per-observation density is shared, which is not
under test.

Grid: 6 families (gamma, beta, negbin, negbin1, studentt, exponential) ×
3 regimes × 50 seeds = 900 cells. Poisson/binomial are canonical (nothing to
adjudicate); gp1/tweedie deferred to a follow-up cell type.

## D-139 gate (status: PRE-RUN DONE, AWAITING APPROVAL)

Pre-run (2026-08-27, local, 2 cells): gamma/small and negbin/small run in
~5 s each, oracle sane, both cells prefer `:observed` on both metrics.
Estimate for the full grid: ~5 CPU-hours serial (≈20 s/cell average across
regimes) → ~30–60 min wall on Totoro at modest parallelism, or one DRAC
array (`sbatch_array.sh`, 120 bundled tasks) in a single queue cycle.
**Do not submit the full campaign without maintainer approval.**
