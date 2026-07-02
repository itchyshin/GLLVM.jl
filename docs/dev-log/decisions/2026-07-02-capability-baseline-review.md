# Capability Baseline Review After LV Closeout

Date: 2026-07-02
Status: seven-hour capability-baseline goal, first truth-sync slice complete
Scope: GLLVM.jl handover worktree plus gllvmTMB Mission Control and capability
ledgers

## Decision

Use the next work block as a capability-baseline push, not a new compute or
formula-exposure slice. The LV arc is already closed as operating truth:
ordinary predictor-informed LV is covered, source-specific `lv` is fail-loud,
Phylo Model A evidence is frozen for the changed internal `B_eta_realized`
target, and mixed-family bridge claims stay complete balanced point/postfit
only.

The first safe improvement in this block is a wording repair in
`docs/design/73-predictor-informed-latent-scores.md`: the phylo future-wiring
requirements now say "future-only source-specific reopening" and explicitly
distinguish supported ordinary `latent(..., lv = ~ x)` from guarded
source-specific `phylo_latent(..., lv = ~ x)`.

## Sources Reviewed

- gllvmTMB Mission Control `status.json` and `sweep.json`: current operating
  board already says source guards are active, weak-cell reruns are retired,
  mixed-family `X`/`X_lv`/masks/missing/CIs are blocked, and no compute is
  active.
- gllvmTMB `docs/design/61-capability-status.md`: older random-slope synthesis
  dated 2026-06-18. It remains useful for structural random-slope rows, but it
  predates the LV closeout and should not be treated as the current
  source-specific `lv` story.
- gllvmTMB `docs/design/35-validation-debt-register.md`: row-level truth for
  structural random slopes and bridge cells. Rows such as PHY-17 and SPA-09 are
  structural random-slope evidence, not source-specific `lv = ~ env` evidence.
- GLLVM.jl `docs/design/73-predictor-informed-latent-scores.md`: current
  detailed LV spec. It had one future-requirements bullet that could be read as
  current admission guidance; that is now tightened.
- GLLVM.jl 2026-07-02 LV closeout notes: current truth-lock source for the
  next lane and blockers.

## Current Capability Baseline

| Surface | Current truth | Next action |
| --- | --- | --- |
| Ordinary `latent(..., lv = ~ env)` | Supported ordinary score-mean grammar and extractor route. | Keep covered; avoid reopening old evidence. |
| Source-specific `phylo/spatial/animal/kernel` `lv = ~ env` | Guarded/fail-loud; not support. | Keep parked unless Shinichi authorizes a new gated slice. |
| Structural random slopes such as `phylo_latent(1 + env | sp, d = 1)` | Separate grammar with its own R evidence rows. | Do not use as source-specific `lv` evidence. |
| Phylo Gaussian Model A | Internal Gate 0-3 evidence for `B_eta_realized`; old population `B_lv` route parked. | No public grammar exposure from this evidence alone. |
| Mixed-family bridge vector | Complete balanced point/postfit only. | Keep `X`, `X_lv`, masks, missing responses, and CIs blocked. |
| Non-Gaussian/source-specific LV | No inherited support. | New estimand, derivation, ADEMP plan, and claim wording gate. |

## Seven-Hour Work Order

1. Finish this truth-sync slice and commit it locally.
2. Run a bridge-capability drift audit focused on `src/bridge.jl`,
   `test/test_bridge_*.jl`, gllvmTMB `R/julia-bridge.R`, and
   `tests/testthat/test-julia-bridge.R`.
3. If drift is found and the files are safe to touch, add or tighten one guard
   test for unavailable mixed-family `X_lv`/CI status. If the only drift is
   wording, keep the change as docs-only.
4. Validate with focused text scans, `git diff --check`, and dashboard JSON
   parsing. Do not launch Totoro/DRAC jobs and do not mix host denominators.
5. Close with check-log, after-task report, local commit, and explicit remaining
   blockers.

## Do Not Do In This Goal

- Do not push or open/reopen a PR.
- Do not expose `phylo_latent(..., lv = ~ env)` or any source-specific `lv`.
- Do not modify likelihood code or package API.
- Do not touch the pre-existing dirty `src/confint_family.jl` or
  `test/test_phylo_xlv.jl` unless a later explicitly authorized slice needs
  them.
- Do not launch large compute on Totoro or DRAC.

## Rose Verdict

Rose verdict: PASS WITH NOTES - the first capability-baseline slice fixes a
wording drift without changing behavior. Remaining notes are deliberate
blockers: bridge drift still needs a focused audit, mixed-family intervals
remain unavailable, and source-specific `lv` remains parked.
