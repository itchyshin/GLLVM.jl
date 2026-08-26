# Curvature-contract fault class — final ruling on structural closure

Lane: `/Users/z3437171/local-scratch/lanes/GLLVM.jl-beyond-20260824` (HEAD 08b40a98). Read-only
synthesis of the grouped_dispersion.jl and truncated_nbinom2.jl audits against the 11-kernel
contract (`hessian` selects the log-det curvature ONLY; the mode search is always Fisher-scored;
per-family defaults flow through `_default_hessian(family, link)`; `_glm_weight_matches_observed`
short-circuits the redundant branch). No Julia was run; every numerical claim below is either
analytic, a repo-recorded measurement, or flagged as a prediction.

## 1. Is the class structurally closed?

**No.** The generic core is closed — `laplace.jl`, `covariates.jl`, `quadratic.jl`,
`spde_latent.jl`, `phylo_glm.jl`, `coevolution_glm.jl`, `mixed.jl` and the phylo-XLV kernels all
route the selector to the log-det only, with `_default_hessian` as the single point of truth and
`_glm_weight_matches_observed` traits where Fisher ≡ observed. But two distinct debts remain, and
they must not be conflated in reporting because they are different fault classes with different
consequences:

### (a) Kernels that still CONFLATE the two roles (the original fault, still live)

`src/families/grouped_dispersion.jl` — **four of five grouped families**. In
`_nb_grouped_loglik_site` (:41/:55), `_beta_grouped_loglik_site` (:431/:445),
`_gamma_grouped_loglik_site` (:770/:784) and `_nb1_grouped_loglik_site` (:1114/:1128), the same
`hessian`-selected weight `W` is built twice: once inside the Newton loop (drives
`A = Λ'WΛ + I` and the step) and once after the loop (drives `logdet(A)`). Under
`hessian = :observed` the mode search itself runs on observed curvature — exactly the conflation
the programme removed from the generic core. Severity is tiered honestly:

- **Benign in outcome (Gamma, NB2):** the fixed point Λ's − z = 0 does not involve W, and both
  observed weights are provably ≥ 0, so A stays SPD. Path-and-tolerance difference only — but it
  is the second, unnamed contributor to the residual the team already paid for once
  (`test/test_grouped_dispersion_beta_gamma.jl:46-56`, the tol tightened 1e-9 → 1e-13).
- **Defective (Beta, plausibly NB1):** the observed weights (:413, :1097) have unsigned terms and
  Beta's is RECORDED as going negative (`laplace.jl:271-273`, measured). A can then be indefinite,
  and these loops have none of the shared `_laplace_mode` safeguards (no backtracking, no zero
  restart, no PD guard anywhere in 1640 lines). Even number of negative eigenvalues → `logdet`
  returns a finite wrong number silently. This is a reachable silent-wrong-answer path at the Beta
  grouped fitter's CURRENT default.

Tweedie grouped (:1433-1640) has no selector at all — hard-coded Fisher in both roles. That is
outside the contract but NOT conflated in the harmful sense; it is the old safe behaviour.

### (b) Kernels that HAVE the contract but whose defaults/traits are not wired

- `src/families/truncated_nbinom2.jl` — **does not conflate** (verified: the mode goes through
  `_grouped_laplace_mode` with no `hessian` argument; the selector reaches only the log-det). It
  is internally self-consistent at `:observed`. The debt is one level out: **no
  `_default_hessian(::TruncatedNegBin2, ::LogLink)` and no
  `_glm_weight_matches_observed`/`_glm_obs_weight` methods exist**, so the generic route
  (`marginal_loglik_laplace`, reached unconditionally by `test/test_truncated_nbinom2.jl:95`, plus
  mixed/covariates/quadratic/spde/phylo_glm/coevolution) defaults the same family to `:fisher`.
  Same model, two exported log-likelihoods — the exact fault `mixed.jl:250-256` documents for
  Gamma, mirrored. Bounded blast radius: not on the R bridge; no analytic-gradient path.
