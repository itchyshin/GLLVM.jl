<!-- 7-agent design workflow (3 designers, 3 adversarial judges, Rose
consolidation), 2026-08-28: Student-nu estimator (parity cell 9), cloglog
saturation guard, speedup-claims reconciliation. Each section ends in an
executable numbered plan. Notable: a candidate TWIN BUG (gllvmTMB df-profile
back-transform exp vs 1+exp) flagged for verification before any nu-CI parity
claim. -->

# Rose Consolidation — Three Arcs: Student-t Completion, Laplace Saturation Guard, Speedup Reconciliation

**Consolidator:** Rose (systems-audit lens). **Inputs:** three design documents + three adversarial critiques. **Repos:** lane worktree `/Users/z3437171/local-scratch/lanes/GLLVM.jl-beyond-20260824` (HEAD `7952ecbd`, branch `hessian-kwarg-20260827` per critique 2's evidence stamp); twin `/Users/z3437171/Dropbox/Github Local/gllvmTMB` (read-only, HEAD `b9a90c8c8`). Line anchors below are from the design/critique evidence passes; every plan begins with a re-verification step because anchors drift.

**Overall verdicts:** all three designs are sound in mechanism and unusually citation-accurate; all three critiques are substantially valid. Each design proceeds after the revisions below. Explicit rejections of critique points are marked **REJECTED** or **PARTIALLY REJECTED** with reasons.

---

## Section 1 — Student-t estimator completion (Arc 3, parity-ladder cell 9)

### Consolidated position

The design's core is confirmed and adopted: mirror the twin's `ν = 1 + exp(θ_ν)` per-trait parameterisation (`gllvmTMB.cpp:1183-1184`, `:2798`), per-trait σ via the grouped-dispersion isolated-parallel pattern (vector of `StudentTFamily` markers reusing all existing `_glm_*` pieces verbatim), twin-matching init (σ₀ = 1, ν₀ = 3), `hessian = :observed` default, Option C marker widening (`StudentTFamily(nothing)` = estimate, `StudentTFamily(3.0)` = pin, `StudentTFamily()` unchanged), two-sub-cell parity payment (pinned-df first, estimated-df with cross-plugged ridge fallback second), tiered ADEMP recovery contract, and the two flagged maintainer decisions (no silent default flip; coerce-on-`nothing` yes / coerce-on-fixed no).

### Critique adjudication

**Accepted (incorporated into the plan):**

1. **Defect 1 — wrong extension point (load-bearing).** `disp_group` routing never reaches `_fit_gllvm`; it routes at `fit_gllvm.jl:196-209` to `_fit_gllvm_grouped` (methods `:298-327`). The per-trait route must be a new `_fit_gllvm_grouped(::StudentTFamily, ...)` method; the estimating/coerce behaviour belongs in the coerce block at `:142-146`. Plan step 6 is rewritten accordingly.
2. **Defect 3 — twin mischaracterised; convention already exists.** The twin's extractor computes σ²·df/(df−2) itself and returns **NA** for df ≤ 2 (`R/extract-sigma.R:270-281`); Julia already has the Inf-for-ν≤2 convention at `src/link_residual.jl:101-105`, `:450-455`. Reuse that convention; record the Inf-vs-NA twin divergence rather than inventing a fresh one.
3. **Defect 4 — twin df profile back-transform is `exp`, not `1+exp`** (`R/profile-targets.R:205-210`), so a naive ν-CI parity comparison would be off by exactly 1. Must be verified (twin bug vs downstream correction) before the twin CI surface is used as a reference. Harmless for logLik parity; load-bearing for CI work.
4. **Defect 5 — type-parameter narrowing.** Prefer `StudentTFamily{N<:Union{Real,Nothing}}` keeping the promoting constructor, and add an explicit `StudentTFamily(::Nothing)` method (the existing `StudentTFamily(ν::Real)` at `:60` cannot catch `nothing`). The "all live sites are Float64" observation is itself unverified-by-run; keep Real and avoid the question.
5. **Defect 6 (tolerance half) — nesting inequalities need ε.** `estimating logLik ≥ pinned-at-truth logLik` holds only at exact optima; assert `≥ −ε` (ε ≈ 1e-6·|logLik| scale, set once, documented) from the start rather than widening later.
6. **Defect 7 — Workflow Q not scheduled.** JET/Allocs/Aqua/multi-shape must be either in-scope or explicitly waived with reason in the after-task report; silence is a Rose-gate blocker.
7. **Defect 8 — both docstring stalenesses.** Fix `:176` (`:fisher`→`:observed`) *and* the retired `marginal_loglik_laplace_aux_value_grad` claim at `studentt.jl:160-168` together.
8. **Defect 9 — citation slips** (`gllvmTMB.cpp:1183-1184`; pin map is `:5347-5348`; `fit_gllvm.jl:86-96` grouped list already includes Gamma/TweedieED). Corrected in the plan.
9. **Defect 10 — cascade completions**: `_fit_family`/`_fit_dispersion` hooks, `Base.show`, export in `src/GLLVM.jl:200`, `runparity.jl` include; no bridge cascade (verified absent). Plus the critique's positive note: extend the `_GroupedDispersionFit` union at `confint_family.jl:39` — an exact in-repo pattern that shrinks the CI-scope risk.

**Partially rejected:**

- **Defect 2 (composability regression)** — *accepted as a documentation duty, rejected as a design blocker.* The one-of constraint at `fit_gllvm.jl:164-172` does make per-trait Student-t mutually exclusive with `row_eff` in Julia, a divergence the twin doesn't have, and the design should have said so. But lifting the exclusivity is engine surgery on the shared routing layer — out of scope for this arc. Disposition: document the divergence in the fitter docstring and `response-families.md`, add a ledger caveat, file a follow-up issue; do not restructure routing here.
- **Defect 6 (warm-start alternative) — REJECTED.** The critique's second remedy ("warm start the estimating fit from the pinned solution") conflicts with the design's own load-bearing requirement that the estimating parity sub-cell start from the *twin-equivalent* init (σ₀ = 1, ν₀ = 3), precisely because the ν ridge makes the endpoint start-dependent. The ε-tolerance remedy is adopted; the warm-start remedy is not.

**Rejected:** nothing else — all remaining critique points verified as stated.

### Implementation plan (Section 1)

1. **Preflight.** `cd /Users/z3437171/local-scratch/lanes/GLLVM.jl-beyond-20260824 && git status && git rev-parse --short HEAD`; run `tools/lane_preflight.sh` if present. Re-verify every line anchor cited below with `grep -n` before editing (anchors drift).
2. **Verify the twin df-CI back-transform (defect 4) before any CI parity claim.** Read `~/Dropbox/Github Local/gllvmTMB/R/profile-targets.R:200-210` and grep the twin for downstream `1 +` corrections on `log_df_student` CI output. Record the verdict (twin bug vs corrected downstream) in `docs/dev-log/decisions/2026-08-XX-studentt-parameterisation.md`. If uncorrected, any ν-CI parity comparison uses `1 + exp(bound)` on the twin's reported interval.
3. **Widen the marker.** In `src/families/studentt.jl`: `StudentTFamily{N<:Union{Real,Nothing}}` keeping σ promotion; add `StudentTFamily(::Nothing)` constructor; keep `StudentTFamily()` ⇒ ν = 4.0 fixed (no default flip — maintainer decision 1 stands). Grep all construction sites (`studentt.jl:101`, `link_residual.jl:219,454`) and confirm they still compile.
4. **Site kernel.** Add `_studentt_grouped_loglik_site` to `src/families/studentt.jl` (or alongside the NB kernel), cloned from `_nb_grouped_loglik_site` (`grouped_dispersion.jl:41ff`), preserving: (a) Fisher-scored mode search unconditionally; (b) log-det weight honouring `hessian` (`:observed` uses `_glm_obs_weight`, genuinely negative for `|r| > σ√ν`); (c) assembly-level PD guard via `cholesky(A; check=false)` → `-Inf` — never a weight clamp.
5. **θ packing and init.** `θ = [β; pack_lambda(Λ); log σ_1…log σ_p; log(ν_1−1)…log(ν_p−1)]`; pinned mode omits the ν block. Warm start: per-trait row-wise MAD for σ₀; `log(ν₀−1) = log 2`. Optimizer: L-BFGS, `autodiff = :finite`; note the #105 analytic-gradient follow-up in the docstring.
6. **Routing (corrected per defect 1).** New method `_fit_gllvm_grouped(family::StudentTFamily, ...)` beside `fit_gllvm.jl:298-327`; `StudentTFamily(nothing)` coercion behaviour in the coerce block `:142-146`; extend the `disp_group` doc contract list (`:86-96`, which already includes Gamma/TweedieED). Document the `row_eff`/`disp_group` mutual exclusion divergence (defect 2 disposition) in the docstring and `docs/src/response-families.md`; open a follow-up issue.
7. **Fit type + cascade (defects 3, 10).** `StudentTPerTraitFit` with `hessian::Symbol` field. Same PR: `simulate` method (pattern `src/simulate_fit.jl:263-271`); per-trait `link_residual` reusing the existing Inf-for-ν≤2 convention (`link_residual.jl:101-105`), recording the twin's NA divergence; `_fit_family`/`_fit_dispersion` hooks; `Base.show`; export in `src/GLLVM.jl`; Wald + profile CIs for σ_t and ν_t by extending the `_GroupedDispersionFit` union (`confint_family.jl:39`), log-scale and log(ν−1)-scale back-transforms. If CIs are deferred, the ledger row says estimator-only.
8. **Docstring repair (defect 8).** Fix both stale claims in the `fit_studentt_gllvm` docstring: `:fisher`→`:observed` default, and remove the retired implicit-gradient path claim (`studentt.jl:160-168` vs `:219-223`).
9. **ADEMP in-suite test.** Extend `test/test_studentt.jl` per design §4 (p = 6, K = 1, n = 400; ν ∈ {3, 8} split; three-tier contract; pin-mode sanity; degenerate cells; masked-cell run). All nesting inequalities use `≥ −ε` with ε documented in the test header (defect 6). RNG: match whatever the existing Student-t tests actually use (verify — do not assume StableRNGs).
10. **Parity cell.** Add `:student` (+ `df` passthrough kwarg) to the allowlist/switch in `test/parity/parity_helpers.jl:87-124`; new `test/parity/test_studentt_parity.jl` included from `runparity.jl`; sub-cell 1 (pinned df = 3, |Δ logLik| ≤ 1e-3, σ̂ ~2%) then sub-cell 2 (estimated, twin-equivalent init, loose ν bar + cross-plugged logLik fallback ≤ 1e-3). No Y-centring; rotation-invariant quantities only. Run: `GLLVM_PARITY_TESTS=1 julia --project=test/parity test/parity/runparity.jl` (per parity README).
11. **Workflow Q (defect 7).** JET + Aqua ride `Pkg.test()`; run an Allocs check on the site kernel inner loop; multi-shape p ∈ {100, 1000, 10000} for the grouped kernel OR record an explicit reasoned waiver (FD outer gradient limits practical p for the estimating route) in the after-task report — one or the other, never silence.
12. **Maintainer decisions surfaced, not made:** default flip (recommend defer to v0.2.0); coerce semantics (recommend yes for `nothing`, no for fixed); struct widening + new export under merge authority.
13. **Close-out.** `julia --project=. -e 'using Pkg; Pkg.test()'` full tally pasted; check-log entry; after-task report at `docs/dev-log/after-task/`; Rose audit verdict; campaign-scale recovery table is a Totoro job with a D-139 estimate + pre-run test before launch — not part of this arc's tests.

---

## Section 2 — Laplace saturation guard for Binomial/cloglog

### Consolidated position

The design survives critique intact in its three structural decisions, all confirmed by verification: (i) the saturation geometry (η_sat ≈ 3.32 for cloglog via `log(−log(1e-12))`; weight collapse a full η-unit earlier; both curvature selectors lose the penalty); (ii) placement as a post-fit health field + warning, **not** `_fit_verdict`, never flipping `converged` (the optimizer genuinely converged on the coded objective); (iii) the layered twin answer — diagnostic ships regardless, parity experiment adjudicates the tail-cap difference later as a campaign slice. The design's §1 sharpening of the check-log ("identical objective" holds only in the interior; Julia caps the y=0 penalty at ≈ −27.6n while the twin runs unbounded to η = 700) is confirmed as a genuine finding and is preserved.

### Critique adjudication

**Accepted (all seven defects incorporated):**

1. **D1 — RNG contradiction (test-breaking).** The campaign uses `Xoshiro(seed)` (`cell_binlinks.jl:105`); `grep -rn StableRNG test/` returns nothing, so the design's "all seeded, StableRNGs" premise — and AGENTS.md's own claim — is stale. T2 must embed the campaign's `Xoshiro` DGP verbatim or independently verify a runaway seed under the chosen RNG.
2. **D2 — `maxlog=1` wrong.** Per-session suppression silently passes every saturated fit after the first — the exact failure mode the guard exists to prevent. Drop `maxlog`; warn per fit (the tweedie idiom at `tweedie.jl:346-353` has no maxlog).
3. **D3 — intercept/separation false-positive channel** — *accepted in modified form.* η ≥ 3.32 is reachable through β̂ alone (complete separation under cloglog) with no Λ pathology, and the quietness evidence comes from a mild-intercept DGP; probit collapses near η ≈ 5.6–7. Remedy adopted: hedge the warning text ("may indicate…; loadings and loglik can be inflated when saturation is latent-mode driven") **and** add an extreme-prevalence benign case to T3 — rather than the critique's alternative of gutting the trigger. The trigger itself (`n_clamp > 0 ∨ n_wcollapse > 0`) stands.
4. **D4 — plateau branch.** Skip computation (leave `nothing`) when `loglik == -Inf`; scope T4 to finite-loglik fits. Prevents mode passes at garbage Λ̂ and misleading warnings on already-failed fits.
5. **D5 — "19/300" unverifiable in-repo.** Restate the saturation definition independently in the docstring; do not pre-register test counts against the check-log prose figure.
6. **D6 — `variational_binomial.jl:334` shares the struct.** VA fits carry `saturation = nothing`; the accessor docstring must name this explicitly alongside the dense-kernel out-of-scope list.
7. **D7 — DoD/authority/sweep gaps.** `docs/` reference entry + README in the same PR (design rule 3 / DoD item 4); exported accessor flagged as maintainer-approval API addition; sweep the five existing cloglog-exercising test files for log-/show-sensitive assertions the new warning or tag would break.
8. **Citation drift items** (DGP at `cell_binlinks.jl:87-99`, `_fit_verdict` at `:52-64`, mask promise at `laplace.jl:311-315`, etc.) accepted as anchor corrections; content was right.

**Rejected:** none outright. This critique found no unsound point; two items (D2 mechanism, D3 remedy choice) are accepted in modified form as noted, with the modification reasons stated above.

### Implementation plan (Section 2)

1. **Preflight.** Confirm lane repo state (`git status; git rev-parse --short HEAD` — expect `hessian-kwarg-20260827` lineage); re-verify anchors: `binomial.jl:27,34,72-101,195-197,296-314`, `laplace.jl:20,60,196-224,311-315`, `links.jl:29,41,46-56`, `fit_verdict.jl:52-64`, `variational_binomial.jl:334`, `cell_binlinks.jl:87-105`.
2. **Struct.** Add immutable `LaplaceSaturationHealth` `(n_clamp::Int, n_wcollapse::Int, n_obs::Int, max_abs_eta::Float64, hessian_used::Symbol)`; append `saturation::Union{Nothing,LaplaceSaturationHealth}` to `BinomialFit` with a positional compat constructor defaulting `nothing` (template: the `hessian` field precedent at `binomial.jl:88-93`).
3. **Statistic.** `_laplace_saturation_health(fit-state…)`: recompute per-site Laplace modes at `(β̂, Λ̂)` (same pass as `getLV`); thresholds link-agnostically via `η_sat_upper = linkfun(link, 1 − 1e-12)`, `η_sat_lower = linkfun(link, 1e-12)`; count μ-clamp contact, η-clamp contact (|η̂| ≥ 30), and `W ≤ 1e-8` under the **fit's own** `hessian` selector; observed (mask-respecting) cells only. Docstring restates the saturation definition independently (D5) and names out-of-scope surfaces: the non-dense kernels (grouped/covariates/quadratic/mixed/spde/phylo/aghq/coevolution) **and** VA fits via `variational_binomial.jl` (D6).
4. **Computation site.** In `fit_binomial_gllvm`, on both return branches (`binomial.jl:308, 313`), guarded: if `loglik == -Inf` (plateau verdict), leave `saturation = nothing` (D4). The X_lv branch is safe for the selector logic (non-default `hessian` throws there — confirmed `binomial.jl:195-197`).
5. **Surfacing.** `@warn` per fit, **no maxlog** (D2), hedged text (D3): counts, link, `‖Λ̂‖` as context only, "may indicate the Laplace approximation is unreliable at this optimum; loadings and loglik can be strongly inflated when saturation is latent-mode driven; see check-log 2026-08-28". `Base.show` gains `", SATURATED (k cells)"` beside the `NOT CONVERGED` tag. Exported accessor with docstring.
6. **Tests** (RNG per D1 — mirror the file's actual convention; embed `Xoshiro` for campaign-derived data):
   - T1: constructed `(Λ, β, z)` straddling thresholds; exact counts; mask exclusion.
   - T2: the campaign-flagged runaway cell reproduced with `Xoshiro(seed)` verbatim from `cell_binlinks.jl:87-105`; assert `converged == true`, large `‖Λ̂‖`, `n_clamp > 0`, `@test_logs (:warn, r"saturat")`; cap iterations if slow (statistic is point-wise).
   - T3: (i) benign cloglog truth → counts 0, quiet; (ii) logit/probit own DGPs → populated, 0, quiet; (iii) **new**: extreme-prevalence benign case (large |β|, trivial Λ) — establishes whether pure-intercept clamp contact occurs and that the hedged warning is not misleading there (D3).
   - T4: `-negll(θ̂) ≈ fit.loglik` on **finite-loglik** fits only (D4); compat-constructor fit behaves identically downstream with `nothing` = "not computed".
   - T5 stays campaign-side (`exact_marginal` oracle iff-fired check).
7. **Regression sweep (D7c).** Run and inspect `test_binomial_laplace.jl`, `test_curvature_census.jl`, `test_laplace_curvature_contract.jl`, `test_laplace_dual_safety.jl`, `test_families.jl` for assertions broken by the new warn/show output; fix call sites, never tolerances.
8. **Docs/authority (D7a-b).** Reference entry in `docs/` + README note in the same PR; flag the exported accessor as an API addition requiring maintainer approval before merge.
9. **Close-out.** Full `Pkg.test()` tally; check-log entry; after-task report; Rose audit. The §4 twin parity experiment (fit twin ML cloglog on the 19 saturated datasets) remains a **separate campaign slice** with its own D-139 estimate; the guard ships regardless of its outcome. File the outcome to cross-pollination issue #13 either way.

---

## Section 3 — Speedup-claims reconciliation (Arc 6)

### Consolidated position

The canonical framing is adopted as designed: **161–698× per cell, grid-wide median 265.1×, Gaussian closed-form path only**, range + median always together, honest caveats travelling with the number, ~340× retired from live surfaces and surviving only inside fenced historical text. The arithmetic and nearly all provenance verified. The critique adds two major corrections (an unreconciled document, and a replacement that isn't drop-in safe) that the plan now incorporates.

### Critique adjudication

**Accepted:**

1. **D1 (major) — the 2026-08-25 release-readiness audit still advertises ~340× as the six-cell grid median** (and "~1000× (lognormal)" vs the published ≈1280×), and the design both endorsed its release prose and misread it (the audit bans only the *phylogenetic attribution*, while actively using 340× as the Gaussian figure). The two audits genuinely disagree; the reconciliation must adjudicate, not paper over. Adjudication adopted: the 2026-08-26 grid-derived figure (265.1×) wins because it is arithmetic on the only published table; the 2026-08-25 audit's numbers are marked superseded with a dated note.
2. **D2 (major) — the parity-page replacement decapitates a sentence.** The pre-existing malformed splice at `gllvmtmb-parity.md:97-98` (admonition text running mid-sentence into unindented body text "Beta use analytic Laplace outer gradients…") must be repaired as part of the edit; the design's "exact replacement" was not drop-in safe.
3. **D3 — `[Benchmarks](/benchmarks)` root-absolute link** in §3c is wrong for Documenter and internally inconsistent with §3b/§3d; use `benchmarks.md`.
4. **D4 — missed cascade sites**: `.agents/skills/julia-likelihood-review/SKILL.md:235` ("keeps the 340× speedup honest") is a live agent-facing surface; stale build artifacts live under `docs/build/1/` as well as `.documenter` (regenerate, never hand-edit).
5. **D5 — false "echoed in" claim** (lognormal ≈1280× appears only at `benchmarks.md:24`; README/changelog hits are the unrelated Delta-lognormal family). Provenance row corrected.
6. **D6 — changelog convention.** The "append, never rewrite" convention is precedent (one parenthetical at `:144`), not a stated rule — and the proposed edit inserted text *inside* the existing italic correction block, editing a published correction. Remedy: append a **new dated correction block** after the existing one; describe the convention as precedent.
7. **D7 — comparison.md medians provenance is AGENT-INFERRED.** "Pairwise medians of the six cells" is arithmetic coincidence (median of two = mean of two); the ground truth is the bench repo's `grid-bench.md`. Verify there before shipping "All are medians over the same six published cells", or hedge the sentence.
8. **Nit — silent admonition retitle** noted in the change list explicitly.

**Partially rejected:**

- **D8 (sequencing: re-run first, cascade once) — PARTIALLY REJECTED.** The critique is right that the n_reps ≥ 10 refresh will change the token, and right that this is a maintainer decision to surface. But re-run-first is *not* clearly cheaper: (i) the parity-page-disputes-changelog contradiction is release-blocking **now**, independent of the refresh, and leaving four inconsistent framings live while waiting on a bench-repo run extends the defect window; (ii) the design's single greppable token (`265.1`) makes the post-refresh cascade a one-grep, one-pass sweep — the second cascade costs minutes, not a second reconciliation; (iii) the docs already carry the "not a publishable final number" disclaimer, which the canonical sentence can reference. Disposition: reconcile text now, keep the disclaimer adjacent to the headline, run the refresh before the release tag, re-sweep the token then. The sequencing choice is surfaced in the maintainer decision table (accepting that half of D8).

**Rejected:** nothing else; all other critique claims verified.

### Implementation plan (Section 3)

1. **Preflight.** Lane repo `git status`; re-verify grid values at `docs/src/benchmarks.md:33-40` (194.9, 185.3, 698.1, 335.3, 398.8, 161.2; median 265.1) and all edit-site anchors (`README.md:33`, `changelog.md:142-151`, `comparison.md:35-37`, `gllvmtmb-parity.md:84-98`, `CLAUDE.md:7`, `AGENTS.md:13`).
2. **Adjudicate the audits (D1).** Append a dated note to `docs/dev-log/pending/2026-08-25-release-readiness-audit.md` (or a new dev-log note referencing it, if pending files are treated as frozen): its "roughly 340×" grid median and "~1000× (lognormal)" are superseded by the published grid (265.1× median; ≈1280× lognormal, `benchmarks.md:24`); its release-note paragraph must not be reused verbatim at tag time. State explicitly that the audit's *phylogenetic* prohibition stands and was never the whole of its 340× usage.
3. **README (`README.md:33`).** Apply the design's 3a edit verbatim (add "per cell (grid-wide median **265.1×**)"); leave the existing dated-correction notes and Gaussian fence untouched.
4. **Changelog (D6).** Append a **new** dated italic correction block after the existing 2026-08-25 block (never inside it), with the design's 3b text adapted: ~340× came from an unpublished bench-repo grid, cannot be checked here; published grid measures 161–698× per cell, median 265.1×; ~340× retained above only as originally published text.
5. **comparison.md (D3, D7).** Apply the 3c replacement with link fixed to `[Benchmarks](benchmarks.md)`. Before shipping the sentence "All are medians over the same six published Gaussian cells": check `gllvmTMB-julia-bench/report/grid-bench.md` if locally readable; if it confirms, keep; if unreachable, hedge to "consistent with the six published Gaussian cells (see Benchmarks)" and drop the computation-method assertion. Keep the "not a publishable final number" caveat adjacent (D8 disposition).
6. **gllvmtmb-parity.md (D2).** Two-step edit: first repair the malformed splice — detach "Poisson, NB2, Binomial, and Beta use analytic Laplace outer gradients…" (line 98ff) into its own well-formed body paragraph below the admonition; then replace the admonition body with the design's 3d text. Note the retitle ("…not folklore" vs "…not the headline") in the commit message as a deliberate voice change, or keep the old title if the maintainer prefers — flag it.
7. **Cascade (D4, D5).** Add `.agents/skills/julia-likelihood-review/SKILL.md:235` to the edit set (self-merge class — agent-facing doc); correct the provenance-table "echoed in" wording; do **not** hand-edit `docs/build/` — regenerate via `julia --project=docs docs/make.jl` and confirm no ~340× survives in fresh build output. Draft but **hold** `CLAUDE.md:7` and `AGENTS.md:13` substitutions for maintainer approval (merge-authority class).
8. **Verification sweep.** `grep -rn "340×\|340x" --include="*.md"` across the repo excluding `docs/build/`: expected survivors are exactly (a) the fenced changelog historical text, (b) the superseded-marked 2026-08-25 audit, (c) dated dev-log history. Any other hit is an unfinished cascade. Local Documenter build clean.
9. **Pre-release measurement (unchanged from design §4, sequenced per D8 disposition).** Before the release tag: re-run the six-cell grid in `gllvmTMB-julia-bench/` with n_reps ≥ 10, median + MAD + cold-start row; publish the refreshed table into `benchmarks.md`; recompute range and median; sweep the `265.1` token repo-wide in one pass. Add the R-side configuration clause (non-default `disp.formula = ~1`-equivalent; per-species default un-benchmarked) next to the headline. Well under the D-139 30-minute line; runs in the bench repo.
10. **Maintainer decision table (updated).** Canonical headline as designed; ~340× retired; self-merge files: README, comparison, parity page, changelog-append, SKILL.md, audit-supersede note; approval-required: CLAUDE.md, AGENTS.md; **new row:** sequencing = reconcile-now / refresh-before-tag (with the re-run-first alternative recorded as considered and why it was not chosen).
11. **Close-out.** check-log entry; after-task report; Rose pre-publish audit pass over the edited surfaces (this arc *is* the gate's subject matter — the audit must be run by a fresh lens, not the implementing session, per own-the-verifier).

---

**Cross-cutting notes for the orchestrator:** (1) All three arcs touch maintainer-approval surfaces (Section 1: struct widening + exports; Section 2: exported accessor; Section 3: CLAUDE.md/AGENTS.md) — batch those approvals into one ask. (2) Section 2's D1 exposed a stale AGENTS.md claim ("StableRNGs" in the test suite) worth a separate one-line doc fix, not bundled into any of these arcs. (3) Sections 1 and 2 both depend on line anchors from branch `hessian-kwarg-20260827`; if that branch has moved or merged, step 1 of each plan re-anchors before any edit.
