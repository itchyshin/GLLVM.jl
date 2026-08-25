# After-task — Rung A: no-X arms for Gamma / NB1 / BetaBinomial, and an engine defect

**Date:** 2026-08-24
**Lane:** `parity-catchup` on `handover/2026-08-24-claude`, worktree
`/Users/z3437171/local-scratch/lanes/GLLVM.jl-a43-honesty-20260818`. PLATFORM: claude.
**Follows:** `2026-08-24-lognormal-truncpois-parity-cells.md` (same arc, same toolchain).
**Reviewed as:** Ada (orchestration), Gauss (numerics), Rose (claim-vs-evidence).

## Goal, stated as a check first

Gamma (twin fid 4), NB1 (fid 15) and BetaBinomial (fid 8) had live twin Δ evidence
**only** through the +X cohort. Add the no-X arm for each, agreeing at rtol 1e-6 in a
run that also re-verifies every previously-green cell — or, where they do not agree,
say so and diagnose rather than widen.

## Result

Full suite: **191 pass · 1 broken · 192 total, exit 0, zero failures.**

| Family | Δ (jl − r) | Verdict |
|---|---|---|
| Gamma, fid 4, seed 54, per-trait α | **2.049853264907142e-8** | PASS |
| BetaBinomial, fid 8, seed 56, per-trait φ, N=8 | **6.1477294366341084e-9** | PASS |
| NB1, fid 15, seed 55, per-trait φ | −0.11505233680600213 | **BROKEN — engine defect** |

Pairing rule applied throughout: R defaults to per-trait dispersion, so each cell uses
the Julia **grouped** fitter (`group = collect(1:p)`), never the shared-dispersion
default. Getting this wrong does not error — it silently compares two different
models — so it is named in every testset.

## The NB1 cell found a real engine defect — the honest headline of this rung

Δ = −0.115 is ~1.0e-4 relative, 100× the locked rtol, and Julia's optimum is **worse**
than the twin's. Rather than widen or re-roll, it was isolated:

```
fit_nb1_gllvm_grouped(Y; K, group)                    -> -1129.7817843739615
fit_nb1_gllvm_grouped_cov(Y; X = zeros(p,n,1), K, …)  -> -1129.6667320237116
gllvmTMB nbinom1() (twin fid 15)                      -> -1129.6667320371555
```

An all-zero X contributes nothing to the linear predictor, so the `_cov` route fits
the **same model** — and matches the twin to 1.34e-8. The no-X route does not.

Ruled out **by experiment**, not by argument:

| Candidate cause | Test | Result |
|---|---|---|
| Outer convergence | `g_tol` ∈ {1e-5, 1e-8, 1e-10}, up to 5000 iterations | loglik invariant at −1129.78178; `converged == true` throughout |
| Inner Laplace mode | `newton_tol` ∈ {1e-9, 1e-12}, `newton_maxiter` ∈ {100, 500} | invariant |
| Identity / parameterisation | the +X NB1 cell under the same dispersion identity | already agrees to 1.53e-9 |

So the defect is localised to the no-X `fit_nb1_gllvm_grouped` path
(`src/families/grouped_dispersion.jl:1235`).

**How it is recorded.** The Δ assertion is `@test_broken`, so the suite **alerts
loudly when the engine is fixed** rather than silently passing. Alongside it ships a
*live* assertion that the zero-X `_cov` route does match the twin and that its loglik
is strictly better than the no-X route's — so the isolating evidence is executed on
every run, not left as prose that can rot. **No Δ is claimed for NB1 no-X.** Fixing
the engine is a `src/` change and therefore a separate arc carrying a full
`Pkg.test()`; filed as its own chip.

## Rung B (student, fid 9) — blocked on identity, correctly not attempted

Source-grounded, not assumed:

- Twin **estimates** ν by default — `R/families.R:367` `student(link, df = NULL)`;
  `src/gllvmTMB.cpp:1184-1185` carries `log_df_student` in the parameter vector;
  `R/fit-multi.R:5346-5348` maps it to `factor(NA)` **only** when `df` is supplied.
- Julia **fixes** ν — `fit_studentt_gllvm(Y; K, nu = 4.0, …)`; ν never enters the
  optimised vector.
- Worse, the scale differs in *dimension*: the twin fits `log_sigma_student` **per
  trait**; Julia fits a **single shared** σ.

So default-vs-default spans different parameter spaces twice over. Even with
`student(df = 4)` pinning ν, a **symmetric** Δ stays meaningless; only a one-sided
nesting check (R ≥ Julia, since the per-trait-scale model nests the shared-scale one)
would be honest. Recorded as **blocked on ν + scale identity** — no cell, no number.

## Files changed

| File | Change |
|---|---|
| `test/parity/parity_helpers.jl` | `:gamma`, `:nb1`, `:betabinomial` in the **no-X** oracle + trials `N` threaded as twin API-B `weights` |
| `test/parity/test_nox_dispersion_parity.jl` | **new** — three testsets, 25 assertions |
| `test/parity/runparity.jl` | include the cohort |
| `docs/design/capability-status.md` | Gamma + BetaBinomial no-X receipts; explicit NB1 **not-paid** entry |
| `docs/dev-log/check-log.md` | arc entry + measured speed entry |

`src/` was not opened.

## Fences held

L47 `none × dep` still `planned` · AGHQ rows and `aghq_grid.jl` untouched · #254's
three files untouched · `test/runtests.jl` still has zero `test/parity/` references ·
no tolerance widened · no seed re-rolled (54/55/56 fixed before first execution).

## Measured speed (separate entry in the check-log)

lognormal ≈1280× (0.104 ms vs 133 ms), truncated_poisson ≈2.2×, Gamma ≈1.6×. The
spread is an **algorithm** story: lognormal rides the closed-form Gaussian profile
path; the dense-Laplace families do not. **The ~340× headline does not generalise to
non-Gaussian families.** Bootstrap gain is the per-fit ratio × B and therefore
compounds per family — inferred from per-fit timings, with no end-to-end
`confint_bootstrap` comparison run and none claimed. Tiny fixtures, few reps, one
machine: explicitly not a benchmark result.

## Coverage

**No-X** twin-verified coverage **8/17 → 10/17** (Gamma, BetaBinomial added; NB1
attempted and deliberately *not* counted). The global "full family R↔Julia parity
claim" stays **`rejected`**.

## Remaining risks / limitations

1. One seed and one fixture per family — same-model agreement, not coverage.
2. No-X only; no X_lv, mask, or CI transport for these arms.
3. NB1 no-X is a known-bad route until the defect is fixed; the surface is unchanged.
4. Small fixtures throughout — no scaling claim.

## OWED after this rung

NB1 engine fix (chip filed) · student(9) identity decision (ν + scale) ·
truncated_nbinom2(11) dispersion granularity read from twin source ·
delta_lognormal(12) / delta_gamma(13) two-part identity · multinomial(16) needs a new
oracle helper, not a clone · tweedie(6) still blocked behind its grouped-route defects.

## Rose verdict

Checkpoint 1 (the two OWED cells) carries an explicit **PASS WITH NOTES** with all
three notes fixed — see the preceding after-task. This rung has **not** had an
independent Rose pass; its central claim (the NB1 defect) rests on the isolating
comparison now shipped as a live assertion, which any reviewer can re-run.
