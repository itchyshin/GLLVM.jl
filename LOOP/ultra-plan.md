```
🎯 GOAL
Solo platform: Claude (Claude Code — read from tools/session_ownership.sh; the `codex/…` branch is leftover naming)
Deliverable: a TRUE R↔Julia parity programme that is decidable and provable — (1) a committed decision map
  saying what parity means, what is decided, what is fog, and what it will never mean; (2) the knowable slices
  run now: a second-order (SE/vcov/CI) parity CONTRACT + its Totoro pre-run on the five paired families, a
  both-direction parity-ledger tool co-opted from DRM.jl, a deterministic recount of the ledger, a re-bind of
  the 8 estimand-defect rows, and the R-side defect list Shinichi asked this lane to hand the gllvmTMB lane;
  (3) an acceptance ledger `.unlazy/core070-true-parity/` written before dispatch and re-verified at close.
  All on lane `codex/core070-aghq-20260830`, local commits only, no push while CI run 33622687447 is live.
HEADLINE: second-order parity. Every one of the 40 paired cells runs se=FALSE; a wrong Hessian would pass every
  assertion today. Until SE/vcov/confint agree engine-to-engine on receipted cells, "parity" is first-order only.
IN PARALLEL: ledger recount (Haiku) · estimand-defect re-bind (same Haiku child) · R-side defects for the R lane
  (Haiku, running) · SE contract draft (Sonnet/Fisher) · parity-ledger tool port (Sonnet/Hopper) · Totoro se=TRUE
  pre-run (Sonnet/Gauss).
DEFER (fenced): any merge/release · phylo code (design under review) · formula grammar (change-control class) ·
  R 0.7.1 column_coef/slope family (R-only surface) · spatial/slopes engines · REML/EVA/full-VA variants ·
  CairoMakie · anything under gllvmTMB/, DRM.jl/, drmTMB/ · the four real-data acceptance runs until PR #1236
  merges and data access is confirmed (ticket T7) · re-freezing the oracle at 0.7.1 (ticket T2).
DISCIPLINE: verify = unlazy ledger, gate-check --reverify per leaf, Rose refutes one passing gate · compute =
  Totoro for the se=TRUE pre-run (≤30 min, D-139: state estimate, smoke first) · closure = map committed,
  every leaf gate met or ABANDONED with reason, Melissa plan-actual filed, `LANE:` line printed.
```

