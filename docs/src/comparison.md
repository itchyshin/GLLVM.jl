# Comparison: R, GLLVM.jl, MixedModels.jl

The benchmark study (see [Benchmarks](/benchmarks)) runs three engines
on each cell to put GLLVM.jl's speed numbers in context against the
state-of-the-art Julia LMM port. The third engine is
[MixedModels.jl](https://github.com/JuliaStats/MixedModels.jl), the
canonical Julia descendant of `lme4`.

## What each engine fits

- **R `gllvmTMB`** — fits the GLLVM exactly. The reference engine for
  every grid cell. TMB Laplace + L-BFGS in C++.
- **GLLVM.jl** — fits the same GLLVM. Closed-form Gaussian marginal +
  `Optim` L-BFGS + `ForwardDiff` gradients, with a PPCA closed-form
  warm start for the no-other-RE path.
- **MixedModels.jl** — cannot fit a `K ≥ 1` GLLVM directly because it
  has no latent-factor block in the formula DSL. On `K = 0` cells the
  GLLVM degenerates to an LMM and the three engines coincide (the
  `K = 0` apples-to-apples sanity check vs `lme4` lives in
  `gllvmTMB-julia-bench/report/three-way-smoke.md`). On `K ≥ 1` cells
  MixedModels.jl fits the **proxy LMM** `value ~ 1 + (1|site)` (or
  `value ~ 0 + trait + (1|site)` when fixed effects are present) — a
  strictly easier problem than the GLLVM, with no rank-`K` loading
  parameters and no per-iteration Cholesky update on a low-rank-plus-
  diagonal target.

The three-way table is reported as *"what Julia's state-of-the-art LMM
engine would do on a comparable-cost LMM problem"* — **not** a direct
head-to-head on the GLLVM.

## Headline numbers

From PERF+E (full numbers in the benchmark report):

- **GLLVM.jl vs R `gllvmTMB` on the GLLVM**: median speedup of
  **~190x** on the small cells, **~520x** on the mid cells, and
  **~280x** on the large cells. Worst-case `|Δ logLik|` across the
  grid: `2.343e-07`. Both engines converged on every fit.
- **GLLVM.jl vs MixedModels.jl on the proxy LMM**: MixedModels.jl is
  faster on the larger cells (the proxy is a strictly easier problem),
  but only by a factor of `~1.4–1.8x`. The order of magnitude is the
  same. Where MixedModels.jl is faster, the difference is an *upper
  bound* on the cost the latent-factor structure adds; that the cost
  is bounded above by a small constant factor is itself a measure of
  how cleanly the closed-form Gaussian marginal eliminates the
  expensive part of the GLLVM evaluation.

## Honest caveats

- Absolute timings in the smallest cells are sub-millisecond on the
  Julia side; replicate noise is on the order of single GC pauses. The
  benchmark uses `n_reps = 3` with medians — an order-of-magnitude
  scaling picture, not a publishable final number. A publishable speed
  claim wants `n_reps >= 10` with median + MAD plus a cold-start row.
- Both engines get a warm-up pass before the timed grid. The R side
  loads the TMB DLL and S4 method tables; the Julia side runs one
  per-`(p, n, K, has_intercept)` warm-up so the ForwardDiff
  specialisation is in the JIT cache. Without these warm-ups, rep 1 of
  every cell would be 10–100x slower than reps 2–3 on the engine that
  hadn't yet compiled the relevant code path.
- MixedModels.jl's logLik on each row is on a *different* model from
  the GLLVM logLik. It is not directly comparable unless `K = 0`. It
  is reported only for completeness.
