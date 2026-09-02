# Second-order (SE / vcov) pre-run vs frozen R oracle — 2026-09-02

## Purpose

D-139 time-boxed (≤30 min compute) PRE-RUN comparing **second-order**
quantities (Wald SEs, fixed-effect vcov, Wald CI endpoints) between the
frozen R oracle and Julia on the five smallest already-paired parity
fixtures (Gaussian, Poisson-log, Binomial-logit, Beta-logit, NB2-log).
**A 5-cell TOY-FIXTURE pre-run, not a parity claim** — no tolerance is
asserted or gated; every discrepancy below is a finding with a
hypothesis, nothing was tuned.

## Host / environment / oracle receipt

Totoro (`snakagaw@totoro.biology.ualberta.ca`), existing ControlMaster
socket only, ≤8 cores requested (single-threaded fits:
`OPENBLAS/OMP/JULIA_NUM_THREADS=1`). Julia `+1.10.10`; repo rsynced
from the current worktree (`df7009b3`) into
`/home/snakagaw/core070-aghq-20260830/se-prerun-01/repo` (fresh
`src/tools/test/Project.toml/Manifest.toml`, not the older
`suite-run-01` tree). R oracle: `gllvmTMB` **0.7.0**, frozen commit
`b4d5fee64def88bc768dda1f1f77c29b295edd86` — confirmed via the
installed `CORE070_SOURCE_PIN.toml` in
`oracle-build-01/library/gllvmTMB` (matches `_CORE070_REFERENCE_COMMIT`
in `test/parity/parity_helpers.jl` exactly; `RemoteSha` is NA — the pin
file is the authoritative receipt). Working dir new
(`se-prerun-01/`); the running 120-core ZI campaign in `zi-ademp-01`
was untouched.

## Convention (frozen by the orchestrator)

Observed joint Hessian on both sides.

- **R**: `control = gllvmTMBcontrol(n_init=1L, se=TRUE)`. SEs/vcov read
  directly from `fit_r$sd_report$par.fixed` / `$cov.fixed` (the same
  slot `gllvmTMB:::vcov.gllvmTMB_multi` indexes by `b_fix` rows) —
  used directly rather than `tidy(..., effects="ran_pars")`, which
  returned `estimate` but no `std.error`/CI columns for this model
  class on this build (a usability note, not chased further here).
- **Julia**: `confint(fit, Y)` (family-generic Wald route,
  `objective=:laplace` internally, i.e. FD Hessian of the fitted
  marginal negative log-likelihood at Julia's own MLE — the "observed"
  Hessian of the fitted objective).
- **Per-family selector actually used**: Gaussian — no Laplace
  approximation exists (exact marginal likelihood); `confint` uses
  `ForwardDiff.hessian` on the exact NLL, no `hessian` kwarg applies.
  Poisson-log, Binomial-logit — `hessian=:observed` passed
  **explicitly** to `fit_poisson_gllvm`/`fit_binomial_gllvm`; the
  package's own default for these two (LogLink/LogitLink) is `:fisher`
  (`_default_hessian(family,link)=:fisher` fallback in
  `src/families/laplace.jl`, no override exists yet for these two
  pairs) — overriding to `:observed` was needed to match the frozen
  convention. Beta-logit, NB2-log — `fit_gllvm(...; family=Beta()/
  NegativeBinomial())` dispatch to the grouped (`disp_group=:species`)
  fitters, whose package default is already `hessian=:observed`
  (`src/families/grouped_dispersion.jl`) — no override needed.
- **Matched-coordinates**: **NOT done for any cell.** Both engines were
  fit independently to their own MLE; Julia's Hessian was *not*
  re-evaluated at R's optimum, since Λ carries a rotation/sign
  ambiguity and transplanting R's θ̂ into Julia's packed
  parameterisation is a nontrivial per-family mapping, not a
  30-minute-compute-box task. The comparisons below compare each
  engine's own SE/vcov at its own (independently converged) MLE —
  weaker than a matched-coordinates comparison, stated explicitly.
- **Rotation handling**: raw Λ SEs are **not** compared (rotation/sign
  non-identifiable, per `test/parity/README.md`). Only rotation-safe
  blocks are compared: the per-trait intercept block (`beta[1..p]` /
  R's `b_fix`) and, for Gaussian, `sigma_eps` (plus its Λ+σ 10×10 vcov
  block, included only because it happened to land without a rotation
  in this run — not asserted as a general invariant).

