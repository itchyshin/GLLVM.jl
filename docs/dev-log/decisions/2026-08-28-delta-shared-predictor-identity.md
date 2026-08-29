# Decision: `predictor = :shared` twin-identity mode for delta_lognormal / delta_gamma

**Date:** 2026-08-28
**Status:** ACCEPTED — implemented as a `predictor::Symbol` kwarg on
`fit_delta_lognormal_gllvm` / `fit_delta_gamma_gllvm` (default `:separate`,
bit-identical to previous behaviour).
**Depends on:** `docs/dev-log/decisions/2026-08-28-arc-decision-batch.md` gate 4
(maintainer decision: "Twin identity MODE"); build design at
`docs/dev-log/pending/…` (see the julia-engineer task brief that produced this
slice) which itself extends
`docs/dev-log/pending/2026-08-25-parity-ladder-decision-brief.md` decisions
#8/#11.
**Supersedes:** the 2026-08-25 parity brief's "new named fitter" recommendation
(decisions #8/#11) for the *shape* of this change only — the brief's other
delta-family conclusions (default stays unpaired at any Δ; `Λz = 0` under
`:separate`) are unaffected. This supersession is the 2026-08-28 maintainer's
explicit choice (kwarg-on-existing-function), recorded here per design Risk R4.

## Problem

gllvmTMB's `delta_lognormal()` / `delta_gamma()` families share ONE linear
predictor across both the occurrence and positive-value components — not two
independent predictors. GLLVM.jl's existing `:separate`-only fitters (`Λz = 0`,
independent `βz`/`βc`) cannot represent this tie, so no fit-vs-fit parity
receipt against the twin's delta families was possible.

## Twin cites (load-bearing)

| Surface | Evidence |
|---|---|
| Design comment | `gllvmTMB.cpp:714-716`: "Delta families share ONE linear predictor for both components: p = invlogit(eta) for presence and mu_pos = exp(eta) for the positive continuous part." |
| delta_lognormal (fid 12) | `gllvmTMB.cpp:2816-2830` — `eta_o` passed unchanged into both `dbinom_robust(x_pres, 1, eta_o, true)` and `dnorm(log(y), eta_o, sigma_t, true)` |
| delta_gamma (fid 13) | `gllvmTMB.cpp:2831-2844` — identical pattern with `dgamma(y, shape_g, scale_g, true)`, `mu_g = exp(eta_o)` |
| Shared `eta` construction | `gllvmTMB.cpp:2661` builds `eta(o)` once, family-agnostically, before the fid dispatch — no second term added for delta rows |
| Offset wiring | `gllvmTMB.cpp:1401`: `eta(o) = eta_fix(o) + offset_vec(o)` — the offset is folded into the SINGLE shared `eta` before any family dispatch, so it hits both parts symmetrically by construction, not by a delta-specific branch |
| R-side hard constraint | `R/fit-multi.R:754-773` aborts on anything but `type="standard"`, `link1="logit"`, `link2="log"` — the shared-η pair is not optional from R |
| Roxygen statement of intent | `R/gllvmTMB.R:151-154, 422-430`: "share one linear predictor under the current implementation… a future release may decouple the two predictors" |

**Consequence:** the twin's tie is a hard, provisional (self-flagged) design
choice, current as of gllvmTMB 0.7.0. Any receipt built against it must pin
that version.

## Julia design (this Identity)

- New kwarg `predictor::Symbol = :separate` on both fitters. Validated
  `∈ (:separate, :shared)`, `ArgumentError` otherwise (same style as the
  existing `hessian::Symbol` validation in this file).
- `:separate` (default): **unchanged** — `θ = [βz; βc; pack(Λc); log(dispersion)]`,
  `Λz ≡ 0`. This is the pre-existing/only behaviour; bit-identical, proven by
  test (`test/test_delta_shared_predictor.jl`, ":separate ≡ omitted").
- `:shared`: `θ = [β; pack(Λ); log(dispersion)]` (fewer free parameters — no
  separate `βz`). The fit driver reconstructs `βz = βc = β`, `Λz = Λc = Λ`
  and calls the **existing, unmodified**
  `delta_lognormal_marginal_loglik_laplace` / `delta_gamma_marginal_loglik_laplace`
  kernel with those tied arguments. No kernel source change — `_twopart_mode`'s
  `A(z) = Λz'diag(Wz)Λz + Λc'diag(Wc)Λc + I` is already the correct curvature
  when `Λz = Λc`, since both parts' curvature genuinely loads on the same `z`
  through the same `Λ` (this is what TMB's joint-Hessian differentiation of
  the single composite `obs_loglik(o, eta(o))` would also produce).
