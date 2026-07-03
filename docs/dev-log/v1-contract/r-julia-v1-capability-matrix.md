# R + Julia v1.0 Capability Matrix

Date: 2026-07-03

Status vocabulary:

| Status | Meaning |
|---|---|
| `covered` | Implemented, tested, documented, and admitted for the stated surface. |
| `partial` | Real implementation exists, but the row is missing parity, docs, tests, or a claim gate. |
| `point-only` | Fit/postfit payloads are admitted, but intervals or coverage claims are not. |
| `guarded` | Deliberately rejected or fail-loud until a named gate is cleared. |
| `blocked` | Not a v1.0 claim without a new derivation, design, or maintainer authorization. |
| `planned` | Useful future work, but not current capability. |

## Bridge Surface

| Row | `gllvmTMB` R truth | `GLLVM.jl` truth | v1.0 contract | Evidence | Next gate |
|---|---|---|---|---|---|
| No-X one-part families | `partial`: R `engine = "julia"` ledger admits Gaussian, Poisson, Binomial, NB2, NB1, Beta, Gamma, Ordinal, Ordinal probit. | `partial`: local `bridge_fit` admits Gaussian, Poisson, Binomial, NB2, Beta, Gamma, Ordinal only. | `partial` until the same family set is reconciled or differences are named gates. | `R/julia-bridge.R`; `src/bridge.jl`; `tests/testthat/test-julia-bridge.R`; `tests/testthat/test-julia-bridge-live-capabilities.R` in paired gllvmTMB commits `73af9258`, `96028892`, and `fa70b50d`; `test/test_bridge_capabilities.jl`. | Hopper reconciles row-by-row drift, especially NB1 and ordinal-probit. |
| Fixed-effect `X` bridge | `partial`: admitted for complete one-part rows for selected families; mask+X and unsupported designs are gated. | `partial`: local `bridge_fit` now admits Gaussian `X` only; non-Gaussian `X` remains fail-loud. | `guarded/partial`: Gaussian `X` is shared locally; non-Gaussian X rows stay registered drift. | `R/julia-bridge.R` gates `GJL-GATE-X-FAMILY`, `GJL-GATE-X-DESIGN`; `src/bridge.jl`; `test/test_bridge_capabilities.jl`; `test/test_bridge_fit.jl`; paired live R test `tests/testthat/test-julia-bridge-live-capabilities.R`. | Reconcile non-Gaussian X row by row; do not promote masks, mixed-family X, or source-specific LV. |
| Missing-response masks | `partial`: admitted for no-X point rows across selected families; mask+X remains gated. | `guarded`: local `bridge_fit` has no `mask` argument. | `guarded/partial`: no public broad mask parity. | `R/julia-bridge.R`; dashboard `LV structural dependencies`; `src/bridge.jl`. | Curie tests mask-only vs mask+X claims separately. |
| Mixed-family vector | `point-only`: complete balanced Gaussian + Poisson + Binomial point/postfit only. | `guarded`: local `bridge_fit` rejects mixed-family vectors. | `point-only` in R, `guarded` in local Julia until branch reconciliation. | `R/julia-bridge.R`; `tests/testthat/test-julia-bridge.R`; `tests/testthat/test-julia-bridge-live-capabilities.R`; dashboard mixed blocker. | Keep `GJL-GATE-MIXED-COMPONENTS`; no CI, X, X_lv, mask, or missing-response claim. |
| Structured terms through bridge | `guarded`: `engine = "julia"` rejects structured covariance terms. | `planned`: native Julia structured pieces exist in separate engine paths but not flat bridge parity. | `guarded`. | `R/julia-bridge.R` `GJL-GATE-STRUCTURED-TERMS`; dashboard source grammar row. | Do not bridge phylo/spatial/animal/kernel until a public contract and parity tests exist. |
| Multiple reduced-rank latent blocks | `guarded`. | `planned`. | `guarded`. | `R/julia-bridge.R` `GJL-GATE-MULTI-RR`. | Design first; no implicit widening. |

## Inference And CI Status

