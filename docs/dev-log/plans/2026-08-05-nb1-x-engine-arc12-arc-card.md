# ARC CARD — NB1+X combined Arc 1+2 (engine + light RCall)

**Status:** **LOCAL DONE** — engine + identity + scaffold landed on
`cursor/nb1-x-engine-arc12-fffd` (PR #186). Live RCall Δ OWED (no R in cloud).

**Mode:** size  
**Requested outcome:** quantified programme — (1) implement locked NB1+X twin
identity as `fit_nb1_gllvm_grouped_cov` + bridge/`@formula` + Julia identity
tests; (2) land **one** light gllvmTMB NB1+X logLik cell @ rtol `1e-6`. Theme =
**R–Julia parity**.  
**Mechanism authority:** surgical `src/` + `test/` + narrow docs cascade from
`origin/main` @ `210de76d` (#185 ACCEPTED). Explicit exclusions: no ADEMP /
coverage; no Phylo Model A; no Gamma Option B flip; no Tweedie/ZIP/+X; no
`X_lv` redesign; no Dropbox-protected writes; no `git add -A`; no push without
ask; no “full family parity”; no silent rtol widen; do not invent a second
family in this arc.  
**Recommended arc:** **4.5 hours** (range **3.5–6 h**)  
**Time contract:** ceiling ~6 h (outcome-first; under-run → stop after green
engine+cell, do not pad)  
**Estimate confidence:** **inferred** (Gamma engine Arc 1 ~3.5 h one family +
Gamma/Ordinal Arc 2 ~1.5–2 h one cell; NB1 already has no-X grouped Laplace +
identity decision — combined programme, not two chats)  
**Arc 0 outcome (this programme’s executable rung):**
- Exported `fit_nb1_gllvm_grouped_cov` (+ fit type) implementing
  `η = β + Xγ + Λz` with per-group/per-trait `log φ`
- Bridge X + `@formula`+X route `nb1` / `nbinom1` through it (per-trait default
  under X); shared-φ + X remains opt-in if a path exists
- Julia identity tests green (G=1+fisher ≈ shared cov spirit; constant-φvec
  checks) **without** rtol widen
- Light RCall cell: Julia vs gllvmTMB `nbinom1`+shared site-X logLik Δ within
  rtol `1e-6` (live `GLLVM_PARITY_TESTS=1`)
- Docs/board/check-log/after-task; Rose OK for **engine + light cell only**

**State transition:** identity locked (#185), bridge throws on nb1+X → twin
API B under X wired + one light oracle green.  
**Executable rung and evidence:** mirror `fit_nb_gllvm_grouped_cov` /
`fit_gamma_gllvm_grouped_cov`; extend `_BRIDGE_X_FAMILIES` + formula dispatch;
add `test/test_nb1_x_identity.jl` (or extend existing x-identity suite); extend
`fit_gllvmtmb_parity_loglik_x` + `test_x_covariate_parity.jl` for `:nb1` /
`nbinom1()`; paste Δ; DGP/link repair over rtol widen.

### Capacity ladder

| Order | Budget | Outcome | Trigger / definition of done |
| --- | ---: | --- | --- |
| Gate | — | #185 MERGED on `main` @ `210de76d` (done) | External |
| Optional | 10 min | Board tick “#185 MERGED” (pointer hygiene) | Cheap; may fold into S0 |
| Rung A (engine) | 2.5–3.5 h | `fit_nb1_gllvm_grouped_cov` + identity + bridge/formula | After G0 |
| Rung B (light) | 1–2 h | One NB1+X RCall cell @ 1e-6 | After Rung A green |
| Integrate/close | 20–30 min | docs + after-task + Rose ≠ full parity | Always |

### Budget (combined)

| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient / LOOP | 20–30 | Rehydrate #185 decision; #175/#178 pattern; twin `nbinom1` cite refresh |
| Engine core | 90–120 | `NB1GroupedCovFit` + `fit_nb1_gllvm_grouped_cov`; exports |
| Bridge/formula/CI adapters | 40–50 | Route nb1 under X; keep shared opt-in honest |
| Identity verify | 35–45 | Julia identity suite; tallies; FD if pattern requires |
| Light helper + cell | 35–50 | `:nb1` → `nbinom1()` in X helper; one `@testset` |
| Live RCall verify | 25–40 | Δ logLik; rtol 1e-6; repair reserve (DGP/seed, not rtol) |
| Closeout | 20–30 | capability/parity docs + board + check-log + after-task + Actuals |
| **Total** | **~265–365 (~4.5–6 h)** | |

**In scope:** NB1+X engine + one light RCall cell + docs fence.  
**Not in this arc:** second family; ADEMP; Phylo Model A; Gamma Option B;
“full family parity”; push without ask.

**Evidence used (plan-write):**
- Decision ACCEPTED: `docs/dev-log/decisions/2026-08-05-nb1-x-dispersion-identity.md`
  on `main` @ `210de76d` (#185)
- Engine mirrors: `fit_nb_gllvm_grouped_cov` / `fit_gamma_gllvm_grouped_cov` in
  `src/families/grouped_dispersion.jl`; after-tasks
  `2026-08-02-nb2-beta-x-grouped-cov.md`, `2026-08-03-gamma-x-grouped-cov.md`
- Light mirrors: Gamma/Ordinal Arc 2 after-tasks (Δ≈3e-8 / 5e-9)
- Gap: nb1 absent from `_BRIDGE_X_FAMILIES`; no `fit_nb1_gllvm_grouped_cov`;
  `test/test_bridge_x.jl` expects throw on nb1+X
- Twin: `nbinom1` fid 15 / `log_phi_nbinom1` (re-cite at execute; decision used
  `5bf18ab3`)
- Open PRs: none at plan cut; Dropbox PROTECTED

**Risk branch:**
1. If G=1 Fisher identity fails outside #172/#175 band → stop; diagnose
   Hessian/offset — no rtol widen.
2. If live R Δ ≫ 1e-6 from OH/Fisher or DGP → repair path (observed Hessian /
   seed / packing) like Gamma Arc 2; **never** widen rtol.
3. If R/`gllvmTMB` absent in execute env → land engine + scaffold cell; mark
   live oracle OWED (honest).

**Done when:** engine exported + routed; identity green; live (or honestly OWED)
light cell; docs/Rose fence; STOP.  
**First action (after G0):**

```sh
git fetch origin
git checkout -b fix/nb1-x-grouped-cov-20260805 origin/main
# cloud agent may continue on cursor/nb1-x-engine-arc12-fffd
```

### Actuals (complete at close)

**Recommended / actual:** 4.5 h / cloud execute (G0 yes/yes) · **Rungs
completed:** A (engine+identity+bridge) + B scaffold; live RCall OWED  
**Result:** LOCAL DONE @ `a83391fa`+docs · **Next arc:** merge #186 when
asked; live NB1+X RCall Δ when R/`gllvmTMB` available; STOP inventing next
family — fresh `/arc-creation`

---

**HAND TO ULTRA PLAN:** done —
`docs/dev-log/plans/2026-08-05-nb1-x-engine-arc12-ultra-plan.md` (Phases 0–2).
After G0 run via `/goal` (fresh chat preferred for the long execute).
