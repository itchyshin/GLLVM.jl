# gllvmTMB 0.7.0 → 0.7.1 catch-up gap sheet

Author: Hopper (R↔Julia translator, read-only recon)
Scope: `git diff b4d5fee..origin/main` restricted to `R/`, `src/`, `NAMESPACE`,
`DESCRIPTION`, `man/` in `/Users/z3437171/Dropbox/Github Local/gllvmTMB`
(protected reference repo — READ ONLY, no checkouts performed), plus
`git log --oneline b4d5fee..origin/main` (172 commits) for feature framing.

Frozen reference: `b4d5fee64def88bc768dda1f1f77c29b295edd8` (tagged 0.7.0).
Target: `origin/main` = `101fafcc3c9d08c938d3589f242205ee2b831d70` (0.7.1
candidate; `DESCRIPTION` version bumped 0.7.0 → 0.7.1 in this range).

Diff footprint restricted to the scoped paths: 59 files changed, +4625/−730
across `DESCRIPTION`, `NAMESPACE`, 33 `R/*.R` files, 24 `man/*.Rd` files, and
`src/gllvmTMB.cpp` (+297/−… ).

## Summary counts

| Class | Count | Notes |
| --- | --- | --- |
| 1 — NEW public capability | 9 | 8 new exported R functions (response-column coefficient/slope family) + 1 new `gllvmTMB()` argument (`column_data`) |
| 2 — BEHAVIOR change to existing capability | 3 | interval-certificate claim rewrite (DESCRIPTION + profile-derived docs), `sigma_eps` parameterization split (Gaussian/lognormal), Gaussian cell-effect / column-coefficient TMB template gating |
| 3 — BUGFIX that could change frozen-oracle numbers | 1 | `V_t = (ΛΛᵀ)_tt + ψ_t` → `+ ψ_t²` fix in total-variance profile/derived-CI math (`R/profile-derived.R`, `R/extract-sigma.R`) |
| 4 — internal/docs-only | remainder (~159 commits) | iJSDM diagnostic hardening, interval-calibration campaign receipts/plumbing, CI runner bump (Node 20→24), tree-axis article corrections, animal/Gaussian coefficient repair commits scoped to the new column-coefficient feature, Windows test portability fixes |

No commit in this range touches the base single-family, single-`σ_eps`,
non-phylogenetic-slope Gaussian likelihood path or the sparse-phylogenetic
precision math that GLLVM.jl's frozen 0.7.0 speed/parity oracle exercises.

## Class-1 table — NEW public capability

| R surface | Description | Commit(s) | Affects Julia twin's frozen 0.7.0 oracle? |
| --- | --- | --- | --- |
| `column_coef()` | New export: IID random response-column coefficient basis (`R/column-coef-foundation.R`, 1033 new lines) | `e957e7888` feat: add inert response-column coefficient foundation; `889dc6b5e` test; `77afa7362` fix | NO — brand-new R-only formula-grammar surface with no Julia counterpart yet (GLLVM.jl has no `@formula`/column-coefficient family). Does not touch code paths GLLVM.jl compares against. |
| `phylo_coef()` | New export: phylogenetic response-column coefficients (fixed or estimated ρ) | `4e38af6dc` feat: add internal fixed-rho phylo coefficients; `0cdc8ec90` feat: add public response-column coefficients | NO — same reasoning as above |
| `animal_coef()` | New export: pedigree/relationship-matrix response-column coefficients | `b8387bd46` feat: add animal response-column coefficients | NO |
| `kernel_coef()` | New export: dense-kernel response-column coefficients | `bff33d7ff` feat: add kernel response-column coefficients | NO |
| `spatial_coef()` | New export: SPDE-mesh response-column coefficients | `1abdab68c` feat: add spatial response-column coefficients | NO |
| `slope()` | New export: ordinary (non-structured) response-column slope helper, RHS resolves to the response-column factor | `7d38ce2fe` feat: complete response-column slope family; `235c32a8a` feat: complete fixed response-column slope helpers | NO |
| `kernel_slope()` | New export: fixed-kernel response-column slope | part of `503ea6671`/`efc4cffc0` column-slope-family PR chain | NO |
| `spatial_slope()` | New export: SPDE-mesh response-column slope | same PR chain | NO |
| `gllvmTMB(..., column_data = NULL)` | New argument: optional keyed response-column metadata joined into fixed effects (cannot be a coefficient basis/grouping/covariance source) | within `R/gllvmTMB.R` diff (doc block + arg added, no isolated single-purpose commit found in the 31-commit path-scoped subset) | NO — additive optional argument, default `NULL` preserves old call signature and behavior |

