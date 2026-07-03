# Arc 1 Bridge / Grammar Audit

Audit date: 2026-07-03  
Roles: Hopper + Boole  
GLLVM.jl worktree: `/private/tmp/gllvmjl-phylo-xlv`, HEAD `2fdd7a6`, clean before audit.  
gllvmTMB reference: `/Users/z3437171/Dropbox/Github Local/gllvmTMB`, HEAD `9ee2ec8d`, broadly dirty and read-only for this audit.  
R note: `docs/design/73-predictor-informed-latent-scores.md` is absent in the inspected gllvmTMB checkout.

## Verdict

Next Arc 1 should expose truth about the current R<->Julia bridge ledger, not new R grammar.

Admit only a bridge/ledger slice: reconcile `GLLVM.bridge_capabilities()` with `gllvm_julia_capabilities()`, keep drift gate-labelled, and document that Julia low-level `bridge_fit(..., X_lv=...)` is broader than the R `engine = "julia"` formula admission surface. Do not expose source-specific `lv = ~ env` grammar in R or Julia-facing docs. Do not present structural random slopes, spatial/phylo `unique=`, or private structural-source `X_lv` likelihoods as parity evidence for source-specific `lv`.

## Admitted Bridge Truth

- Julia low-level `bridge_fit` admits complete-response, one-part `X_lv` routes for Gaussian, Poisson, NB2, Beta, Gamma, and binomial logit/probit/cloglog, with Wald `B_lv` payloads only; profile/bootstrap, masks, mixed-family `X_lv`, and source-specific `X_lv` remain separate gates (`src/bridge.jl:65-89`, `src/bridge.jl:491-510`, `src/bridge.jl:618-632`).
- The Julia capability ledger marks `predictor_informed_lv` for those one-part rows and explicitly leaves the mixed-family vector false (`test/test_bridge_capabilities.jl:57-74`, `test/test_bridge_capabilities.jl:159-178`).
- The Julia route tests verify the payload shape and decomposition (`scores`, `scores_mean`, `scores_innovation`, `alpha_lv`, `lv_effects`) and reject `X_lv + mask` / `X_lv + X` combinations (`test/test_bridge_lv_predictor.jl:24-57`, `test/test_bridge_lv_predictor.jl:78-139`, `test/test_bridge_lv_predictor.jl:158-215`, `test/test_bridge_lv_predictor.jl:233-293`, `test/test_bridge_lv_predictor.jl:311-367`).
- The R bridge admission surface is narrower. `gllvm_julia_fit()` has `X` and `mask`, but no `X_lv` argument (`R/julia-bridge.R:2119-2160`, `R/julia-bridge.R:2265-2288`). The main `gllvmTMB(..., engine = "julia")` dispatcher maps fixed effects and rejects structured terms; it does not parse or transport source-specific `lv` (`R/julia-bridge.R:2833-2874`, `R/julia-bridge.R:2930-3030`).
- R-side gate tests require gate-labelled bridge stops and drift detection (`tests/testthat/test-julia-bridge.R:416-472`, `tests/testthat/test-julia-bridge.R:599-646`).

## Blocked Grammar

- Source-specific `phylo_latent(..., lv = ~ env)` remains fail-loud. The evidence freeze says ordinary LV is covered, source-specific phylo `lv` remains fail-loud, mixed-family LV remains point/postfit only, and non-Gaussian/source-specific structural LV starts a new derivation/ADEMP arc (`docs/dev-log/decisions/2026-07-01-phylo-model-a-evidence-freeze-and-next-arc.md:9-23`, `docs/dev-log/decisions/2026-07-01-phylo-model-a-evidence-freeze-and-next-arc.md:67-76`, `docs/dev-log/decisions/2026-07-01-phylo-model-a-evidence-freeze-and-next-arc.md:91-116`).
- gllvmTMB Mission Control says `lv = ~ env` is rejected across phylo, spatial, animal, and kernel structural keywords and aliases; ordinary `latent(lv = ~ x)` evidence must not promote `phylo_latent`, `spatial_latent`, `animal_latent`, or `kernel_latent` grammar (`docs/dev-log/dashboard/status.json:978-982`, `docs/dev-log/dashboard/sweep.json:269-272`).
- Structural random-slope syntax, for example `spatial_latent(1 + env | site, d = K)`, is a separate route, not predictor-informed `lv` grammar (`docs/dev-log/dashboard/status.json:978-982`).

## Source-Specific LV Exposure Boundary

Internal structural-source work is route evidence only. The GLLVM.jl check log repeatedly states that private phylo x non-Gaussian `X_lv` likelihood/canary work added no public fitter, no R grammar, no bridge transport, no compute, no coverage calibration, and no source-specific support (`docs/dev-log/check-log.md:3-72`, `docs/dev-log/check-log.md:74-79`, `docs/dev-log/check-log.md:682-686`).

Current source-specific phylo evidence is also not a public bridge claim: the R dashboard records source-specific phylo LV as blocked/parked, with future exposure requiring explicit maintainer authorization despite Gate 2/3 evidence for the changed internal `B_eta_realized` target (`docs/dev-log/dashboard/status.json:936-969`, `docs/dev-log/dashboard/status.json:1137-1142`, `docs/dev-log/dashboard/status.json:1273-1280`).

Arc 1 can name the internal target and gate state, but cannot admit `phylo_latent(..., lv = ~ env)`, `spatial_latent(..., lv = ~ env)`, `animal_latent(..., lv = ~ env)`, or `kernel_latent(..., lv = ~ env)`.

## Spatial unique= Lane Separation

`unique=` is separate from the LV bridge/grammar lane. The R dashboard says the concurrent `unique=` implementation is R/TMB-first and does not touch `spatial_latent(..., unique=)`, `phylo_latent(..., unique=)`, `*_unique()` compatibility, or Julia spatial/phylo unique parity; Julia parity joins only after the R contract is green and a separate parity gate opens (`docs/dev-log/dashboard/sweep.json:39-42`, `docs/dev-log/dashboard/status.json:783-795`).

Therefore Arc 1 must not use any LV or bridge evidence to claim spatial `unique=` parity. Keep R/TMB spatial `unique=` separate from GLLVM.jl parity unless a later artifact shows a direct Julia route, R bridge transport, and parity tests for that specific surface.

## Next Safe Bridge Slice

1. Add no grammar. Keep source-specific `lv = ~ env` fail-loud.
2. Refresh the bridge truth table only: Julia low-level `bridge_fit` capabilities, R direct-wrapper capabilities, and main `engine = "julia"` dispatcher gates.
3. If adding tests later, make them drift/guard tests only: verify R does not overclaim `X_lv`, mixed-family, mask, CI, structured-term, source-specific, or `unique=` cells.
4. If public docs change later, use wording such as: "Julia low-level bridge has complete-response one-part ordinary `X_lv` payload routes with Wald `B_lv` payloads; R formula/source-specific grammar remains blocked unless separately admitted."
5. Defer all of these to separate arcs: R `lv=~env` source grammar, R bridge `X_lv` argument transport, R-vs-Julia `X_lv` parity, profile/bootstrap transport, mixed-family `X_lv`, response-mask `X_lv`, per-trait ordinal `X_lv`, and spatial/phylo `unique=` parity.