- `grouped_dispersion.jl` defaults are all hard-coded literals, not `_default_hessian` dispatch,
  and they are internally inconsistent: NB2/Beta/NB1 marginals default `:fisher` while their own
  fitters default `:observed` (fit then re-score at the estimates → different number than
  `fit.loglik`, no warning; only Gamma agrees with itself), and the grouped fitters disagree with
  their shared-precision twins at G = 1 (the same model). The `*GroupedFit` structs do not store
  the `hessian` used, and `getLV`'s mode (`_grouped_laplace_mode`, :68) is unconditionally Fisher.

One premise correction carried forward from the audits: the file does NOT have `hessian`
"throughout" (Tweedie has none), and there is no BetaBinomial grouped path in it at all.

## 2. Remaining work list (ordered)

1. **Fisher-score the mode in the four grouped site kernels.** Replace the in-loop selected
   weight with `_glm_weight.(fams, μ, n, me)` (what `_grouped_laplace_mode:78` and the Tweedie
   loop :1458 already do); leave the post-loop log-det selector untouched. Four call sites, no
   signature change. *Effort: small.* *Impact: removes the reachable silent-wrong-answer path for
   Beta/NB1 under `:observed`; restores the SPD/ascent guarantee for free; predicted (not run) to
   shrink the Gamma G=1 residual and retire the tol=1e-13 workaround.*
2. **Port the sign-keyed PD guard** from `laplace.jl:265-291` into grouped_dispersion.jl
   (`any(w < 0)` → guarded `cholesky`/`issuccess` → `-Inf`), independent of item 1 — it protects
   the still-selectable post-loop `:observed` log-det. *Effort: small.* *Impact: converts the
   even-negative-eigenvalue finite-wrong-number case into a clean rejection.*
3. **Route grouped defaults through `_default_hessian(family, link)`** instead of literals, making
   marginal and fitter of each family agree and grouped agree with shared at G = 1. Net effect:
   Gamma stays `:observed` (via its existing trait); NB2/Beta/NB1 grouped fitters revert to
   `:fisher` — which the measured evidence supports (Beta observed closer to quadrature only 2/12).
   *Effort: small.* *Impact: `fit.loglik` becomes re-scorable by the public marginal; one policy,
   one point of truth; user-visible default change for three grouped fitters (changelog entry
   required).*
4. **Wire TruncatedNegBin2 into the trait system:** add
   `_default_hessian(::TruncatedNegBin2, ::LogLink) = :observed` AND
   `_glm_obs_weight(::TruncatedNegBin2, ...) = _truncnb2_observed_weight(...)` (routes the generic
   core to the verified analytic formula instead of nested ForwardDiff); replace the two literal
   `:observed` defaults with `_default_hessian`. *Effort: small.* *Impact: closes the
   two-numbers-for-one-model split across six generic kernels.* **Gate:** this changes the number
   returned by the generic route — `test/test_truncated_nbinom2.jl:95-104` (FD-vs-AD) must be
   re-run before claiming green; parity test :92-94 asserting the objectives differ must be
   updated to assert they now agree.
5. **Store `hessian` in the `*GroupedFit` structs** (and note that `getLV` is Fisher-mode), so a
   fit object records which objective produced its loglik. *Effort: small-medium.* *Impact:
   reproducibility of reported fits.*
