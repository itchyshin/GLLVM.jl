# Estimand alignment: communality / correlations / proportions / Omega

Maintainer decision (round 1, item 3;
`docs/dev-log/decisions/2026-09-01-maintainer-decisions-round1.md`):

> **Estimand alignment** (communality/correlations/proportions/Omega):
> align to R's tier-scoped decomposition as the default, mirroring R's
> `level=` arguments; keep the total-variance variant behind an explicit
> option. R is the frozen contract.

This closes the estimand-mismatch family first surfaced in the wave5
surface-conversion batch (`docs/dev-log/core070/surface-conversion-notes.md`,
Repairs 3–5): `extract_communality`, `extract_correlations`,
`extract_proportions`, and `extract_Omega` were each deferred from the
executable oracle batch because GLLVM.jl's TOTAL-variance composition
(`sigma_y_site(fit)`, which folds `σ_eps²` in unconditionally) numerically
disagreed with R's TIER-SCOPED composition (`extract_Sigma(fit, level,
part="total")`, which never folds `σ_eps²` into any `B`/`W`/`phy` tier —
confirmed by reading `extract-sigma.R`/`extract-omega.R` directly).

## What changed (`src/extractors.jl`)

| Function | Old default | New default | Escape hatch |
| --- | --- | --- | --- |
| `extract_communality(fit::GllvmFit)` | `communality(fit)` (total-variance, folds `σ_eps²`) | `level = :unit` — `(Λ_tier Λ_tierᵀ)_tt / Σ_tier,total_tt`, no `σ_eps²` | `level = :total` |
| `extract_correlations(fit::GllvmFit)` | `correlation(fit)` (total-variance) | `level = :unit` — `cov2cor(Σ_tier,total)` | `level = :total` |
| `extract_proportions(fit::GllvmFit; component=:shared)` | `proportions(fit; component=:shared)` (total-variance) | `level = :unit` — `shared_unit / (sum of tiers the fit genuinely carries)` | `level = :total`, or any `component != :shared` (unchanged, forwards regardless of `level`) |
| `extract_Omega(fit::GllvmFit)` | unconditional `Σ_unit + Σ_unit_obs` (`Σ_unit_obs` always adds `σ_eps²·I`, even absent a genuine W tier — the Repair-5 bug) | `level = :auto` — sums only the tiers the fit genuinely carries (tier-presence gate `_r_tier_present`), each tier's total excluding `σ_eps²` | `level = :total` (legacy unconditional sum, bug retained on purpose for backward compatibility) |

`level = :unit_obs` is the within-unit (W) twin for `extract_communality`/
`extract_correlations` (mirrors `communality_W`/`correlation_W` on
`TwoLevelFit`). `level = :site` has no R tier-scoped analogue and is
rejected with `ArgumentError` (`_validate_communality_level`).

New internal helpers (not exported): `_r_tier_total(fit, lvl)`,
`_r_tier_shared(fit, lvl)`, `_r_tier_present(fit, lvl)`,
`_validate_communality_level(level)`. These deliberately duplicate (rather
than reuse) `_sigma_unit`/`_sigma_unit_obs`'s tier composition, because the
existing `_sigma_unit_obs` (backing `extract_Sigma(level=:unit_obs)`) is
GLLVM.jl's own useful extension — it folds `σ_eps²` in unconditionally by
design, per `extract_Sigma`'s own (unchanged) docstring contract — and that
public contract was never part of this alignment decision. Only the
DEFAULTS of `extract_communality`/`extract_correlations`/
`extract_proportions`/`extract_Omega` moved; `extract_Sigma` itself is
untouched.

## Degenerate-fit behaviour is intentional, not a bug

On a fit with only a `:unit` tier and no diagonal Ψ_tier component (e.g.
`has_diag = false`, no W tier) — which is exactly the `gaussian_small`
oracle fixture's shape — the shared and total tiers coincide algebraically
(`Λ_B Λ_Bᵀ == Λ_B Λ_Bᵀ`), so `extract_communality`/`extract_proportions`
degenerate to `1.0` for every trait. This is R's own confirmed behaviour on
such a fit (Repair 3: "`level="unit"` degenerates to an uninformative
constant `1.0`"), reproduced exactly by the new Julia default — not a
regression. Note this does NOT mean `extract_correlations` degenerates to
the identity matrix: when the tier total is a rank-deficient `Λ Λᵀ` (e.g.
`K = 1`), `cov2cor` of a rank-1 matrix is `±1` off the diagonal (perfectly
(anti)correlated), which is mathematically correct, not `I`.

## Oracle provenance

Test oracle constants in `test/test_extractors.jl`'s
`"R-tier-scoped oracle pins (gaussian_small fixture, wave5-conversion7)"`
testset are pinned from
`.unlazy/core070-aghq/wave5-batches/wave5-conversion7/r-oracle.json`,
fixture `gaussian_small` (`p=5, K=2, n=80`, no diag, no W tier):

- Input `y` reproduced exactly (column-major `reshape(p, n)`, matching
  `tools/core070_surface_conversion_batch.jl`'s own convention).
- `Σ_R` pinned from oracle key
  `CORE070-SURFCONV-POSTFIT-POSTFIT-SURFACE-EXTRACT-SIGMA` — R's
  `extract_Sigma(fit_g, level="unit", part="total")$Sigma`.
- `R_R` pinned from oracle key
  `CORE070-SURFCONV-NAMESPACE-EXPORT-GETRESIDUALCOR` — R's
  `getResidualCor(fit_g, level="unit")`, `= cov2cor(Σ_R)` on this fixture.

R and Julia fit **independently** on the identical `y` (R's TMB optimiser,
Julia's LBFGS) — per the paired-independent-fit precedent established in
Repair 3 of `surface-conversion-notes.md`, numeric comparisons use
`atol = 1e-4`, matching the batch contract's own recalibrated tolerance for
`sigma_unit_total`/`residual_cor`
(`docs/dev-log/core070/surface-conversion-batch-contract.json`). Purely
algebraic identities on this fixture (communality/proportions degenerate to
exactly `1.0`; `extract_Omega`'s tier-presence gate) use `atol = 1e-10` —
these do not depend on the two fits agreeing at all.

`extract_Omega`'s oracle check additionally confirms `gaussian_small` has
no genuine `:unit_obs` tier (`_r_tier_present(fit_g, :unit_obs) == false`)
and no phy block, so the R-aligned default correctly reduces to exactly the
`:unit` tier total — matching Repair 5's trace of R's own `tiers = "B"`-only
composition on this fixture.

## Pre-existing bug fixed en route

The uncommitted `src/extractors.jl` edit found on resume (dead agent,
~214-line diff) had a docstring string-interpolation bug at line 364:
`` `extract_Sigma(fit, level = tier, part = "total")$R` `` inside a plain
triple-quoted Julia docstring interpolates `$R` as a variable reference,
raising `UndefVarError: R not defined` at package precompile time — this
broke `using GLLVM` for every agent sharing the worktree. Fixed by escaping
to `\$R`. Flagged by a peer agent (`cloglog-leaf2`) mid-session; confirmed
and fixed before proceeding. Also updated a now-stale sentence in
`extract_cross_correlations`'s docstring ("GLLVM.jl computes one
site-level correlation tier") that predated this decision and no longer
described `extract_correlations`'s own (now tier-scoped) default.

## Verification

`julia --project=. test/test_extractors.jl` — standalone, clean `using
GLLVM` load, 92/92 pass (was 72/75 red on resume: 3 pre-existing failures
from tests asserting the OLD total-variance default, now fixed to assert
the new default explicitly and pin `level = :total` as the escape-hatch
regression check). No full-suite run performed per task scope (standalone
`test_extractors.jl` only).
