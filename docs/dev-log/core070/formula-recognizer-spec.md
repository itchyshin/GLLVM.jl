# Formula structured-term recognizer spec (core070)

**Status: SPEC + lane implementation only. Formula grammar is maintainer-approval-required
to merge** (AGENTS.md merge authority: "any API change, formula grammar change" needs
maintainer approval; see also docs/dev-log/core070/missing-surface-work-order.md:32).
Nothing in this document authorizes a merge to `main`.

Synthesized 2026-08-31 from four scout reports (dep-indep-scalar-kernel, phylo-animal,
spatial-slopes, namespace-misc). R oracle: frozen readback at
`.unlazy/core070-aghq/oracle-source/readback/R/`, reference commit b4d5fee6.
Julia worktree: `/private/tmp/GLLVM.jl-core070-aghq-20260830`.

Architectural fact that shapes everything below: **the R keyword functions are inert
markers** (`invisible(NULL)`); all semantics live in `rewrite_canonical_aliases()`
(brms-sugar.R:2398+) and fit-multi.R guards. A Julia port implements a *recognizer*
over the formula AST, not the functions.

---

## 1. Per-term contracts

### 1.1 `dep(formula)`

| Aspect | R oracle | GLLVM.jl target |
|---|---|---|
| Signature | `dep(formula)`; formula shape `0 + trait \| g` or `1 \| g` only (brms-sugar.R:1756-1758) | recognizer emits `SourceCovariance(C, P; mode=:dep)` (src/source_fit.jl:18-49) |
| Desugar | → `rr(form, d=.deferred_n_traits, .dep=TRUE)` (brms-sugar.R:4380-4388); `.dep` keyed at fit-multi.R:1629-1642 | full-rank packed triangular; `rank` forbidden for `:dep` (src/source_fit.jl:41-43) |
| Params | T(T+1)/2 (Cholesky of unstructured T×T Σ) | `rr_theta_len(p,p)` (src/source_fit.jl:60-70); B = L·Lᵀ (:79-82) |
| Gates | `.assert_no_augmented_lhs` (brms-sugar.R:2172-2215); dep+latent same group abort (fit-multi.R:1642-1656); dep+unique (:1657-1671); dep+indep (:1672-1681) | none yet — recognizer must add exclusion guards |
| Bridge | — | `mode="dep"` accepted (src/bridge.jl:1976-1983); full-rank unpack (:2052-2054) |
| Ledger | `namespace/export/dep` already **paid** (CORE070-NAMESPACE-DEP-FORMULA-KEYWORD); feeds `covariance/COV-ORD-DEP` (unplanned) and shared machinery for COV-SLOPE-F00-L0 dep rows | |

### 1.2 `indep(formula, common = FALSE)`

| Aspect | R oracle | GLLVM.jl target |
|---|---|---|
| Signature | `indep(form, common=FALSE)` (brms-sugar.R:1472-1474); `common` literal TRUE/FALSE, named-or-positional pos 3 (:4154-4159) | `SourceCovariance(C_identity, P; mode=:indep, common=...)` |
| Desugar | → `diag(form, .indep=TRUE[, common=...])` (brms-sugar.R:4150-4162); routes to `diag_B/diag_W` (`_common` variants at fit-multi.R:1367, 1393) | B = Diagonal(exp.(2θ)) (src/source_fit.jl:75-78); params `common ? 1 : p` (:68-69) |
| Gates | `.assert_no_augmented_lhs` (:4152); `.read_common_flag` abort "must be a literal TRUE or FALSE" (:2464-2483); indep+latent over-param abort (fit-multi.R:1682-1695); indep+unique redundant (block ~:1585) | mode gate src/source_fit.jl:35; common gate :37 |
| Semantics note | R's no-prefix `indep` couples groups by **identity**; Julia `SourceCovariance` always takes explicit C — recognizer must pass identity C | |
| Ledger | converts `namespace/export/indep` (CORE070-NAMESPACE2-INDEP-FORMULA-TERM); feeds COV-ORD-INDEP, COV-ORD-INDEP-COMMON; same recognizer contributes to COV-PHYLO-INDEP / COV-SPATIAL-INDEP structured rows later | |