6. **Doc-drift sweep (five verified stale claims):** gamma grouped marginal docstring :799/:805
   (says `:fisher`, code says `:observed`); `fit_beta_gllvm_grouped` docstring :548 missing the
   `hessian=:fisher` G=1 qualifier its three siblings carry; Beta header comment :395 ("reduces
   EXACTLY") unqualified; truncnb2 :124-136 ("generic core hard-codes Fisher with no `hessian`
   keyword" — falsified by 6d9d3e1b the same day it was written); truncnb2 :115 advertising a
   `hessian` kwarg the signature does not have. Plus the dead local `N1` at :230. *Effort: small.*
   *Impact: docs stop documenting pre-flip behaviour.*
7. **Targeted probe** on `_beta_grouped_laplace_weight` (and NB1's) at realistic parameter values
   to confirm negativity by execution, upgrading the "defective" tier from well-supported to
   established. *Effort: small (one script).* Then **tighten the G=1 fitter tests** — `rtol = 0.2`
   at `test_grouped_dispersion_beta_gamma.jl:81,:102` is too loose to catch any of the above.
8. **Correct the design doc:** `docs/dev-log/plans/2026-08-25-laplace-structural-design.md:237`
   claims TruncNB2's generic-core support is "genuinely optional"; it is reachable in the default
   suite (`runtests.jl:48` → `test_truncated_nbinom2.jl:95`). *Effort: trivial.*

Items 1-3 + 6 are one coherent slice on grouped_dispersion.jl; item 4 + its gate are a second
slice; 5, 7, 8 can trail.

## 3. What should NOT be done

- **Do not touch `src/families/aghq_grid.jl`.** Fenced/parked by the maintainer. Its Fisher W at
  :203 is known and stays as-is until unfenced.
- **Do not flip `_default_hessian` to `:observed` for Beta or NB1 (shared or grouped).** The
  measured evidence is against it for Beta (observed closer to quadrature only 2/12); for NB1 and
  NB2 no measurement is cited at all. Only Gamma has 12/12 evidence. Flipping on symmetry rather
  than measurement is how the Beta grouped fitter ended up pointing away from the data in the
  first place. Item 3 deliberately reverts, not extends, those flips.
- **Do not add a `hessian` selector to the Tweedie grouped path** as part of this class. It is
  Fisher-in-both-roles, self-consistent, and there is no measurement motivating an observed
  log-det for it. Adding an unexercised selector is surface area, not closure. (If Tweedie ever
  gets the selector, it inherits the contract shape from items 1-3 for free.)
- **Do not build a BetaBinomial grouped path** to satisfy the brief — the brief's premise was
  wrong; `beta_binomial.jl` is separate and no such path exists to fix.
- **Do not claim the Gamma-residual shrinkage (item 1) as a result** until the tol=1e-9 identity
  is actually re-run; it is an analytic prediction, explicitly flagged as such in the audit.
- **Do not "fix" the marginals' Fisher-branch silence on non-log links in truncnb2** by making
  `:fisher` throw — failing loud is already the behaviour of the dangerous branch; widening throws
  on the safe branch changes public behaviour for no correctness gain.

## 4. Honest release-note paragraph

> The Laplace curvature contract (`hessian` selects the log-determinant curvature only; the
> latent-mode search is always Fisher-scored) is now enforced across the eleven generic kernels
> and verified by audit in the truncated NB2 kernel. Two gaps remain and are tracked: (i) the
> grouped-dispersion kernels for NB2, Beta, Gamma and NB1 still apply the selected curvature
> inside the Newton mode search as well as in the log-determinant — harmless in converged value
> for Gamma and NB2 (whose observed weights are provably non-negative), but for Beta, whose
> observed weight is measured to go negative, the unguarded loop can silently return an invalid
> log-marginal at the current `:observed` fitter default; until the fix lands, pass
> `hessian = :fisher` to the Beta and NB1 grouped fitters; and (ii) `TruncatedNegBin2` defaults to
> observed curvature through its own kernel but to Fisher through the generic
> `marginal_loglik_laplace` route, so the two exported entry points return different
> log-likelihoods for the same model by default. Grouped-fitter defaults for NB2, Beta and NB1
> also currently differ from their marginals and from the shared-precision twins; these will be
> unified under `_default_hessian`, changing three grouped-fitter defaults back to `:fisher` in
> line with the recorded quadrature comparisons (only Gamma's observed default is
> evidence-backed). No numerical claim here beyond the repo's recorded measurements has been
> re-verified by execution in this audit.

## Files

- /Users/z3437171/local-scratch/lanes/GLLVM.jl-beyond-20260824/src/families/grouped_dispersion.jl
- /Users/z3437171/local-scratch/lanes/GLLVM.jl-beyond-20260824/src/families/truncated_nbinom2.jl
- /Users/z3437171/local-scratch/lanes/GLLVM.jl-beyond-20260824/src/families/laplace.jl
- /Users/z3437171/local-scratch/lanes/GLLVM.jl-beyond-20260824/src/families/gamma.jl
- /Users/z3437171/local-scratch/lanes/GLLVM.jl-beyond-20260824/test/test_grouped_dispersion_beta_gamma.jl
- /Users/z3437171/local-scratch/lanes/GLLVM.jl-beyond-20260824/test/test_truncated_nbinom2.jl
- /Users/z3437171/local-scratch/lanes/GLLVM.jl-beyond-20260824/docs/dev-log/plans/2026-08-25-laplace-structural-design.md
