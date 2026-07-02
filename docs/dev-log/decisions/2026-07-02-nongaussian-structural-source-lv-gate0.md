# Non-Gaussian Structural-Source LV Gate 0 Matrix

Date: 2026-07-02
Status: Gate 0 matrix; ordinary Gate 1 now includes Ordinal; phylo x Poisson S0 target, S1 likelihood proof, and private S1 selected-entry canary banked
Scope: non-Gaussian LV after ordinary selected-entry profile canaries

## Decision

Do not start source-specific non-Gaussian LV compute or grammar work from the
ordinary non-Gaussian canaries alone. The ordinary Poisson, Binomial logit, NB2,
Gamma, Beta, and shared-cutpoint Ordinal logit selected-entry `B_lv` profile-LR
canaries prove that native GLLVM.jl can route finite selected-entry profile
intervals in admitted ordinary one-part fits. They do not prove phylo, spatial,
animal, kernel, mixed-family, mask, missing-response, R bridge, or `unique=`
support.

The next structural-source step must be an estimand-first Gate 0 page for a
single source/family combination. No source-specific `lv = ~ env`, PR #127
reopen, package API widening, bridge promotion, Totoro diagnostic, DRAC claim
run, or public wording follows from this matrix.

2026-07-02 update: the first source/family S0 page is now banked for
phylo x Poisson in
`docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s0-target.md`.
The first internal S1 likelihood proof is now banked in
`docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s1-likelihood.md`.
The first private S1 selected-entry canary is now banked in
`docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s1-profile-canary.md`.
Together they reduction-test the combined phylo + Poisson + `X_lv` likelihood
surface and show one deterministic `B_eta_realized` truth-inclusion route, but
they do not expose a public fitter, bridge route, R grammar, coverage claim, or
source-specific support wording.

2026-07-02 update 2: the second source/family S0 page is now banked for
phylo x Binomial logit in
`docs/dev-log/decisions/2026-07-02-phylo-binomial-structural-lv-s0-target.md`.
This is symbolic alignment only. It does not add a likelihood proof, canary,
compute manifest, or support claim.

## Inputs

- Ordinary one-part selected-entry profile canaries are local for Poisson,
  Binomial logit, NB2, Gamma, Beta, and shared-cutpoint Ordinal logit in
  `test/test_lv_ci.jl`; the focused file passed `196/196` in 3m57.7s.
- The retired phylo population-`B_lv` evidence remains negative:
  `bootstrap_basic` `591/720 = 0.821`, optimistic cancelled-task bound
  `671/800 = 0.839`, task-8 `profile_truth` LR `9.9918 > 3.8415`, K = 1
  population profile gate `98/100`, and `profile_direct_slope` `96/100`.
- The Gaussian phylo `B_eta_realized` Gate 0-3 arc is internal evidence for a
  changed eta-scale realized/design-conditional target only. It is not public
  source-specific `lv` support and does not transfer to non-Gaussian families.
- R-side source-specific `lv = ~ env` remains fail-loud for phylo, spatial,
  animal, and kernel structural keywords and legacy aliases.
- The concurrent `unique=` lane is R/TMB-first and separate. It does not block
  this matrix, and this matrix does not start Julia `unique=` parity.

## Structural Source Order

| Source | Gate 0 truth | Next admissible target | Current boundary |
| --- | --- | --- | --- |
| Phylo | Best first source after ordinary, because Gaussian Model A internals and `Σ_phy` tests exist. | Phylo x Poisson now has an S0 target page, private S1 likelihood proof, and private deterministic selected-entry `B_eta_realized` profile-LR canary with finite endpoints and MLE/truth bracketing; next admissible target is an S2/Totoro diagnostic manifest, only if authorized. | No public `phylo_latent(..., lv = ~ env)`, no old population-`B_lv` reruns, and no source-specific claim until later evidence gates and maintainer signoff exist. |
| Spatial | Wait for the R/TMB `unique=` lane review and a separate Julia parity/join decision before any spatial-source inference claim. | Source covariance and SPDE support target must be explicit before a non-Gaussian LV canary. | Do not mix with the `unique=` lane or imply Julia parity. |
| Animal | Follows phylo/relmat derivation discipline. | Declare whether the target is realized link-scale, trait-scale, or source-level random-slope association. | No inheritance from ordinary LV or Gaussian phylo evidence. |
| Kernel | Requires dense/cross-kernel source derivation and a mean-vs-covariance confound audit. | Start only after source covariance, kernel overlap, and estimand orientation are written. | No source-specific `kernel_latent(..., lv = ~ env)` support. |

