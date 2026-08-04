# ARC CARD — Ordinal+X Arc 2 (light gllvmTMB logLik RCall) — after engine Arc 1

**Status:** **CONTINGENT** — size-mode recommendation only. **Not executable
until Ordinal+X engine Arc 1 is LOCAL DONE** (committed tip + after-task, or
open PR). Do **not** Ultra Plan / `/goal` this card while Arc 1 is still WIP.

**Mode:** size  
**Requested outcome:** one light RCall Ordinal+X logLik cell green at rtol
`1e-6` against live gllvmTMB `ordinal_probit` (+ shared site-X), using Arc 1
`fit_ordinal_gllvm_pertrait_cov` (per-trait τ₁=0 / K−2 free; shared γ;
`η = β + Xγ + Λz`). No engine redesign in Arc 2.  
**Mechanism authority:** `test/parity/` helpers + `test_x_covariate_parity.jl`
(or a dedicated ordinal-X parity include if helper shape forces it) + narrow
docs fence. Explicit exclusions: no Arc 1 engine redo; no silent shared-cutpoint
public X default; no ADEMP/coverage; no Phylo Model A; no Dropbox-protected
checkout writes; no `git add -A`; no push without ask; no “full family parity”;
**do not open a parallel engine branch** for this arc.  
**Recommended arc:** **1.5–2 hours** (range **1–2.5 h**) once the gate opens  
**Time contract:** ceiling ~2.5 h after engine LOCAL DONE  
**Estimate confidence:** **inferred** (direct analogues: Gamma+X Arc 2 ~1.5–2 h
one cell + helper extend, after-task Δ≈3e-8; NB2/Beta Arc 2 two cells with DGP
repair). Ordinal may need an extra DGP/link pass (`ordinal_probit` / probit vs
Julia default LogitLink under X) — budgeted in repair, not as a second arc.  
**Arc 0 outcome (when unlocked):** Ordinal+X light logLik cell Pass at rtol
1e-6; README + capability-status + surgical check-log + after-task; Rose OK for
light cell only.  
**State transition:** current = engine Arc 1 **not** LOCAL DONE (tip still at
main; WIP uncommitted) → intended *after gate* = shared site-X light logLik
cohort also covers Ordinal under per-trait cutpoints + shared γ.  
**Executable rung and evidence:** extend `fit_gllvmtmb_parity_loglik_x` (or
sibling helper) for `:ordinal` / `ordinal_probit()`; one `@testset` calling
`fit_ordinal_gllvm_pertrait_cov`; live `GLLVM_PARITY_TESTS=1` run; paste Δ;
DGP/seed/link repair over rtol widen.

### Gate (do not skip)

| Check | Required before Ultra Plan / `/goal` |
| --- | --- |
| Engine branch tip | `fix/ordinal-x-pertrait-cov-20260803` (or successor) has **≥1 commit** beyond the identity merge base, or a clear LOCAL DONE SHA |
| Artefact | `fit_ordinal_gllvm_pertrait_cov` + Julia tests green; after-task or checkpoint says LOCAL DONE |
| Identity | Decision ACCEPTED: `docs/dev-log/decisions/2026-08-03-ordinal-x-cutpoint-identity.md` (already true) |
| Ownership | Same tip / fresh parity branch off engine tip — **not** a second engine lane |

**Snapshot at card write (2026-08-03 ~17:00 MDT):** tip `0630f8e4` =
`origin/main` (**0 commits** ahead); uncommitted WIP in
`src/families/ordinal.jl` (~+125/−7: offset plumbing +
`OrdinalPerTraitCovFit` / `fit_ordinal_gllvm_pertrait_cov` draft). Treat as
**Arc 1 in flight**, not LOCAL DONE.

### Capacity ladder (size mode — after gate)

