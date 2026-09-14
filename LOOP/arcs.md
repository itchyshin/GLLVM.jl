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
| 3 | S4 Gaussian paired public-formula probe | **blocked** | `S4-PUBLIC-FORMULA` `NOT AUTHORIZED` / `HELD` | Two barriers: no fresh maintainer authorisation, **and** recorder object `97214679c` physically absent (unpushed commit in sibling gllvmTMB repo, branch `codex/destination-b-s4-phylo-dep-formula-20260910`) |
| 4 | #318 CI — Hessian-PD/curvature defects across joint/precision/grouped-nongaussian paths | **blocked (owned by #318 fix agent; CI re-run pending)** | blocks merge of arcs 1–2's evidence onto `main` | Fix stack through `89235578` (NB2-log PD knife-edge); prior red run `34790377224`; await green on `34791694556` before merge-when-green |
| 5 | B1-RECOVERY (Monte-Carlo recovery evidence for the grouping curvature contract) | **blocked** | `NOT AUTHORIZED`; downstream of arc 4 landing | Needs its own pre-run + compute estimate (D-139) + Totoro/DRAC placement before it can even start |
| 6 | `API-BOUNDARY` row (32-row DestB scope) | **blocked** | untouched | Named in the #318 G2 closeout as one of the rows nothing this programme has reached |
| 7 | `FINAL-REVIEW` row (32-row DestB scope) | **blocked** | untouched | Same; sequenced last by design — it is the "are we done" gate itself |
| 8 | Promote #318's G1/G2 docs + `.unlazy/destination-b-programme/GATES.md` reconciliation onto `origin/main` | **next** | unblocks all future DestB work from living only on one branch | Currently `docs/dev-log/2026-09-13-destination-b-g1-audit-matrix.md` / `-g2-closeout.md` exist only on #318; this repo's own gap inventory (`ultra-plan.md`) is built by reading that branch, not `main` |

## Covariance structure grid (15 cells; `docs/design/capability-status.md`)

| # | cell | status | gate? |
|---|------|--------|-------|
| 9 | `phylo_dep()` | **next** | `planned` — the twin's phylogenetic full-unstructured-trait covariance has no Julia engine yet |
| 10 | `animal_dep()` | **next** | `planned` |
| 11 | `animal_latent()` | **next** | `planned` |
| 12 | `spatial_dep()` | **next** | `planned` |
| 13 | `kernel_indep()` | **next** | `planned` — Design 65's dense-kernel row; none of the three kernel cells exist |
| 14 | `kernel_dep()` | **next** | `planned` |
| 15 | `kernel_latent()` | **next** | `planned` |

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
