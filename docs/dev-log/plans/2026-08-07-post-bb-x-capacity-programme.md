# Ultra Plan — Post-#192 / post-BB+X capacity programme (Species-XB · BB CI · ZIP+X Identity)

```
🎯 GOAL
PLATFORM = Cursor (solo). Deliverable = one capacity programme that (1)
widens Species-XB light RCall with a required Binomial `(0+trait):x` cell
(Gaussian optional under-run); (2) implements BetaBinomial grouped /
grouped_cov confidence intervals (Julia `confint` + lift bridge CI guard);
(3) writes ACCEPTED ZIP+X Identity Arc 0 decision — docs-only, no ZIP
engine, no ZIP light RCall. HEADLINE = clear the post-#192/#193 desk as
one R–Julia light-parity ladder programme without inventing a second-family
engine. IN PARALLEL (cheap): twin recon cites for BB CI mirrors
(NB1/Beta grouped_cov) + ZIP two-part estimand / twin known-limitation while
S1 CI runs. DEFER/FENCE: ZIP/ZINB/hurdle engine or light cell; Tweedie+X;
ADEMP/coverage; Phylo Model A (#127 parked); Dropbox protected writes;
git add -A; push without ask; “full family parity”; silent rtol widen;
second-family engine in the same execute run. DISCIPLINE: verify =
Binomial species-XB Δ≤1e-6 (or honest OWED if R absent) + BB CI smoke +
ZIP Identity twin/Julia cites with Rose fence; compute = laptop (RCall
local); closure = after-task(s) + check-log + board START HERE + STOP.
G0 LOCKED — hand to /goal (fresh chat); do NOT Phase-3 in this planning turn.
```

**ARC PROGRAM:** fixed capacity · **~5.5 h (4.5–7.5)** · outcome =
Species-XB Binomial (+ optional Gaussian) + BB grouped CI + ZIP+X Identity
docs · under-run → stop after green required rungs (do **not** pad with ZIP
engine; Gaussian is the only optional under-run) · closeout = board +
Actuals · file:
`docs/dev-log/plans/2026-08-07-post-bb-x-capacity-programme-arc-card.md`.

**Plan-mode note (once):** Cursor Plan-mode toggle is not auto-flipped here.
Phases 0–2 of this turn are **read-only planning**. Phase 3 execute waits
for `/goal` on a fresh chat. **G0 is LOCKED by owner (2026-08-07).**

**Phase 0.3b two-bar (AGENT-INFERRED):** Usage not opened this turn.
MODEL-ROUTING (2026-08-01): scout/rebase/CI/Species-XB cells → **Cursor
Models**; BB CI packing judgment / ZIP Identity prose / Rose fence →
**Other Models**. Owner: glance bars before `/goal`.

---

## Context (orient)

