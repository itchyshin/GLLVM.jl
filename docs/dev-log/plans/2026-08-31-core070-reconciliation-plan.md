# Ultra Plan — Core 0.7.0 + AGHQ reconciliation → OWED optimizer-health slice → parity-and-beyond

```
🎯 GOAL
Solo platform: Claude (this session; codex/core070-aghq-20260830 lane transferred to Claude by the
  committed 2026-08-31 handover — the Codex cycle is intentionally stopped)
Deliverable: (a) programme reconciliation recorded; (b) the OWED direct-native optimizer-health
  slice DIAGNOSED and, if warranted, repaired via TDD with the exact frozen gate re-run on Totoro,
  turning COV-ORD-LATENT-BARE from PARTIAL to PASS without weakening any gate; (c) an arc-loop
  goal file on disk that carries Milestone 1 closure → Milestone 2 (Core + AGHQ) → Milestone 3
  (performance/Documenter) toward true R–Julia parity and beyond.
HEADLINE: demonstrate (not assume) why BackTracking stalls on the default-mean path at an
  identical start vs Hager-Zhang, then make the minimal optimizer-selection repair.
IN PARALLEL: none required for the OWED slice (one lane, one blocker); recon reads only.
DEFER (fenced): Milestone 2 source-coverage/multinomial/data-postfit/Stage-1a-AGHQ qualification;
  Milestone 3 benchmarks + Documenter; any DRAC campaign; release/push/merge/destructive cleanup;
  R 0.7.1 gllvmTMB_main; article lanes; all foreign Cursor worktrees; full test suite runs.
DISCIPLINE: verify = frozen strict verifier + retained receipts + no tolerance widening ·
  compute = local diagnosis, Totoro for the frozen replay (ControlMaster socket, ≤150 cores,
  BLAS threads pinned to 1) · closure = evidence JSON flips to PASS + after-task report +
  Melissa reconcile + Rose audit; else an honest PARTIAL update.
```

## Context

The 2026-08-31 Codex→Claude handover (committed on `codex/core070-aghq-20260830`, worktree
`/private/tmp/GLLVM.jl-core070-aghq-20260830`) hands over a three-milestone Core 0.7.0 + AGHQ
programme frozen against gllvmTMB `b4d5fee6`. `COV-ORD-LATENT-BARE` is PARTIAL solely because the
**direct native default-mean fit** reports `converged=false` (gradient 1.674e-6 vs requested
`g_tol=1e-7`), while the frozen R, Julia-formula, and public R-bridge routes all converged and all
four routes agree to ~1e-7 or machine precision (Δloglik ≤ 5.7e-13). Shinichi has additionally set
the north star as **true R–Julia parity and beyond**, with unlazy gates, a wayfinder decision map
for the fog, and arc-loop execution.

## Phase 0.25 sweep receipt (gate for decomposition)

- **repo git state** → `[git status -sb; git log --all --diff-filter=A -- docs/dev-log/handover/2026-08-31*; git worktree list]` → handover lives on `codex/core070-aghq-20260830` (worktree `/private/tmp/GLLVM.jl-core070-aghq-20260830`, clean, HEAD `425cabf5`); main checkout is a different Claude branch with only `.claude/preview` noise → **resume the codex lane; do not rebuild**.
- **lane preflight (Shannon)** → `[~/shinichi-brain/tools/lane_preflight.sh <repo>]` → verdict `FOREIGN LANE ACTIVE (codex)`, live lease `codex:core070-aghq-20260830` on `src/,test/,docs/,tools/`; the committed handover + Shinichi's instruction transfer that lane to Claude → **claim the lane as Claude before writing (lane_lease.sh), state the takeover in the goal file**.
- **twin repo** → gllvmTMB frozen at `b4d5fee6` is the read-only oracle (handover Mission Control table); R 0.7.1 `gllvmTMB_main` protected → **reuse frozen reference; touch nothing**.
- **brain** → `[grep -in "aghq|core070" memory/DECISIONS.md + AGENT_LOG.md]` → AGHQ stays opt-in/earned-claims; "0.7 ships on Laplace + AGHQ"; no decision contradicts the programme → **no conflict; proceed**.
- **Mission Control** → `[git show 761222e --stat in shinichi-brain]` → commit `761222e` "Record latent bare handoff status" updates `Dashboards/mission-control/live/status/gllvmTMB.json` with `239dbd23` + `PARTIAL_DIRECT_NATIVE_FIT_HEALTH_UNPAID` → **board reconciled; update again at slice close**.
- **Verdict** → nothing to rebuild. The genuinely new work is the OWED optimizer-health diagnosis + minimal repair, then arc-looped Milestones 2–3.

