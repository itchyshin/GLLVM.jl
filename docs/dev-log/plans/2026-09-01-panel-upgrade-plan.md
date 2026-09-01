# Panel-upgrade plan — from qualified harness agreement toward defensible parity

```
🎯 GOAL
Solo platform: Claude (this session, lane codex/core070-aghq-20260830)
Deliverable: the adversarial panel's mandated upgrades implemented and receipted —
  (a) Julia boundary-honesty repair (a fit at a nu->infinity / sigma->0 boundary can
      no longer present as cleanly converged without a reported boundary flag);
  (b) cross-objective identity machinery (evaluate each engine's objective at the
      other's fitted coordinates), validated first on a known-answer frozen fixture,
      then applied to ACC-URBMAP to decide ridge-vs-different-likelihood;
  (c) the machinery wired into the harness as an additional assertion tier;
  (d) the two pre-existing red test files diagnosed (fix if root cause is safe and
      local; classify otherwise);
  (e) Julia-side bridge payload upgrades (gradient_max + R-style coefficient names).
HEADLINE: (b) — the two-function-evaluation check that converts argmax agreement
  into same-likelihood proof, panel-ranked highest value.
IN PARALLEL: (a), (d), (e) are independent of (b); (c) depends on (b).
DEFER (fenced): R-side bridge lane (awaits maintainer authorization); se=TRUE
  curvature cells and realistic-shape fixtures (needs fixture-design decision);
  any contract/tolerance change; anything outside this lane; push/merge; DRAC.
DISCIPLINE: verify = TDD red-first per slice + frozen-fixture known-answer
  validation before any real-data conclusion · compute = local + Totoro socket ·
  closure = per-slice unlazy gates below + check-log + checkpoint; honest PARTIAL
  where a slice doesn't land by morning.
```

## Wayfinder decision map (the fog, named)

Destination: "parity" claims for GLLVM.jl satisfy the panel qualifier's upgrade
path — same-likelihood (cross-objective) proven per cell, boundary pathologies
reported symmetrically by both engines, and inference-level (curvature/SE)
comparison at least designed.

Decisions so far: panel qualifier is binding on the word "parity"; additive
boundary flag rather than flipping `converged` semantics (a converged-flag
change is a public-contract change = maintainer gate); cross-objective deltas
target <=1e-8; validation on a known-answer fixture before real-data use.

Not yet specified (maintainer): R-side bridge lane authorization; whether the
boundary flag should eventually demote `converged` (behavior change); fixture
scale for realistic-shape cells; se=TRUE comparison design; A6 final
classification wording (now "shared boundary pathology, asymmetric reporting").

Out of scope: editing R gllvmTMB from this lane; re-running the whole harness
tonight (cross-objective wiring lands with tests; the full receipted re-run is
the morning's first Totoro batch after review).

## Slices and unlazy gates

- S1 boundary-honesty (src/families/studentt.jl + fit-health surface)
  G-S1: red test first — a Student-t fit driven to the boundary (nu huge,
  sigma tiny) must expose a truthy boundary indicator in its public fit object;
  test fails pre-change, passes post; neighboring Student suites unregressed.
- S2 cross-objective machinery (new tools/ + test file; no engine edits)
  G-S2a: on the frozen COV-ORD-LATENT-BARE case, Julia objective at Julia
  coordinates reproduces the retained NLL to <=1e-10 (machinery sanity);
  G-S2b: R->Julia coordinate translation validated on the same case: Julia
  objective at R's retained fitted coordinates within <=1e-8 of R's logLik.
  Only after G-S2 passes may ACC-URBMAP be cross-evaluated (G-S2c: both
  cross-deltas computed and recorded, whatever they are).
- S3 harness wiring: cross-objective assertion helper added to parity fixtures
  behind an env flag default-on for new runs; unit-tested; NOT a re-run tonight.
- S4 red-file diagnosis: root-cause the empty-design ~1e-7 route disagreement
  and the phylo-poisson canary; fix only if local and safe (TDD); else classify
  with evidence.
- S5 bridge payload: gradient_max + coefficient names in the Julia bridge
  return; red-first bridge unit test; no R-side edits.

Estimate: S1 ~1h · S2 ~2h · S3 ~1h · S4 ~1-2h · S5 ~1h. Order: S1, S2, S5,
S4, S3 (S2 result may consume attention; S5 is small and independent).
```
