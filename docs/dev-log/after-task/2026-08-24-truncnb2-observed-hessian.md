# After-task — truncated_nbinom2 (fid 11): observed Laplace curvature, cell unblocked and paid

**Date:** 2026-08-24 · **Lane:** `parity-catchup` on `handover/2026-08-24-claude`.
PLATFORM: claude. OTHER LANES: cursor + open #254 (untouched).
**Identity:** `docs/dev-log/decisions/2026-08-15-truncated-nbinom2-identity.md`.
**Reviewed as:** Ada (orchestration), Gauss (derivation + numerics), Rose (claim fence).

## Goal, stated as a check first

Make the fid-11 parity cell *meaningful*, then pay it: implement the observed
(TMB-matching) Laplace curvature for zero-truncated NB2, thread a `hessian` keyword
through the per-trait route, and have the cell agree with `gllvmTMB` at rtol 1e-6 in a
run where every previously-green cell stays green — with `Pkg.test()` clean.

## Why it was blocked

Everything already matched the twin — per-trait dispersion (`r_t ≡ exp(log_phi_truncnb2[t])`,
`cpp:1187-1190`), untruncated mean scale, log-link-only, `y ≥ 1` — **except the Laplace
curvature**. Both Julia routes built the log-det from the **Fisher** (expected
information) weight with no way to select otherwise, while TMB always uses the
**observed** joint Hessian.

For NB2-class likelihoods those differ pointwise, because the curvature is y-dependent
through `−(y+r)·log(μ+r)`. That is the distinction from truncated Poisson (fid 10),
where `y` enters `η` linearly, observed ≡ Fisher, and the Fisher-core cell paid
legitimately at ~2.7e-9. So fid 11 would have reproduced the same class of artifact as
the NB1 defect fixed earlier the same day — except with no keyword to flip.

## Derivation, and how it was verified

At the log link, with `ℓ = log NB2(y; μ, r) − log(1 − p₀)`, `p₀ = (r/(r+μ))^r`:

```
−∂²ℓ/∂η² = μr(y+r)/(μ+r)²  −  p₀A²/(1−p₀)²  +  [p₀/(1−p₀)]·μr²/(μ+r)²
                                                       with A = −μr/(μ+r)
```

Checked against **ForwardDiff**: max relative error **1.8e-13** across 125 (μ, r, y)
cells, μ ∈ [0.5, 25], r ∈ [0.3, 50], y ∈ [1, 40].

**Sanity that the term is the right one:** substituting `E[y] = μ` in the first term
recovers `μr/(μ+r)`, the untruncated NB2 Fisher weight — confirming both that the
algebra is right and that `y` genuinely enters the observed curvature.

### The verification instrument was the hard part

The first pass used central finite differences at `h = 1e-5` and declared the
derivation **WRONG** at ~1e-5 relative error. That verdict was an artifact of the
method: a second central difference carries roundoff ≈ `eps/h² ≈ 2e-6`, so the 1e-6
pass threshold was **tighter than the instrument could resolve**. The verifier was less
accurate than the thing being verified. Switching to AD settled it at machine
precision.

Worth recording because the failure mode is silent and inverted: trusting the first
result would have discarded a *correct* derivation and sent the arc chasing a
non-existent algebra bug.

## What changed

| File | Change |
|---|---|
| `src/families/truncated_nbinom2.jl` | `_truncnb2_observed_weight` (analytic, log-link only); `_truncnb2_laplace_weight` dispatch; `hessian::Symbol = :observed` on `fit_truncated_nbinom2_gllvm_pertrait` and `_truncnb2_pertrait_loglik_site`; up-front symbol validation; docstrings |
| `test/parity/parity_helpers.jl` | `:truncated_nbinom2` in the no-X oracle + `gllvmTMB::truncated_nbinom2()`; pairing rule documented |
| `test/parity/test_truncated_nbinom2_parity.jl` | **new** — 11 assertions |
| `test/parity/runparity.jl` | include the cell |
| `docs/design/capability-status.md` | fid 11 receipt |
| `docs/dev-log/check-log.md` | derivation, verification, before/after |

**Mode solve deliberately left on the Fisher weight.** The mode is where the joint
gradient vanishes (`Λ's − z = 0`), which does not involve the weight at all; Fisher
scoring and Newton reach the same fixed point by different paths. Only the Laplace
**log-det** requires the observed curvature, and that is the only place it changed.

**A default changed, not a capability removed.** `:fisher` remains a legitimate
expected-information objective and is still reachable; a regression testset asserts it
stays a *different* objective, so the fix's direction is pinned rather than just its
magnitude.

## Result

```
── truncated_nbinom2 logLik oracle (seed=58, p=5, K=1, n=120, per-trait r; twin fid 11) ──
  Julia logLik          = -1375.39137543662
  gllvmTMB logLik       = -1375.3913738604654
  Δ logLik (jl − r)     = -1.57615454554616e-6
```

Parity suite: **219 pass / 0 broken / 0 failed, exit 0.**

Same data and seed, before vs after — the fix moved the number, which is the only thing
that makes it worth having:

| objective | logLik | Δ vs twin | relative | vs rtol 1e-6 |
|---|---|---|---|---|
| `:fisher` (previously the only option) | −1375.4059371497754 | −0.01456 | 1.06e-5 | **fails** |
| `:observed` (new default) | −1375.39137543662 | −1.576e-6 | **1.15e-9** | **passes** |

## Robustness hole found and closed in passing

The smoke test's invalid-symbol check printed nothing. An invalid `hessian` throws
**inside** `negll`, whose `try/catch` converts any throw to `1e12` — so a typo would
have produced a converged-looking garbage fit rather than an error. Validation now runs
up front beside the link check, covered by `@test_throws ArgumentError`. This is a
general hazard of objective-level `try/catch`: it turns programming errors into
plausible numbers.

## Checks run

- Parity suite **219 pass / 0 broken / 0 failed, exit 0**; every previously-green cell
  green in the same invocation.
- ForwardDiff verification of the weight (125 cells, 1.8e-13).
- Full `Pkg.test()` — required because `src/` changed; result in the check-log.
- No tolerance widened; no seed re-rolled.

## Remaining risks / limitations

1. One seed and one fixture — same-model agreement, not coverage.
2. **The shared-scalar `fit_truncated_nbinom2_gllvm` still has no `hessian` keyword**
   and remains Fisher-only. It must not be paired with the twin default (it also
   mismatches on granularity). Giving it the same treatment is a follow-up.
3. Observed curvature is implemented for the **log link only** — which is all the twin
   permits for fid 11, so it is a fence rather than a gap.
4. No-X only; no X, mask, or CI transport for this family.

## Coverage

**No-X twin-verified coverage 12/17 → 13/17.** Remaining blocked: tweedie (6),
student (9), delta_lognormal (12), delta_gamma (13). The global *"Full family R↔Julia
parity claim"* stays **`rejected`**.

## Rose verdict

Not independently audited. Every load-bearing claim ships as a live assertion or a
reproducible command — the ForwardDiff check, the parity cell, the `:fisher`-is-different
regression, and the invalid-symbol throw — so a reviewer can re-run rather than trust
this report.