- **Offset symmetry** (twin-matched, `gllvmTMB.cpp:1401`): under `:shared`,
  a supplied `offset` is threaded into BOTH `offsetz` and `offsetc`
  symmetrically (`offsetz = offset, offsetc = offset`), preserving `ηz ≡ ηc`.
  The `:separate` path is unchanged (`offset` → `offsetc` only, `offsetz`
  never set — occurrence stays intercept-only there regardless of offset).
- Warm start under `:shared`: `β0 = 0.5 .* (βz0 .+ βc0)` (average of the
  existing occurrence-logit and positive-meanlog warm starts), `Λ0 = Λc0`
  (existing SVD warm start reused). Arbitrary but adequate — correctness is
  checked by the recovery test, not warm-start quality (design Risk R3).
- Fit structs (`DeltaLogNormalFit`, `DeltaGammaFit`) gain one field,
  `predictor::Symbol`, appended at the end; a positional-compat constructor
  (matching the `hessian::Symbol` precedent) keeps every old 7-arg call site
  (e.g. `families/variational_dgamma.jl`) defaulting to `:separate` unchanged.
  No new `Λz` field — under `:shared`, `f.Λc` IS the shared loadings matrix
  and `f.βz === /== f.βc` element-wise identical; documented in both struct
  docstrings (design Risk R1).

## FD verification gate — not applicable, stated explicitly

Both fitters optimise via `autodiff = :finite` on the whole packed objective
(no hand-coded analytic gradient in this file). The packing change touches no
analytic gradient, so the Engine Quality Battery's FD-verification gate has
nothing new to check for this specific slice (design §3.1). A future
hand-coded shared-η gradient would need its own central-FD check to ≤ 1e-6.

## Verification (this slice)

`test/test_delta_shared_predictor.jl` (wired into `test/runtests.jl` next to
`test_delta_fit.jl`), covering:
1. `:separate` ≡ omitted — bit-identical loglik/params (compat safety net).
2. Invalid `predictor` symbol throws `ArgumentError` (both fitters).
3. `:shared` recovery on data generated under the tied shared-predictor DGP
   (lognormal and gamma), fresh simulator (not the `:separate`-mode
   generator, which ties only through `Λc`/`βc`).
4. The tie is real: `βz == βc`, and the fitted `loglik` equals a direct
   kernel evaluation at `θ̂` with tied arguments (`atol = 1e-8`).
5. `hessian × predictor` composition: `:shared` + `:observed` differs from
   `:shared` + `:fisher` for DeltaGamma (the one family with a specialised
   observed weight — `TWOPART_KNOWN_OPEN`); coincide bit-for-bit for
   DeltaLogNormal, consistent with `test_twopart_hessian_kwarg.jl`.
6. Offset symmetry under `:shared`: a constant per-species offset is fully
   absorbable into `β` (loglik unchanged, `β̂` shifts by `−c`), and a direct
   kernel evaluation with `offsetz = offsetc = offset` at the fitted `θ̂`
   reproduces the fitted `loglik` to `1e-8` — proving the offset actually hit
   both parts, not just `offsetc`.

All green; no existing test's tolerance was touched.

## Out of scope

- `type = "poisson-link"` and the mixture-variant delta families
  (`delta_lognormal_mix`, `delta_gengamma`) — the twin aborts on these
  (`R/fit-multi.R:754-759`); this Identity covers only fid 12/13.
- Fit-vs-fit parity Δ against a live gllvmTMB install — not run in this
  slice (no R session available here); the kernel-Δ / fit-Δ receipt genres
  and the `parity_helpers.jl` wiring described in the build design remain
  future work, to be pinned to gllvmTMB 0.7.0 when executed live.
- Non-Gaussian REML / delta latent-scale advertising — both stay rejected per
  the 2026-08-28 decision batch, unaffected by this change.
- `Λz`/`βz` are NOT separately estimated under `:shared` — the struct field
  layout is unchanged apart from `predictor::Symbol`; a caller reads
  `f.Λc`/`f.βc` as "the one shared predictor" per the updated docstrings.