| Row | `gllvmTMB` R truth | `GLLVM.jl` truth | v1.0 contract | Evidence | Next gate |
|---|---|---|---|---|---|
| Wald CI no-X one-part bridge | `partial`: R ledger routes admitted rows except per-trait ordinal CI gates. | `partial`: local `bridge_fit` routes Wald for all seven local families, including Ordinal. | `partial`: support must be row-specific, not blanket. | `R/julia-bridge.R`; `src/bridge.jl`; tests listed above. | Fisher reconciles Ordinal family labels and native-vs-R CI status. |
| Profile CI no-X bridge | `partial`: R ledger routes complete-response no-X profile payloads for selected non-ordinal rows, including named post-fit `confint(..., method = "profile", parm = ...)` transport through `ci_parm`. | `partial`: local `bridge_fit` now routes no-X profile payloads for Gaussian, Poisson, Binomial, NB2, Beta, and Gamma, with optional `options["ci_parm"]`; Ordinal remains unsupported through the bridge. | `partial`: selected no-X non-ordinal profile transport is admitted; coverage calibration, masks, fixed-effect X, mixed-family, and source-specific structural profile CIs remain gated. | `R/julia-bridge.R`; `src/bridge.jl` `_bridge_compute_ci`; `test/test_bridge_capabilities.jl`; `test/test_bridge_fit.jl`; paired gllvmTMB live drift and selected-`parm` tests through commit `96028892`. | Fisher/Hopper next classify the remaining CI drifts: ordinal profile, masks, fixed-effect X, mixed-family, and bootstrap remain separate gates. |
| Bootstrap CI no-X bridge | `partial`: R ledger can refit admitted rows, but bootstrap remains secondary. | `partial/guarded`: local `bridge_fit` routes bootstrap only for Gaussian. | `partial`: no coverage calibration claim. | `R/julia-bridge.R`; `src/bridge.jl`; Mission Control claim guard. | Keep bootstrap as diagnostic; do not use it as rescue evidence. |
| Masked CI | `partial` for selected no-X mask rows in R ledger; mask+X blocked. | `guarded`: no local bridge mask route. | `guarded/partial`. | `GJL-GATE-MASK-X-CI`, `GJL-GATE-MASK-X`; `src/bridge.jl`. | Separate no-X mask CI from mask+X CI in tests and docs. |
| Fixed-effect-X CI | `partial` for selected complete-response rows. | `partial`: Gaussian `X` Wald/profile/bootstrap CI payloads route through native Gaussian CI methods; non-Gaussian `X` CI rows remain fail-loud drift. | `guarded/partial`. | `GJL-GATE-X-CI`; `src/bridge.jl`; `test/test_bridge_capabilities.jl`; paired live R Gaussian-X smoke. | Reconcile non-Gaussian X CI only after non-Gaussian X point rows are shared. |
| Mixed-family CI | `blocked`. | `blocked`. | `blocked`. | `GJL-GATE-MIXED-CI`; Mission Control mixed-family blocker. | No CI endpoints or empty intervals as support. |
| Source-specific structural `B_lv` intervals | `blocked/parked` for public v1 exposure. | Private plumbing and S2 runners only. | `blocked` without explicit maintainer authorization. | Mission Control phylo Model A rows; private S2 runner notes. | New ADEMP target and authorization before compute or grammar. |

## Formula, LV, And Structural Dependence

| Row | `gllvmTMB` R truth | `GLLVM.jl` truth | v1.0 contract | Evidence | Next gate |
|---|---|---|---|---|---|
| Ordinary `latent(lv = ~ env)` | `covered` for admitted ordinary Gaussian/binomial surfaces and guards. | Native ordinary selected-entry `B_lv` profile route exists for admitted families. | `covered/partial` by family and inference route. | Dashboard ordinary LV rows; `docs/dev-log/check-log.md`; `test/test_lv_ci.jl` in active lanes. | Keep family-by-family route evidence and avoid broad coverage wording. |
| Source-specific `lv = ~ env` | `guarded`: phylo/spatial/animal/kernel structural keywords fail loudly. | Private source-specific prototypes are not public API. | `guarded`. | `tests/testthat/test-canonical-keywords.R`; Mission Control source grammar blocker. | Boole guard tests before any syntax change. |
| Phylo Gaussian Model A public exposure | `blocked/parked` for v1. | Gate 0-3 evidence exists for changed `B_eta_realized`, not public grammar. | `blocked` unless Shinichi authorizes exposure. | Mission Control Model A rows. | Do not reopen PR #127 from this arc. |
| Phylo non-Gaussian structural LV | Private S2 runner readiness only. | All-six S2 runners are plumbing only. | `guarded`. | Mission Control all-six S2 runner row. | Separate authorized S2 endpoint-profile diagnostic, then DRAC claim evidence if stable. |
| Spatial/animal/kernel structural LV | Source-specific predictor-informed `lv` guarded. | Native support varies by structure; not bridge/public parity. | `guarded/partial` depending on row. | `tests/testthat/test-canonical-keywords.R`; `docs/design/61-capability-status.md`. | Matrix row must separate random-slope syntax from predictor-informed `lv`. |
| `unique=` | R/TMB spatial `unique=` lane is separate and R-first. | Julia parity not started by the LV closeout. | `partial/planned`. | Separate lane handoff; not a current GLLVM.jl parity row. | Wait for reviewed R contract before Julia parity. |

## Families

