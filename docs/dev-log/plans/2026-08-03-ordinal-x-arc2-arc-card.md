# ARC CARD — Ordinal+X Arc 2 (light gllvmTMB logLik RCall)

**Status:** **LOCAL DONE** — light cell Δ≈5.38e-9 on
`parity/ordinal-x-arc2-20260803` (tip exception from engine #180 @ `e2b4afde`).
After-task: `docs/dev-log/after-task/2026-08-03-ordinal-x-arc2-parity.md`.
Push/PR after #180 merges + Shinichi ask.

**Mode:** size  
**Requested outcome:** one light RCall Ordinal+X logLik cell green at rtol
`1e-6` against live gllvmTMB `ordinal_probit` (+ shared site-X), using Arc 1
`fit_ordinal_gllvm_pertrait_cov` (per-trait τ₁=0 / K−2 free; shared γ;
`η = β + Xγ + Λz`). No engine redesign in Arc 2.  
**Mechanism authority:** `test/parity/` helpers + `test_x_covariate_parity.jl`
(or dedicated ordinal-X parity include) + narrow docs fence. Exclusions: no
engine redo; no silent shared-cutpoint public X; no ADEMP/coverage; no Phylo
Model A; no Dropbox-protected writes; no `git add -A`; no push without ask; no
“full family parity”.  
**Recommended arc:** **1.5–2 hours** (range **1–2.5 h**) after #180 on `main`  
**Time contract:** ceiling ~2.5 h  
**Estimate confidence:** **inferred** (Gamma+X Arc 2 ~1.5–2 h one cell; NB2/Beta
Arc 2 with DGP repair). Ordinal may need probit vs LogitLink / DGP pass —
repair reserve, not a second arc.  
**Arc 0 outcome:** Ordinal+X light logLik cell Pass @ rtol 1e-6; README +
capability-status + check-log + after-task; Rose OK for light cell only.  
**State transition:** engine Arc 1 landed (or landing via #180) → shared site-X
light logLik cohort also covers Ordinal under per-trait cutpoints + shared γ.  
**Executable rung and evidence:** extend `fit_gllvmtmb_parity_loglik_x` for
`:ordinal` / `ordinal_probit()`; one `@testset` calling
`fit_ordinal_gllvm_pertrait_cov`; live `GLLVM_PARITY_TESTS=1`; paste Δ; DGP
repair over rtol widen.

### Capacity ladder

| Order | Budget | Outcome | Trigger / definition of done |
| --- | ---: | --- | --- |
| Gate | — | #180 MERGED (or work off engine tip if CI still running and Shinichi allows) | External CI |
| Arc 0 | 1.5–2 h | Ordinal+X light RCall cell + docs fence | After G0 + `/goal` |
| Integrate/close | 20 min | check-log + after-task + Rose ≠ full parity | Always |

### Budget (Arc 0)

| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient / LOOP | 15–20 | Branch off post-#180 `main` (or engine tip); `lanes/ordinal-x-arc2-*/LOOP/` |
| Helper + cell | 35–45 | `:ordinal` / `ordinal_probit` in X helper; one `@testset` |
| Live RCall verify | 25–30 | Δ logLik from log; rtol 1e-6 |
| Repair reserve | 25–35 | DGP/seed/link — never rtol widen |
| Closeout | 20 | Docs + after-task + commit (no push until ask) |
| **Total** | **~120–150** | |

**In scope:** light Ordinal+X RCall cell; helper family switch; narrow docs.  
**Not in this arc:** engine surgery; Option B shared-cutpoint; ADEMP; push
without ask; “full family parity”.  
**Evidence used:** ACCEPTED identity
`docs/dev-log/decisions/2026-08-03-ordinal-x-cutpoint-identity.md`; engine
after-task `docs/dev-log/after-task/2026-08-03-ordinal-x-engine.md`; Gamma/NB2
Arc 2 analogues.  
**Risk branch:** If R Δ ≫ 1e-6 from link mismatch (probit vs logit), stop and
diagnose link/packing — do not widen rtol. If R/`gllvmTMB` absent, land helper
+ cell scaffold and mark live oracle OWED.

**Done when:** live cell Pass @ 1e-6 (or honest OWED with scaffold) + after-task
+ Rose fence.  
**First action after G0:** fresh `/goal` from Ultra Plan GOAL block.

### Actuals (complete at close)
**Recommended / actual:** 90–150 / ~45 (cell first-try green) · **Rungs completed:** Arc 0  
**Result:** Δ≈5.38e-9 Pass · **Next arc:** push/PR after #180 + ask

**HAND TO ULTRA PLAN:** size-mode Ordinal+X light RCall Arc 2, ~90–150 min,
outcome = one `ordinal_probit`+X logLik cell @ rtol 1e-6 via
`fit_ordinal_gllvm_pertrait_cov`; no engine redesign; PLATFORM Cursor; execute
via `/goal` after G0.
