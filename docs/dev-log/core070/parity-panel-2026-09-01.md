# Adversarial parity panel — 2026-09-01 (D-43, fired once on the harness-parity claim)

Claim reviewed: "GLLVM.jl is at verified engine parity with frozen gllvmTMB 0.7.0
on the required harness surface (attempt5 40/40 green; attempt2 Student 284/286
with both failures R-side)." Three fresh reviewers, distinct refuting lenses.

## Verdicts

- **Panel A (receipt forensics, Sonnet): CONFIRMED.** 40 cell receipts across all
  phases, 819 assertions, full-scan zero failures; source pins byte-identical to
  candidate tree 806804c3; frozen commit verified; Student cell fails are exactly
  the two R-health assertions.
- **Panel B (coverage skeptic, Sonnet): OVERCLAIM as an unqualified phrase;
  confirmed only as literally scoped.** Harness cells are toy fixtures (p<=5,
  n<=150); 12/447 required_core rows bound (2.7%); 0/39 AGHQ rows and 0/79
  SE/vcov/confint/predict rows have executable receipts; recovery-to-truth never
  tested (engine-to-engine only).
- **Panel C (statistical adequacy, Opus): DEFENSIBLE-WITH-QUALIFIERS**, with
  four load-bearing findings:
  1. Only the Tier-B cells (same-point objective identity) license "same
     likelihood"; 13/17 family smokes are Tier-A only (argmax value agreement),
     and absolute 1e-6 logLik tolerance admits large coordinate displacement in
     ill-conditioned directions (no cell measures conditioning).
  2. **Nothing second-order is compared anywhere** (se=FALSE throughout; the
     covariance cells collect hessian_min and never assert it): SE/interval/
     curvature parity is entirely unproven — the exact historical bug class
     (expected-vs-observed Laplace weight) would pass every required assertion.
  3. ACC-URBMAP's 2.2e-2 is in a ROTATION-INVARIANT quantity — a genuine
     flat-ridge finding (effective curvature ~4.7e-4, condition ~1e6), and the
     harness has no cell at that shape or conditioning.
  4. **The A6 "R-side health" classification is overturned as one-sided:** both
     engines sit on the nu->infinity boundary (Julia nu1=3.0e31 with
     converged=true vs R 2.3e10 with false-convergence(8), sigma1 differing 3
     orders). R correctly DIAGNOSED the shared boundary singularity; Julia
     MISSED it. The fixture computes flat_boundary and only prints it. The
     "40/40" denominator itself depends on this disputed classification.

## Panel-mandated qualifier (verbatim; binding on every use of "parity")

> Parity here means agreement of the marginal log-likelihood to <=1e-6 at each
> engine's own optimum, with matching free-parameter counts and both-engine
> fit-health, on small well-conditioned fixtures (p<=5, K<=2, n<=150); a subset
> of cells additionally verifies that Julia's objective evaluated at R's fitted
> coordinates matches R's objective, and the Gaussian cells verify its gradient
> there too, but no cell compares Hessians, standard errors, or intervals
> between engines (se = FALSE throughout), and no cell tests a shape or
> conditioning comparable to real data, where a measured logLik agreement of
> 1.4e-7 has coexisted with a 2.2e-2 difference in the rotation-invariant
> loading crossproduct.

## Panel-mandated next checks (highest value first)

1. **Cross-objective identity as a required assertion in every cell**: evaluate
   each engine's objective at the OTHER engine's fitted coordinates; require
   both deltas <=1e-8. Two function evaluations per cell; converts every Tier-A
   cell to Tier-B. Run it FIRST on ACC-URBMAP (requires refits that save full
   coordinate vectors + careful parameter-map translation — a bounded slice,
   not a five-minute patch; a packing mistake would manufacture a false alarm).
2. Cross-engine gradient at the shared point (extend the Gaussian
   point_gradient_delta pattern to all families).
3. NEW REPAIR LEAF (from finding 4): Julia boundary/fit-health honesty — a fit
   with nu ~ 1e31 must not report converged=true without a boundary flag;
   promote the computed flat_boundary diagnostic from println to an asserted,
   reported field. This is a JULIA defect found by the panel, symmetric to the
   R health gate we have been crediting.
4. Then: se=TRUE curvature/SE comparison cells; realistic-shape fixtures.

## Net verdict for the maintainer

We are NOT "at parity" in the sense a user or referee would hear unqualified.
We ARE at receipt-verified, likelihood-level harness agreement on a small
well-conditioned surface, with the qualifier above mandatory, three named
upgrades that would make the claim strong (cross-objective, gradient,
curvature), and one Julia-side diagnostic defect to repair before the Student
cell's classification can be finalized.

## Addendum — panel-mandated checks EXECUTED (same session)

1. Cross-objective identity tool built with a known-answer gate
   (test/test_cross_objective_known_answer.jl): on frozen COV-ORD-LATENT-BARE,
   GLLVM's objective at the frozen R reference's retained coordinates
   reproduces R's loglik to <=1e-8 (4/4). Commit 51dfac3f.
2. ACC-URBMAP cross-evaluation run (local, invariant-coordinate route,
   eigen factor of the retained crossprods, ProbitLink, observed curvature):
   Julia objective at Julia's coordinates delta 2.374e-10 (validation);
   Julia objective at R's fitted coordinates delta -2.486e-9 vs R's retained
   logLik. VERDICT on panel finding 3: the engines implement the SAME
   likelihood at both optima on the real 52x191 data; the 2.2e-2
   loading-crossproduct divergence is one shared flat ridge (weak
   identification both engines inherit), not a likelihood difference.
   Limitation stated: this is the Julia-evaluates-at-R direction; the
   TMB-evaluates-at-Julia direction remains to run for full symmetry.
3. Julia boundary-honesty repair shipped (commit efe3d644): StudentTFit
   carries nu_boundary (nu > 1e6 rule), warns at fit time, prints in show();
   converged semantics unchanged. Red-first; 56/56 Student suites.