### 1.3 `scalar(formula)` — soft-deprecated alias

| Aspect | R oracle | GLLVM.jl target |
|---|---|---|
| Signature/desugar | byte-identical to `indep(form, common=TRUE)` (brms-sugar.R:1510-1512, 4163-4177); Σ_T = σ²I, 1 param | `SourceCovariance(mode=:indep, common=true)` — already reachable via bridge dict (src/bridge.jl:1984-1985) |
| Gates | one-shot deprecation warn FIRST (`.gllvmTMB_warn_scalar_family_deprecated`, brms-sugar.R:150-167, fired :4170; suppressible via option); then augmented-LHS gate; inherits all indep guards | Julia should emit a one-shot `@warn` analogue with hint "use indep(..., common=true)" |
| Ledger | converts `namespace/export/scalar` (CORE070-NAMESPACE2-SCALAR-FORMULA-TERM) | |

### 1.4 `kernel_latent(unit, K, d=1, name="kernel", unique=FALSE)` and kernel siblings

| Aspect | R oracle | GLLVM.jl target |
|---|---|---|
| Signature | kernel-keywords.R:55-57; `K` MUST be named (abort "requires a named K matrix", brms-sugar.R:3302-3308); `d` named-or-positional pos 4 (:3356); `unique` literal logical (:3364-3372) | `SourceCovariance(C=K, P; name=name, mode=:latent, rank=d, unique=unique)` |
| Desugar | → `phylo_rr(unit, d=d, vcv=K, .kernel_name=name, .kernel_mode="latent")` (brms-sugar.R:3374-3378); `unique=TRUE` emits a SECOND `phylo_rr(..., .phylo_unique=TRUE, .auto_unique=TRUE, ...)` term joined by `+` (:3380-3389) | Julia folds the Ψ companion into the SAME source via `unique=true` (params src/source_fit.jl:60-66; B = L·Lᵀ + Diagonal, :79-88) — one-source vs two-term shape difference is internal, log-lik identical |
| Gates | slope bars abort for kernel_latent ("does not support this random-slope bar yet", :3321-3350); `lv=~...` hard abort (`.abort_source_specific_lv`, :2431-2456, applied :2694); multi-kernel tiers loadings-only (no `unique=TRUE`/`kernel_dep` combo; kernel-keywords.R:8-12) | PD-strict `isposdef` abort, no jitter (src/source_fit.jl:47) — **PSD-vs-PD mismatch**: R accepts PSD kernels |
| Bridge | `.kernel_*` metadata → `extract_Sigma(fit, level=name)` (comment brms-sugar.R:3290-3297) | bridge carries name/mode/rank/unique/common (src/bridge.jl:1967-2010, 2066-2073); **single source only** (:2031-2034); Gaussian only (:2013-2015); no named extractor tier |
| Siblings | `kernel_indep` → SourceCovariance(K, :indep); `kernel_scalar` → (K, :indep, common=true); `kernel_dep` → (K, :dep); `kernel_unique` → Ψ-only kernel diagonal (no direct SourceCovariance mode today — needs a small `:unique`/Ψ-only engine addition or `mode=:indep`-with-K semantics check) | |
| Ledger | converts `namespace/export/kernel_latent` (+ kernel_indep, kernel_dep, kernel_scalar, kernel_unique); `covariance/COV-KERNEL-LATENT`, `covariance/COV-KERNEL-FOLDED-UNIQUE` (cases STRUCT-KER-SINGLE-PSI, STRUCT-KER-MULTI, STRUCT-KER-MULTI-PSI-PRUNED; STRUCT-KER-MULTI additionally needs the multi-source lift) | |

### 1.5 `phylo_latent(species, d, tree=, vcv=, A=, Ainv=, unique=FALSE)` — DEFERRED (see §3)

