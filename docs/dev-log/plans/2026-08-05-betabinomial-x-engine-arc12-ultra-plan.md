# Ultra Plan — BetaBinomial+X combined Arc 1+2 (engine + light RCall; Phases 0–2 only)

```
🎯 GOAL
PLATFORM = Cursor (solo). Deliverable = (A) fit_beta_binomial_gllvm_grouped +
_grouped_cov implementing ACCEPTED BetaBinomial+X identity (per-trait φ +
shared site-X γ, trials N) with Julia identity tests + bridge/`@formula`
admit; AND (B) one light gllvmTMB BetaBinomial+X logLik cell green at rtol
1e-6 via betabinomial() + shared site-X. HEADLINE = next light-parity ladder
rung after NB1 — Identity already locked (#191); engine only. IN PARALLEL
(cheap): refresh twin log_phi_betabinom / n_trials cites; map
fit_nb1_gllvm_grouped_cov + fit_beta_gllvm_grouped_cov call sites for
surgical copy into beta_binomial.jl. DEFER/FENCE: ADEMP/coverage; Phylo Model
A; Tweedie/ZIP/+X; X_lv redesign; Dropbox protected writes; git add -A; push
without ask; “full family parity”; silent rtol widen; second family; MixedModels
BetaBinomial (does not exist — twin authority). DISCIPLINE: verify = identity
tallies + live Δ≤1e-6 (or honest OWED if R absent) + no claim inflation;
compute = laptop (RCall needs local R+gllvmTMB); closure = after-task +
check-log + board/AGENTS + STOP. After G0: hand to /goal (fresh chat preferred
for ~5.5 h); do NOT Phase-3 in this planning turn.
```

**ARC PROGRAM:** size · recommended **~5.5 h (4.5–7.5)** · outcome =
BetaBinomial+X engine + one light cell · under-run → stop after green (do not
invent Tweedie) · closeout = board + Actuals ·
file: `docs/dev-log/plans/2026-08-05-betabinomial-x-engine-arc12-arc-card.md`.

**Plan-mode note (once):** Phases 0–2 remain **read-only** here. Phase 3 /
`src/` body is **not** executed in this planning turn.

**Phase 0.3b two-bar (AGENT-INFERRED):** Usage not opened this turn.
MODEL-ROUTING (2026-08-01): scout/build → **Cursor Models**; judgment / N+FD
Laplace hazards / Rose → **Other Models**. Owner: glance bars before `/goal`.

---

## Context (orient)

| Fact | Evidence at plan-write (2026-08-05 ~18:40 UTC) |
| --- | --- |
| `origin/main` | `d5d61cb7` = Merge #191 (BetaBinomial+X Identity ACCEPTED) |
| Identity | `docs/dev-log/decisions/2026-08-05-betabinomial-x-dispersion-identity.md` |
| Twin recon | `docs/dev-log/plans/scratch/betabinomial-x-twin-recon.md` (`ab49638b`) |
| Engine gap | named shared `fit_beta_binomial_gllvm` only; **no** grouped / `_grouped_cov`; **not** in `_BRIDGE_ONEPART_FAMILIES` / `_BRIDGE_X_FAMILIES` |
| Mirrors | NB1 #186 (`fit_nb1_gllvm_grouped_cov`); Beta `fit_beta_gllvm_grouped_cov` @ `grouped_dispersion.jl:671` — packing template; **BB Laplace stays in `beta_binomial.jl`** (custom FD mode + `N`) |
| Twin | fid 8; `log_phi_betabinom`; `n_trials`; logit only |
| Open PRs | none at plan cut |
| Dropbox | PROTECTED |
| Stale worktree | this checkout still on deleted Identity branch tip — **execute from fresh worktree @ `origin/main`** |

---

## Phase 0.25 — Sweep receipt (gate)