`NAMESPACE` diff also confirms these 8 new `export(...)` lines are the entire
set of newly exported symbols in this range (no other new exports, no
removed exports).

## Class-2 table — BEHAVIOR change to an existing capability

| R surface | Description | Commit(s) | Affects Julia twin's frozen 0.7.0 oracle? |
| --- | --- | --- | --- |
| Interval/coverage claim surface (`DESCRIPTION`, `R/profile-derived.R`, `R/extract-sigma.R` roxygen blocks, `R/coverage-study.R`) | Complete rewrite of the package's interval-calibration claim. 0.7.0 claimed "one narrowly scoped two-sided Gaussian total-variance profile regime has a documented 0.94 coverage floor." 0.7.1 claims "Broad ... coverage is not certified. Three exact native, pinned, unrotated ordinary-Gaussian standardized-loading Wald cells have target-specific certificates ... conditional on eligible fits; total-variance penalty profiles remain route-only." The certified regime moved from a total-variance *profile* claim to a *standardized-loading Wald* claim over 3 named cells `(n_units=150,d=2)`, `(n_units=400,d=1)`, `(n_units=400,d=2)`; the `(n_units=150,d=1)` cell explicitly *failed* its lower-band gate and the old total-variance profile route (`.total_variance_in_certified_regime`, "CERTIFICATE CANDIDATE") is demoted to "ROUTE-ONLY PENALTY-PROFILE APPROXIMATION" and its certification-predicate function is deleted. | ~120 commits in the "interval calibration" campaign, e.g. `bc9df28ce` Close interval calibration programme, `b600b019c` Fail closed interval calibration claims, `de9d960ce` Adjudicate interval calibration claims, `4cfb2ea27` Make interval target evidence replayable | **YES, but narrowly** — GLLVM.jl's `confint.jl`/`confint_derived.jl`/`confint_derived_wald.jl` module docs and any dev-log provenance notes that cite gllvmTMB's coverage-certificate wording (e.g. "0.94 coverage floor") should be checked and updated; the certified-regime *definition* changed shape (profile→Wald, different cell grid). This is a documentation/claim-surface risk, not a numeric-kernel risk for the frozen Gaussian speed oracle itself. |
| `sigma_eps` parameterization (`src/gllvmTMB.cpp`, `R/gllvmTMB.R` docs) | `PARAMETER(log_sigma_eps)` (scalar) → `PARAMETER_VECTOR(log_sigma_eps)`. Previously one scalar `sigma_eps` was shared across *all* Gaussian and lognormal rows in a fit. Now: a pure Gaussian-only or pure lognormal-only fit still gets exactly 1 slot (`sigma_eps(0)`, `expected_sigma_slots == 1`); a fit that mixes Gaussian *and* lognormal families in the same call now gets 2 slots — a separate raw-scale Gaussian `sigma_eps_gaussian = sigma_eps(0)` and log-scale lognormal `sigma_eps_lognormal = sigma_eps(1)`. | commit not isolated in the 31 path-scoped commits; bundled inside the large `column-coef`/Gaussian-cell-effects PR chain (`853daf5f0` fix: integrate Gaussian cell effects with compatible conditional outputs; `2e10e3fb0` fix: stabilize coefficient prior through triangular whitening) | NO for GLLVM.jl's current scope — the Julia twin implements pure Gaussian (single family) only; no mixed Gaussian+lognormal fit exists in GLLVM.jl, so `expected_sigma_slots == 1` always applies and the scalar-`sigma_eps` numerics GLLVM.jl's oracle depends on are unchanged. Flag as future-relevant only if/when a lognormal family or mixed-family fit is ported. |
| Gaussian "diag_B" cell-effect integration / column-coefficient standardization gating (`src/gllvmTMB.cpp`: new `integrate_gaussian_diag_B`, `standardize_column_coef`, `use_column_coef_estimated_rho`, `eta_column_coef_rho` params + fence blocks) | New TMB-template data flags and hard `error()` fences admitting "exact scalar Gaussian convolution" and "standardized Gaussian coefficient composition" only for a narrow, fully-enumerated set of feature combinations (no AGHQ, no REML, no spatial/kernel/diag-species/etc. terms active simultaneously). This is new machinery layered under the new `column_coef()`/`animal_coef()`/etc. family, not a change to any existing default code path — the flags are 0 (no-op) unless a new coefficient formula is used. | `8cd7a18d6` fix: standardize Gaussian column coefficients with physical outputs; `008a679e1` fix: preserve constrained fits and Gaussian warm-start compatibility; `853daf5f0` fix: integrate Gaussian cell effects with compatible conditional outputs | NO — every new flag defaults to an explicit no-op (`0`) and the fence blocks only activate when the *new* column-coefficient formula grammar is used, which GLLVM.jl does not exercise. |

