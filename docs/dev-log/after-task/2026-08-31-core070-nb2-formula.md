# Original NB2 formula qualification and input repair

## 1. Goal
Verify that wide and long Julia formulas express the original native per-trait
NB2 model, then repair any demonstrated input defect. Full Core+AGHQ goal ACTIVE,
Milestone1 PARTIAL; no full-family or bridge completion claim.

## 2. Implemented
Formula entry now validates all supplied site-table columns before model dispatch,
including intercept-only fits. Empty tables remain valid without covariates.
Added28 no-fit input assertions across Gaussian, Poisson, NB2 and Beta, wired
into the central runner. Added original NB2 native/wide/long paired qualification
with complete hashed fit evidence. Bound this formula case in the family plan.

## 3a. Decisions and Rejected Alternatives
No likelihood, curvature, optimizer controls, native fixture or parameterization
changed. Preserve seed45/p5/K2/n80 and19 free coordinates. Long rows are reversed
to test sorted pivot identity, not a different dataset. Reject wrong row counts
before response access; do not silently ignore unused malformed columns.
Foreign formula refs were inspected: their older/different front ends do not
contain this repair and were not overwritten or imported wholesale.

## 4. Files Touched
src/formula.jl; test/test_formula_input.jl and test/runtests.jl; scoped NB2 formula
runner/verifiers and native refresh wrapper; current evidence summaries, family
catalogue/plan and binding verifier; README, tutorial, changelogs, check-log and
checkpoint. No R engine or foreign checkout edits.

## 5. Checks Run
Totoro1 thread, Julia1.12.6, R4.5.3/TMB1.9.21, frozen Rb4d5fee. Each run estimated
under2min and capped5min. Red run48.199s:18pass/1fail; malformed rows returned
NO_ERROR. Green formula40.219s:19/19 pass. No-fit input checks8.137s:28/28 pass.
All original native/wide/reversed-long parameters and likelihoods agree within
absolute1e-10, with observed curvature and NBGroupedFit type. Native/R health
and required relative1e-6 likelihood gate pass. Wrong rows now DimensionMismatch;
missing/duplicate long cells ArgumentError. Every oracle-before/after passes.

Fresh actual required NB2/truncated-NB2 pair after source change:39/39 in43.823s.
All three batches terminal. Eleven coverage regressions plus aggregate selftest
pass while verifying the refreshed bindings. Full package suite NOT RUN.

## 6. Tests of the Tests
Retained original malformed-row failure with the unchanged fitted-model test
script. Eight formula-summary and eight copied-artifact corruptions rejected.
Native health is linked to formula report by hash; both reports and raw R fit
hashes bind to supervisor stdout. Base-R whole-fit readback and source archives
verified.28 input tests use unreadable responses, proving validation precedes
data access. Unlazy3 scoped gates pass. Requirements were written before runs;
exact verification commands were bound after initial execution, not represented
as a pre-run independent completion panel.

## 7a. Issue Ledger
Closed ignored site-table row counts for intercept-only formula calls. Original
NB2 formula model qualified at no-X scope. Formula required-runner integration
and public R bridge remain unpaid, as do broader formula model combinations.

## 8. Consistency Audit
README, docstring, tutorial and both changelogs document the same row-count and
empty-table behavior. Family plan now has2 native plus1 formula evidence bindings,
94 unbound specifications. Master source map still has no complete family
executable coverage. Older whole-source receipts are historical; current native
proof is nb2-required-refresh-evidence.json. Independent Rose review NOT RUN.

## 9. What Did Not Go Smoothly
Initial lookup assumed src/model.jl; actual front end is src/formula.jl. Red test
confirmed the source-inspection hypothesis. Other refs contain different formula
work and were inspected before editing. No failed run was erased or restarted
because of a polling timeout. Existing full formula test battery was not rerun;
the targeted checks do not substitute for it.

## 10. Known Residuals
Formula qualification is a standalone supervised check, not yet an executable
case in the main required runner. No public R bridge claim. Other families,
covariates, modifiers, recovery, coverage and inference require distinct cases.
Documenter examples were matched to executed calls; whole-page rendering unpaid.

## 11. Team Learning
An intercept-only formula still carries an input shape contract. Validate the
table before the early-return path, while retaining the intentional empty-table
route. Parent implementation/verification only; no new child or review verdict.

## 12. Cross-Product Coverage
This does NOT cover complete family/interface parity, full Core+AGHQ scope,
public bridge embedding, final package checks, scientific campaigns, performance
or rendered documentation. R0.7.1/article/foreign lanes protected. No push,
merge, release, destructive cleanup or DRAC job.