## PREFLIGHT (Shannon, Phase 0.2 — this session)
`lane_preflight.sh .` → **FOREIGN LANE ACTIVE (codex)** from the branch prefix; handover hands the lane to
Claude; worktree clean at `df7009b3` (+ this session's uncommitted docs). **Lane taken: Core 0.7.0 true-parity
replan.** Lease `claude:GLLVM.jl-core070-aghq-20260830:88432` GRANTED on `docs/dev-log/, LOOP/,
.unlazy/core070-owed-20260902/` — extend to `tools/parity_ledger.py` and `.unlazy/core070-true-parity/` on
approval. Other lanes: `overnight-parity-closure-20260828` (PR #274) untouched; **gllvmtmb-54** (Claude, R
repo) is scouting the reverse gap on the R side — coordinated by message, no shared files.
PLATFORM (read): `session_ownership.sh` → Claude Code. Session model Fable 5.1; usage bars not readable here.

## SWEEP RECEIPT (Phase 0.25 — every line cites what ran)
- **repo git state** → `git status -sb; branch_drift_check.sh` (360 ahead / 2 behind main); ledger read by
  scout `recon-ledger` (`jq` over required-source-case-map.json) → 769 rows total, 379 `required_core`
  (215 bound / 76 needs-surface / 44 spec-defect / 36 open-question / 8 parity-defect); the handover's
  "505 required" is not reproducible from `required_core` alone → **task: deterministic recount (K1)**.
- **twin / sister repos** → gllvmTMB `origin/main a15f9e46a` (0.7.0 DESCRIPTION on this checkout; 0.7.1 on
  main per gap sheet); **DRM.jl `tools/parity_ledger.py`** reconciles both directions at a git ref and the
  drmTMB lane ran a true-parity decision map this morning (`~/.claude/plans/piped-dancing-floyd.md`, D-202)
  → **co-opt the tool and the map shape (K5, K7)**.
- **brain** → `search_notes("true parity gllvmTMB GLLVM.jl … second-order SE confint", search_all_projects)`
  → `docs/src/gllvmtmb-parity.md` (capability scoreboard, honest gaps), 2026-06-16 per-trait dispersion
  spec, 2026-07-03 handover (canonical-side question) → **reuse the scoreboard as the public "what parity is
  not" surface**. Deterministic greps: `grep -in parity memory/AGENT_LOG.md` → 2026-09-02 drmTMB true-parity
  entry (D-202); `grep -inE "^### .*(parity|twin|gllvm)" memory/DECISIONS.md` → D-23 (twins as one), D-94 (R
  half first), D-112/D-113 (0.6 intervals, 0.7 tracks), D-149/D-159 (LA-MSPL intervals); OPEN_QUESTIONS none;
  deep-research dr3/dr11/dr34 → **no prior decision defines second-order parity or directionality — fog**.
- **repo docs** (scouts `recon-evidence`, `recon-decisions`) → maintainer definition: *"Fixture parity + these
  acceptance cases = true parity; fixture parity alone is harness parity"* (real-workflow-acceptance-lessons.md:61);
  panel finding: nothing second-order compared, toy fixtures only, recovery never paired
  (parity-panel-2026-09-01.md:24-49) → **build the gap: second-order + realistic-size + acceptance runs**.
- **Verdict** → genuinely new: the decision map, the second-order contract + pre-run, the both-direction
  ledger tool, the recount. Reuse: DRM.jl tool, sister map shape, existing paired fixtures and batch template.

## ROUTE CHECK (Phase 0.6) → **MAP**
1. Destination writable? Yes (below). 2. Slices with "depends what we decide"? **Yes** — SE tolerance/scope,
directionality, oracle target, acceptance-run data access, AGHQ in-claim. 3. Output shapes? Undecided for the
acceptance runs and the promotion bar. ⇒ decision map first; only knowable slices decompose now.

## DECISION MAP (wayfinder)

**Destination.** GLLVM.jl is at true parity with frozen gllvmTMB 0.7.0 (`b4d5fee6`) when: every `required_core`
row is either bound to a receipt or carries a maintainer-signed disposition, with "required" defined in one
committed sentence; every paired family × route cell carries first-order AND second-order receipts (logLik,
estimates, cross-objective identity in both directions, SE/vcov fixed-effect block/Wald-CI endpoints — fitted/predict/residuals are collected but out of claim per T3) at
tolerances fixed in a committed contract, including at least one realistic-size cell per family with its
condition number recorded; at least one real-data workflow per qualified family/structure passes the eight ACC
classes through `engine="julia"`; the reverse direction (what Julia has that R lacks) is a written list produced
by a tool, each item a decision not drift; and `docs/src/gllvmtmb-parity.md` states in one place what parity
does NOT mean. Merges and releases are separate owner ceremonies.

**Decisions so far.** 12 maintainer decisions of 2026-09-01 (nobs p·n; cloglog was ours; tier-scoped estimands;
draft PRs; 6 renames; `structure=` kwarg; phylo design first; Wald-only coverage; bulk triage; CairoMakie later;
A6 fixed-df; ZI Julia-beyond) · frozen oracle = 0.7.0 `b4d5fee6` (handover:16; gap-sheet:9) · the eight ACC
classes and the four Ayumi-495 target repos (acceptance-lessons.md:56-75) · D-64/D-139/D-143/D-201 compute
rules · Q0 Totoro for ZI (approved with plan v1; run launched 11:57Z, 240 chunks) · phylo Q1–Q4 brought with
recommendations (phylo-transport-questions-2026-09-02.md).

**Not yet specified (the fog) — tickets.**
| # | Ticket (a QUESTION) | Kind | Recommendation · default if "use your judgment" |
|---|---|---|---|
| T1 | Is true parity ONE-directional (R workflows → Julia, against 0.7.0) or TWO-directional (Julia-beyond owed to R)? | decide-with-Shinichi | one-directional for the qualification claim; reverse gap = tool-produced list handed to the gllvmtmb-54 lane · default: one-directional |
| T2 | Oracle target: stay frozen at 0.7.0, or re-freeze at 0.7.1 (ψ→ψ² total-variance fix, σ_eps slot split, 9 new exports)? | decide-with-Shinichi | stay 0.7.0 for first- and second-order qualification; re-freeze gate scheduled right after the SE contract lands, because the ψ² fix touches derived CIs · default: stay |
| T3 | Second-order contract: which quantities and tolerances count as parity? | decide-with-Shinichi after K2 draft | SE rtol 1e-4 at the matched optimum (observed Hessian both sides), Wald endpoints abs 1e-4 on link scale, vcov fixed-effect block Frobenius rel 1e-4, fitted/predict/residual rtol 1e-6; conditioning recorded, not gated · default: adopt the draft |
| T4 | Realistic-size grid: p∈{20,50,100} × n∈{500,2000}, which families first, on Totoro? | decide-with-Shinichi after K3 timing | Gaussian + Poisson + NB2 first; pre-run one cell per family before any grid · default: as recommended |
| T5 | Are the 8 PARTIAL_PARITY_DEFECT rows (communality/correlations/proportions/Omega tier; loading_profile; 3 nobs rows) resolved by decisions #1/#3 and merely un-re-bound? | task (K4) then decide | re-run their cells; rows that pass re-bind, rows that fail become named defects · default: re-bind on pass |
| T6 | What does "required" mean (505 vs 379 vs 769)? | task (K1) | one committed sentence in the ledger README; counts regenerated by script · no decision needed unless the recount changes a disposition |
| T7 | Real-data acceptance runs: which of the four repos first, and how is data access granted? `urbanisation_map` already has a cross-eval receipt (ACC-URBMAP). | decide-with-Shinichi | urbanisation_map first (receipt exists), then avian_trait_scales; needs PR #1236 merged · default: wait for merge, prepare runner |
| T8 | AGHQ: 22 policy rows are BLOCKED_SPEC_DEFECT ("name an exact native policy call"); 0/39 AGHQ rows receipted. In-claim or a separate beyond track? | decide-with-Shinichi | in-claim only for rows with an R native anchor; the rest reclassified out with the reason recorded · default: reclassify |
| T9 | Promotion authority: is a Rose-scanned draft PR sufficient to flip a row, or does each disposition need a maintainer sentence? | decide-with-Shinichi | draft PR + Rose = proposal; maintainer merge = sign-off · default: that |
| T10 | Phylo Q1–Q4 | decide-with-Shinichi | already brought; defaults recorded in phylo-transport-questions-2026-09-02.md |
| T11 | Which of the 38 API-alignment collisions are R inconsistencies? | research (K6 → gllvmtmb-54 lane) | hand the list over; R lane verifies against R main |
| T12 | Owner requirement (RELAYED 2026-09-02): `unit`, `unit_obs`, `cluster`, `cluster2` on both engines; are the four names the ledger keys, and is `unit_obs` a new Julia surface? | decide-with-Shinichi (confirm the relay) | keys = the four names; `unit_obs` = new required surface sequenced after phylo transport · default: that |

**Out of scope (with reason).** Formula grammar and the R 0.7.1 response-column family (change-control class;
R-only surface, gap-sheet §Class-1) · spatial/slopes engines (decision #7 sequences phylo first) · REML/EVA/
full-VA variants (never in the required set) · interval *coverage* certification (R's own claim moved to 3 Wald
cells; parity is capability + agreement, not coverage) · CRAN / Julia General registration · edits in
gllvmTMB, DRM.jl, drmTMB · `.unlazy/core070-aghq` legacy ledgers (prior cycle; leaf-A5.md:25 parse defect noted).

## SLICE TABLE — knowable now (Phase 1–2)

| # | Slice | Member | Model · effort | Dispatch | Time | Output (exact) | Dep |
|---|---|---|---|---|---|---|---|
| K0 | RECON (done) | Ada + 3 Haiku scouts | Haiku · low | Agent, explicit model | done | scratchpad/recon-{ledger,evidence,decisions}.md | — |
| K1 | **Ledger recount + "required" definition** | Rose (mechanical) | **Haiku · low** | Agent, explicit model | 20 min | `docs/dev-log/core070/ledger-recount-2026-09-02.md` + `tools/core070_ledger_counts.py` (jq/python, prints the table; the 505/379/769 reconciliation) | — |
| K4 | **Re-bind check of the 8 parity-defect rows** | Curie (mechanical) | Haiku · low (same child as K1, reused) | SendMessage | 30 min | `docs/dev-log/core070/parity-defect-rebind-2026-09-02.md`: per row, the verifier/batch found, re-run result on Totoro or "no runnable batch" | K1 |
| K6 | **R-side defects for the R lane** (running) | Hopper (mechanical) | Haiku · low | Agent, explicit model | 15 min | scratchpad/r-side-defects.md → copied to `docs/dev-log/core070/r-side-defects-2026-09-02.md`; summary sent to gllvmtmb-54 | — |
| K2 | **Second-order parity CONTRACT draft** | Fisher | **Sonnet 5 · high** (estimand judgment; Opus only if the derivation disagrees between engines — recorded) | Agent, explicit model, fresh | 45 min | `docs/dev-log/core070/second-order-parity-contract.md`: quantities, both-side Hessian conventions (TMB observed joint Hessian vs Julia `hessian=` selector, Fisher-retained families GP-1/cloglog named), tolerances proposed for T3, receipt fields extending delta-matched-contract.md, both-direction cross-objective rule | — |
| K3 | **se=TRUE pre-run on Totoro** (D-139, ≤30 min est.) | Gauss | **Sonnet 5 · medium** | Agent, explicit model, fresh | 45 min incl. smoke | on Totoro (oracle build `oracle-build-01/library`, env block in handover): for the five paired families (Gaussian, Poisson, Binomial-logit, Beta, NB2) take the existing paired fixture, fit R with `se=TRUE` and Julia with observed-Hessian SE, record SE vectors, vcov fixed block, Wald endpoints (fitted collected, out-of-claim per T3); write `docs/dev-log/core070/second-order-prerun-2026-09-02.md` with deltas and wall times. Smoke = one Gaussian cell first. No gate edits; disagreement = a finding | Hessian convention FROZEN before dispatch (Rose edit 2): observed joint Hessian on both sides — TMB structurally; Julia `hessian=:observed`; selector recorded in the receipt; K2 argues it, does not change it |
| K5 | **Both-direction parity-ledger tool** | Hopper | **Sonnet 5 · medium** | Agent, explicit model, fresh | 60 min | `tools/parity_ledger.py` ported from DRM.jl (`git show <ref>:NAMESPACE` read from the checkout `/Users/z3437171/Dropbox/Github Local/gllvmTMB` — verified: `b4d5fee6` is a reachable commit there, 160 exports; `origin/main` 168 exports vs GLLVM.jl export block; ALIASES/NOT_CAPABILITY tables seeded from the ledger's namespace rows) + first run saved to `docs/dev-log/core070/parity-ledger-run-2026-09-02.md`; unit test under `test/` only if pure-logic | — |
| K7 | **Decision map committed + questions asked** | Ada | Fable, inline | — | 20 min | `docs/dev-log/core070/true-parity-decision-map.md` (four sections above) · AskUserQuestion T1/T2/T3-scope/T7 | K0 |
| K8 | Rose plan-review (before K2/K3/K5 dispatch) | Rose | Sonnet 5 · medium | Agent, explicit model, fresh | 10 min | critique of this decomposition + sweep receipt non-vacuity → appended to the map doc | K7 |
| K9 | **MECHANICAL-VERIFY** | Rose (mechanical) | **Haiku · low** | Agent, explicit model, fresh | 10 min | `gate-check.mjs --reverify` on every leaf; outputs exist non-empty; `git status -sb` ahead (no push) | K1–K6 |
| K10 | **RECONCILE** | Melissa | Sonnet 5 · low | Agent, explicit model, fresh | 10 min | `docs/dev-log/plan-actual/2026-09-02-core070-true-parity.md` | K9 |
| — | IN FLIGHT from plan v1 (approved) | Ada | — | Monitor / bg | external | CI verdict 33622687447 → `ci-verdict-df7009b3.md`; ZI run on Totoro (started 11:57Z, 240 chunks) → findings via a Sonnet child when done; after-task report `2026-09-02-core070-owed-steps.md` | — |

SEARCH: none external (no novelty claim). tier-b offered? n.
PARALLEL: {K1→K4, K6, K2, K3, K5} after K8 · SEQUENTIAL: K8←K7 · K9←all · K10←K9.
FAN-OUT BUDGET: checkpoint=`true-parity-20260902` · new children = **5/6** (K1+K4 one Haiku, K6 Haiku [running],
K2 Sonnet [Fisher + Noether lens per Rose edit 7], K3 Sonnet, K5 Sonnet) · ceiling = **0** · K8/K9/K10 (+ the ZI findings child) fire after the next
user checkpoint = the answers to K7's questions. Reuse: K4 reuses K1's child.
SCOUT SUITABILITY: yes — K1/K4/K6/K9 are bounded mechanical work on Haiku.
ULTRA EFFORT: no. CONTEXT BRAKE: parent ≈ 110k tokens → **at the brake**: no forked children; every child gets
a self-contained brief (already the pattern); after K10, `LANE: START A FRESH TASK` with the map as first-read.
COMPACTIONS: parent=0. D-43 PANEL: not a milestone claim (no parity claim is made by this plan).
ESTIMATE: ~2.5 h wall this session for K1–K7 (K3 bounded by Totoro fits, ≤30 min; K5 the longest build);
K8–K10 ~30 min after the checkpoint; the CI verdict and ZI results land in parallel. Fits one session; the
decision-dependent work (T3 tolerances → full second-order batch; T4 grid; T7 acceptance runs) is the NEXT arc.
REVIEW: Rose (K8) + Fisher on the contract shape. VERIFY: K9 + Rose refutes one passing gate.
CONSOLIDATE: map + contract + tool + recount committed locally by name; check-log entry; LOOP append;
AGENTS.md snapshot line; lease released. RECONCILE: Melissa K10.

## ACCEPTANCE LEDGER (Phase 2.5 — `.unlazy/core070-true-parity/`, written before dispatch)
`GATES.md` OWNS: `docs/dev-log/core070/{ledger-recount,parity-defect-rebind,r-side-defects,second-order-*,
parity-ledger-run,true-parity-decision-map}-2026-09-02.md, tools/parity_ledger.py, tools/core070_ledger_counts.py`
(disjoint from `core070-owed-20260902` and the legacy `core070-aghq`).
- `leaf-recount.md` G1: `python3 tools/core070_ledger_counts.py docs/dev-log/core070/required-source-case-map.json`
  prints `TOTAL=769 REQUIRED_CORE=379` and one line defining "required" → EXPECT `LEDGER_COUNTS_OK`.
- `leaf-contract.md` G1 (manual): every quantity has a tolerance, a Hessian convention per engine, and a receipt
  field; G2 (manual, Rose reads it): a quoted sentence states how the Fisher-retained families (GP-1, cloglog) are treated.
- `leaf-prerun.md` G1: prerun doc has a per-family table with 5 rows and wall times (CHECK grep -c "^| " ≥ 6);
  G2 (manual): every delta is reported, none summarised away; disagreement rows carry a hypothesis, not a fix.
- `leaf-tool.md` G1: `python3 tools/parity_ledger.py --gllvmtmb "<path>" --ref b4d5fee6 --julia .` exits 0 and
  prints `FORWARD=<n> REVERSE=<m>`; G2: `--self-test` mutation negative passes.
- `leaf-map.md` G1: the map file has exactly the four sections in order (CHECK grep -c "^## \(Destination\|Decisions
  so far\|Not yet specified\|Out of scope\)" == 4 → `MAP_SECTIONS_OK`).
- `leaf-close.md` G1: `git log origin/codex/core070-aghq-20260830..HEAD | wc -l ≥ 1` and `git status -sb` ahead
  (no push); G2: Melissa file exists.

## PRE-AUTHORISATION ENVELOPE
```
PRE-AUTHORISED AFTER G0: scoped edits under docs/dev-log/**, LOOP/core070-checkpoint.md, tools/parity_ledger.py,
  tools/core070_ledger_counts.py, AGENTS.md phase-snapshot line; local commits by name; ssh/rsync over the EXISTING
  Totoro socket (BatchMode); Totoro fits ≤ 10 cores for K3/K4 (the ZI run already holds 120 → total ≤ 130 < 150);
  creating .unlazy/core070-true-parity/**; reading gh run logs; messages to the gllvmtmb-54 session (facts only).
OPTIONAL REMOTE AUTHORITY: none. NO push (CI verdict pending). NO PR edits.
MUST STOP: any push; merge/release; any src/ engine or test edit (this arc produces contracts, tools, docs, and
  receipts — not engine changes); any tolerance/gate edit on a disagreement; any Duo-triggering ssh; Totoro > 150
  cores; a Totoro pre-run exceeding 30 min; edits to another lane's files; a public parity claim.
```

## Verification and closure
1. `gate-check.mjs --reverify` on every `.unlazy/core070-true-parity/gates/leaf-*.md` → exit 0 or the unmet gate named.
2. K9 Haiku mechanical pass + Rose refutes one passing gate (she picks).
3. K10 Melissa plan-actual written; check-log + LOOP + after-task updated; lease released; `LANE:` line.
4. Final message MUST contain: "the se=TRUE pre-run is a 5-cell toy-fixture pre-run, not a second-order parity claim"; then what parity currently means (first-order, harness), what the pre-run found (second-order deltas),
   the map's open tickets with defaults, merge state of #277/#1236, ZI run status.
