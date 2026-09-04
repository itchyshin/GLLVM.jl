# True R↔Julia parity — decision map (wayfinder), 2026-09-02

A decision map, not a build plan: it records what "true parity" means for GLLVM.jl against
gllvmTMB, what has been decided and where, what is still fog, and what is ruled out. The
map is finished when nothing is left to decide; the build slices then follow from it.
Companion plan (session-local): `~/.claude/plans/typed-churning-wombat.md`. Sister precedent:
the drmTMB ↔ DRM.jl true-parity map of the same morning (vault D-202).

## Destination

GLLVM.jl is at true parity with frozen gllvmTMB 0.7.0 (`b4d5fee64def88bc768dda1f1f77c29b295edd86`)
when all of the following are true and each is backed by a retained receipt:

1. Every **required** ledger row (`classification ∈ {required_core, compatibility_adapter}`;
   497 rows after D4 AGHQ reclassify 2026-09-04, was 505; reproduced by
   `tools/core070_ledger_counts.py`) is either bound to
   a receipt or carries a maintainer-signed disposition; no row is free.
2. Every paired family × route cell carries **first-order** receipts (log-likelihood at each
   optimum, point estimates, cross-objective identity in *both* directions) **and second-order**
   receipts — standard errors of every fixed parameter, the fixed-effect `vcov` block, and Wald
   confidence-interval endpoints on the link scale — at tolerances fixed in a committed contract
   (`second-order-parity-contract.md`), with each engine's Hessian convention stated.
3. At least one **realistic-size** cell per paired family (p ≥ 20, n ≥ 500) with its condition
   number recorded alongside the deltas.
4. At least one **real-data workflow** per qualified family/structure runs end-to-end through
   `engine = "julia"` exactly as a user would and passes the eight acceptance classes
   (`real-workflow-acceptance-lessons.md` §Standing rule; targets: the four Ayumi-495 repos).
5. The **grouping levels `unit`, `unit_obs`, `cluster`, `cluster2`** exist on both engines under
   those names and pair (owner requirement, relayed 2026-09-02 — see Decisions so far).
6. The **reverse direction** (what Julia has that R lacks) is a list produced by a tool
   (`tools/parity_ledger.py`, both directions at a git ref), each item a written decision.
7. `docs/src/gllvmtmb-parity.md` states in one place what parity does **not** mean.

Merges, releases, and registrations are separate owner ceremonies and are not part of this
destination.

## Decisions so far