| Fact | Evidence at plan-write (2026-08-07) |
| --- | --- |
| `origin/main` | `2f07ad37` = Merge #193 (post-#192 board/handover hygiene) |
| Prior engine | #192 MERGED @ `f56befc1` — BetaBinomial+X Δ abs ≈ **1.50e-8** (seed=49) |
| Species-XB | #190 MERGED — Poisson only; helper admits `:poisson` only (`parity_helpers.jl`) |
| BB CI gap | `_bridge_ci_guard_betabinomial` fail-loud; no `_family_ci` for `BetaBinomialGrouped(Fit\|CovFit)` |
| CI mirrors | `NB1GroupedCovFit` / `BetaGroupedCovFit` in `src/confint_family.jl` |
| ZIP Julia | `fit_zip_gllvm` / `ZIPFit` (no-X; `Λz=0`); **not** in `_BRIDGE_X_FAMILIES` |
| ZIP twin | gllvmTMB **ZIP cut** from 0.2.0 (`known-limitations.md`); absent from `family_to_id` |
| Open PRs | none at plan cut (hygiene #193 merged) |
| Dropbox | PROTECTED (`claude/jl-bridge-capabilities-20260619`) |
| This branch | `docs/post-bb-x-ultra-plan-20260807` @ `2f07ad37` (plan-only) |

Authoritative pointers:

- `docs/dev-log/handover/2026-08-07-cursor-handover-post-bb-x.md`
- `docs/dev-log/coordination-board.md`
- After-tasks: `2026-08-05-betabinomial-x-engine-arc12.md`,
  `2026-08-04-species-xb-light-rcall.md`
- Identity mirrors: `2026-08-05-betabinomial-x-dispersion-identity.md`,
  `2026-08-05-nb1-x-dispersion-identity.md`
- Two-part design: `docs/superpowers/specs/2026-05-31-two-part-families-design.md`

---

## Phase 0.25 — Sweep receipt (gate)

| Surface | Evidence ran | Finding | Call |
| --- | --- | --- | --- |
| **repo git** | `git fetch`; `origin/main`=`2f07ad37` (#193); `gh pr list` empty; CI green on #193 merge; this worktree switched to `docs/post-bb-x-ultra-plan-20260807` from main tip; foreign unpushed branches ignored | Hygiene landed; desk clear for programme | **build-the-gap** |
| **twin / sister** | local `gllvmTMB` `R/fit-multi.R` `family_to_id` (no `zip`); `docs/dev-log/known-limitations.md` ZIP/ZINB cut; Julia `fit_zip_gllvm` exists | ZIP Identity = **Julia-forward / twin-asymmetric** until twin ZIP lands; Species-XB Binomial twin path exists (`stats::binomial`) | **reuse** Poisson species-XB pattern; **lock** ZIP Identity with honest twin fence |
| **brain** | MCP `search_notes` “post-#192 capacity… ZIP+X” (`search_all_projects:true`) + `rg` brain `AGENT_LOG.md` / `DECISIONS.md` for ZIP/Species-XB/capacity | no contradictory lock against ZIP Identity; no prior ZIP+X decision file | **build** Identity docs; **resume** Species-XB widen + BB CI |
| **log/history grep** | `rg` `Species-XB\|BetaBinomial\|ZIP\|_bridge_ci_guard_betabinomial` under `docs/dev-log/` | #192 after-task OWED CI explicitly; Species after-task lists Binomial as later rung; BB Identity fenced ZIP+X out of #191 | **build-the-gap** = this programme |
| **src gap** | `rg` `_bridge_ci_guard_betabinomial`; `_GroupedDispersionCovFit` union omits BB; species helper `:poisson` only | three genuine gaps = S1/S2/S3 | **implement** S1–S2; **docs-only** S3 |
| **Verdict** | — | Gap = Binomial species-XB light + BB grouped CI + ZIP+X Identity docs; no ZIP engine | **build-the-gap** |

External novelty: **not claimed** — ladder / twin-parity programme; no `/notebook` required.

---

## WHAT THE BRAIN ALREADY KNOWS

- Identity-before-engine is load-bearing (#174 / #185 / #191).
- Light RCall ≠ full family parity; rtol `1e-6`; no silent widen.
- Species-XB Arc 0 = Poisson only; engine `fit_gllvm_speciescov` already exists.
- BB grouped CI was intentionally fail-loud in #192 (`_bridge_ci_guard_betabinomial`).
- Twin ZIP is **planned / cut**, not a live light-oracle family — Identity must not pretend a twin Δ exists.
- Dropbox checkout PROTECTED; stage by name; no push without ask.

## WHAT SHINICHI TOLD US

- Post-#192: want **all 3 rungs as one capacity programme**; handover first, then
  fresh `/ultra-plan` (no engine in planning chat).
- G0 dialogue (2026-08-07): owner confirmed **OK** / Ada defaults → locks below.
- Earlier “go” covered merge → arc → ultra-plan G0 sequence; **push still
  requires explicit ask** (repo hard boundary).

## WHAT THE TEAM RAISED

```
TEAM RAISED
  Ada     — Programme OK; packaging A serial; ZIP Identity docs-only with twin
            asymmetry called out · Default: this plan.
  Hopper  — Species-XB Binomial = extend species helper + cell; Gaussian optional
            · Rec: mirror Poisson DGP with binomial trials · Default: N=1 Bernoulli
            or small fixed N if needed for stability.
  Gauss   — BB CI = copy NB1/Beta grouped_cov `_family_ci`; thread trials N;
            keep FD Hessian (BB Laplace has no OH) · Rec: lift bridge guard only
            after Julia confint smoke green.
  Fisher  — ZIP Identity must lock π (structural-zero logit) + count η under
            shared site-X; note twin ZIP absent · Rec: ACCEPTED-with-fence, not
            fake twin cites · Default: Julia two-part design + CRAN gllvm ZIP
            precedent as secondary authority.
  Rose    — Fence: programme ≠ ZIP engine ≠ full family parity ≠ ADEMP;
            Species-XB Binomial ≠ full species-B surface; BB CI ≠ ADEMP
            coverage · Rec: explicit STOP before next-family engine.
  Shannon — Packaging A: three serial landings; merge-on-green after each CI;
            foreign unpushed branches CARRIED-OVER / ignore.
```

## ADA'S RECOMMENDATION

Execute packaging A on a fresh `/goal` worktree from `origin/main` @
`2f07ad37` (or later green tip). Keep ZIP Identity **docs-only**. Do not start
ZIP engine, ZINB+X, Tweedie+X, or Phylo Model A in this programme.

## DECISIONS LOCKED (G0 — owner 2026-08-07)

| Lock | Value |
| --- | --- |
| Programme | **yes** — all 3 rungs as one capacity programme |
| Species-XB | Binomial **required**; Gaussian **optional under-run** |
| Identity family S3 | **ZIP+X** (Ada lean accepted) |
| merge-on-green | **yes** |
| packaging | **A** — serial landings S1 → S2 → S3 |

## QUESTIONS STILL OPEN

None blocking G0. Execute-time only: Gaussian under-run yes/no if wall-clock
tight after Binomial green (default: skip if <45 min remain before closeout).

---

## Decomposition (Phase 1)

### Serial critical path (packaging A)

```
S0  Fresh worktree / branch from origin/main @ 2f07ad37 (or later green tip)
      ↓
S1  Species-XB widen — Binomial required (+ Gaussian optional under-run)
      → PR1 · CI · merge-on-green
      ↓
S2  BetaBinomial grouped CI — confint + bridge guard lift + tests
      → PR2 · CI · merge-on-green
      ↓
S3  ZIP+X Identity Arc 0 — docs-only decision (+ board/AGENTS closeout)
      → PR3 · CI · merge-on-green
      ↓
S4  Board START HERE + Actuals + STOP (no ZIP engine)
```

### Parallel (cheap, during S1/S2 CI)

| Slice | Owner | Output |
| --- | --- | --- |
| Twin/Julia ZIP estimand recon | Hopper | scratch note file:line + twin known-limitation cite |
| BB CI mirror call-site map | Gauss | NB1/Beta `_family_ci` packing checklist |
| Rose fence pass | Rose | claim vs evidence on each PR body |

### Slice table

| ID | Rung | Member · Model · Bar · Effort · Dispatch | Work (files) | Verify | Depends |
| --- | --- | --- | --- | --- | --- |
| RECON | 0 | Hopper · Composer/Grok · Cursor Models · low · native | Twin ZIP cut cite; BB CI mirror paths; species helper family arm | receipt in plan / scratch | S0 |
| S1 | 1 | Curie/Hopper · Composer · Cursor Models · medium · native | `parity_helpers.jl` admit `:binomial` (+ `:gaussian` if under-run); `test_species_x_parity.jl` cell(s); board/AGENTS/check-log as needed | live Δ ≤1e-6 @ rtol 1e-6 (or OWED if R absent); no widen | S0 |
| S2 | 2 | Gauss/Fisher · Auto Cost / Claude · Other Models · high · native | `confint_family.jl` `_family_ci` for `BetaBinomialGroupedFit` + `BetaBinomialGroupedCovFit` (thread `N`); add to unions; lift/update `_bridge_ci_guard_betabinomial`; tests; bridge CI smoke | focused CI tests green; bridge no longer fail-loud for BB when method≠none (or document remaining methods) | S1 merged |
| S3 | 3 | Ada/Hopper/Rose · Auto Cost · Other Models · medium · native | `docs/dev-log/decisions/2026-08-07-zip-x-identity.md` (name may shift by date); twin asymmetry + Julia two-part cites; **no `src/` ZIP engine** | Rose fence; ACCEPTED; zero ZIP engine diff | S2 merged (preferred) / after S2 PR open OK for draft |
| MV | close | Luna-tier · Composer · Cursor Models · low · native | Mechanical: PR links, board grep, file landed | counts/links | S1–S3 |
| RECONCILE | close | Melissa · Sonnet/Terra · Other Models · low–medium | plan-vs-actual → `docs/dev-log/plan-actual/2026-08-07-post-bb-x-capacity.md` | drift tags | after close |

**LUNA SUITABILITY:** yes — RECON + MECHANICAL-VERIFY (board grep / file presence).  
**ULTRA EFFORT:** no.  
**FAN-OUT BUDGET:** checkpoint=`post-bb-x-cap-20260807` · new children ≤6 · scout=1 · build=2–3 · ceiling=0–1 (Rose only if claim gate).  
**CONTEXT BRAKE:** fresh `/goal` chat · parent planning chat STOP.  
**D-43 PANEL:** milestone=`programme-close` · fire once after all three landings + evidence.

---

## Capacity ladder S1–S3

| Order | Budget | Outcome | Definition of done |
| --- | ---: | --- | --- |
| Arc 0 / orient | 15–20 min | Fresh worktree from `origin/main`; LOOP kit | Start `/goal` |
| **S1 Species-XB** | 70–100 min | Binomial `(0+trait):x` light cell (+ Gaussian optional) | Δ ≤1e-6; PR1 merged on green |
| **S2 BB grouped CI** | 100–140 min | `confint` for BB grouped(_cov); bridge guard lifted | tests green; PR2 merged on green |
| **S3 ZIP+X Identity** | 50–80 min | ACCEPTED docs-only decision | no `src/` ZIP engine; PR3 merged on green |
| Integrate/close | 15–25 min | Board START HERE; Actuals; STOP | Always |
| **Total** | **~5.5 h** | | |

---

## Alternatives reconciled

| Candidate | Verdict | Why |
| --- | --- | --- |
| Three separate chats | Rejected by owner | Explicit programme |
| Tweedie+X Identity | Rejected earlier | twin user path fail-loud |
| ZINB+X / hurdle+X Identity | Deferred | Ada lean + owner lock = ZIP |
| ZIP engine in same programme | **Out of scope** | Identity-before-engine; STOP |
| Skip BB CI / keep guard | Reject | #192 remaining OWED; owner S2 |
| Force twin ZIP light Δ now | Reject | twin ZIP cut — honest OWED only if attempted |

---

## Fences (Rose — load-bearing)

**OK to claim after programme (when evidence lands):**

- Binomial species-XB light logLik under per-trait `B` twin to gllvmTMB
  `(0+trait):x` (plus Gaussian only if under-run cell green).
- BetaBinomial grouped(_cov) Wald/profile/bootstrap CI routed (scope of methods
  as implemented) and bridge no longer fail-loud for supported methods.
- ZIP+X Identity Arc 0 **ACCEPTED** on disk (docs-only).

**Not OK (explicit ≠):**

- full family parity · ADEMP / coverage · ZIP/ZINB/hurdle **engine** or light
  RCall cell · twin ZIP light Δ (twin family absent) · Tweedie+X · Phylo Model A
  · full species-B multi-family cohort · silent rtol widen.

---

## Verification (programme)

| Check | Gate |
| --- | --- |
| Species-XB Binomial focused cell | abs/rel Δ ≤ rtol `1e-6`; no widen |
| Species-XB Gaussian (optional) | same; skip OK if under-run |
| BB CI unit/smoke | `confint` on grouped + grouped_cov with `N`; bridge path |
| ZIP Identity | decision ACCEPTED; twin asymmetry paragraph; **zero** ZIP engine files in S3 diff |
| Packaging A | three PRs, each merge-on-green |
| Rose | fence language on each PR + after-task |
| Full suite | at least focused tests per rung; prefer `Pkg.test()` before final programme claim |

**Compute:** laptop. Ask Totoro/DRAC only if a future recovery campaign appears
(out of scope here). RCall needs local R + gllvmTMB for S1.

---

## Packaging A (serial landings)

1. **PR1 — S1 Species-XB** (`parity/species-xb-binomial-…` or similar) → merge on green.  
2. **PR2 — S2 BB CI** (`feat/betabinomial-grouped-ci-…`) → merge on green.  
3. **PR3 — S3 ZIP+X Identity** (`docs/zip-x-identity-…`) → merge on green.  

Do **not** squash all three into one PR. Board/AGENTS updates may ride the
landing they truthfully describe; final START HERE rides PR3 or a tiny
docs closeout on PR3.

---

## Definition of Done (programme)

- [ ] Binomial Species-XB light cell green (Δ ≤1e-6) and PR1 merged
- [ ] Gaussian Species-XB either green **or** explicitly skipped as under-run
- [ ] BB grouped(_cov) CI implemented; bridge guard lifted for supported methods; PR2 merged
- [ ] ZIP+X Identity decision ACCEPTED on disk; **docs-only** (no ZIP engine); PR3 merged
- [ ] Rose fence explicit in after-task(s)
- [ ] Board START HERE points past this programme; check-log + Actuals filled
- [ ] **STOP** — next-family ZIP engine = fresh `/arc-creation` or ultra-plan only

---

## STOP before next-family engine

This programme **ends** at ZIP+X Identity ACCEPTED. Do **not** start
`fit_zip_gllvm_*_cov`, bridge ZIP X admit, or ZIP light RCall in the same
`/goal` run. Next engine = new G0.

---

## HAND TO /goal (paste-ready)

```text
/goal

Execute the LOCKED post-#192 capacity programme in
docs/dev-log/plans/2026-08-07-post-bb-x-capacity-programme.md
(+ arc card docs/dev-log/plans/2026-08-07-post-bb-x-capacity-programme-arc-card.md).

G0 LOCKS (do not re-interview):
- Programme = yes (all 3 rungs)
- Species-XB = Binomial required; Gaussian optional under-run
- Identity S3 = ZIP+X (docs-only)
- merge-on-green = yes
- packaging A = serial PR1→PR2→PR3

Base: fresh worktree from origin/main (tip was 2f07ad37 / Merge #193 at plan-write).
Scaffold LOOP under lanes/post-bb-x-capacity-20260807/LOOP/ from the ultra-plan.
Order: S1 Species-XB Binomial → merge → S2 BB grouped CI → merge → S3 ZIP+X Identity docs-only → merge → board closeout → STOP.
Fences: ≠ ZIP engine ≠ ZIP light RCall ≠ Tweedie+X ≠ ADEMP ≠ full family parity ≠ Phylo Model A ≠ git add -A ≠ Dropbox protected tree.
Verify: Binomial Δ≤1e-6; BB CI tests; ZIP Identity ACCEPTED with twin-asymmetry fence; no silent rtol widen.
Ask before push only if repo gate still binds; owner already approved merge-on-green for these landings once PRs exist.
Do not Phase-0 re-plan. Re-read LOOP/GOAL.md every arc.
```
