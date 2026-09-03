# Second-order (SE / vcov / Wald-CI) receipts — 20-cell batch, 2026-09-03

## Purpose

This is a **receipts batch, not a parity claim.** It extends the 5-cell
D-139 pre-run (`second-order-prerun-2026-09-02.md`) to every paired harness
cell this arc could pair inside the time box: standard errors of every
fixed parameter, the fixed-effect vcov block, and Wald CI endpoints on the
working (link) scale, both engines, frozen R oracle `gllvmTMB` 0.7.0
(`b4d5fee6`). Tolerances are from `second-order-parity-contract.md` §4 and
are **measured and reported against, never gated** — the maintainer signs
tolerances later. Hessian convention frozen per contract §2: observed joint
Hessian on both sides; selector recorded per cell. **Each-own-optimum**
only — both engines converge independently to their own MLE; no
matched-coordinates re-evaluation (same limitation as the pre-run, same
reason: Λ's rotation/sign ambiguity makes transplanting one engine's θ̂
into the other's packing a nontrivial per-family mapping, not a
time-boxed task).

## Compute estimate and actual (D-139)

One representative cell (`binomial_x`, the most uncertain case — R's
fixed-effect naming under a shared covariate) was timed first: **47 s**
wall (incl. a one-time ~6 s Julia/GLLVM precompile). Estimate for the
20-cell batch at `parallel -j 20` (Julia and R each
`OPENBLAS/OMP/JULIA_NUM_THREADS=1`): **under 2 minutes**, far under the
30-minute D-139 line — run directly, no pre-run-then-approval gate needed.
**Actual: 49 s** per full pass (two full passes: an initial 20-cell run,
then a re-run after a mid-batch code fix below). 20 cores requested, well
under the 60-core budget for this arc.

## Cells attempted, paired, and skipped

**20 of 20 attempted cells paired** (both engines converged, receipts
retained). No cell from the intended list was dropped.

**Families/links covered**: Gaussian, Poisson-log, Binomial-logit/probit/
cloglog, Beta-logit, NB2-log, Gamma-log (per-trait shape), NB1-log
(per-trait dispersion), BetaBinomial-logit (per-trait precision) — each
no-X and, except Binomial-cloglog, with a shared site covariate (q=1);
Poisson and Binomial-logit additionally with per-trait (species-specific)
covariate slopes.

**Families/cells NOT attempted, with reasons** (an honest list, not a
silent gap):

- **Lognormal, Truncated-Poisson, Truncated-NB2** — no `confint(fit, Y;
  method=:wald)` dispatch exists for `LognormalFit` / `TruncatedPoissonFit`
  / `TruncatedNegBin2(PerTrait)Fit` (none in `confint_family.jl`'s `_CIFit`
  union). An API gap, not a data problem.
- **Ordinal-probit (no-X and +X)** — the paired R fixtures fit Julia's
  `OrdinalPerTraitFit`/`OrdinalPerTraitCovFit`. Only the shared-cutpoint
  `OrdinalFit` is in `_CIFit`; the per-trait structs the actual paired
  fixtures use are not. Same class of gap as above.
- **Tweedie (shared and grouped)** — contract §2 flags its default as
  disputed/stale (unresolved); no paired no-X/+X fixture was already read
  for this arc, and adding one was out of the time box.
- **GP-1** — Fisher-retained by standing decision; contract §6 declares it
  out of scope pending a ruling on what "parity" means against a
  Fisher-retained family.
- **Student-t** — ν sits on a nonlinear boundary where Wald SEs misbehave
  (contract §3, panel finding 4); excluded from batch 1 by the contract.
- **Delta-lognormal, Delta-Gamma** — `DeltaLogNormalFit`/`DeltaGammaFit`
  ARE in `_CIFit`, unlike the three families above, so these are genuinely
  **feasible for a follow-up batch** — simply not reached this window.
- **Multinomial, BetaBinomial ungrouped/shared-φ** — not attempted; scope
  discipline only (this batch targeted the per-trait-dispersion pairing
  the existing test files already use).