## Handover request classification (OWED step 1)

| Handover request | Class |
|---|---|
| Lane preflight + classify | **DONE** (this plan) |
| Reproduce direct default-mean vs explicit-X fit from one identical start; record objective/gradient/line-search/stop reason | **OWED** |
| Decide Hager-Zhang for default-mean path; if yes TDD repair + frozen Totoro replay | **OWED** |
| Delegate Totoro replay if Claude can't run Julia/RCall | **RETRACTED as delegation** — Claude runs Julia locally and reaches Totoro via the standing ControlMaster socket; falls back to asking a live-toolchain lane only if the socket is absent |
| R 0.7.1, article lanes, foreign Cursor/Claude worktrees, frozen R reference | **PROTECTED** |
| Milestone 1/programme completion claims | **PROTECTED** (not claimable from this slice) |

## Wayfinder decision map (the "beyond" programme)

**Destination:** GLLVM.jl is a verified, Julia-idiomatic implementation of the frozen gllvmTMB
0.7.0 Core + callable Stage 1a AGHQ contract, with every required manifest row PASS/PARTIAL/BLOCKED
on fresh evidence, scoped measured performance wins, and executed accurate Documenter pages — a
local integration candidate demonstrating true R–Julia parity and named "beyond" capabilities.

**Decisions so far:** compare ΛΛᵀ never signed loadings; explicit `unique=false` bridge transport
is same-model; no tolerance widening ever; diagnose-before-code for the line search; release/push/
merge are separate gates; AGHQ claims stay earned/opt-in (brain DECISIONS).

**Not yet specified (fog — becomes arc-loop gates, not guesses):** exact "beyond" capability list
(what beats R, not just matches it); which correctness-qualified models enter the benchmark set;
Documenter page inventory; whether any DRAC array campaign is warranted and its pre-run test;
whether the BackTracking policy flip is global or default-mean-only (the diagnosis decides).

**Out of scope:** engine surgery on R gllvmTMB (hard boundary); R 0.7.1 lane; article lanes;
foreign worktree cleanup (destructive — separate authorization).

## Slice table

