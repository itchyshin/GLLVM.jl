# Ultra-plan — honest-0.7 parity programme

**Written:** 2026-09-13. **Author:** Ada (Cursor lane), while Shinichi is away.
**Branch:** `cursor/gllvm-07-parity-programme-20260913` (fresh from `origin/main` @ `57ff35c5`).

## 0. Why this programme exists

Shinichi's instruction: **do not bump `GLLVM.jl` to 0.7 yet.** Build the durable programme to
*earn* honest 0.7.0 parity with frozen `gllvmTMB` 0.7.0 (0.7.1 only later if warranted). Versions
are independent (vault D-183's convention, which DRM.jl explicitly names as "the GLLVM.jl↔gllvmTMB
convention": the version number communicates *parity level*, earned by evidence, not a race with
the twin's release calendar). `GLLVM.jl`'s `Project.toml` reads `0.3.0` today and stays there until
a separate, later, maintainer-gated arc.

This slice does three things: (1) reads the current Destination B (DestB) numerical-parity
programme state — most of which lives only on the unmerged PR
[#318](https://github.com/itchyshin/GLLVM.jl/pull/318) — without touching it; (2) reads the
covariance-grid and second-order gaps already recorded on `main`; (3) turns both into a ranked,
durable arc list so the next agent (after #318's fix agent lands green CI) knows exactly what to
pick up, in what order, and why.

## 1. Evidence gathered (method: graft-first, read-only)

| Source | What it says |
|---|---|
| `docs/design/capability-status.md` (main) | Covariance grid: 7/15 cells `planned` (`phylo_dep`, `animal_dep`, `animal_latent`, `spatial_dep`, `kernel_indep/dep/latent`). Response families: 1 `missing` (multinomial/categorical, deliberately, with a fenced FE-only parity Δ). Model structure: random slopes `(1+x|g)` marked 🔨 in-progress. |
| `docs/src/gllvmtmb-parity.md` (main) | Parity is explicitly **harness parity, not true parity**. Second-order programme: **NOT DONE** — only a 5-cell toy pre-run (3 pass/2 blocked on θ-map). No realistic-size (p≥20,n≥500) receipts of either order. Qualification claim is **one-directional** (R workflows→Julia); the reverse gap is a tool-produced list (`tools/parity_ledger.py`: FORWARD=77, REVERSE=85 at the frozen oracle), a record not an obligation. |
| `docs/dev-log/core070/true-parity-decision-map.md` (main) | 7-point destination definition for "true parity". §Not yet specified: T5, T8, T11–T15 open. §Out of scope: two-directional claim, 0.7.1 re-freeze now, fitted/predict/residuals as a gate, formula-grammar R-only surface, spatial/slopes before phylo transport, interval-coverage certification. |
| PR #318 (`codex/destination-b-b1-integration-20260910`, read via `git fetch` + `git show FETCH_HEAD:…`, **not merged/checked out**) | Carries `docs/dev-log/2026-09-13-destination-b-g1-audit-matrix.md` (16 DONE / 7 OWED / 4 RETRACTED / 1 PROTECTED across B1/S3b/S4) and `-g2-closeout.md` (B1 → `CLOSED — INTERFACE LIMIT`; S3b consumer → qualified, adapter/test-scope only; S4 → `HELD`). CI is **currently red**: 7/10 checks fail, 8 test files with genuine Hessian-PD/curvature defects never exercised by CI before today (`Julia 1`/`Julia 1.10` shards 1–3; only shard 4 + Documenter pass). One unrelated `test_cv.jl:145` flake also fails independently on `main`'s own tip. |
| `docs/dev-log/decisions/destination-b-scope-reconciliation.md` (on #318) | The formal DestB scope is exactly 32 rows: A1–A15, B1–B4, C1–C5, D1–D8 (`node tools/destination_b_scope_check.mjs` verifies identity, not implementation). |
| `docs/dev-log/after-task/2026-09-13-destination-b-beyond-slice.md` (main, PR #319) | Confirms none of the DestB ledger/matrix content is on `main` yet; PR #318's merge attempt is the source of the CI-red finding above. |
| vault `DECISIONS.md` D-183 | DRM.jl versioning entry, which explicitly names and adopts "the GLLVM.jl↔gllvmTMB convention: the version communicates parity level with the R twin" — the citation for "versions independent" in this programme's own decision note. |

## 2. Gap inventory — ranked DONE / NEXT / BLOCKED

### DONE (evidence exists; not yet on `main` because it rides on unmerged #318)

1. **B1 marginal-curvature** — `CLOSED — INTERFACE LIMIT`. Two independent out-of-pipeline
   `TMB::MakeADFun` reconstructions against the frozen 0.7.0 binding both failed before
   `obj$fn()`/`sdreport()` — a rebuild-outside-the-pipeline limitation, not a GLLVM.jl curvature
   or singularity verdict. Both HOLD JSON receipts retained as honest FAILED artifacts.
2. **S3b R `phylo_rr` adapter-consumer** — `test/test_destination_b_adapter_consumer.jl` 97/97
   pass against frozen-R fixtures (tree, pedigree-with-ancestors, dense-`vcv`). Narrowly fenced:
   this is adapter/test-scope evidence, **not** B1 Wald inference, **not** full DestB, **not** S4.
3. **G1 static audit matrix** — 16 DONE items across B1/S3b/S4 (grouping-term vocabulary fixed,
   bridge dispatch entry point verified, rank-reduced df formulas symbolically aligned, S4 target
   formula locked in a validator, acceptance boundary documented as closed/private/non-public).

### NEXT (ranked; the 5 handed to whoever picks this up after #318 is green — see §3 below)

4. Fix #318's CI-red 8 test files (Hessian-PD/curvature defects) — **owned by the #318 fix agent**,
   not this lane; ranked #1 for them because nothing else in DestB can land on `main` until this
   clears.
5. Promote #318's G1/G2 docs + ledger reconciliation onto `main` once green (either via #318 itself
   or a clean docs-only split, per the 2026-09-13 after-task's own recommendation).
6. Covariance-grid gaps — 7 `planned` cells: `phylo_dep()`, `animal_dep()`, `animal_latent()`,
   `spatial_dep()`, `kernel_indep()`, `kernel_dep()`, `kernel_latent()`. None has a Julia engine
   yet. Rank by twin-user demand: `phylo_dep` and `animal_latent` are the two most likely to be
   asked for next (phylogenetic/animal-model users already have `indep`/`latent` on the same
   source; `dep` completes the row). Kernel row (Design 65) is a clean three-cell unit since
   `kernel_indep` alone would need the same dense-K plumbing as `kernel_dep`/`kernel_latent`.
7. `B1-RECOVERY` (Monte-Carlo recovery evidence for the grouping curvature contract) — needs a
   pre-run + compute estimate (D-139 discipline) + Totoro/DRAC placement before it can start.
   Downstream of #318 landing.
8. S4 rehydration — two barriers, either one enough to block: (a) no fresh maintainer
   authorisation for the probe itself; (b) the recorder object `97214679c94cc4a6b9e02d3c2b03ccce516027d8`
   is an **unpushed** commit in the sibling `gllvmTMB` checkout (branch
   `codex/destination-b-s4-phylo-dep-formula-20260910`) — physically unreachable from any
   GLLVM.jl worktree until that branch is pushed to a gllvmTMB remote. Coordinate with the
   gllvmTMB lane to push it, *then* seek authorisation — do not seek authorisation for a probe
   that cannot physically run yet.
9. `API-BOUNDARY` and `FINAL-REVIEW` rows (32-row DestB scope) — named in the #318 G2 closeout as
   completely untouched. `FINAL-REVIEW` is, by design, the last gate — do not start it before
   everything above is closed or dispositioned.
10. Second-order programme gaps (`true-parity-decision-map.md` T5/T13/T14/T15) — smaller, more
    mechanical than the DestB numerical gates: T13 (flip `mi()` row to `implemented` with a pasted
    receipt) and T14 (NB2 Wald-NaN F1/F2/F3 fix decision) are both single-decision, bounded tasks.
11. Realistic-size grid + real-data workflow acceptance (T4/T7 in the decision map) — both
    **CLOSED at Ada-default** already (grid: Gaussian/Poisson/NB2 at p∈{20,50}, n∈{500,2000} on
    Totoro; workflow order: `urbanisation_map` → `avian_trait_scales` → …) but **execution is
    blocked** on gllvmTMB PR #1236 merging first for the real-data leg, and on Totoro compute
    allocation for the size grid.

### BLOCKED (named, cannot proceed without an external unblock)

12. **S4 probe** — blocked as in #8 above; do not attempt.
13. **0.7.1 re-freeze of the oracle** — blocked by design until the second-order contract lands
    (T2 decision); the ψ→ψ² fix touches derived CIs only, not the frozen first-order oracle.
14. **Two invalid realistic-size pairs** carried over from the CLAUDE.md snapshot — need an
    R-driver re-run with the seed named in the filename; not started.
15. **T11** (38 API-alignment collisions, which are R-side defects) — handed to the gllvmTMB lane;
    not this repo's action item.
16. **`Project.toml` version bump** — forbidden in this programme by explicit instruction; the
    final gated arc, requiring a maintainer go, sequenced after every item above.

## 3. Ranked next 5 arcs (for the fix/merge agent, after #318's CI is green)

1. **Merge #318** once its 8 test files pass CI, then promote the DestB G1/G2 record onto `main`
   (arc #4/#5 above) — this is the single highest-leverage unblock; almost everything else in
   DestB is either downstream of it or currently unreadable from `main`.
2. **Covariance-grid: build `phylo_dep()`** — the most-requested `planned` cell (completes the
   phylogenetic row alongside the existing `phylo_indep`/`phylo_latent`); needs a simulation
   recovery test per the repo's family-addition rule.
3. **B1-RECOVERY pre-run** — size and cost it (D-139), then run on Totoro/DRAC once #1 lands.
4. **S4 rehydration coordination** — cross-repo ask to the gllvmTMB lane: push
   `codex/destination-b-s4-phylo-dep-formula-20260910` to a remote so the recorder object becomes
   fetchable; only then is a fresh S4 authorisation request meaningful.
5. **Covariance-grid: build `animal_latent()` + `kernel_{indep,dep,latent}`** — the remaining
   4 `planned` cells (animal_latent, kernel row); kernel row is a clean 3-cell unit (Design 65
   dense-K plumbing shared across all three).

## 4. What this slice explicitly did NOT do

- Did not touch #318's failing test/engine files or any `src/` engine code.
- Did not run the S4 probe or seek its authorisation.
- Did not bump `Project.toml`.
- Did not merge, mark-ready, or push to `main`.
- Did not build any new covariance-grid engine code — that is arc #2/#5 above, sequenced after
  this docs/gap-inventory slice, with its own tests.