| Family | R bridge status | Julia bridge status | v1.0 contract | Notes |
|---|---|---|---|---|
| Gaussian | `partial` | `partial` | Admit no-X bridge, Gaussian fixed-effect `X`, and row-specific CI/status; keep Gaussian-only REML language. | Local Julia bridge routes Gaussian `X`, Wald/profile/bootstrap CI payloads, and ordinary cbind-free no-X rows; R ledger remains broader for masks and structured rows. |
| Poisson | `partial` | `partial` | Admit only tested one-part rows. | Structural-source phylo Poisson S2 runner remains private plumbing. |
| Binomial | `partial` | `partial` | Admit only tested standard-link rows. | Paired R commit `fa70b50d` routes ordinary `cbind(successes, failures)` rows as success-count `Y` plus trial-count `N`; `GJL-GATE-CBIND-BINOMIAL` remains for non-binomial cbind rows, invalid counts, and cbind with separate weights. |
| NB2 | `partial` | `partial` | Admit only tested one-part rows. | Dispersion scale must stay explicit. |
| NB1 | `partial` | `planned/absent in local bridge` | R-side partial; local Julia contract must not claim it unless branch reconciliation lands. | Drift row required. |
| Beta | `partial` | `partial` | Admit only tested one-part rows. | Precision scale must stay explicit. |
| Gamma | `partial` | `partial` | Admit only tested one-part rows. | Shared Gamma grouped-dispersion boundary remains explicit on R side. |
| Ordinal | `partial` | `partial` | Admit point/postfit and row-specific CI only where tested. | Per-trait ordinal CI and residual/simulate gates remain. |
| Ordinal probit | `partial` | `planned/absent in local bridge` | R-side partial; local Julia contract must not claim it unless branch reconciliation lands. | Drift row required. |
| Delta/hurdle/two-part | `partial/planned` | Native pieces exist outside bridge parity. | `planned/guarded` for v1 public parity. | Two-scale latent covariance requires derivation before structural LV claims. |

## v1.0 Promotion Rule

Before any row is promoted to `covered`, the implementing slice must provide:

1. implementation file path and exact public surface;
2. tests that cover success and at least one rejection or boundary path;
3. point estimate and logLik/objective parity where applicable;
4. CI endpoint or CI-status evidence, with empty/unavailable payloads treated
   as unavailable rather than support;
5. docs or examples if user-facing;
6. check-log and after-task report;
7. Rose verdict;
8. Mission Control refresh only if operating truth changed.

## First Action Items

1. Done in paired `gllvmTMB` commit `73af9258`: generated a compact drift
   report comparing R `gllvm_julia_capabilities()` against local Julia
   `GLLVM.bridge_capabilities()`, with 68 registered drift rows and zero
   unregistered rows when `GLLVM_JL_PATH` points at this checkout.
2. Done in paired `gllvmTMB` commit `73af9258`: tightened the synthetic drift
   test and added `tests/testthat/test-julia-bridge-live-capabilities.R`, which
   asserts that live drift is named by `GJL-GATE-*` gates.
3. Done in the matrix-supersession slice: the historical
   `docs/dev-log/capability-bridge-matrix.md` is superseded for the current
   v1.0 contract by this dated matrix, with its old `GLLVM.jl-integration` and
   `439/439` evidence retained as pre-v1 context only.
4. Only after the contract is stable, scope the queued selected beta-zero
   twin-lane from prior issues, PRs, and design docs in both repos.
5. Done in the selected-profile bridge slice: local `GLLVM.bridge_fit` now
   routes no-X profile CI payloads for the six non-ordinal local bridge rows,
   and the paired live drift test now reports 62 registered drift rows with
   zero unregistered rows.
6. Done in paired `gllvmTMB` commit `96028892`: R post-fit
   `confint(..., method = "profile", parm = ...)` now forwards named
   parameters as Julia `ci_parm` selections, with focused mocked and live
   JuliaCall tests. At that step, the live drift count remained 62 registered
   rows and zero unregistered rows.
7. Done in paired `gllvmTMB` commit `fa70b50d`: R `engine = "julia"` now
   marshals ordinary binomial `cbind(successes, failures)` responses as
   success-count `Y` plus trial-count `N`. The paired live drift test now
   reports 61 registered rows, zero unregistered rows, and zero cbind drift
   rows.
8. Done in the Gaussian fixed-effect-X bridge slice: local `GLLVM.bridge_fit`
   now routes Gaussian `X` point fits plus selected Wald/profile/bootstrap CI
   payloads through the native Gaussian engine. The paired live drift test now
   reports 57 registered rows, zero unregistered rows, and no Gaussian
   `fixed_effect_X` / `ci_x_*` drift rows. Non-Gaussian `X`, masks, mixed-family
   vectors, source-specific `lv`, and `unique=` parity remain gated.