| Order | Budget | Outcome | Trigger / definition of done |
| --- | ---: | --- | --- |
| **WAIT** | — | Engine Arc 1 LOCAL DONE / PR | External — do not start Arc 2 core |
| Arc 0 | 1.5–2 h | Ordinal+X light RCall cell + docs fence | Only after WAIT clears + G0 / Ultra Plan |
| Rung 1 (later) | — | Push/PR when asked | Maintainer |
| Integrate/close | 20 min | check-log + after-task + Rose ≠ full parity | Always |

### Budget (Arc 0 — unlocked only)

| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient / LOOP scaffold | 15–20 | Branch off engine tip; lane `lanes/ordinal-x-arc2-*/LOOP/` |
| Helper + cell | 35–45 | `:ordinal` / `ordinal_probit` in X helper; one `@testset` |
| Live RCall verify | 25–30 | Δ logLik from log; rtol 1e-6 |
| Repair reserve | 25–35 | DGP/seed/link (probit vs logit; cutpoint packing) — never rtol widen |
| Closeout | 20 | Docs + after-task + commit (no push) |
| **Total** | **~120–150** | |

**In scope:** light Ordinal+X RCall cell; helper family switch; narrow docs.  
**Not in this arc:** finishing engine Arc 1; engine surgery unless a bug blocks
the cell; Option B / shared-cutpoint public X; ADEMP; Dropbox writes; push;
parallel engine branch.  
**Evidence used:**
- Identity ACCEPTED: `docs/dev-log/decisions/2026-08-03-ordinal-x-cutpoint-identity.md`
- Mirror cards: `docs/dev-log/plans/2026-08-03-gamma-x-arc2-arc-card.md`;
  NB2/Beta `docs/dev-log/plans/2026-08-02-nb2-beta-x-arc2-ultra-plan.md`
- Measured/inferred Δs: Gamma Arc 2 after-task (Δ≈3.03e-8); NB2/Beta Arc 2
  (Δ≈1e-8 / 4e-9 after DGP repair)
- Twin: `ordinal_probit` fid 14; τ₁=0 / K−2; site-X via shared `X_fix * b_fix`
- Live tip: engine worktree still at main + dirty `ordinal.jl`

**Risk branch:** If engine Arc 1 stalls or lands a different public X route than
the decision, **rewrite this card** before Ultra Plan — do not cargo-cult Gamma
cells onto a wrong fitter. If live Δ ≫ 1e-6 or R Heywood/false-convergence,
repair DGP/seed/link — **never** widen rtol. If missing R/gllvmTMB, land gated
cells + document BLOCKED — do not fake green. If Julia default under X is
LogitLink while twin cell is probit, fix the **cell contract** (match twin) or
document an explicit dual-link fence — do not claim parity across links.

**Done when (post-gate):** cell Pass at 1e-6 with pasted Δ; docs fence updated;
Rose OK for light Ordinal+X only; commits local; no push.  
**First action (now):** **WAIT** for engine Arc 1 LOCAL DONE — do not scaffold
LOOP or edit parity tests for Arc 2 yet.  
**First action (after gate + G0):** Ultra Plan → scaffold
`lanes/ordinal-x-arc2-YYYYMMDD/LOOP/` on engine tip → implement one light cell.

### Actuals (complete at close)

**Recommended / actual:** 90–150 / _pending_ · **Requested / used:** N/A /
_pending_ · **Rungs/cohorts completed:** _pending_  
**Under-run event:** _pending_  
**Calibration:** _pending_  
**Metric movement:** none yet — preparation / contingent card only  
**Result:** blocked on engine Arc 1 · **Next arc:** engine Arc 1 finish (owner:
current engine lane); then this Arc 2 via Ultra Plan

---

**HAND TO ULTRA PLAN:** Ordinal+X light gllvmTMB logLik Arc 2 — **1.5–2 h**
once `fit_ordinal_gllvm_pertrait_cov` is LOCAL DONE — one RCall cell at rtol
`1e-6`, helper extend only, no engine redesign, no push without ask, Rose fence
≠ full family parity. **Do not start Ultra Plan until Shinichi clears the WAIT
gate below.**