## Family Matrix

| Family block | Ordinary selected-entry `B_lv` profile | Structural-source status |
| --- | --- | --- |
| Poisson | Gate 1 local canary complete. | Phylo x Poisson S0 target plus internal S1 likelihood proof and deterministic selected-entry profile canary with finite endpoints banked; S2/Totoro manifest is the next possible diagnostic gate. |
| Binomial logit | Gate 1 local canary complete. | S0 target page banked; S1 still requires Binomial-specific reduction tests, trial-count guards, and a combined likelihood proof before any profile canary. |
| NB2 | Gate 1 local canary complete with fitted-dispersion guard. | Gate 0 only; source/family page must name dispersion treatment and stop rules. |
| Gamma | Gate 1 local canary complete with shape guard. | Gate 0 only; source/family page must name shape treatment and link-scale target. |
| Beta | Gate 1 local canary complete with precision guard. | Gate 0 only; bounded response and precision treatment must be explicit. |
| Shared-cutpoint Ordinal logit | Gate 1 local canary complete with ordered-cutpoint guard and no per-trait intercept. | Gate 0 only; source/family page must name cutpoint treatment, link-scale target, and whether per-trait ordinal parity is in or out. |
| Tweedie / zero-inflated / hurdle / Student-t | Not admitted for ordinary `X_lv` canaries in this arc. | Blocked until separate family likelihood derivation and tests. |
| Mixed-family vectors | Point/postfit boundary only in the bridge ledger. | `X_lv`, masks, missing responses, and CIs remain blocked. |

## Gate Ladder

- S0: write one source/family target page with model, estimand, DGP,
  constraints, pass/fail rule, stop rules, wording boundary, host plan, and
  rollback condition.
- S1: run one tiny local finite-route canary with selected-entry profile-LR,
  finite endpoints, MLE bracketing, known truth inclusion, and no public claim.
- S2: run a Totoro diagnostic only after S1 is green and a manifest is approved;
  keep host and denominator separate from DRAC evidence.
- S3: run DRAC seed-matched claim evidence only after S2 is stable and the
  denominator/MCSE rule is predeclared.
- S4: expose R grammar or bridge/public wording only after explicit maintainer
  authorization and Rose wording audit.

## Council Roles

- Ada: hold the scope to Gate 0 until a single source/family target is approved.
- Fisher: own the likelihood-ratio target and block bootstrap rescue language.
- Curie: own S1/S2 canaries and the ADEMP denominator.
- Gauss: own numerical feasibility and profile optimizer stop rules.
- Boole: keep source-specific `lv = ~ env` grammar fail-loud.
- Hopper: keep R bridge profile transport and Julia native routes separated.
- Grace: keep Totoro diagnostic and DRAC claim denominators separate.
- Rose: block "partial support", "inherits ordinary", "inherits Gaussian Gate 3",
  and "ready to expose" wording.

## Stop Rules

Stop before compute if the target page cannot name the estimand, DGP, selected
entries, host denominator, and rollback rule. Stop S1 if profile endpoints are
non-finite, the MLE is not bracketed, the selected truth misses with a converged
solve, or the fitter repeatedly underconverges. Stop interpretation if bootstrap
is used as a rescue label rather than a secondary diagnostic layer.

## Rose Verdict

Rose verdict: PASS WITH NOTES - this matrix is a safe Gate 0 boundary. Ordinary
non-Gaussian profile route evidence is banked for Poisson, Binomial, NB2, Gamma,
Beta, and shared-cutpoint Ordinal, and phylo x Poisson has one private S1
selected-entry finite-endpoint canary, but every public structural-source family
claim remains blocked until later evidence gates and claim audit exist.