| # | Slice | Member | Model·effort | Dispatch | Time | Detail | Dep |
|---|---|---|---|---|---|---|---|
| S0 | RECON: claim lane lease as Claude; verify rehydration commands (`git status`, contract test) in the codex worktree | Shannon | Haiku·low | claude/model-param | 10m | `/private/tmp/GLLVM.jl-core070-aghq-20260830` | — |
| S1 | Identical-start diagnosis: run default-mean (BackTracking) vs explicit trait-intercept X (Hager-Zhang) source fits from ONE parameter vector; record objective, gradient, line-search trace, stopping reason; answer the roundoff question | Gauss | Sonnet·high | claude/model-param | 1–2h | `src/source_fit.jl:355-359`, `tools/core070_latent_bare_model.jl`, attempt05 receipts | S0 |
| S2 | Decision gate: does evidence show BackTracking stops on objective roundoff before the fresh-gradient gate? If NO → record honest finding, case stays PARTIAL with diagnosis. If YES → S3 | Ada | Fable (session) | — | 15m | evidence from S1 | S1 |
| S3 | TDD repair: preserve red attempt05; add narrow regression (default-mean source fit converges at g_tol=1e-7); minimal optimizer-selection change guarded so the trait-intercept path's prior fix is not regressed | Gauss | Sonnet·high | claude/model-param | 1–2h | `src/source_fit.jl`, `test/` | S2=YES |
| S4 | Frozen gate replay on Totoro (attempt06): exact contract, retained receipts, strict verifier; expect evidence JSON → PASS | Curie | Sonnet·medium | claude/model-param | 1h + queue-free run | `tools/core070_*`, `.unlazy/core070-aghq/latent-bare-model-06` | S3 |
| S5 | MECHANICAL-VERIFY: re-run strict verifier + contract test; confirm no tolerance/flag weakened (diff the contract SHA-256); negative controls still pass | Curie | Haiku·low | claude/model-param | 20m | `tools/core070_verify_latent_bare_model.py --self-test` | S4 |
| S6 | Close: evidence JSON, check-log, after-task report, Mission Control update + readback | Rose | Sonnet·medium | claude/model-param | 30m | docs/dev-log/*, shinichi-brain dashboard | S5 |
| S7 | RECONCILE: plan-vs-actual along the six axes → `docs/dev-log/plan-actual/2026-08-31-core070-optimizer-health.md` | Melissa | Sonnet·low | claude/model-param | 15m | routing receipt | S6 |
| S8 | Write arc-loop goal file for Milestones 2–3 (parity-and-beyond programme), gates from the decision map; launch loop | Ada | Fable (session) | — | 30m | `LOOP/` goal kit in the lane | S6 |

SEARCH: none (all evidence local). SCOUT SUITABILITY: yes — S0/S5 run on Haiku.
FAN-OUT BUDGET: ≤6 children, 0 ceiling children (Fable orchestrates inline). ULTRA EFFORT: no.
ESTIMATE: ~4–6 h wall-clock for S0–S7; fits one session; S8 hands the rest to arc-loop.
BARS: usage meters unreadable in this non-interactive session — noted as unknown; orchestration on Fable per D-151.

## Acceptance ledger (unlazy — Phase 2.5)

Reuse the existing `.unlazy/core070-aghq/` scope in the lane (already gitignored there). New gates
before dispatch:

- **G-S1**: identical-start comparison artifact exists with both optimizers' stop reasons.
  CHECK: retained JSON under `.unlazy/core070-aghq/optimizer-diagnosis-01/` names both line searches and stop reasons. EXPECT: non-empty, both routes present.
- **G-S3**: red-first regression test exists and fails before the repair, passes after.
- **G-S4**: `docs/dev-log/core070/latent-bare-model-evidence.json` status == PASS with
  `native_julia.converged == true` and `gradient_max <= 1e-7`... at the UNCHANGED contract SHA-256
  `a055bd33…`. A changed contract hash is an automatic FAIL.
- **G-S5**: all eight negative controls pass; verifier self-test passes.

Protected invariants (never gated away): no tolerance widening; convergence flag honored; frozen
R reference untouched; loading sign never compared; protected lanes untouched.

## Verification

1. S5's strict verifier + contract test are the machine check.
2. Own-the-verifier: S5 runs in a fresh Haiku context, not by the S3 author.
3. Totoro replay receipts retained beside attempts01–05; SHA-256 recorded.
4. D-43 completion panel fires only if S4 yields PASS and we claim the case closed (2 Sonnet + 1
   Opus fresh reviewers); PARTIAL outcomes skip the panel and report honestly.

## Execution notes

- Work happens ONLY in `/private/tmp/GLLVM.jl-core070-aghq-20260830` (branch
  `codex/core070-aghq-20260830`). Main checkout stays untouched.
- Totoro via existing `~/.ssh/cm-*totoro*` socket; `OPENBLAS_NUM_THREADS=1`, 1 Julia thread
  (matching attempt05's environment). If the socket is absent: flag once, do S1–S3 locally, and
  leave S4 as the arc-loop's first gate for a live-toolchain lane.
- Gotchas honored: LD_PRELOAD unset before `julia_setup`; both retained Manifests; explicit
  `gllvm_julia_setup(jl_path=<lane>)`; `Distributions` import in the Julia runner.
- Commit locally per concern; **no push** without explicit instruction.

PRE-AUTHORISED AFTER G0: scoped edits in the lane worktree; local Julia runs; the retained-receipt
runner; Totoro replay via the existing socket; local commits; checkpoints.
MUST STOP: push/merge/release; any contract or tolerance change; DRAC; edits outside the lane;
foreign-lane files; a Duo prompt.
