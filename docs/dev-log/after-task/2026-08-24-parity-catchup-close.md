# After-task — twin-parity catch-up campaign, close-out (6/17 → 12/17, ladder complete)

**Date:** 2026-08-24 · **Lane:** `parity-catchup` on `handover/2026-08-24-claude`,
worktree `/Users/z3437171/local-scratch/lanes/GLLVM.jl-a43-honesty-20260818`, cut from
`origin/main` @ `c5b72310`. PLATFORM: claude. OTHER LANES: cursor + open #254 (untouched).
**Consolidates:** `2026-08-24-lognormal-truncpois-parity-cells.md`,
`2026-08-24-rung-a-nox-dispersion-cells.md`, `2026-08-24-nb1-nox-observed-hessian-fix.md`.

## Goal, and whether it was met

Raise **no-X twin-verified family coverage** by paying live paired RCall Δ cells,
starting with the two OWED by the handover — and, where a family cannot be compared,
say why in writing instead of quoting a number.

**Met.** Coverage **6/17 → 12/17**, and the remaining 5 each carry a written,
source-cited blocking reason. **No twin family is now un-triaged.**

## Why the OWED status was revisited at all

The handover marked lognormal (fid 3) and truncated_poisson (fid 10) **OWED**, on the
explicit premise that this session could not reach a live twin: *"If this session cannot
run the live twin, write the cell and stop — do not invent."* The premise was
**re-tested rather than inherited**, and it was false — R 4.6.0 and `gllvmTMB` 0.7.0 are
installed, and RCall's built `Rhome` already matched live `R RHOME`. Paying the cells
live is what the handover asks for when the twin *is* reachable.

## Paid — 12/17

Every number transcribed from a live paired run in which all previously-green cells
re-verified **in the same invocation**.

| fid | family | Δ (jl − r) | seed | note |
|---|---|---|---|---|
| 3 | lognormal | 2.2390281628759112e-8 | 52 | exact-vs-exact; Jacobian double-verified |
| 10 | truncated_poisson | 2.7131363822263665e-9 | 53 | Laplace both sides |
| 4 | Gamma | 2.049853264907142e-8 | 54 | per-trait α |
| 8 | BetaBinomial | 6.1477294366341084e-9 | 56 | per-trait φ, N=8, twin API-B weights |
| 15 | NB1 | 1.3443241186905652e-8 | 55 | **after fixing an engine defect this cell found** |
| 16 | multinomial | −2.2737367544323206e-12 | 57 | exact concave softmax; no Laplace either side |

Plus the six already green at session start (gaussian 0, binomial 1, poisson 2,
nbinom2 5, Beta 7, ordinal_probit 14).

Final suite: **208 pass / 0 broken / 0 failed, exit 0.**

## Blocked — 5/17, with reasons rather than numbers

| fid | family | blocking reason |
|---|---|---|
| 6 | tweedie | its only public grouped route carries previously recorded defects; a Δ would measure a defective route |
| 9 | student | twin ESTIMATES ν by default (Julia fixes it at 4.0) **and** twin fits per-trait scales vs Julia's single shared σ — two parameter-space mismatches |
| 11 | truncated_nbinom2 | granularity/mean/link all match, but NB2-class observed curvature is y-dependent and the Julia core is Fisher-only with no keyword — the NB1 artifact with nothing to flip |
| 12 | delta_lognormal | twin shares ONE η across presence and positive parts; Julia uses separate predictors with `Λz = 0` — non-nested in both directions |
| 13 | delta_gamma | same structural mismatch as fid 12 |

Not one of these consumed a fit run. Deciding *not* to measure was the correct output.

## The campaign's most valuable product was a bug, not a passing cell

The NB1 cell failed at Δ = −0.115 (~1e-4 relative, 100× rtol). Instead of widening:

```
fit_nb1_gllvm_grouped(Y; K, group)                   -> -1129.7817843739615
fit_nb1_gllvm_grouped_cov(Y; X = zeros(p,n,1), …)    -> -1129.6667320237116
gllvmTMB nbinom1() (twin fid 15)                     -> -1129.6667320371555
```

An all-zero X contributes nothing, so the `_cov` route fits the **same model** and
matched the twin to 1.34e-8. Root cause: `fit_nb1_gllvm_grouped` declared **no `hessian`
keyword**, silently inheriting the `:fisher` default — a *different objective* from
TMB's — while the file's own header (line 1079) documented `:observed` as the intended
"fit/cov" default. The code contradicted its own contract.