R contract summary (for the eventual build): marker at brms-sugar.R:753; `A=` renamed
to `vcv=` (both supplied → abort); `Ainv=` densely inverted at rewrite time
(`solve(as.matrix(Ainv))`, brms-sugar.R:2948) — a covariance-vs-precision conversion
site. Desugars to `phylo_rr` (brms-sugar.R:3644-3667). Canonical tree route builds the
augmented Hadfield–Nakagawa sparse A⁻¹ (`.gllvm_phylo_tree_precision`,
phylo-tree-precision.R:183-249; consumed fit-multi.R:3796-3819), with ultrametric
abort (phylo-tree-precision.R:140-146). Dense vcv route jitters `+1e-8I` then inverts
(fit-multi.R:3862). Sparse vcv is treated as pre-computed A⁻¹ and kept whole —
"subsetting a precision would condition on the dropped nodes, not marginalize them"
(fit-multi.R:3820-3856, 638-685). Julia has the sparse engine
(src/sparse_phy.jl, src/likelihood_sparse_phy.jl — no ultrametric check) but the
`sources=` route accepts dense covariance only, and the native `Σ_phy=` path puts
phylogeny on the TRAIT axis — **not the same model** as R's `(Z C Zᵀ) ⊗ V_trait`
(docs/dev-log/core070/structured-native-mapping.md:49-56).

### 1.6 `animal_*` family — DEFERRED (see §3)

Pure sugar over phylo_rr/propto (brms-sugar.R:2953-2958). `.animal_resolve_vcv_call`
(brms-sugar.R:2552-2591): `pedigree=` → `pedigree_to_Ainv_sparse` (Quaas/Henderson,
pedigree-precision.R:156-215); dense `Ainv=` inverted, sparse passed through
(animal-keyword.R:631-633). Julia has **no pedigree support at all** (only disclaimers:
src/structured_cov.jl:107-130, src/formula.jl:167, src/source_fit.jl:285). Note:
building `pedigree_to_A` / `pedigree_to_Ainv_sparse` twins in Julia is ordinary code
work NOT gated on the maintainer decision; the covariance-vs-precision storage choice
in the typed source spec IS (structured-native-mapping.md:110-118).

### 1.7 `spatial_latent / spatial_indep / spatial_dep` — DEFERRED (see §3)

Markers at brms-sugar.R:1201, :1683, :1893; canonical orientation
`0 + trait | coords` with coordinates from `mesh=` (`make_mesh()`, spde-keyword.R).
These estimate κ (`log_kappa_spde`) — a **fixed-covariance `SourceCovariance` cannot
represent them**; they need the existing SPDE fitters (`fit_spde_gaussian`
src/spde_fit.jl:146, `fit_spde_latent_gllvm` src/spde_latent.jl:252) wired to a
recognizer, which is engine plumbing beyond this spec's SourceCovariance-reuse plan.

### 1.8 `latent(1 + x | g, ...)` augmented slopes and animal/phylo slope bars — DEFERRED (see §3)

Augmented LHS rewrites to `rr(..., .latent_augmented=TRUE, ...)` (brms-sugar.R:3518-3527);
`common=TRUE` aborts on augmented latent (:3467-3474). Julia has iid-Σ_b random-slope
fitters (src/fit_random_effects.jl:150,185; src/families/random_slopes.jl:106) but no
rank-d B-slope engine (`theta_rr_B_slope`), no interleaved dep engine
(`theta_dep_chol`), no structured-A slopes. Recognizer alone cannot convert these rows.

---

## 2. Ordered implementation plan (SourceCovariance reuse, smallest first)

Each step: red-first test sketch, then implementation, then ledger conversion.
All tests live under `test/` and run in the core suite; the bridge transport tests
reuse the existing `sources=` dict route so no new TMB-side machinery is needed.
**Every step below stays on the lane branch until maintainer approval of the grammar.**

### Step 0 — recognizer scaffolding in src/formula.jl
- Add an internal structured-term walker over the formula AST: detect calls named
  `dep/indep/scalar/kernel_*` on the RHS, split off the bar expression
  (`lhs | group`), and return `(remaining_formula, Vector{SourceTermSpec})`.
