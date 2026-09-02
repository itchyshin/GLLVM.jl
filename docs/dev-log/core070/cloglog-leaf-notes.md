# Binomial/cloglog Laplace likelihood defect — diagnosis and fix

Maintainer decisions round 1, item 2
(`docs/dev-log/decisions/2026-09-01-maintainer-decisions-round1.md`):
"Binomial cloglog likelihood disagreement: open the reviewed repair leaf now
— diagnose per-cell at R's coordinates on the retained fixture (seed 81012)
against the analytic cloglog Bernoulli-Laplace marginal; fix whichever
engine deviates if it is ours."

## Confirmed defect

At R/`gllvmTMB`'s fitted coordinates on the retained fixture
(`.unlazy/core070-aghq/wave4-batches/wave4-famlinks2/r-oracle.json`,
`"cloglog"` block: Bernoulli cloglog, `p=4, n=120, K=1`, seed 81012):

```
R loglik            = -307.8958232820915
Julia (old default)  = -309.9946742988598   (:fisher)
delta                =    2.0988510167683   nats
```

`tools/probe_famlinks_identity.jl` (same-day probit control) confirmed the
gap was cloglog-specific: probit's identity delta was already 6.6e-12 on
identical transport, so the discrepancy was NOT a coordinate/transport bug —
it was localized to the cloglog likelihood evaluation itself.

## Root cause

`_default_hessian(family, link)` selects which curvature the Laplace
log-det term uses: `:fisher` (expected/Fisher information) or `:observed`
(the true second derivative of the coded conditional log-density at the
mode). `Binomial`+`LogitLink` is canonical, so the two coincide pointwise
(`_glm_weight_matches_observed(::Binomial, ::LogitLink) = true`).
`ProbitLink` is non-canonical and already had an explicit override,
`_default_hessian(::Binomial, ::ProbitLink) = :observed` (2026-08-28).

`CLogLogLink` is ALSO non-canonical for Binomial but had **no** override —
it silently fell through to the generic
`_default_hessian(family, link::Link) = :fisher` in `families/laplace.jl`.
That generic default is correct only where observed ≡ Fisher (canonical
links, or families with an explicit `_glm_weight_matches_observed` trait);
for cloglog it is not, so every cloglog fit computed a systematically wrong
(too-Fisher, not-TMB) Laplace marginal by default.

No hand-coded `_glm_obs_weight(::Binomial, ..., ::CLogLogLink, ...)` method
exists (or was needed): the generic nested-`ForwardDiff` fallback in
`families/laplace.jl` already differentiates the coded conditional
log-density correctly for any link, and is exactly what got exercised once
`hessian = :observed` was requested explicitly. Its output matched R to
7.4e-12 (see below) — the fallback itself was never the bug.

## Per-site localization

`tools/probe_persite_cloglog.jl` (per-site `observed − fisher` gap over all
120 sites of the retained fixture):

- Gap is **not** concentrated at a handful of extreme-η sites. It takes
  exactly one of two values depending on `sum(y_t)` for that site
  (`-0.0982` for `sum(y)=1` sites, `+0.0833` for `sum(y)=4` sites, matching
  every site with that response-sum count) — i.e. the gap is a systematic
  function of the response pattern under the fixed (β, Λ), not a
  saturation-region artifact. Sum over all 120 sites = 2.09885..., exactly
  the confirmed total delta.
- The 2026-08-28 saturation clamps (`_clamp_mu`, `_clamp_eta`,
  `binomial.jl:105-112`/`~275`) are NOT implicated: they clamp μ/η only in
  the extreme tails, and this fixture's fitted coordinates (`‖Λ‖` ≈ 0.45–0.68,
  moderate η) never reach them. Re-running the two probes after the fix
  confirms this: the saturation guard's own test suite
  (`test/test_saturation_health.jl`) still fires unchanged on its dedicated
  runaway fixture, so the clamps are untouched by this change.

## Ground truth (exact quadrature)

`tools/probe_persite_cloglog.jl`, site 13 (the largest-gap site,
`sum(y)=1`), against a `QuadGK` (`rtol=1e-13`) quadrature of the exact
Bernoulli-cloglog Laplace integral `∫ exp(ℓ(z)) N(z;0,1) dz`:

```
quadrature = -3.7766839510482977   (quadgk err = 1.06e-16)
:fisher    = -3.6685514665910945   |gap to quadrature| = 0.1081
:observed  = -3.7667504131618545   |gap to quadrature| = 0.0099
```

`:observed` is ~11× closer to the exact marginal than `:fisher`. The
residual 0.0099 gap is ordinary Laplace-approximation error (K=1, moderate
curvature), not a further defect — consistent with the approximation-error
magnitudes reported elsewhere in the curvature-adjudication campaigns
(check-log 2026-08-28).

