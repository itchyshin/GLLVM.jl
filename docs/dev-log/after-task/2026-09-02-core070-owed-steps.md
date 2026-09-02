# After-task — Core 0.7.0 handover: the four OWED steps + true-parity replan (2026-09-02)

Session: Claude Fable 5.1 (Claude Code), lane `codex/core070-aghq-20260830`, worktree
`/private/tmp/GLLVM.jl-core070-aghq-20260830`. Base: handover `df7009b3`. Plan file:
`~/.claude/plans/typed-churning-wombat.md` (v1 owed steps, approved; v2 true-parity replan, approved
with four maintainer answers). Acceptance ledgers: `.unlazy/core070-owed-20260902/` (3 leaves) and
`.unlazy/core070-true-parity/` (8 leaves), both written before dispatch, git-ignored.

**Honesty line, first:** the se=TRUE pre-run reported below is a 5-cell toy-fixture pre-run, not a
second-order parity claim. Nothing in this report claims parity beyond the first-order harness parity
already qualified in `core070/parity-panel-2026-09-01.md`.

## 1. Goal

Close the handover's four OWED steps with receipts — CI verdict for `df7009b3`; merge state of PR #277
and gllvmTMB PR #1236; the ZI-trio ADEMP recovery campaign actually run; the phylo-transport design's
four sub-questions brought to the maintainer — then, on the maintainer's request, replan toward TRUE
R↔Julia parity with a wayfinder decision map and unlazy acceptance gates. No push while the CI run lives.

## 2. Implemented