| Surface | Evidence ran | Finding | Call |
| --- | --- | --- | --- |
| **repo git** | `git fetch`; `origin/main`=`d5d61cb7`; `gh pr list` empty; `branch_drift_check` Identity branch 0 ahead / 1 behind | Identity landed; desk clear for engine | **build-the-gap** |
| **twin / sister** | `rg` gllvmTMB `log_phi_betabinom` / fid 8 / `n_trials` / logit abort (`fit-multi.R:315`) | per-trait φ + trials size; logit-only | **re-cite** at execute S0 |
| **brain** | `search_notes` “BetaBinomial+X engine…” `search_all_projects:true` | no contradictory engine lock; Identity ACCEPTED in repo docs | **resume** Identity; **build** engine |
| **log/history grep** | `rg betabinomial` `docs/dev-log/check-log.md`; `rg betabinomial` brain `AGENT_LOG.md` / `DECISIONS.md` | check-log points START HERE → BB engine; no prior BB+X engine after-task | **build-the-gap** |
| **src gap** | scout map + `rg` `fit_beta_binomial` / `_BRIDGE_*` | shared named only; bridge absent; mirrors = NB1 cov packing + BB custom Laplace | **implement** in `beta_binomial.jl` + bridge/formula |
| **Verdict** | — | Gap = grouped(+cov) + bridge admit + one light cell; Identity frozen | **build-the-gap** |

External novelty: **not claimed** — twin parity rung; no `/notebook` required.

---

## WHAT THE BRAIN ALREADY KNOWS

