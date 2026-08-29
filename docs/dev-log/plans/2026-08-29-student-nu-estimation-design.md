# Design — Student-t ν estimation (parity cell 9's remainder)

**Written 2026-08-28/29 by the Claude lane, immediately after cell 9 was paid
AT FIXED ν.** Deliberately a design, not a build: the change is architectural
and contains a decision, and starting it at session end would have handed the
next session a half-built estimator. Execute after reading §5.

## 1. Where cell 9 stands

PAID at fixed ν (2026-08-28, on `main` via PR #273): with ν pinned on both
sides and Julia set to `disp_group = :species`, Δ logLik = −9.66e-10, and
3.34e-9 on an independent re-measurement at a fresh seed. Per-trait σ̂ matches
the twin to 4–5 significant figures.

NOT paid in the twin's DEFAULT configuration, because **`gllvmTMB::student()`
estimates ν** (`R/families.R:362,367`) while GLLVM.jl fixes it
(`fit_studentt_gllvm(...; nu = 4.0)`). Closing that is this design's subject.

## 2. The architectural constraint (this is the crux)

`src/families/studentt.jl:5,11,29` records it: the family currently rides the
**generic scalar-auxiliary implicit-gradient path** — ONE scalar auxiliary
(log σ) alongside η. The in-code note is explicit that estimating ν *"would
need a SECOND auxiliary, breaking the scalar-aux implicit path used here"*.

So ν estimation is NOT the same shape as the per-trait σ work that paid the
cell. Per-trait σ multiplied an existing auxiliary across traits; ν adds a
structurally new one. That is why this is a design and not a follow-on patch.

## 3. The decision the executor must take to the maintainer

**How should the ν-estimating route obtain its gradient?**

- **(A) Extend the implicit path to two auxiliaries.** Fastest at runtime and
  keeps the family on the same machinery as its siblings; the most invasive
  option, and the generic core is shared, so a mistake there is a cross-family
  fault (exactly the class this whole campaign existed to kill — see the
  2026-08-25 curvature audit).
- **(B) Route only the ν-estimating configuration to finite-difference or
  generic AD**, leaving the fixed-ν path exactly as it is. Slower for that one
  configuration, zero risk to every other family, and it matches how Gamma and
  Tweedie already sit on FD paths. **Recommended** as the first landing:
  correctness first, then optimise if the cost is measured to matter.
- **(C) Profile ν out** on a small grid / by golden-section on the marginal.
  Cheap and robust, but changes the estimand's uncertainty treatment and does
  not give a joint Hessian for ν's interval — do not choose this if intervals
  for ν are wanted.

Recommendation: **(B)**, with (A) as a later optimisation gated on a measured
need. This mirrors the repo's own precedent of shipping a correct FD path and
hand-coding kernels only where a benchmark justified it.

## 4. Parameterisation — match the twin exactly

The twin uses `df = 1 + exp(log_df_student)` (`gllvmTMB.cpp:1185`), i.e. the
support is ν > 1, NOT ν > 0. GLLVM.jl's current validation is `nu > 0`
(`studentt.jl:310`). Use the twin's transform for the estimating route so the
two optimise the same object; keep `nu > 0` for the fixed-ν route so nothing
existing breaks.

`log_df_student` is itself **per-trait** in the twin (`length n_traits`), so
full parity eventually means per-trait ν, reachable through the same
`disp_group` mechanism that landed today. Do this in two steps — shared ν
first (measure), then per-trait ν (measure again).

**⚠ The twin's df CI is off by one** — `docs/dev-log/decisions/
2026-08-28-studentt-parameterisation.md` (CONFIRMED: the C++ uses
`1 + exp(log_df)` while the profile registry uses `exp`, so reported df
bounds are df−1). Point estimates are unaffected. **A logLik Δ is therefore
safe to compare; a ν INTERVAL comparison is not** until that is fixed
upstream. Do not attribute an interval mismatch to GLLVM.jl.

## 5. Execution order

1. Read `src/families/studentt.jl` end to end, plus today's `disp_group` work
   (`git show 41e44e22`) — that commit is the shape to imitate for anything
   per-trait.
2. Take the §3 decision to the maintainer BEFORE building. It is a
   performance-vs-blast-radius call, not an implementation detail.
3. Add `nu = :estimate` (or `estimate_nu::Bool`) as an ADDITIVE option;
   `nu::Real` stays the default and must remain bit-identical (assert `==`,
   per today's precedent).
4. Warm start: method-of-moments on the standardised residuals' kurtosis, or
   simply ν₀ = 4 (the current default) — measure which converges better;
   heavy-tailed likelihoods are multimodal in ν at small n.
5. Identifiability guard: at large ν the t-likelihood flattens toward the
   Gaussian, so ν is weakly identified. Cap or warn rather than letting the
   optimiser wander to ν = 10⁶; record the cap in the fit struct's
   convergence story, not silently.
6. Tests: default bit-identity · recovery of a known ν on simulated t data at
   several true ν · nesting (estimated-ν logLik ≥ fixed-ν at the same seed) ·
   composition with `disp_group` and `hessian` · a guard test for the
   weak-identifiability cap.
7. Re-measure the parity cell with the twin's DEFAULT `student()` (ν
   estimated). Report the Δ. If it lands inside 1e-6, cell 9 pays
   unconditionally and the ladder reaches 16/17 — but have the orchestrator
   re-verify on a fresh seed before any ledger edit (today's standing rule:
   the builder is not its own judge).

## 6. What NOT to do

- Do not change the fixed-ν default. It is a shipped, tested, parity-paying
  configuration.
- Do not touch the shared scalar-aux core to add a second auxiliary without
  the §3 decision — the blast radius is every family on that path.
- Do not compare ν intervals against the twin until its df-CI bug is fixed.
- Do not mark cell 9 unconditionally paid on a fixed-ν measurement; that is
  the distinction the 2026-08-28 ledger entry exists to preserve.
