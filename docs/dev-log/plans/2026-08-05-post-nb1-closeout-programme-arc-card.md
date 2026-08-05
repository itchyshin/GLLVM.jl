# ARC CARD — Post-NB1 closeout programme (hygiene + Species-XB land + next Identity)

**Mode:** fixed capacity (owner: do 1+2+3 as one arc)  
**Requested outcome:** (1) NB1 ledger truth + live Δ recorded + `runparity`-safe NB1+X cell; (2) Species-XB Poisson light PR landed on `main`; (3) ACCEPTED next-family +X Identity Arc 0 decision  
**Mechanism authority:** docs/tests + rebase/push/PR for Species-XB; Identity Arc 0 = **docs-only** (no next-family engine in this programme). Merge Species-XB when CI green **after** owner G0 yes.  
**Recommended arc:** **~3.5 hours** (range **2.75–4.5 h**) as one capacity programme  
**Time contract:** fixed capacity fill for rungs 1–3; stop at Identity ACCEPTED (do not start engine Arc 1)  
**Estimate confidence:** measured (NB1 identity ~55 min; Species-XB cell already done; hygiene docs-only; rebase risk inferred from 18-behind + 5-file overlap)  
**Arc 0 outcome:** programme locked + worktree from `origin/main` @ `a100cc63`  
**State transition:** NB1 OWED/awaiting-merge fiction → MERGED+Δ; Species-XB unpushed → PR(/merged); idle next-family → Identity decision on disk  
**Executable rung and evidence:** live Δ already measured (abs `1.531e-9`); Species-XB prior Δ≈4.20e-9; Identity cites twin file:line

### Capacity ladder
| Order | Budget | Outcome | Trigger / definition of done |
| --- | ---: | --- | --- |
| Arc 0 / orient | 15–20 min | Fresh worktree from `origin/main`; classify Species-XB tip vs main | Start now after G0 |
| Rung 1 — Hygiene | 35–50 min | Board/AGENTS/capability-status/after-task Δ; `using Distributions` in X parity cell | After Arc 0 |
| Rung 2 — Species-XB land | 60–100 min | Rebase `parity/species-xb-light-20260804` onto tip; resolve board/`parity_helpers` overlap; push + PR; CI; merge if G0 allows | After Rung 1 (or fold hygiene into rebase tip) |
| Rung 3 — Next Identity Arc 0 | 60–100 min | Decision note ACCEPTED (Ada-default **BetaBinomial+X** unless G0 overrides) | After Rung 2 PR open (can parallel docs while CI runs) |
| Integrate/close | 15–20 min | Board START HERE; check-log; after-tasks; Actuals; STOP (no engine) | Always |
| **Total capacity** | **~210 min (3.5 h)** | | |

### Budget (whole programme)
| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient | 15–20 | Worktree + drift map |
| Core R1 | 25–35 | Docs truth + Distributions import |
| Core R2 | 45–70 | Rebase + PR body + CI watch |
| Core R3 | 45–70 | Twin recon + decision + identity tests scaffold only if docs need |
| Verify | 25–35 | Focused parity smokes; CI green |
| Repair reserve | 25–40 | Rebase conflicts on `parity_helpers.jl` / board |
| Closeout | 15–20 | Board + Actuals + STOP |
| **Total** | **~210** | |

**In scope:** 1+2+3 as listed; Ada-default next family = BetaBinomial+X identity (twin fid 8 / `log_phi_betabinom`; Tweedie user-path fail-loud — not default).  
**Not in this arc:** next-family engine/`grouped_cov`; Tweedie+X engine; ADEMP; Phylo Model A; Binomial species-XB expansion; Dropbox protected writes; `git add -A`.  

**Evidence used:** #186 MERGED `a100cc63`; NB1+X Δ abs `1.531e-9`; Species-XB tip `2d19318c` (18 behind / 7 ahead); overlap files with NB1: `AGENTS.md`, `capability-status.md`, `check-log.md`, `coordination-board.md`, `parity_helpers.jl`.  

**Risk branch:** If Species-XB rebase conflicts on `parity_helpers.jl` exceed ~40 min, land Species-XB as rebase-only PR and park Identity to a follow-on chat (still finish Rung 1). If twin shows BetaBinomial+X estimand ≠ per-trait, rewrite Identity choice — do not force API B.

**Done when:** (1) no “NB1 live Δ OWED / awaiting merge” on board; (2) Species-XB PR exists (merged if G0 yes + CI green); (3) next-family Identity decision ACCEPTED on a branch/PR; programme STOP before any engine.

**First action:** answer G0 below → then `/goal` on this ultra-plan.

### Actuals (complete at close)
**Recommended / actual:** 210 / — · **Requested / used:** 1+2+3 programme / — · **Rungs completed:** —  
**Under-run event:** —  
**Calibration:** —  
**Metric movement:** —  
**Result:** — · **Next arc:** Identity-accepted family engine Arc 1 (fresh `/arc-creation` or ultra-plan) only after this closes.
