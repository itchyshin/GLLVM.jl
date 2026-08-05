# Ultra Plan — Post-NB1 closeout programme (1 hygiene + 2 Species-XB + 3 Identity)

```
🎯 GOAL
PLATFORM = Cursor (solo). Deliverable = one capacity programme that (1) closes
NB1+X ledger truth (board/AGENTS/capability-status + paste live Δ + make
NB1+X parity cell import Distributions so runparity can hit it); (2) rebases
and push/PRs Species-XB Poisson light cell
`parity/species-xb-light-20260804` onto current main; (3) writes ACCEPTED
next-family +X Identity Arc 0 decision (Ada-default BetaBinomial+X unless G0
overrides) — docs-only, no engine. HEADLINE = clear the post-#186 queue without
inventing a second engine in the same chat. IN PARALLEL (cheap): twin recon
cites for BetaBinomial `log_phi_betabinom` while Species-XB CI runs; confirm
Tweedie remains fail-loud for user light oracles. DEFER/FENCE: next-family
engine/`*_grouped_cov`; Tweedie+X engine; Binomial species-XB; ADEMP; Phylo
Model A; Dropbox protected writes; git add -A; “full family parity”; silent
rtol widen. DISCIPLINE: verify = board grep clean of OWED fiction + Species-XB
CI + Identity twin file:line; compute = laptop (RCall local); closure =
after-task(s) + check-log + board START HERE + STOP. After G0: hand to /goal
(fresh chat OK for ~3.5 h); do NOT Phase-3 in this planning turn.
```

**ARC PROGRAM:** fixed capacity · **~3.5 h (2.75–4.5)** · outcome = hygiene +
Species-XB land + next Identity · under-run → stop after green rungs (do not
pad with engine) · closeout = board + Actuals ·
file: `docs/dev-log/plans/2026-08-05-post-nb1-closeout-programme-arc-card.md`.

**Plan-mode note (once):** Cursor Plan-mode toggle is not auto-flipped here.
Phases 0–2 of this turn are **read-only planning**. Phase 3 execute waits for
explicit G0 approval + `/goal`.

**Phase 0.3b two-bar (AGENT-INFERRED):** Usage not opened this turn.
MODEL-ROUTING (2026-08-01): scout/rebase/CI → **Cursor Models**; Identity
prose / Rose fence → **Other Models**. Owner: glance bars before `/goal`.

---

## Context (orient)

| Fact | Evidence at plan-write (2026-08-05 local) |
| --- | --- |
| `origin/main` | `a100cc63` = Merge #186 (NB1+X Arc 1+2) |
| Live NB1+X Δ | abs `1.531e-9`, rel `1.379e-12` (focused cell seed=48) — **DONE this session** |
| Board fiction | still says live Δ OWED / awaiting merge |
| Species-XB tip | `parity/species-xb-light-20260804` @ `2d19318c` — **LOCAL DONE, unpushed** |
| Drift | `origin/main...species` = **18 behind / 7 ahead** |
| Overlap vs #186 | `AGENTS.md`, `capability-status.md`, `check-log.md`, `coordination-board.md`, `parity_helpers.jl` |
| Worktree hazard | `.worktrees/gllvmjl-species-xb-arc0-20260804` currently on `cursor/nb1-x-engine-arc12-fffd` @ `b1929734` — **do not treat as Species tip**; use fresh worktree or `git switch` carefully |
| Next +X candidates | bridge onepart **lacks** tweedie / exponential / betabinomial; twin **supports** betabinomial (fid 8, per-trait `log_phi_betabinom`); tweedie user path often **fail-loud** |
| Open PRs | none at plan cut |
| Dropbox | PROTECTED |

Authoritative pointers:  
`docs/dev-log/handover/2026-08-05-cursor-handover-nb1-x-arc12.md`  
`docs/dev-log/handover/2026-08-04-cursor-handover-species-xb-close.md`  
`docs/dev-log/coordination-board.md`  
Mirrors for Identity:  
`docs/dev-log/decisions/2026-08-02-nb2-beta-x-dispersion-identity.md`  
`docs/dev-log/decisions/2026-08-05-nb1-x-dispersion-identity.md`

---

## Phase 0.25 — Sweep receipt (gate)

| Surface | Evidence ran | Finding | Call |
| --- | --- | --- | --- |
| **repo git** | `git fetch`; `origin/main`=`a100cc63`; `gh pr list` empty; species tip `2d19318c`; left-right `18 7`; overlap `comm -12` of file lists | Species must rebase; hygiene needed; worktree on wrong branch | **resume** Species tip + **build** hygiene + Identity |
| **twin / sister** | local `gllvmTMB` `fit-multi.R` / `gllvmTMB.cpp` | betabinomial fid 8 + `log_phi_betabinom`; tweedie often reserved fail-loud | Ada-default Identity = **BetaBinomial+X** |
| **brain** | `search_notes` “Species-XB Tweedie+X…” + `rg` AGENT_LOG/DECISIONS | no contradictory “do Tweedie next” lock; Species-XB prior exists in repo docs | **resume Species**; **do not** invent Tweedie engine |
| **log/history grep** | `rg species-xb\|NB1+X` `docs/dev-log/check-log.md` | NB1+X + hygiene entries present; Species after-task on species branch | reuse after-tasks |
| **Verdict** | — | Gap = ledger close + rebase/PR Species + Identity docs for next family | **build-the-gap** = this programme |

External novelty: **not claimed** — no `/notebook` required for Identity (internal twin parity).

---

## WHAT THE BRAIN ALREADY KNOWS