| Decision | Answer | Recorded |
|---|---|---|
| Programme definition of parity | fixture parity + real-workflow acceptance cases = true parity; fixture parity alone is *harness* parity | `real-workflow-acceptance-lessons.md:56-62` |
| Oracle | frozen gllvmTMB 0.7.0 `b4d5fee6`; a build, not a version pin (the rebuilt CI oracle differs) | handover 2026-09-02:16; `ci-oracle-reproducibility-finding.md` |
| 12 maintainer decisions of 2026-09-01 | nobs p·n; cloglog was ours; tier-scoped estimands; draft PRs; 6 renames; `structure=` kwarg; phylo design first; Wald-only coverage; bulk triage; CairoMakie later; A6 fixed-df; ZI Julia-beyond | `decisions/2026-09-01-maintainer-decisions-round{1,2-3}.md` |
| **T1 Direction** (maintainer, 2026-09-02) | the **qualification claim is one-directional**: R workflows → Julia against 0.7.0. The reverse gap is a tool-produced written list handed to the gllvmTMB lane, never owed work here | `decisions/2026-09-02-maintainer-decisions-true-parity.md` |
| **T2 Oracle target** (maintainer, 2026-09-02) | **stay frozen at 0.7.0**; a re-freeze gate is scheduled right after the second-order contract lands (the 0.7.1 ψ→ψ² fix touches derived CIs only) | same |
| **T3 Second-order scope** (maintainer, 2026-09-02) | **SE + fixed-effect vcov block + Wald CI endpoints**; fitted/predict/residuals and paired recovery-to-truth are *not* in the claim | same |
| **Grouping levels** (owner requirement, RELAYED by the gllvmTMB lane 2026-09-02, verbatim intent: *"make sure both Julia and R have unit_obs, unit, cluster and cluster2 — it is important"*; and *"parity is about capabilities in both directions, but the bridge stays one-way"*) | **CONFIRMED 2026-09-04 (D6 Ada defaults).** New R→Julia required row family + naming rows keyed by the four level names. Measured: R exposes all four as `gllvmTMB()` arguments (`R/gllvmTMB.R:625-628`); Julia has `row_effects`/`RowRandomFit` and a Gaussian-only `TwoLevelFit`, no named `unit_obs`/`cluster`/`cluster2`. Engineering design: D5/D6 defaults in `maintainer-decision-set-2026-09-03.md`, detail in `t12-grouping-levels-design.md`. Compatible with T1 (capability both ways, claim one way) | this file; `maintainer-decision-set-2026-09-03.md` §D5–D6 |
| Compute for the ZI-trio ADEMP evidence | Totoro (Narval socket absent, Nibi in maintenance) | plan v1, approved 2026-09-02 |
| **ZI trio on the R side** (owner decision, RELAYED by the gllvmTMB lane 2026-09-02: chosen option *"Bring zip/zinb/zib to R"*) | **CONFIRMED 2026-09-04 (D6 Ada defaults) — already shipped.** R Arc D landed `zi_poisson()`/`zi_nbinom2()`/`zi_binomial()` (`R/families.R`; fids 17–19). Supersedes decision #12's "no R twin" **on the R side only**; Julia-forward `zip`/`zinb`/`zib` fitters unchanged. No new R build owed; rows pairable when Julia surfaces exist | `maintainer-decision-set-2026-09-03.md` §D6 |
| **Capability direction** (owner decision, RELAYED 2026-09-02: *"both ways, for user-facing capabilities"* — R ports the models a user would miss; engine-internal Julia-only rows are accounted for in writing; the bridge stays R→Julia) | consistent with T1: the *qualification claim* runs one way (R workflows → Julia against 0.7.0); *capabilities* are tracked both ways and the R lane owns the R-side ports. **Confirmed as vault D-204** (Shinichi in the drmTMB session, 2026-09-02: *"both ways for user-facing; keep the legacy rewrite; file the issues"*) | vault `DECISIONS.md` D-204; this file |
| Phylo transport Q1–Q4 | brought with recommendations and defaults; **no reply yet**, no code | `phylo-transport-questions-2026-09-02.md` |

## Not yet specified

Each line is a question, with who must be in the room and the default if the answer is "use your judgment".

- **T3-tolerances.** Which numeric tolerances make SE / vcov / Wald endpoints "the same"? *decide-with-Shinichi after the contract draft*; default: adopt the draft (SE rtol 1e-4 at the matched optimum with the observed Hessian on both sides; Wald endpoints abs 1e-4 on the link scale; vcov block relative Frobenius 1e-4; conditioning recorded, not gated).
- **T4 Realistic-size grid.** Which (p, n) cells and families first, and on which host? *decide-with-Shinichi after the se=TRUE pre-run timing*; default: Gaussian, Poisson, NB2 at p ∈ {20, 50}, n ∈ {500, 2000} on Totoro, one pre-run cell per family first (D-139).
- **T5 The 8 PARTIAL_PARITY_DEFECT rows.** Resolved by decisions #1/#3 and merely un-re-bound, or still defective? *task* (`parity-defect-rebind-2026-09-02.md`), then decide; default: re-bind on a passing verifier.
- **T7 Real-data acceptance runs.** Which of the four repos first, and how is data access granted? Needs gllvmTMB PR #1236 merged. *decide-with-Shinichi*; default: `urbanisation_map` first (an ACC-URBMAP cross-eval receipt already exists), then `avian_trait_scales`.
- **T8 AGHQ.** 8 unreachable policy rows **reclassified** 2026-09-04 (D4 DEFAULTED);
  **14 bindable rows** remain `BLOCKED_SPEC_DEFECT` pending public-fit receipts
  (`t8-aghq-bind-next-slice.md`). Was 22 BLOCKED_SPEC_DEFECT; 0/14 bind receipts.
