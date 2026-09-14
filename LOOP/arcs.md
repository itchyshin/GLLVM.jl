# Arcs — honest-0.7 parity programme (from `ultra-plan.md`)

Status: `done` / `next` / `blocked` / `paused`. `paused` = awaiting Shinichi's named decision;
`blocked` = external dependency (another lane, a missing object, a maintainer sign-off). Ordinary
repair work in progress elsewhere stays visible here as `blocked (owned by #318 fix agent)`, not
silently dropped.

## DestB (Destination B) numerical gates

| # | arc | status | gate? | owner / evidence |
|---|-----|--------|-------|-------------------|
| 1 | B1 marginal-curvature (`B1-JOINT-STATIONARY`, `B1-JOINT-PAIR`) | **done** | `CLOSED — INTERFACE LIMIT` | Two independent out-of-pipeline `MakeADFun` reconstructions both failed before `obj$fn()`/`sdreport()`. `docs/dev-log/decisions/2026-09-13-destination-b-b1-close-as-limit.md` (on #318) |
| 2 | S3b R `phylo_rr` adapter-consumer | **done** | `S3B-CONSUMER` qualified, narrowly fenced (adapter/test scope only) | `test/test_destination_b_adapter_consumer.jl` 97/97 pass, tree/pedigree/dense-vcv fixtures (on #318) |
| 3 | S4 Gaussian paired public-formula probe | **paused** | G0 Q2: **push authorized**; **probe NOT until second yes** after fetch | Recorder `97214679c` still unpushed on gllvmTMB branch `codex/destination-b-s4-phylo-dep-formula-20260910` until G9 push slice |
| 4 | #318 CI — merge DestB G1/G2 docs onto `main` | **done** | — | Squash-merged `6c46873a` (2026-09-14); pre-merge 8/8 Julia + Documenter green; advisory Frozen R smoke red (OWED #322) |
| 5 | B1-RECOVERY (Monte-Carlo recovery evidence for the grouping curvature contract) | **paused** | `NOT AUTHORIZED` (G0 Q1 2026-09-14: B1 closed-as-limit **permanent**) | Off for this run unless Shinichi explicitly reopens grouping Wald evidence |
| 6 | `API-BOUNDARY` row (32-row DestB scope) | **done** | static PASS | `docs/dev-log/after-task/2026-09-14-destb-api-boundary.md`; `node tools/destination_b_scope_check.mjs` exit 0 @ `23fd0496` base |
| 7 | `FINAL-REVIEW` row (32-row DestB scope) | **blocked** | untouched | Same; sequenced last by design — it is the "are we done" gate itself |
| 8 | Promote #318's G1/G2 docs onto `origin/main` | **done** | — | G1/G2 markdown on `main` @ `6c46873a`; `.unlazy/destination-b-programme/GATES.md` remains gitignored / local-only |

## Covariance structure grid (15 cells; `docs/design/capability-status.md`)

| # | cell | status | gate? |
|---|------|--------|-------|
| 9 | `phylo_dep()` | **done** | `planned` — #324 @ `806b5476`; Arc 0 `fit_phylo_dep_gllvm` on `main`; ledger row unchanged until Rose/promotion |
| 10 | `animal_dep()` | **done** | `planned` — #325 @ `1ef979f`; Arc 0 `fit_animal_dep_gllvm` on `main`; ledger row unchanged until Rose/promotion |
| 11 | `animal_latent()` | **done** | `planned` — #327 @ `5e4f38b`; Arc 0 `fit_animal_latent_gllvm` on `main`; ledger row unchanged until Rose/promotion |
| 12 | `spatial_dep()` | **done** | `planned` — #329 @ `f110bf3`; Arc 0 fail-loud admission on `main`; ledger row unchanged until Rose/promotion |
| 13 | `kernel_indep()` | **done** | `planned` — #331 @ `5e9bfcd4`; Arc 0 `fit_kernel_indep_gllvm` on `main`; ledger unchanged until Rose/promotion |
| 14 | `kernel_dep()` | **done** | `planned` — #333 @ `c6f8233b`; Arc 0 `fit_kernel_dep_gllvm` on `main`; ledger unchanged until Rose/promotion |
| 15 | `kernel_latent()` | **done** | `planned` — #334 @ `9cb279e5`; Arc 0 `fit_kernel_latent_gllvm` on `main`; ledger unchanged until Rose/promotion |

7 of 15 grid cells are `planned` (not `implemented`). None is `blocked`/rejected outright except
`phylo_latent + lv = ~x` (Phylo Model A public intervals — already `rejected` by 2026-08-28
maintainer decision, out of scope here).

## Second-order / real-workflow programme (`true-parity-decision-map.md`)

| # | arc | status | gate? |
|---|-----|--------|-------|
| 16 | T5 — 8 `PARTIAL_PARITY_DEFECT` rows re-bind | **next** | needs a verifier task then a decision |
| 17 | T8 — AGHQ gate-tier promotion | **paused** | closed as compatibility-tier-only 2026-09-05 unless owner promotes |
| 18 | T11 — 38 API-alignment collisions, which are R-side defects | **blocked** | handed to the gllvmTMB lane |
| 19 | T13 — capability-status.md `mi()` row drift (exported+tested but marked `planned`) | **next** | small, mechanical: flip to `implemented` with a pasted test receipt |
| 20 | T14 — NB2 second-order health (Wald NaN at degenerate optimum) | **next** | diagnosed 2026-09-02; needs F1/F2/F3 fix decision |
| 21 | T15 — single-seed knife-edge fixture audit | **next** | audit first, then decide per file |
| 22 | Realistic-size grid (p≥20, n≥500) beyond the one pre-run cell | **blocked** | needs Totoro/DRAC compute allocation |
| 23 | Real-data workflow acceptance (T7: `urbanisation_map` → `avian_trait_scales` → …) | **blocked** | needs gllvmTMB PR #1236 merged first |

## Final gated arc (do not start until everything above is closed or dispositioned)

| # | arc | status | gate? |
|---|-----|--------|-------|
| 24 | `Project.toml` version bump `0.3.0` → `0.7.0` | **paused** | explicit maintainer go required; forbidden in this programme |