## Class-3 table — BUGFIX that could change frozen-oracle numbers

| R surface | Description | Commit(s) | Affects Julia twin's frozen 0.7.0 oracle? |
| --- | --- | --- | --- |
| Total-variance formula: `V_t = (ΛΛᵀ)_tt + ψ_t` → `V_t = (ΛΛᵀ)_tt + ψ_t²` | `R/profile-derived.R` and `R/extract-sigma.R` (roxygen `@details`, inline comments, and the `cli_abort` guidance text) previously wrote the per-trait total variance as `(ΛΛᵀ)_tt + ψ_t` — i.e. adding the *unique standard deviation* directly rather than its square (the unique *variance*). 0.7.1 corrects every occurrence to `+ ψ_t²`. This is the quantity underlying `profile_ci_total_variance()` / `extract_Sigma()`'s total-variance derived CI, and the certificate-predicate rewrite above is entangled with this fix (the old "CERTIFICATE CANDIDATE" profile route is simultaneously demoted, likely *because* its target quantity was wrong). | Bundled inside the interval-calibration campaign (no single isolated commit found scoped to just this formula fix within the 31 path-scoped commits; the fix is visible as a doc/comment-string change co-committed with certificate-predicate removal, e.g. within the range covering `b600b019c`…`bc9df28ce`) | **YES — flag for verification, mark UNCERTAIN pending direct check of GLLVM.jl's own formula.** GLLVM.jl's own `packing.jl`/`likelihood.jl` conventions build `Σ_y = ΛΛᵀ + diag(ψ²)` (variance, not SD) per this repo's own docs, so GLLVM.jl's implementation was very likely already correct and unaffected by this R-side bug. But: (a) if any GLLVM.jl dev-log parity note records a total-variance-CI numeric comparison against the frozen 0.7.0 R oracle, that R number was computed with the `+ ψ_t` bug and should NOT be treated as ground truth without re-deriving; (b) `docs/dev-log/decisions/` should be checked for any note that ported this specific R formula string verbatim. Recommend a `grep -rn "psi_t" docs/dev-log/` sanity pass in GLLVM.jl before trusting any existing total-variance parity claim frozen against 0.7.0. |

## Verdict

**Does anything in 0.7.1 invalidate qualifying GLLVM.jl against the frozen
0.7.0 R oracle first?** No, for the specific numeric surface GLLVM.jl
currently claims parity on (single-family Gaussian marginal log-likelihood,
point estimates, and the phylogenetic-precision representations). Every
class-1 item is a brand-new R-only formula-grammar surface with zero Julia
counterpart. The class-2 `sigma_eps` vectorization is a strict no-op for
pure-Gaussian fits (`expected_sigma_slots == 1` unchanged). The class-2
Gaussian-diag-B / column-coefficient TMB fences are gated behind new,
unused-by-Julia formula terms and default to no-ops.

The one genuine risk is the class-3 `ψ_t` → `ψ_t²` total-variance formula
fix, which is entangled with a much larger, complete rewrite of the
package's interval-certification claim surface (0.94-coverage-floor total-
variance-profile claim → 3-cell standardized-loading-Wald claim, explicitly
demoting the old profile route to "route-only"). This does not touch the
Gaussian likelihood or point-estimate oracle GLLVM.jl freezes against, but
it does mean: (1) any GLLVM.jl doc or dev-log text that cites gllvmTMB's old
coverage-certificate wording is now stale and should be refreshed against
0.7.1's wording rather than re-derived from 0.7.0, and (2) if a total-
variance derived-CI parity number was ever pulled from a 0.7.0 R run, it
should be re-pulled from 0.7.1 (or hand-verified) before being trusted,
since the 0.7.0 number embeds the now-fixed `+ ψ_t` (not `+ ψ_t²`) bug.

**Recommendation on re-freeze timing:** No urgency to re-freeze the
Gaussian/phylogenetic speed-and-likelihood oracle itself — nothing in this
172-commit range touches that surface. Re-freezing is worth doing
opportunistically the next time GLLVM.jl's CI/derived-quantity work touches
total-variance CIs specifically (confint_derived.jl / confint_derived_wald.jl
Σ_y-entry work), at which point pull a fresh R reference from 0.7.1 (or
later) rather than continuing to treat 0.7.0's total-variance numbers as
ground truth. Otherwise, defer a full re-freeze until the next natural
milestone (e.g. when GLLVM.jl starts porting any of the new response-column
coefficient/slope family, which would require a fresh R reference anyway).