**Owed step 1 — CI verdict.** Run `33622687447` on `df7009b3` is the first CI run on this branch with no
push behind it. Advisory frozen-R smoke: `failure` (documented, expected; `ci-oracle-reproducibility-finding.md`).
Julia jobs: **`Julia 1.10 - ubuntu-latest`: `failure`** at 12:54Z — `Some tests did not pass: 13360 passed, 7 failed, 0 errored, 6 broken` (108m53s). Six failures are `@test_deprecated` log-pattern misses in the API-rename shims (`test/test_diagnostics.jl:250-262`, `test/test_se_machinery.jl:68,306`: the captured depwarn says "X is renamed to Y", the expected pattern is `r"deprecated"i`); the seventh is `test/test_phylo_branch_re.jl:139` — sparse vs dense scaled-precision solve differing at ~3e-8 relative against `rtol=1e-9`. Both classes pass on the local Julia 1.12.6 suite (13 325/0/0); diagnosis in `core070/ci-verdict-df7009b3.md` (environment drift, not the engine — 13 360 passes include every parity, cross-objective and recovery suite). No gate, tolerance or test was edited. `Julia 1 - ubuntu-latest` (julia 1.12.7): **`failure`** at ~13:12Z — `Some tests did not pass: 13362 passed, 8 failed, 0 errored, 6 broken`: the same seven plus one more, `test/test_bridge_x.jl:350` (`negbinomial Wald (grouped_cov)`: `d < 1e-8` evaluated `NaN < 1e-8` — the bridge or native NB2 Wald interval carried NaN on 1.12.7; it passes on local 1.12.6). Run conclusion: **failure**. The maintainer chose (AskUserQuestion, 2026-09-02) to apply the two test-side fixes — depwarn wording gains "is deprecated:" in the six shims; the phylo fixture mean is recentred from 1e8 to 10 with no tolerance change — verify them locally with `--depwarn=yes` on Julia 1.12 and 1.10.12, commit, and **push once** now that the run has concluded. The NB2 Wald NaN is NOT fixed by this: it is recorded as an open numeric finding (same family as the pre-run's NB2 singular Hessian) and the next run is expected to stay red on Julia 1 for that one test until it is diagnosed.

**Owed step 2 — merge state.** `gh pr view 277`: draft, MERGEABLE, mergeState `UNSTABLE` (checks pending
at the time of the read). `gh pr view 1236 -R itchyshin/gllvmTMB`: draft, MERGEABLE, mergeState `CLEAN`,
`ubuntu-latest (release)` pass 43m7s. Neither can be merged from this session (merge guard); the
maintainer presses merge. #1236 is ready now; #277 becomes decidable with the verdict above.

**Owed step 3 — ZI-trio ADEMP campaign.** Relocated from Narval to **Totoro**: Narval has no live
ControlMaster socket (D-64 forbids forcing a Duo prompt); Nibi's socket is live but the cluster is under
the `NibiMaintenance` reservation 2026-09-02 08:00 → 09-03 08:00 (all 778 nodes, 8 437 jobs pending).
Deploy + smoke + D-139 pre-run by a Haiku child (`core070/zi-ademp-totoro-deploy-receipt.md`): three
chunks (zip/zinb/zib, p=5, n=50, 25 seeds) — wall 0:36.85 / 1:21.27 / 0:21.85, max RSS 434 MB, all seeds
converged, outputs finite. Full run of the same 240-chunk cell map (`tools/zi-cells.txt` × 20 chunks,
identical to the sbatch mapping) launched 11:57:07Z under GNU parallel `-j 120` in
`/home/snakagaw/core070-aghq-20260830/zi-ademp-01/repo` (joblog `zi-ademp.joblog`, per-chunk logs in
`logs/`, outputs `zi-out/*.csv`). **Overrun re-report (D-139):** the pre-run measured only p=5 cells; the
p=25 cells fit at ~110 s per fit (zip, n=50) vs 1.6 s at p=5, so the second wave (100 chunks) runs
1–3 h beyond the 40–60 min estimate. Not killed: the run sits inside the approved envelope (≤ 120 cores,
now 100), and killing would discard finished work. State at 12:20Z: 140/240 chunks complete, 0 non-zero
exits, 240 CSVs open. **Run ended 14:06:54Z (2 h 10 m wall): 240/240 chunks, 0 non-zero exits, 240 CSVs, 6 000 fit rows, 0 error rows** (watch task output: `joblog rows 240 · nonzero exit 0 · csv files 240 · data rows 6000 · error rows 0`). ADEMP summary `core070/zi-ademp-recovery-findings.md` (raw CSVs + joblog under `core070/zi-ademp-out/`): convergence 100 % for zib in all four cells and for zip/zinb at p=5; at p=25, n=50 zip converges **35.0 %** (175/500, MCSE 2.1 pp; among converged fits βz bias median −0.80, RMSE median 3.86 — the worst cell on the grid) and zinb 70.0 %; at p=25, n=200 zip 96.2 %, zinb 98.6 %. Recorded as a small-n limitation of intercept-only zero-inflation at p=25, not a capability; no coverage or SE evaluated; no R twin exists (decision #12).

**Owed step 4 — phylo transport.** `core070/phylo-transport-questions-2026-09-02.md`: Q1 estimand
convention (recommend opt-in `correlation=true`, bridge always sets it), Q2 dense `vcv=` (admit, ship the
condition number, warn instead of silent jitter), Q3 kernel scope (split to S3b), Q4 non-ultrametric
trees (defer with `GJL-GATE-PHYLO-NONULTRAMETRIC`), each with a safe default. No phylo code.

**Replan (true parity).** Decision map `core070/true-parity-decision-map.md`; maintainer answers recorded
in `decisions/2026-09-02-maintainer-decisions-true-parity.md` (one-directional claim; oracle stays 0.7.0;
second-order scope = SE + fixed-effect vcov block + Wald endpoints; go). Knowable slices: ledger recount
(`tools/core070_ledger_counts.py`, `core070/ledger-recount-2026-09-02.md` — "required" = classification ∈
{required_core, compatibility_adapter}; TOTAL=769 REQUIRED=505 BOUND=285 DISPOSITIONED=220 FREE=0);
re-bind check of the 8 PARTIAL_PARITY_DEFECT rows (`core070/parity-defect-rebind-2026-09-02.md`: 4
extract_* rows LIKELY-FIXED on Julia tests only, 3 nobs rows + loading_profile need a paired batch or an
estimand decision — no row re-bound); R-side defect leads for the gllvmTMB lane
(`core070/r-side-defects-2026-09-02.md`, 34 leads, cloglog item removed as ours); second-order parity
contract DRAFT (`core070/second-order-parity-contract.md`, tolerances proposed for signature — see §10);
se=TRUE pre-run on Totoro (`core070/second-order-prerun-2026-09-02.md`: four families agree — max relative ΔSE on the β block: gaussian 1.02e-06 (σ_eps only), poisson 5.83e-06, binomial 4.49e-06, beta 2.22e-06; vcov block relative Frobenius 6.46e-06 / 1.09e-05 / 7.76e-06 / 5.98e-06; NB2 could not produce SEs on the Julia side: `confint` hit a `SingularException` on the joint 19×19 finite-difference Hessian at a degenerate huge-dispersion optimum while R's `sdreport()` returned finite SEs except the two boundary-trait `log_phi` entries — a numbered finding with a hypothesis, nothing tuned; all cells p=5, n≤80, unmatched coordinates);
both-direction parity-ledger tool (`tools/parity_ledger.py`, `core070/parity-ledger-run-2026-09-02.md`:
at the frozen oracle FORWARD=77 REVERSE=82 with 0 of 77 forward gaps untracked in the ledger; at 0.7.1 main FORWARD=85 REVERSE=82 with 8 untracked (`animal_coef`, `column_coef`, `kernel_coef`, `kernel_slope`, `phylo_coef`, `slope`, `spatial_coef`, `spatial_slope` — the response-column family that post-dates the oracle); `--self-test` SELFTEST_OK).

## 3a. Decisions and Rejected Alternatives

- Totoro over Nibi/Narval for the ZI evidence (compute-routing skill; D-201 "validate on Totoro before
  queue time"). Rejected: waiting for Nibi's maintenance window; forcing a Narval login.
- Not killing the overrunning ZI run (reversible, inside envelope) — re-reported instead.
- Maintainer: one-directional claim (rejected two-directional qualification); stay at 0.7.0 (rejected
  re-freeze now); second-order scope excludes fitted/predict/residuals and paired recovery.
- Rose's plan review moved the Hessian convention freeze before the Totoro dispatch and replaced a
  tautological grep gate with a manual read; both adopted.
- Re-bind verdicts corrected from RE-BINDABLE to LIKELY-FIXED: Julia-only test evidence does not bind a
  paired row.
- Melissa's reconciliation (K10) was run BEFORE the mechanical verify (K9), inverting the planned order, so
  that a forced session stop would still leave the plan-vs-actual record on disk while the CI verdict and
  ZI run were pending (pacing request of 2026-09-02). Melissa tagged the unrecorded inversion as drift; this
  line records it. K9 runs last and its result is appended to her file.

## 4. Files Touched

Created: `docs/dev-log/core070/{phylo-transport-questions,zi-ademp-totoro-deploy-receipt,true-parity-decision-map,ledger-recount,parity-defect-rebind,r-side-defects,second-order-parity-contract,second-order-prerun,parity-ledger-run}-2026-09-02.md`
(two without the date suffix: `true-parity-decision-map.md`, `second-order-parity-contract.md`),
`docs/dev-log/decisions/2026-09-02-maintainer-decisions-true-parity.md`, `tools/core070_ledger_counts.py`,
`tools/parity_ledger.py`, this report, `docs/dev-log/plan-actual/2026-09-02-core070-true-parity.md`.
Modified: `docs/dev-log/check-log.md`, `LOOP/core070-checkpoint.md`. Untracked run state:
`.unlazy/core070-owed-20260902/`, `.unlazy/core070-true-parity/` (git-ignored). No `src/`, no `test/`,
no tolerance, no CI file touched. Remote: Totoro `core070-aghq-20260830/zi-ademp-01/` and `se-prerun-01/`.

## 5. Checks Run

- `gh run view 33622687447` — see §2 step 1 (Monitor task polled every 180 s).
- Totoro pre-run: `/usr/bin/time -v` on three chunks (receipt); full run joblog: 140/240 at 12:20Z, 0 non-zero.
- `python3 tools/core070_ledger_counts.py …` → `TOTAL=769 … REQUIRED=505 BOUND=285 DISPOSITIONED=220 FREE=0`.
- `gate-check.mjs --reverify` (root = worktree): leaf-recount 2/2, leaf-map 2/2, leaf-rebind 2/2,
  leaf-rdefects 2/2 (manual gates with recorded evidence); leaf-contract 3/3 (CT-G2 failed once because the draft never spelled out "standard error"; the author expanded the acronym, the gate was not loosened), leaf-tool 2/2 (CHECK flag corrected from a guessed `--julia` to the tool's actual `--root`; same measurement), leaf-prerun 2/2;
  leaf-close **CLOSE_GATES_PLACEHOLDER**.
- Owed-steps ledger `.unlazy/core070-owed-20260902/`: **OWED_GATES_PLACEHOLDER**.

## 6. Tests of the Tests

- The ledger counter was written against a stated hypothesis and reproduced the handover's 505/285/220/0
  exactly; a wrong "required" predicate (required_core alone) gives 379 — the failure mode is visible.
- `parity_ledger.py --self-test` mutates an alias and requires the count to change (negative control).
- The contract gate CT-G2 failed on first run because the draft never spelled out "standard error"; the
  author expanded the acronym rather than the gate being loosened.
- Gate IDs in all 11 leaves were reformatted after the checker refused `ID (manual):` lines — the same
  defect that breaks the legacy `leaf-A5.md:25`.

## 7a. Issue Ledger

| # | Issue | State |
|---|---|---|
| 1 | CI Julia 1.10 red: 7 failures (6 depwarn wording vs `@test_deprecated` on 1.10; 1 sparse-vs-dense 1e-9 tolerance) | diagnosed, fixes PROPOSED not applied (src/test edits are outside this arc's envelope); PR #277 not mergeable until a fix commit gets a fresh green run |
| 2 | ZI campaign overran its D-139 estimate (p=25 cells unmeasured by the pre-run) | re-reported; running |
| 3 | Fisher-retained family list in `docs/src/gllvmtmb-parity.md` §Honest gaps is stale: source shows Binomial-cloglog (`src/families/binomial.jl:95`) and the Tweedie grouped route flipped to `:observed` on 2026-09-01; only GP-1 remains Fisher | open — docs cascade owed (Rose principle: check every neighbour of that section) |
| 4 | 4 extract_* defect rows need a paired re-run on the frozen oracle before re-binding | open — next arc |
| 5 | 3 nobs rows need `postfit-policy-batch-01` paired on Totoro; `loading_profile` needs an estimand-scope decision | open |
| 6 | Owner requirements relayed via the gllvmTMB lane (grouping levels on both engines; ZI trio to R; capabilities both ways) | recorded as RELAYED; **maintainer to confirm directly** |
| 7 | Legacy `.unlazy/core070-aghq` ledgers: 8 unmet, `leaf-A5.md:25` parse defect | carried over, untouched |

## 8. Consistency Audit

Walked the neighbours of each change: the decision map's Destination matches the maintainer's own
definition (`real-workflow-acceptance-lessons.md:56-62`) and the T3 scope (fitted/predict struck after Rose's
review); the recount script's predicate matches the handover's stated totals; the R-side list was vetted
for misfiled Julia defects (one removed); the contract's Fisher-retained sentence exposed the stale scoreboard
(issue 3); the cross-lane page from the drmTMB lane was checked line by line against this map (no
contradiction; ledger key here is the ledger `source_id`).

## 9. What Did Not Go Smoothly

Plan mode was toggled mid-execution and back; the approved v1 write action (launching the full ZI run) waited
for the toggle. The gate checker resolved the wrong working directory until `--root`/`--cwd` were passed
explicitly. zsh does not word-split a quoted `$SSH` variable; the launch script had to be inlined. The
pre-run sampled only the cheapest cells, so the campaign's wall time was under-estimated by 2–4×.

## 10. Known Residuals

- The second-order contract's **each-own-optimum** tolerances (SE rel ≤ 1e-2, vcov ≤ 1e-2, Wald endpoints
  ≤ 5e-2 of half-width) are the author's proposal and look loose next to the matched-coordinates column
  (1e-4); **the maintainer signs the tolerances (ticket T3-tolerances)** — nothing is adopted yet.
- No parity row changed disposition today; no capability claim is made.
- The ZI findings write-up (`zi-ademp-recovery-findings.md`) is DEFERRED until the run ends.
- Frozen-R CI smoke remains advisory and failing (documented state; re-expression as a same-machine
  invariant still owed).

## 11. Team Learning

A pre-run must sample the *most expensive* cell class, not the cheapest, or the D-139 estimate is fiction.
A scout's "RE-BINDABLE" on one engine's tests is not a paired receipt — the verdict vocabulary must name the
evidence class. Gate files must use `ID:` immediately after the checkbox; a parenthetical before the colon
silently breaks the checker (now known to be the legacy A5 defect). Rose verdict (S9): **ROSE_PLACEHOLDER**.

## 12. Cross-Product Coverage

Not covered (and not claimed): second-order parity beyond a 5-cell toy pre-run; realistic-size fixtures;
real-data acceptance runs (need PR #1236 merged + data access); the 76 required_core rows needing a Julia
surface; AGHQ receipts (0/39); phylo transport code; spatial/slopes; the reverse (Julia-ahead) ports on
the R side — owned by the gllvmTMB lane. Melissa plan-vs-actual: `plan-actual/2026-09-02-core070-true-parity.md`.
