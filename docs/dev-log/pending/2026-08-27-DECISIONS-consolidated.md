# Every decision blocking the goal, consolidated — 2026-08-27

Read this instead of reconstructing state from the check-log. Each item is answerable in
one word or a short sentence; none require touching code yourself. Ordered by what
unblocks the most downstream work.

## 1. `hessian` kwarg on the family fitters — HIGHEST LEVERAGE

**Blocks:** the HEADLINE (Fisher-vs-observed curvature) entirely. No public fitter exposes
`hessian`, so the plan's own rule — *"check by fitting, not evaluating"* — cannot be
followed, and no curvature flip can be A/B tested at the surface a user actually calls.

**Ask:** approve adding an optional `hessian::Symbol` kwarg (default = today's behaviour)
to the family fitters. Additive, backward-compatible. Once in, the 6 single-part +
5 two-part open curvature cells become testable and this session can measure each one
properly instead of arguing from first principles.

**Answer:** _____

## 2. The curvature flips themselves (11 cells: 6 single-part, 5 two-part)

**Blocks:** the HEADLINE.

Measured, not guessed: flipping is a **parity change that costs accuracy** for the
single-part cells (Beta observed is farther from the exact marginal in 10/12 measured
cells). The two-part cells are more consequential — ZINB's Fisher weight is off by ~13×,
ZIB's observed curvature goes negative in 6 of 18 probe cells (a real PD-guard risk,
unlike Beta which measured 0/20).

**Ask:** proceed with the flips once #1 lands, accepting the measured accuracy trade-off
on single-part cells? Or hold pending more evidence?

**Answer:** _____

## 3. StatsAPI re-rooting (6 shadowed exports: confint/aic/bic/predict/fitted/residuals)

**Blocks:** nothing structural — a documented pitfall with a workaround exists
(`docs/src/pitfalls.md`). But it's an API change + full convention cascade (AGENTS.md),
so it needs sign-off before it can be scheduled at all.

**Answer:** _____

## 4. The 8 ledger understatements (a Rose-audited finding, not mine)

Rows reading `planned` that ship code, exports, and wired tests: multinomial/categorical
(`missing`, should be `implemented`), `mi()`, mixed-family response vector, none×dep,
kernel×indep, kernel×latent, Phylo Model A interval promotion, animal×latent (thin
evidence). Two are internal self-contradictions (bridge mixed-family reads `implemented`
while the native engine it dispatches into reads `planned`).

**Blocks:** capability ledger honesty.

**Ask:** approve relabelling these 7 to `implemented` (animal×latent stays `planned`,
evidence too thin)? One caveat: `none×dep`'s `fit_dep_gllvm` identifiability should be
checked first — a K=p wrapper implies σ_eps isn't separately identified.

**Answer:** _____

## 5. Delta-family identity fork (S12/S13 — DeltaGamma, DeltaLogNormal)

**Blocks:** 2 of the 17-cell parity ladder's remaining cells.

The twin shares ONE linear predictor across both parts; Julia uses two non-nested
predictors. This changes the model, not the code — needs your call on which identity to
adopt.

**Answer:** _____

## 6. Fenced items (unchanged all session, listed for completeness)

AGHQ unpark · Tweedie admit (STOP #234) · L47 none×dep promote · the four `rejected` ledger
rows · version bump 0.3.0→0.4.0. None touched, none need touching until 1-5 above settle.

## 7. Two engine bugs, diagnosed and NOT fixed (found while fixing something else)

- **Exponential / grouped-dispersion mode-solver**: an undamped Newton iteration
  genuinely diverges (confirmed causal — capping iterations before divergence gives a
  sane answer; the full run gives ~1e22). Shared by every grouped-dispersion family, so
  fixing it needs its own verification that the converged mode doesn't move for families
  that currently work. Also confirmed **platform-inconsistent** — diverges on
  macOS/ubuntu, does not on Windows, for the identical fixture.
- **NB1 near-zero-dispersion fragility**: a deterministic fixture's fit collapses to
  `φ≈6.7e-7` and platform floating-point determines whether that reads as converged.

**Ask:** schedule as its own arc? Neither is blocking a merge right now (both are now
`@info`-observed rather than asserted in tests), but both are real correctness debt.

**Answer:** _____

## 8. Repo housekeeping

- `gh auth refresh -s workflow -h github.com` — unblocks pushing the already-committed
  `CI.yml` change (drops `push:[main]`, saves ~25 Linux-equivalent hours per merge).
- "Require branches to be up to date before merging" in branch protection — needed to
  keep the CI.yml change's safety guarantee once it lands.
- PR #267 — status tracked live in check-log; will report here when it settles.

---

**If you only answer one thing right now:** #1. It's additive, reversible, and every other
open item in the HEADLINE column is waiting on it.