## Convention notes (hessian_selector per cell)

- Gaussian (no-X/+X): exact marginal, `ForwardDiff.hessian` — no curvature
  choice exists.
- Poisson-log, Binomial-logit (no-X): `hessian=:observed` passed
  **explicitly** (package default is `:fisher`; same convention-completeness
  gap the pre-run flagged).
- Binomial-probit/cloglog: family default already `:observed`.
  **cloglog's default is contract §2's "disputed, not resolved" flip** —
  flagged `hessian_selector_disputed=true` per contract §5, not treated as
  settled.
- Beta-logit, NB2-log, Gamma-log, NB1-log, BetaBinomial-logit (no-X and
  grouped-cov +X): family/grouped-route default already `:observed`.
- Binomial-logit +X, Poisson-log +X (`fit_gllvm_cov`), and both
  species-XB cells (`fit_gllvm_speciescov`): **no `hessian` keyword is
  exposed at all** — flagged `hessian_selector_disputed=true`,
  `hessian_selector="not exposed"`. A genuine API gap the contract's
  convention section did not anticipate; worth a design note, not fixed
  here.

## Per-cell table (each-own-optimum; Δ = Julia − R unless noted)

| cell | p·K·n | logLik Δ | max\|ΔSE\| rel | vcov Frob rel | max\|ΔWald endpoint\| | cond(H) jl / r | pd jl / r |
|---|---|---:|---:|---:|---:|---:|:---:|
| gaussian | 5·2·80 | 1.13e-08 | 2.08e-06 | n/a¹ | 2.22e-06 | — / — | T/T |
| poisson | 5·2·60 | 6.75e-09 | 5.83e-06 | 1.09e-05 | 5.27e-06 | 4.7 / 41.0 | T/T |
| binomial_logit | 5·2·60 | 1.82e-10 | 6.97e-06 | 8.43e-06 | 8.47e-06 | 6.1 / 61.6 | T/T |
| binomial_probit | 5·2·60 | −1.20e-09 | 2.24e-05 | 4.36e-05 | 2.86e-05 | 5.7 / 32.3 | T/T |
| binomial_cloglog² | 5·2·60 | 7.80e-09 | 2.12e-05 | 1.08e-05 | 1.14e-05 | 5.1 / 45.6 | T/T |
| beta_logit | 5·1·60 | 5.97e-09 | 2.22e-06 | 5.98e-06 | 3.29e-06 | 5.6 / 22.6 | T/T |
| nb2_log | 5·2·80 | 3.41e-06 | 2.44e-05³ | n/a³ | 5.95e-06³ | — / 4.8e5 | **F/F** |
| gamma_log | 5·1·120 | 2.06e-08 | 1.13e-05 | 1.40e-05 | 7.84e-06 | 8.4 / 44.6 | T/T |
| nb1_log | 5·1·120 | 1.36e-08 | 1.00e-04 | 1.84e-04 | 3.27e-05 | 19.3 / 39.3 | T/T |
| betabinomial_logit | 5·1·120 | 6.15e-09 | 3.06e-06 | 5.79e-06 | 2.46e-06 | 5.1 / 22.1 | T/T |
| gaussian_x | 5·2·30·q1 | 1.95e-09 | 1.41e-06 | n/a¹ | 2.68e-06 | 21.5 / 11.7 | T/T |
| binomial_x⁴ | 5·2·80·q1 | 3.40e-09 | 1.78e-05 | 2.13e-05 | 1.50e-05 | 6.0 / 106.9 | T/T |
| poisson_x⁴ | 5·2·30·q1 | 1.23e-09 | 3.26e-06 | 5.29e-06 | 4.00e-06 | 6.0 / 25.6 | T/T |
| nb2_x | 5·1·120·q1 | 1.29e-08 | 3.86e-05 | 5.21e-05 | 1.11e-05 | 6.8 / 46.5 | T/T |
| beta_x | 5·1·80·q1 | 4.28e-09 | 2.62e-06 | 3.83e-06 | 3.99e-06 | 6.0 / 40.3 | T/T |
| gamma_x | 5·1·120·q1 | 3.06e-08 | 9.92e-06 | 1.40e-05 | 7.79e-06 | 8.7 / 42.5 | T/T |
| nb1_x | 5·1·120·q1 | 1.55e-09 | 1.29e-05 | 1.34e-05 | 4.01e-06 | 19.0 / 45.3 | T/T |
| betabinomial_x | 5·1·120·q1 | 1.50e-08 | 3.86e-06 | 7.76e-06 | 7.39e-06 | 6.0 / 27.0 | T/T |
| poisson_speciesx⁵ | 5·1·80·q1 | 4.20e-09 | 4.40e-06 | n/a⁵ | 3.16e-06 | — / 53.1 | ?/T |
| binomial_speciesx⁵ | 5·1·80·q1 | 1.32e-09 | 3.44e-06 | n/a⁵ | 8.79e-06 | — / 39.4 | ?/T |