- Port the two shared gates as pure functions:
  `_assert_no_augmented_lhs` (R brms-sugar.R:2172-2215 — abort on `1 + x | g`) and
  `_read_literal_flag` (R :2464-2483 — literal `true`/`false` only).
- Red test: `@test_throws` on `indep(1 + x | g)` (augmented LHS) and
  `indep(0 + trait | g, common = flagvar)` (non-literal); passing parse for
  `0 + trait | g` and `1 | g` returning a spec with the group symbol.
- Converts: nothing directly; prerequisite for every later step.

### Step 1 — `indep()` recognizer → `SourceCovariance(:indep)`
- Map `indep(0 + trait | g, common=...)` to `SourceCovariance(I_groups, P; mode=:indep,
  common=common)` with identity C over the levels of `g` and projection P from the
  group column (matching the bridge `groups` key, src/bridge.jl:1967-2010).
- Red test: fit via the formula path on a small Gaussian sim equals a direct
  `fit_gaussian_sources` call with the hand-built identity-C SourceCovariance
  (log-lik and θ̂ to 1e-8); `common=true` yields 1 variance param.
- Converts: `namespace/export/indep`. Feeds: `covariance/COV-ORD-INDEP`,
  `COV-ORD-INDEP-COMMON` (currently unplanned rows).

### Step 2 — `scalar()` alias + deprecation warn
- Rewrite to Step 1 with `common=true`; emit a one-shot warning mirroring
  brms-sugar.R:150-167 (hint: `indep(..., common=true)`).
- Red test: `scalar(0 + trait | g)` fit identical to `indep(..., common=true)`;
  `@test_logs (:warn, r"deprecated")` fires exactly once per session.
- Converts: `namespace/export/scalar`.

### Step 3 — `dep()` recognizer → `SourceCovariance(:dep)`
- Map `dep(0 + trait | g)` to `SourceCovariance(I, P; mode=:dep)`; reject any `rank`
  spelling (src/source_fit.jl:41-43 already gates).
- Red test: formula fit equals direct `mode=:dep` sources fit; T(T+1)/2 params
  (`rr_theta_len(p,p)`).
- Converts: nothing new in namespace (dep row already paid); feeds
  `covariance/COV-ORD-DEP` (unplanned) and the dep half of future slope machinery.

### Step 4 — mutual-exclusion / redundancy gates
- Port the fit-multi.R guard quartet: dep+latent same grouping (over-parameterised,
  fit-multi.R:1642-1656), dep+unique (:1657-1671), dep+indep (:1672-1681),
  indep+latent (:1682-1695). Implement as a validation pass over the collected
  `SourceTermSpec`s before dispatch.
- Red test: each forbidden pair `@test_throws` with a message naming both terms.
- Converts: no row alone; required for R-parity error-contract cases and blocks
  silent over-parameterisation.

### Step 5 — `kernel_indep` / `kernel_scalar` / `kernel_dep` recognizers
- Same mappings as Steps 1-3 with `C = K` (named-`K` mandatory abort, mirroring
  brms-sugar.R:3302-3308) and `name=` metadata carried on the source.
- Red test: named-K omission aborts; `kernel_indep(id, K=K)` equals direct
  `SourceCovariance(K, P; mode=:indep)` fit.
- Converts: `namespace/export/kernel_indep`, `kernel_scalar`, `kernel_dep`.

### Step 6 — `kernel_latent` recognizer (single source)
- Map to `SourceCovariance(K, P; name=name, mode=:latent, rank=d, unique=unique)`.
  Port the gates: slope-bar abort (brms-sugar.R:3321-3350), `lv=` abort (:2431-2456),
  literal-`unique` (:3364-3372). Document (do not change) the PD-strict Julia
  behaviour vs R's PSD tolerance — a PSD kernel aborts with the existing
  `isposdef` message; flag the mismatch in the case contract rather than adding
  silent jitter (no-silent-regularization rule, structured-native-mapping.md:112-118).
