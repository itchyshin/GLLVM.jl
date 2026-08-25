# After-task — DeltaGamma observed Laplace curvature (instance 5 of 6)

**Date:** 2026-08-24 · **Lane:** `parity-catchup` on `handover/2026-08-24-claude`.
PLATFORM: claude. OTHER LANES: cursor + open #254 (untouched).
**Reviewed as:** Ada (orchestration), Gauss (numerics), Rose (claim fence).

## Why this one, and why only half of it

The three open instances of the Fisher-vs-observed fault were **measured before being
fixed**, rather than ordered by intuition:

| family | measured logLik impact |
|---|---|
| **DeltaGamma** | **+3.2128** |
| Tweedie | +0.2414 |
| Student-t | −0.1720 |
| *(Exponential, already fixed)* | *+0.226* |

DeltaGamma is ~13× the others. That ranking **contradicted the prior expectation** —
Student-t looked worst, because its Fisher weight is a literal constant, structurally
the same shape as Exponential's constant `1`. It measures smallest, and with the
opposite sign.

Only the **curvature** half is done here. DeltaGamma's other gap — per-trait dispersion
in the two-part substrate — is deliberately out of scope: `_tp_pieces` receives no trait
index, so that change alters a signature ~10 families implement. The curvature half is
independently worth doing because the **score is already correct**, so the error lives
purely in `−½logdet A`: it biases the reported log-likelihood *and* the outer estimates
while the fit converges and looks perfectly healthy.

## What the reference implementations do — the framing that changed the fix

Prompted by a direct question, the twin and its siblings were checked before another
formula was hand-derived. The finding reframes the whole fault class:

**TMB never makes this choice.** `TMB::MakeADFun(..., random = ...)` builds the
random-effect Hessian as an **AD tape** (`MakeADHessObject`, differentiated off the
gradient tape of the joint nll). It is therefore the observed Hessian of whatever nll
the template coded — structurally, with no expected-vs-observed decision anywhere.
gllvmTMB (`R/fit-multi.R:5786-5793`), glmmTMB and drmTMB all go through this.

So GLLVM.jl's six instances are **one architectural fault, not six slips**:
`src/families/laplace.jl:15` defines a single `W` and uses it for two different roles —
the Fisher-scoring mode search (where expected information is fine, since it solves the
same score equation and reaches the same mode) and the Laplace log-det (where it must
be observed). The conflation was invisible for the launch families because at canonical
links the two coincide pointwise.

**And the pattern to fix it already exists inside GLLVM.jl.** Three families never had
the bug because they compute `W` as a nested ForwardDiff second derivative of the
log-density: `beta_binomial.jl:81-89`, `com_poisson.jl:109-111`,
`ordered_beta.jl:93-95`. `laplace_grad.jl:283` does the same, commenting *"rather than
hand-derive it we take it from a 1-D ForwardDiff derivative … exact and low-risk"*.
`DRM.jl` — the Julia sibling — encodes the discipline properly with a
`_laplace_d1/d2/d3` contract where `d2` is observed *by definition*, gate-tested against
ForwardDiff at rtol 1e-10, with LM damping for the *search* and exact curvature for the
*value*.

**Consequence for this fix:** the observed weight is **not re-derived here**. It calls
`_gamma_grouped_laplace_weight` in `grouped_dispersion.jl`, which already implements
`α·y/μ` and is under test elsewhere. One formula, one place.

## The change

`src/families/twopart.jl` only (`laplace.jl` and `grouped_dispersion.jl` stay untouched
— the Arc1b fence holds):

- `_tp_observed_Wc(::Any, y, ηc, Wc) = Wc` — an **identity default**, so every two-part
  family without a specific method is bit-for-bit unchanged.
- `_tp_observed_Wc(f::DeltaGamma, …)` — delegates to the existing verified Gamma helper.
- `hessian::Symbol = :observed` threaded through `twopart_loglik_site` →
  `twopart_marginal_loglik_laplace` → `delta_gamma_marginal_loglik_laplace` →
  `fit_delta_gamma_gllvm`, validated up front.

**The mode solve is deliberately left on Fisher.** Observed curvature enters *only* the
A-matrix in `twopart_loglik_site`, never `_twopart_mode`. This is not incidental:
substituting a curvature into a mode search tuned for a different one is exactly how the
Exponential fix first went wrong (‖Λ‖ ran away to ~960 against a true 0.38).

## Verification

| check | result |
|---|---|
| `:observed` vs `:fisher` differ | yes — impact **1.4937** |
| **DeltaLogNormal unchanged** | **Δ = 0.000e+00, exact equality** |
| `test_delta_gamma.jl` | **50/50** |
| `test_twopart_substrate.jl`, `test_delta_fit.jl` | pass |
| fits converge, no degeneracy | ‖Λc‖ 0.72 / 0.69 |
| invalid symbol | `ArgumentError` |
| `Pkg.test()` | see check-log |

The exact zero on DeltaLogNormal is the load-bearing safety check: it is the sharpest
possible probe of the identity default, because its positive part is Gaussian in log y,
so its `Wc = 1/σ²` was *already* the exact Hessian and must not move.

**Impact note, stated honestly:** measured **1.49** here versus the **3.21** predicted by
the ranking. The ranking fixture had *all* cells positive; a realistic delta has ~64%
presence, so only that fraction carries the positive part. The ranking was an upper
bound, not an estimate. DeltaGamma remains comfortably the largest of the four.

## Remaining risks / limitations

1. Curvature half only. Per-trait dispersion in the two-part substrate is untouched and
   is a much larger change (shared `_tp_pieces` signature, ~10 families).
2. One fixture, one seed — same-model behaviour, not a coverage claim.
3. **Tweedie and Student-t remain unfixed instances**, and a seventh surface was flagged
   at `aghq_grid.jl:203` (AGHQ adaptation also uses the Fisher `W`).
4. The structural fix — an observed-curvature hook in `laplace.jl`, using the
   nested-ForwardDiff pattern already proven in-repo — would close the class rather than
   patch it. It requires lifting the Arc1b fence: **a maintainer decision, not an
   engineering blocker.** It also obliges the implicit-gradient paths in
   `laplace_grad.jl` (which currently match the Fisher marginal deliberately) to change
   in the same arc.

## Rose verdict

Not independently audited. Every load-bearing claim ships as a live assertion or a
reproducible command — the impact difference, the exact-zero DeltaLogNormal invariance,
the delegation to the verified Gamma helper, and the invalid-symbol throw.