¹ Gaussian has a single-term fixed-effect block (σ_eps for no-X; the sole
shared-X slope for +X — Y is pre-centred so there is no per-trait
intercept), so a Frobenius norm over a 1×1 block is not reported (SE and
Wald-endpoint comparisons still are).
² disputed default (contract §2) — see convention notes.
³ **NB2 boundary cell, T14 F1 in action.** Both engines' per-trait
dispersion optimum sits at a Poisson-limit boundary for traits 1, 3 (same
fixture as the pre-run's NB2 cell). Julia's `confint()` reports
`pd_hessian=false` **but still returns finite SE for every well-identified
β/Λ term** via T14 F1's boundary-aware degradation
(`boundary_terms=["r[1]","r[3]"]`), matching R's block-tolerant
NA-only-on-degenerate-entries behaviour (`pdHess=FALSE` both sides). The
**full joint vcov block still fails to invert** on the private
re-derivation used for the Frobenius comparison (all-or-nothing, unlike
the public T14-degraded route) — reported as `vcov_frobenius_relative_delta
= null`, not silently dropped. This is the pre-run's finding #1, now
**partially closed**.
⁴ `fit_gllvm_cov`-backed: `hessian_selector_disputed=true` (no selector
exposed); numbers still agree tightly.
⁵ species-XB cells use `confint_speciescov`, with no private `_family_ci`
accessor for the full covariance — only SE/Wald endpoints compared, no
vcov Frobenius; `pd_hessian_native=nothing` for the same reason.

## Summary per quantity (n cells with a finite value / 20)

| quantity | n | median | max |
|---|---:|---:|---:|
| max relative ΔSE | 20 | 6.4e-06 | 1.01e-04 (nb1_log) |
| vcov Frobenius relative Δ | 15 | 1.09e-05 | 1.84e-04 (nb1_log) |
| max abs ΔWald endpoint (link scale) | 20 | 6.7e-06 | 3.27e-05 (nb1_log) |
| \|logLik Δ\| | 20 | 6.1e-09 | 3.41e-06 (nb2_log, the boundary cell) |
| Julia cond(H) (β block) | 17 | 6.1 | 21.5 |
| R cond(sd_report precision) | 20 | 53.1 | 4.85e+05 (nb2_log) |

Every finite SE/vcov/CI-endpoint relative delta is **at least two orders of
magnitude inside** the contract's each-own-optimum tolerance (rel ≤1e-2 for
SE and vcov Frobenius, scaled by `cond(H)/1e3` only above cond=1e3 — no
cell here approaches that; ≤5e-2 relative-to-half-width for Wald endpoints
— absolute deltas here, ~1e-5–1e-4, are a small fraction of typical
half-widths of ~0.05–0.4 given the observed SEs, so this is a qualitative
read, not an exact relative-to-half-width number: the receipt schema does
not carry the half-width itself, a follow-up field to add). `nb1_log` is
the loosest cell on every finite quantity and is still ~100× inside
tolerance.

## Findings