- Red test: `kernel_latent(id, K=K, d=2)` equals direct latent-mode sources fit;
  `unique=true` adds the folded Ψ params and matches R's two-term Σ = ΛΛᵀ⊗K + Ψ⊗K
  numerics on the prepared STRUCT-KER-SINGLE-PSI fixture
  (test/parity/fixtures/core070_structured_input.R).
- Converts: `namespace/export/kernel_latent`, `namespace/export/kernel_unique`
  (via the `unique` path — if a standalone Ψ-only `kernel_unique` term is required,
  add a `:unique` folding note; smallest honest scope is unique-via-kernel_latent);
  `covariance/COV-KERNEL-LATENT`, `covariance/COV-KERNEL-FOLDED-UNIQUE`
  (case STRUCT-KER-SINGLE-PSI payable).

### Step 7 — multi-source lift in the bridge
- Remove the single-source restriction (src/bridge.jl:2031-2034): accept a vector of
  sources from the recognizer, dispatch through `fit_gaussian_sources` extended to sum
  source blocks. This is the one step that touches the engine beyond marshalling.
- Red test: two-kernel fit (loadings-only per R's multi-kernel restriction) matches
  the STRUCT-KER-MULTI prepared numerics; `unique=true` + multi-kernel aborts
  (mirrors kernel-keywords.R:8-12).
- Converts: makes STRUCT-KER-MULTI and STRUCT-KER-MULTI-PSI-PRUNED payable under
  the COV-KERNEL rows above.

### Step 8 — named extractor tier
- `extract_Sigma(fit, level=name)` for named kernel sources (R contract
  brms-sugar.R:3290-3297), thin over the stored source_names/modes already on the
  bridge result (src/bridge.jl:2066-2073).
- Red test: level string round-trips; unknown level aborts listing available names.
- Converts: no ledger row alone; completes the kernel_latent user contract.

Implementable ledger-row tally for §2: **12 rows**
(`namespace/export/{indep, scalar, kernel_latent, kernel_indep, kernel_dep,
kernel_scalar, kernel_unique}` = 7 conversions;
`covariance/{COV-KERNEL-LATENT, COV-KERNEL-FOLDED-UNIQUE}` = 2;
feeds `covariance/{COV-ORD-DEP, COV-ORD-INDEP, COV-ORD-INDEP-COMMON}` = 3
currently-unplanned rows. `namespace/export/dep` is already paid and counted nowhere.)

---

## 3. DEFERRED — blocked on maintainer decisions or engine work beyond this spec

### 3.1 Covariance-vs-precision storage decision (phylo + animal) — **maintainer decision required**

**Exact decision needed:** does the typed Julia source spec accept sparse *precision*
(tree/pedigree Q) natively, or does it densify to covariance at the surface?
The frozen-programme candidate bindings densify (`inv(Qtree)` / `inv(Qped)`,
docs/dev-log/core070/gaussian-source-bindings.md:24,27;
structured-native-mapping.md:23,31 — helper-only, fixture-scale), while
structured-native-mapping.md:112-118 requires a future "source precision adapter"
that must not silently regularize sparse Q, and the after-task
(2026-08-31-core070-covariance-modes.md §10) lists sparse precision as a deliberate
residual. R's canonical pedigree route is sparse-precision-only **with ancestor
retention** (marginalisation-vs-conditioning hazard, fit-multi.R:3829-3835), so a
dense-covariance-only Julia surface cannot represent it without the forbidden silent
conversion. Constructor/dispatch names are "DESIGN ONLY … the first B1/B2
implementation decision" (structured-native-mapping.md:120-127).

Conversion-site index to preserve in the eventual design (R oracle):
1. brms-sugar.R:2948 — phylo `Ainv=` → `solve(as.matrix(Ainv))` at rewrite time.
2. animal-keyword.R:632 — dense `Ainv=` inverted; sparse passed through.
3. fit-multi.R:3862 — dense vcv → precision after `+1e-8I` jitter.
4. fit-multi.R:625-631 — dense Ainv with extra nodes: invert, subset, jitter, re-invert.
5. fit-multi.R:739 — phylo_slope dense vcv sparse-inverted after jitter.

Rows held here: `namespace/export/{phylo_latent, phylo_rr, phylo_indep, phylo_scalar,
phylo_unique, phylo_dep, phylo_slope}` (7); `covariance/{COV-PHYLO-LATENT,
COV-PHYLO-INDEP}` (2; cases STRUCT-PHY-TREE-RR, STRUCT-PHY-DENSE-RR,
STRUCT-PHY-TREE-PROPTO); `postfit/POSTFIT-SURFACE-{extract,profile,profile_ci}_phylo_signal`
(3 — need a fitted phylo surface first; note the `profile_ci_phylo_signal` *function*
already exists at src/confint_derived.jl:1038, so the namespace twin is stale, but the
postfit case rows still need the fitted surface); `namespace/export/{animal_dep,
animal_indep, animal_latent, animal_unique, pedigree_to_A, pedigree_to_Ainv_sparse,
phylo}` (7 — PARTIAL_PENDING_DECISION_RECLASSIFY: blocked on the maintainer triage
"reuse existing receipted evidence or reclassify", not on Julia code);
`covariance/COV-ANIMAL-LATENT` (1; case STRUCT-ANI-PED-SPARSE). Additional caution:
the native `fit_gaussian_gllvm(Σ_phy=)` path is trait-axis phylogeny, not R's source
model — do not map to it (structured-native-mapping.md:49-56).

Not gated: building `pedigree_to_A` / `pedigree_to_Ainv_sparse` Julia twins
(Henderson recursion pedigree-precision.R:111-140; Quaas sparse A⁻¹ :156-215) is
ordinary code work and can proceed independently.

### 3.2 Spatial terms — engine wiring, not recognizer work

`spatial_indep/latent/dep` estimate κ/τ; they cannot ride the fixed-C SourceCovariance
path and need the SPDE fitters (src/spde_fit.jl, src/spde_latent.jl) wired to a
formula + mesh surface. Rows held: `covariance/{COV-SPATIAL-INDEP, COV-SPATIAL-DEP,
COV-SPATIAL-LATENT, COV-SPATIAL-FOLDED-UNIQUE}` (4; cases STRUCT-SPA-INDEP/LATENT/
LATENT-PSI/DEP/COMMON-MAP, all PREPARED_REFERENCE_NUMERICS_UNPAID);
`namespace/export/spatial_{latent,indep,dep}` (3 — PARTIAL_PENDING_DECISION_RECLASSIFY).

### 3.3 Augmented-slope engines — missing numerics, not just grammar

`latent(1 + x | g, d=K)` B-slope (theta_rr_B_slope + diag companion), animal/phylo
`theta_dep_chol` interleaved dep, and `theta_rr_phy_slope` block engines have no Julia
counterpart; the existing random-slope fitters are iid-Σ_b only. Rows held:
`covariance/{COV-ORD-SLOPE, COV-ORD-SLOPE-NOUNIQUE, COV-SLOPE-F02-L0,
COV-SLOPE-F00-L0}` (4); `namespace/export/latent` (1 — term-recognizer row; also
hosts the REFERENCE_REJECTED indep/dep slope boundaries). Full prepared case list and
pinned parameter counts: docs/dev-log/core070/slopes-required-case-plan.json.

### 3.4 R-side reference defects — **reviewed Julia disposition required, never reproduce**

- SLOPE-ANIMAL-DEP-MULTIGAUSS and SLOPE-ANIMAL-DEP-MULTIPOIS: BLOCKED_REFERENCE_MISROUTE
  — R's single-slope LHS classifier silently misroutes `animal_dep(1 + x + x2 | ...)`
  (silent term loss / falls back to 6 free intercept loadings;
  slopes-input-contract.md:52-55). **Decision needed:** the reviewed Julia disposition
  (expected: explicit rejection with a clear error). Do NOT pair numerics against these.
- The kernel plan carries a separate BLOCKED_REFERENCE_PARAMETER_LOSS case — same
  rule, out of this spec's scope.
- REFERENCE_REJECTED boundary cases (SLOPE-ORD-LAT-RANK7, SLOPE-ORD-INDEP-BAR/DBAR,
  SLOPE-ORD-DEP-BAR/DBAR, SLOPE-ORD-LAT-COMBINE, SLOPE-ANIMAL-LAT-RANK4,
  SLOPE-PHYLO-DEP-MULTIPOIS): Julia acceptance rule is "specific unsupported
  combination rejected, or separately reviewed documented extension" — these become
  error-contract tests on the recognizers when their host terms land.

Deferred ledger-row tally for §3: **32 rows**
(7 phylo namespace + 2 COV-PHYLO + 3 postfit phylo_signal + 7 animal/pedigree
namespace + 1 COV-ANIMAL-LATENT + 4 COV-SPATIAL + 3 spatial namespace +
4 slope covariance + 1 namespace/export/latent).

---

## 4. NOT COVERED

- `namespace/export/{gr, meta, meta_V, meta_known_V, traits}` (5 rows): structured-term
  rows named in the ledger but not examined by any of the four scouts — no R-contract
  read, no Julia mapping proposed here.
- The 18 non-structured namespace rows from the namespace-misc scout (getLoadings,
  getResidualCov, getResidualCor, getREsd, gllvmTMB_check_consistency, gllvmTMB_diagnose,
  gllvmTMBcontrol, loading_ci, loading_profile, predictive_check,
  profile_ci_phylo_signal, profile_ci_total_variance, profile_phylo_signal,
  profile_targets, sanity_multi, slope_sd_ci, standard_errors, tmbprofile_wrapper):
  these are extractor/CI/control-surface work, not formula-recognizer work. Per that
  scout, 8 are already implemented in this worktree and need ledger reclassification,
  4 are cheap implements, 6 are defers — dispositions belong to the extractors/postfit
  lanes, not this spec. (Notably `namespace/export/slope_sd_ci` is stale: the surface
  exists at src/confint_derived_wald.jl:663.)
- Non-Gaussian families on the sources route: the bridge sources path is Gaussian-only
  (src/bridge.jl:2013-2015) with `ci_method="none"`; every mapping in §2 inherits that
  limit. Lifting it is a separate engine slice.
- Ordinary `latent(0 + trait | g, d=K)` non-augmented grammar (the plain rr surface),
  `rr`/`diag` engine spellings, and the `residual=`/`lv=` sub-grammar of `latent()`:
  not scouted in detail here beyond the gates that reference them.
- Varimax/promax rotation parity, plotting surfaces, and TMB-plumbing aliases —
  explicitly out of scope per the misc scout's defer list.
- Case-plan freezing: structured-required-case-plan.json is DRAFT_NOT_FROZEN; this
  spec cites its cases but does not freeze them.

Not-covered ledger-row tally for §4: **23 rows** (5 structured-unscouted + 18
non-structured misc).

---

## 5. Reminder

Formula grammar changes are **maintainer-approval-required** (AGENTS.md merge
authority). This document plus lane-branch implementation and red-first tests is the
full extent of authorized work; no recognizer merges to `main` without Shinichi's
explicit approval, and the two decisions in §3.1/§3.4 must be put to him as questions,
not resolved unilaterally.

## Post-verification correction (2026-09-01, adversarial verify round)

The §2 tally counted covariance/COV-ORD-DEP, COV-ORD-INDEP, and
COV-ORD-INDEP-COMMON as unconverted feeds; the current ledger (post the
2026-09-01 covariance evidence repointing) shows all three already carry
PASS-receipted executable cases including formula-interface cases. The
implementable payoff is therefore 9 BLOCKED rows (7 namespace kernel/indep/
scalar + 2 covariance kernel), not 12. No partition error; all other
citations spot-checked accurate.
