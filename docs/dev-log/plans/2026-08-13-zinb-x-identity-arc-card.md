# ARC CARD — ZINB+X Identity Arc 0 (docs-only)

**Status:** **EXECUTED** (2026-08-13) — Identity ACCEPTED; STOP before engine.  
**Mode:** size  
**Requested outcome:** ACCEPTED decision
`docs/dev-log/decisions/2026-08-13-zinb-x-identity.md`  
**Mechanism authority:** docs-only decision + board/AGENTS/check-log/after-task
in a fresh worktree off `origin/main` @ `#201` / `8abdd751`.  
**Lock:** shared site-X, **separate** `γ^z` / `γ^c`, retain `Λ_z = 0`,
**shared scalar `r`** (log-scale). Julia-forward / twin-asymmetric.  
**Do NOT** copy NB2 per-trait φ (twin-backed).  
**Reject:** engine-before-acceptance; free `Λ_z`; hurdle/Tweedie as this
Identity; invent twin Δ.  
**Recommended arc:** **~70 min** (range **55–90**)  
**Time contract:** ceiling ~90 min; STOP after acceptance  
**Estimate confidence:** **measured** (ZIP+X Identity #198 same shape)

### Fences

- No `src/` ZINB+X engine
- No bridge `zinb` admit
- No twin ZIP/ZINB light Δ
- Do not re-open ZIP Identity
- No hurdle/Tweedie+X, ADEMP, Phylo #127
- Dropbox checkout PROTECTED
- Do not touch PR #199
- Never `git add -A`
- If twin ZIP/ZINB restored at S0: **STOP** this Identity; do not invent light Δ

### Capacity ladder

| Order | Budget | Outcome | Trigger / definition of done |
| --- | ---: | --- | --- |
| Arc 0 | 55–90 min | ACCEPTED ZINB+X Identity note | Start from `origin/main` @ #201 |
| Engine (later) | — | `fit_zinb_gllvm_cov` under this lock | Fresh `/arc-creation` only |
| Integrate/close | 10 min | check-log + after-task + board + Actuals | Always for Arc 0 |

### Budget (Arc 0)

| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient / S0 | 15 | Worktree on `8abdd751`; twin ZIP/ZINB still cut; Julia no-X map |
| Core | 35 | Decision cloned from ZIP+X Identity; lock shared scalar `r` |
| Verify | 10 | Twin cites; zero `src/`; rejected-alts table; Rose fence |
| Closeout | 10 | Board #201 flip + AGENTS + check-log + after-task + Actuals |
| **Total** | **~70** | |

**In scope:** one ZINB+X Identity decision; board START HERE (#201 MERGED);
AGENTS snapshot; check-log; after-task; this card’s Actuals.  
**Not in this arc:** any `src/` change; bridge `zinb`; twin Δ; ZIP Identity
edits; hurdle/Tweedie+X; ADEMP; Phylo #127; PR #199; Dropbox tree.  
**Evidence used:**
- Clone: `docs/dev-log/decisions/2026-08-09-zip-x-identity.md`
- Twin `gllvmTMB` @ `9518d1bf`: known-limitations L146–148; `family_to_id`
  has no ZIP/ZINB arm
- Julia @ `8abdd751`: `fit_zinb_gllvm` shared `log r`; `zinb` ∉ `_BRIDGE_*`;
  `ZIPCovFit` dual-`γ` shipped
- Contrast: NB2/Beta+X Identity (per-trait φ — do not copy)

**Done when:** decision exists, cites twin cut + Julia no-X `fit_zinb_gllvm`
map + ZIP dual-`γ` reuse, **explicitly locks shared scalar `r`**, lists
rejected alts, Rose fence forbids engine / twin parity / ADEMP, **zero**
ZINB+X `src/` in the diff.

**First action:**

```sh
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
git fetch origin main && git rev-parse --short origin/main  # expect ~8abdd751
git worktree add .worktrees/gllvmjl-zinb-x-identity-20260813 \
  -b docs/zinb-x-identity-20260813 origin/main
```

### Actuals (complete at close)

**Recommended / actual:** 70 / ~session-under-70 (docs; S0 twin still cut) ·
**Requested / used:** EXECUTE DIRECTLY / this lane  
**Rungs/cohorts completed:** Arc 0 (S0–closeout identity lock)  
**Under-run event:** no engine; twin ZIP/ZINB not restored (S0 continue)  
**Calibration:** ZIP+X Identity clone held; extra lock text was the
shared-`r` / do-not-copy-NB2 paragraph  
**Metric movement:** none — preparation only (expected)  
**Result:** LOCAL DONE / ACCEPTED · **Next arc:** STOP. Fresh
`/arc-creation` only for ZINB+X engine (`fit_zinb_gllvm_cov` packing
`[βz; γ^z; βc; γ^c; pack(Λc); log r]`). Do not merge this PR unless asked.

---

HAND TO ULTRA PLAN: size-mode Arc 0, **~70 min (55–90)**, outcome =
ZINB+X Identity decision doc only; no engine; clone ZIP+X Identity;
lock shared scalar `r`; fence twin Δ / ADEMP / hurdle/Tweedie / Phylo #127 /
PR #199; PLATFORM = Cursor.