## Per-family results

| family | n p K seed | logLik Δ (jl−r) | max&#124;ΔSE&#124; | max rel ΔSE | vcov rel Frobenius (β-block) | max&#124;ΔWald endpoint&#124; | matched-coords? | R wall (fit) | Julia wall (fit) |
|---|---|---:|---:|---:|---:|---:|:---:|---:|---:|
| gaussian | 80 5 2 42 | 4.13e-09 | 4.65e-08 | 1.02e-06 | 6.46e-06 | 9.20e-07 | NO | 0.628 s | 9.383 s |
| poisson  | 60 5 2 44 | 6.78e-09 | 7.80e-07 | 5.83e-06 | 1.09e-05 | 5.27e-06 | NO | 0.598 s | 10.753 s |
| binomial | 60 5 2 43 | 1.36e-10 | 1.93e-06 | 4.49e-06 | 7.76e-06 | 5.92e-06 | NO | 0.627 s | 11.764 s |
| beta     | 60 5 1 45 | 5.95e-09 | 1.45e-07 | 2.22e-06 | 5.98e-06 | 3.29e-06 | NO | 0.715 s | 5.160 s |
| nb2      | 80 5 2 45 | 3.22e-06 | **NaN (see notes)** | NaN | NaN | NaN | NO | 0.910 s | 7.600 s |

(gaussian's ΔSE/Frobenius columns compare `sigma_eps` SE plus the
10×10 (`sigma_eps`,Λ) vcov block — Gaussian has **no** β/intercept
block, see notes.)

