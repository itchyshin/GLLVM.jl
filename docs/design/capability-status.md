# GLLVM.jl capability status (twin of gllvmTMB)

Mission Control input for `/p/gllvmTMB/julia-surface`. **GLLVM.jl is a twin of
gllvmTMB**: public capability rows use the **same R vocabulary**
(sources × modes, families, intervals, slopes) so the board shows R↔Julia
alignment. The *code behind* a row may be Julia (closed-form / dense Laplace /
sparse phy / SPDE) rather than TMB — that is an engine difference, not a
different product taxonomy.

Status words (MC parser; counts derived at render time — never hand-typed into
`status/*.json`):

- `implemented` — Julia code under `src/` **and** a test (`test/` and/or gated
  `test/parity/`) for this capability row (or its clear twin analogue).
- `rejected` — deliberately refused, fail-loud, or not advertised.
- `planned` — tracked / designed; no promoted twin-complete implementation yet.
- `missing` — no Julia implementation found for this R-parallel row.

**Rose fence.** Intended API similarity ≠ full parity claim.

- Light gllvmTMB logLik: named-route **63/63** + shared site-X
  Gaussian/Binomial/Poisson **18/18** + NB2+X/Beta+X **16/16** (#177) +
  **Gamma+X** light cell (per-trait α, observed Laplace; Δ≈3e-8) +
  **Ordinal+X** light cell (per-trait cutpoints + shared γ, `ordinal_probit`;
  Δ≈5e-9) + **NB1+X** light cell (per-trait φ, observed Laplace; abs Δ≈1.53e-9,
  seed=48; #186) + **Poisson species-XB** light cell (`(0+trait):x` /
  `fit_gllvm_speciescov`; Δ≈4e-9) + **BetaBinomial+X** light cell (per-trait φ,
  trials `N`, finite-difference outer Laplace; abs Δ≈1.50e-8, seed=49). Engine
  Arc 1 lands per-trait NB2/Beta/Gamma/NB1/BetaBinomial+X and Ordinal+X. Not
  full family parity; ADEMP and coverage certificates remain fenced.
- R-bridge (`engine = "julia"`) rows that are live are still **partial** vs the
  public R-user surface even when Status = `implemented`.
- Phylo Model A / source-specific `lv` intervals: **rejected** for advertising.
- Prefer reading this beside R `/p/gllvmTMB/surface` — gaps should stay visible
  as `planned` / `missing` / `rejected`, not renamed away.

## Covariance structure grid (sources × modes)

R grammar: source ∈ {none, phylogenetic, animal, spatial, kernel} × mode ∈
{indep, dep, latent} (+ `common = TRUE` / `unique = TRUE` modifiers). Julia
exposes twin capabilities under native fitters; engine notes in parentheses are
implementation detail only.

| Capability | Status |
|---|---|
| none × indep (`indep()` / ordinary independent RE) | implemented |
| none × dep (`dep()` / unstructured trait covariance) | planned |
| none × latent (`latent()` / ordinary LV GLLVM) | implemented |
| phylogenetic × indep (`phylo_indep()`) | implemented |
| phylogenetic × dep (`phylo_dep()`) | planned |
| phylogenetic × latent (`phylo_latent()`) | implemented |
| animal × indep (`animal_indep()`) | implemented |
| animal × dep (`animal_dep()`) | planned |
| animal × latent (`animal_latent()`) | planned |
| spatial × indep (`spatial_indep()`) | implemented |
| spatial × dep (`spatial_dep()`) | planned |
| spatial × latent (`spatial_latent()`) | implemented |
| kernel × indep (`kernel_indep()`) | planned |
| kernel × dep (`kernel_dep()`) | planned |
| kernel × latent (`kernel_latent()`) | planned |
| phylo_latent + `lv = ~ x` (Phylo Model A public intervals) | rejected |

Notes (not status rows): Julia phylo rows share three **equivalent** likelihood
representations (sparse CHOLMOD, contrasts, edge-incidence). Gaussian animal/spatial
today enter via `relatedness_cov` / `spatial_cov` (and SPDE latent for
non-Gaussian `spatial_latent`). `none × indep` maps to random row effects /
per-trait diagonal paths; full unstructured `dep()` without LV is still a gap.

## Response families

Twin family names align with gllvmTMB / gllvm. Status = native Julia engine
(with tests). Bridge partiality is under **R bridge**, not hidden by renaming.

| Capability | Status |
|---|---|
| gaussian | implemented |
| poisson | implemented |
| nbinom2 | implemented |
| nbinom1 | implemented |
| binomial | implemented |
| betabinomial | implemented |
| beta | implemented |
| Gamma | implemented |
| tweedie | implemented |
| ordinal_probit / cumulative_logit | implemented |
| student | implemented |
| lognormal | planned |
| truncated_poisson | implemented |
| truncated_nbinom2 | planned |
| censored_poisson | missing |
| multinomial / categorical | missing |
| delta_gamma | implemented |
| delta_lognormal | implemented |
| hurdle_poisson / hurdle_nbinom2 | implemented |
| zip / zinb / zib | implemented |
| ordered_beta / beta_hurdle | implemented |
| exponential (Gamma shape=1 path) | implemented |
| com_poisson | implemented |

Notes (not status rows): `zip` / `zinb` / `zib` are Julia-forward (ZIP+X via
`fit_zip_gllvm_cov`; ZINB+X via `fit_zinb_gllvm_cov`, shared scalar `r`);
twin gllvmTMB cut ZIP/ZINB — **no** invent twin light Δ. Status cells stay
bare MC tokens. `zib` also has a native Julia ZIB+X fitter (`fit_zib_gllvm_cov`) with dual shared slopes (`γz`, `γc`), `Λ_z = 0`, and one shared scalar `N::Int`; this is Julia-forward only—no `fit_gllvm`, `@formula`, bridge, CI-under-X, or gllvmTMB parity claim.
`student` / `com_poisson` promoted on native engine + package
tests (`test_studentt.jl`, `test_com_poisson.jl`). `truncated_poisson` =
zero-truncated Poisson (Identity 2026-08-15; twin fid 10); `truncated_nbinom2`
remains planned (contingent).

## Intervals and estimation evidence

| Capability | Status |
|---|---|
| Point extraction (coef / loadings / Σ_y / correlations) | implemented |
| Wald intervals | implemented |
| Profile-likelihood intervals | implemented |
| Parametric bootstrap intervals | implemented |
| Simulation-validated coverage certificate (broad grid) | missing |
| Light gllvmTMB logLik named routes (63/63) | implemented |
| Shared-X light logLik Gauss/Bin/Pois (18/18) | implemented |
| ML default (Gaussian closed-form / non-Gaussian Laplace) | implemented |
| REML (Gaussian pilot twin) | planned |
| AGHQ estimator | missing |
| VA / ELBO alternative (selected families; not R-default) | implemented |

Notes (not status rows): Gaussian REML code exists (`src/reml.jl`,
`fit_gaussian_reml`, bridge `reml=true` path) but **no dedicated package test**
exercises the REML criterion — keep `planned` (OWED: add `test_reml.jl` before
promote). Twin admits Gaussian-only REML pilot.

## Random slopes and special capabilities

| Capability | Status |
|---|---|
| Fixed-effect covariates `X` (shared site design) | implemented |
| Species-specific environmental coefficients | implemented |
| Fourth-corner / trait–environment | implemented |
| Row effects fixed | implemented |
| Row effects random | implemented |
| Per-species / grouped dispersion (`disp.group`) | implemented |
| Keyworded random slopes (≥1) | planned |
| Uncorrelated slope (R double-bar / uncorrelated RE) | planned |
| Missing responses (NA / mask) | implemented |
| Missing predictor `mi()` | planned |
| Latent scores on covariates `latent(..., lv = ~ x)` ordinary | implemented |
| Concurrent / constrained / RRR ordination (`num.lv.c` / `num.RR`) | implemented |
| Quadratic response | implemented |
| Mixed-family response vector | planned |
| `@formula` / long+wide data (fixed effects) | implemented |

## R bridge (`engine = "julia"`)

Same twin surface, transport layer. Status = code + bridge/parity test exist;
**every live bridge family remains partial vs full R-user parity.**

| Capability | Status |
|---|---|
| Bridge capability ledger + drift probe | implemented |
| Bridge no-X point fit (core one-part families) | implemented |
| Bridge fixed-effect X (selected families) | implemented |
| Bridge missing-response mask (selected families) | implemented |
| Bridge CI transport Wald/profile/bootstrap (selected) | implemented |
| Bridge predictor-informed `lv` / `X_lv` (selected) | implemented |
| Bridge mixed-family vector | implemented |
| Bridge full family × full structure parity | rejected |
| Bridge phylo / animal / spatial / kernel source parity | planned |
| Bridge Phylo Model A / source-specific `lv` advertising | rejected |

## Withdrawn and deferred (twin fences)

| Capability | Status |
|---|---|
| Full family R↔Julia parity claim | rejected |
| Phylo Model A public interval promotion | rejected |
| Delta/hurdle latent-scale correlation advertising | rejected |
| Non-Gaussian REML | rejected |
| Broad AGHQ (Julia) | missing |

## Evidence pointers

- R surface (compare side-by-side): `/p/gllvmTMB/surface` ←
  `gllvmTMB/docs/dev-log/capability-surface.html`
- Light logLik 63/63: `docs/dev-log/handover/2026-08-01-cursor-handover.md`
- Shared-X 18/18: `docs/dev-log/after-task/2026-08-02-x-covariate-light-loglik.md`
- NB1+X engine (bridge/`@formula`/`fit_nb1_gllvm_grouped_cov`):
  `docs/dev-log/after-task/2026-08-05-nb1-x-engine-arc12.md` — light RCall
  cell live Δ abs ≈1.53e-9 @ rtol 1e-6 (seed=48; ≠ full family parity)
- BetaBinomial+X engine (bridge/`@formula`/`fit_beta_binomial_gllvm_grouped_cov`):
  `docs/dev-log/after-task/2026-08-05-betabinomial-x-engine-arc12.md` — light
  RCall cell live Δ abs ≈1.50e-8 @ rtol 1e-6 (seed=49; ≠ full family parity)
- ZIP+X engine (bridge/`@formula`/`fit_zip_gllvm_cov`; Identity 2026-08-09):
  `docs/dev-log/after-task/2026-08-09-zip-x-engine.md` — Julia identity/FD only;
  **no** twin light Δ (gllvmTMB ZIP cut)
- ZINB+X engine (bridge/`@formula`/`fit_zinb_gllvm_cov`; Identity 2026-08-13):
  `docs/dev-log/after-task/2026-08-14-zinb-x-engine.md` — Julia identity/FD only;
  shared scalar `r`; **no** twin light Δ (gllvmTMB ZINB cut)
- ZINB+X confint under X (`confint(ZINBCovFit)`; FD Hessian; `ci_x_*` true):
  Julia CI claim only ≠ twin Δ ≠ ADEMP
- truncated_poisson Identity + engine (zero-truncated; twin fid 10):
  `docs/dev-log/decisions/2026-08-15-truncated-poisson-identity.md` ·
  `src/families/truncated_poisson.jl` · `test/test_truncated_poisson.jl`
- student / com_poisson ledger promote: `test/test_studentt.jl`,
  `test/test_com_poisson.jl` (code already present)
- REML OWED: `src/reml.jl` present; dedicated package test still missing
- Public catch-up prose: `docs/src/gllvmtmb-parity.md` (Documenter legend ≠ this
  MC vocabulary)