**The optimiser was never failing; it was converging correctly to the wrong objective.**
That is why it looked stable under every `g_tol` and `newton_tol`. Lesson worth keeping:
when a fit is stable, converged, and *reproducibly offset*, suspect the **objective**
before the optimiser.

Fixed by aligning the default with its NB2/Beta/`_cov` siblings. `:fisher` stays
reachable — a default changed, not a capability removed — with a regression testset
pinning the fix's **direction**, not just its magnitude. Verified by `Pkg.test()`:
**6401 pass / 1 broken (pre-existing) / 6402, 72m20s, exit 0.**

## Guards that did real work

- **Lognormal Jacobian, verified twice.** Structural reconstruction, plus a scale-shift
  test refitting both engines on `2·Y` (each must shift by exactly `−p·n·log 2`).
- **Multinomial anchored to an analytic value.** For an intercept-only multinomial the
  MLE is the observed category frequency, so both engines are asserted against
  `Σ_c n_c log(n_c/n)`. Two engines agreeing proves nothing if they share a mistake;
  matching a closed form independently rules that out.
- **Canary before every claim.** The full pre-existing suite was re-run unchanged before
  any new cell was trusted.

## Corrections made during the campaign

1. **Mission Control board was NOT drifted.** My diagnostic ("26 MSPL mentions vs 2 for
   GLLVM.jl") was wrong — `MSPL` lives in 1482 files of the gllvmTMB repo and the `#11xx`
   PRs are its own. Approval to "fix" it had been given on my faulty evidence; the board
   was left untouched and the prior plan's propose-only fence was right.
2. **The Jacobian gate's justification was overstated** (caught by Rose). A *one-sided*
   dropped Jacobian **is** caught by the ordinary Δ test; the scale-shift gate uniquely
   catches a **both-sides** convention error.
3. **The NB1 sweep claim was scoped too narrowly.** "NB1 was the only instance" holds
   only within `fit_*_grouped*`; the generic Laplace core is Fisher-only throughout. No
   paid receipt is affected (observed ≡ Fisher for Poisson-class at the canonical link),
   but the general claim was wrong and is corrected in the check-log.
4. **First speed figure was an artifact** ("22277×" — divide-by-near-zero plus R
   warm-up); the real value is 1280×.

## Measured speed — the expectation held only partly

lognormal ≈1280× (0.104 ms vs 133 ms) · truncated_poisson ≈2.2× · Gamma ≈1.6×. An
**algorithm** story: lognormal rides the closed-form Gaussian profile path.
**The ~340× headline does not generalise to non-Gaussian families.** Bootstrap gain is
the per-fit ratio × B and so compounds per family — *inferred* from per-fit timings; no
end-to-end `confint_bootstrap` comparison was run and none is claimed. Tiny fixtures,
few reps, one machine: explicitly not a benchmark result.

## Infrastructure fixed in passing

`runparity.jl` rewrote its own `test/parity/Project.toml` on every run — deleting the
comment explaining why GLLVM must not be listed there, then listing it. Fixed by
declaring the dep; verified by sha256 identical before and after a full run.

## Fences held, verified by command across the whole arc

`aghq_grid.jl` untouched (0) · #254's three files untouched (0) · L47 `none × dep` still
`planned` · `runtests.jl` still has **zero** `test/parity/` references · exactly **one**
`src/` file changed (`grouped_dispersion.jl`, the NB1 fix) · no tolerance widened · no
seed re-rolled after seeing a result · nothing pushed.

## Remaining risks / limitations

1. One seed and one fixture per family — same-model agreement, not coverage or recovery.
2. No-X only: no X_lv, mask, or CI transport for the new arms.
3. The five blocked families need engine or identity work, each scoped in the check-log.
4. Global *"Full family R↔Julia parity claim"* remains **`rejected`** and this campaign
   does not move it. 12/17 counts no-X logLik-agreement cells, nothing more.

## Rose verdict

Checkpoint 1 carries an independent **PASS WITH NOTES** with all three notes fixed. The
later rungs were not independently audited; their central claims ship as live assertions
or reproducible commands, so a reviewer can re-run rather than trust this report.