Julia `confint()` wall time (separate from "Julia wall (fit)" above):
gaussian 5.86 s, poisson 1.95 s, binomial 1.55 s, beta 1.43 s, nb2
1.71 s. R's `sd_report` extraction is ~0.0001–0.0002 s in every cell
(folded into R's fit wall time, not timed separately). **Not a
benchmark**: every Julia call is a fresh process, so its wall time
includes full JIT/compile overhead, unlike R's already-compiled TMB
object — not a speed comparison in either direction.

## Per-family notes (β SE vectors, trait order t1..t5; ≤ 12 params/family)

### gaussian (seed=42, p=5, K=2, n=80, Y pre-centred)

Gaussian fit here (`fit_gaussian_gllvm`) has **no β** — Y is centred
per trait so the Julia model is zero-mean; R still fits
`0 + trait` intercepts (all ≈ 1e-11, i.e. correctly recovering ≈0), so
the β/intercept block is **not comparable across engines for this
fixture** (Julia has no such parameter). Compared instead: σ_eps
(log-scale SE) and the Λ+σ_eps vcov block.

`sigma_eps` se (log-scale): Julia 0.0456435465 vs R (`log_sigma_eps`)
0.0456434999. Λ SEs (natural scale) also matched closely (e.g.
Λ_B[1,1]: Julia 0.10933198 vs R 0.10933195) — reported for
completeness, not asserted as a general rotation-invariance guarantee
(see Convention above). pd_hessian=true both sides.

### poisson (seed=44, p=5, K=2, n=60)

Julia β SE (t1..t5): 0.08737499, 0.08588857, 0.13388186, 0.06978187,
0.07748599. R β SE: 0.08737507, 0.08588868, 0.13388108, 0.06978183,
0.07748604. pd_hessian=true both sides.

### binomial (seed=43, p=5, K=2, n=60, Bernoulli)

Julia β SE (t1..t5): 0.29580939, 0.29377031, 0.40219056, 0.42953289,
0.31250498. R β SE: 0.29581024, 0.29377111, 0.40218905, 0.42953481,
0.31250477. pd_hessian=true both sides.

### beta (seed=45, p=5, K=1, n=60, per-trait φ)

Julia β SE (t1..t5): 0.07677626, 0.06643672, 0.08156615, 0.06528346,
0.07327444. R β SE: 0.07677615, 0.06643679, 0.08156624, 0.06528331,
0.07327453. pd_hessian=true both sides.

### nb2 (seed=45, p=5, K=2, n=80, per-trait r)

Both engines fit a **boundary/degenerate** per-trait dispersion for
traits 1 and 3 (huge r: Julia r[1]=2.53e20, r[3]=8.99e9; R's matching
`log_phi_nbinom2`=18.86, 13.95, i.e. φ≈1.55e8/1.14e6 — effectively
Poisson-like for those two traits at n=80). **R**
(`sd_report$cov.fixed`, block-wise): `log_phi_nbinom2` SE is `NA`
**only** for the two degenerate traits; every other parameter (all 5
β, all 9 Λ, the 3 well-behaved `log_phi`) still returns a **finite**
SE (β SEs: 0.0853, 0.1090, 0.1296, 0.1027, 0.1162). **Julia**:
`confint(fit, Y)` computes one 19×19 joint FD Hessian and inverts it in
one shot; that inversion throws `SingularException`, and `confint`'s
own try/catch marks `pd_hessian=false`, returning **NaN for every
parameter's SE** — including the 5 β and 9 Λ that are individually
well-identified. logLik Δ=3.22e-6 (larger than the other cells'
~1e-8–1e-9 but still tiny in absolute terms — plausibly each
optimizer's own stopping tolerance at a near-boundary optimum, not
chased further here).

## Findings (each with a hypothesis, none "fixed")

1. **NB2: whole-vector NaN SE vs R's block-tolerant NaN.** At a
   near-boundary per-trait dispersion optimum (r/φ → huge for traits
   1, 3), R's TMB `sdreport()` still returns finite SEs for every
   well-identified parameter, NaN-ing only the two degenerate
   `log_phi` entries. Julia's generic `confint(fit, Y)` inverts one
   monolithic 19×19 joint FD Hessian; one near-singular block anywhere
   in it fails the whole `inv()` (`SingularException`), propagating NaN
   to unrelated, well-identified β/Λ entries too. **Hypothesis**:
   TMB's `sdreport()` likely uses a generalized/pseudo-inverse or
   per-block extraction that degrades gracefully, while Julia's
   `_family_wald`/`_fd_hessian`+`inv(Symmetric(...))` degrades
   all-or-nothing — a genuine SE-availability gap on a boundary
   fixture, not a point-estimate defect (logLik and β estimates both
   still matched to ~1e-6 relative). Nothing was changed to pass this.
2. **Poisson-log / Binomial-logit ship without an `:observed` default.**
   `_default_hessian(family,link)=:fisher` is the only applicable rule
   for these two pairs — no override exists yet (unlike Beta/LogitLink,
   NB2/LogLink, Gamma/LogLink, which all declare `:observed`). This
   pre-run passed `hessian=:observed` explicitly to match the frozen
   convention; a caller who omits it silently gets Fisher-weighted
   curvature instead. Not a disagreement here (`:observed` agreed with
   R to ~1e-6) — a convention-completeness gap, not an urgent defect.
3. **Gaussian has no β for this fixture.** The oracle cell centres Y
   and fits a zero-mean Julia model against R's `0+trait` formula; R's
   fitted intercepts are (correctly) ≈0 with real SEs, but Julia has no
   matching parameter. Any reuse toward a "β SE parity" claim for
   Gaussian must first decide whether to compare R's (near-zero)
   intercept SEs at all, or restrict Gaussian to σ_eps/Λ as done here.
4. All four non-degenerate cells (gaussian σ_eps, poisson, binomial,
   beta) agree at **≤1.1e-5 relative** on SE, vcov Frobenius, and Wald
   endpoints, at **unmatched** (independently-converged) coordinates —
   consistent with, but weaker than, a matched-coordinates claim.

## Remote paths

Repo (rsynced, `df7009b3`, not `suite-run-01`):
`.../se-prerun-01/repo/`. Scripts: `.../se-prerun-01/scripts/`
(`gen_data.jl`, `julia_fit.jl`, `r_fit.R`). Fixture CSVs
(byte-identical inputs to both engines):
`.../se-prerun-01/repo/data/{gaussian,poisson,binomial,beta,nb2}.csv`.
Raw per-family outputs: `.../se-prerun-01/repo/out/*_{julia,r}_*.{txt,csv}`
(all under `/home/snakagaw/core070-aghq-20260830`). Local copy of
`out/`: `.../8341dc72-fc11-4347-8e97-3c240c3b8802/scratchpad/out/`.

## Limits

Five ordinary loadings-only no-X cells, smallest fixtures only, no
recovery/coverage claim, no matched-coordinates evaluation, no fix
applied to the NB2 finding, no engine change. Not a parity gate, not a
speed benchmark. Λ SEs reported for Gaussian only as an observation,
not a general rotation-invariant comparison.
