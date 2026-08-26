# Two corrections to the ultra-plan (both REMOVE work)

**Date:** 2026-08-25 · **Lane:** `claude/lane-beyond-20260824` · Verified read-only.

## 1. S18 "Cross-validation" is NOT a parity gap — drop it

**The plan said:** *"Twin ships `R/cv-internal.R`, `R/cv-metrics.R`. Julia has no
`crossval` symbol at all, and no ledger row — a gap in the ledger's own coverage."*

**Measured:** the Julia half is right; the twin half is wrong.

| check | result |
|---|---|
| CV symbols in `GLLVM.jl/src/` | **none** (`cross_kernel` / `make_cross_kernel` are cross-*trait* kernels, unrelated) |
| twin functions in `cv-*.R` | 20, **all dot-prefixed internals** (`.cv_run`, `.cv_rmse`, `.cv_auc`, …) |
| `@export` roxygen tags in `cv-internal.R` / `cv-metrics.R` | **0 and 0** |
| CV entries in twin `NAMESPACE` (`origin/main`) | **0** |
| callers of `.cv_run` / `.cv_baselines` outside `R/cv-*.R` | **none** — only a code comment in `data-cv-fixture.R` |
| twin vignette for CV | none (a test exists: `test-cv-internal.R`) |

The twin's cross-validation is **tested internal machinery that no exported function
reaches**. It is not a shipped user capability, so there is nothing for GLLVM.jl to
reach parity *with*.

**Consequences:**
- **Drop S18 from the parity scope.** It is not owed.
- The capability ledger's *lack* of a CV row is **correct**, not an omission. The plan
  listed this as "a gap in the ledger's own coverage" — that criticism is withdrawn.
- If CV is ever wanted in GLLVM.jl it is a *new feature*, judged on its own merits, not
  a parity debt.

## 2. The twin has moved to 0.7.1 — but the parity target does not move

The goal names **gllvmTMB 0.7.0**. The local twin working tree is 0.7.0; **`origin/main`
is `Version: 0.7.1`**. So the stated target was one release behind.

It does not matter, and the twin's own NEWS says why:

> "This candidate is a narrow trust-release closure. It adds no new response
> family, likelihood, integration engine, random-slope capability, iSDM route,
> or broad `predict(newdata = )` claim."

0.7.1 ships documentation, a soft-deprecation help update, and one new warning. It is
also explicitly a **release candidate** — *"No CRAN submission, tag, or public release
accompanies this candidate."*

**Consequences:**
- **The 17-cell parity ladder is not chasing a moving target.** Capability parity with
  0.7.0 remains the correct stopping condition.
- One small optional item, not currently on the ladder: twin **#1190** now warns when
  `unit_obs` / `cluster` is supplied but consumed by no covariance keyword. If GLLVM.jl
  has equivalent slots this is a cheap UX-parity item. **Not verified either way** —
  flagged only.

## Method note

Both corrections came from checking the *twin's* side of a claimed gap, not the Julia
side. The plan's Julia-side facts were accurate in both cases; the errors were in what
the twin was assumed to ship. Worth repeating on the remaining ladder cells: **a parity
gap needs evidence from both halves, and "the file exists in the twin" is not evidence
that the twin ships the capability.**
