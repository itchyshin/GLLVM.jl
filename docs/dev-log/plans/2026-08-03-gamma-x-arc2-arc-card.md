# ARC CARD — Gamma+X Arc 2 (light gllvmTMB logLik RCall)

**Mode:** size  
**Requested outcome:** one light RCall Gamma+X logLik cell green at rtol
`1e-6` against live gllvmTMB, using Arc 1 `fit_gamma_gllvm_grouped_cov`
(`group=collect(1:p)`, default `hessian=:observed`). No engine redesign.  
**Mechanism authority:** `test/parity/` helpers + `test_x_covariate_parity.jl`
+ narrow docs fence. Explicit exclusions: no Arc 1 engine redo; no Option B
flip; no Ordinal+X; no ADEMP/coverage; no Phylo Model A; no Dropbox-protected
checkout writes; no `git add -A`; no push without ask; no “full family
parity”; **do not merge or resolve #177**.  
**Recommended arc:** **1.5 hours** (range **1–2 h**)  
**Time contract:** ceiling ~2 h  
**Estimate confidence:** **inferred** (direct analogue: NB2/Beta Arc 2
`docs/dev-log/plans/2026-08-02-nb2-beta-x-arc2-ultra-plan.md` / after-task
`docs/dev-log/after-task/2026-08-02-nb2-beta-x-arc2-parity.md` — 2 cells,
infra existed; Gamma is **one** cell, helper extend `:gamma` only, engine
already local at `ca2b2c0b`)  
**Arc 0 outcome:** Gamma+X light logLik cell Pass at rtol 1e-6; README +
capability-status + surgical check-log + after-task; Rose OK for light cell
only.  
**State transition:** current = Arc 1 engine local-done, X cohort still
G/Bin/Pois only on this tip → intended = shared site-X light logLik also
covers Gamma under per-trait α.  
**Executable rung and evidence:** extend `fit_gllvmtmb_parity_loglik_x` for
`:gamma` via `stats::Gamma(link="log")`; add one `@testset`; live
`GLLVM_PARITY_TESTS=1` run; paste Δ; DGP/seed repair over rtol widen.

### Capacity ladder (size mode)

| Order | Budget | Outcome | Trigger / definition of done |
| --- | ---: | --- | --- |
| Arc 0 | 1.5 h | Gamma+X light RCall cell + docs fence | G0 already granted (this follow-on) |
| Rung 1 (later) | — | Push/PR when asked; land after #177 if needed | Maintainer |
| Integrate/close | 20 min | check-log + after-task + Rose ≠ full parity | Always |

### Budget (Arc 0)

| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient / LOOP scaffold | 15 | Continue on engine tip; lane LOOP/ |
| Helper + cell | 35 | `:gamma` in X helper; one `@testset` |
| Live RCall verify | 25 | Δ logLik read from log; rtol 1e-6 |
| Repair reserve | 25 | DGP/seed only (NB2/Beta lesson) |
| Closeout | 20 | Docs + after-task + commit (no push) |
| **Total** | **~120 (~2 h)** | |

**In scope:** light Gamma+X RCall cell; helper family switch; narrow docs.  
**Not in this arc:** engine surgery unless a bug blocks the cell; #177 merge;
NB2/Beta X helper widen on this lane (leave to #177); Option B; Ordinal+X;
ADEMP; Dropbox writes; push.  
**Evidence used:**
- Arc 1 LOCAL DONE: `fix/gamma-x-grouped-cov-20260803` @ `ca2b2c0b`
- Decision: `docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md`
- Mirror: #177 / `docs/dev-log/plans/2026-08-02-nb2-beta-x-arc2-ultra-plan.md`
- Twin: `stats::Gamma(link="log")` → per-trait `log_phi_gamma` (fid 4)

**Risk branch:** If live Δ ≫ 1e-6 or R Heywood/false-convergence, repair DGP
(K, n, α_true, loadings) — **never** widen rtol. If missing R/gllvmTMB, land
gated cells + document BLOCKED — do not fake green.

**Done when:** cell Pass at 1e-6 with pasted Δ; docs fence updated; Rose OK
for light Gamma+X only; commits local; no push.  
**First action (after G0):** write ultra-plan → scaffold
`lanes/gamma-x-arc2-20260803/LOOP/` → implement cell on engine tip (same
branch OK while unpushed).