This also explains, mechanistically, why R matches `:observed` to 7.4e-12:
TMB differentiates its coded joint negative log-density via automatic
differentiation, which is definitionally the observed Hessian. TMB never
substitutes a Fisher/expected-information approximation for any family or
link it ships. R was never the deviating engine here.

## Relationship to the 2026-08-28 "cloglog saturation pathology" finding

check-log 2026-08-28 ("the last four curvature cells") diagnosed a SEPARATE
problem: on an unrelated synthetic DGP, `fit_binomial_gllvm` under cloglog
ran `‖Λ̂‖` to 20–27 (truth 0.9) during OPTIMIZATION, with 19/300 cells
saturated at the runaway optimum, overstating the exact marginal by +74.8
nats. That finding explicitly measured the runaway under **both** curvature
selectors — `:fisher` and `:observed` both derailed — so the pathology is
an identifiability / optimizer-trajectory issue orthogonal to which
curvature the log-det uses at any FIXED coordinate. Keeping `:fisher` as
the default did not protect against that runaway (it happens either way);
it only meant every cloglog fit's reported likelihood VALUE was wrong
relative to R by default, including at well-behaved, non-runaway optima —
exactly the case exercised by this fixture. The `LaplaceSaturationHealth`
diagnostic (`_laplace_saturation_health`, `BinomialFit.saturation`) remains
the correct, already-shipped mechanism for flagging that separate runaway;
it fires under either curvature selector and is unaffected by this fix
(`test/test_saturation_health.jl` reconfirmed green post-fix).

## Fix

`src/families/binomial.jl`: added

```julia
_default_hessian(::Binomial, ::CLogLogLink) = :observed
```

next to the existing `ProbitLink` override, and updated the
`fit_binomial_gllvm` docstring (previously claimed "Cloglog stays `:fisher`
... a deliberate exception, not an oversight" — that claim is now corrected
in place, citing this note).

No change to `src/families/laplace.jl` (the generic `:fisher` default for
untyped `(family, link)` pairs is untouched, and its generic
`_glm_obs_weight` ForwardDiff fallback needed no change — it was already
correct). No change to the saturation-clamp logic.

## Verification

- `tools/probe_hessian.jl` (unchanged, explicit `hessian=` kwarg both arms):
  `:fisher` still -309.9946742988598 (delta 2.0988510167683 — the selector
  itself is untouched, only the DEFAULT changed), `:observed`
  -307.8958232820989 (delta 7.39e-12).
- `tools/probe_famlinks_identity.jl` re-run post-fix (no `hessian` kwarg,
  i.e. default path):
  ```
  probit  identity_delta = 6.59e-12   (unchanged control)
  cloglog identity_delta = 7.39e-12   (was 2.0988510167683 pre-fix)
  ```
  Both links now at the same ~1e-12 floor.
- New regression test `test/test_cloglog_likelihood.jl` (wired into
  `test/runtests.jl`): (1) `_default_hessian(Binomial(), CLogLogLink()) ===
  :observed`; (2) the R-oracle fixture reproduced verbatim, asserting the
  default-path marginal matches R to `atol = 1e-8` (measured 7.39e-12) and
  that the stale `:fisher` value is still off by > 2.0 nats when forced
  explicitly (regression guard against silently reverting the default);
  (3) an independent site-level trapezoidal-quadrature ground-truth check
  (no `QuadGK` dependency) confirming `:observed` lands strictly closer to
  the exact marginal than `:fisher` at fixed non-degenerate coordinates.
- Existing suites reconfirmed green post-fix: `test_binomial_fit.jl` (8/8),
  `test_binomial_laplace.jl` (9/9), `test_beta_binomial.jl` (9/9),
  `test_bridge_lv_predictor.jl` (207/207), `test_saturation_health.jl`
  (17/17, runaway warning still fires unchanged), `test_hessian_kwarg.jl`
  (32/32, updated to assert the new cloglog default), and
  `test_laplace_curvature_contract.jl` (134/134, updated to assert the new
  cloglog default).
- All binomial links (`LogitLink`, `ProbitLink`, `CLogLogLink`) remain on
  their existing gradient paths (logit: hand-coded analytic on the no-offset
  path; probit/cloglog: finite-difference — `link isa LogitLink` gate,
  unaffected by this change) — no coupled analytic-gradient formula assumed
  a specific curvature for cloglog, so no gradient FD-verification tolerance
  is at risk from this fix.

## Verdict

**Julia was the deviating engine.** R/`gllvmTMB` was correct throughout;
no frozen-oracle defect report is warranted. Fixed with a single-line
`_default_hessian` override, matching the established per-(family,link)
pattern used for every other non-canonical-link case in the codebase
(`ProbitLink`, `LogLink` for Gamma/NegBin/NB1/Exponential/Tweedie/
TruncatedNegBin2, `LogitLink` for Beta, `IdentityLink` for Student-t).