- Light RCall ≠ full family parity; rtol 1e-6; no silent widen.
- Species-XB Arc 0 = Poisson only; engine `fit_gllvm_speciescov` already exists.
- NB1+X engine merged #186; live Δ proven locally this session.
- Identity-before-engine is load-bearing (#174 lesson).
- Dropbox checkout PROTECTED; stage by name.

## WHAT SHINICHI TOLD US

- Asked if NB1 is good → yes with stale board / Distributions debt.
- Asked to `/arc-creation` next → sized 1/2/3 options.
- Then: **do 1,2,3 as one arc and ultra-plan 1–3** (this plan).

## WHAT THE TEAM RAISED

```
TEAM RAISED
Ada      — Programme OK if Identity stays docs-only; Ada-default BetaBinomial+X.
Shannon  — Rebase before push; worktree currently wrong branch; one PR vs three.
Hopper   — Twin: prefer betabinomial over tweedie for next light-oracle family.
Rose     — Fence: programme ≠ next-family engine ≠ full family parity ≠ ADEMP.
Grace    — Species-XB CI after rebase; Documenter may touch board/capability docs.
Gauss    — Distributions import is the only code fix in Rung 1; keep surgical.
```

---

## Decomposition (Phase 1)

### Serial critical path

```
S0  Fresh worktree from origin/main @ a100cc63
      ↓
S1  Hygiene: board/AGENTS/capability-status/after-task Δ + Distributions import
      ↓
S2  Rebase Species-XB onto S1 tip; resolve 5 overlap files; push + PR
      ↓
S3  (parallel OK) Twin recon + BetaBinomial+X Identity decision draft
      ↓
S4  CI green → merge Species-XB (if G0 merge=yes) ; open/merge Identity PR
      ↓
S5  Board START HERE + closeout Actuals + STOP
```

### Parallel (cheap, during S2 CI)

| Slice | Owner | Output |
| --- | --- | --- |
| Twin BetaBinomial cites | Hopper/Cursor | file:line for Identity |
| Confirm Tweedie fail-loud | Hopper | one paragraph in Identity “why not Tweedie” |
| Rose fence pass | Rose | claim vs evidence on PR bodies |

### Slice table

| ID | Rung | Work | Verify | Depends |
| --- | --- | --- | --- | --- |
| S1 | 1 | Docs truth + `using Distributions` in `test/parity/test_x_covariate_parity.jl` (+ add dep to parity `Project.toml` if needed) | focused NB1+X include still Δ≪1e-6; file loads under `--project=test/parity` with helpers | S0 |
| S2 | 2 | Rebase `parity/species-xb-light-20260804`; keep Poisson cell; rewrite board rows for #186 MERGED + Species PR | `git range-diff` sanity; PR CI | S1 |
| S3 | 3 | Decision `docs/dev-log/decisions/2026-08-05-betabinomial-x-dispersion-identity.md` (name may shift if G0 overrides family) | twin cites; Rose fence; no `src/` engine | S0 (content); land after S2 open preferred |
| S4 | close | Board/AGENTS snapshots; after-tasks; check-log | grep no OWED fiction for NB1; Species row accurate | S1–S3 |

---

## Alternatives reconciled

| Candidate | Verdict | Why |
| --- | --- | --- |
| **Three separate chats** | Rejected by owner | Explicitly wants 1+2+3 as one arc |
| **Skip Species rebase / force-push old tip** | Reject | 18 behind; overlap with #186 docs/helpers |
| **Tweedie+X as Identity default** | Reject as default | twin user path often fail-loud; poorer light-oracle |
| **Exponential+X Identity** | Defer | thin (Gamma α=1); weak as ladder rung |
| **BetaBinomial+X Identity** | **Ada-default** | twin fid 8 + per-trait `log_phi_betabinom`; Julia `fit_beta_binomial_gllvm` exists; bridge onepart gap is real |
| **Start BetaBinomial engine in same programme** | **Out of scope** | Identity-before-engine; STOP after decision |

---

## G0 — approval gates (**LOCKED** 2026-08-05 local)

1. **Programme shape:** **yes** — ~3.5 h capacity programme 1+2+3
2. **Species-XB push+PR:** **yes** — push rebased `parity/species-xb-light-20260804`
3. **Merge policy:** **yes** — merge Species-XB when CI green (no second ask)
4. **Identity family:** **BetaBinomial+X** — confirmed; MixedModels.jl GLMM ≈ Bernoulli/Binomial/Poisson only (no BetaBinomial); GLM.jl likewise; twin `gllvmTMB` remains load-bearing (`log_phi_betabinom`)
5. **PR packaging:** **(A)** — hygiene PR first → Species-XB rebase PR → Identity PR (3 landings)

**Execute:** `/goal` (fresh chat OK) on this plan — Phase 3 not started in the planning turn.

---

## Definition of Done (programme)

- [ ] Board/AGENTS/capability-status: #186 MERGED + NB1+X Δ cited (not OWED)
- [ ] `test_x_covariate_parity.jl` can resolve `NegativeBinomial` under parity project
- [ ] Species-XB PR open (and merged if G0 merge=yes) with CI green
- [ ] Next-family Identity decision ACCEPTED (or REJECTED-with-fence) on disk
- [ ] Rose fence explicit; no engine for that family; no full-parity claim
- [ ] After-task(s) + check-log + Actuals on Arc Card
- [ ] STOP — next engine = fresh arc-creation/ultra-plan

---

## HAND TO /goal

After G0 answers: execute S0→S5 on a **fresh worktree from `origin/main`**.
Do not Phase-3 inside this planning chat unless owner explicitly says “execute
now in this thread.”