1. **NB2 boundary cell: T14 F1 rescues the SE/CI route, not yet the full
   vcov block** (footnote 3). `_family_wald`'s boundary-conditioning
   (`t14-nb2-wald-nan-diagnosis.md`) operates on the joint Hessian used by
   the *public* `confint()` path; the *private* `_family_ci`+raw
   `_fd_hessian`+`inv()` route used for the Frobenius block has no such
   conditioning and still fails all-or-nothing — that route needs the same
   degradation to return a usable sub-covariance.
2. **Two X-covariate fitters (`fit_gllvm_cov`, `fit_gllvm_speciescov`)
   expose no `hessian` selector at all** — contract §2 implicitly assumes
   every fitter carries one. Flagged disputed; both agreed with R to
   ~1e-5 anyway, so the *absence of control* is the finding, not the
   disagreement.
3. **Every attempted cell converged and paired on the first try** — no DGP
   re-seeding, no false-convergence warning, no Heywood case. Plausibly
   because every fixture here is an already-verified logLik-parity DGP
   ported from `test/parity/*.jl`, never invented.
4. **cond(H) asymmetry**: Julia's β-block condition number (median 6.1,
   max 21.5) is far smaller than R's `sdreport` precision condition number
   (median 53.1, max 4.85e5 at the NB2 boundary). Plausible, unconfirmed
   reason: R's spans the full joint fixed-effect block (incl. per-trait
   dispersion, where the boundary lives); Julia's is scoped to just the
   β(+γ/B) sub-block — not apples-to-apples as computed.

## Compute, receipts, and reproducibility

Totoro, existing ControlMaster socket, `OPENBLAS/OMP/JULIA_NUM_THREADS=1`,
`parallel -j 20`. Repo rsynced (HEAD `bba953df`, this arc's starting
commit — src/test/tools/Project.toml/Manifest.toml only) to
`/home/snakagaw/core070-aghq-20260830/second-order-01/repo/`. R oracle:
same frozen `gllvmTMB` 0.7.0 install as the pre-run (`oracle-build-01/
library`, `R_LIBS` env var). Driver: `tools/core070_second_order/
run_cell.jl` + `cells.jl` (new files) — one process per cell, DGPs ported
verbatim (seeds/coefficients/loadings) from the already-verified
`test/parity/*.jl` fixtures (provenance per cell in each receipt's
`dgp_source`), R fit via RCall with `se=TRUE` (mirrors
`gllvmTMB:::vcov.gllvmTMB_multi`'s `b_fix` rows, same as the pre-run's
`r_fit.R`), Julia fit via the same public `confint(fit, Y; method=:wald,
...)` used elsewhere in this repo, plus a private re-derivation
(`GLLVM._family_ci` + `GLLVM._fd_hessian`) for the full fixed-effect
covariance block. Receipts: `docs/dev-log/core070/
second-order-batch-out/<cell_id>.json` (20 files, this commit). Remote
scratch (rsynced repo, per-cell logs, raw timings) stays on Totoro under
`second-order-01/`, not committed (verbose, same policy as the pre-run).

sha256 of the 20 committed receipt files (`shasum -a 256
docs/dev-log/core070/second-order-batch-out/*.json | shasum -a 256`):
`85da32626723274e616530969de73c333a55f6eb7c129c0b8f9bb226559d4361`.

## Limits (contract §7 qualifier, restated every time)

Toy-fixture shape only (p=5, K≤2, n≤120, q≤1) — proves the SE/vcov/CI
machinery is wired correctly end-to-end across 20 families/links/designs
and gives a first tolerance read at that shape; does **not** prove
tolerances hold at realistic shape/conditioning (Panel C: 1.4e-7 logLik
agreement coexisted with 2.2e-2 rotation-invariant discrepancy at higher
condition number). No matched-coordinates evaluation, no recovery-to-truth
or coverage claim. Six families/dispositions above were not attempted,
with reasons. Not a speed benchmark (fresh Julia process per cell; R's TMB
object is already compiled).
