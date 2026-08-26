# After-task — post-#265 audit session: five plan slices withdrawn, one guard built

**Date:** 2026-08-26 · **Lane:** `claude/lane-beyond-20260824` · **Platform:** Claude
**Base:** `main` @ `c9605077` (PR #265 merged, all six checks green)

## Why this one

PR #265 landed the curvature contract across 12 of 13 kernels. This session was meant to
continue toward the goal's four clauses — parity, correctness debt cleared, ladder closed,
releasable. It did not close any of them. What it did instead was establish, by
measurement, that **a substantial fraction of the remaining work does not exist**, and
build the anti-recurrence guard the plan called for but never had.

That is a smaller claim than the goal, and it is the accurate one.

## What the ultra-plan got wrong

Five slices checked against the files. The Julia-side facts were usually right; the
errors were in what the *twin* or the *docs* were assumed to contain.

| slice | plan's claim | measured |
|---|---|---|
| S16 | three ledger rows "understate the code" | **wrong** — all three correct under the ledger's own published vocabulary |
| S18 | cross-validation is a parity gap | **wrong** — twin's `cv-*.R` is 20 internals, 0 `@export`, 0 NAMESPACE entries, no caller |
| S22 | "missing StatsAPI methods" (additive) | **mis-scoped** — real defect: six exported generics shadow StatsBase |
| S24 | `response-families.md` has zero coverage of 7 families | **wrong** — all 7 have their own `###` section (23 total) |
| S25 | non-Gaussian numbers only in dev-log; README/docs disagree | **half wrong** — `benchmarks.md` opens with them; the real item was the README *understating* its own data |

Plus: the goal targets twin 0.7.0; `origin/main` is 0.7.1. Immaterial — 0.7.1 "adds no new
response family, likelihood, integration engine, random-slope capability, iSDM route".

**One error shape, six times: judging a capability by whether a file exists rather than
whether it is reachable and tested.** Twice on the twin's side, four times on ours.

## The change

Documentation and one test. **No `src/` change.**

- `test/test_curvature_census.jl` (new, wired at `runtests.jl:217`) — the structural guard.
- `README.md` — speedup claim corrected to the measured 161–698×, fenced to the Gaussian
  closed-form path, non-Gaussian counter-numbers inline.
- `docs/dev-log/check-log.md` — four entries: post-#265 audits, ledger honesty pass, the
  Beta PD measurement, the docs/API withdrawals.
- `docs/dev-log/pending/` — 8 analysis documents + two reproducible probes.

### The guard, and why it is not a grep

Every prose census of the curvature class was built with `grep`, and every one missed
sites: `^_glm_weight(` skips Beta (`beta.jl:21`) and GP1 (`gp1.jl:65`) because they use
block form; a `src/families/*.jl` sweep skips `_glm_weight(::Normal)` at
`spde_latent.jl:54`. That last one was found *by the guard*, in my own census, an hour
after I wrote the census.

So it reflects over `methods(_glm_weight)`. It cannot miss a definition by formatting or
location. It asserts that every family has **made and recorded** a curvature choice — not
which choice is correct, which is a per-family modelling decision.

## Verification

- Guard in isolation: **6 pass / 0 fail**.
  **Superseded — see the note at the end of this report.** These citations describe the
  guard as of `247efbc1`. The next commit (`52bd95e1`) rewrote it after an adversarial
  review found two holes; the final file has 10 tests and the cited assertions moved.
- **Falsifiability proven** (I shipped tautological tests earlier in this arc and will not
  repeat it): dropping Beta from `KNOWN_OPEN` fails at `:102` naming `Beta @ beta.jl:21`;
  adding a phantom entry fails at `:114` on `isempty(stale)`; restored → 6/6.
- Beta PD-hit measurement: 4 settings × 5 seeds, **0 / 20** `-Inf` marginals.
- Full `Pkg.test()`: **running at time of writing — this report is not a pass claim.**

## What I got wrong, corrected in-session

1. **Overstated the Beta risk.** I reported the flip as blocked by a silent-failure mode
   (negative curvature → PD guard → `-Inf` → `1e12` sentinel reads as convergence).
   Measured: 0 of 20. Negative weights are real but too sparse (0.04–0.63 % of cells) to
   make the Hessian indefinite. **That should not be the reason to hold.**
2. **Wrote a vacuous assertion.** The guard's first run had two failures that were my own
   bug — `hasmethod(_default_hessian, Tuple{fam, Any})` when the fallback is
   `link::Link`. `Any` would also have made the check pass vacuously. Fixed at the cause.
3. **Nearly reported a documented design decision as a bug.** The `Multinomial` /
   `Distributions.Multinomial` collision is documented twice, precisely, with a workaround.

## Remaining risks / limitations

- **The guard prevents a seventh open family; it fixes none of the six.** NB2, NB1,
  Student-t, Tweedie, Beta, GP1 still ship Fisher weights where TMB uses observed.
- **The mandated verification is impossible with current plumbing.** The plan requires
  "check every delegation move by FITTING, not evaluating". No public fitter exposes a
  `hessian` kwarg, so a flip cannot be A/B tested at the surface a user calls.
- **The `~340×` headline has no published grid.** `benchmarks.md` has no phylogenetic
  speedup table; its only grid has a median of 265.1×. Not edited — unverifiable from
  this repo.
- **StatsAPI shadowing is found, not fixed.** Six exported generics break under
  `using GLLVM, StatsBase`. The fix is an API change.

## Blocked on the maintainer

1. `hessian` kwarg on the family fitters — the plumbing that makes the six flips testable.
2. StatsAPI re-rooting (API change + convention cascade).
3. Delta-family identity fork (S12/S13 — changes the model).
4. CI duplication: `push: [main]` + `pull_request` re-tests an identical tree, ~25 Linux-
   equivalent hours per merge.
5. Version bump 0.3.0 → 0.4.0, the four `rejected` rows, AGHQ unpark, Tweedie STOP #234.

## Outcome (author's statement — NOT a Rose verdict)

*Corrected 2026-08-26: this heading originally read "## Rose verdict" and rendered a verdict
in Rose's voice. AGENTS.md defines Rose as an independent gate precisely so the implementer
does not grade their own work. The real audit ran afterwards; its verdict and blockers are
recorded in `check-log.md` under "Rose audit". What follows is the author's own summary.*

**Not done, and not claimed done.** None of the goal's four clauses is satisfied. The
session's net contribution is negative-scope (work removed by measurement) plus one
structural guard. Claim-vs-evidence: every number here is reproducible from
`docs/dev-log/pending/`. The one open honesty item I could not resolve is the `~340×`
figure, which is flagged for the pre-tag gate rather than quietly corrected.


---

## Post-audit note (2026-08-26)

Rose audited these commits after this report was written and returned **four defects in
the artifacts above**, three of them in records built to fix earlier sloppiness:

1. The drift fence undercounted the engine's own `X` surface by one (cited the
   gaussian-exclusive constant against a gaussian-inclusive R list). Fixed; the public
   report at `gllvmTMB#488` was corrected too.
2. A check-log entry gives the bridge-X drift as 3 where the correct figure is 6, and was
   superseded without being marked. Reconciled.
3. **This report's verification citations describe the pre-`52bd95e1` guard** — the version
   before the two holes were closed. Noted inline above.
4. `README.md`'s MixedModels section has no pointer to the new pitfalls entry. Fixed.

Rose confirmed clean: the `14 _glm_weight + 8 _tp_pieces` census and every family's bucket
assignment; the README's 161–698× against the benchmarks table; and that the guard's
assertions are non-vacuous, each traceable to an invariant that fails under a concrete
mutation.

Rose also correctly notes the suite tally here is **self-reported** — these 9 commits have
never been through CI, because the workflow triggers only on `push:[main]` or
`pull_request` and no PR is open.