- **T9 Promotion authority.** Is a Rose-scanned draft PR sufficient to flip a row's disposition, or does each need a maintainer sentence? *decide-with-Shinichi*; default: draft PR + Rose = proposal, maintainer merge = sign-off.
- **T10 Phylo Q1–Q4.** *decide-with-Shinichi*; defaults recorded in the questions note.
- **T11 Which of the 38 API-alignment collisions are R inconsistencies?** *research*, handed to the gllvmTMB lane with `r-side-defects-2026-09-02.md` (group E).
- **T12 Grouping-level rows.** Are the four level names the ledger keys (the R lane intends to use them for the twin board)? Does `unit_obs` map to a Julia observation-level random effect that does not exist yet (a new engine surface, not a rename)? *decide-with-Shinichi*; default: keys = the four names; `unit_obs` is a new required surface, sequenced after phylo transport unless the maintainer reorders.
- **T13 Ledger drift on our own status page.** `docs/design/capability-status.md` (this repo, also on `origin/main`) marks the missing-predictor `mi()` row `planned`, but `fit_gaussian_mi_fiml`, `fit_gaussian_mi_phylo`, `fit_gllvm_mi`, `fit_gllvm_mi_multi` are exported with tests (`test/test_mi_fitter.jl`, `test_missing_predictor_*.jl`) — found by the gllvmTMB lane's join of the two status pages (row names match byte-for-byte; their R ledger `docs/design/capability-status.md`, 76 rows, includes `unit / unit_obs / cluster / cluster2`). *task, then decide*: flip to `implemented` only with a pasted test receipt; default: flip after the receipt. Correction to an earlier message of ours: this file exists and is the exact-name join key for mission control, not the ledger `source_id`.
- **T14 NB2 second-order health.** Two independent NB2 signals today: Julia `confint` singular on the joint FD Hessian at a degenerate huge-dispersion optimum (se=TRUE pre-run), and CI Julia 1.12.7 `test_bridge_x.jl:350` NB2 grouped-covariate Wald interval NaN (passes on 1.12.6). **Diagnosed 2026-09-02** (`t14-nb2-wald-nan-diagnosis.md`): the seed-523 fixture is degenerate (two traits at the NB→Poisson boundary, r = 5e9 and 2.5e20); the Wald path has no boundary handling (all-NaN or `Inf` bounds); the test helper turns `Inf == Inf` into NaN; environment drift only selects the regime. *decide-with-Shinichi*: apply F1 (engine boundary flag + per-parameter SEs, red-first), F2 (well-conditioned fixture + explicit degenerate-pattern test), F3 (helper equality) — or a subset; default: all three, F1 last behind its own red-first test.
- **T15 Fixture sizes tuned on single seeds.** Corroborated on both sides on 2026-09-03: the R lane's shipped single-seed ZI recovery tests (sizes tuned on four seeds) hold in only 82 %/82 %/92 % of 50 seeds; on our side the seed-523 NB2 bridge fixture, the sentinel's "healthy" NB2 fixture and the first deterministic F1 test all sat on a knife edge (per-trait dispersion vs a free latent factor). *task then decide*: audit every parity/bridge/recovery fixture that pins one seed at small n; either assert the fit-health flags it relies on, or size it from a multi-seed sweep. default: audit first, list the knife-edge fixtures, then decide per file. Cross-ref: gllvmTMB `dev/gapclose/arcD/recovery/RESULTS.md` (FAM-22 cites our ZI findings doc).
- **Fog without a question yet.** M3 performance (Poisson 0.45–0.80× R) and Documenter; the beyond-parity missing-surface arc (76 required_core rows need a Julia surface); spatial and slopes engines; formula recognizers (change-control class); REML/EVA/full-VA variants; the frozen-R CI smoke re-expressed as a same-machine invariant.

## Out of scope

- **Two-directional qualification claim** — T1 says one-directional; Julia-beyond capabilities are recorded, not owed (the R lane decides on its side).
- **Re-freezing at 0.7.1 now** — T2; the ψ² fix and σ_eps slot split do not touch the first-order oracle; re-freeze gate after the second-order contract.
- **fitted / predict / residuals and paired recovery-to-truth as parity criteria** — T3 scope; they stay measured (wave-7 rows) but do not gate the claim.
- **Formula grammar and the R 0.7.1 response-column family** (`column_coef`, `*_coef`, `slope`, `*_slope`) — change-control class; R-only surface with no Julia counterpart (gap sheet §Class-1).
- **Spatial and slopes engines** — decision #7 sequences phylo transport first.
- **Interval *coverage* certification** — parity is capability + agreement; R's own certified regime is three Wald cells (gap sheet §Class-2).
- **CRAN / Julia General registration**; any edit under gllvmTMB, DRM.jl, drmTMB; the legacy `.unlazy/core070-aghq` ledgers (prior cycle; `leaf-A5.md:25` parse defect noted, not repaired here).