- Identity-before-engine (#174 / #185 / #191).
- Light RCall ≠ full family parity; rtol 1e-6; no silent widen.
- Twin authority for BetaBinomial (MixedModels/GLM have no BB GLMM).
- NB1 combined Arc 1+2 (#186) is the programme shape owner likes for ladder rungs.
- BB hazards: trials `N`; custom FD `_beta_binomial_mode`; do **not** plug into
  `_beta_grouped_loglik_site`.

## WHAT SHINICHI TOLD US

- Closeout packaging A finished (#187/#190/#191).
- Asked for **fresh-chat `/ultra-plan` for BetaBinomial+X engine only** (no
  engine in the closeout chat).
- This turn: plan only → G0 → `/goal` handoff.

## WHAT THE TEAM RAISED

```
TEAM RAISED
  Gauss  — Packing mirror = fit_nb1_gllvm_grouped_cov; Laplace kernel stays in
           beta_binomial.jl with N + per-trait φ · Rec: extend
           betabinomial_marginal_loglik_laplace(φvec, offset) · Default: FD outer
           like current shared BB unless OH proves needed for R match.
  Hopper — Light cell must call gllvmTMB betabinomial() + shared site-X; pass
           trials · Rec: extend fit_gllvmtmb_parity_loglik_x(:betabinomial) ·
           Default: N=ones or small fixed trials DGP.
  Fisher — Identity: G=1 vs shared fit_beta_binomial_gllvm (no fit_gllvm_cov for
           BB yet); constant φvec+offset · Rec: do not widen rtol · Q: add
           hessian=:fisher only if needed for G=1 match.
  Rose   — Combined OK if fence = one family + light ≠ full parity; fix stale
           “family 15” comment opportunistically · Rec: explicit STOP · Default:
           fold comment fix into S0 (5 min).
  Ada    — Recommend combined Arc 1+2 (~5.5 h) like NB1; sequence engine→bridge
           →light→docs; fresh worktree from d5d61cb7.
```

## ADA'S RECOMMENDATION

1. Approve G0 for **combined BetaBinomial+X Arc 1+2** (~5.5 h).
2. Sequence: grouped+cov engine + identity → bridge/formula/capabilities → light
   cell → docs → STOP.
3. Fresh worktree `cursor/betabinomial-x-engine-arc12-YYYYMMDD` from
   `origin/main` @ `d5d61cb7` (do not reuse Identity/closeout worktree tip).
4. If R absent: ship engine+scaffold; mark live oracle OWED (do not fake Δ).
5. Do **not** start Tweedie/ZIP/Exponential engine in the same `/goal`.

---

## Decomposition (Phase 1)

### Serial critical path

```
S0  Fresh worktree @ origin/main d5d61cb7 + LOOP scaffold + twin cite refresh
      ↓
S1  Extend BB Laplace: φvec + offset; fit_beta_binomial_gllvm_grouped
      ↓
S2  fit_beta_binomial_gllvm_grouped_cov (+ fit types, exports)
      ↓
S3  Identity suite test/test_betabinomial_x_identity.jl (G=1 + constant φvec)
      ↓
S4  Bridge admit + formula + capabilities golden (+ optional confint adapters)
      ↓
S5  Light RCall cell (:betabinomial) — live Δ or OWED
      ↓
S6  Docs/board/AGENTS/capability-status/after-task/check-log + STOP
```

### Parallel (cheap, during S1–S2)

| Slice | Bar | Owner | Output |
| --- | --- | --- | --- |
| Twin cite refresh | Cursor Models | Hopper | file:line for `n_trials` + `log_phi_betabinom` |
| Capabilities golden list draft | Cursor Models | Emmy | expected `_BRIDGE_*` rows |
| Rose fence pass on PR body | Other Models | Rose | claim vs evidence |

### Slice table

| ID | Rung | Work | Verify | Depends | Bar |
| --- | --- | --- | --- | --- | --- |
| S1–S2 | A | Grouped(+cov) in `beta_binomial.jl` | unit smoke; FD sanity if pattern requires | S0 | Cursor Models |
| S3 | A | Identity tests | **pass tally**; no rtol widen | S2 | Cursor Models |
| S4 | B | Bridge/formula/capabilities | `test_bridge_*` / capabilities golden | S3 | Cursor Models |
| S5 | B | Light parity cell | Δ≤1e-6 or OWED | S4 | Cursor Models (+ local R) |
| S6 | close | Docs + STOP | board START HERE next ≠ this engine | S5 | Other Models (prose) |

---

## Alternatives reconciled

| Candidate | Verdict | Why |
| --- | --- | --- |
| **Split Arc 1 / Arc 2 chats** | Acceptable fallback | Safer if S1–S3 blow budget; owner may prefer combined |
| **Combined Arc 1+2** | **Ada-default** | Matches NB1 #186 ladder rhythm; one programme |
| **Reuse `_beta_grouped_loglik_site`** | Reject | Wrong kernel (no `N`; different FD/mode) |
| **Shared-φ + X as public default** | Reject | Breaks Identity / twin |
| **Tweedie next instead** | Reject | Identity already chose BB; twin user path fail-loud |
| **Engine without bridge** | Incomplete | Bridge admit is the public twin surface |

---

## G0 — approval gates (**LOCKED** 2026-08-05 — owner “resume” → Ada defaults)

1. **Programme shape:** **yes** — combined Arc 1+2 (~5.5 h)
2. **Merge policy:** **yes** — merge on CI green (no second ask)
3. **Hessian:** **FD-first** — add `:observed`/`:fisher` only if R Δ needs it

**Execute:** `/goal` on worktree `gllvmjl-betabinomial-x-engine-20260805`.

---

## Definition of Done (programme)

- [ ] `fit_beta_binomial_gllvm_grouped` + `_grouped_cov` exported; `N` threaded
- [ ] Identity suite green (no rtol widen)
- [ ] Bridge one-part + X + `@formula`+X admit `betabinomial`
- [ ] Light cell green @ 1e-6 **or** scaffold + honest OWED
- [ ] Rose fence explicit; no full-parity / ADEMP claim
- [ ] After-task + check-log + board START HERE (next ≠ this engine)
- [ ] STOP

---

## HAND TO /goal

After G0 answers: execute S0→S6 on a **fresh worktree from `origin/main`**.
Do not Phase-3 inside this planning chat unless owner explicitly says “execute
now in this thread.”
