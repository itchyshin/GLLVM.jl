# Post-M2 slice adversarial review (ultracode, 4 lenses + verify, 2026-09-01)

Raw verified findings (CONFIRMED ranked first; verified against HEAD 85c502fb
with live Julia runs where cheap). Source: workflow wf_c978d263.

```
{
  "summary": "Multi-lens adversarial review of the ~60 new exports from the post-M2 slices",
  "agentCount": 5,
  "logs": [],
  "result": {
    "verified": "All findings verified against the worktree at current HEAD 85c502fb (2 commits past the reviewed 450cc412/23fb43f9; none of the findings were fixed in between). Evidence is from direct code reading plus a live Julia run (small Gaussian K=2 fit) at `/private/tmp/claude-503/.../scratchpad/verify.jl`.\n\n## CONFIRMED (ranked)\n\n**P1 — `src/confint_derived_wald.jl:557-608` (`loading_ci`): `method=:wald, loading_scale=:standardized` silently returns raw-loading CIs labeled `:standardized`.** CONFIRMED by live run: `loading_ci(fit, y; method=:wald, loading_scale=:standardized)` row 1 gave est=0.97586, lower=0.76645 with `loading_scale=standardized` — bit-identical to the `:raw` call — while the true standardized estimate (`standardized_loading_wald_ci`) is 0.91266. Validation refuses only wald_asym+raw and profile+standardized; the `:wald` branch unconditionally calls `raw_loading_wald_ci` and stamps rows with `scale`. R's `loading-ci.R` genuinely standardizes `Lambda_out` before its wald branch, so the mirror claim is also false. (Reported by Karpinski + Rose lenses; same defect.)\n\n**P1 — `src/confint_derived_wald.jl:111-134` (`_phylo_signal_packed`) + `src/confint_derived.jl:306-324` (`phylo_signal`) + `profile_ci_phylo_signal`: H² denominator excludes the phylogenetic variance.** CONFIRMED by code: both compute `(Λ_phy_aug Λ_phy_aug')[t,t]·d / Σ_y_site[t,t]`, and `_sigma_y_site_from_unpacked` (confint_derived.jl:153-176) adds only Λ_B, Λ_W, σ²_B, σ²_W, σ²_eps — the file's own comment says \"The phylogenetic block ... is not part of the per-site covariance\". R oracle (`profile-derived.R:145-156`) defines `H² = σ²_phy/(σ²_phy + σ²_non)`. So Julia H² = phy/non, unbounded above; at phy==non it returns 1.0 exactly, tripping `transformed_wald_ci_derived`'s interiority guard (`g_hat ≥ hi_bound` → `method=:failed`, NaN bounds), and >1 for stronger signal, contradicting every \"[0,1]\" docstring and the logit machinery.\n\n**P1 — `src/re_sd.jl:72-84` vs `src/postfit.jl` (`getLV`): getREsd SDs are in the unrotated basis while getLV defaults to `rotate=true`.** CONFIRMED by live run: `getREsd` row = [0.32361, 0.34301] (unrotated diag(M⁻¹)) vs rotated diag(RᵀM⁻¹R) = [0.31924, 0.34708]. No `rotate` kwarg, no docstring warning; the in-repo test pairs them only with `rotate=false`. Same defect applies to the Laplace-family methods.\n\n**P1 — `src/re_sd.jl:128-153` + family methods: predictor-informed (`alpha_lv`) non-Gaussian fits get silently wrong modes/curvatures.** CONFIRMED by code: `getLV` (postfit.jl, e.g. Binomial method) passes `lv_offset = Λ·(X_lv·α_lv)'` into `_laplace_mode`; `getREsd` has no `X_lv` argument, no `_has_lv_predictor` guard (defined for every family fit at postfit.jl:95-102), and `_laplace_re_sd` calls `_laplace_mode`/`_laplace_re_precision_site` with only the user offset — η missing the latent-mean term, so ẑ and W_s are wrong, no error. Contradicts the file's own line 155-164 honest-MethodError doctrine (which correctly guards AGHQ fits but not this).\n\n**P1 — `src/re_sd.jl:72-84` (`getREsd(::GllvmFit)`): no structural guard — silently wrong for phylo (`K_phy>0`/`has_phy_unique`), K_W-tier, and masked/offset Gaussian-record fits, while labeled \"EXACT\".** CONFIRMED by code: `Ψ = sigma_y_site(fit) − ΛΛ'` excludes the phylo block by construction and diagonalizes the W tier; no `_has_gaussian_record` guard, so masked fits get site-constant rows built from the full unmasked Σ. Contrast: `gllvmTMB_check_consistency` (diagnostics.jl:60-65) and the Binomial/Poisson AGHQ guards show the intended pattern.\n\n**P1 — `src/re_sd.jl:4-15` header: \"This is exactly TMB's `sdreport()` convention for random effects\" is false.** CONFIRMED against the R readback (`re-uncertainty.R:62-80`): TMB's default sdreport random-effect SDs DO propagate fixed-effect (θ̂) uncertainty (\"diag.cov.random reflects fixed-effect-uncertainty-propagated marginal variance\"; documented order-of-magnitude divergence near boundaries). Julia's quantity is the `ignore.parm.uncertainty=TRUE` conditional variant. Computation fine; claim wrong. Related confirmed mismatch: R's `getREsd(fit, block=...)` covers auxiliary RE blocks and explicitly assigns latent scores to `getLV(se=TRUE)`; Julia's `getREsd(fit, Y)` returns exactly the latent-score SDs under the mirrored name with a different signature, and no docstring mentions the R surface it shadows.\n\n**P1 — `src/confint_profile.jl:572-638` (`_tmbprofile_curve`) / `tmbprofile_wrapper`: mixed likelihood surfaces on Gaussian-record fits.** CONFIRMED by code: `profile_ci` short-circuits `_has_gaussian_record` fits to `_gaussian_record_confint` (:434-443), but `_tmbprofile_curve` has no such branch — its trace walks `_profile_refit_with_fixed`, which evaluates `gaussian_nll_packed` (:250, closed-form, no mask/offset/AGHQ), while the cutoff uses `fit.logLik` (record objective) and the attached `lower`/`upper` come from the record path via `profile_ci`. Trace, cutoff, and bounds live on different surfaces for AGHQ/masked/offset fits, silently. The param_index validation discrepancy (`length(terms)` in the record branch vs `length(θ_packed)` here) is also as described.\n\n**P1 (mechanism) — `src/confint_derived.jl:1043-1069` (`profile_ci_phylo_signal`) and :1015-1041 (`profile_ci_total_variance`): raw-c-space bracket/bisect with no feasibility clamp and no boundary flag.** CONFIRMED by code: both are thin wrappers over `profile_ci_derived` (quadratic penalty); the bisect helper returns the raw midpoint `(lo+hi)/2` with no range clamp, and plateau-below-cutoff cases surface as NaN/`:partial`, not \"bound = boundary\". `profile_ci_total_variance`'s \"handles that natively\" docstring claim is backed by nothing enforcing positivity. Note: for H² the \"upper bound > 1\" scenario is compounded by the H²-definition bug above (the Julia estimand is already unbounded). The exact >1-bound scenario was not reproduced live (needs a phylo refit campaign); the missing-protection mechanism is fully confirmed.\n\n**P2 — `src/diagnostics.jl:414-427` (`diagnose_kernel_separability`) and :489-502 (`compare_loadings`): \"principal angles\" from `svd(Λ_B'Λ_W)` on non-orthonormalized matrices.** CONFIRMED: singular values of raw Λ₁'Λ₂ are not angle cosines. Arithmetic check: Λ_B=Λ_W=0.2·ones(4,1) → σ_max=0.16, acos(0.16)=1.4101 rad (verified live) → identical column spaces reported `separable=true`; large loadings give σ>1, clamped to angle 0.\n\n**P2 — `src/diagnostics.jl:293-306` (`gllvmTMB_diagnose` correlation scan): implied Σ built as `ΛΛᵀ + σ_eps²I` only, ignoring σ²_B/σ²_W/Λ_W/phylo tiers `sigma_y_site` includes; no structural guard on the fit, so multi-tier fits get inflated correlations and spurious `correlation_near_boundary` → `pass=false`. CONFIRMED. Same defect in `_implied_Sigma_y` (:441-445).\n\n**P2 — `src/diagnostics.jl:279-291`: one `var_tol` applied to σ_eps/σ_phy (SD scale) and σ²_B/σ²_W (variance scale), all spelled \"variance_near_zero\" — thresholds differ by orders of magnitude across parameterisations. CONFIRMED by code (both lenses).\n\n**P2 — `src/twolevel.jl:508-509` (`repeatability_bootstrap_ci`): `cholesky(Symmetric(fit.Σ_B)).L` outside any try; Σ_B = Λ_BΛ_Bᵀ+diag(σ²_B) is only PSD, so a boundary fit throws `PosDefException` and aborts the whole call, inconsistent with the NaN-row convention. CONFIRMED by code.\n\n**P2 — `src/extractors.jl:310-315` (`extract_cross_correlations(::GllvmFit)`): `level` kwarg accepted and silently ignored (always forwards to the site-blended `extract_correlations(fit)`), unlike `bootstrap_Sigma`'s validate-and-throw pattern. CONFIRMED by code.\n\n**P2 — `src/extractors.jl:239-247` (`extract_communality(::GllvmFit)`) and :272-277: \"Mirrors ... at `level = \"unit\"`\" is numerically false.** CONFIRMED: R at level=\"unit\" divides shared by the unit-tier total from `extract_Sigma(level=\"unit\")`; Julia divides by the blended `Σ_y_site[t,t]` including σ²_eps and W tier — differs for every fit with σ_eps>0. Nuance: the Julia docstring's parenthetical does acknowledge the blend, so this is an overstated-mirror claim rather than a fully silent one.\n\n**P2 — `src/formula.jl:591-624` (`_source_term_covariance`): kernel `K` aligned to `sort(unique(gcol))` by row index; only the dimension is checked (:608-609), so a K supplied in tip/appearance order is silently permuted. CONFIRMED by code (lane-internal; sorted convention stated but unverified).\n\n**P2 — `src/confint_derived.jl:533-543` (`call_derived`): any `MethodError` raised inside a fit-consuming `derived_fn` triggers the silent `derived_fn(fb.pars.θ_packed)` fallback. CONFIRMED by code; failure needs a derived_fn that both throws an internal MethodError and accepts a vector — real but conditional.\n\n**P2 — `src/diagnostics.jl:64`: `isempty(fit.pars.β)` throws `MethodError` when `β === nothing` — a case the codebase explicitly defends against elsewhere (`_derived_spec`, confint_derived.jl:57, and :508). CONFIRMED by code.\n\n**P2 — `src/re_sd.jl:213`: NBFit's `AbstractMatrix{<:Integer}` signature gives a bare `MethodError` on Float64 counts where Binomial/Poisson give a clear `ArgumentError`. CONFIRMED by code.\n\n**P2 — `bootstrap_Sigma` (`src/confint_derived_wald.jl:800-826`): p(p+1)/2 independent full bootstrap campaigns with the same seed — O(p²)×n_boot refits doing O(n_boot) work. CONFIRMED; the docstring honestly records the cost, so this is a documented inefficiency, not a hidden one.\n\n**P2 — `src/confint_derived.jl:1053+` (`loading_profile` docstring) and `src/confint_profile.jl:735-758` (`profile_phylo_signal`): mirror-name/estimand hazards.** CONFIRMED with nuance: R's `loading_profile()` returns a long deviance-grid data.frame (`loading-profile.R`, `delta_deviance` column); Julia returns a single inverted bound — the docstring names the wrong R surface. `profile_phylo_signal` profiles raw `sigma_phy[t]` (docstring is honest) but its return NamedTuple carries no parameter-name field, so the R-parity-named output is unmarked at runtime.\n\n**P2 — `src/extractors.jl:378-395` (`extract_cutpoints`) and :226-233 (`extract_rotated_loadings`): \"Mirrors\" claims omit R's `tau_se` column (verified in `extract-cutpoints.R:32,72`) resp. the table-vs-tuple shape, with no deviation note unlike sibling docstrings. CONFIRMED (doc gap only).\n\n**P3 — `src/extractors.jl:499-501`: \"Still blocked ... getREsd ... no such accessor exists in GLLVM.jl yet\" while `src/re_sd.jl` implements and `src/GLLVM.jl` includes (:151) and exports (:195) `getREsd`. CONFIRMED at current HEAD. Same pattern: `test/test_se_machinery.jl:8-9` says \"Not wired into test/runtests.jl\" while `test/runtests.jl:221` includes it. CONFIRMED.\n\n**P3 — `src/twolevel.jl:485` docstring: \"(warm-started at `fit`'s own converged `K_B`/`K_W`)\" — only the ranks are reused; each replicate is a cold `fit_twolevel_gaussian` call. CONFIRMED as misleading wording. The companion `repeatability_wald_ci` missing-`:boundary`-tag note is a suggestion, not a defect (its failure mode surfaces as `method=:failed` NaN rows).\n\n## REFUTED\n\n**Fisher P2 — `standardized_loading_wald_ci` \"back-transform breaks at endpoints ... Inf ± z·se → NaN/Inf bounds with no boundary flag\": REFUTED.** `transformed_wald_ci_derived` (confint_derived_wald.jl:246-249) checks `g_hat ≤ lo_bound || g_hat ≥ hi_bound` *before* evaluating `h` and returns `method = :failed` with NaN bounds — the claimed Inf-arithmetic path is unreachable, and `:failed` is a flag (arguably mislabeled vs `:boundary`, but that is a naming quibble, not the claimed degeneracy). Near-boundary SE inflation is inherent Fisher-z behaviour with bounds still mapped inside (−1,1) by `tanh`.\n\n**Karpinski P2 — `confint_inspect` `findfirst` → `nothing` → `profile_ci(fit, nothing)`: DOWNGRADED to latent/plausible, not confirmed.** The `wald.term` strings come from the same `confint` name generator as `_confint_all_term_names`, including under a `parm` filter (a filtered subset is still a subset of `terms`), so no current input produces `nothing`. The fragility is real only against future divergence; the one-line guard is cheap hardening, not a live bug.\n\nAll other \"verified clean / non-issue\" claims in the four lens reports were spot-checked where cheap (family-marker dummy arguments, `fit.pars::NamedTuple` haskey use, interiority guards, `bootstrap_Sigma` level validation) and held.\n\nLive-evidence script: `/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-GLLVM-jl/9e47a792-aea6-48c0-a634-2b33b845c045/scratchpad/verify.jl` (run against `/private/tmp/GLLVM.jl-core070-aghq-20260830`, HEAD 85c502fb)."
  },
  "workflowProgress": [
    {
      "type": "workflow_phase",
      "index": 1,
      "title": "Review"
    },
    {
      "type": "workflow_phase",
      "index": 2,
      "title": "Verify"
    },
    {
      "type": "workflow_agent",
      "index": 1,
      "label": "review:numerical-correctness",
      "phaseIndex": 1,
      "phaseTitle": "Review",
      "agentId": "a31784c1b7df10865",
      "model": "claude-fable-5",
      "state": "done",
      "startedAt": 1788292659024,
      "queuedAt": 1788292657287,
      "attempt": 1,
      "lastToolName": "Bash",
      "lastToolSummary": "cd /private/tmp/GLLVM.jl-core070-aghq-20260830/.unlazy/core…",
      "promptPreview": "Committed post-M2 slice files in /private/tmp/GLLVM.jl-core070-aghq-20260830 (branch codex/core070-aghq-20260830): src/extractors.jl, src/re_sd.jl, src/diagnostics.jl, src/formula.jl (the new structured-term recognizer section only), the appended sections of src/confint_derived.jl / src/confint_derived_wald.jl / src/confint_profile.jl, src/twolevel.jl additions, and their tests (test/test_extracto…",
      "lastProgressAt": 1788293052220,
      "tokens": 205279,
      "toolCalls": 36,
      "durationMs": 391506,
      "resultPreview": "Findings (Gauss lens, numerical correctness), reviewed against `/private/tmp/GLLVM.jl-core070-aghq-20260830` at 450cc412.\n\n**P1 (statistical) — `src/confint_derived_wald.jl:111-133` (`_phylo_signal_packed`), with `phylo_signal_wald_ci` (:409), `_phylo_signal_wald_ci_all` (:320), and `src/confint_derived.jl:1038` (`profile_ci_phylo_signal`): H² denominator excludes the phylogenetic variance, contra…"
    },
    {
      "type": "workflow_agent",
      "index": 2,
      "label": "review:statistical-validity",
      "phaseIndex": 1,
      "phaseTitle": "Review",
      "agentId": "a13707a966a8370e8",
      "model": "claude-fable-5",
      "state": "done",
      "startedAt": 1788292658982,
      "queuedAt": 1788292657287,
      "attempt": 1,
      "lastToolName": "Bash",
      "lastToolSummary": "cd /private/tmp/GLLVM.jl-core070-aghq-20260830 && grep -rn …",
      "promptPreview": "Committed post-M2 slice files in /private/tmp/GLLVM.jl-core070-aghq-20260830 (branch codex/core070-aghq-20260830): src/extractors.jl, src/re_sd.jl, src/diagnostics.jl, src/formula.jl (the new structured-term recognizer section only), the appended sections of src/confint_derived.jl / src/confint_derived_wald.jl / src/confint_profile.jl, src/twolevel.jl additions, and their tests (test/test_extracto…",
      "lastProgressAt": 1788293124173,
      "tokens": 182963,
      "toolCalls": 42,
      "durationMs": 463459,
      "resultPreview": "Fisher lens review of the committed post-M2 slice at `/private/tmp/GLLVM.jl-core070-aghq-20260830` (HEAD 23fb43f9). Findings ranked by severity, one per paragraph.\n\n**P0 — none found.** No outright likelihood or interval-arithmetic error in the plain (non-record, non-phylo) support cells; the Gaussian getREsd identity, the logit/Fisher-z delta-method conventions, and the twolevel repeatability log…"
    },
    {
      "type": "workflow_agent",
      "index": 3,
      "label": "review:type-stability-ad",
      "phaseIndex": 1,
      "phaseTitle": "Review",
      "agentId": "ad7b149c5e4fe6826",
      "model": "claude-fable-5",
      "state": "done",
      "startedAt": 1788292659034,
      "queuedAt": 1788292657287,
      "attempt": 1,
      "lastToolName": "Bash",
      "lastToolSummary": "cd /private/tmp/GLLVM.jl-core070-aghq-20260830 && grep -n \"…",
      "promptPreview": "Committed post-M2 slice files in /private/tmp/GLLVM.jl-core070-aghq-20260830 (branch codex/core070-aghq-20260830): src/extractors.jl, src/re_sd.jl, src/diagnostics.jl, src/formula.jl (the new structured-term recognizer section only), the appended sections of src/confint_derived.jl / src/confint_derived_wald.jl / src/confint_profile.jl, src/twolevel.jl additions, and their tests (test/test_extracto…",
      "lastProgressAt": 1788293034124,
      "tokens": 164990,
      "toolCalls": 33,
      "durationMs": 373409,
      "resultPreview": "Review complete (lens: Julia engineering / Karpinski; scope: committed post-M2 slice files at `/private/tmp/GLLVM.jl-core070-aghq-20260830`, HEAD 450cc412). Findings, most severe first.\n\n**P1 (statistical/correctness) — `src/confint_derived_wald.jl:559-608` (`loading_ci`): `method = :wald` with `loading_scale = :standardized` silently returns RAW-loading CIs mislabeled as standardized.** The valid…"
    },
    {
      "type": "workflow_agent",
      "index": 4,
      "label": "review:api-doc-consistency",
      "phaseIndex": 1,
      "phaseTitle": "Review",
      "agentId": "a6307d00535be57c7",
      "model": "claude-fable-5",
      "state": "done",
      "startedAt": 1788292658880,
      "queuedAt": 1788292657287,
      "attempt": 1,
      "lastToolName": "Bash",
      "lastToolSummary": "cd /private/tmp/GLLVM.jl-core070-aghq-20260830 && grep -n \"…",
      "promptPreview": "Committed post-M2 slice files in /private/tmp/GLLVM.jl-core070-aghq-20260830 (branch codex/core070-aghq-20260830): src/extractors.jl, src/re_sd.jl, src/diagnostics.jl, src/formula.jl (the new structured-term recognizer section only), the appended sections of src/confint_derived.jl / src/confint_derived_wald.jl / src/confint_profile.jl, src/twolevel.jl additions, and their tests (test/test_extracto…",
      "lastProgressAt": 1788292972173,
      "tokens": 201070,
      "toolCalls": 36,
      "durationMs": 313293,
      "resultPreview": "Findings from the API/doc consistency (Rose-lite) review of the committed post-M2 slice in /private/tmp/GLLVM.jl-core070-aghq-20260830. All findings verified against the frozen R readback in `.unlazy/core070-aghq/oracle-source/readback/R/`. Six R files spot-checked: `re-uncertainty.R`, `loading-ci.R`, `loading-profile.R`, `profile-targets.R`, `extractors.R`, `extract-cutpoints.R` (plus line-number…"
    },
    {
      "type": "workflow_agent",
      "index": 5,
      "label": "verify-findings",
      "phaseIndex": 2,
      "phaseTitle": "Verify",
      "agentId": "a3ac18a91d4657b2c",
      "model": "claude-fable-5",
      "state": "done",
      "startedAt": 1788293129086,
      "queuedAt": 1788293125662,
      "attempt": 1,
      "lastToolName": "Bash",
      "lastToolSummary": "cd /private/tmp/GLLVM.jl-core070-aghq-20260830 && cat > /pr…",
      "promptPreview": "Adversarially verify review findings for /private/tmp/GLLVM.jl-core070-aghq-20260830 (read-only). For EVERY finding below, attempt to REFUTE it by reading the actual code and, where cheap, running a tiny julia snippet (~/.juliaup/bin/julialauncher --project=/private/tmp/GLLVM.jl-core070-aghq-20260830). A finding survives only if you confirm the defect is real with concrete evidence. Findings:\n\n===…",
      "lastProgressAt": 1788293539400,
      "tokens": 156459,
      "toolCalls": 28,
      "durationMs": 410314,
      "resultPreview": "All findings verified against the worktree at current HEAD 85c502fb (2 commits past the reviewed 450cc412/23fb43f9; none of the findings were fixed in between). Evidence is from direct code reading plus a live Julia run (small Gaussian K=2 fit
```
